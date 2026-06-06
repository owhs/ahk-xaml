#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"
#Include "..\data/MockData.ahk"

; Initialize App with a dark theme structure
app := XAML_GUI("VS Code Clone - AHK-XAML", { Sidebar: false, BurgerMenu: false, TitleBarHeight: 35 })

; Hide default TabControl since we are building a custom layout
app.tabs.Visibility("Collapsed")

; Set the background of the main area to match VS Code dark theme
app.main.Background("{DynamicResource SolidBg}")

; Main Layout Grid
layout := app.main.Add("Grid").Grid_Row(1)
layout.Rows("*", "22") ; Main area, Status bar

; Main Area Splitter
mainArea := layout.Add("Grid").Grid_Row(0)
mainArea.Cols("50", "*")

; 1. Activity Bar (Far Left)
activityBarBorder := mainArea.Add("Border").Grid_Column(0).Background("{DynamicResource SolidControl}").BorderBrush("{DynamicResource SolidBorder}").BorderThickness("0,0,1,0").SetProp("Panel.ZIndex", "10")
activityBar := activityBarBorder.Add("Grid")
activitySp := activityBar.Add("StackPanel").Margin("0,10,0,0").VerticalAlignment("Top")

; Uses Example_MockData.AddActivityIcon

Example_MockData.AddActivityIcon(activitySp, 0xE814, "BtnActExplorer", true)  ; Explorer
Example_MockData.AddActivityIcon(activitySp, 0xE721, "BtnActSearch")        ; Search
Example_MockData.AddActivityIcon(activitySp, 0xE90F, "BtnActSourceControl") ; Source Control
Example_MockData.AddActivityIcon(activitySp, 0xEBE8, "BtnActRun")           ; Run/Debug
Example_MockData.AddActivityIcon(activitySp, 0xE718, "BtnActExtensions")    ; Extensions

; Bottom Activity Icons
activityBottom := activityBar.Add("StackPanel").VerticalAlignment("Bottom").Margin("0,0,0,10")
Example_MockData.AddActivityIcon(activityBottom, 0xE713, "BtnActSettings")  ; Settings
Example_MockData.AddActivityIcon(activityBottom, 0xE77B, "BtnActAccounts")  ; Accounts

; 3. Editor Area (Declared before Sidebar to render underneath)
editorArea := mainArea.Add("Grid").Name("EditorArea").Grid_Column(1).Margin("250,0,0,0")

; Editor Scrim (Catches clicks when Sidebar is overlaid)
editorScrim := editorArea.Add("Border").Name("EditorScrim").Grid_RowSpan(2).Background("#40000000").Visibility("Collapsed").SetProp("Panel.ZIndex", "100").Cursor("Arrow")
    .On("PreviewMouseDown", (*) => ToggleSidebar(currentSidebarView))

editorArea.Rows("Auto", "*")

; Tabs Container
topBarGrid := editorArea.Add("Grid").Grid_Row(0).Background("{DynamicResource SolidControl}")
topBarGrid.Cols("*", "Auto")

tabsScroll := topBarGrid.Add("ScrollViewer").Name("tabsScroll").Grid_Column(0).HorizontalScrollBarVisibility("Auto").VerticalScrollBarVisibility("Disabled")
tabsBar := tabsScroll.Add("StackPanel").Orientation("Horizontal")

; 2. Sidebar (Explorer)
sidebar := mainArea.Add("Border").Name("SidebarPanel").Grid_Column(1).HorizontalAlignment("Left").Width("250").Background("{DynamicResource SolidSidebar}").BorderBrush("{DynamicResource SolidBorder}").BorderThickness("0,0,1,0").SetProp("Panel.ZIndex", "5")
sidebar.Add("Border.RenderTransform").Add("TranslateTransform").SetProp("x:Name", "SidebarTranslate").X("0")

sidebar.InjectResources('
(
    <Storyboard x:Key="AnimSlideIn">
        <DoubleAnimation Storyboard.TargetName="SidebarTranslate" Storyboard.TargetProperty="X" To="0" Duration="0:0:0.2">
            <DoubleAnimation.EasingFunction><ExponentialEase EasingMode="EaseOut" Exponent="4"/></DoubleAnimation.EasingFunction>
        </DoubleAnimation>
    </Storyboard>
    <Storyboard x:Key="AnimSlideOut">
        <DoubleAnimation Storyboard.TargetName="SidebarTranslate" Storyboard.TargetProperty="X" To="-250" Duration="0:0:0.2">
            <DoubleAnimation.EasingFunction><ExponentialEase EasingMode="EaseOut" Exponent="4"/></DoubleAnimation.EasingFunction>
        </DoubleAnimation>
    </Storyboard>
    <Storyboard x:Key="AnimSnapIn">
        <DoubleAnimation Storyboard.TargetName="SidebarTranslate" Storyboard.TargetProperty="X" To="0" Duration="0:0:0"/>
    </Storyboard>
)')

sidebarGrid := sidebar.Add("Grid")
sidebarGrid.Rows("Auto", "*")

sidebarGrid.Add("TextBlock").Name("SidebarTitle").Text("EXPLORER").Grid_Row(0).Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("SemiBold").Margin("20,15,0,10")

; Explorer View
sideExplorer := sidebarGrid.Add("StackPanel").Name("View_EXPLORER").Grid_Row(1)
sideExplorer.Add("TextBlock").Text("V AHK-XAML").Foreground("{DynamicResource TextMain}").FontWeight("Bold").FontSize(12).Margin("10,5,0,5")

; AddFileNode moved to Example_MockData

Example_MockData.AddFileNode(sideExplorer, 20, 0xE8B7, "#E3C93A", "lib", "Folder_Lib")
Example_MockData.AddFileNode(sideExplorer, 40, 0xE8A5, "#E34F26", "XAML_GUI.ahk", "XAML_GUI")
Example_MockData.AddFileNode(sideExplorer, 40, 0xE8A5, "#E34F26", "XAML_Components.ahk", "XAML_Components", false, true)
Example_MockData.AddFileNode(sideExplorer, 20, 0xE8B7, "#E3C93A", "examples", "Folder_Examples")
Example_MockData.AddFileNode(sideExplorer, 40, 0xE8A5, "#E34F26", "example_clone_vscode.ahk", "Main", true)
Example_MockData.AddFileNode(sideExplorer, 40, 0xE8A5, "#E34F26", "example_clone_chat.ahk", "Chat")
Example_MockData.AddFileNode(sideExplorer, 40, 0xE713, "#AAAAAA", "settings.ini", "Settings_Ini")

; Search View
sideSearch := sidebarGrid.Add("StackPanel").Name("View_SEARCH").Grid_Row(1).Visibility("Collapsed").Margin("10,5")
sideSearch.Add("TextBox").Text("Search").Background("{DynamicResource SolidControl}").Foreground("{DynamicResource TextSub}").BorderThickness("1").BorderBrush("{DynamicResource Accent}").Padding("5")

; Source Control View
sideGit := sidebarGrid.Add("StackPanel").Name("View_SOURCE_CONTROL").Grid_Row(1).Visibility("Collapsed").Margin("10,5")
sideGit.Add("TextBlock").Text("No source control providers registered.").Foreground("{DynamicResource TextSub}").TextWrapping("Wrap")

; Run View
sideRun := sidebarGrid.Add("StackPanel").Name("View_RUN_AND_DEBUG").Grid_Row(1).Visibility("Collapsed").Margin("10,5")
sideRun.Add("Button").Content("Run and Debug").Background("{DynamicResource Accent}").Foreground("{DynamicResource TextMain}").Padding("5").BorderThickness("0")

; Extensions View
sideExt := sidebarGrid.Add("StackPanel").Name("View_EXTENSIONS").Grid_Row(1).Visibility("Collapsed").Margin("10,5")
sideExt.Add("TextBox").Text("Search Extensions in Marketplace").Background("{DynamicResource SolidControl}").Foreground("{DynamicResource TextSub}").BorderThickness("1").BorderBrush("Transparent").Padding("5")

; Settings View has been moved to the Editor Area as a Tab

; ... Editor Area UI generated above ...

global currentThemeMap := Map("BgColor", "#1E1E1E", "ControlBg", "#333333", "Accent", "#007ACC", "ControlBorder", "#2D2D2D", "TextMain", "White", "TextSub", "#CCCCCC", "SolidBg", "#1E1E1E", "SolidSidebar", "#252526", "SolidControl", "#333333", "SolidBorder", "#2D2D2D")

; AddTab moved to Example_MockData

Example_MockData.AddTab(tabsBar, 0xE8A5, "#E34F26", "example_clone_vscode.ahk", "Main", true, true)
Example_MockData.AddTab(tabsBar, 0xE8A5, "#E34F26", "XAML_GUI.ahk", "XAML_GUI", false, true)
Example_MockData.AddTab(tabsBar, 0xEA86, "#519ABA", "README.md", "README", false, true)
Example_MockData.AddTab(tabsBar, 0xE8A5, "#E34F26", "XAML_Components.ahk", "XAML_Components", false, false)
Example_MockData.AddTab(tabsBar, 0xE8A5, "#E34F26", "example_clone_chat.ahk", "Chat", false, false)
Example_MockData.AddTab(tabsBar, 0xE713, "#AAAAAA", "settings.ini", "Settings_Ini", false, false)
Example_MockData.AddTab(tabsBar, 0xE713, "#AAAAAA", "Settings", "Settings", false, false)

; Right Side Tab Actions
tabActions := topBarGrid.Add("StackPanel").Grid_Column(1).Orientation("Horizontal").Margin("0,0,10,0").HorizontalAlignment("Right")
tabActions.Add("Button").Content(Chr(0xE718)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Background("Transparent").BorderThickness("0").Foreground("{DynamicResource TextSub}").FontSize(14).Margin("5,0")
tabActions.Add("Button").Content(Chr(0xE72D)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Background("Transparent").BorderThickness("0").Foreground("{DynamicResource TextSub}").FontSize(14).Margin("5,0")

; Text Editor Area
codeEditor := editorArea.Add("Border").Grid_Row(1).Background("{DynamicResource SolidBg}")
codeEditor.Add("TextBox").Name("MainTextBox").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness("0").FontFamily("Consolas").FontSize(14).AcceptsReturn("True").Padding("20").VerticalContentAlignment("Top")

; Error Screen (Not Found)
errorScreen := editorArea.Add("Grid").Name("ErrorScreen").Grid_Row(1).Visibility("Collapsed").Background("{DynamicResource SolidBg}")
errSp := errorScreen.Add("StackPanel").VerticalAlignment("Center").HorizontalAlignment("Center")
errSp.Add("TextBlock").Text(Chr(0xEA39)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(64).Foreground("{DynamicResource ErrorColor}").HorizontalAlignment("Center").Margin("0,0,0,20")
errSp.Add("TextBlock").Text("The editor could not be opened because the file was not found.").Foreground("{DynamicResource TextSub}").FontSize(16).HorizontalAlignment("Center")

; INI Settings Viewer (Custom Interactive Dummy File)
iniEditorScreen := editorArea.Add("Grid").Name("IniEditorScreen").Grid_Row(1).Visibility("Collapsed").Background("{DynamicResource SolidBg}")
iniScroll := iniEditorScreen.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").Padding("20")
iniSp := iniScroll.Add("StackPanel").Margin("10")
iniSp.Add("TextBlock").Text("SETTINGS CONFIGURATION").FontSize(22).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,25")

; Uses Example_MockData.AddIniField

Example_MockData.AddIniField(iniSp, "Window DWM Mode", "2,1")
Example_MockData.AddIniField(iniSp, "Background Color (Hex)", "#90111114")
Example_MockData.AddIniField(iniSp, "Sidebar Color (Hex)", "#30000000")
Example_MockData.AddIniField(iniSp, "Text Main (Hex)", "#FFFFFF")
Example_MockData.AddIniField(iniSp, "Accent Color (Hex)", "#0A84FF")
iniSp.Add("Button").Content("Save Configuration").Background("{DynamicResource Accent}").Foreground("{DynamicResource TextMain}").Padding("15,10").BorderThickness("0").Margin("0,15,0,0").HorizontalAlignment("Left").Cursor("Hand")

; Settings Tab Screen
settingsScreen := editorArea.Add("Grid").Name("SettingsScreen").Grid_Row(1).Visibility("Collapsed").Background("{DynamicResource SolidBg}")
setScroll := settingsScreen.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").Padding("30")
setSp := setScroll.Add("StackPanel")
setSp.Add("TextBlock").Text("Settings").FontSize(24).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,30")

setSp.Add("TextBlock").Text("APPEARANCE").Foreground("{DynamicResource TextSub}").FontSize(12).FontWeight("SemiBold").Margin("0,0,0,10")
themeCb := setSp.Add("ComboBox").Name("AppThemeCb").Margin("0,0,0,20").Width("300").HorizontalAlignment("Left")
    .On("SelectionChanged", ChangeTheme)
    .Track()

try {
    iniPath := FileExist("themes.ini") ? "themes.ini" : "../themes.ini"
    Loop Parse, IniRead(iniPath), "`n", "`r"
        themeCb.Add("ComboBoxItem").Content(A_LoopField)
}
themeCb.SelectedIndex(0)

; 4. Status Bar (Bottom)
statusBar := layout.Add("Grid").Grid_Row(1).Background("{DynamicResource Accent}")
statusBar.Cols("Auto", "*", "Auto")

statusLeft := statusBar.Add("StackPanel").Grid_Column(0).Orientation("Horizontal").Margin("10,0")
statusLeft.Add("TextBlock").Text(Chr(0xE83D)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("0,0,5,0")
statusLeft.Add("TextBlock").Text("main*").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("0,0,15,0")
statusLeft.Add("TextBlock").Text(Chr(0xE814) " 0  " Chr(0xE711) " 0").FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets, Segoe UI").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("0,0,15,0")

statusRight := statusBar.Add("StackPanel").Grid_Column(2).Orientation("Horizontal").Margin("10,0")
statusRight.Add("TextBlock").Text("Ln 15, Col 42").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("15,0,0,0")
statusRight.Add("TextBlock").Text("Spaces: 4").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("15,0,0,0")
statusRight.Add("TextBlock").Text("UTF-8").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("15,0,0,0")
statusRight.Add("TextBlock").Text("CRLF").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("15,0,0,0")
statusRight.Add("TextBlock").Text("AutoHotkey").Foreground("White").FontSize(12).VerticalAlignment("Center").Margin("15,0,0,0")

; Command Palette Component
cmdPalette := app.overlay.CommandPalette("CmdPal")
cmdPalette.Hotkey("^+P")
Example_MockData.PopulateVSCodeCommandPalette(cmdPalette)

cmdPalette.DefineProp("OnCommandSelected", { Call: HandleCommand })
HandleCommand(this, id) {
    global ui, currentThemeMap
    theme := "Dark Mica (Win 11)"
    owner := ui.wpfHwnd

    if (id == "settings") {
        SelectTab("Settings")
    } else if (id == "toggle_sidebar") {
        ToggleSidebarMode()
    } else if (id == "reload") {
        res := XDialog.Show({ Title: "Reload Window", Message: "Are you sure you want to reload the window? Any unsaved changes will be lost.", Icon: Chr(0xE72C), IconColor: "#FF9F0A", Buttons: ["Reload", "Cancel"], Width: 420, Modal: true, Owner: owner, Theme: theme })
        if (res.Button == "Reload")
            Reload()
    } else if (id == "terminal") {
        XDialog.Show({ Title: "Terminal Created", Message: "A new integrated terminal has been created.", Icon: Chr(0xE756), IconColor: "#32D74B", Buttons: ["OK"], Width: 380, Modal: true, Owner: owner, Theme: theme })
    } else if (id == "file_new") {
        XDialog.Show({ Title: "New File", Message: "A new untitled file has been created in the editor.", Icon: Chr(0xE8A5), IconColor: "{DynamicResource Accent}", Buttons: ["OK"], Width: 380, Modal: true, Owner: owner, Theme: theme })
    } else if (id == "file_save" || id == "file_saveas") {
        XDialog.Show({ Title: "File Saved", Message: "Your file has been saved successfully.", Icon: Chr(0xE74E), IconColor: "#32D74B", Buttons: ["OK"], Width: 350, Modal: true, Owner: owner, Theme: theme })
    } else if (id == "help_welcome") {
        XDialog.Show({ Title: "Welcome to VS Code Clone", Message: "This is a demo application built with the AHK-XAML framework.`n`nFeatures:`n• Full command palette with keyboard navigation`n• Theme switching`n• Tabbed editor with file tree`n• Modal dialogs via XDialog", Icon: Chr(0xE897), IconColor: "{DynamicResource Accent}", Buttons: ["OK"], Width: 500, Modal: true, Owner: owner, Theme: theme })
    } else if (id == "help_about") {
        XDialog.Show({ Title: "About", Message: "VS Code Clone`nBuilt with AHK-XAML Framework`n`nA demonstration of the XCommandPalette component.", Icon: Chr(0xE946), IconColor: "{DynamicResource Accent}", Buttons: ["OK"], Width: 400, Modal: true, Owner: owner, Theme: theme })
    } else {
        ; Generic handler for any other command
        XDialog.Show({ Title: "Command Executed", Message: "Successfully ran: " id, Icon: Chr(0xE73E), IconColor: "#32D74B", Buttons: ["OK"], Width: 380, Modal: true, Owner: owner, Theme: theme })
    }
}

; Compile UI
ui := app.Compile()

HotIfWinActive("VS Code Clone - AHK-XAML")
Hotkey("^b", ToggleSidebarMode, "On")  ; Ctrl+B
HotIf()

; Populate Editor Content
global fileKeys := ["Main", "XAML_GUI", "README", "XAML_Components", "Chat", "Settings_Ini", "Settings"]
global filesData := Example_MockData.GetVSCodeFilesData()

global openTabs := ["Main", "XAML_GUI", "README"]
global currentTab := "Main"

UpdateActivityHighlights(viewName) {
    global currentThemeMap, currentTab
    acts := Map("EXPLORER", "BtnActExplorer", "SEARCH", "BtnActSearch", "SOURCE CONTROL", "BtnActSourceControl", "RUN AND DEBUG", "BtnActRun", "EXTENSIONS", "BtnActExtensions")

    for v, btnName in acts {
        isActive := (v == viewName)
        fg := isActive ? currentThemeMap["TextMain"] : currentThemeMap["TextSub"]
        brd := isActive ? currentThemeMap["TextMain"] : "Transparent"

        ui.Update(btnName, "Foreground", fg)
        ui.Update(btnName, "BorderBrush", brd)
    }

    ; Update and highlight bottom icons based on current theme and tab
    isSettingsActive := (currentTab == "Settings")
    ui.Update("BtnActSettings", "Foreground", isSettingsActive ? currentThemeMap["TextMain"] : currentThemeMap["TextSub"])
    ui.Update("BtnActSettings", "BorderBrush", isSettingsActive ? currentThemeMap["TextMain"] : "Transparent")
    ui.Update("BtnActAccounts", "Foreground", currentThemeMap["TextSub"])
}

global sidebarMode := "Fixed"
global sidebarOpen := true
global currentSidebarView := "EXPLORER"

ApplySidebarState() {
    global sidebarMode, sidebarOpen

    if (sidebarMode == "Fixed") {
        ui.Update("EditorArea", "Margin", sidebarOpen ? "250,0,0,0" : "0,0,0,0")
        ui.Update("SidebarPanel", "BeginStoryboard", "AnimSnapIn")
        ui.Update("SidebarPanel", "Visibility", sidebarOpen ? "Visible" : "Collapsed")
        ui.Update("EditorScrim", "Visibility", "Collapsed")
    } else {
        ui.Update("EditorArea", "Margin", "0,0,0,0")
        ui.Update("SidebarPanel", "Visibility", "Visible")

        if (sidebarOpen) {
            ui.Update("SidebarPanel", "BeginStoryboard", "AnimSlideIn")
            ui.Update("EditorScrim", "Visibility", "Visible")
        } else {
            ui.Update("SidebarPanel", "BeginStoryboard", "AnimSlideOut")
            ui.Update("EditorScrim", "Visibility", "Collapsed")
        }
    }
}

ToggleSidebarMode(*) {
    global sidebarMode, sidebarOpen

    if (sidebarMode == "Fixed") {
        sidebarMode := "Hidden"
        sidebarOpen := false
    } else {
        sidebarMode := "Fixed"
        sidebarOpen := true
    }

    ApplySidebarState()
}

ToggleSidebar(viewName) {
    global sidebarOpen, currentSidebarView, sidebarMode

    if (sidebarOpen && currentSidebarView == viewName) {
        if (sidebarMode == "Fixed") {
            ; In Fixed mode, clicking the active icon should do nothing (always available)
            return
        }
        sidebarOpen := false
        UpdateActivityHighlights("")
    } else {
        sidebarOpen := true
        currentSidebarView := viewName

        ui.Update("SidebarTitle", "Text", viewName)

        views := ["EXPLORER", "SEARCH", "SOURCE_CONTROL", "RUN_AND_DEBUG", "EXTENSIONS"]
        for v in views {
            ui.Update("View_" v, "Visibility", (v == StrReplace(viewName, " ", "_")) ? "Visible" : "Collapsed")
        }

        UpdateActivityHighlights(viewName)
    }
    ApplySidebarState()
}

global lastClickTime := 0
global lastClickCtrl := ""
ActivityIconClicked(viewName, state, ctrlName, event) {
    global lastClickTime, lastClickCtrl

    if (ctrlName == lastClickCtrl && A_TickCount - lastClickTime < 400) {
        lastClickTime := 0
        ToggleSidebarMode()
        return
    }

    lastClickTime := A_TickCount
    lastClickCtrl := ctrlName

    ToggleSidebar(viewName)
}

ui.OnEvent("BtnActExplorer", "Click", ObjBindMethod(ActivityIconClicked, "Call", "EXPLORER"))
ui.OnEvent("BtnActSearch", "Click", ObjBindMethod(ActivityIconClicked, "Call", "SEARCH"))
ui.OnEvent("BtnActSourceControl", "Click", ObjBindMethod(ActivityIconClicked, "Call", "SOURCE CONTROL"))
ui.OnEvent("BtnActRun", "Click", ObjBindMethod(ActivityIconClicked, "Call", "RUN AND DEBUG"))
ui.OnEvent("BtnActExtensions", "Click", ObjBindMethod(ActivityIconClicked, "Call", "EXTENSIONS"))

ui.OnEvent("BtnActSettings", "Click", (*) => SelectTab("Settings"))
ui.Track("EditorScrim") ; Needed for mouse down


; Tab Switching Logic
SelectTab(tabName) {
    global openTabs, currentTab, fileKeys, filesData, currentThemeMap

    ; Add to open tabs if not open
    isOpen := false
    for t in openTabs {
        if (t == tabName)
            isOpen := true
    }
    if (!isOpen) {
        openTabs.Push(tabName)
        ui.Update("BtnTab_" tabName, "Visibility", "Visible")
    }

    currentTab := tabName

    ; Update Visuals
    for t in fileKeys {
        isSelected := (t == tabName)

        ; Extract active/inactive colors from the global map instead of sending raw "{DynamicResource}"
        ; since the XAML framework might not dynamically re-resolve it via ui.Update
        bgCol := isSelected ? currentThemeMap["SolidBg"] : currentThemeMap["SolidControl"]
        brdCol := isSelected ? currentThemeMap["Accent"] : "Transparent"
        txtCol := isSelected ? currentThemeMap["TextMain"] : currentThemeMap["TextSub"]

        ui.Update("BtnTab_" t, "Background", bgCol)
        ui.Update("BtnTab_" t, "BorderBrush", brdCol)
        ui.Update("TxtTab_" t, "Foreground", txtCol)

        if (t != "README" && t != "Settings") {
            ui.Update("BtnNode_" t, "Background", isSelected ? currentThemeMap["SolidBorder"] : "Transparent")
            ui.Update("TxtNode_" t, "Foreground", txtCol)
        }
    }

    ; Auto-scroll to the selected tab
    ui.Update("BtnTab_" tabName, "BringIntoView", "")

    ; Toggle Panes
    type := filesData[tabName].type
    ui.Update("MainTextBox", "Visibility", type == "code" ? "Visible" : "Collapsed")
    ui.Update("ErrorScreen", "Visibility", type == "error" ? "Visible" : "Collapsed")
    ui.Update("IniEditorScreen", "Visibility", type == "ini" ? "Visible" : "Collapsed")
    ui.Update("SettingsScreen", "Visibility", type == "settings" ? "Visible" : "Collapsed")

    if (type == "code") {
        ui.Update("MainTextBox", "Text", filesData[tabName].text)
    }
    UpdateActivityHighlights(currentSidebarView)
}

CloseTab(tabName) {
    global openTabs, currentTab

    ; Remove from openTabs
    newOpenTabs := []
    for t in openTabs {
        if (t != tabName)
            newOpenTabs.Push(t)
    }
    openTabs := newOpenTabs

    ui.Update("BtnTab_" tabName, "Visibility", "Collapsed")

    ; Handle focus switch if closing current tab
    if (currentTab == tabName) {
        if (openTabs.Length > 0) {
            SelectTab(openTabs[openTabs.Length])
        } else {
            currentTab := ""
            ui.Update("MainTextBox", "Text", "")
            ui.Update("MainTextBox", "Visibility", "Visible")
            ui.Update("ErrorScreen", "Visibility", "Collapsed")
            ui.Update("IniEditorScreen", "Visibility", "Collapsed")
            ui.Update("SettingsScreen", "Visibility", "Collapsed")
            for t in fileKeys {
                if (t != "README" && t != "Settings") {
                    ui.Update("BtnNode_" t, "Background", "Transparent")
                    ui.Update("TxtNode_" t, "Foreground", "{DynamicResource TextSub}")
                }
            }
        }
    }
    UpdateActivityHighlights(currentSidebarView)
}

; Helper for Color Blending
BlendColor(fg, bg) {
    fg := StrReplace(fg, "#", "")
    if (StrLen(fg) == 6)
        fg := "FF" fg

    bg := StrReplace(bg, "#", "")
    if (StrLen(bg) == 6)
        bg := "FF" bg

    a_fg := Integer("0x" SubStr(fg, 1, 2)) / 255.0
    r_fg := Integer("0x" SubStr(fg, 3, 2))
    g_fg := Integer("0x" SubStr(fg, 5, 2))
    b_fg := Integer("0x" SubStr(fg, 7, 2))

    r_bg := Integer("0x" SubStr(bg, 3, 2))
    g_bg := Integer("0x" SubStr(bg, 5, 2))
    b_bg := Integer("0x" SubStr(bg, 7, 2))

    r_out := Round(r_fg * a_fg + r_bg * (1 - a_fg))
    g_out := Round(g_fg * a_fg + g_bg * (1 - a_fg))
    b_out := Round(b_fg * a_fg + b_bg * (1 - a_fg))

    return "#FF" Format("{:02X}", r_out) Format("{:02X}", g_out) Format("{:02X}", b_out)
}

IsLightColor(hex) {
    hex := StrReplace(hex, "#", "")
    if (StrLen(hex) == 8)
        hex := SubStr(hex, 3)
    r := Integer("0x" SubStr(hex, 1, 2))
    g := Integer("0x" SubStr(hex, 3, 2))
    b := Integer("0x" SubStr(hex, 5, 2))
    return (r + g + b) > 380
}

; Themes
ChangeTheme(state, ctrl, event) {
    global currentThemeMap
    if !state.Has("AppThemeCb")
        return

    theme := state["AppThemeCb"]
    try {
        iniPath := FileExist("themes.ini") ? "themes.ini" : "../themes.ini"
        themeData := IniRead(iniPath, theme)
        
        themeKeys := Map()
        Loop Parse, themeData, "`n", "`r" {
            parts := StrSplit(A_LoopField, "=", " `t", 2)
            if (parts.Length == 2) {
                themeKeys[parts[1]] := parts[2]
            }
        }

        if !themeKeys.Has("Resource_TitleBarColor")
            themeKeys["Resource_TitleBarColor"] := "Transparent"
        if !themeKeys.Has("Resource_TitleBarForeground") {
            if themeKeys.Has("Resource_TextMain")
                themeKeys["Resource_TitleBarForeground"] := themeKeys["Resource_TextMain"]
            else
                themeKeys["Resource_TitleBarForeground"] := "#000000"
        }
        if !themeKeys.Has("Resource_WindowBorderBrush")
            themeKeys["Resource_WindowBorderBrush"] := "Transparent"
        if !themeKeys.Has("Resource_WindowBorderThickness")
            themeKeys["Resource_WindowBorderThickness"] := "0"
        if !themeKeys.Has("Resource_TitleBarGradientOpacity")
            themeKeys["Resource_TitleBarGradientOpacity"] := "0"

        tempMap := Map()
        for key, val in themeKeys {
            if (key == "Window_DWM") {
                ui.Update("Window", "DWM", val)
            } else if (InStr(key, "Resource_") == 1) {
                resName := SubStr(key, 10)
                tempMap[resName] := val
                ui.Update("Resource", resName, val)
                currentThemeMap[resName] := val
            }
            if (key == "Resource_TextSub") {
                ui.Update("Resource", "ErrorColor", val)
            }
        }

        ; Generate Solid Colors
        bgColor := tempMap.Has("BgColor") ? tempMap["BgColor"] : "#FF1E1E1E"
        isLight := IsLightColor(bgColor)
        baseBg := isLight ? "#FFFFFFFF" : "#FF000000"

        solidBg := BlendColor(bgColor, baseBg)
        solidSidebar := tempMap.Has("SidebarColor") ? BlendColor(tempMap["SidebarColor"], solidBg) : solidBg
        solidControl := tempMap.Has("ControlBg") ? BlendColor(tempMap["ControlBg"], solidBg) : solidBg
        solidBorder := tempMap.Has("ControlBorder") ? BlendColor(tempMap["ControlBorder"], solidBg) : solidBg

        ui.Update("Resource", "SolidBg", solidBg)
        ui.Update("Resource", "SolidSidebar", solidSidebar)
        ui.Update("Resource", "SolidControl", solidControl)
        ui.Update("Resource", "SolidBorder", solidBorder)

        currentThemeMap["SolidBg"] := solidBg
        currentThemeMap["SolidSidebar"] := solidSidebar
        currentThemeMap["SolidControl"] := solidControl
        currentThemeMap["SolidBorder"] := solidBorder

        ; Refresh tabs to apply new raw colors
        global currentTab
        if (currentTab != "")
            SelectTab(currentTab)
        else
            UpdateActivityHighlights(currentSidebarView)
    } catch {
        ; Do nothing
    }
}

InitApp(*) {
    ChangeTheme(Map("AppThemeCb", "Dark Mica (Win 11)"), "", "")
    SelectTab("Main")
}

ui.OnEvent("AppGrid", "Loaded", InitApp)

; Bind Tab Click Events
for t in fileKeys {
    boundName := t
    ui.OnEvent("BtnTab_" boundName, "MouseLeftButtonUp", ((name, *) => SelectTab(name)).Bind(boundName))
    ui.OnEvent("BtnNode_" boundName, "Click", ((name, *) => SelectTab(name)).Bind(boundName))
    ui.OnEvent("BtnCloseTab_" boundName, "Click", ((name, *) => CloseTab(name)).Bind(boundName))
}

app.Show()