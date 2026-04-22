#Requires AutoHotkey v2.0
#SingleInstance Force

class ModernXAML {
    static _instances := Map()
    static _msgHooked := false

    __New(xaml) {
        this.id := "WPF_" A_TickCount "_" Random(1000, 9999)
        ModernXAML._instances[this.id] := this
        this.xaml := xaml
        this.events := Map()
        this.wpfHwnd := 0
        this.pid := 0
        this.psPath := A_Temp "\" this.id ".ps1"
        this.errLog := A_Temp "\AhkWpfError.log"

        this.receiver := Gui()
        DllCall("user32\ChangeWindowMessageFilterEx", "Ptr", this.receiver.Hwnd, "UInt", 0x004A, "UInt", 1, "Ptr", 0)

        if (!ModernXAML._msgHooked) {
            OnMessage(0x004A, ObjBindMethod(ModernXAML, "OnCopyData"))
            ModernXAML._msgHooked := true
        }
    }

    OnEvent(controlName, eventName, callback) {
        if !this.events.Has(controlName)
            this.events[controlName] := Map()
        this.events[controlName][eventName] := callback
    }

    Update(controlName, propertyName, valueStr) {
        if !this.wpfHwnd
            return
        payload := controlName "|" propertyName "|" valueStr
        buf := Buffer(StrPut(payload, "UTF-8"))
        StrPut(payload, buf, "UTF-8")

        cds := Buffer(A_PtrSize * 3)
        NumPut("Ptr", 0, cds, 0)
        NumPut("UInt", buf.Size, cds, A_PtrSize)
        NumPut("Ptr", buf.Ptr, cds, A_PtrSize * 2)

        DllCall("user32\SendMessageW", "Ptr", this.wpfHwnd, "UInt", 0x004A, "Ptr", 0, "Ptr", cds.Ptr)
    }

    CheckForCrashes() {
        if (this.wpfHwnd != 0) {
            SetTimer(ObjBindMethod(this, "CheckForCrashes"), 0)
            return
        }
        if FileExist(this.errLog) {
            SetTimer(ObjBindMethod(this, "CheckForCrashes"), 0)
            err := FileRead(this.errLog)
            FileDelete(this.errLog)
            MsgBox("The Background Engine crashed!`n`nDETAILS:`n" err, "Engine Crash", 0x10)
            ExitApp()
        }
    }

    Show() {
        if FileExist(this.errLog)
            FileDelete(this.errLog)

        SetTimer(ObjBindMethod(this, "CheckForCrashes"), 500)

        names := [], unique := Map(), pos := 1
        while (pos := RegExMatch(this.xaml, "i)(?:x:)?Name=['`"]([^'`"]+)['`"]", &match, pos)) {
            if !unique.Has(match[1]) {
                unique[match[1]] := true
                names.Push(match[1])
            }
            pos += match.Len[0]
        }

        trackedCsv := ""
        for index, name in names
            trackedCsv .= '"' name '"' (index < names.Length ? "," : "")

        eventBindings := ""
        for ctrlName, events in this.events {
            eventBindings .= "$c = $win.FindName(`"" ctrlName "`")`n"
            eventBindings .= "if ($c) {`n"
            for eventName, cb in events
                eventBindings .= "    try { $c.add_" eventName "({ param(`$s, `$e); & `$dumpState `"" ctrlName "`" `"" eventName "`" }) } catch {}`n"
            eventBindings .= "}`n"
        }

        b64Xaml := ModernXAML.Base64Encode(this.xaml)

        psScript := '
        (
            param([string]$ahkHwndStr)
            try {
                $ahkHwnd = [IntPtr][long]$ahkHwndStr
                
                $code = @"
                using System;
                using System.Runtime.InteropServices;
                public struct COPYDATASTRUCT {
                    public IntPtr dwData; public int cbData; public IntPtr lpData;
                }
                public class NativeIPC {
                    [DllImport("user32.dll", CharSet = CharSet.Auto)]
                    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, ref COPYDATASTRUCT lParam);
                    [DllImport("dwmapi.dll")]
                    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
                    public static void Send(IntPtr target, string text) {
                        byte[] bytes = System.Text.Encoding.UTF8.GetBytes(text);
                        COPYDATASTRUCT cds = new COPYDATASTRUCT();
                        cds.cbData = bytes.Length + 1;
                        IntPtr ptr = Marshal.AllocHGlobal(cds.cbData);
                        Marshal.Copy(bytes, 0, ptr, bytes.Length);
                        Marshal.WriteByte(ptr, bytes.Length, (byte)0); 
                        cds.lpData = ptr;
                        SendMessage(target, 0x004A, IntPtr.Zero, ref cds);
                        Marshal.FreeHGlobal(ptr);
                    }
                }
            "@
                Add-Type -TypeDefinition $code
                Add-Type -AssemblyName PresentationFramework
                Add-Type -AssemblyName PresentationCore
                Add-Type -AssemblyName WindowsBase
            
                $xamlBytes = [Convert]::FromBase64String("{B64_XAML}")
                $xaml = [System.Text.Encoding]::UTF8.GetString($xamlBytes)
                $win = [System.Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader ([xml]$xaml)))
            
                foreach ($name in @("DragArea", "TxtLogo")) {
                    $dragEl = $win.FindName($name)
                    if ($dragEl) { $dragEl.add_MouseLeftButtonDown({ param($s, $e); try { $win.DragMove() } catch {} }) }
                }
                
                $cBtn = $win.FindName("BtnClose")
                if ($cBtn) { $cBtn.add_Click({ param($s, $e); try { $win.Close() } catch {} }) }
            
                $win.add_Loaded({
                    param($s, $e)
                    $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper($win)).Handle
                    $src = [System.Windows.Interop.HwndSource]::FromHwnd($hwnd)
                    
                    $hook = [System.Windows.Interop.HwndSourceHook] {
                        param([IntPtr]$h, [int]$msg, [IntPtr]$wP, [IntPtr]$lP, [ref]$handled)
                        if ($msg -eq 0x004A) {
                            try {
                                $cds = [System.Runtime.InteropServices.Marshal]::PtrToStructure($lP, [type][COPYDATASTRUCT])
                                $bytes = New-Object byte[] $cds.cbData
                                [System.Runtime.InteropServices.Marshal]::Copy($cds.lpData, $bytes, 0, $cds.cbData)
                                $text = [System.Text.Encoding]::UTF8.GetString($bytes).TrimEnd([char]0)
                                
                                $parts = $text.Split("|", 3)
                                if ($parts.Length -eq 3) {
                                    if ($parts[0] -eq "Window" -and $parts[1] -eq "DWM") {
                                        $p = $parts[2].Split(",")
                                        $backdrop = [int]$p[0]; $dark = [int]$p[1]
                                        [NativeIPC]::DwmSetWindowAttribute($h, 20, [ref]$dark, 4) | Out-Null
                                        [NativeIPC]::DwmSetWindowAttribute($h, 38, [ref]$backdrop, 4) | Out-Null
                                    
                                    } elseif ($parts[0] -eq "Resource") {
                                        $win.Resources[$parts[1]] = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($parts[2])
                                    
                                    } else {
                                        $ctrl = $win.FindName($parts[0])
                                        if ($ctrl) {
                                            if ($parts[1] -eq "AddItem" -and $ctrl -is [System.Windows.Controls.ItemsControl]) {
                                                $ctrl.Items.Add($parts[2]) | Out-Null
                                                if ($ctrl -is [System.Windows.Controls.ListBox]) {
                                                    $ctrl.SelectedIndex = $ctrl.Items.Count - 1
                                                    $ctrl.ScrollIntoView($ctrl.SelectedItem)
                                                }
                                            } elseif ($parts[1] -eq "ClearItems" -and $ctrl -is [System.Windows.Controls.ItemsControl]) {
                                                $ctrl.Items.Clear()
                                                
                                            } else {
                                                $prop = $ctrl.GetType().GetProperty($parts[1])
                                                if ($prop) {
                                                    $pt = $prop.PropertyType.Name
                                                    if ($pt -eq "Brush") {
                                                        $val = (New-Object System.Windows.Media.BrushConverter).ConvertFromString($parts[2])
                                                    } elseif ($prop.PropertyType.IsEnum) {
                                                        $val = [Enum]::Parse($prop.PropertyType, $parts[2], $true)
                                                    } elseif ($pt -eq "Double") {
                                                        $val = [double]$parts[2]
                                                    } elseif ($pt -eq "Boolean" -or $pt -eq "Nullable``1") {
                                                        $val = [System.Convert]::ToBoolean($parts[2])
                                                    } elseif ($pt -eq "Object" -or $pt -eq "String") {
                                                        $val = $parts[2]
                                                    } else {
                                                        $val = [Convert]::ChangeType($parts[2], $prop.PropertyType)
                                                    }
                                                    $prop.SetValue($ctrl, $val)
                                                }
                                            }
                                        }
                                    }
                                }
                            } catch {}
                            $handled.Value = $true
                        }
                        return [IntPtr]::Zero
                    }
                    
                    $src.AddHook($hook)
                    [NativeIPC]::Send($ahkHwnd, "EVENT|{WIN_ID}|Window|Loaded|" + $hwnd.ToString() + "``n")
                })
            
                $win.add_Closed({ param($s, $e); [NativeIPC]::Send($ahkHwnd, "EVENT|{WIN_ID}|Window|Closed``n") })
            
                $tracked = @({TRACKED_CSV})
                $dumpState = {
                    param($cName, $eName)
                    $msg = "EVENT|{WIN_ID}|$cName|$eName``n"
                    foreach ($ctrlName in $tracked) {
                        $c = $win.FindName($ctrlName)
                        if ($c) {
                            $val = ""
                            if ($c -is [System.Windows.Controls.TextBox]) { $val = $c.Text }
                            elseif ($c -is [System.Windows.Controls.PasswordBox]) { $val = $c.Password }
                            elseif ($c -is [System.Windows.Controls.Primitives.ToggleButton]) { $val = [string]$c.IsChecked }
                            elseif ($c -is [System.Windows.Controls.Primitives.RangeBase]) { $val = [string]$c.Value }
                            elseif ($c -is [System.Windows.Controls.ComboBox]) { 
                                if ($c.SelectedItem -is [System.Windows.Controls.ComboBoxItem]) { $val = $c.SelectedItem.Content } 
                                else { $val = $c.Text }
                            }
                            if ($null -eq $val) { $val = "" }
                            $msg += $ctrlName + "=" + [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($val)) + "``n"
                        }
                    }
                    [NativeIPC]::Send($ahkHwnd, $msg)
                }
            
                {EVENT_BINDINGS}
                $win.ShowDialog() | Out-Null
                
            } catch {
                $err = "CRASH: " + $_.Exception.Message
                if ($error[0].Exception.Errors) {
                    foreach ($ce in $error[0].Exception.Errors) { $err += "``n" + $ce.ToString() }
                }
                $err += "``n``nFULL TRACE:``n" + ($error | Out-String)
                [System.IO.File]::WriteAllText("$env:TEMP\AhkWpfError.log", $err)
            }
            
            Remove-Item -Path $MyInvocation.MyCommand.Path -ErrorAction SilentlyContinue
        )'

        psScript := StrReplace(psScript, "{B64_XAML}", b64Xaml)
        psScript := StrReplace(psScript, "{WIN_ID}", this.id)
        psScript := StrReplace(psScript, "{TRACKED_CSV}", trackedCsv)
        psScript := StrReplace(psScript, "{EVENT_BINDINGS}", eventBindings)

        if FileExist(this.psPath)
            FileDelete(this.psPath)
        FileAppend(psScript, this.psPath, "UTF-8")

        cmd := 'powershell.exe -STA -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' this.psPath '" ' String(this.receiver.Hwnd)
        Run(cmd, "", "Hide", &pid)
        this.pid := pid
    }

    static OnCopyData(wParam, lParam, msg, hwnd) {
        if (msg != 0x004A)
            return 0

        lpData := NumGet(lParam, A_PtrSize * 2, "Ptr")
        payload := StrGet(lpData, "UTF-8")
        if !InStr(payload, "EVENT|")
            return 0

        lines := StrSplit(payload, "`n", "`r")
        parts := StrSplit(lines[1], "|")
        if (parts.Length < 4)
            return 0

        winId := parts[2], ctrlName := parts[3], eventName := parts[4]
        if !ModernXAML._instances.Has(winId)
            return 0

        instance := ModernXAML._instances[winId]

        if (ctrlName == "Window" && eventName == "Loaded") {
            instance.wpfHwnd := Integer(parts[5])
        }
        if (ctrlName == "Window" && eventName == "Closed") {
            ExitApp()
            return 1
        }

        stateMap := Map()
        Loop lines.Length {
            if (A_Index == 1 || lines[A_Index] == "")
                continue
            pos := InStr(lines[A_Index], "=")
            if pos {
                k := SubStr(lines[A_Index], 1, pos - 1)
                stateMap[k] := ModernXAML.Base64Decode(SubStr(lines[A_Index], pos + 1))
            }
        }

        if (instance.events.Has(ctrlName) && instance.events[ctrlName].Has(eventName)) {
            cb := instance.events[ctrlName][eventName]
            SetTimer(() => cb(stateMap, ctrlName, eventName), -1)
        }
        return 1
    }

    static Base64Encode(str) {
        buf := Buffer(StrPut(str, "UTF-8"))
        StrPut(str, buf, "UTF-8")
        DllCall("crypt32\CryptBinaryToStringW", "Ptr", buf, "UInt", buf.Size - 1, "UInt", 0x00000001, "Ptr", 0, "UInt*", &size := 0)
        b64 := Buffer(size * 2)
        DllCall("crypt32\CryptBinaryToStringW", "Ptr", buf, "UInt", buf.Size - 1, "UInt", 0x00000001, "Ptr", b64, "UInt*", &size)
        return StrReplace(StrReplace(StrGet(b64, "UTF-16"), "`r", ""), "`n", "")
    }

    static Base64Decode(b64) {
        if (b64 == "")
            return ""
        size := 0
        DllCall("crypt32\CryptStringToBinaryW", "Str", b64, "UInt", 0, "UInt", 1, "Ptr", 0, "UInt*", &size, "Ptr", 0, "Ptr", 0)
        buf := Buffer(size)
        DllCall("crypt32\CryptStringToBinaryW", "Str", b64, "UInt", 0, "UInt", 1, "Ptr", buf, "UInt*", &size, "Ptr", 0, "Ptr", 0)
        return StrGet(buf, "UTF-8")
    }
}


XAML_TEMPLATE := '
(
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Width="940" Height="700"
            WindowStyle="None" AllowsTransparency="False" Background="Transparent"
            WindowStartupLocation="CenterScreen"
            TextElement.Foreground="{DynamicResource TextMain}" FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif">
        
        <WindowChrome.WindowChrome>
            <WindowChrome GlassFrameThickness="-1" CaptionHeight="0" CornerRadius="12" />
        </WindowChrome.WindowChrome>
    
        %components%
    
        %app%
    </Window>
)'
XAML_TEMPLATE := StrReplace(XAML_TEMPLATE, "%components%", FileRead(A_ScriptDir "/xaml.components.xaml", "UTF-8"))