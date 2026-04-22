#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "xaml.ahk"

myXaml := StrReplace(XAML_TEMPLATE, "%app%", FileRead(A_ScriptDir "\eg.xaml", "UTF-8"))

; ==============================================================================
; 2. INSTANTIATE & BIND AHK LOGIC
; ==============================================================================

global ui := ModernXAML(myXaml)
;global ui := ModernXAML(myXaml, A_ScriptDir "\egFrame.exe")

ui.OnEvent("RadDarkMica", "Checked", ThemeChanged)
ui.OnEvent("RadDarkAcrylic", "Checked", ThemeChanged)
ui.OnEvent("RadLightMica", "Checked", ThemeChanged)
ui.OnEvent("RadCyber", "Checked", ThemeChanged)

ui.OnEvent("BtnExecute", "Click", ExecuteProcess)
ui.OnEvent("Window", "Loaded", OnUIReady)

;ui.Track("TxtUser") ;; COMMENT OUT FOR PS
;ui.Track("ComboRegion") ;; COMMENT OUT FOR PS
;ui.Track("TglProxy") ;; COMMENT OUT FOR PS

ui.Show()
Persistent()

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