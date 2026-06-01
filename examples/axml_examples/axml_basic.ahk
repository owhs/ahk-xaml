#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\AXML.ahk"

; 1. Initialize Reactive State
global AppState := AXML_State({ Brightness: 75 })

; 2. Create base Window
app := XAML_GUI("AXML Basic Test", { Width: 600, Height: 400 })

; 3. Parse AXML into the main layout
result := AXML.ParseFile("axml_basic.axml", app.main, AppState)

; 4. Compile, Bind, and Show
ui := app.Compile()

; 5. Bind state and events dynamically BEFORE showing
AXML.BindAll(ui, result, AppState)

app.Show()

; --- Event Handlers ---
HandleBrightnessChanged(state, ctrl, event) {
    ; The UI Slider changed, update our state
    val := Round(Number(state["SldBrightness"]))

    ; Because we mapped AppState.Brightness to $Brightness in AXML,
    ; updating it here will automatically trigger ui.Update to the Slider AND the TextBlock!
    AppState.Brightness := val
}

HandleResetClick(state, ctrl, event) {
    ; Update state directly.
    ; The proxy will intercept this and automatically send ui.Update to the Slider AND the TextBlock.
    AppState.Brightness := 50
}

Persistent()