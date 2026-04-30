#Requires AutoHotkey v2.0
#SingleInstance Force

class XAMLGUI {
    static _instances := Map()
    static _msgHooked := false

    __New(xaml := "", exePath := "") {
        this.id := "WPF_" A_TickCount "_" Random(1000, 9999)
        XAMLGUI._instances[this.id] := this
        this.xaml := xaml
        this.exePath := exePath
        this.events := Map()
        this.tracked := Map()
        this.wpfHwnd := 0
        this.pid := 0
        this.errLog := A_Temp "\AhkWpfError.log"

        this.receiver := Gui()
        DllCall("user32\ChangeWindowMessageFilterEx", "Ptr", this.receiver.Hwnd, "UInt", 0x004A, "UInt", 1, "Ptr", 0)

        if (!XAMLGUI._msgHooked) {
            OnMessage(0x004A, ObjBindMethod(XAMLGUI, "OnCopyData"))
            XAMLGUI._msgHooked := true
        }
    }

    OnEvent(controlName, eventName, callback) {
        if !this.events.Has(controlName)
            this.events[controlName] := Map()
        this.events[controlName][eventName] := callback
    }

    Track(controlName) {
        this.tracked[controlName] := true
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

        targetExe := (this.exePath != "") ? this.exePath : A_Temp "\AhkWpf_" this.id ".exe"
        trackedCsv := ""

        if !FileExist(targetExe) {
            names := [], unique := Map(), pos := 1
            if (this.xaml != "") {
                while (pos := RegExMatch(this.xaml, "i)(?:x:)?Name=['`"]([^'`"]+)['`"]", &match, pos)) {
                    if !unique.Has(match[1]) {
                        unique[match[1]] := true
                        names.Push(match[1])
                    }
                    pos += match.Len[0]
                }
            }

            for index, name in names
                trackedCsv .= name (index < names.Length ? "," : "")

            eventBindings := ""
            for ctrlName, events in this.events {
                for eventName, cb in events {
                    eventBindings .= 'BindEvent("' ctrlName '", "' eventName '");`n            '
                }
            }

            b64Xaml := XAMLGUI.Base64Encode(this.xaml)

            csCode := '
            (
                using System;
                using System.Linq;
                using System.Windows;
                using System.Windows.Markup;
                using System.Windows.Controls;
                using System.Windows.Controls.Primitives;
                using System.Windows.Interop;
                using System.Runtime.InteropServices;
                using System.Text;
                using System.Xml;
                using System.Reflection;
                
                public class AhkWpfEngine : Application {
                    [StructLayout(LayoutKind.Sequential)]
                    public struct COPYDATASTRUCT {
                        public IntPtr dwData; public int cbData; public IntPtr lpData;
                    }
                    [DllImport("user32.dll", CharSet = CharSet.Auto)]
                    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, ref COPYDATASTRUCT lParam);
                    [DllImport("dwmapi.dll")]
                    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
                
                    string winId; IntPtr ahkHwnd; string[] tracked; Window win;
                
                    [STAThread]
                    public static void Main(string[] args) {
                        try {
                            if (args.Length < 3) return;
                            new AhkWpfEngine().RunEngine(args[0], args[1], args[2]);
                        } catch (Exception ex) {
                            System.IO.File.WriteAllText(System.IO.Path.Combine(System.IO.Path.GetTempPath(), "AhkWpfError.log"), ex.ToString());
                        }
                    }
                
                    public void RunEngine(string id, string hwndStr, string trackedCsv) {
                        winId = id; ahkHwnd = (IntPtr)long.Parse(hwndStr);
                        tracked = trackedCsv.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries);
                        
                        string b64Xaml = "{B64_XAML}";
                        byte[] xamlBytes = Convert.FromBase64String(b64Xaml);
                        win = (Window)XamlReader.Load(new XmlNodeReader(new XmlDocument { InnerXml = Encoding.UTF8.GetString(xamlBytes) }));
                
                        var dragArea = win.FindName("DragArea") as UIElement;
                        if (dragArea != null) dragArea.MouseLeftButtonDown += (s, e) => { try { win.DragMove(); } catch { } };
                        
                        var txtLogo = win.FindName("TxtLogo") as UIElement;
                        if (txtLogo != null) txtLogo.MouseLeftButtonDown += (s, e) => { try { win.DragMove(); } catch { } };
                        
                        var btnClose = win.FindName("BtnClose") as ButtonBase;
                        if (btnClose != null) btnClose.Click += (s, e) => { try { win.Close(); } catch { } };
                
                        win.Loaded += (s, e) => {
                            IntPtr hwnd = new WindowInteropHelper(win).Handle;
                            HwndSource.FromHwnd(hwnd).AddHook(WndProc);
                            SendToAhk("EVENT|" + winId + "|Window|Loaded|" + hwnd.ToString() + "\n");
                        };
                        win.Closed += (s, e) => { SendToAhk("EVENT|" + winId + "|Window|Closed\n"); };
                
                        {EVENT_BINDINGS}
                
                        win.ShowDialog();
                    }
                
                    private void BindEvent(string ctrlName, string eventName) {
                        try {
                            var ctrl = win.FindName(ctrlName);
                            if (ctrl == null) return;
                            var evt = ctrl.GetType().GetEvent(eventName);
                            if (evt == null) return;
                
                            var parameters = evt.EventHandlerType.GetMethod("Invoke").GetParameters();
                            var pExprs = parameters.Select(p => System.Linq.Expressions.Expression.Parameter(p.ParameterType, p.Name)).ToArray();
                            var dumpStateMethod = this.GetType().GetMethod("DumpState", BindingFlags.NonPublic | BindingFlags.Instance);
                            var call = System.Linq.Expressions.Expression.Call(System.Linq.Expressions.Expression.Constant(this), dumpStateMethod, System.Linq.Expressions.Expression.Constant(ctrlName), System.Linq.Expressions.Expression.Constant(eventName));
                            var lambda = System.Linq.Expressions.Expression.Lambda(evt.EventHandlerType, call, pExprs);
                            evt.AddEventHandler(ctrl, lambda.Compile());
                        } catch { }
                    }
                
                    private void DumpState(string cName, string eName) {
                        var sb = new StringBuilder("EVENT|" + winId + "|" + cName + "|" + eName + "\n");
                        foreach (var t in tracked) {
                            var c = win.FindName(t);
                            if (c != null) {
                                string val = "";
                                if (c is TextBox) {
                                    val = ((TextBox)c).Text;
                                }
                                else if (c is PasswordBox) {
                                    val = ((PasswordBox)c).Password;
                                }
                                else if (c is ToggleButton) {
                                    bool? isChecked = ((ToggleButton)c).IsChecked;
                                    val = isChecked.HasValue ? isChecked.Value.ToString() : "False";
                                }
                                else if (c is RangeBase) {
                                    val = ((RangeBase)c).Value.ToString();
                                }
                                else if (c is ComboBox) {
                                    ComboBox cb = (ComboBox)c;
                                    if (cb.SelectedItem is ComboBoxItem) {
                                        object content = ((ComboBoxItem)cb.SelectedItem).Content;
                                        val = content != null ? content.ToString() : "";
                                    }
                                    else {
                                        val = cb.Text;
                                    }
                                }
                                if (val == null) val = "";
                                sb.Append(t + "=" + Convert.ToBase64String(Encoding.UTF8.GetBytes(val)) + "\n");
                            }
                        }
                        SendToAhk(sb.ToString());
                    }
                
                    private void SendToAhk(string text) {
                        byte[] bytes = Encoding.UTF8.GetBytes(text);
                        var cds = new COPYDATASTRUCT { cbData = bytes.Length + 1, lpData = Marshal.AllocHGlobal(bytes.Length + 1) };
                        Marshal.Copy(bytes, 0, cds.lpData, bytes.Length);
                        Marshal.WriteByte(cds.lpData, bytes.Length, 0);
                        SendMessage(ahkHwnd, 0x004A, IntPtr.Zero, ref cds);
                        Marshal.FreeHGlobal(cds.lpData);
                    }
                
                    private IntPtr WndProc(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled) {
                        if (msg == 0x004A) {
                            try {
                                var cds = (COPYDATASTRUCT)Marshal.PtrToStructure(lParam, typeof(COPYDATASTRUCT));
                                byte[] bytes = new byte[cds.cbData];
                                Marshal.Copy(cds.lpData, bytes, 0, cds.cbData);
                                ProcessMessage(hwnd, Encoding.UTF8.GetString(bytes).TrimEnd('\0'));
                            } catch { }
                            handled = true;
                        }
                        return IntPtr.Zero;
                    }
                
                    private void ProcessMessage(IntPtr hwnd, string text) {
                        string[] parts = text.Split(new[] { '|' }, 3);
                        if (parts.Length < 3) return;
                        if (parts[0] == "Window" && parts[1] == "DWM") {
                            string[] p = parts[2].Split(',');
                            int backdrop = int.Parse(p[0]), dark = int.Parse(p[1]);
                            DwmSetWindowAttribute(hwnd, 20, ref dark, 4);
                            DwmSetWindowAttribute(hwnd, 38, ref backdrop, 4);
                        } else if (parts[0] == "Resource") {
                            win.Resources[parts[1]] = new System.Windows.Media.BrushConverter().ConvertFromString(parts[2]);
                        } else {
                            var ctrl = win.FindName(parts[0]);
                            if (ctrl != null) {
                                if (parts[1] == "AddItem" && ctrl is ItemsControl) {
                                    ((ItemsControl)ctrl).Items.Add(parts[2]);
                                    if (ctrl is ListBox) {
                                        ListBox lb = (ListBox)ctrl;
                                        lb.SelectedIndex = lb.Items.Count - 1;
                                        lb.ScrollIntoView(lb.SelectedItem);
                                    }
                                } else if (parts[1] == "ClearItems" && ctrl is ItemsControl) {
                                    ((ItemsControl)ctrl).Items.Clear();
                                } else {
                                    var prop = ctrl.GetType().GetProperty(parts[1]);
                                    if (prop != null) {
                                        object val = null;
                                        string pt = prop.PropertyType.Name;
                                        if (pt == "Brush") val = new System.Windows.Media.BrushConverter().ConvertFromString(parts[2]);
                                        else if (prop.PropertyType.IsEnum) val = Enum.Parse(prop.PropertyType, parts[2], true);
                                        else if (pt == "Double") val = double.Parse(parts[2]);
                                        else if (pt == "Boolean" || pt == "Nullable`1") val = Convert.ToBoolean(parts[2]);
                                        else if (pt == "Object" || pt == "String") val = parts[2];
                                        else val = Convert.ChangeType(parts[2], prop.PropertyType);
                                        prop.SetValue(ctrl, val, null);
                                    }
                                }
                            }
                        }
                    }
                }
            )'

            csCode := StrReplace(csCode, "{B64_XAML}", b64Xaml)
            csCode := StrReplace(csCode, "{EVENT_BINDINGS}", eventBindings)

            csPath := A_Temp "\AhkWpf_" this.id ".cs"

            if FileExist(csPath)
                FileDelete(csPath)

            FileAppend(csCode, csPath, "UTF-8")

            cscPath := "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
            if !FileExist(cscPath)
                cscPath := "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"

            SplitPath(cscPath, , &cscDir)
            wpfDir := cscDir "\WPF"

            cmd := A_ComSpec ' /c ""' cscPath '" /nologo /target:winexe /out:"' targetExe '" /lib:"' wpfDir '" /reference:System.dll /reference:System.Core.dll /reference:System.Xml.dll /reference:PresentationFramework.dll /reference:PresentationCore.dll /reference:WindowsBase.dll /reference:System.Xaml.dll "' csPath '" > "' this.errLog '" 2>&1"'
            RunWait(cmd, "", "Hide")
            FileDelete(csPath)

            if !FileExist(targetExe) {
                errOut := FileExist(this.errLog) ? FileRead(this.errLog) : "Unknown compilation error."
                MsgBox("Failed to compile background engine.`n`nCompiler Output:`n" errOut, "Engine Error", 0x10)
                return
            }
        } else {
            unique := Map()
            for ctrlName in this.events
                unique[ctrlName] := true
            for ctrlName in this.tracked
                unique[ctrlName] := true

            for name in unique
                trackedCsv .= name ","
            trackedCsv := RTrim(trackedCsv, ",")
        }

        if FileExist(this.errLog)
            FileDelete(this.errLog)

        Run('"' targetExe '" "' this.id '" "' String(this.receiver.Hwnd) '" "' trackedCsv '"', "", "Hide", &pid)
        this.pid := pid

        SetTimer(ObjBindMethod(this, "CheckForCrashes"), 500)
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
        if !XAMLGUI._instances.Has(winId)
            return 0

        instance := XAMLGUI._instances[winId]

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
                stateMap[k] := XAMLGUI.Base64Decode(SubStr(lines[A_Index], pos + 1))
            }
        }

        if (instance.events.Has(ctrlName) && instance.events[ctrlName].Has(eventName)) {
            cb := instance.events[ctrlName][eventName]
            SetTimer(() => cb(stateMap, ctrlName, eventName), -1)
        }
        return 1
    }

    static Base64Encode(str) {
        if (str == "")
            return ""
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

SplitPath(A_LineFile, , &_thisDir)
if FileExist(_thisDir "/xaml.components.xaml")
    XAML_TEMPLATE := StrReplace(XAML_TEMPLATE, "%components%", FileRead(_thisDir "/xaml.components.xaml", "UTF-8"))
else
    XAML_TEMPLATE := StrReplace(XAML_TEMPLATE, "%components%", "")