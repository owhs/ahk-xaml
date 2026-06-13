#Requires AutoHotkey v2.0
; ==============================================================================
; NICHE EXAMPLES — niche_list_views.ahk
; Shows the DataGridEx with selection events, persistent checkboxes, and hover-triggered toolbars.
; ==============================================================================

#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Generator.ahk"
#Include "../../lib/XAML_Dialog.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Components.ahk"

; Initialize App with Sidebar enabled to allow dynamic user theme switching
app := XAML_GUI("Advanced ListView Showcase", { Sidebar: true })
app.width := 1250
app.height := 820

; Setup Main Content Grid
mainGrid := app.main.Add("Grid").Grid_Row(1).Margin("30,20,30,20")
mainGrid.Rows("Auto", "*", "160")

; 1. Title Header
header := mainGrid.Add("StackPanel").Grid_Row(0).Margin("0,0,0,15")
header.Add("TextBlock").Text("Advanced List & Grid Engine").Use("PageTitle")
header.Add("TextBlock").Text("Explore row selection callbacks, persistent multiselect checkboxes, and inline row actions.").Foreground("{DynamicResource TextSub}").FontSize(14).Margin("0,5,0,0")

; 2. Columns (Left Control Cards & Right Data Table)
contentGrid := mainGrid.Add("Grid").Grid_Row(1)
contentGrid.Cols("320", "20", "*")

; Column 0: Left controls panel
leftPanel := contentGrid.Add("StackPanel").Grid_Column(0)

; 2.1 Grid Configuration options
optCard := leftPanel.Add("Border").Use("CardPanel").Padding("20").Margin("0,0,0,15")
optSp := optCard.Add("StackPanel")
optSp.Add("TextBlock").Text("GRID CONFIGURATION").Foreground("{DynamicResource TextSub}").FontSize(10).FontWeight("Bold").Margin("0,0,0,12")

optSp.Add("CheckBox").Name("TglCheckboxes").Content("Show Row Checkboxes").IsChecked("True").Margin("0,0,0,10")
optSp.Add("CheckBox").Name("TglActions").Content("Show Row Actions Toolbar").IsChecked("True").Margin("0,0,0,10")
optSp.Add("CheckBox").Name("TglHoverOnly").Content("Actions Hover-Only Mode").IsChecked("True").Margin("0,0,0,10")
optSp.Add("CheckBox").Name("TglSticky").Content("Pin Actions Column").Margin("0,0,0,10")

optSp.Add("TextBlock").Text("PAGE LIMIT").Foreground("{DynamicResource TextSub}").FontSize(10).FontWeight("Bold").Margin("0,10,0,6")
cbLimit := optSp.Add("ComboBox").Name("CbLimit").Height("30").Margin("0,0,0,15").SelectedIndex(0)
cbLimit.Add("ComboBoxItem").Content("5")
cbLimit.Add("ComboBoxItem").Content("10")
cbLimit.Add("ComboBoxItem").Content("All")

btnActionSelected := optSp.Add("Button").Name("BtnActionSelected").Content("Process Selected (0)").IsEnabled("False").Background("{DynamicResource Accent}").Foreground("White").Height("32").FontWeight("SemiBold").Cursor("Hand").Margin("0,0,0,8")
btnClearCheck := optSp.Add("Button").Name("BtnClearCheck").Content("Clear Selections").Background("Transparent").BorderThickness("1").BorderBrush("{DynamicResource ControlBorder}").Foreground("{DynamicResource TextSub}").Height("30").Cursor("Hand")

; 2.2 Selected Item Detailed Status Card
detailsCard := leftPanel.Add("Border").Use("CardPanel").Padding("20").Height("250")
detailsSp := detailsCard.Add("StackPanel")
detailsSp.Add("TextBlock").Text("SELECTED SERVER DETAILS").Foreground("{DynamicResource TextSub}").FontSize(10).FontWeight("Bold").Margin("0,0,0,12")

detailsSp.Add("TextBlock").Name("DetName").Text("No Server Selected").FontSize(18).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,4")
detailsSp.Add("TextBlock").Name("DetIP").Text("IP: --").Foreground("{DynamicResource TextSub}").FontSize(12).Margin("0,0,0,15")

metricsGrid := detailsSp.Add("Grid").Margin("0,0,0,10")
metricsGrid.Cols("*", "*")

cpuSp := metricsGrid.Add("StackPanel").Grid_Column(0).Margin("0,0,10,0")
cpuSp.Add("TextBlock").Text("CPU LOAD").Foreground("{DynamicResource TextSub}").FontSize(9).FontWeight("Bold").Margin("0,0,0,4")
cpuSp.Add("TextBlock").Name("DetCPU").Text("--").FontSize(16).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}")

tempSp := metricsGrid.Add("StackPanel").Grid_Column(1)
tempSp.Add("TextBlock").Text("TEMPERATURE").Foreground("{DynamicResource TextSub}").FontSize(9).FontWeight("Bold").Margin("0,0,0,4")
tempSp.Add("TextBlock").Name("DetTemp").Text("--").FontSize(16).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}")

statusSp := detailsSp.Add("StackPanel").Orientation("Horizontal").Margin("0,15,0,0")
statusSp.Add("TextBlock").Text("Status: ").Foreground("{DynamicResource TextSub}").FontSize(12).VerticalAlignment("Center")
statusSp.Add("Border").Name("DetStatusDot").Width("12").Height("12").CornerRadius("6").Background("#666666").Margin("5,0,8,0").VerticalAlignment("Center")
statusSp.Add("TextBlock").Name("DetStatusText").Text("Idle").Foreground("{DynamicResource TextMain}").FontSize(13).FontWeight("SemiBold").VerticalAlignment("Center")

; Column 2: The DataGridEx control
gridBdr := contentGrid.Add("Border").Grid_Column(2).Use("CardPanel").Padding("15")

; Server Dataset
global serverData := [{ Server: "US-East-DB-01", IP: "10.0.1.10", CPU: "42%", Temp: "58°C", Status: "Active", Location: "Virginia, USA" }, { Server: "EU-West-Web-01", IP: "10.1.10.15", CPU: "88%", Temp: "72°C", Status: "Warning", Location: "Frankfurt, Germany" }, { Server: "AP-South-Redis", IP: "10.2.5.4", CPU: "12%", Temp: "41°C", Status: "Active", Location: "Mumbai, India" }, { Server: "US-West-Backup", IP: "10.0.2.100", CPU: "5%", Temp: "38°C", Status: "Active", Location: "Oregon, USA" }, { Server: "EU-East-Auth", IP: "10.1.12.8", CPU: "0%", Temp: "0°C", Status: "Offline", Location: "Warsaw, Poland" }, { Server: "US-East-LoadBalancer", IP: "10.0.1.1", CPU: "61%", Temp: "65°C", Status: "Active", Location: "Virginia, USA" }, { Server: "AP-East-API-01", IP: "10.3.1.20", CPU: "94%", Temp: "79°C", Status: "Warning", Location: "Hong Kong" }, { Server: "SA-East-DB-02", IP: "10.4.1.10", CPU: "30%", Temp: "52°C", Status: "Active", Location: "São Paulo, Brazil" }, { Server: "EU-West-DB-03", IP: "10.1.10.12", CPU: "0%", Temp: "0°C", Status: "Offline", Location: "Frankfurt, Germany" }, { Server: "US-West-Analytics", IP: "10.0.2.50", CPU: "75%", Temp: "68°C", Status: "Active", Location: "Oregon, USA" }, { Server: "AF-South-Edge", IP: "10.5.1.5", CPU: "18%", Temp: "44°C", Status: "Active", Location: "Cape Town, SA" }, { Server: "ME-Central-Web-02", IP: "10.6.2.10", CPU: "55%", Temp: "61°C", Status: "Active", Location: "Dubai, UAE" }, { Server: "US-East-Dev-01", IP: "10.0.1.99", CPU: "0%", Temp: "0°C", Status: "Offline", Location: "Virginia, USA" }, { Server: "EU-North-Cache", IP: "10.7.1.4", CPU: "35%", Temp: "49°C", Status: "Active", Location: "Stockholm, Sweden" }, { Server: "AP-Southeast-DB-04", IP: "10.8.1.12", CPU: "81%", Temp: "76°C", Status: "Warning", Location: "Singapore" }
]

global myGrid := DataGridEx("DGX", serverData, {
    PageSize: 5,
    ShowSearch: true,
    ShowFilters: true,
    ShowPagination: true,
    ShowReset: true,
    ShowRowCount: true,
    FilterColumn: "Status",
    FilterValues: ["Active", "Offline", "Warning"],
    SortCol: "Server",
    Columns: ["Server", "IP", "CPU", "Temp", "Status", "Location"],
    ColumnWidths: { Server: "180", IP: "110", CPU: "80", Temp: "90", Status: "90", Location: "140" },
    ShowCheckboxes: true,
    ShowRowActions: true,
    RowActionsHoverOnly: true,
    StickyActions: false,
    OnRowSelect: OnRowSelected,
    OnRowCheck: OnRowChecked,
    OnRowAction: OnRowActionTriggered
})
myGrid.Build(gridBdr)

; 3. Log Output Console (Displays Realtime Event Data)
logGrid := mainGrid.Add("Grid").Grid_Row(2).Margin("0,15,0,0")
logGrid.Rows("Auto", "*")
logGrid.Add("TextBlock").Grid_Row(0).Text("REALTIME EVENT MONITOR").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold").Margin("0,0,0,8")

logBdr := logGrid.Add("Border").Grid_Row(1).Use("CardPanel").Padding(1).Height(110)
logList := logBdr.Add("ListBox").Name("LogList").FontFamily("Consolas, Courier New").FontSize(12).Padding(10).ScrollViewer_VerticalScrollBarVisibility("Auto")
logList.Add("ListBoxItem").Content("System initialized. Advanced ListView Showcase loaded.")

; Compile UI
ui := app.Compile()

; Bind option controls
ui.OnEvent("TglCheckboxes", "Click", OnToggleCheckboxes)
ui.Track("TglCheckboxes")

ui.OnEvent("TglActions", "Click", OnToggleActions)
ui.Track("TglActions")

ui.OnEvent("TglHoverOnly", "Click", OnToggleHoverOnly)
ui.Track("TglHoverOnly")

ui.OnEvent("TglSticky", "Click", OnToggleSticky)
ui.Track("TglSticky")

ui.OnEvent("CbLimit", "SelectionChanged", OnPageLimitChanged)
ui.Track("CbLimit")

ui.OnEvent("BtnActionSelected", "Click", OnProcessSelected)
ui.Track("BtnActionSelected")

ui.OnEvent("BtnClearCheck", "Click", OnClearCheck)
ui.Track("BtnClearCheck")

; Bind DataGridEx internal bindings
myGrid.Bind(ui)

; Show the Window
app.Show()

; --- Event Handlers ---

OnToggleCheckboxes(state, ctrl, ev) {
    isChecked := (state["TglCheckboxes"] == "True")
    myGrid.showCheckboxes := isChecked
    myGrid.Render(state)
    UpdateSelectionCount()
    LogEvent("Checkbox column visibility: " (isChecked ? "ENABLED" : "DISABLED"))
}

OnToggleActions(state, ctrl, ev) {
    isChecked := (state["TglActions"] == "True")
    myGrid.showRowActions := isChecked
    myGrid.Render(state)
    LogEvent("Row Actions visibility: " (isChecked ? "ENABLED" : "DISABLED"))
}

OnToggleHoverOnly(state, ctrl, ev) {
    isChecked := (state["TglHoverOnly"] == "True")
    myGrid.rowActionsHoverOnly := isChecked
    myGrid.Render(state)
    LogEvent("Row Actions Hover-Only Mode: " (isChecked ? "ENABLED" : "DISABLED"))
}

OnToggleSticky(state, ctrl, ev) {
    isChecked := (state["TglSticky"] == "True")
    myGrid.stickyActions := isChecked
    myGrid.Render(state)
    LogEvent("Sticky Actions column: " (isChecked ? "ENABLED" : "DISABLED"))
}

OnPageLimitChanged(state, ctrl, ev) {
    limitVal := state["CbLimit"]
    if (limitVal == "All") {
        myGrid.pageSize := 99999
    } else {
        myGrid.pageSize := Number(limitVal)
    }
    myGrid.page := 1
    myGrid.Render(state)
    LogEvent("Page limit changed to: " limitVal)
}

OnProcessSelected(state, ctrl, ev) {
    checkedList := myGrid.GetCheckedRows()
    if (checkedList.Length == 0)
        return

    serverNames := ""
    for serverObj in checkedList
        serverNames .= "  • " serverObj.Server " (" serverObj.IP ")`n"

    themeName := state.Has("ComboTheme") ? state["ComboTheme"] : "Dark Mica (Win 11)"
    XDialog.Show({
        Title: "Process Selected Servers",
        Message: "Are you sure you want to run updates on the following " checkedList.Length " servers?`n`n" serverNames,
        Buttons: ["Update Now", "Cancel"],
        Icon: Chr(0xE9CE),
        IconColor: "#0A84FF",
        Theme: themeName
    })

    LogEvent("Bulk process requested for " checkedList.Length " servers.")
}

OnClearCheck(state, ctrl, ev) {
    myGrid.ClearCheckedRows(state)
    UpdateSelectionCount()
    LogEvent("Selections cleared.")
}

OnRowSelected(rowObj) {
    ui.Update("DetName", "Text", rowObj.Server)
    ui.Update("DetIP", "Text", "IP: " rowObj.IP "  |  " rowObj.Location)
    ui.Update("DetCPU", "Text", rowObj.CPU)
    ui.Update("DetTemp", "Text", rowObj.Temp)

    color := "#666666"
    if (rowObj.Status == "Active")
        color := "#32D74B"
    else if (rowObj.Status == "Warning")
        color := "#FF9F0A"
    else if (rowObj.Status == "Offline")
        color := "#FF453A"

    ui.Update("DetStatusDot", "Background", color)
    ui.Update("DetStatusText", "Text", rowObj.Status)
    ui.Update("DetStatusText", "Foreground", color)

    LogEvent("SelectionChanged: " rowObj.Server " selected.")
}

OnRowChecked(rowObj, isChecked) {
    if (rowObj == "") {
        LogEvent("Master checkbox toggled: " (isChecked ? "Checked All" : "Unchecked All"))
    } else {
        LogEvent("Row checkbox toggled: " rowObj.Server " -> " (isChecked ? "Checked" : "Unchecked"))
    }
    UpdateSelectionCount()
}

OnRowActionTriggered(rowObj, actionName) {
    LogEvent("Action Clicked: '" actionName "' on server " rowObj.Server " (" rowObj.IP ")")

    themeName := ui.Query("ComboTheme") || "Dark Mica (Win 11)"
    if (actionName == "Edit") {
        XDialog.Show({
            Title: "Edit Server configuration",
            Message: "Modify configuration options for " rowObj.Server "`nLocation: " rowObj.Location "`n`n[Configure properties or network variables in production dashboard]",
            Buttons: ["Save", "Cancel"],
            Icon: Chr(0xE70F),
            IconColor: "#0A84FF",
            Theme: themeName
        })
    } else if (actionName == "Details") {
        XDialog.Show({
            Title: "Server Technical Details",
            Message: "Server: " rowObj.Server "`nIP Address: " rowObj.IP "`nCPU Load: " rowObj.CPU "`nCPU Temp: " rowObj.Temp "`nLocation: " rowObj.Location "`nStatus: " rowObj.Status,
            Buttons: ["Close"],
            Icon: Chr(0xE946),
            IconColor: "#32D74B",
            Theme: themeName
        })
    } else if (actionName == "Delete") {
        XDialog.Show({
            Title: "Confirm Server Deletion",
            Message: "Are you sure you want to decommission and remove " rowObj.Server "?`nThis action cannot be undone.",
            Buttons: ["Decommission", "Cancel"],
            Icon: Chr(0xE7BA),
            IconColor: "#FF453A",
            Theme: themeName
        })
    }
}

UpdateSelectionCount() {
    checkedList := myGrid.GetCheckedRows()
    count := checkedList.Length

    ui.Update("BtnActionSelected", "Content", "Process Selected (" count ")")
    ui.Update("BtnActionSelected", "IsEnabled", count > 0 ? "True" : "False")
}

LogEvent(text) {
    formatted := "[" FormatTime(, "HH:mm:ss") "] " text
    ui.Update("LogList", "AddItem", formatted)
}

Persistent()