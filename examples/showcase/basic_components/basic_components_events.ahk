; ==============================================================================
; EVENT HANDLERS - basic_components_events.ahk
; All event bindings and callback implementations. Always needed at runtime.
; ==============================================================================


; ==============================================================================
; APP SPECIFIC EVENT HANDLERS
; ==============================================================================

ui.OnEvent("BtnExecute", "Click", ExecuteProcess)
ui.OnEvent("BtnShowAlert", "Click", ShowAlertDialog)
ui.OnEvent("BtnShowInput", "Click", ShowInputDialog)
ui.OnEvent("BtnShowError", "Click", ShowErrorDialog)
ui.OnEvent("BtnShowAuth", "Click", ShowAuthDialog)
ui.OnEvent("BtnShowComplex1", "Click", ShowComplexDialog1)
ui.OnEvent("BtnShowComplex2", "Click", ShowComplexDialog2)
ui.OnEvent("BtnShowComplex3", "Click", ShowComplexDialog3)
ui.OnEvent("BtnShowComplex4", "Click", ShowComplexDialog4)
ui.OnEvent("BtnToggleTask", "Click", ToggleTaskSpinner)
ui.OnEvent("BtnStopTask", "Click", ToggleTaskSpinner)
ui.OnEvent("BtnClearSearch", "Click", ClearSearchBox)
ui.OnEvent("BtnManageUsers", "Click", CloseDropdown)
ui.OnEvent("BtnSettingsMenu", "Click", CloseDropdown)
ui.OnEvent("BtnBadgeToggle", "Click", ToggleBadge)
ui.OnEvent("BtnShowSnackbar", "Click", (*) => app.ShowSnackbar("Action completed successfully!"))
ui.OnEvent("BtnShowTestModal", "Click", ShowTestModal)
ui.OnEvent("ComboStrictSearch", "LostFocus", OnStrictSearchLostFocus)
ui.OnEvent("BtnOpenColorPicker", "Click", ShowColorPickerModal)
ui.OnEvent("BtnTestGauge", "Click", OnTestGaugeClick)

; Advanced UI Tab Events
ui.OnEvent("MyDropZone", "PreviewMouseLeftButtonDown", OnFileDropClick)
ui.OnEvent("BtnBadge", "Click", (*) => app.ShowSnackbar("You have 3 new notifications!", "DISMISS"))

; Rating ÔÇö bind star click events
RatingBind(ui, "Rating5", 5, false, Chr(0xE735), Chr(0xE734), "#FFD700", "{DynamicResource TextSub}")
RatingBind(ui, "Rating10", 10, false, Chr(0xEB52), Chr(0xEB51), "#FF453A", "{DynamicResource TextSub}")

; Emoji Picker ÔÇö bind all emoji button events
emojiList := Example_MockData.GetEmojiList()
EmojiPickerBind(ui, "MyEmoji", emojiList)

; DateRangePickerEx — recreate object if production mode
if !IsObject(myDatePicker)
    myDatePicker := DateRangePickerEx("EventDates", "2026-05-16", "2026-06-16")
ui.OnEvent("PriceFilter_SliderMin", "ValueChanged", ClampSliderMin)
ui.OnEvent("PriceFilter_SliderMax", "ValueChanged", ClampSliderMax)
ui.Track("PriceFilter_SliderMin")
ui.Track("PriceFilter_SliderMax")

; DataGridEx — recreate object if production mode, then bind
if !IsObject(myGrid) {
    scrambled := Example_MockData.GenerateDataGridExData()
    myGrid := DataGridEx("DGX", scrambled, {
        PageSize: 50,
        ShowSearch: true,
        ShowFilters: true,
        ShowPagination: true,
        ShowReset: true,
        ShowRowCount: true,
        FilterColumn: "Status",
        FilterValues: ["Active", "Offline", "Pending"],
        SortCol: "Id",
        HiddenColumns: ["Id"],
        ColumnWidths: { Id: "50", Name: "250", Role: "180", Status: "180" }
    })
}
myGrid.Bind(ui)

ui.Track("TxtUser")
ui.Track("ComboRegion")
ui.Track("ComboStrictSearch")
ui.Track("TxtSearch")
ui.Track("ComboTheme")
ui.Track("MainTabs")

for tabName in tabList {
    cleanName := StrReplace(tabName, " ", "")
    ui.OnEvent("TglTab" cleanName, "Click", ToggleTabVis)
    ui.Track("TglTab" cleanName)
}

ui.OnEvent("Window", "Loaded", SyncTabVis)

; --- Custom Event Implementations ---

global gaugeValue := 45
global gaugeTarget := 45
global gaugeTimerActive := false


OnTestGaugeClick(state, ctrl, ev) {
    global gaugeTimerActive, gaugeTarget, gaugeValue
    if (!gaugeTimerActive) {
        gaugeTimerActive := true
        ui.Update("BtnTestGauge", "Content", "Stop Monitor")
        SetTimer(GaugeSetNewTarget, 1000) ; Pick a new target every 1s
        SetTimer(GaugeAnimateTick, 16)    ; 60 FPS animation loop
    } else {
        gaugeTimerActive := false
        ui.Update("BtnTestGauge", "Content", "Start Monitor")
        SetTimer(GaugeSetNewTarget, 0)
        SetTimer(GaugeAnimateTick, 0)
    }
}

GaugeSetNewTarget() {
    global gaugeTarget
    gaugeTarget += Random(-30, 40)
    if (gaugeTarget < 0)
        gaugeTarget := 0
    if (gaugeTarget > 100)
        gaugeTarget := 100

    ui.Update("MyGauge_Text", "Text", Integer(gaugeTarget))
}

GaugeAnimateTick() {
    global gaugeValue, gaugeTarget
    diff := gaugeTarget - gaugeValue
    if (Abs(diff) < 0.1) {
        gaugeValue := gaugeTarget
        return
    }

    ; Smooth easing
    gaugeValue += diff * 0.15

    pct := gaugeValue / 100
    offset := 18.06 * (1 - pct)

    ui.Update("MyGauge_Arc", "StrokeDashOffset", offset)
}

ShowColorPickerModal(state, ctrl, event) {
    theme := state.Has("ComboTheme") ? state["ComboTheme"] : "Dark Mica (Win 11)"
    ; Retrieve the current color from the preview element's background (or rely on a bound variable)
    res := XColorPicker.Show({
        Title: "Advanced Color Selector",
        DefaultColor: "#FF0A84FF",
        Owner: ui.wpfHwnd,
        Modal: true,
        Theme: theme
    })

    if (res.Status == "OK") {
        ui.Update("Resource", "SelectedColorBrush", res.Color)
        ui.Update("BtnColorPreview", "Background", res.Color)
        app.ShowSnackbar("Color updated to " res.Color)
    }
}

OnFileDropClick(state, ctrl, event) {
    selectedFile := FileSelect(3, , "Select a file to load")
    if (selectedFile) {
        OnFileDropped(selectedFile)
    }
}

OnFileDropped(filePath) {
    SplitPath filePath, &name, &dir, &ext, &name_no_ext, &drive
    ui.Update("MyDropZone_Text", "Text", name)
    ui.Update("MyDropZone_Icon", "Text", Chr(0xE8A5)) ; Document icon
}

; Slider clamping: prevent min > max and max < min
ClampSliderMin(state, ctrl, event) {
    if (state.Has("PriceFilter_SliderMin") && state.Has("PriceFilter_SliderMax")) {
        minVal := Number(state["PriceFilter_SliderMin"])
        maxVal := Number(state["PriceFilter_SliderMax"])
        if (minVal > maxVal)
            ui.Update("PriceFilter_SliderMin", "Value", String(maxVal))
    }
}
ClampSliderMax(state, ctrl, event) {
    if (state.Has("PriceFilter_SliderMin") && state.Has("PriceFilter_SliderMax")) {
        minVal := Number(state["PriceFilter_SliderMin"])
        maxVal := Number(state["PriceFilter_SliderMax"])
        if (maxVal < minVal)
            ui.Update("PriceFilter_SliderMax", "Value", String(minVal))
    }
}

ExecuteProcess(state, ctrl, event) {
    ui.Update("BtnExecute", "IsEnabled", "False")
    ui.Update("TxtStatus", "Text", "Connecting to " state["ComboRegion"] "...")
    ui.Update("TxtStatus", "Foreground", "#FF9F0A")
    ui.Update("LoadingSpinner", "Visibility", "Visible")

    ui.Update("LogList", "ClearItems", "")
    ui.Update("LogList", "AddItem", "Authenticating " state["TxtUser"] " on " state["ComboRegion"])
    proxyActive := state.Has("TglProxy") ? state["TglProxy"] : "False"
    ui.Update("LogList", "AddItem", "Proxy Active: " proxyActive)

    Loop 20 {
        ui.Update("SldPower", "Value", String(A_Index * 5))
        ui.Update("LogList", "AddItem", "[" A_Hour ":" A_Min ":" A_Sec "." A_MSec "] Processing payload chunk " A_Index "...")
        Sleep(40)
    }

    ui.Update("LogList", "AddItem", "")
    ui.Update("LogList", "AddItem", "--> DEPLOYMENT SUCCESSFUL.")
    ui.Update("LoadingSpinner", "Visibility", "Hidden")
    ui.Update("TxtStatus", "Text", "Deployment Successful!")
    ui.Update("TxtStatus", "Foreground", "#32D74B")
    ui.Update("BtnExecute", "IsEnabled", "True")
    ui.Update("BtnExecute", "Content", "RESTART SEQUENCE")
}

ToggleTaskSpinner(state, ctrl, event) {
    static taskActive := false
    taskActive := !taskActive
    if (taskActive) {
        ui.Update("TaskSpinner", "Visibility", "Visible")
        ui.Update("TaskPulsing", "Visibility", "Hidden")
        ui.Update("BtnToggleTask", "Visibility", "Collapsed")
        ui.Update("BtnStopTask", "Visibility", "Visible")
    } else {
        ui.Update("TaskSpinner", "Visibility", "Hidden")
        ui.Update("TaskPulsing", "Visibility", "Visible")
        ui.Update("BtnToggleTask", "Visibility", "Visible")
        ui.Update("BtnStopTask", "Visibility", "Collapsed")
    }
}

ClearSearchBox(state, ctrl, event) {
    ui.Update("TxtSearch", "Text", "")
    ui.Update("AppGrid", "Focus", "True")
}

CloseDropdown(state, ctrl, event) {
    ui.Update("SplitBtn", "IsChecked", "False")
    if (ctrl == "BtnManageUsers") {
        XDialog.Show({ Title: "Manage Users", Message: "You clicked the Manage Users button!", Icon: Chr(0xE77B), Buttons: ["OK"], Width: 300, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"] })
    } else if (ctrl == "BtnSettingsMenu") {
        XDialog.Show({ Title: "Settings", Message: "You clicked the Settings button!", Icon: Chr(0xE713), Buttons: ["OK"], Width: 300, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"] })
    }
}

ToggleBadge(state, ctrl, event) {
    static badgeState := 0
    badgeState++
    if (badgeState > 3)
        badgeState := 0

    if (badgeState == 0) {
        ui.Update("BdgBorder", "Visibility", "Collapsed")
    } else {
        ui.Update("BdgBorder", "Visibility", "Visible")
        if (badgeState == 1)
            ui.Update("BdgText", "Text", "1")
        else if (badgeState == 2)
            ui.Update("BdgText", "Text", "99+")
        else if (badgeState == 3)
            ui.Update("BdgText", "Text", "!")
    }
}

OnStrictSearchLostFocus(state, ctrl, event) {
    text := state["ComboStrictSearch"]
    valid := false
    for item in ["Administrator", "Moderator", "User", "Guest"] {
        if (text == item) {
            valid := true
            break
        }
    }
    if (!valid && text != "") {
        ui.Update("ComboStrictSearch", "Text", "")
    }
}

ShowAlertDialog(state, ctrl, event) {
    res := XDialog.Show({ Title: "Alert", Message: "This is your custom message content.", Icon: Chr(0xE946), IconColor: "#FF453A", Progress: true, Buttons: ["OK", "Cancel"], Width: 400, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"], Sound: "*-1" })
    if (res.Button == "OK")
        ui.Update("LogList", "AddItem", "Alert dialog accepted!")
}

ShowInputDialog(state, ctrl, event) {
    res := XDialog.Show({ Title: "What is your name?", Message: "This is your custom message content.", Icon: Chr(0xE70F), IconColor: "#0A84FF", InputText: "Type here...", Buttons: ["OK", "Cancel"], Width: 450, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"] })
    if (res.Button == "OK") {
        ui.Update("LogList", "AddItem", "User inputted: " res.Input)
        XDialog.Show({ Title: "Hello there!", Message: "Welcome to the AHKAST Workbench, " res.Input "!", Icon: Chr(0xE77B), IconColor: "#32D74B", Buttons: ["Awesome"], Width: 400, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"], Sound: "*-1" })
    }
}

ShowErrorDialog(state, ctrl, event) {
    XDialog.Show({ Title: "Critical Error", Message: "There was a critical error found before saving!`nThe following error was found in the board file:", Icon: Chr(0xE7BA), IconColor: "#FFD60A", DetailText: "MESSAGE: 0x0000000`n`nThis is a very long error message that will definitely wrap around to`nmultiple lines`n`nto test the selection functionality and ensure`nthat it works`ncorrectly`nacross all visible text within the control's boundaries.", DetailRows: 10, Buttons: ["Close"], Width: 550, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"], Sound: "*16" })
}

ShowAuthDialog(state, ctrl, event) {
    res := XDialog.Show({ Title: "Advanced Tool Authentication", Message: "The AI Agent has requested to execute a tool:", Icon: Chr(0xE7BA), IconColor: "#E0AA00", DetailText: "GET_TIME", DetailRows: 5, InputText: "Provide feedback or a reason for denial (Optional):", Buttons: ["Allow Execution", "Deny & Send Feedback"], Width: 500, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"], Sound: "*-1" })
    ui.Update("LogList", "AddItem", "Auth result: " res.Button)
}

ShowComplexDialog1(state, ctrl, event) {
    res := XDialog.Show({ Title: "Analyzing Workspace", Message: "The internal AST analyzer is currently scanning the environment and building the tree index. This might take a few moments.", Progress: true, Buttons: ["Cancel"], Width: 480, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"], WaitForResponse: false })
    dialogUi := res.Instance
    Loop 10 {
        if (res.Button != "")
            return
        dialogUi.Update("DialogProgSub1", "Text", "Scanning file " A_Index " of 10...")
        dialogUi.Update("DialogProg1", "Value", String(A_Index * 10))
        Sleep(300)
    }
    if (res.Button == "") {
        dialogUi.Update("DialogProgSub1", "Text", "Analysis complete.")
        Sleep(500)
        dialogUi.Update("Window", "Close", "")
        ui.Update("LogList", "AddItem", "Complex 1 result: Success")
    } else {
        ui.Update("LogList", "AddItem", "Complex 1 result: " res.Button)
    }
}

ShowComplexDialog2(state, ctrl, event) {
    res := XDialog.Show({ Title: "Diagnostic Terminal", Message: "Streaming live verbose logs from the backend engine. Press 'Abort' to stop.", DetailText: "Initializing diagnostics...", DetailRows: 7, Icon: Chr(0xE7BA), IconColor: "#FFD60A", Buttons: ["Abort", "Close"], Width: 550, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"], WaitForResponse: false })
    dialogUi := res.Instance
    logText := "Initializing diagnostics...`n"
    Loop 25 {
        if (res.Button != "")
            break
        logStr := "[" A_Hour ":" A_Min ":" A_Sec "." A_MSec "] Checking subsystem " A_Index "...`n"
        logText .= logStr
        dialogUi.Update("DialogDetail", "AppendText", logStr)
        Sleep(150)
    }
    if (res.Button == "") {
        dialogUi.Update("DialogDetail", "AppendText", "Diagnostics complete.")
        res.Button := "Closed by script"
    }
}

ShowComplexDialog3(state, ctrl, event) {
    res := XDialog.Show({ Title: "Regex Workspace Tool", Message: "Draft a new Regular Expression pattern. You can test it below:", InputText: "^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$", DetailText: "Test String Input:`nsupport@ahkast.io", DetailRows: 5, Resizable: true, Width: 600, Height: 500, Buttons: ["Execute Matches", "Clear", "Close"], Modal: false, AlwaysOnTop: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"] })
    ui.Update("LogList", "AddItem", "Complex 3 Tool Exit: " res.Button)
}

ShowComplexDialog4(state, ctrl, event) {
    res := XDialog.Show({ Id: "delete_confirm", Title: "Permanent Deletion", Message: "Are you sure you want to permanently delete these 14 files? This action cannot be undone.", DetailText: "C:\projects\ahk\ahk-xaml\v3-generator\example.ahk`nC:\projects\ahk\ahk-xaml\v2-csc\xaml.components.xaml`nC:\projects\ahk\ahk-xaml\v2-csc\XAMLEngine.ahk", DetailRows: 4, Icon: Chr(0xE74D), IconColor: "#FF453A", Buttons: ["Permanently Delete", "Cancel"], Width: 500, Modal: true, Owner: ui.wpfHwnd, Theme: state["ComboTheme"], Sound: "*16" })
    ui.Update("LogList", "AddItem", "Deletion result: " res.Button)
}

ShowTestModal(state, ctrl, event) {
    res := XDialog.Show({ Id: "test_modal", Title: "Modal Dialog Test", Message: "This is a simple modal dialog.", Icon: Chr(0xE814), Owner: ui.wpfHwnd, Modal: true, Theme: state.Has("ComboTheme") ? state["ComboTheme"] : "Dark Mica (Win 11)", Movable: false, ShowCloseBtn: false, DarkenOwner: true })
}

; NEW ADVANCED COMPONENTS TAB


Persistent()
global visibleTabs := 8

ToggleTabVis(state, ctrl, event) {
    global visibleTabs, tabList
    tabName := SubStr(ctrl, 7)
    tabId := "Tab_" tabName
    isChecked := (state[ctrl] == "True")

    if (!isChecked && visibleTabs <= 1) {
        ui.Update(ctrl, "IsChecked", "True")
        app.ShowSnackbar("At least 1 tab must remain visible!")
        return
    }

    if (isChecked) {
        ui.Update(tabId, "Visibility", "Visible")
        visibleTabs++
    } else {
        ui.Update(tabId, "Visibility", "Collapsed")
        visibleTabs--

        currIdx := -1
        if (state.Has("MainTabs") && state["MainTabs"] != "")
            currIdx := Integer(state["MainTabs"])
        tabIdx := -1
        for idx, tName in tabList {
            if (StrReplace(tName, " ", "") == tabName) {
                tabIdx := A_Index - 1
                break
            }
        }

        if (currIdx == tabIdx || currIdx == -1) {
            for idx, tName in tabList {
                cName := "TglTab" StrReplace(tName, " ", "")
                if (cName != ctrl && state.Has(cName) && state[cName] == "True") {
                    ui.Update("MainTabs", "SelectedIndex", String(A_Index - 1))
                    break
                }
            }
        }
    }
}

SyncTabVis(state, ctrl, event) {
    global visibleTabs, tabList
    visibleTabs := 0
    for idx, tName in tabList {
        cName := "TglTab" StrReplace(tName, " ", "")
        tId := "Tab_" StrReplace(tName, " ", "")
        if (state.Has(cName) && state[cName] == "True") {
            ui.Update(tId, "Visibility", "Visible")
            visibleTabs++
        } else {
            ui.Update(tId, "Visibility", "Collapsed")
        }
    }
}