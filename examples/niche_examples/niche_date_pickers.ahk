#Requires AutoHotkey v2.0
; ==============================================================================
; NICHE EXAMPLES — niche_date_pickers.ahk
; Shows the DateRangePickerEx in both Period Mode and Two Single Days Mode.
; ==============================================================================

#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Generator.ahk"
#Include "../../lib/XAML_Dialog.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Components.ahk"

; Initialize App with Sidebar enabled to allow dynamic user theme switching
app := XAML_GUI("Niche Date Pickers Showcase", { Sidebar: true })
app.width := 1050
app.height := 750

; Setup Main Content Grid
grid := app.main.Add("Grid").Grid_Row(1).Margin("40,30,40,30")
grid.Rows("Auto", "*", "Auto")

; 1. Title Header
header := grid.Add("StackPanel").Grid_Row(0).Margin("0,0,0,25")
header.Add("TextBlock").Text("Date Picker Options").Use("PageTitle")
header.Add("TextBlock").Text("A comparison between standard range selection and niche dual date selection.").Foreground("{DynamicResource TextSub}").FontSize(14).Margin("0,5,0,0")

; Mode selector checkbox
modeSelectorSp := header.Add("StackPanel").Orientation("Horizontal").Margin("0,12,0,0")
modeSelectorSp.Add("CheckBox").Name("ChkThirdPress").Content("Enable 'Third Press' mode (updates the second/end date if clicked date is after start date)").IsChecked("True")

; 2. Columns (Side-by-Side Comparison)
colGrid := grid.Add("Grid").Grid_Row(1).Margin("0,0,0,20")
colGrid.Cols("*", "30", "*")

; Column 0: Standard Date Range Picker (Period of Days)
bdrStandard := colGrid.Add("Border").Grid_Column(0).Use("CardPanel").Padding("25")
spStandard := bdrStandard.Add("StackPanel")
spStandard.Add("TextBlock").Text("Standard Date Range Selector").Foreground("{DynamicResource TextMain}").FontSize(18).FontWeight("SemiBold").Margin("0,0,0,10")
spStandard.Add("TextBlock").Text("Selects a period of days. The range is filled, highlighting all intermediate days between the two selections.").Foreground("{DynamicResource TextSub}").FontSize(12).TextWrapping("Wrap").Margin("0,0,0,25")

spStandard.Add("TextBlock").Text("EVENT TIMELINE RANGE").Foreground("{DynamicResource TextSub}").FontSize(10).FontWeight("Bold").Margin("0,0,0,8")
global standardPicker := DateRangePickerEx("StandardDates", "", "", {
    SelectPeriod: true,
    Separator: "  -  ",
    OnChange: OnStandardChange
})
standardPicker.Build(spStandard)

; Column 2: Niche Dual Date Picker (Two Single Days)
bdrNiche := colGrid.Add("Border").Grid_Column(2).Use("CardPanel").Padding("25")
spNiche := bdrNiche.Add("StackPanel")
spNiche.Add("TextBlock").Text("Niche Dual Date Selector").Foreground("{DynamicResource TextMain}").FontSize(18).FontWeight("SemiBold").Margin("0,0,0,10")
spNiche.Add("TextBlock").Text("Selects two single days (e.g. milestones). No intermediate days are highlighted. The second date cannot be earlier than the first.").Foreground("{DynamicResource TextSub}").FontSize(12).TextWrapping("Wrap").Margin("0,0,0,25")

spNiche.Add("TextBlock").Text("MILESTONE SINGLE DATES").Foreground("{DynamicResource TextSub}").FontSize(10).FontWeight("Bold").Margin("0,0,0,8")
global nichePicker := DateRangePickerEx("NicheDates", "", "", {
    SelectPeriod: false,
    Separator: "  &  ",
    OnChange: OnNicheChange
})
nichePicker.Build(spNiche)

; 3. Log Output Console (Displays Realtime Event Data)
logGrid := grid.Add("Grid").Grid_Row(2).Margin("0,15,0,0")
logGrid.Rows("Auto", "*")
logGrid.Add("TextBlock").Grid_Row(0).Text("REALTIME EVENT MONITOR").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold").Margin("0,0,0,8")

logBdr := logGrid.Add("Border").Grid_Row(1).Use("CardPanel").Padding(1).Height(140)
logList := logBdr.Add("ListBox").Name("LogList").FontFamily("Consolas, Courier New").FontSize(12).Padding(10).ScrollViewer_VerticalScrollBarVisibility("Auto")
logList.Add("ListBoxItem").Content("System initialized. Interaction log started...")

; Compile UI
ui := app.Compile()

; Bind the checkbox event
ui.OnEvent("ChkThirdPress", "Click", OnThirdPressToggle)
ui.Track("ChkThirdPress")

; Show the Window
app.Show()

; Event Handlers
OnStandardChange(start, end) {
    formattedStart := (start == "") ? "Blank" : FormatTime(start, "yyyy-MM-dd")
    formattedEnd := (end == "") ? "Blank" : FormatTime(end, "yyyy-MM-dd")
    ui.Update("LogList", "AddItem", "[" A_Hour ":" A_Min ":" A_Sec "." A_MSec "] [Standard Picker] Range selected: " formattedStart " to " formattedEnd)
}

OnNicheChange(start, end) {
    formattedStart := (start == "") ? "Blank" : FormatTime(start, "yyyy-MM-dd")
    formattedEnd := (end == "") ? "Blank" : FormatTime(end, "yyyy-MM-dd")
    ui.Update("LogList", "AddItem", "[" A_Hour ":" A_Min ":" A_Sec "." A_MSec "] [Niche Picker] Two single days selected: Left = " formattedStart ", Right = " formattedEnd)
}

OnThirdPressToggle(state, ctrl, ev) {
    isChecked := (state["ChkThirdPress"] == "True")
    standardPicker.SetThirdPressMode(isChecked)
    nichePicker.SetThirdPressMode(isChecked)
    ui.Update("LogList", "AddItem", "[" A_Hour ":" A_Min ":" A_Sec "." A_MSec "] 'Third Press' mode: " (isChecked ? "ENABLED" : "DISABLED"))
}

Persistent()