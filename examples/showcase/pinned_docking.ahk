#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Generator.ahk"
#Include "..\..\lib\XAML_Host.ahk"
XAMLHost.Prewarm()
#Include "..\..\lib\XAML_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"
#Include "..\..\lib\XAML_PanelManager.ahk"

; --- Pinned Docking Manager Example ---
; Demonstrates a premium multi-window workspace where floating panels
; can be snapped (pinned) to each other and follow in perfect real-time lockstep
; during drags, powered by high-performance Win32 WinEventHooks.

global INI_FILE := A_ScriptDir "\pinned_docking_layout.ini"
global isAppReady := false
global isInitializing := true

Trace(msg) {
    try FileAppend(msg "`n", A_Temp "\AhkWpf\AhkTrace.log", "UTF-8")
}

try FileDelete(A_Temp "\AhkWpf\AhkTrace.log")
Trace("1. Pinned Docking Script Start")

; Enable High-Performance Snapped Window Follow Dragging
PanelManager.FollowMode := true
PanelManager.IniFile := INI_FILE

; Register Panels
PanelManager.RegisterPanel("Terminal", "Terminal Output", 100, 100, 600, 300)
PanelManager.RegisterPanel("Properties", "Object Properties", 750, 100, 300, 500)
PanelManager.RegisterPanel("Toolbox", "Component Toolbox", 100, 450, 250, 400)

; --- Main Application Setup ---
app := XAML_GUI("Silky-Smooth Pinned Docking", { Sidebar: true, BurgerMenu: true, TitleBarHeight: 28, AppIcon: true, MaxButton: false })
app.SkipDefaultThemeOnLoad := true

; Load saved settings
savedRadius := IniRead(INI_FILE, "Global", "PanelRadius", "0")
savedShowInAltTab := IniRead(INI_FILE, "Global", "ShowInAltTab", "0")
savedShowInTaskbar := IniRead(INI_FILE, "Global", "ShowInTaskbar", "0")
savedNoShadows := IniRead(INI_FILE, "Global", "NoShadows", "0")
savedTransparency := IniRead(INI_FILE, "Global", "Transparency", "1")
savedBackdrop := IniRead(INI_FILE, "Global", "Backdrop", "Mica")

; Add settings directly to sidebar
app.sidebarPanel.Add("TextBlock").Text("WINDOW OPTIONS").Margin("0,15,0,5")

app.sidebarPanel.Add("TextBlock").Text("Panel Visibility:").Foreground("{DynamicResource TextSub}").Margin("0,5,0,2")
cbVisibility := app.sidebarPanel.Add("ComboBox").Name("ComboVisibility").Height(30).Margin("0,0,0,10")
    .On("SelectionChanged", (state, ctrl, event) => OnVisibilityChanged(state))
    .Track()
cbVisibility.Add("ComboBoxItem").Content("Hidden in taskbar & alt tab")
cbVisibility.Add("ComboBoxItem").Content("Taskbar + Alt Tab")
cbVisibility.Add("ComboBoxItem").Content("ONLY Alt tab")

chkShadows := app.sidebarPanel.Add("CheckBox").Name("ChkEnableShadows").Content("Enable window shadows").Foreground("{DynamicResource TextMain}").Margin("0,0,0,10")
    .On("Click", (state, ctrl, event) => OnShadowsToggle(state))
    .Track()

app.sidebarPanel.Add("TextBlock").Text("TRANSPARENCY & BLUR").Margin("0,15,0,5")
chkTrans := app.sidebarPanel.Add("CheckBox").Name("ChkTransparency").Content("Transparency effects").Foreground("{DynamicResource TextMain}").Margin("0,0,0,10")
    .On("Click", (state, ctrl, event) => OnTransparencyToggle(state))
    .Track()
app.sidebarPanel.Add("TextBlock").Text("Material Blur Effect:").Foreground("{DynamicResource TextSub}").Margin("0,5,0,2")
cbBlur := app.sidebarPanel.Add("ComboBox").Name("ComboBlurEffect").Height(30).Margin("0,0,0,10")
    .On("SelectionChanged", (state, ctrl, event) => OnBlurEffectChanged(state))
    .Track()
cbBlur.Add("ComboBoxItem").Content("Mica (High Fidelity)")
cbBlur.Add("ComboBoxItem").Content("Acrylic (Frosted Glass)")
cbBlur.Add("ComboBoxItem").Content("Aero (Classic Glass)")

initVisIdx := 0
if (savedShowInAltTab == "1" && savedShowInTaskbar == "1") {
    initVisIdx := 1
} else if (savedShowInAltTab == "1" && savedShowInTaskbar == "0") {
    initVisIdx := 2
} else {
    initVisIdx := 0
}

cbVisibility.SelectedIndex(initVisIdx)

chkShadows.IsChecked(savedNoShadows == "0" ? "True" : "False")
chkTrans.IsChecked(savedTransparency == "1" ? "True" : "False")
initBlurIdx := savedBackdrop == "Acrylic" ? 1 : (savedBackdrop == "Aero" ? 2 : 0)
cbBlur.SelectedIndex(initBlurIdx)

app.sidebarPanel.Add("TextBlock").Text("PANEL THEMES").Margin("0,15,0,5")
for id, pInfo in PanelManager.Panels {
    app.sidebarPanel.Add("TextBlock").Text(pInfo.Title ":").Foreground("{DynamicResource TextSub}").Margin("0,5,0,2")
    cb := app.sidebarPanel.Add("ComboBox").Name("ComboTheme_" id).Height(30).Margin("0,0,0,10")
    cb.Add("ComboBoxItem").Content("Inherit")
    try {
        iniPath := FindThemesIni()
        Loop Parse, IniRead(iniPath), "`n", "`r" {
            cb.Add("ComboBoxItem").Content(A_LoopField)
        }
    } catch {
    }
    cb.SelectedIndex(0)
}

contentPanel := app.main.Add("StackPanel").Grid_Row(1).Margin("40")

contentPanel.Add("TextBlock").Text("SILKY-SMOOTH PINNED DOCKING").Foreground("{DynamicResource TextMain}").FontSize(24).FontWeight("Bold").Margin("0,0,0,5")
contentPanel.Add("TextBlock").Text("Tear off any panels below. When you drag panels next to each other, they will SNAP and PIN together. Once pinned, dragging any window moves the entire cluster seamlessly in real-time!").Foreground("{DynamicResource TextSub}").Margin("0,0,0,30").TextWrapping("Wrap")

btnSp := contentPanel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,30")
btnSp.Add("Button").Name("BtnOpenTerminal").Content("Toggle Terminal").Margin("0,0,10,0")
    .On("Click", (*) => PanelManager.ShowPanel("Terminal"))
btnSp.Add("Button").Name("BtnOpenProperties").Content("Toggle Properties").Margin("0,0,10,0")
    .On("Click", (*) => PanelManager.ShowPanel("Properties"))
btnSp.Add("Button").Name("BtnOpenToolbox").Content("Toggle Toolbox")
    .On("Click", (*) => PanelManager.ShowPanel("Toolbox"))

ui := app.Compile()
for id, pInfo in PanelManager.Panels {
    ui.Track("ComboTheme_" id)
}

; Restore Main Window Position
mainX := IniRead(INI_FILE, "MainWindow", "X", "")
mainY := IniRead(INI_FILE, "MainWindow", "Y", "")
mainW := IniRead(INI_FILE, "MainWindow", "W", "940")
mainH := IniRead(INI_FILE, "MainWindow", "H", "700")

if (mainX != "" && mainY != "") {
    ui.xaml := StrReplace(ui.xaml, 'Width="940" Height="700"', 'Width="' mainW '" Height="' mainH '" Left="' mainX '" Top="' mainY '"')
    ui.xaml := StrReplace(ui.xaml, 'WindowStartupLocation="CenterScreen"', 'WindowStartupLocation="Manual"')
}
if (IniRead(INI_FILE, "Global", "NoShadows", "0") == "1") {
    ui.xaml := StrReplace(ui.xaml, 'GlassFrameThickness="-1"', 'GlassFrameThickness="0" ResizeBorderThickness="6"')
}
ui.OnEvent("Window", "LoadedHwnd", (state, ctrl, event) => OnMainLoaded())
ui.OnEvent("ComboTheme", "SelectionChanged", (state, ctrl, event) => (
    OnThemeEngineChanged(state["ComboTheme"])
))
for id, pInfo in PanelManager.Panels {
    ui.OnEvent("ComboTheme_" id, "SelectionChanged", OnPanelThemeChanged.Bind(id))
}
ui.OnEvent("ComboScale", "SelectionChanged", (state, ctrl, event) => (
    isInitializing ? "" : (
        app.ScaleChanged(state, ctrl, event),
        IniWrite(state["ComboScale"], INI_FILE, "Global", "Scale"),
        PanelManager.UpdateScale(state["ComboScale"])
    )
))
ui.OnEvent("ComboRadius", "SelectionChanged", (state, ctrl, event) => OnRadiusChanged(state))
ui.OnEvent("Window", "Closing", (*) => OnMainClosing())

app.Show()

OnMainLoaded() {
    global INI_FILE, isAppReady
    savedTheme := IniRead(INI_FILE, "Global", "Theme", "Dark Mica (Win 11)")
    PanelManager.CurrentTheme := savedTheme
    savedScale := IniRead(INI_FILE, "Global", "Scale", "Balanced")
    savedRadius := IniRead(INI_FILE, "Global", "PanelRadius", "0")

    radiusIdx := 0
    switch savedRadius {
        case "0": radiusIdx := 0
        case "4": radiusIdx := 1
        case "8": radiusIdx := 2
        case "12": radiusIdx := 3
        case "16": radiusIdx := 4
        default: radiusIdx := 2
    }

    themeIdx := 0
    try {
        iniPath := FindThemesIni()
        Loop Parse, IniRead(iniPath), "`n", "`r" {
            if (A_LoopField == savedTheme) {
                break
            }
            themeIdx++
        }
    } catch {
        themeIdx := 0
    }

    scaleIdx := savedScale == "Thin" ? 0 : (savedScale == "Balanced" ? 1 : 2)

    PanelManager.Init(ui, INI_FILE)

    if (PanelManager.FollowMode) {
        try {
            WinWait("ahk_id " ui.wpfHwnd, , 2)
            WinSetStyle("-0x10000", "ahk_id " ui.wpfHwnd)
        }
    }

    SetTimer(ApplyInitialSelections.Bind(radiusIdx, themeIdx, scaleIdx, savedRadius, savedTheme, savedScale), -50)
    SetTimer(CheckMainMoved, 1000)
}

ApplyInitialSelections(rIdx, tIdx, sIdx, savedRadius, savedTheme, savedScale) {
    global isAppReady, ui, app, isInitializing
    isAppReady := true
    try {
        ui.Update("ComboRadius", "SelectedIndex", String(rIdx))
    } catch {
    }
    try {
        ui.Update("ComboTheme", "SelectedIndex", String(tIdx))
    } catch {
    }
    try {
        ui.Update("ComboScale", "SelectedIndex", String(sIdx))
    } catch {
    }

    for id, pInfo in PanelManager.Panels {
        savedPTheme := IniRead(INI_FILE, id, "Theme", "Inherit")
        pThemeIdx := 0
        if (savedPTheme != "Inherit") {
            try {
                iniPath := FindThemesIni()
                idx := 1
                Loop Parse, IniRead(iniPath), "`n", "`r" {
                    if (A_LoopField == savedPTheme) {
                        pThemeIdx := idx
                        break
                    }
                    idx++
                }
            } catch {
                pThemeIdx := 0
            }
        }
        try {
            ui.Update("ComboTheme_" id, "SelectedIndex", String(pThemeIdx))
        } catch {
        }
    }

    Trace("ApplyInitialSelections: Force-syncing theme '" savedTheme "', scale '" savedScale "', radius '" savedRadius "' to all windows")
    try {
        app.ThemeChanged(Map("ComboTheme", savedTheme), "", "")
    } catch as eTheme {
        Trace("ApplyInitialSelections ThemeChanged failed: " eTheme.Message)
    }
    try {
        PanelManager.UpdateTheme(savedTheme)
    } catch as eThemePanels {
        Trace("ApplyInitialSelections UpdateTheme failed: " eThemePanels.Message)
    }

    try {
        app.ScaleChanged(Map("ComboScale", savedScale), "", "")
    } catch as eScale {
        Trace("ApplyInitialSelections ScaleChanged failed: " eScale.Message)
    }
    try {
        PanelManager.UpdateScale(savedScale)
    } catch as eScalePanels {
        Trace("ApplyInitialSelections UpdateScale failed: " eScalePanels.Message)
    }

    try {
        radStr := ""
        switch savedRadius {
            case "0": radStr := "Sharp (0)"
            case "4": radStr := "Rounded (4)"
            case "8": radStr := "Smooth (8)"
            case "12": radStr := "Extra Smooth (12)"
            case "16": radStr := "Fluid (16)"
            default: radStr := "Smooth (8)"
        }
        app.RadiusChanged(Map("ComboRadius", radStr), "", "")
        PanelManager.UpdateRadius(savedRadius)
    } catch as eRad {
        Trace("ApplyInitialSelections OnRadiusChanged failed: " eRad.Message)
    }

    try {
        UpdateBackdropEffects()
    } catch as eBackdrop {
        Trace("ApplyInitialSelections UpdateBackdropEffects failed: " eBackdrop.Message)
    }

    ; Done initializing!
    SetTimer(EndInitialization, -500)
}

EndInitialization() {
    global isInitializing
    isInitializing := false
    Trace("Initialization ended. isInitializing=" isInitializing)
}

CheckMainMoved() {
    if (ui.wpfHwnd && WinExist("ahk_id " ui.wpfHwnd)) {
        WinGetPos(&x, &y, &w, &h, "ahk_id " ui.wpfHwnd)
        if (x < -10000 || y < -10000)
            return

        static lastX := "", lastY := "", lastW := "", lastH := ""
        if (x != lastX || y != lastY || w != lastW || h != lastH) {
            lastX := x, lastY := y, lastW := w, lastH := h
            IniWrite(x, INI_FILE, "MainWindow", "X")
            IniWrite(y, INI_FILE, "MainWindow", "Y")
            IniWrite(w, INI_FILE, "MainWindow", "W")
            IniWrite(h, INI_FILE, "MainWindow", "H")
        }
    }
}

OnThemeEngineChanged(themeName) {
    global INI_FILE, ui, app, isAppReady, isInitializing
    if (!isAppReady || isInitializing)
        return

    IniWrite(themeName, INI_FILE, "Global", "Theme")
    PanelManager.CurrentTheme := themeName
    
    iniPath := FindThemesIni()
    try {
        themeData := IniRead(iniPath, themeName)
    } catch {
        themeData := ""
    }
    
    backdrop := "2"
    darkMode := "1"
    
    if (themeData != "") {
        Loop Parse, themeData, "`n", "`r" {
            parts := StrSplit(A_LoopField, "=", " `t", 2)
            if (parts.Length == 2 && parts[1] == "Window_DWM") {
                dwmParts := StrSplit(parts[2], ",")
                if (dwmParts.Length >= 2) {
                    backdrop := dwmParts[1]
                    darkMode := dwmParts[2]
                }
                break
            }
        }
    }
    
    transVal := (backdrop != "0") ? "1" : "0"
    blurVal := "Mica"
    if (backdrop == "3")
        blurVal := "Acrylic"
    else if (backdrop == "1")
        blurVal := "Aero"
        
    if (!isInitializing) {
        IniWrite(transVal, INI_FILE, "Global", "Transparency")
        IniWrite(blurVal, INI_FILE, "Global", "Backdrop")
        
        if (ui.wpfHwnd) {
            try ui.Update("ChkTransparency", "IsChecked", (transVal == "1" ? "True" : "False"))
            blurIdx := (blurVal == "Acrylic" ? 1 : (blurVal == "Aero" ? 2 : 0))
            try ui.Update("ComboBlurEffect", "SelectedIndex", String(blurIdx))
        }
    }
    
    radius := "12"
    if (themeData != "") {
        Loop Parse, themeData, "`n", "`r" {
            parts := StrSplit(A_LoopField, "=", " `t", 2)
            if (parts.Length == 2 && parts[1] == "Resource_WindowRadius") {
                radiusVal := parts[2]
                if (InStr(radiusVal, "CornerRadius:") == 1) {
                    radius := SubStr(radiusVal, 14)
                }
                break
            }
        }
    }
    
    if (!isInitializing) {
        IniWrite(radius, INI_FILE, "Global", "PanelRadius")
        if (ui.wpfHwnd) {
            radIdx := 2
            switch radius {
                case "0": radIdx := 0
                case "4": radIdx := 1
                case "8": radIdx := 2
                case "12": radIdx := 3
                case "16": radIdx := 4
            }
            try ui.Update("ComboRadius", "SelectedIndex", String(radIdx))
        }
    }
    
    try app.ThemeChanged(Map("ComboTheme", themeName), "", "")
    
    activeRadius := isInitializing ? IniRead(INI_FILE, "Global", "PanelRadius", "0") : radius
    
    radStr := ""
    switch activeRadius {
        case "0": radStr := "Sharp (0)"
        case "4": radStr := "Rounded (4)"
        case "8": radStr := "Smooth (8)"
        case "12": radStr := "Extra Smooth (12)"
        case "16": radStr := "Fluid (16)"
        default: radStr := "Smooth (8)"
    }
    try app.RadiusChanged(Map("ComboRadius", radStr), "", "")
    PanelManager.UpdateRadius(activeRadius)

    noShadows := IniRead(INI_FILE, "Global", "NoShadows", "0")
    PanelManager.UpdateShadows(noShadows == "0")
    
    PanelManager.UpdateTheme(themeName)
    UpdateBackdropEffects()
}

OnRadiusChanged(state) {
    global INI_FILE, isAppReady, app, isInitializing
    if (!isAppReady || isInitializing || !state.Has("ComboRadius"))
        return
    radText := state["ComboRadius"]
    RegExMatch(radText, "\((\d+)\)", &match)
    radius := match ? match[1] : "0"
    
    IniWrite(radius, INI_FILE, "Global", "PanelRadius")
    
    try app.RadiusChanged(state, "", "")
    PanelManager.UpdateRadius(radius)
}

OnPanelThemeChanged(id, state, ctrl, event) {
    global INI_FILE, isAppReady
    if (!isAppReady || !state.Has("ComboTheme_" id))
        return
    chosenTheme := state["ComboTheme_" id]
    IniWrite(chosenTheme, INI_FILE, id, "Theme")
    
    if (PanelManager.Panels.Has(id)) {
        pInfo := PanelManager.Panels[id]
        PanelManager.ApplyThemeToPanel(pInfo, PanelManager.CurrentTheme)
    }
}

OnVisibilityChanged(state) {
    global INI_FILE, isAppReady
    if (!isAppReady)
        return
    
    selected := state["ComboVisibility"]
    
    showInAltTab := "0"
    showInTaskbar := "0"
    
    if (selected == "Taskbar + Alt Tab") {
        showInAltTab := "1"
        showInTaskbar := "1"
    } else if (selected == "ONLY Alt tab") {
        showInAltTab := "1"
        showInTaskbar := "0"
    } else {
        showInAltTab := "0"
        showInTaskbar := "0"
    }
    
    IniWrite(showInAltTab, INI_FILE, "Global", "ShowInAltTab")
    IniWrite(showInTaskbar, INI_FILE, "Global", "ShowInTaskbar")
    
    PanelManager.ApplyVisibilityStyles()
}

OnTransparencyToggle(state) {
    global INI_FILE, isAppReady, isInitializing
    if (!isAppReady || isInitializing)
        return
    val := state["ChkTransparency"] == "True" ? "1" : "0"
    IniWrite(val, INI_FILE, "Global", "Transparency")
    UpdateBackdropEffects()
}

OnBlurEffectChanged(state) {
    global INI_FILE, isAppReady, isInitializing
    if (!isAppReady || isInitializing || !state.Has("ComboBlurEffect"))
        return
    selected := state["ComboBlurEffect"]
    blur := selected == "Acrylic (Frosted Glass)" ? "Acrylic" : (selected == "Aero (Classic Glass)" ? "Aero" : "Mica")
    IniWrite(blur, INI_FILE, "Global", "Backdrop")
    UpdateBackdropEffects()
}

UpdateBackdropEffects() {
    global INI_FILE, ui
    trans := IniRead(INI_FILE, "Global", "Transparency", "1")
    blur := IniRead(INI_FILE, "Global", "Backdrop", "Mica")
    
    effectNum := 0
    if (trans == "1") {
        if (blur == "Mica")
            effectNum := 2
        else if (blur == "Acrylic")
            effectNum := 3
        else if (blur == "Aero")
            effectNum := 1
    }
    
    modeNum := InStr(PanelManager.CurrentTheme, "Light") || InStr(PanelManager.CurrentTheme, "Sakura") ? 0 : 1
    valStr := effectNum "," modeNum
    
    if (ui.wpfHwnd) {
        try ui.Update("Window", "DWM", valStr)
    }
    for id, pInfo in PanelManager.Panels {
        if (pInfo.Instance != "" && pInfo.GuiHwnd) {
            try pInfo.Instance.Update("Window", "DWM", valStr)
        }
    }
}

OnShadowsToggle(state) {
    global INI_FILE, isAppReady, isInitializing
    if (!isAppReady || isInitializing)
        return
    val := state["ChkEnableShadows"] == "True" ? "0" : "1"
    IniWrite(val, INI_FILE, "Global", "NoShadows")
    PanelManager.UpdateShadows(val == "0")
}

OnMainClosing() {
    for id, pInfo in PanelManager.Panels {
        if (pInfo.Instance != "") {
            try pInfo.Instance.Update("Window", "Close", "")
        }
    }
    ExitApp()
}
