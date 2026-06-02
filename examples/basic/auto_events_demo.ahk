#Requires AutoHotkey v2.0
#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Generator.ahk"
#Include "../../lib/XAML_Dialog.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Components.ahk"

; ==============================================================================
; Auto Events Demo — Showcases the XAML_AUTO_GENERATE_EVENTS flag.
;
; When you use .On("Click", "MyHandler") with a STRING function name that
; doesn't exist yet, the framework auto-generates a skeleton handler in:
;   <ScriptName>.events.ahk  →  auto_events_demo.events.ahk
;
; This demo has TWO modes:
;   1. First run: some handlers exist below, some don't (they'll be auto-generated)
;   2. After first run: open auto_events_demo.events.ahk and fill in the stubs!
;
; Lightweight events mode is enabled — events only include the trigger's value.
; ==============================================================================

; Enable auto-generation of missing event handlers
XAML_AUTO_GENERATE_EVENTS := true

; Auto-include the events file if it exists (generated on first run)
; *i = ignore if missing — safe on first run before the file is generated
#Include *i auto_events_demo.events.ahk

; --- Initialize ---
app := XAML_GUI("Auto Events Demo")
app.lightweightEvents := true

; Sidebar
app.sidebarPanel.Add("TextBlock").Text("SETTINGS").Margin("0,15,0,15").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold")
app.sidebarPanel.Toggle("TglDarkMode", "Dark Mode", true)
    .Track()
    .On("Click", OnDarkModeToggle)  ; ← this function EXISTS below

; --- Main Content ---
app.tabs.Visibility("Collapsed")
panel := app.main.Add("StackPanel").Grid_Row(1).Margin("40,20,40,20")

panel.Add("TextBlock").Text("Auto Events Demo").Use("PageTitle").Margin("0,0,0,5")
panel.Add("TextBlock").Text("Some handlers exist in this file. Missing ones are auto-generated in auto_events_demo.events.ahk").Use("BodyText").Foreground("{DynamicResource TextSub}").Margin("0,0,0,20")

; --- Section 1: Handlers defined HERE (inline) ---
panel.Add("TextBlock").Text("HANDLERS IN THIS FILE").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold").Margin("0,0,0,8")

nameRow := panel.Add("Grid").Margin("0,0,0,10")
nameRow.Cols("*", "10", "Auto")
nameRow.Add("TextBox").Name("TxtName").Grid_Column(0)
    .Track()
    .On("TextChanged", OnNameTyped)  ; ← EXISTS below

nameRow.Add("Button").Name("BtnGreet").Content("Greet!").Use("PrimaryBtn").Width(80).Height(32).Grid_Column(2)
    .On("Click", OnGreetClick)  ; ← EXISTS below

panel.Add("TextBlock").Text("STATUS").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold").Margin("0,10,0,8")
statusCard := panel.Add("Border").Use("CardPanel").Padding("12").Margin("0,0,0,20")
statusCard.Add("TextBlock").Name("TxtStatus").Text("Type your name and click Greet!").Foreground("{DynamicResource TextMain}").TextWrapping("Wrap").FontSize(13)

; --- Section 2: Handlers that will be AUTO-GENERATED ---
panel.Add("TextBlock").Text("AUTO-GENERATED HANDLERS (check .events.ahk file!)").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold").Margin("0,0,0,8")
panel.Add("TextBlock").Text("These use string function names that don't exist yet. The framework generates stubs for them automatically.").Use("BodyText").Foreground("{DynamicResource TextSub}").Margin("0,0,0,10")

autoRow := panel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,10")

; These handlers DON'T EXIST in this file — they'll be auto-generated!
autoRow.Add("Button").Name("BtnSave").Content("💾 Save").Use("PrimaryBtn").Width(100).Height(32).Margin("0,0,10,0")
    .On("Click", "OnSaveClick")

autoRow.Add("Button").Name("BtnExport").Content("📤 Export").Use("PrimaryBtn").Width(100).Height(32).Margin("0,0,10,0")
    .On("Click", "OnExportClick")

autoRow.Add("Button").Name("BtnReset").Content("🔄 Reset").Use("PrimaryBtn").Width(100).Height(32)
    .On("Click", "OnResetClick")

; A slider with auto-generated handler
panel.Add("TextBlock").Text("VOLUME (auto-generated handler)").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold").Margin("0,10,0,8")
panel.Add("Slider").Name("SldVolume").Minimum(0).Maximum(100).Value(75)
    .Track()
    .On("ValueChanged", "OnVolumeChanged")

; --- Section 3: Info about what was generated ---
panel.Add("TextBlock").Text("HOW IT WORKS").Foreground("{DynamicResource TextSub}").FontSize(11).FontWeight("Bold").Margin("0,15,0,8")

infoCard := panel.Add("Border").Use("CardPanel").Padding("12")
infoSp := infoCard.Add("StackPanel")
infoSp.Add("TextBlock").Foreground("{DynamicResource TextMain}").TextWrapping("Wrap").FontSize(12)
    .Text('1. Set XAML_AUTO_GENERATE_EVENTS := true'
        . "`n" '2. Use .On("Click", "OnSaveClick") with a STRING name'
        . "`n" "3. If OnSaveClick doesn't exist at Compile time..."
        . "`n" "4. → Framework creates auto_events_demo.events.ahk"
        . "`n" "5. → With a skeleton: OnSaveClick(state, ctrl, event) { }"
        . "`n" "6. → Fill in the skeleton and reload!")

; --- Compile & Show ---
ui := app.Compile()
app.Show()

; ==============================================================================
; Event Callbacks (defined in THIS file)
; ==============================================================================

OnNameTyped(state, ctrl, event) {
    val := state.Has("TxtName") ? state["TxtName"] : ""
    if (val != "")
        app.host.Update("TxtStatus", "Text", "Typing: " val " (" StrLen(val) " chars)")
    else
        app.host.Update("TxtStatus", "Text", "Type your name and click Greet!")
}

OnGreetClick(state, ctrl, event) {
    name := ui.Query("TxtName")
    if (name == "")
        name := "friend"
    app.ShowSnackbar("Hey " name "! 👋")
    app.host.Update("TxtStatus", "Text", "Greeted: " name)
}

OnDarkModeToggle(state, ctrl, event) {
    isDark := state.Has("TglDarkMode") && state["TglDarkMode"] == "True"
    app.host.Update("TxtStatus", "Text", "Dark Mode: " (isDark ? "ON" : "OFF"))
}

; NOTE: OnSaveClick, OnExportClick, OnResetClick, and OnVolumeChanged
; are NOT defined here. If they don't exist anywhere, the framework
; auto-generates skeleton stubs in: auto_events_demo.events.ahk

Persistent()