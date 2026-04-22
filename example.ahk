#Requires AutoHotkey v2.0

#Include "xaml.ahk"

class CustomGenerator extends XAML_Generator {
    ; App-specific shorthands go here
    TelemetryRow(id, location, latencyMs, status, statusColor) {
        return this.Tag("ListBoxItem", "", [
            this.Tag("Grid", "", [
                this.Cols("120", "170", "80", "*"),
                this.Tag("TextBlock", 'Grid.Column="0" Text="' id '" Foreground="{DynamicResource TextMain}" Margin="10,0,0,0" VerticalAlignment="Center"'),
                this.Tag("TextBlock", 'Grid.Column="1" Text="' location '" Foreground="{DynamicResource TextSub}" VerticalAlignment="Center"'),
                this.Tag("TextBlock", 'Grid.Column="2" Text="' latencyMs 'ms" Foreground="' statusColor '" VerticalAlignment="Center"'),
                this.Tag("Border", 'Grid.Column="3" Background="#20' StrReplace(statusColor, "#", "") '" HorizontalAlignment="Left" Padding="8,3" CornerRadius="4"', [
                    this.Tag("TextBlock", 'Text="' status '" Foreground="' statusColor '" FontSize="10" FontWeight="Bold"')
                ])
            ])
        ])
    }
}

; ==========================================
; EXAMPLE USAGE COMPILING YOUR UI
; ==========================================

X := CustomGenerator("Window", 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"')
X.LoadDefaultTheme() ; Injects your massive styling block seamlessly

AppUI := X.Tag("Grid", 'Name="AppGrid" Background="{DynamicResource BgColor}"', [
    X.Cols("240", "*"),
    ; SIDEBAR (Col 0)
    X.Tag("Border", 'Name="SidebarBorder" Grid.Column="0" Background="{DynamicResource SidebarColor}" BorderBrush="{DynamicResource ControlBorder}" BorderThickness="0,0,1,0"', [
        X.Tag("StackPanel", 'Margin="25,35,25,25"', [
            X.Tag("TextBlock", 'Name="TxtLogo" Text="✦ FLUID UI" FontSize="22" FontWeight="Black" Foreground="{DynamicResource TextMain}" Margin="0,0,0,40"'),
            X.Tag("TextBlock", 'Text="THEME ENGINE" Foreground="{DynamicResource TextSub}" FontSize="11" FontWeight="Bold" Margin="0,0,0,12"'),
            X.Tag("RadioButton", 'Name="RadDarkMica" Content="Dark Mica (Win 11)" IsChecked="True"'),
            X.Tag("RadioButton", 'Name="RadDarkAcrylic" Content="Dark Acrylic (Win 10)"'),
            X.Tag("TextBlock", 'Text="SYSTEM TOGGLES" Foreground="{DynamicResource TextSub}" FontSize="11" FontWeight="Bold" Margin="0,15,0,15"'),
            X.Toggle("TglOverdrive", "Overdrive Mode", true, "Accelerate packet processing natively."),
            X.Toggle("TglProxy", "Anonymous Proxy", false)
        ])
    ]),
    ; MAIN CONTENT (Col 1)
    X.Tag("Grid", 'Grid.Column="1"', [
        X.Rows("50", "*", "90"),
        ; Close Button Area (Row 0)
        X.Tag("Border", 'Name="DragArea" Grid.Row="0" Background="Transparent" Cursor="SizeAll"', [
            X.Tag("Button", 'Name="BtnClose" Width="45" Height="35" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,10,10,0" Background="Transparent" BorderThickness="0"', [
                X.Tag("TextBlock", 'Text="✕" Foreground="{DynamicResource TextSub}" FontSize="16" VerticalAlignment="Center" HorizontalAlignment="Center"')
            ])
        ]),
        ; Tab Control (Row 1)
        X.Tag("TabControl", 'Grid.Row="1" Margin="40,0,40,10"', [
            X.Tag("TabItem", 'Header="DEPLOYMENT"', [
                X.Tag("ScrollViewer", 'VerticalScrollBarVisibility="Auto" Margin="0,10,0,0"', [
                    X.Tag("StackPanel", 'Margin="0,10,15,20"', [
                        X.Tag("TextBlock", 'Text="PRIORITY TIER" Foreground="{DynamicResource TextSub}" FontSize="11" FontWeight="Bold" Margin="0,0,0,8"'),
                        ; Calling our Power Tool Method for Segmented Buttons
                        X.SegmentGroup("Priority", ["LOW", "BALANCED", "MAXIMUM"], 2),
                        ; Native tag structure for the Slider
                        X.Tag("TextBlock", 'Text="PROCESSING POWER" Foreground="{DynamicResource TextSub}" FontSize="11" FontWeight="Bold" Margin="0,0,0,12"'),
                        X.Tag("Grid", 'Margin="0,0,0,10"', [
                            X.Tag("Slider", 'Name="SldPower" Minimum="0" Maximum="100" Value="45" Margin="0,0,60,0" ToolTip="Adjust priority."'),
                            X.Tag("TextBlock", 'Text="{Binding Value, ElementName=SldPower, StringFormat={}{0:0}%}" Foreground="{DynamicResource Accent}" FontSize="20" FontWeight="Bold" HorizontalAlignment="Right"')
                        ])
                    ])
                ])
            ]),
            X.Tag("TabItem", 'Header="DATA GRID"', [
                X.Tag("StackPanel", 'Margin="0,20,0,0"', [
                    X.Tag("TextBlock", 'Text="Live Telemetry Grid" FontSize="28" FontWeight="SemiBold" Foreground="{DynamicResource TextMain}" Margin="0,0,0,5"'),
                    X.Tag("Border", 'BorderBrush="{DynamicResource ControlBorder}" BorderThickness="1" CornerRadius="8" Background="{DynamicResource ControlBg}" Margin="0,0,0,15"', [
                        X.Tag("Grid", "", [
                            X.Rows("35", "*"),
                            X.Tag("ListBox", 'Grid.Row="1" Background="Transparent" BorderThickness="0" Padding="0,5"', [
                                ; Using the Power Tool Method for complex items
                                X.TelemetryRow("SRV-US-01", "N. Virginia, USA", "14", "ONLINE", "#32D74B"),
                                X.TelemetryRow("SRV-EU-04", "London, UK", "89", "SYNCING", "#FF9F0A"),
                                X.TelemetryRow("SRV-AP-09", "Tokyo, Japan", "ERR", "OFFLINE", "#FF453A")
                            ])
                        ])
                    ])
                ])
            ])
        ])
    ])
])

; Generate the clean, compiled XAML string
CompiledMarkup := X.Compile(AppUI)

; ==============================================================================
; 2. INSTANTIATE & BIND AHK LOGIC
; ==============================================================================

;global ui := XAMLGUI(myXaml)
global ui := XAMLGUI(StrReplace(XAML_TEMPLATE, "%app%", CompiledMarkup), A_ScriptDir "\test.exe") ;XAMLGUI(CompiledMarkup, A_ScriptDir "\test.exe")

;MsgBox(ui)

ui.OnEvent("RadDarkMica", "Checked", ThemeChanged)
ui.OnEvent("RadDarkAcrylic", "Checked", ThemeChanged)
ui.OnEvent("RadLightMica", "Checked", ThemeChanged)
ui.OnEvent("RadCyber", "Checked", ThemeChanged)

ui.OnEvent("BtnExecute", "Click", ExecuteProcess)
ui.OnEvent("Window", "Loaded", OnUIReady)

ui.Track("TxtUser") ;; COMMENT OUT FOR PS
ui.Track("ComboRegion") ;; COMMENT OUT FOR PS
ui.Track("TglProxy") ;; COMMENT OUT FOR PS

ui.Show()

; --- EVENT CALLBACKS ---

OnUIReady(state, ctrl, event) {
    ui.Update("Window", "DWM", "2,1")
}

ThemeChanged(state, ctrl, event) {
    if (ctrl == "RadDarkMica" || ctrl == "RadDarkAcrylic") {
        ui.Update("Window", "DWM", (ctrl == "RadDarkAcrylic" ? "3" : "2") ",1")
        ui.Update("Resource", "BgColor", (ctrl == "RadDarkAcrylic" ? "#70000000" : "#90111114"))
        ui.Update("Resource", "SidebarColor", "#30000000")
        ui.Update("Resource", "TextMain", "#FFFFFF")
        ui.Update("Resource", "TextSub", "#AAAAAA")
        ui.Update("Resource", "ControlBg", "#15FFFFFF")
        ui.Update("Resource", "ControlBorder", "#20FFFFFF")
        ui.Update("Resource", "DropdownBg", "#1E1E1E")
        ui.Update("Resource", "Accent", "#0A84FF")
        ui.Update("LogList", "Foreground", "#32D74B")

    } else if (ctrl == "RadLightMica") {
        ui.Update("Window", "DWM", "2,0")
        ui.Update("Resource", "BgColor", "#90F5F5F5")
        ui.Update("Resource", "SidebarColor", "#50FFFFFF")
        ui.Update("Resource", "TextMain", "#111111")
        ui.Update("Resource", "TextSub", "#444444")
        ui.Update("Resource", "ControlBg", "#80FFFFFF")
        ui.Update("Resource", "ControlBorder", "#40000000")
        ui.Update("Resource", "DropdownBg", "#FAFAFA")
        ui.Update("Resource", "Accent", "#005CBA")
        ui.Update("LogList", "Foreground", "#005CBA")

    } else if (ctrl == "RadCyber") {
        ui.Update("Window", "DWM", "0,1")
        ui.Update("Resource", "BgColor", "#F009001A")
        ui.Update("Resource", "SidebarColor", "#30FF0055")
        ui.Update("Resource", "TextMain", "#00FFCC")
        ui.Update("Resource", "TextSub", "#FF0055")
        ui.Update("Resource", "ControlBg", "#2000FFCC")
        ui.Update("Resource", "ControlBorder", "#40FF0055")
        ui.Update("Resource", "DropdownBg", "#09001A")
        ui.Update("Resource", "Accent", "#FF0055")
        ui.Update("LogList", "Foreground", "#FF0055")
    }
}

ExecuteProcess(state, ctrl, event) {
    ui.Update("BtnExecute", "IsEnabled", "False")

    ui.Update("TxtStatus", "Text", "Connecting to " state["ComboRegion"] "...")
    ui.Update("TxtStatus", "Foreground", "#FF9F0A")
    ui.Update("LoadingSpinner", "Visibility", "Visible") ; <-- TOGGLES GPU SPINNER ON!

    ui.Update("LogList", "ClearItems", "")
    ui.Update("LogList", "AddItem", "Authenticating " state["TxtUser"] " on " state["ComboRegion"])
    ui.Update("LogList", "AddItem", "Proxy Active: " state["TglProxy"])

    Loop 20 {
        ui.Update("SldPower", "Value", String(A_Index * 5))
        ui.Update("LogList", "AddItem", "[" A_Hour ":" A_Min ":" A_Sec "." A_MSec "] Processing payload chunk " A_Index "...")
        Sleep(40)
    }

    ui.Update("LogList", "AddItem", "")
    ui.Update("LogList", "AddItem", "--> DEPLOYMENT SUCCESSFUL.")

    ui.Update("LoadingSpinner", "Visibility", "Hidden") ; <-- HIDES SPINNER
    ui.Update("TxtStatus", "Text", "Deployment Successful!")
    ui.Update("TxtStatus", "Foreground", "#32D74B")

    ui.Update("BtnExecute", "IsEnabled", "True")
    ui.Update("BtnExecute", "Content", "RESTART SEQUENCE")
}