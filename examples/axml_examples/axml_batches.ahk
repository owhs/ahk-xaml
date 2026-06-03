#Requires AutoHotkey v2.0

#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\AXML.ahk"
#Include "..\..\lib\XAML_Config.ahk"

NUM_BOXES := 100

; 1. Define State
initialData := { StatusText: "Ready. Click a button to begin benchmark." }
Loop NUM_BOXES {
    initialData.%"BoxColor" A_Index% := "#333333"
    initialData.%"BoxText" A_Index% := "-"
}
global appState := AXML_State(initialData)

; 2. Create base Window
app := XAML_GUI("IPC Batching Benchmark", { Width: 800, Height: 700 })

; 3. Parse AXML (which now natively expands the 100-box @For loop at compile time!)
axmlObj := AXML.ParseFile("axml_batches.axml", app.main, appState)

; 4. Compile, Bind, and Show
ui := app.Compile()
AXML.BindAll(ui, axmlObj, appState)
app.Show()

; --- Benchmarking Logic ---

global currentIteration := 0
global colors := ["#FF3333", "#33FF33", "#3333FF", "#FFFF33", "#FF33FF", "#33FFFF"]

GetTime() {
    DllCall("QueryPerformanceCounter", "Int64*", &counter := 0)
    DllCall("QueryPerformanceFrequency", "Int64*", &freq := 0)
    return (counter * 1000) / freq ; returns ms
}

RunStandard(uiState, ctrl, evt) {
    global currentIteration
    currentIteration++
    c := colors[Mod(currentIteration, colors.Length) + 1]

    appState.StatusText := "Running Standard Update (Unbatched)..."

    start := GetTime()

    ; Loop and update each property individually.
    ; Each assignment fires a synchronous IPC call.
    Loop NUM_BOXES {
        appState.%"BoxColor" A_Index% := c
        appState.%"BoxText" A_Index% := currentIteration
    }

    end := GetTime()
    elapsed := Round(end - start, 2)

    appState.StatusText := "Standard Update finished in " elapsed " ms (" (NUM_BOXES * 2) " IPC Calls)"
}

RunBatched(uiState, ctrl, evt) {
    global currentIteration
    currentIteration++
    c := colors[Mod(currentIteration, colors.Length) + 1]

    appState.StatusText := "Running Batched Update..."

    start := GetTime()

    ; Prepare a batch object
    batchObj := {}
    Loop NUM_BOXES {
        batchObj.%"BoxColor" A_Index% := c
        batchObj.%"BoxText" A_Index% := currentIteration
    }

    ; Dispatch EXACTLY 1 IPC call containing all updates
    appState.Batch(batchObj)

    end := GetTime()
    elapsed := Round(end - start, 2)

    appState.StatusText := "Batched Update finished in " elapsed " ms (1 IPC Call!)"
}