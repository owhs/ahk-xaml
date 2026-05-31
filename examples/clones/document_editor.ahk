; ==============================================================================
; Document Editor — Google Docs-Inspired Clone
; ==============================================================================
; A comprehensive document editor with DOCX/DOC support, rich text formatting,
; tables, images, find/replace, undo/redo, zoom, and a Google Docs-style layout.
;
; Features:
;   ● Full DOCX import (hyperlinks, images, lists, tables, formatting)
;   ● Non-destructive Dark Document Mode (preserves original colors)
;   ● Theme Document Mode
;   ● Responsive toolbar with overflow popover
;   ● Document outline / section navigator
;   ● Insert: Tables, Images, Hyperlinks, Horizontal Rules
;   ● Format: Bold, Italic, Underline, Strikethrough, Alignment
;   ● Edit: Undo, Redo, Find, Replace, Select All
;   ● File: New, Open, Save, Save As, Properties panel (Ctrl+I)
;   ● Collapsible menu bar (Ctrl+M / Alt toggle)
;   ● Keyboard shortcuts for everything
;
; Requirements: XAML_ENABLE_DOCUMENT := true (DLLs auto-download from NuGet)
; ==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "..\..\lib\XAML_Config.ahk"

; Enable the Document Editor component
global XAML_ENABLE_DOCUMENT := true

#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"

global menuBarCollapsed := false
global menuTempShown := false
global currentDocTheme := "Normal"

; --- Build the UI ---
options := Map("Sidebar", true, "BurgerMenu", true, "TitleBarHeight", 36, "MinMaxButtons", true, "AppIcon", true, "WindowState", "Maximized")
global app := XAML_GUI("Untitled document", options)
app.tabs.Visibility("Collapsed")

; === INNER LAYOUT: Menu Bar + Editor ===
innerGrid := app.main.Add("Grid").Grid_Row(1)
innerGrid.Rows("Auto", "*")

; === MENU BAR ===
docMenuBar := innerGrid.Add("Border").Name("MenuBarBorder").Grid_Row(0).Background("{DynamicResource BgColor}").Padding("6,0")
docMenu := docMenuBar.MenuBar("MainMenuBar")

; --- File Menu ---
fileMenu := docMenu.AddMenu("File")
fileMenu.AddItem("New", Chr(0xE8A5), "MenuFileNew", "Ctrl+N")
fileMenu.AddItem("Open...", Chr(0xE8E5), "MenuFileOpen", "Ctrl+O")
fileMenu.AddSeparator()
fileMenu.AddItem("Save", Chr(0xE74E), "MenuFileSave", "Ctrl+S")
fileMenu.AddItem("Save As...", Chr(0xE792), "MenuFileSaveAs", "Ctrl+Shift+S")
fileMenu.AddSeparator()
fileMenu.AddItem("Properties", Chr(0xE946), "MenuFileProps", "Ctrl+I")

; --- Edit Menu ---
editMenu := docMenu.AddMenu("Edit")
editMenu.AddItem("Undo", Chr(0xE7A7), "MenuEditUndo", "Ctrl+Z")
editMenu.AddItem("Redo", Chr(0xE7A6), "MenuEditRedo", "Ctrl+Y")
editMenu.AddSeparator()
editMenu.AddItem("Select All", Chr(0xE8B3), "MenuEditSelectAll", "Ctrl+A")
editMenu.AddSeparator()
editMenu.AddItem("Find...", Chr(0xE721), "MenuEditFind", "Ctrl+F")
editMenu.AddItem("Replace...", Chr(0xE71E), "MenuEditReplace", "Ctrl+H")

; --- View Menu ---
viewMenu := docMenu.AddMenu("View")
viewMenu.AddItem("Show Menu Bar", Chr(0xE700), "MenuViewToggleMenuBar", "Ctrl+M").SetProp("IsCheckable", "True").SetProp("IsChecked", "True")
viewMenu.AddSeparator()
viewMenu.AddItem("Theme Document", Chr(0xE790), "MenuViewThemeDoc", "").SetProp("IsCheckable", "True")
viewMenu.AddItem("Dark Document", Chr(0xE793), "MenuViewDarkDoc", "").SetProp("IsCheckable", "True")
viewMenu.AddSeparator()
viewMenu.AddItem("Feed View (Default)", Chr(0xE8F1), "MenuViewFeed", "").SetProp("IsCheckable", "True").SetProp("IsChecked", "True")
viewMenu.AddItem("Paper View", Chr(0xE8A5), "MenuViewPaper", "").SetProp("IsCheckable", "True")
viewMenu.AddItem("Web View", Chr(0xE774), "MenuViewWeb", "").SetProp("IsCheckable", "True")
viewMenu.AddSeparator()
viewMenu.AddItem("Zoom 100%", "", "MenuViewZoom100", "Ctrl+0")
viewMenu.AddItem("Zoom In", Chr(0xE8A3), "MenuViewZoomIn", "Ctrl++")
viewMenu.AddItem("Zoom Out", Chr(0xE71F), "MenuViewZoomOut", "Ctrl+-")

; --- Insert Menu ---
insertMenu := docMenu.AddMenu("Insert")
insertMenu.AddItem("Image...", Chr(0xEB9F), "MenuInsertImage", "")
insertMenu.AddItem("Table...", Chr(0xE8A4), "MenuInsertTable", "")
insertMenu.AddItem("Hyperlink...", Chr(0xE71B), "MenuInsertLink", "Ctrl+K")
insertMenu.AddSeparator()
insertMenu.AddItem("Horizontal Rule", Chr(0xE738), "MenuInsertHR", "")

; --- Format Menu ---
formatMenu := docMenu.AddMenu("Format")
formatMenu.AddItem("Bold", Chr(0xE8DD), "MenuFormatBold", "Ctrl+B")
formatMenu.AddItem("Italic", Chr(0xE8DB), "MenuFormatItalic", "Ctrl+I")
formatMenu.AddItem("Underline", Chr(0xE8DC), "MenuFormatUnderline", "Ctrl+U")
formatMenu.AddItem("Strikethrough", Chr(0xEDE0), "MenuFormatStrike", "")
formatMenu.AddSeparator()
formatMenu.AddItem("Align Left", Chr(0xE8E4), "MenuFormatAlignLeft", "Ctrl+L")
formatMenu.AddItem("Align Center", Chr(0xE8E3), "MenuFormatAlignCenter", "Ctrl+E")
formatMenu.AddItem("Align Right", Chr(0xE8E2), "MenuFormatAlignRight", "Ctrl+R")
formatMenu.AddItem("Justify", Chr(0xF57E), "MenuFormatJustify", "Ctrl+J")

; --- Tools Menu ---
toolsMenu := docMenu.AddMenu("Tools")
toolsMenu.AddItem("Word Count", Chr(0xE82B), "MenuToolsWordCount", "")

; --- Help Menu ---
helpMenu := docMenu.AddMenu("Help")
helpMenu.AddItem("About", Chr(0xE946), "MenuHelpAbout", "")

; === MAIN EDITOR AREA ===
editorRoot := innerGrid.Add("Grid").Grid_Row(1)

; The DocumentEditor component: toolbar + rich editor + status bar
global docEditor := editorRoot.DocumentEditor("DocEdit")

; === RIGHT FLYOVER — Document Info Panel (Ctrl+I) ===
infoFlyout := XFlyout("DocInfo", "Right", "Overlay", 280, true)
infoFlyout.Build(editorRoot)
infoFlyout.Hotkey("^i")

infoSv := infoFlyout.container.Add("ScrollViewer").VerticalScrollBarVisibility("Auto")
infoSp := infoSv.Add("StackPanel").Margin("20,15")

; --- Panel Header ---
closeRow := infoSp.Add("Grid").Margin("0,0,0,12")
closeRow.Cols("*", "Auto")
closeRow.Add("TextBlock").Text("DOCUMENT").FontSize(13).FontWeight("Bold").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center")
closeRow.Add("Button").Name("BtnCloseInfo").Content(Chr(0xE711)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness(0).Cursor("Hand").Grid_Column(1).FontSize(10).Padding("6")

; --- File Info Section ---
infoSp.Add("Border").Height(1).Background("{DynamicResource ControlBorder}").Margin("0,0,0,14")
infoSp.Add("TextBlock").Text("FILE INFO").Foreground("{DynamicResource TextSub}").FontSize(10).FontWeight("SemiBold").Margin("0,0,0,10")

infoGrid := infoSp.Add("Grid").Margin("0,0,0,8")
infoGrid.Cols("Auto", "*")
infoGrid.Rows("Auto", "Auto", "Auto", "Auto", "Auto")

for i, info in [{ Label: "File", Name: "InfoFileName", Default: "Untitled.docx" }, { Label: "Words", Name: "InfoWords", Default: "—" }, { Label: "Chars", Name: "InfoChars", Default: "—" }, { Label: "Zoom", Name: "InfoZoom", Default: "100%" }, { Label: "Status", Name: "InfoStatus", Default: "Ready" }] {
    r := i - 1
    infoGrid.Add("TextBlock").Text(info.Label).Foreground("{DynamicResource TextSub}").FontSize(11).Grid_Row(r).Grid_Column(0).Margin("0,0,14,8")
    tb := infoGrid.Add("TextBlock").Name(info.Name).Text(info.Default).Foreground("{DynamicResource TextMain}").FontSize(11).Grid_Row(r).Grid_Column(1).Margin("0,0,0,8").TextTrimming("CharacterEllipsis")
    if (info.Name == "InfoStatus")
        tb.Foreground("{DynamicResource Accent}")
}

infoSp.Add("Border").Height(1).Background("{DynamicResource ControlBorder}").Margin("0,8,0,14")

; --- Quick Actions Section ---
infoSp.Add("TextBlock").Text("ACTIONS").Foreground("{DynamicResource TextSub}").FontSize(10).FontWeight("SemiBold").Margin("0,0,0,10")

for action in [{ Id: "QuickNew", Icon: 0xE8A5, Label: "New Document" }, { Id: "QuickOpen", Icon: 0xE8E5, Label: "Open File..." }, { Id: "QuickSave", Icon: 0xE74E, Label: "Save" }, { Id: "QuickExport", Icon: 0xE792, Label: "Save As..." }] {
    aBtn := infoSp.Add("Button").Name(action.Id).Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness(0).Padding("8,6").Cursor("Hand").HorizontalContentAlignment("Left")
    aSp := aBtn.Add("StackPanel").Orientation("Horizontal")
    aSp.Add("TextBlock").Text(Chr(action.Icon)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(13).VerticalAlignment("Center").Margin("0,0,10,0").Foreground("{DynamicResource Accent}")
    aSp.Add("TextBlock").Text(action.Label).VerticalAlignment("Center").FontSize(12)
}

; === COMPILE ===
global ui := app.Compile()

ui.OnEvent("BtnCloseInfo", "Click", (*) => infoFlyout.Toggle())

; ============================================================================
; EVENT WIRING
; ============================================================================

; --- File ---
ui.OnEvent("MenuFileNew", "Click", (*) => DoNewDocument())
ui.OnEvent("MenuFileOpen", "Click", (*) => DoOpen())
ui.OnEvent("MenuFileSave", "Click", (*) => DoSave())
ui.OnEvent("MenuFileSaveAs", "Click", (*) => DoSaveAs())
ui.OnEvent("MenuFileProps", "Click", (*) => infoFlyout.Toggle())

; --- Edit ---
ui.OnEvent("MenuEditUndo", "Click", (*) => docEditor._Cmd("Undo"))
ui.OnEvent("MenuEditRedo", "Click", (*) => docEditor._Cmd("Redo"))
ui.OnEvent("MenuEditSelectAll", "Click", (*) => docEditor._SelectAll())
ui.OnEvent("MenuEditFind", "Click", (*) => docEditor._FindDialog())
ui.OnEvent("MenuEditReplace", "Click", (*) => docEditor._ReplaceDialog())

; --- View ---
ui.OnEvent("MenuViewToggleMenuBar", "Click", (*) => ToggleMenuBar())
ui.OnEvent("MenuViewThemeDoc", "Click", (*) => ToggleDocTheme("Theme"))
ui.OnEvent("MenuViewDarkDoc", "Click", (*) => ToggleDocTheme("Dark"))
ui.OnEvent("MenuViewFeed", "Click", (*) => TogglePageView("Feed"))
ui.OnEvent("MenuViewPaper", "Click", (*) => TogglePageView("Paper"))
ui.OnEvent("MenuViewWeb", "Click", (*) => TogglePageView("Web"))
ui.OnEvent("MenuViewZoom100", "Click", (*) => docEditor._SetZoom(100))
ui.OnEvent("MenuViewZoomIn", "Click", (*) => docEditor._SetZoom(docEditor.zoom + 10))
ui.OnEvent("MenuViewZoomOut", "Click", (*) => docEditor._SetZoom(docEditor.zoom - 10))

; --- Insert ---
ui.OnEvent("MenuInsertImage", "Click", (*) => docEditor._InsertImage())
ui.OnEvent("MenuInsertTable", "Click", (*) => docEditor._InsertTableDialog())
ui.OnEvent("MenuInsertLink", "Click", (*) => docEditor._InsertLinkDialog())
ui.OnEvent("MenuInsertHR", "Click", (*) => docEditor._Cmd("InsertHR"))

; --- Format ---
ui.OnEvent("MenuFormatBold", "Click", (*) => docEditor._Cmd("Bold"))
ui.OnEvent("MenuFormatItalic", "Click", (*) => docEditor._Cmd("Italic"))
ui.OnEvent("MenuFormatUnderline", "Click", (*) => docEditor._Cmd("Underline"))
ui.OnEvent("MenuFormatStrike", "Click", (*) => docEditor._Cmd("Strikethrough"))
ui.OnEvent("MenuFormatAlignLeft", "Click", (*) => docEditor._Cmd("JustifyLeft"))
ui.OnEvent("MenuFormatAlignCenter", "Click", (*) => docEditor._Cmd("JustifyCenter"))
ui.OnEvent("MenuFormatAlignRight", "Click", (*) => docEditor._Cmd("JustifyRight"))
ui.OnEvent("MenuFormatJustify", "Click", (*) => docEditor._Cmd("JustifyFull"))

; --- Tools ---
ui.OnEvent("MenuToolsWordCount", "Click", (*) => DoWordCount())

; --- Help ---
ui.OnEvent("MenuHelpAbout", "Click", (*) => ShowAbout())

; --- Quick Actions Panel ---
ui.OnEvent("QuickNew", "Click", (*) => DoNewDocument())
ui.OnEvent("QuickOpen", "Click", (*) => DoOpen())
ui.OnEvent("QuickSave", "Click", (*) => DoSave())
ui.OnEvent("QuickExport", "Click", (*) => DoSaveAs())

; ============================================================================
; KEYBOARD SHORTCUTS
; ============================================================================
HotIf (*) => WinActive("ahk_id " ui.wpfHwnd)
Hotkey("^n", (*) => DoNewDocument())
Hotkey("^o", (*) => DoOpen())
Hotkey("^s", (*) => DoSave())
Hotkey("^+s", (*) => DoSaveAs())
Hotkey("^f", (*) => docEditor._FindDialog())
Hotkey("^h", (*) => docEditor._ReplaceDialog())
; Ctrl+A is handled natively by WPF for both RichTextBox and TextBox controls
Hotkey("^k", (*) => docEditor._InsertLinkDialog())
Hotkey("^=", (*) => docEditor._SetZoom(docEditor.zoom + 10))
Hotkey("^-", (*) => docEditor._SetZoom(docEditor.zoom - 10))
Hotkey("^0", (*) => docEditor._SetZoom(100))
Hotkey("^m", (*) => ToggleMenuBar())
HotIf

; ============================================================================
; STATE MANAGEMENT
; ============================================================================
global menuBarCollapsed := false
global menuTempShown := false
global currentDocTheme := "Normal"

; --- Core Actions ---

ToggleDocTheme(mode) {
    global currentDocTheme
    ; Toggle off if already active
    if (currentDocTheme == mode) {
        mode := "Normal"
    }
    
    currentDocTheme := mode
    
    ; Ensure checkboxes reflect truth
    ui.Update("MenuViewThemeDoc", "IsChecked", mode == "Theme" ? "True" : "False")
    ui.Update("MenuViewDarkDoc", "IsChecked", mode == "Dark" ? "True" : "False")
    
    docEditor.SetDocumentTheme(mode)
}

TogglePageView(mode) {
    ui.Update("MenuViewFeed", "IsChecked", mode == "Feed" ? "True" : "False")
    ui.Update("MenuViewPaper", "IsChecked", mode == "Paper" ? "True" : "False")
    ui.Update("MenuViewWeb", "IsChecked", mode == "Web" ? "True" : "False")
    docEditor.SetPageView(mode)
}

ToggleMenuBar() {
    global menuBarCollapsed, menuTempShown
    menuBarCollapsed := !menuBarCollapsed
    ui.Update("MenuViewToggleMenuBar", "IsChecked", menuBarCollapsed ? "False" : "True")
    ui.Update("MenuBarBorder", "Visibility", menuBarCollapsed ? "Collapsed" : "Visible")
    if (!menuBarCollapsed && menuTempShown)
        menuTempShown := false
}

DoNewDocument() {
    global currentDocTheme
    ; Reset theme before clearing document
    if (currentDocTheme != "Normal") {
        currentDocTheme := "Normal"
        docEditor.SetDocumentTheme("Normal")
        ui.Update("MenuViewThemeDoc", "IsChecked", "False")
        ui.Update("MenuViewDarkDoc", "IsChecked", "False")
    }
    docEditor.NewDocument()
    docEditor.filePath := ""
    UpdateTitle("Untitled document")
    SetStatus("New document created")
}

DoOpen() {
    docEditor._OpenFile()
    if (docEditor.filePath != "") {
        SplitPath(docEditor.filePath, &fn)
        UpdateTitle(fn)
        SetStatus("Opened")
        SetTimer(() => docEditor.GetWordCount(), -500)
    }
}

DoSave() {
    docEditor._SaveFile()
    if (docEditor.filePath != "") {
        SplitPath(docEditor.filePath, &fn)
        UpdateTitle(fn)
        SetStatus("Saved")
    }
}

DoSaveAs() {
    docEditor._SaveFileAs()
    if (docEditor.filePath != "") {
        SplitPath(docEditor.filePath, &fn)
        UpdateTitle(fn)
        SetStatus("Saved as " fn)
    }
}

DoWordCount() {
    docEditor.GetWordCount()
    if (!infoFlyout.IsOpen(ui))
        infoFlyout.Toggle()
}

ShowAbout() {
    opts := {
        Title: "About Document Editor",
        Message: "Document Editor`nBuilt with XAML GUI for AutoHotkey`n`nSupports DOCX, RTF, and plain text documents with rich formatting, tables, images, hyperlinks, and more.",
        Icon: Chr(0xE946),
        Buttons: ["OK"],
        Owner: ui ? ui.wpfHwnd : 0,
        Modal: true
    }
    if (app.HasOwnProp("currentThemeName") && app.currentThemeName != "")
        opts.Theme := app.currentThemeName
    if (app.HasOwnProp("currentIniPath") && app.currentIniPath != "")
        opts.IniPath := app.currentIniPath
    XDialog.Show(opts)
}



; --- Alt Key Menu Reveal ---
IsDocEditorActive() => WinActive("ahk_id " ui.wpfHwnd)
#HotIf IsDocEditorActive()
~LAlt:: {
    ; Do nothing on key down — wait for release
}

~LAlt Up:: {
    global menuBarCollapsed, menuTempShown
    if (menuBarCollapsed && !menuTempShown && A_PriorKey == "LAlt") {
        ui.Update("MenuBarBorder", "Visibility", "Visible")
        menuTempShown := true
        SetTimer(AutoHideMenu, -4000)
    }
}

~Escape:: {
    global menuTempShown
    if (menuTempShown) {
        ui.Update("MenuBarBorder", "Visibility", "Collapsed")
        menuTempShown := false
    }
}

~LButton:: {
    global menuTempShown
    if (menuTempShown) {
        SetTimer(CheckMenuHide, -500)
    }
}

AutoHideMenu() {
    global menuBarCollapsed, menuTempShown
    if (menuTempShown) {
        ui.Update("MenuBarBorder", "Visibility", "Collapsed")
        menuTempShown := false
    }
}

CheckMenuHide() {
    global menuBarCollapsed, menuTempShown
    if (menuTempShown) {
        ui.Update("MenuBarBorder", "Visibility", "Collapsed")
        menuTempShown := false
    }
}
#HotIf

; ============================================================================
; HELPERS
; ============================================================================

UpdateTitle(name) {
    app.host.Update("AppTitle", "Text", name)
    ui.Update("InfoFileName", "Text", name)
}

SetStatus(text) {
    ui.Update("InfoStatus", "Text", text)
    ; Auto-clear status after 5 seconds
    SetTimer(ClearStatus, -5000)
}

ClearStatus() {
    try ui.Update("InfoStatus", "Text", "Ready")
}

; ============================================================================
; PERIODIC WORD COUNT + INFO SYNC
; ============================================================================
SetTimer(UpdateWordCount, 3000)
UpdateWordCount() {
    try docEditor.GetWordCount()
}

ui.OnEvent("DocEdit", "WordCount", UpdateInfoPanel)
UpdateInfoPanel(state, ctrl, event) {
    data := state.Has("WordCount") ? state["WordCount"] : ""
    if (data != "") {
        parts := StrSplit(data, ",")
        if (parts.Length >= 2) {
            ui.Update("InfoWords", "Text", parts[1])
            ui.Update("InfoChars", "Text", parts[2])
            ui.Update("InfoZoom", "Text", docEditor.zoom "%")
            ui.Update("DocEdit_WordCount", "Text", "Words: " parts[1] " | Characters: " parts[2])
        }
    }
}

; ============================================================================
; DOCUMENT OUTLINE
; ============================================================================
ui.OnEvent("DocEdit", "Outline", OutlineReceived)
OutlineReceived(state, ctrl, event) {
    outlineData := state.Has("Outline") ? state["Outline"] : ""
    ui.Update("DocEdit_OutlineContainer", "ClearItems", "")

    if (outlineData == "") {
        ui.Update("DocEdit_OutlineContainer", "AddXamlItem", '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Text="No headings found." Foreground="{DynamicResource TextSub}" FontSize="12" FontStyle="Italic" Margin="0,4"/>')
        return
    }

    lines := StrSplit(outlineData, "`n")
    for line in lines {
        if (line == "")
            continue
        parts := StrSplit(line, ",", , 3)
        if (parts.Length >= 3) {
            blockIdx := parts[1]
            level := parts[2]
            text := parts[3]
            text := StrReplace(text, "&", "&amp;")
            text := StrReplace(text, '"', "&quot;")
            text := StrReplace(text, "<", "&lt;")
            text := StrReplace(text, ">", "&gt;")

            margin := (level == "H1") ? "0,4,0,4" : ((level == "H2") ? "12,4,0,4" : ((level == "H3") ? "24,4,0,4" : ((level == "H4") ? "36,4,0,4" : ((level == "H5") ? "48,4,0,4" : "60,4,0,4"))))
            fontSize := (level == "H1") ? "13" : ((level == "H2") ? "12" : "11")
            fontWeight := (level == "H1") ? "Bold" : "Normal"

            xaml := '<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Name="OutlineGo_' blockIdx '" Background="Transparent" BorderThickness="0" Foreground="{DynamicResource TextMain}" Padding="4,2" Margin="' margin '" Cursor="Hand" HorizontalContentAlignment="Left"><TextBlock Text="' text '" FontSize="' fontSize '" FontWeight="' fontWeight '" TextTrimming="CharacterEllipsis"/></Button>'
            ui.Update("DocEdit_OutlineContainer", "AddXamlItem", xaml)
            ui.OnEvent("OutlineGo_" blockIdx, "Click", (*) => docEditor._Cmd("GoToBlock", blockIdx))
        }
    }
}

; ============================================================================
; COMMAND LINE: open file if passed as argument
; ============================================================================
if (A_Args.Length > 0 && FileExist(A_Args[1])) {
    docEditor.Open(A_Args[1])
    SplitPath(A_Args[1], &fileName)
    UpdateTitle(fileName)
}

app.Show()
return