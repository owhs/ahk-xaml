#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_Config.ahk"
global XAML_ENABLE_AVALONEDIT := true

#Include "..\..\lib\XAML_Host.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"
#Include "..\..\lib\XAML_Components.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\data/MockData.ahk"

; Setup standard UI without the built-in sidebar/tabs, so we can use our new NavigationView
options := Map("Sidebar", true, "BurgerMenu", true)
app := XAML_GUI("Advanced Components Showcase", options)
app.tabs.Visibility("Collapsed")

root := app.main.Add("Grid").Grid_Row(1)

; Command Bar
cmdBarBorder := root.Add("Border").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,0,0,1").VerticalAlignment("Top").Padding("10").SetProp("Panel.ZIndex", "10")
cmdBar := cmdBarBorder.CommandBar("TopCmdBar")
cmdBar.AddButton(Chr(0xE74E), "Save State", "BtnSave")
cmdBar.AddButton(Chr(0xE8E5), "Load State", "BtnLoad")
cmdBar.AddSeparator()
cmdBar.AddButton(Chr(0xE711), "Close", "BtnCmdClose")

; Content Area below Command Bar
mainContent := root.Add("Border").Margin("0,55,0,0")

; Navigation View
nav := mainContent.NavigationView("MainNav")

; ---------------------------------------------------------
; PAGE 1: Dashboard (Sparklines & Markdown)
; ---------------------------------------------------------
dashGrid := XAML_Generator("Grid").Margin("0")
dashGrid._Parent := app.X
dashGrid.Rows("Auto", "Auto", "*")

dashGrid.Add("TextBlock").Text("Dashboard Overview").Grid_Row(0).FontSize("24").FontWeight("Light").Foreground("{DynamicResource TextMain}").Margin("0,0,0,20")

metricsSp := dashGrid.Add("StackPanel").Grid_Row(1).Orientation("Horizontal").Margin("0,0,0,20")
card1 := metricsSp.Add("Border").Use("CardPanel").Padding("15").Width("180").Margin("0,0,15,0")
c1sp := card1.Add("StackPanel")
c1sp.Add("TextBlock").Text("SERVER LOAD").Foreground("{DynamicResource TextSub}").FontSize("10").FontWeight("Bold").Margin("0,0,0,10")
c1sp.Sparkline([12, 15, 20, 18, 25, 40, 35, 60, 50, 45, 65, 80], 150, 40, "#FF3333")

card2 := metricsSp.Add("Border").Use("CardPanel").Padding("15").Width("180").Margin("0,0,15,0")
c2sp := card2.Add("StackPanel")
c2sp.Add("TextBlock").Text("USER ACTIVITY").Foreground("{DynamicResource TextSub}").FontSize("10").FontWeight("Bold").Margin("0,0,0,10")
c2sp.Sparkline([100, 110, 105, 120, 115, 130, 140, 135, 150, 160], 150, 40, "#32D74B", "Area")

card3 := metricsSp.Add("Border").Use("CardPanel").Padding("15").Width("180").Margin("0,0,15,0")
c3sp := card3.Add("StackPanel")
c3sp.Add("TextBlock").Text("SYSTEM ERRORS").Foreground("{DynamicResource TextSub}").FontSize("10").FontWeight("Bold").Margin("0,0,0,10")
c3sp.Sparkline([5, 2, 0, 8, 3, 1, 0, 4, 2, 0, 1, 0], 150, 40, "#FFCC00", "Bar")

docBdr := dashGrid.Add("Border").Grid_Row(2).Use("CardPanel").Padding("20")
mdText := Example_MockData.GetMockMarkdownText()
docSp := docBdr.Add("Grid")
docSp.Rows("Auto", "*")

headerSp := docSp.Add("StackPanel").Grid_Row(0).Orientation("Horizontal").Margin("0,0,0,10")
headerSp.Add("TextBlock").Text("Markdown Renderer").Foreground("{DynamicResource TextSub}").FontSize("12").FontWeight("Bold").Margin("0,0,10,0")
headerSp.Add("CheckBox").Name("BtnToggleMd").Content("Edit Raw").Style("{StaticResource ToggleSwitch}")
    .On("Checked", (*) => (ui.Update("MdViewSv", "Visibility", "Collapsed"), ui.Update("MdEditor", "Visibility", "Visible")))

mdGrid := docSp.Add("Grid").Grid_Row(1)
mdSv := mdGrid.Add("ScrollViewer").Name("MdViewSv").VerticalScrollBarVisibility("Auto")
mdRenderer := mdSv.Add("StackPanel").Name("MdView").VerticalAlignment("Top")
mdRenderer.MarkdownRenderer(mdText)

mdGrid.Add("TextBox").Name("MdEditor").Text(mdText).TextWrapping("Wrap").AcceptsReturn("True").VerticalScrollBarVisibility("Auto").VerticalContentAlignment("Top").Visibility("Collapsed").Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness("1").BorderBrush("{DynamicResource ControlBorder}").Padding("10")
    .Track()

nav.AddPage("Dashboard", Chr(0xEA24), dashGrid)

; ---------------------------------------------------------
; PAGE 2: Kanban Board
; ---------------------------------------------------------
kanbanGrid := XAML_Generator("Grid").Margin("0")
kanbanGrid._Parent := app.X
kanbanGrid.Rows("Auto", "Auto", "*")
kanbanGrid.Add("TextBlock").Text("Task Board").Grid_Row(0).FontSize("24").FontWeight("Light").Foreground("{DynamicResource TextMain}").Margin("0,0,0,10")


kb := kanbanGrid.KanbanBoard("ProjectKanban")
kb.sv.Grid_Row(2)
kb.EnableDrag()
Example_MockData.PopulateKanbanBoard(kb)

nav.AddPage("Kanban", Chr(0xE8D4), kanbanGrid)

; ---------------------------------------------------------
; PAGE 3: Node Graph
; ---------------------------------------------------------
nodesGrid := XAML_Generator("Grid").Margin("0")
nodesGrid._Parent := app.X
nodesGrid.Rows("Auto", "Auto", "*")
nodesGrid.Add("TextBlock").Text("Visual Scripting").Grid_Row(0).FontSize("24").FontWeight("Light").Foreground("{DynamicResource TextMain}").Margin("0,0,0,8")

nodesHeader := nodesGrid.Add("Grid").Grid_Row(1).Margin("0,0,0,12")
nodesHeader.Cols("*", "Auto")
nodesHeader.Add("TextBlock").Text("Right-click: context menu  |  Scroll: zoom  |  Mid-drag: pan  |  Left-drag: select/move").FontSize("11").Foreground("#666").VerticalAlignment("Center")

tb := nodesHeader.Add("StackPanel").Grid_Column(1).Orientation("Horizontal")

btnPan := tb.Add("RadioButton").Name("BtnPanMode").Content("Pan Mode").IsChecked("True").Margin("0,0,10,0")
    .On("Checked", (*) => ui.Update(ng.id, "SetCanvasMode", "Pan"))
btnSel := tb.Add("RadioButton").Name("BtnSelectMode").Content("Select Mode").Margin("0,0,10,0")
    .On("Checked", (*) => ui.Update(ng.id, "SetCanvasMode", "Select"))
btnKnife := tb.Add("RadioButton").Name("BtnKnifeMode").Content("Knife Tool").Margin("0,0,20,0")
    .On("Checked", (*) => ui.Update(ng.id, "SetCanvasMode", "Knife"))

chkSnap := tb.Add("CheckBox").Name("ChkGridSnap").Content("Grid Snap").IsChecked("True").VerticalAlignment("Center").Margin("0,0,20,0")
    .On("Checked", (*) => ng.SetGridSnap(ui, true))
    .On("Unchecked", (*) => ng.SetGridSnap(ui, false))

btnZoomOut := tb.Add("Button").Name("BtnZoomOut").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness("1").BorderBrush("{DynamicResource ControlBorder}").Padding("8,4").Cursor("Hand").Margin("0,0,4,0")
    .On("Click", (*) => ui.Update(ng.id, "Zoom", "0.8"))
btnZoomOut.Add("TextBlock").Text("-").FontSize("14").FontWeight("Bold").VerticalAlignment("Center").Margin("0,-2,0,0")

btnZoomIn := tb.Add("Button").Name("BtnZoomIn").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness("1").BorderBrush("{DynamicResource ControlBorder}").Padding("8,4").Cursor("Hand").Margin("0,0,4,0")
    .On("Click", (*) => ui.Update(ng.id, "Zoom", "1.2"))
btnZoomIn.Add("TextBlock").Text("+").FontSize("14").FontWeight("Bold").VerticalAlignment("Center").Margin("0,-2,0,0")

btnZoom := tb.Add("Button").Name("BtnZoomAll").Background("Transparent").Foreground("{DynamicResource TextSub}").BorderThickness("1").BorderBrush("{DynamicResource ControlBorder}").Padding("10,4").Cursor("Hand")
    .On("Click", (*) => ui.Update(ng.id, "ZoomAll", ""))
spZ := btnZoom.Add("StackPanel").Orientation("Horizontal")
spZ.Add("TextBlock").Text(Chr(0xE8A3)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize("12").VerticalAlignment("Center").Margin("0,0,6,0")
spZ.Add("TextBlock").Text("Zoom Fit").FontSize("12").VerticalAlignment("Center").Foreground("{DynamicResource TextSub}")

ng := nodesGrid.NodeGraph("WorkflowGraph")
ng.bdr.Grid_Row(2)
ng.EnableDrag()
Example_MockData.PopulateNodeGraph(ng)

nav.AddPage("Node Graph", Chr(0xE9D5), nodesGrid)

; ---------------------------------------------------------
; PAGE 4: Media Player
; ---------------------------------------------------------
mediaGrid := XAML_Generator("Grid").Margin("0")
mediaGrid._Parent := app.X
mediaGrid.Rows("Auto", "*")
mediaGrid.Add("TextBlock").Text("Media Tools").Grid_Row(0).FontSize("24").FontWeight("Light").Foreground("{DynamicResource TextMain}").Margin("0,0,0,20")

vidBdr := mediaGrid.Add("Border").Use("CardPanel").Padding("15").Margin("0,0,20,0").Grid_Row(1)
vidGrid := vidBdr.Add("Grid")
vidGrid.Rows("Auto", "*")
mp := vidGrid.MediaPlayerEx("", "VidPlayer")
mp.grid.Grid_Row(1)

nav.AddPage("Media", Chr(0xE1D3), mediaGrid)

; ---------------------------------------------------------
; PAGE 5: Web/File Viewer
; ---------------------------------------------------------
webGrid := XAML_Generator("Grid").Margin("0")
webGrid._Parent := app.X
webGrid.Rows("Auto", "*")

webHeader := webGrid.Add("StackPanel").Grid_Row(0).Orientation("Horizontal").Margin("0,0,0,10")
webHeader.Add("TextBlock").Text("Web/File Viewer").FontSize("24").FontWeight("Light").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").Margin("0,0,20,0")

webHeader.Add("Button").Name("BtnSvgBgColor").Style("{StaticResource IconButton}").Width("32").Height("32").Margin("0,0,5,0").ToolTip("Change Background Color").Add("TextBlock").Text(Chr(0xE790)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(16).HorizontalAlignment("Center").VerticalAlignment("Center").Margin("0")
    .On("Click", ChangeSvgBgColor)
webHeader.Add("Button").Name("BtnSvgGridDark").Style("{StaticResource IconButton}").Width("32").Height("32").Margin("0,0,5,0").ToolTip("Dark Grid").Add("TextBlock").Text(Chr(0xE80A)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(16).HorizontalAlignment("Center").VerticalAlignment("Center").Margin("0")
    .On("Click", (state, ctrl, event) => webViewer.SetGrid("Dark"))
webHeader.Add("Button").Name("BtnSvgGridLight").Style("{StaticResource IconButton}").Width("32").Height("32").Margin("0,0,5,0").ToolTip("Light Grid").Add("TextBlock").Text(Chr(0xE80A)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(16).Foreground("{DynamicResource TextSub}").HorizontalAlignment("Center").VerticalAlignment("Center").Margin("0")
    .On("Click", (state, ctrl, event) => webViewer.SetGrid("Light"))
webHeader.Add("Button").Name("BtnSvgGridNone").Style("{StaticResource IconButton}").Width("32").Height("32").Margin("0,0,15,0").ToolTip("No Grid").Add("TextBlock").Text(Chr(0xE814)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(16).Foreground("#FF453A").HorizontalAlignment("Center").VerticalAlignment("Center").Margin("0")
    .On("Click", (state, ctrl, event) => webViewer.SetGrid("None"))

webHeader.Add("Button").Name("BtnWebReplace").Content("Replace File").Background("Transparent").Foreground("{DynamicResource Accent}").BorderThickness("0").Margin("15,0,0,0").VerticalAlignment("Center").Visibility("Collapsed").Cursor("Hand")

webViewer := webGrid.WebViewer("MyWebViewer")
webViewer.grid.Grid_Row(1)

nav.AddPage("File Viewer", Chr(0xEB9F), webGrid)

; ---------------------------------------------------------
; PAGE 6: Image Cropper
; ---------------------------------------------------------
cropGrid := XAML_Generator("Grid").Margin("0")
cropGrid._Parent := app.X
cropGrid.Rows("Auto", "*")
cropGrid.Add("TextBlock").Text("Image Editor").Grid_Row(0).FontSize("24").FontWeight("Light").Foreground("{DynamicResource TextMain}").Margin("0,0,0,20")

imgBdr := cropGrid.Add("Border").Use("CardPanel").Padding("15").Margin("0,0,20,0").Grid_Row(1)
imgGrid := imgBdr.Add("Grid")
imgGrid.Rows("Auto", "*")
imgGrid.Add("TextBlock").Text("Image Cropper").Grid_Row(0).Foreground("{DynamicResource TextSub}").FontSize("12").FontWeight("Bold").Margin("0,0,0,10")
ic := imgGrid.ImageCropper("", "ImgCrop")
ic.grid.Grid_Row(1)
ic.EnableDrag()

nav.AddPage("Image", Chr(0xE91B), cropGrid)

; ---------------------------------------------------------
; PAGE 7: Animated Clock
; ---------------------------------------------------------
clockPage := XAML_Generator("Grid").Margin("0")
clockPage._Parent := app.X
clockPage.Rows("Auto", "*")

clockHeader := clockPage.Add("StackPanel").Grid_Row(0).Orientation("Horizontal").Margin("0,0,0,20")
clockHeader.Add("TextBlock").Text("Dynamic Clock").FontSize("24").FontWeight("Light").Foreground("{DynamicResource TextMain}").Margin("0,0,20,0").VerticalAlignment("Center")

liveSp := clockHeader.Add("StackPanel").Orientation("Horizontal").Margin("0,0,15,0")
liveSp.Add("CheckBox").Name("BtnClockLive").Style("{StaticResource ToggleSwitch}").IsChecked("True").Margin("0,0,10,0")
    .On("Checked", (s, c, e) => SwitchClockMode("Live", s, digitalClock, ui))
    .On("Unchecked", (s, c, e) => SwitchClockMode("Edit", s, digitalClock, ui))
liveSp.Add("TextBlock").Text("Live Mode").Foreground("{DynamicResource TextSub}").VerticalAlignment("Center")

editSp := clockHeader.Add("StackPanel").Orientation("Horizontal")
editSp.Add("CheckBox").Name("BtnClockEdit").Style("{StaticResource ToggleSwitch}").Margin("0,0,10,0")
    .On("Checked", (s, c, e) => SwitchClockMode("Edit", s, digitalClock, ui))
    .On("Unchecked", (s, c, e) => SwitchClockMode("Live", s, digitalClock, ui))
editSp.Add("TextBlock").Text("Edit Mode").Foreground("{DynamicResource TextSub}").VerticalAlignment("Center")

cBox := clockPage.Add("Grid").Grid_Row(1)
digitalClock := cBox.Clock("MyClock")

nav.AddPage("Clock", Chr(0xE823), clockPage)

; ---------------------------------------------------------
; PAGE 8: Code Editor (AvalonEdit IDE)
; ---------------------------------------------------------
editorPage := XAML_Generator("Grid").Margin("0")
editorPage._Parent := app.X
editorPage.Rows("Auto", "Auto", "*")

editorHeader := editorPage.Add("StackPanel").Grid_Row(0).Orientation("Horizontal").Margin("0,0,0,10")
editorHeader.Add("TextBlock").Text("IDE Component").FontSize("24").FontWeight("Light").Foreground("{DynamicResource TextMain}").Margin("0,0,20,0").VerticalAlignment("Center")
editorHeader.Add("TextBlock").Text("Powered by AvalonEdit").Foreground("{DynamicResource TextSub}").VerticalAlignment("Center")

; Toolbar row
editorToolbar := editorPage.Add("StackPanel").Grid_Row(1).Orientation("Horizontal").Margin("0,0,0,10")

; Language selector
editorToolbar.Add("TextBlock").Text("Language:").Foreground("{DynamicResource TextSub}").VerticalAlignment("Center").Margin("0,0,8,0")
langCb := editorToolbar.Add("ComboBox").Name("AELangCombo").Width(120).Height(28).VerticalAlignment("Center").Margin("0,0,15,0")
for lang in ["C#", "JavaScript", "Python", "XML", "HTML", "CSS", "C++", "Java", "SQL", "PowerShell", "Markdown"]
    langCb.Add("ComboBoxItem").Content(lang)
langCb.SelectedIndex(0)

; Theme selector
editorToolbar.Add("TextBlock").Text("Theme:").Foreground("{DynamicResource TextSub}").VerticalAlignment("Center").Margin("0,0,8,0")
themeCb := editorToolbar.Add("ComboBox").Name("AEThemeCombo").Width(130).Height(28).VerticalAlignment("Center").Margin("0,0,15,0")
for t in ["match", "dark", "light", "monokai", "one-dark", "dracula", "solarized-dark"]
    themeCb.Add("ComboBoxItem").Content(t)
themeCb.SelectedIndex(0)

; Action buttons
editorToolbar.Add("Button").Name("AEFoldAll").Content("Fold All").Background("Transparent").Foreground("{DynamicResource Accent}").BorderThickness(0).Padding("8,4").Margin("0,0,5,0").Cursor("Hand")
editorToolbar.Add("Button").Name("AEUnfoldAll").Content("Unfold All").Background("Transparent").Foreground("{DynamicResource Accent}").BorderThickness(0).Padding("8,4").Margin("0,0,5,0").Cursor("Hand")
editorToolbar.Add("Button").Name("AEShowComplete").Content("Show Autocomplete").Background("Transparent").Foreground("{DynamicResource Accent}").BorderThickness(0).Padding("8,4").Cursor("Hand")

; Status bar
statusSp := editorPage.Add("StackPanel").Grid_Row(2).VerticalAlignment("Bottom").Orientation("Horizontal").Margin("0,0,0,0")
statusSp.Add("TextBlock").Name("AEStatus").Text("Ln 1, Col 1").Foreground("{DynamicResource TextSub}").FontSize(11).Margin("0,5,0,0")

; The editor itself
codeGrid := editorPage.Add("Grid").Grid_Row(2).Margin("0,0,0,25")
myEditor := codeGrid.AvalonEditor("IDEEditor", { Language: "cs", Theme: "dark" })

nav.AddPage("Code", Chr(0xE81E), editorPage)

; ---------------------------------------------------------
; PAGE 9: Property Grid
; ---------------------------------------------------------
propPage := XAML_Generator("Grid").Margin("0")
propPage._Parent := app.X
propPage.Rows("Auto", "*")

propHeader := propPage.Add("StackPanel").Grid_Row(0).Orientation("Horizontal").Margin("0,0,0,20")
propHeader.Add("TextBlock").Text("Settings Inspector").FontSize("24").FontWeight("Light").Foreground("{DynamicResource TextMain}").Margin("0,0,20,0").VerticalAlignment("Center")
propHeader.Add("TextBlock").Text("Auto-generated UI from AHK Objects").Foreground("{DynamicResource TextSub}").VerticalAlignment("Center")

propGridContainer := propPage.Add("Grid").Grid_Row(1).Margin("0,0,20,0").Width("400").HorizontalAlignment("Left")

testSettings := Example_MockData.GetMockSettingsMap()

pg := propGridContainer.PropertyGrid(testSettings, "MySettingsGrid")

nav.AddPage("Inspector", Chr(0xE713), propPage)

; ---------------------------------------------------------
; PAGE 10: Diff Viewer
; ---------------------------------------------------------
diffPage := XAML_Generator("Grid").Margin("0")
diffPage._Parent := app.X
diffPage.Rows("Auto", "*")

diffHeader := diffPage.Add("StackPanel").Grid_Row(0).Orientation("Horizontal").Margin("0,0,0,20")
diffHeader.Add("TextBlock").Text("Code Comparison").FontSize("24").FontWeight("Light").Foreground("{DynamicResource TextMain}").Margin("0,0,20,0").VerticalAlignment("Center")
diffHeader.Add("TextBlock").Text("Inline and Side-by-Side Diffing").Foreground("{DynamicResource TextSub}").VerticalAlignment("Center")

diffBdr := diffPage.Add("Border").Grid_Row(1).Margin("0,0,20,0")
dv := diffBdr.DiffViewer("MyDiff")

oldText := "function calculateTotal(items) {`n    let total = 0;`n    for (let i = 0; i < items.length; i++) {`n        total += items[i].price;`n    }`n    return total;`n}"
newText := "function calculateTotal(items) {`n    // Optimized array reduce`n    return items.reduce((total, item) => total + item.price, 0);`n}"
dv.SetDiff(oldText, newText)

nav.AddPage("Diff Tool", Chr(0xE81C), diffPage)

; ---------------------------------------------------------
; PAGE 11: Image Viewer
; ---------------------------------------------------------
imgViewerPage := XAML_Generator("Grid").Margin("0")
imgViewerPage._Parent := app.X
imgViewerPage.Rows("Auto", "*")

imgViewerHeader := imgViewerPage.Add("StackPanel").Grid_Row(0).Orientation("Horizontal").Margin("0,0,0,20")
imgViewerHeader.Add("TextBlock").Text("Image Viewer").FontSize("24").FontWeight("Light").Foreground("{DynamicResource TextMain}").Margin("0,0,20,0").VerticalAlignment("Center")
imgViewerHeader.Add("Button").Name("BtnImgReplace").Content("Replace Image").Background("Transparent").Foreground("{DynamicResource Accent}").BorderThickness("0").Margin("15,0,0,0").VerticalAlignment("Center").Visibility("Collapsed").Cursor("Hand")

imgViewerContent := imgViewerPage.Add("Grid").Grid_Row(1).Margin("0,0,20,0")
imgViewerContent.Cols("200", "*")

iconListBdr := imgViewerContent.Add("Border").Grid_Column(0).Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").CornerRadius("8").Margin("0,0,15,0")
iconList := iconListBdr.Add("ListBox").Name("ImgExampleList").Background("Transparent").BorderThickness("0").Padding("5")
    .On("SelectionChanged", LoadExampleImage)
    .Track()
global exampleIcons := [{ Name: "Shell32 Icon 1", Dll: "shell32.dll", Idx: 1 }, { Name: "Shell32 Icon 3", Dll: "shell32.dll", Idx: 3 }, { Name: "Shell32 Icon 4", Dll: "shell32.dll", Idx: 4 }, { Name: "Shell32 Icon 15", Dll: "shell32.dll", Idx: 15 }, { Name: "Shell32 Icon 44", Dll: "shell32.dll", Idx: 44 }, { Name: "Shell32 Icon 130", Dll: "shell32.dll", Idx: 130 }, { Name: "Imageres Icon 109", Dll: "imageres.dll", Idx: 109 }, { Name: "Imageres Icon 110", Dll: "imageres.dll", Idx: 110 }
]

iconList.SetProp("VirtualizingStackPanel.IsVirtualizing", "False")
for idx, ic in exampleIcons {
    lbi := iconList.Add("ListBoxItem").Tag(ic.Name)
    sp := lbi.Add("StackPanel").Orientation("Horizontal").Margin("0,5,0,5")
    sp.Add("Image").Name("IconPreviewImg_" idx).Width(32).Height(32).Margin("0,0,10,0").Stretch("UniformToFill").SetProp("RenderOptions.BitmapScalingMode", "HighQuality")
    sp.Add("TextBlock").Text(ic.Name).VerticalAlignment("Center").Foreground("{DynamicResource TextMain}")
}

imgBdrContainer := imgViewerContent.Add("Border").Grid_Column(1)
imgViewer := imgBdrContainer.ImageViewer("MyImgViewer")

nav.AddPage("Image Viewer", Chr(0xEB9F), imgViewerPage)


; ---------------------------------------------------------
; START APP
; ---------------------------------------------------------

ui := app.Compile()

; --- AvalonEdit post-compile bindings ---
myEditor.Bind(ui)

; Load snippets dynamically from text database
SplitPath(A_LineFile, , &showcaseDir)
if (A_IsCompiled)
    showcaseDir := A_ScriptDir
global snippetsMap := LoadSnippets(showcaseDir "\snippets.txt")

LoadSnippets(filePath) {
    sMap := Map()
    if !FileExist(filePath)
        return sMap
    content := FileRead(filePath)
    currentLang := ""
    currentCode := ""
    Loop parse, content, "`n", "`r" {
        line := A_LoopField
        if RegExMatch(line, "^===\s*([a-zA-Z0-9#\+\-]+)\s*===$", &m) {
            if (currentLang != "") {
                sMap[currentLang] := RTrim(currentCode, "`n`r")
            }
            currentLang := m[1]
            currentCode := ""
        } else {
            if (currentLang != "") {
                currentCode .= line "`n"
            }
        }
    }
    if (currentLang != "") {
        sMap[currentLang] := RTrim(currentCode, "`n`r")
    }
    return sMap
}

GetThemeColorString(themeName) {
    static iniPath := ""
    if (iniPath == "") {
        iniPath := FileExist("themes.ini") ? "themes.ini" : (FileExist("../themes.ini") ? "../themes.ini" : (FileExist("..\..\examples\themes.ini") ? "..\..\examples\themes.ini" : ""))
    }
    if (iniPath == "")
        return "dark"

    try {
        bg := IniRead(iniPath, themeName, "Resource_DropdownBg", "#1E1E1E")
        fg := IniRead(iniPath, themeName, "Resource_TextMain", "#FFFFFF")
        ln := IniRead(iniPath, themeName, "Resource_TextSub", "#888888")
        accent := IniRead(iniPath, themeName, "Resource_Accent", "#0A84FF")

        accentHex := RegExReplace(accent, "^#")
        sel := "#40" accentHex
        cur := "#15" accentHex

        return "bg:" bg ",fg:" fg ",ln:" ln ",sel:" sel ",cur:" cur
    } catch {
        return "dark"
    }
}

; Set C# as the default starting text
if snippetsMap.Has("cs") {
    myEditor.SetText(snippetsMap["cs"])
}
myEditor.UpdateFolding()
; Apply initial matched theme on startup
targetTheme := (app.HasProp("currentThemeName") && app.currentThemeName != "") ? app.currentThemeName : "Dark Mica (Win 11)"
myEditor.SetTheme(GetThemeColorString(targetTheme))

; Language selector
ui.Track("AELangCombo")
ui.OnEvent("AELangCombo", "SelectionChanged", _AELangChanged)
_AELangChanged(state, ctrl, event) {
    if (!state.Has("AELangCombo"))
        return
    langMap := Map("C#", "cs", "JavaScript", "js", "Python", "python", "XML", "xml", "HTML", "html", "CSS", "css", "C++", "cpp", "Java", "java", "SQL", "sql", "PowerShell", "powershell", "Markdown", "markdown")
    sel := state["AELangCombo"]
    if langMap.Has(sel) {
        langCode := langMap[sel]
        myEditor.SetLanguage(langCode)
        if snippetsMap.Has(langCode) {
            myEditor.SetText(snippetsMap[langCode])
            myEditor.UpdateFolding()
        }
    }
}

; Theme selector
global activeAETheme := "match"
ui.Track("AEThemeCombo")
ui.OnEvent("AEThemeCombo", "SelectionChanged", _AEThemeChanged)
_AEThemeChanged(state, ctrl, event) {
    if (!state.Has("AEThemeCombo"))
        return
    global activeAETheme := state["AEThemeCombo"]
    if (activeAETheme == "match") {
        targetTheme := (app.HasProp("currentThemeName") && app.currentThemeName != "") ? app.currentThemeName : "Dark Mica (Win 11)"
        myEditor.SetTheme(GetThemeColorString(targetTheme))
    } else {
        myEditor.SetTheme(activeAETheme)
    }
}

; Sync with parent UI theme changes
ui.OnEvent("ComboTheme", "SelectionChanged", _ParentThemeChanged)
_ParentThemeChanged(state, ctrl, event) {
    app.ThemeChanged(state, ctrl, event)
    if (activeAETheme == "match") {
        targetTheme := (app.HasProp("currentThemeName") && app.currentThemeName != "") ? app.currentThemeName : "Dark Mica (Win 11)"
        myEditor.SetTheme(GetThemeColorString(targetTheme))
    }
}

; Fold/Unfold buttons
ui.OnEvent("AEFoldAll", "Click", (*) => (myEditor.UpdateFolding(), myEditor.FoldAll()))
ui.OnEvent("AEUnfoldAll", "Click", (*) => myEditor.UnfoldAll())

; Demo autocomplete
ui.OnEvent("AEShowComplete", "Click", (*) => myEditor.ShowCompletion([
    "Console|System.Console class",
    "Console.WriteLine|Write line to stdout",
    "Console.ReadKey|Read a key press",
    "Console.Clear|Clear the console",
    "List|Generic list collection",
    "Dictionary|Key-value dictionary",
    "foreach|Iterate over collection",
    "namespace|Declare namespace",
    "class|Define a class",
    "static|Static member modifier"
]))

; Caret position tracking
myEditor.OnCaretChanged := (editor, state, event) => ui.Update("AEStatus", "Text", "Ln " StrSplit(event, ",")[1] ", Col " StrSplit(event, ",")[2])

SetTimer(LoadPreviewIcons, -100)
LoadPreviewIcons() {
    for idx, ic in exampleIcons {
        try {
            h := LoadPicture(ic.Dll, "Icon" ic.Idx " w32 h32", &t)
            if (h) {
                ui.Update("IconPreviewImg_" idx, "Source", (t == 0 ? "HBITMAP:" : "HICON:") h)
            }
        }
    }
}

; Post-compile bindings (dynamic/non-factory elements)
ui.OnEvent("BtnWebReplace", "Click", ObjBindMethod(webViewer, "OnClick"))
ui.OnEvent("BtnImgReplace", "Click", ObjBindMethod(imgViewer, "OnClick"))


SwitchClockMode("Live", Map(), digitalClock, ui) ; Force initialize state

SwitchClockMode(mode, state, clockRef, uiRef) {
    static currentMode := ""
    if (mode == currentMode)
        return

    currentMode := mode

    if (mode == "Live") {
        uiRef.Update("BtnClockLive", "IsChecked", "True")
        uiRef.Update("BtnClockEdit", "IsChecked", "False")
        clockRef.SetEditMode(false, state)
    } else {
        uiRef.Update("BtnClockLive", "IsChecked", "False")
        uiRef.Update("BtnClockEdit", "IsChecked", "True")
        clockRef.SetEditMode(true, state)
    }
}

ui.OnEvent("ComboTheme", "SelectionChanged", UpdateSvgThemeBase)

UpdateSvgThemeBase(state, ctrl, event) {
    app.ThemeChanged(state, ctrl, event)
    if !state.Has("ComboTheme")
        return
    themeName := state["ComboTheme"]
    baseColor := "#1E1E1E"
    try {
        iniPath := FileExist("themes.ini") ? "themes.ini" : "../themes.ini"
        themeData := IniRead(iniPath, themeName)
        Loop Parse, themeData, "`n", "`r" {
            parts := StrSplit(A_LoopField, "=", " `t", 2)
            if (parts.Length == 2 && parts[1] == "Resource_DropdownBg") {
                baseColor := parts[2]
                break
            }
        }
    }
    webViewer.SetBackground(webViewer.bgColor, baseColor)
}

; Kanban move buttons
ui.OnEvent("KbMoveLeft", "Click", (*) => (kb.HasProp("selectedColIdx") && kb.selectedColIdx > 1) ? kb.MoveSelectedTo(kb.selectedColIdx - 1) : "")
ui.OnEvent("KbMoveRight", "Click", (*) => (kb.HasProp("selectedColIdx") && kb.selectedColIdx > 0 && kb.selectedColIdx < kb.columns.Length) ? kb.MoveSelectedTo(kb.selectedColIdx + 1) : "")

; Track markdown editor for state
ui.Track("ComboTheme")

ui.OnEvent("BtnToggleMd", "Unchecked", ObjBindMethod(app, "RebuildMarkdown"))

; Extend app to handle the dynamic rebuild
app.DefineProp("RebuildMarkdown", { Call: _RebuildMarkdown })
_RebuildMarkdown(this, state, ctrl, event) {
    if !state.Has("MdEditor")
        return
    rawText := state["MdEditor"]

    ; Normalize line endings
    rawText := StrReplace(rawText, "`r`n", "`n")

    ; Build markdown elements
    temp := XAML_Generator("StackPanel")
    temp._Parent := this.X
    temp.MarkdownRenderer(rawText)

    ; Collect child XAML - the MarkdownRenderer adds a StackPanel with children
    innerXaml := ""
    for child in temp._Children {
        for innerChild in child._Children
            innerXaml .= innerChild.ToString()
    }

    ; Wrap in a StackPanel with xmlns for XamlReader.Parse
    xamlStr := '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">' innerXaml '</StackPanel>'

    ui.Update("MdView", "ClearItems", "")
    ui.Update("MdView", "AddXamlItem", xamlStr)

    ui.Update("MdViewSv", "Visibility", "Visible")
    ui.Update("MdEditor", "Visibility", "Collapsed")
}

ChangeSvgBgColor(state, ctrl, event) {
    themeName := state.Has("ComboTheme") ? state["ComboTheme"] : "Dark Mica (Win 11)"
    res := XColorPicker.Show({
        Title: "SVG Background Color",
        DefaultColor: "#1E1E1E",
        Owner: ui.wpfHwnd,
        Modal: true,
        Theme: themeName
    })

    if (res.Status == "OK") {
        baseColor := "#1E1E1E"
        try {
            iniPath := FileExist("themes.ini") ? "themes.ini" : "../themes.ini"
            themeData := IniRead(iniPath, themeName)
            Loop Parse, themeData, "`n", "`r" {
                parts := StrSplit(A_LoopField, "=", " `t", 2)
                if (parts.Length == 2 && parts[1] == "Resource_DropdownBg") {
                    baseColor := parts[2]
                    break
                }
            }
        }
        webViewer.SetBackground(res.Color, baseColor)
    }
}

LoadExampleImage(state, ctrl, event) {
    if !state.Has("ImgExampleList")
        return
    sel := state["ImgExampleList"]
    dllName := ""
    iconIdx := 0
    if InStr(sel, "Shell32") {
        dllName := "shell32.dll"
        iconIdx := Number(StrReplace(sel, "Shell32 Icon ", ""))
    } else if InStr(sel, "Imageres") {
        dllName := "imageres.dll"
        iconIdx := Number(StrReplace(sel, "Imageres Icon ", ""))
    }
    if (dllName != "") {
        try {
            ; Request large icon for the main viewer
            hIcon := LoadPicture(dllName, "Icon" iconIdx " w256 h-1", &imgType)
            if (hIcon)
                imgViewer.LoadImage("HICON:" hIcon)
        }
    }
}

ui.OnEvent("BtnSave", "Click", (*) => ng.SaveState("node_state.ini"))
ui.OnEvent("BtnLoad", "Click", (*) => ng.LoadState("node_state.ini", ui))
ui.OnEvent("BtnCmdClose", "Click", (*) => ExitApp())
ui.OnEvent("KbMoveLeft", "Click", (*) => kb.MoveSelectedTo(kb.selectedColIdx - 1))
ui.OnEvent("KbMoveRight", "Click", (*) => kb.MoveSelectedTo(kb.selectedColIdx + 1))

HotIfWinActive "ahk_pid " DllCall("GetCurrentProcessId")
Hotkey("Delete", (*) => ng.DeleteSelectedConnections())
HotIfWinActive


app.Show()