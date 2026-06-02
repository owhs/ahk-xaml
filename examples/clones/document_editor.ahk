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

; --- Power Tools Menu ---
powerToolsMenu := docMenu.AddMenu("Power Tools")
powerToolsMenu.AddItem("Toggle Inspector Sidebar", Chr(0xE8A4), "MenuPowerToggleSidebar", "Ctrl+P")
powerToolsMenu.AddItem("Highlight Style (Heading 1)...", Chr(0xE7E6), "MenuPowerHighlightStyle", "")
powerToolsMenu.AddItem("Run Security Link Audit...", Chr(0xE71B), "MenuPowerLinkAudit", "")
powerToolsMenu.AddItem("Compile Sales Report Table", Chr(0xE71D), "MenuPowerCompileTemplate", "")

; --- Help Menu ---
helpMenu := docMenu.AddMenu("Help")
helpMenu.AddItem("About", Chr(0xE946), "MenuHelpAbout", "")

; === MAIN EDITOR AREA ===
; === MAIN EDITOR AREA ===
editorRoot := innerGrid.Add("Grid").Grid_Row(1)
editorRoot.Cols("*", "Auto")

; The DocumentEditor component: toolbar + rich editor + status bar
global docEditor := editorRoot.DocumentEditor("DocEdit")

; === RIGHT PANEL — Power Tools Sidebar ===
powerSidebar := editorRoot.Add("Border").Name("PowerSidebarBorder").Grid_Column(1).Width(300).Background("{DynamicResource SidebarColor}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1,0,0,0").Visibility("Collapsed")
sidebarGrid := powerSidebar.Add("Grid")
sidebarGrid.Rows("Auto", "Auto", "*")

; Title row
titleGrid := sidebarGrid.Add("Grid").Grid_Row(0).Margin("16,16,16,12")
titleGrid.Cols("*", "Auto")
titleGrid.Add("TextBlock").Text("POWER TOOLS").FontWeight("Bold").FontSize(11).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center")
titleGrid.Add("Button").Name("BtnClosePowerSidebar").Content(Chr(0xE711)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness(0).Cursor("Hand").Grid_Column(1).FontSize(10).Padding("6")

; Selector & Action Buttons
actionsSp := sidebarGrid.Add("StackPanel").Grid_Row(1).Margin("16,0,16,16")
actionsSp.Add("TextBlock").Text("SELECT DOM QUERY").FontSize(10).FontWeight("SemiBold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,6")

selectorCb := actionsSp.Add("ComboBox").Name("PowerSelectorCb").Height(28).Margin("0,0,0,10")
selectorCb.Add("ComboBoxItem").Content("Hyperlinks (Auditrels)").Tag("hyperlinks")
selectorCb.Add("ComboBoxItem").Content("Headings (Outline)").Tag("headings")
selectorCb.Add("ComboBoxItem").Content("Tables (Grid)").Tag("tables")
selectorCb.Add("ComboBoxItem").Content("Paragraphs (Raw)").Tag("paragraphs")
selectorCb.Add("ComboBoxItem").Content("Mixed Fonts (Styles)").Tag("fonts")
selectorCb.SelectedIndex(0)

queryBtn := actionsSp.Add("Button").Name("BtnRunQuery").Content("Query Document DOM").Background("{DynamicResource Accent}").Foreground("White").BorderThickness(0).Padding("8,6").Cursor("Hand").Margin("0,0,0,14")

actionsSp.Add("Border").Height(1).Background("{DynamicResource ControlBorder}").Margin("0,0,0,14")
actionsSp.Add("TextBlock").Text("QUICK ACTIONS").FontSize(10).FontWeight("SemiBold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,8")

; Action row 1: Highlight matching styles
highlightSp := actionsSp.Add("Grid").Margin("0,0,0,10")
highlightSp.Cols("*", "Auto")
highlightStyleCb := highlightSp.Add("ComboBox").Name("PowerHighlightStyleCb").Height(28).Grid_Column(0).Margin("0,0,6,0")
highlightStyleCb.Add("ComboBoxItem").Content("Heading 1").Tag("Heading1")
highlightStyleCb.Add("ComboBoxItem").Content("Heading 2").Tag("Heading2")
highlightStyleCb.Add("ComboBoxItem").Content("Title").Tag("Title")
highlightStyleCb.SelectedIndex(0)
highlightBtn := highlightSp.Add("Button").Name("BtnPowerHighlight").Content("Highlight").Background("Transparent").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).Foreground("{DynamicResource TextMain}").Padding("10,4").Cursor("Hand").Grid_Column(1)

; Action row 2: Link Security Audit
auditSp := actionsSp.Add("Grid").Margin("0,0,0,10")
auditSp.Cols("*", "*")
auditBtn := auditSp.Add("Button").Name("BtnPowerAudit").Content("Audit Links").Background("Transparent").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).Foreground("{DynamicResource TextMain}").Padding("8,4").Cursor("Hand").Grid_Column(0).Margin("0,0,4,0")
upgradeBtn := auditSp.Add("Button").Name("BtnPowerUpgradeLinks").Content("Upgrade HTTPS").Background("Transparent").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).Foreground("{DynamicResource TextMain}").Padding("8,4").Cursor("Hand").Grid_Column(1).Margin("4,0,0,0")

; Action row 3: Dynamic template table compiler
compileBtn := actionsSp.Add("Button").Name("BtnPowerCompile").Content("Compile Sales Report Table").Background("Transparent").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).Foreground("{DynamicResource TextMain}").Padding("8,5").Cursor("Hand").Margin("0,0,0,10")

; Action row 4: Global Font Standardizer
fontSp := actionsSp.Add("Grid").Margin("0,0,0,0")
fontSp.Cols("*", "*", "Auto")
fromFontCb := fontSp.Add("ComboBox").Name("PowerFromFontCb").Height(28).Grid_Column(0).Margin("0,0,4,0")
fromFontCb.Add("ComboBoxItem").Content("(Scan Fonts)").Tag("none")
fromFontCb.SelectedIndex(0)

toFontCb := fontSp.Add("ComboBox").Name("PowerToFontCb").Height(28).Grid_Column(1).Margin("4,0,4,0")
for f in ["Segoe UI", "Calibri", "Arial", "Times New Roman", "Consolas", "Georgia"] {
    toFontCb.Add("ComboBoxItem").Content(f).Tag(f)
}
toFontCb.SelectedIndex(0)

standardizeBtn := fontSp.Add("Button").Name("BtnPowerStandardizeFont").Content("Standardize").Background("Transparent").BorderBrush("{DynamicResource ControlBorder}").BorderThickness(1).Foreground("{DynamicResource TextMain}").Padding("8,4").Cursor("Hand").Grid_Column(2).Margin("4,0,0,0")

actionsSp.Add("Border").Height(1).Background("{DynamicResource ControlBorder}").Margin("0,14,0,0")

; Results List
resultsSp := sidebarGrid.Add("Grid").Grid_Row(2).Margin("16,0,16,16")
resultsSp.Rows("Auto", "*")
resultsSp.Add("TextBlock").Text("QUERY RESULTS").FontSize(10).FontWeight("SemiBold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,8").Grid_Row(0)

resultsSv := resultsSp.Add("ScrollViewer").Grid_Row(1).VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled")
resultsContainer := resultsSv.Add("StackPanel").Name("PowerResultsContainer")
resultsContainer.Add("TextBlock").Text("No query run yet. Choose a query and click 'Query Document DOM' to inspect structure.").Foreground("{DynamicResource TextSub}").FontSize(11).FontStyle("Italic").TextWrapping("Wrap")

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
ui.OnEvent("DocEdit_BtnNew", "Click", (*) => DoNewDocument())
ui.OnEvent("DocEdit", "DocumentLoaded", OnDocumentLoaded)
ui.OnEvent("DocEdit", "DocumentSaved", OnDocumentSaved)

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

; --- Power Tools ---
ui.OnEvent("MenuPowerToggleSidebar", "Click", (*) => TogglePowerSidebar())
ui.OnEvent("MenuPowerHighlightStyle", "Click", (*) => docEditor.HighlightStyle("Heading1", "Yellow"))
ui.OnEvent("MenuPowerLinkAudit", "Click", (*) => docEditor.AuditLinks())
ui.OnEvent("MenuPowerCompileTemplate", "Click", (*) => CompileSalesReport())

; --- Power Sidebar Controls ---
ui.Track("PowerSelectorCb")
ui.Track("PowerHighlightStyleCb")
ui.Track("PowerFromFontCb")
ui.Track("PowerToFontCb")
ui.OnEvent("BtnClosePowerSidebar", "Click", (*) => TogglePowerSidebar())
ui.OnEvent("BtnRunQuery", "Click", (state, *) => RunSelectorQuery(state))
ui.OnEvent("BtnPowerHighlight", "Click", (state, *) => RunHighlightStyle(state))
ui.OnEvent("BtnPowerAudit", "Click", (*) => docEditor.AuditLinks())
ui.OnEvent("BtnPowerUpgradeLinks", "Click", (*) => UpgradeHttpLinks())
ui.OnEvent("BtnPowerCompile", "Click", (*) => CompileSalesReport())
ui.OnEvent("BtnPowerStandardizeFont", "Click", (state, *) => RunStandardizeFont(state))

; --- Power Bridge Event Routing ---
ui.OnEvent("DocEdit", "PowerQueryDone", PowerQueryReceived)
ui.OnEvent("DocEdit", "PowerAuditDone", PowerAuditReceived)
ui.OnEvent("DocEdit", "PowerToolsError", PowerToolsErrorReceived)

; ============================================================================
; KEYBOARD SHORTCUTS
; ============================================================================
HotIf (*) => (IsSet(ui) && ui && WinActive("ahk_id " ui.wpfHwnd))
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
Hotkey("^p", (*) => TogglePowerSidebar())
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
        SplitPath(docEditor.filePath, , , , &fn)
        UpdateTitle(fn)
        SetStatus("Opened")
        SetTimer(() => docEditor.GetWordCount(), -500)
    }
}

DoSave() {
    docEditor._SaveFile()
    if (docEditor.filePath != "") {
        SplitPath(docEditor.filePath, , , , &fn)
        UpdateTitle(fn)
        SetStatus("Saved")
    }
}

DoSaveAs() {
    docEditor._SaveFileAs()
    if (docEditor.filePath != "") {
        SplitPath(docEditor.filePath, , , , &fn)
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
IsDocEditorActive() => (IsSet(ui) && ui && WinActive("ahk_id " ui.wpfHwnd))
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
    global app, ui
    app.title := name
    ui.Update("AppTitle", "Text", name)
    ui.Update("InfoFileName", "Text", name)
    ui.Update("Window", "Title", name)
}

OnDocumentLoaded(state, ctrl, event) {
    global docEditor
    if (docEditor.filePath != "") {
        SplitPath(docEditor.filePath, , , , &fn)
        UpdateTitle(fn)
    } else {
        UpdateTitle("Untitled document")
    }
}

OnDocumentSaved(state, ctrl, event) {
    global docEditor
    if (docEditor.filePath != "") {
        SplitPath(docEditor.filePath, , , , &fn)
        UpdateTitle(fn)
    }
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
            ui.Update("OutlineGo_" blockIdx, "BindEvent", "Click")
            ui.OnEvent("OutlineGo_" blockIdx, "Click", (*) => docEditor._Cmd("GoToBlock", blockIdx))
        }
    }
}

; ============================================================================
; POWER TOOLS FUNCTIONS
; ============================================================================
global powerSidebarVisible := false
global auditedLinks := Map()

TogglePowerSidebar() {
    global powerSidebarVisible
    powerSidebarVisible := !powerSidebarVisible
    ui.Update("PowerSidebarBorder", "Visibility", powerSidebarVisible ? "Visible" : "Collapsed")
    if (powerSidebarVisible) {
        ui.Update("PowerSelectorCb", "SelectedIndex", "0")
        docEditor.QueryDOM("hyperlinks")
    }
}

RunSelectorQuery(state := "") {
    selector := "hyperlinks"
    if (IsObject(state) && state.Has("PowerSelectorCb")) {
        val := state["PowerSelectorCb"]
        if (InStr(val, "Hyperlinks"))
            selector := "hyperlinks"
        else if (InStr(val, "Headings"))
            selector := "headings"
        else if (InStr(val, "Tables"))
            selector := "tables"
        else if (InStr(val, "Paragraphs"))
            selector := "paragraphs"
        else if (InStr(val, "Mixed Fonts") || InStr(val, "fonts"))
            selector := "fonts"
        else
            selector := val
    }
    SetStatus("Querying DOM: " selector "...")
    docEditor.QueryDOM(selector)
}

RunHighlightStyle(state := "") {
    styleId := "Heading1"
    if (IsObject(state) && state.Has("PowerHighlightStyleCb")) {
        val := state["PowerHighlightStyleCb"]
        if (InStr(val, "Heading 1") || InStr(val, "Heading1"))
            styleId := "Heading1"
        else if (InStr(val, "Heading 2") || InStr(val, "Heading2"))
            styleId := "Heading2"
        else if (InStr(val, "Title"))
            styleId := "Title"
        else
            styleId := val
    }
    SetStatus("Highlighting style " styleId "...")
    docEditor.HighlightStyle(styleId, "Yellow")
}

RunStandardizeFont(state := "") {
    if (!state.Has("PowerFromFontCb") || !state.Has("PowerToFontCb"))
        return
    fromFont := state["PowerFromFontCb"]
    toFont := state["PowerToFontCb"]

    if (fromFont == "" || fromFont == "(Scan Fonts)" || fromFont == "none") {
        MsgBox("Please choose 'Mixed Fonts' in the dropdown and click 'Query Document DOM' first to scan and detect mixed fonts.", "Font Standardizer")
        return
    }

    SetStatus("Standardizing font from " fromFont " to " toFont "...")
    docEditor.StandardizeFont(fromFont, toFont)
    ; Re-run fonts query after 1 sec to refresh
    SetTimer(() => docEditor.QueryDOM("fonts"), -1200)
}

PowerQueryReceived(state, ctrl, event) {
    payload := state.Has("PowerQueryDone") ? state["PowerQueryDone"] : ""
    if (payload == "")
        return

    parts := StrSplit(payload, "|", , 2)
    if (parts.Length < 2)
        return
    selector := parts[1]
    b64 := parts[2]

    decoded := XAMLHost.Base64Decode(b64)
    ui.Update("PowerResultsContainer", "ClearItems", "")

    if (selector == "fonts") {
        ui.Update("PowerFromFontCb", "ClearItems", "")
    }

    if (decoded == "") {
        ui.Update("PowerResultsContainer", "AddXamlItem", '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Text="No matching elements found in DOM." Foreground="{DynamicResource TextSub}" FontSize="11" FontStyle="Italic"/>')
        if (selector == "fonts") {
            ui.Update("PowerFromFontCb", "AddXamlItem", '<ComboBoxItem xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Content="(None found)" Tag="none"/>')
            ui.Update("PowerFromFontCb", "SelectedIndex", "0")
        }
        return
    }

    lines := StrSplit(decoded, "`n")
    matchCount := 0

    for line in lines {
        if (line == "")
            continue

        matchCount++
        if (selector == "headings") {
            parts2 := StrSplit(line, "|", , 3)
            if (parts2.Length >= 3) {
                pIdx := parts2[1]
                styleId := parts2[2]
                text := parts2[3]

                text := CleanXmlString(text)
                margin := InStr(styleId, "2") ? "12,2,0,2" : (InStr(styleId, "3") ? "24,2,0,2" : "0,2,0,2")

                xaml := '<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Name="PowerGo_' pIdx '" Background="Transparent" BorderThickness="0" Foreground="{DynamicResource TextMain}" Padding="4" Margin="' margin '" Cursor="Hand" HorizontalContentAlignment="Left"><StackPanel Orientation="Horizontal"><TextBlock Text="[' styleId '] " Foreground="{DynamicResource Accent}" FontSize="11" FontWeight="Bold" VerticalAlignment="Center"/><TextBlock Text="' text '" FontSize="11" TextTrimming="CharacterEllipsis" VerticalAlignment="Center"/></StackPanel></Button>'
                ui.Update("PowerResultsContainer", "AddXamlItem", xaml)
                ui.Update("PowerGo_" pIdx, "BindEvent", "Click")
                ui.OnEvent("PowerGo_" pIdx, "Click", (*) => docEditor._Cmd("GoToBlock", "paragraph:" pIdx))
            }
        } else if (selector == "hyperlinks") {
            parts2 := StrSplit(line, "|", , 3)
            if (parts2.Length >= 2) {
                text := parts2[1]
                url := parts2[2]
                relId := parts2.Length >= 3 ? parts2[3] : ""

                text := CleanXmlString(text)
                urlEscaped := CleanXmlString(url)

                isUnsecured := (SubStr(url, 1, 7) = "http://")
                badgeColor := isUnsecured ? "#FF3B30" : "#34C759"
                badgeText := isUnsecured ? "HTTP" : "HTTPS"

                xaml := '<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Background="#0AFFFFFF" CornerRadius="4" Padding="8" Margin="0,0,0,8" BorderBrush="{DynamicResource ControlBorder}" BorderThickness="1"><StackPanel><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBlock Text="' text '" FontWeight="SemiBold" FontSize="11" Foreground="{DynamicResource TextMain}" Grid.Column="0" TextTrimming="CharacterEllipsis"/><Border Background="' badgeColor '" CornerRadius="3" Padding="4,2" Grid.Column="1"><TextBlock Text="' badgeText '" FontSize="9" Foreground="White" FontWeight="Bold"/></Border></Grid><TextBlock Text="' urlEscaped '" FontSize="10" Foreground="{DynamicResource TextSub}" Margin="0,4,0,0" TextTrimming="CharacterEllipsis"/><StackPanel Orientation="Horizontal" Margin="0,6,0,0"><Button Name="PowerOpenLink_' matchCount '" Content="Open URL" Padding="6,3" FontSize="10" Background="Transparent" BorderBrush="{DynamicResource ControlBorder}" BorderThickness="1" Cursor="Hand" Margin="0,0,6,0"/><Button Name="PowerGoLink_' matchCount '" Content="Go to Link" Padding="6,3" FontSize="10" Background="Transparent" BorderBrush="{DynamicResource ControlBorder}" BorderThickness="1" Cursor="Hand"/></StackPanel></StackPanel></Border>'
                ui.Update("PowerResultsContainer", "AddXamlItem", xaml)
                ui.Update("PowerOpenLink_" matchCount, "BindEvent", "Click")
                ui.Update("PowerGoLink_" matchCount, "BindEvent", "Click")
                ui.OnEvent("PowerOpenLink_" matchCount, "Click", (*) => RunUrl(url))
                ui.OnEvent("PowerGoLink_" matchCount, "Click", (*) => docEditor._Cmd("GoToBlock", "hyperlink:" (matchCount - 1)))
            }
        } else if (selector == "tables") {
            parts2 := StrSplit(line, "|", , 4)
            if (parts2.Length >= 3) {
                tIdx := parts2[1]
                rows := parts2[2]
                cols := parts2[3]
                firstCell := parts2.Length >= 4 ? parts2[4] : ""

                firstCell := CleanXmlString(firstCell)

                xaml := '<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Name="PowerTable_' tIdx '" Background="Transparent" BorderThickness="0" Padding="0" Margin="0,0,0,8" Cursor="Hand" HorizontalContentAlignment="Stretch"><Border Background="#0AFFFFFF" CornerRadius="4" Padding="8" BorderBrush="{DynamicResource ControlBorder}" BorderThickness="1" HorizontalAlignment="Stretch"><StackPanel><TextBlock Text="Table #' (tIdx + 1) '" FontWeight="Bold" FontSize="11" Foreground="{DynamicResource TextMain}"/><TextBlock Text="Dimensions: ' rows ' rows x ' cols ' columns" FontSize="10" Foreground="{DynamicResource TextSub}" Margin="0,2,0,0"/><TextBlock Text="Header: ' firstCell '" FontSize="10" FontStyle="Italic" Foreground="{DynamicResource TextSub}" Margin="0,4,0,0"/></StackPanel></Border></Button>'
                ui.Update("PowerResultsContainer", "AddXamlItem", xaml)
                ui.Update("PowerTable_" tIdx, "BindEvent", "Click")
                ui.OnEvent("PowerTable_" tIdx, "Click", (*) => docEditor._Cmd("GoToBlock", "table:" tIdx))
            }
        } else if (selector == "paragraphs") {
            parts2 := StrSplit(line, "|", , 3)
            if (parts2.Length >= 3) {
                pIdx := parts2[1]
                style := parts2[2]
                text := parts2[3]

                text := CleanXmlString(text)
                if (StrLen(text) > 60)
                    text := SubStr(text, 1, 57) "..."

                xaml := '<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Name="PowerPara_' pIdx '" Background="Transparent" BorderThickness="0" Foreground="{DynamicResource TextMain}" Padding="4" Margin="0,2" Cursor="Hand" HorizontalContentAlignment="Left"><StackPanel><TextBlock Text="Paragraph #' (pIdx + 1) ' [' style ']" FontSize="10" Foreground="{DynamicResource Accent}" FontWeight="SemiBold"/><TextBlock Text="' text '" FontSize="11" TextTrimming="CharacterEllipsis"/></StackPanel></Button>'
                ui.Update("PowerResultsContainer", "AddXamlItem", xaml)
                ui.Update("PowerPara_" pIdx, "BindEvent", "Click")
                ui.OnEvent("PowerPara_" pIdx, "Click", (*) => docEditor._Cmd("GoToBlock", "paragraph:" pIdx))
            }
        } else if (selector == "fonts") {
            fName := CleanXmlString(line)

            xaml := '<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Background="#0AFFFFFF" CornerRadius="4" Padding="8" Margin="0,0,0,8" BorderBrush="{DynamicResource ControlBorder}" BorderThickness="1"><StackPanel><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBlock Text="' fName '" FontFamily="' fName '" FontWeight="Bold" FontSize="11" Foreground="{DynamicResource TextMain}" Grid.Column="0"/><Border Background="{DynamicResource Accent}" CornerRadius="3" Padding="4,2" Grid.Column="1"><TextBlock Text="Detected" FontSize="9" Foreground="White" FontWeight="Bold"/></Border></Grid><TextBlock Text="Use the dropdown options above to standardize this typography." FontSize="10" Foreground="{DynamicResource TextSub}" Margin="0,4,0,0"/></StackPanel></Border>'
            ui.Update("PowerResultsContainer", "AddXamlItem", xaml)

            ui.Update("PowerFromFontCb", "AddXamlItem", '<ComboBoxItem xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Content="' fName '" Tag="' fName '"/>')
        }
    }

    if (selector == "fonts" && matchCount > 0) {
        ui.Update("PowerFromFontCb", "SelectedIndex", "0")
    } else if (selector == "fonts") {
        ui.Update("PowerFromFontCb", "AddXamlItem", '<ComboBoxItem xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Content="(None found)" Tag="none"/>')
        ui.Update("PowerFromFontCb", "SelectedIndex", "0")
    }

    SetStatus("Query complete: " matchCount " elements found.")
}

PowerAuditReceived(state, ctrl, event) {
    global auditedLinks
    payload := state.Has("PowerAuditDone") ? state["PowerAuditDone"] : ""
    if (payload == "")
        return

    decoded := XAMLHost.Base64Decode(payload)
    ui.Update("PowerResultsContainer", "ClearItems", "")

    if (decoded == "") {
        ui.Update("PowerResultsContainer", "AddXamlItem", '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Text="No links found to audit." Foreground="{DynamicResource TextSub}" FontSize="11" FontStyle="Italic"/>')
        return
    }

    auditedLinks := Map()
    lines := StrSplit(decoded, "`n")
    matchCount := 0
    unsecureCount := 0

    for line in lines {
        if (line == "")
            continue

        parts := StrSplit(line, "|", , 3)
        if (parts.Length >= 2) {
            relId := parts[1]
            url := parts[2]
            text := parts.Length >= 3 ? parts[3] : url

            matchCount++
            auditedLinks[relId] := url

            isUnsecured := (SubStr(url, 1, 7) = "http://")
            if (isUnsecured)
                unsecureCount++

            badgeColor := isUnsecured ? "#FF3B30" : "#34C759"
            badgeText := isUnsecured ? "HTTP (Danger!)" : "HTTPS (Secure)"

            textEsc := CleanXmlString(text)
            urlEsc := CleanXmlString(url)

            xaml := '<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Background="#05FFFFFF" CornerRadius="4" Padding="8" Margin="0,0,0,8" BorderBrush="' (isUnsecured ? "#FF3B30" : "{DynamicResource ControlBorder}") '" BorderThickness="1"><StackPanel><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBlock Text="' textEsc '" FontWeight="Bold" FontSize="11" Foreground="{DynamicResource TextMain}" Grid.Column="0" TextTrimming="CharacterEllipsis"/><Border Background="' badgeColor '" CornerRadius="3" Padding="4,2" Grid.Column="1"><TextBlock Text="' badgeText '" FontSize="9" Foreground="White" FontWeight="Bold"/></Border></Grid><TextBlock Text="' urlEsc '" FontSize="10" Foreground="{DynamicResource TextSub}" Margin="0,4,0,0" TextTrimming="CharacterEllipsis"/></StackPanel></Border>'
            ui.Update("PowerResultsContainer", "AddXamlItem", xaml)
        }
    }

    statusMsg := "Audited " matchCount " links."
    if (unsecureCount > 0)
        statusMsg .= " Found " unsecureCount " unsecure HTTP links!"
    SetStatus(statusMsg)

    if (unsecureCount > 0) {
        opts := {
            Title: "Hyperlink Security Warning",
            Message: "Security Audit completed.`n`nFound " unsecureCount " unsecured 'http://' hyperlinks in relationships.`n`nWould you like to upgrade them automatically to secure 'https://'?",
            Icon: Chr(0xE7BA),
            Buttons: ["Yes", "No"],
            Owner: ui.wpfHwnd,
            Modal: true
        }
        if (app.HasOwnProp("currentThemeName") && app.currentThemeName != "")
            opts.Theme := app.currentThemeName
        if (app.HasOwnProp("currentIniPath") && app.currentIniPath != "")
            opts.IniPath := app.currentIniPath

        res := XDialog.Show(opts)
        if (res.Button == "Yes" || res.Button == "Upgrade Links") {
            UpgradeHttpLinks()
        }
    } else {
        opts := {
            Title: "Security Audit Clear",
            Message: "Security Audit completed.`n`nAll " matchCount " external hyperlinks are fully secured using HTTPS. No unsecured links found!",
            Icon: Chr(0xE73D),
            Buttons: ["OK"],
            Owner: ui.wpfHwnd,
            Modal: true
        }
        if (app.HasOwnProp("currentThemeName") && app.currentThemeName != "")
            opts.Theme := app.currentThemeName
        if (app.HasOwnProp("currentIniPath") && app.currentIniPath != "")
            opts.IniPath := app.currentIniPath
        XDialog.Show(opts)
    }
}

UpgradeHttpLinks() {
    global auditedLinks
    if (!IsSet(auditedLinks) || auditedLinks.Count == 0) {
        MsgBox("No links have been audited yet! Run 'Audit Links' first.", "Power Tools")
        return
    }

    upgradePayload := ""
    upgradeCount := 0

    for relId, url in auditedLinks {
        if (SubStr(url, 1, 7) = "http://") {
            newUrl := "https://" SubStr(url, 8)
            upgradePayload .= relId "|" newUrl "`n"
            upgradeCount++
        }
    }

    if (upgradeCount == 0) {
        MsgBox("All links are already secure HTTPS! No action needed.", "Security Auditor")
        return
    }

    SetStatus("Upgrading " upgradeCount " links to HTTPS...")
    docEditor.RewriteLinks(upgradePayload)
    SetTimer(() => docEditor.AuditLinks(), -1200)
}

CompileSalesReport() {
    SetStatus("Compiling OpenXML styled table from AHK database payload...")
    data := "Department,Q1 Sales ($),Q2 Sales ($),Growth`n"
        . "North America,125000,143000,+14.4%`n"
        . "Europe & ME,98000,105000,+7.1%`n"
        . "Asia Pacific,162000,194000,+19.7%`n"
        . "Latin America,43000,39000,-9.3%`n"
        . "Total Corporate,428000,481000,+12.3%"
    docEditor.CompileTemplate(data)
}

PowerToolsErrorReceived(state, ctrl, event) {
    errMsg := state.Has("PowerToolsError") ? state["PowerToolsError"] : "Unknown OpenXML error."
    SetStatus("Error: " errMsg)
    XDialog.Show({
        Title: "OpenXML Power Tool Error",
        Message: "An error occurred during OpenXML processing:`n`n" errMsg,
        Icon: Chr(0xE783),
        Buttons: ["OK"],
        Owner: ui.wpfHwnd,
        Modal: true
    })
}

RunUrl(url) {
    try {
        Run(url)
    } catch {
        MsgBox("Failed to open URL: " url)
    }
}

CleanXmlString(str) {
    str := StrReplace(str, "&", "&amp;")
    str := StrReplace(str, '"', "&quot;")
    str := StrReplace(str, "<", "&lt;")
    str := StrReplace(str, ">", "&gt;")
    return str
}

; ============================================================================
; COMMAND LINE: open file if passed as argument
; ============================================================================
if (A_Args.Length > 0 && FileExist(A_Args[1])) {
    docEditor.Open(A_Args[1])
    SplitPath(A_Args[1], , , , &fileName)
    UpdateTitle(fileName)
}

app.Show()
return