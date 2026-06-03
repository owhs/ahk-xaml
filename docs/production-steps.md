# Production Asset Workflow (`.dll` Bundling)

The engine supports a "compiled" production asset workflow. You can compile all of your dynamic XAML, events, and the WPF engine itself into a static, ultra-fast `.dll` file, completely eliminating the need for string parsing or `%TEMP%` file extraction in production.

## How It Works

### Development Mode
1. Your script builds the UI tree (`.Add()`, `.On()`, `.Track()` calls)
2. `app.Compile()` generates XAML from the tree and collects inline events
3. `app.ExportBundle("gui.dll")` compiles XAML → BAML, serializes events, bundles into DLL

### Production Mode
1. Your script builds the UI tree (same code — always runs)
2. `app.Load("gui.dll")` loads the precompiled DLL and harvests `.On()` events from the tree
3. Zero XML parsing, instant startup

## Usage

```ahk
#Requires AutoHotkey v2.0
#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Generator.ahk"
#Include "../../lib/XAML_Dialog.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Components.ahk"

global XAML_FORCE_DYNAMIC_COMPILE := true

; ========== UI DEFINITION (always runs) ==========
app := XAML_GUI("My App")
app.lightweightEvents := true

panel := app.main.Add("StackPanel").M("40,20,40,20")
panel.Add("TextBlock").Text("Production Demo").Use("PageTitle")
panel.Add("TextBox").Name("TxtInput").W(300).Track()
panel.Add("Button", { Name: "BtnSave", W: 120, H: 32 })
    .Text("Save")
    .Use("PrimaryBtn")
    .On("Click", OnSaveClick)

; ========== COMPILE / LOAD ==========
if (XAML_FORCE_DYNAMIC_COMPILE) {
    ui := app.Compile()
    app.ExportBundle("gui.dll")   ; creates the production bundle
} else {
    ui := app.Load("gui.dll")     ; loads precompiled + harvests .On() events
}

app.Show()

; ========== CALLBACKS ==========
OnSaveClick(state, ctrl, event) {
    val := ui.Query("TxtInput")
    app.ShowSnackbar("Saved: " val)
}

Persistent()
```

### Steps
1. Run your script with `XAML_FORCE_DYNAMIC_COMPILE := true`. This generates the UI, exports BAML, serializes events, and compiles into `gui.dll`.
2. Change the flag to `false`.
3. The app now instantly loads from `gui.dll` — zero XML parsing.

> [!IMPORTANT]
> **`.On()` and `.Track()` work with both paths.** The element tree (built by your `.Add()` calls) exists regardless of compile/load mode. Both `Compile()` and `Load()` call `_CollectInlineEvents()` to harvest inline events from the tree.

## Distribution

When distributing your final application, ship:
- `MyApplication.exe` (compiled AHK executable, e.g. `document_editor.exe`)
- `editor.dll` (the bundled WPF UI/BAML assembly, containing all resources and event bindings)

Place these two files side-by-side in the same folder. Users get instant startup with zero disk I/O, no XML parsing, and no `%TEMP%` file extraction.

## Build Scripts (`_build.ahk`)

To make compilation easy for distribution, you can create a build script (like [document_editor_build.ahk](../examples/clones/document_editor_build.ahk)) which automates building the precompiled DLL and the compiled executable.

The build script will:
1. Verify if the AutoHotkey interpreter (`AutoHotkey64.exe`) and compiler (`Ahk2Exe.exe`) are present.
2. If any of the required executable files are missing from their default paths, it will present a GUI dialog (`FileSelect`) prompting the user to locate them.
3. Automatically export the bundle (compiling BAML and events) into `editor.dll`.
4. Compile the AHK script using `Ahk2Exe` to output the final executable.

## Implementation Details

### Unified Asset Bundler (`XAML_GUI.ahk`)
`ExportBundle(outFile)` takes the final XAML string, compiles it into WPF `.baml` using MSBuild, serializes all AHK event bindings, and bundles everything into a standalone `.dll` (such as `editor.dll`).

### Zero-Overhead Asset Ingestion (`XAML_AHK_Bridge.cs`)
When `app.Load("editor.dll")` is called, the bridge loads the bundled DLL directly. BAML and events are embedded in the DLL's manifest resources — the C# engine ingests them instantly without file I/O.

### Side-by-Side Distribution
You no longer need `ahk-xaml.dll` alongside your executable. The bundled `editor.dll` is self-contained.
