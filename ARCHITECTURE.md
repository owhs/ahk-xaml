# AHK-XAML Architecture

> A deep-dive into the internal design, data flow, and runtime mechanics of the `ahk-xaml` framework.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Runtime Architecture](#2-runtime-architecture)
3. [Compilation Pipeline](#3-compilation-pipeline)
4. [IPC Bridge & Data Flow](#4-ipc-bridge--data-flow)
5. [Event System & Callbacks](#5-event-system--callbacks)
6. [GUI Ownership & Window Management](#6-gui-ownership--window-management)
7. [State Persistence & Hot Reload](#7-state-persistence--hot-reload)
8. [Crash Recovery & Error Diagnostics](#8-crash-recovery--error-diagnostics)
9. [Dynamic UI Mutations](#9-dynamic-ui-mutations)
10. [Theming & Resource System](#10-theming--resource-system)
11. [WebView2 Integration](#11-webview2-integration)
12. [DevTools Process](#12-devtools-process)
13. [Production Builds](#13-production-builds)
14. [File Map](#14-file-map)

---

## 1. System Overview

`ahk-xaml` is a two-process architecture that separates business logic (AutoHotkey v2) from UI rendering (WPF/.NET). The AHK script constructs a UI declaratively using a chainable generator API. At launch time, the generated XAML markup is handed off to a dynamically compiled C# WPF executable, which renders the window on its own thread. All communication between the two processes happens via Win32 `WM_COPYDATA` messages.

```
┌─────────────────────────────────────────────────────────┐
│                    AHK Process                          │
│                                                         │
│  ┌──────────────┐   ┌─────────────────┐                 │
│  │ .axml File   │──>│ AXML Parser     │                 │
│  └──────────────┘   └────────┬────────┘                 │
│                              │                          │
│  ┌──────────────┐            ▼                          │
│  │ XAML_GUI.ahk │──>┌─────────────────┐                 │
│  │ (App Shell)  │   │ XAML_Generator  │                 │
│  └──────┬───────┘   │ (AST → XAML)    │                 │
│         │           └────────┬────────┘                 │
│         ▼                    ▼                          │
│         ▼                    ▼                          │
│  ┌──────────────────────────────────┐                   │
│  │          XAML_Host.ahk           │                   │
│  │  • Compiles C# engine (csc.exe)  │                   │
│  │  • Launches WPF process          │                   │
│  │  • Receives WM_COPYDATA events   │                   │
│  │  • Dispatches to AHK callbacks   │                   │
│  └──────────────┬───────────────────┘                   │
│                 │ WM_COPYDATA (0x004A)                  │
└─────────────────┼───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│                    WPF Process                          │
│         (AhkWpf_SharedEngine / ahk-xaml.dll)            │
│                                                         │
│  ┌──────────────────────────────────┐                   │
│  │       XAML_AHK_Bridge.cs         │                   │
│  │  • XamlReader.Load(stream)       │                   │
│  │  • DWM Mica/Acrylic integration  │                   │
│  │  • Event capture → SendToAhk()   │                   │
│  │  • ProcessMessage() → UI updates │                   │
│  │  • State dump on AHK reload      │                   │
│  └──────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

**Key principle:** The AHK process is the *controller*; the WPF process is the *view*. AHK never directly manipulates WPF elements. Instead, it sends string commands (`Update("BtnSave", "Text", "Saved!")`) which the C# engine interprets and applies to the live UI.

---

## 2. Runtime Architecture

### Process Lifecycle

1. **AHK starts** → `XAML_GUI.__New()` creates the generator AST.
2. **User code** loads an `.axml` file via the AXML parser, or calls `.Add()`, `.AddTab()`, etc. to build the tree programmatically.
3. **`app.Show()`** triggers:
   - `XAML_Generator.Compile()` serializes the AST to a XAML string.
   - `XAML_Host.CompileEngine()` invokes `csc.exe` to compile `XAML_AHK_Bridge.cs` into `ahk-xaml.dll` (first run only).
   - `XAML_Host.Show()` launches the engine executable with command-line args:
     ```
     ahk-xaml.dll <WinId> <AhkReceiverHwnd> <TrackedCSV> <AhkPID> <ScriptName> <XamlPath> <EventsPath> <OwnerHwnd>
     ```
4. **C# engine starts** → Creates a hidden `HwndSource` message window → Sends `EVENT|<id>|Engine|Ready|<MsgHwnd>` back to AHK.
5. **AHK receives Ready** → Streams the XAML payload + event bindings to the C# message window via `WM_COPYDATA`.
6. **C# parses XAML** → `XamlReader.Load()` → Window appears → Sends `EVENT|<id>|Window|LoadedHwnd|<Hwnd>`.
7. **Bidirectional IPC loop** begins.

### In-Process CLR Hosting Mode (Opt-In)

When `XAML_IN_PROCESS_PREVIEW := true` is set in `XAML_Config.ahk`, the framework switches from a two-process model to a **single-process CLR hosting model**.

#### Bootstrapping Mechanics
1. **CLR Boot:** `XAMLHost.InitializeInProcess()` dynamically initializes the .NET 4.0 Common Language Runtime (CLR) inside the parent AutoHotkey process using standard Windows `mscoree.dll` (`CorBindToRuntimeEx`).
2. **Memory Loading:** The engine DLL (`ahk-xaml.dll`) is read as raw bytes and loaded into the default AppDomain via reflection (`Assembly.Load(byte[])`), preventing file locking on disk.
3. **STA Thread Spawn:** C# spawns a new background `System.Threading.Thread` and sets its apartment state to Single-Threaded Apartment (`ApartmentState.STA`), which is a strict requirement for WPF.
4. **Dispatcher Loop:** The STA thread initializes the WPF `Application` object, loads all embedded styling resources (`LoadComponentStyles`), starts a hidden message receiver window, and enters the WPF `Dispatcher.Run()` loop.
5. **Direct Handle Retrieval:** The `StartInProcess` call returns the hidden message window's HWND directly to AHK, which assigns it to `XAMLHost.daemonHwnd`.

#### Communication & Performance Wins
- **Zero-Latency Interactions:** Mouse coordinates, visual tree structures, and property queries bypass the double process boundary traversal.
- **In-Memory Reflection:** Selecting elements in DevTools allows querying properties instantly via direct memory access rather than parsing serialized strings, yielding a massive performance boost.
- **Flawless Win32 Docking:** Placing a WPF preview window inside an AHK GUI container using `SetParent` works seamlessly without focus loss or input routing glitches because both parent and child reside in the same process space.

### Threading Model

- **AHK:** Single-threaded, but `OnMessage(0x004A)` is registered with `MaxThreads=255` to prevent message queue saturation during rapid UI initialization.
- **WPF:** Runs on its own STA thread via `Application.ShowDialog()`. All UI mutations happen on the WPF Dispatcher thread. The C# `ProcessMessage()` handler runs inline on the WPF thread since `WM_COPYDATA` is delivered synchronously.

---

## 3. Compilation Pipeline

### Configuration Flags (`XAML_Config.ahk`)

| Flag | Default | Purpose |
|---|---|---|
| `XAML_FORCE_DYNAMIC_COMPILE` | `false` | Recompile the C# engine from source on every run |
| `XAML_COMPONENTS_LOAD_MODE` | `"BAML"` | `"BAML"` for binary speed, `"XAML"` for live style editing |
| `XAML_DIAGNOSTICS_ENABLED` | `true` | Show "Skip Element/Property" buttons in crash dialogs |
| `XAML_ENABLE_TRACING` | `true` | Embed AHK source line comments in generated XAML |
| `XAML_ENABLE_WEBVIEW` | `false` | Include WebView2 Chromium browser support |

### AXML Parsing Pipeline

```
.axml File (AHK-XAML Markup)
         │
         ▼
    AXML Parser (Regex/Indentation Tokenizer)
         │
         ▼
    Abstract Syntax Tree (AST)
         │
         ▼
    XAML_Generator (AST → XAML Compiler)
```

The AXML parser reads the custom YAML-like indentation syntax, binds dynamic variables, and seamlessly constructs the AST in the exact same manner as traditional programmatic `ui.Add()` calls.

### Engine Compilation

```
XAML_AHK_Bridge.cs ──▶ csc.exe (Framework64 v4.0.30319) ──▶ ahk-xaml.dll
                          │
                          ├─ /target:winexe
                          ├─ /reference: PresentationFramework, PresentationCore, WindowsBase, System.Xaml
                          ├─ /reference: UIAutomationProvider, UIAutomationTypes
                          ├─ /resource: xaml.components.baml (pre-compiled binary styles)
                          ├─ /resource: xaml.components.xaml (text fallback)
                          └─ [optional] /reference: WebView2 DLLs + /define:ENABLE_WEBVIEW
```

The compiled DLL is cached in `lib/ahk-xaml.dll`. Subsequent runs skip compilation unless the DLL is deleted.

### BAML Precompilation (Component Styles)

The 78KB `xaml.components.xaml` style dictionary is pre-compiled into a 41KB binary BAML (Binary Application Markup Language) file using MSBuild. Both are embedded inside `ahk-xaml.dll` as manifest resources.

At daemon startup, the engine loads styles using a three-tier strategy:
1. **Tier 1 (BAML binary):** Loads pre-tokenized binary directly — no XML parsing, no reflection overhead (~5ms).
2. **Tier 2 (Embedded XAML text):** Falls back to parsing the embedded XAML string — no disk I/O (~150ms).
3. **Tier 3 (Disk file):** Falls back to reading `xaml.components.xaml` from the exe directory — legacy compatibility.

### Production Mode

In production, the pre-compiled `ahk-xaml.dll` is bundled via `FileInstall`. No C# compiler or source code is needed on the target machine.

### Asset Export Pipeline

```
XAML String
         │
         ▼
    gui_temp.xaml (UTF-8)
         │
         ▼
    MSBuild (local .NET framework)
         │
         ▼
    <ScriptName>.baml (native WPF compiled binary)
```

The `.baml` file can be loaded directly at startup using `Baml2006Reader`, bypassing XAML string parsing completely.

---

## 4. IPC Bridge & Data Flow

### Message Format

All IPC messages use the `WM_COPYDATA` (0x004A) Win32 message with UTF-8 encoded string payloads.

#### AHK → WPF (Commands)

```
ControlName|PropertyName|Value
```

Examples:
```
BtnSave|Text|Saved!
MyList|AddItem|New Entry
Window|DWM|2,1
Resource|Brush:Accent|#0A84FF
MyCanvas|AddXamlItem|<Path xmlns="..." ... />
```

#### WPF → AHK (Events)

```
EVENT|<WinId>|<ControlName>|<EventName>|<Base64Data>\n
<TrackedControl1>=<Base64Value>\n
<TrackedControl2>=<Base64Value>\n
```

The first line identifies the event. Subsequent lines contain the current values of all tracked controls (the "state snapshot"). Values are Base64-encoded to safely transmit special characters.

### State Tracking

When you call `ui.Track("TxtUsername")`, the control name is added to a CSV list passed to the C# engine at launch. On every event, the engine iterates all tracked controls and appends their current values to the event payload. This is how the `state` Map in AHK callbacks is populated.

Supported tracked types:
| WPF Type | Value Extracted |
|---|---|
| `TextBox` | `.Text` |
| `PasswordBox` | `.Password` |
| `ToggleButton` / `CheckBox` | `.IsChecked` (True/False) |
| `Slider` / `RangeBase` | `.Value` |
| `ComboBox` | Selected item content or `.Text` |
| `TreeView` | `.SelectedItem.Tag` |

---

## 5. Event System & Callbacks

### Registration Flow

```
AHK: ui.OnEvent("BtnSave", "Click", MyCallback)
  │
  ├─ Stored in XAMLHost.events["BtnSave"]["Click"]
  │
  └─ At launch, serialized as CSV: "BtnSave:Click,TxtSearch:TextChanged,..."
       │
       └─ C# BindEvent("BtnSave", "Click")
            │
            └─ Reflection: ctrl.GetType().GetEvent("Click")
                 │
                 └─ Expression.Lambda → compiled delegate → evt.AddEventHandler()
```

### Event Handler Signature

All AHK callbacks receive three parameters:

```ahk
MyCallback(state, ctrl, event) {
    ; state  → Map of all tracked control values
    ; ctrl   → String name of the control that fired
    ; event  → String name of the event (e.g. "Click")
}
```

For keyboard events, the event name includes the key: `"KeyDown:Return"`, `"KeyDown:Escape"`.

### Dynamic Event Binding

Events can be registered *after* the UI is loaded using `ui.OnEvent()`. The C# engine processes late-bound events identically to startup bindings via the same `BindEvent()` path.

---

## 6. GUI Ownership & Window Management

### Window Hierarchy

```
AHK Receiver Gui (hidden, message-only)
    │
    └── WPF Window (ahk-xaml.dll process)
              │
              └── [Optional] XDialog / XColorPicker (modal children)
```

### Owner Relationship

The `ownerHwnd` parameter sets native Win32 window ownership via `WindowInteropHelper.Owner`. This ensures:
- Modal dialogs stay above the parent
- The parent is re-focused when the dialog closes (`SetForegroundWindow` + `SetWindowPos`)
- The WPF window minimizes/restores with its owner

### Custom Chrome

All windows use `WindowChrome` with `WindowStyle="None"` for a fully custom titlebar. The framework handles:
- DWM rounded corners (Win11) via `DwmSetWindowAttribute(33)`
- Snap layout detection (maximized / half-screen states)
- Dynamic `CornerRadius` adjustment when snapped vs floating
- Custom Min/Max/Close buttons with hover effects

### DWM Integration

```ahk
ui.Update("Window", "DWM", "2,1")
;                          │ │
;                          │ └─ Dark mode (1=yes, 0=no)
;                          └─── Backdrop type (0=none, 1=Mica, 2=Acrylic, 3=MicaAlt)
```

---

## 7. State Persistence & Hot Reload

### State Dump on Reload

When the AHK script exits (e.g., during a hot reload), the C# engine detects the parent process death and automatically:

1. Calls `CollectState()` to serialize all tracked control values.
2. Writes to `%TEMP%\AhkWpf\AhkWpf_StateDump_<ScriptName>.ini`.
3. Exits gracefully.

On the next launch, the C# engine checks for this dump file and restores values:
- `TextBox` → `.Text`
- `PasswordBox` → `.Password`
- `ToggleButton` → `.IsChecked`
- `Slider` → `.Value`
- `ComboBox` → `.SelectedItem`

This creates a seamless "hot reload" experience where UI state survives script restarts.

### Component-Level Persistence

Advanced components like `XNodeGraph` implement their own `SaveState(file)` / `LoadState(file, ui)` methods using INI-formatted files with sections like `[Nodes]` and `[Links]`.

---

## 8. Crash Recovery & Error Diagnostics

### AHK Line Tracking

Every XAML element generated by `XAML_Generator` embeds a tracking comment:
```xml
<!-- [ahk:142] --><Button Width="100" />
```

When the C# engine encounters a `XamlParseException`, it:
1. Extracts the failing XAML line number.
2. Walks backwards to find the nearest `<!-- [ahk:N] -->` comment.
3. Reports the **AHK source line** that generated the bad markup.

### Error Dialog

The framework shows a rich error dialog with:
- The AHK line that caused the crash
- A ±8 line XAML snippet with the error line marked with `>>`
- Full .NET exception trace
- Auto-scrolling to the error position

### Crash Detection

`XAMLHost.CheckForCrashes()` runs on a 500ms timer. If the engine process writes to `AhkWpfError.log` and exits, AHK picks up the log, displays the error dialog, and terminates.

---

## 9. Dynamic UI Mutations

After the window is loaded, AHK can manipulate the live UI through the `Update()` command system.

### Supported Commands

| Command | Target | Description |
|---|---|---|
| `Text` | TextBlock, TextBox | Set text content |
| `Content` | Button, Label | Set content |
| `Visibility` | Any UIElement | `Visible`, `Collapsed`, `Hidden` |
| `IsEnabled` | Any Control | `True`, `False` |
| `Background` | Control, Border | Color string or `{DynamicResource}` |
| `Foreground` | Control | Color or resource |
| `BorderBrush` | Border, Control | Color or resource |
| `Stroke` / `Fill` | Shape | Color or resource |
| `Data` | Path | Geometry path string |
| `AddItem` | ItemsControl | Add string item |
| `AddXamlItem` | ItemsControl, Panel | Parse and inject raw XAML |
| `RemoveItem` | ItemsControl | Remove by content match |
| `ClearItems` | ItemsControl, Panel | Remove all children |
| `SetPosition` | UIElement (Canvas) | `X,Y` coordinates |
| `EnableDrag` | UIElement (Canvas) | Enable drag-to-move |
| `EnableZoomPan` | Canvas | Enable scroll zoom + middle-click pan |
| `Navigate` | WebView2 | Navigate to URL |
| `ExecuteScript` | WebView2 | Run JavaScript (Base64) |
| `OpenDevTools` | WebView2 | Open Chrome DevTools |
| `Document` | RichTextBox | Replace FlowDocument (XAML string) |
| `Source` | Image | Image path, URL, or `HICON:handle` |
| `Play` / `Pause` / `Stop` | MediaElement | Media playback |
| `DWM` | Window | Set backdrop + dark mode |
| `Title` | Window | Set window title |
| `Icon` | Window | Set window icon (`HICON:handle`) |
| `Focus` | Any | Set keyboard focus |
| `Invoke` | ButtonBase | Programmatic click |
| `ScrollIntoView` | ListBox | Scroll to selected |

### Dynamic XAML Injection

New elements can be injected into the live UI at runtime:
```ahk
xamlStr := '<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Text="Dynamic!" />'
ui.Update("MyPanel", "AddXamlItem", xamlStr)
```

The C# engine:
1. Parses the string via `XamlReader.Parse()`
2. Walks the visual tree to register all `x:Name` attributes in the window's `NameScope`
3. Adds the element to the target panel's `Children` collection

> **Important:** Dynamically injected elements must include the full `xmlns` declaration since they are parsed in isolation.

---

## 10. Theming & Resource System

### Architecture

Themes are defined in `themes.ini` as key-value pairs per section:
```ini
[Dark Mica (Win 11)]
Window_DWM=2,1
Resource_Brush:BgColor=#01000000
Resource_Brush:Accent=#0A84FF
Resource_Brush:TextMain=#FFFFFF
```

At runtime, the `ThemeChanged` handler reads the INI section and sends each line as:
```ahk
ui.Update("Resource", "Brush:TextMain", "#FFFFFF")
```

The C# engine applies these to `Window.Resources` and `Application.Current.Resources`, which triggers WPF's `DynamicResource` bindings throughout the visual tree.

### Resource Types

| Prefix | WPF Type |
|---|---|
| `Brush:` | `SolidColorBrush` |
| `Thickness:` | `Thickness` |
| `CornerRadius:` | `CornerRadius` |
| `Double:` | `double` |

### Base Style Dictionary

All control templates are defined in `lib/xaml.components.xaml` (~78KB). This file is injected into the Window XAML at compile time via template substitution (`%components%`). It contains:
- Custom styles for every standard WPF control (Button, TextBox, ComboBox, etc.)
- Win11-style toggle switches, segmented buttons, hamburger menus
- Ribbon control templates
- SearchBox and NumericUpDown templates
- ProgressRing and PulsingRing styles

---

## 11. WebView2 Integration

### Conditional Compilation

WebView2 support is gated behind `XAML_ENABLE_WEBVIEW := true` in `XAML_Config.ahk`. When enabled:
- The C# source is compiled with `/define:ENABLE_WEBVIEW`
- WebView2 NuGet DLLs from `lib/WebView2/` are referenced
- The `XWebView` AHK class becomes available

### Runtime Flow

1. On `Window.Loaded`, the engine walks the visual tree for `WebView2` instances.
2. Creates a `CoreWebView2Environment` with user data stored in `%TEMP%\AhkWebView2Data`.
3. Calls `EnsureCoreWebView2Async()` to initialize the Chromium renderer.
4. Hooks `WebMessageReceived` and `NavigationCompleted` events.

### AHK ↔ JavaScript Bridge

```
AHK → C# → WebView2.ExecuteScriptAsync(js)     // Inject JS
JS  → window.chrome.webview.postMessage(msg)     // Send to AHK
C#  → EVENT|...|WebMessageReceived|<Base64Msg>   // Delivered to AHK callback
```

---

## 12. DevTools Process

`ahk-xaml` includes an interactive Developer Tools suite (`XAML_DevTools.ahk`) designed to aid in UI inspection, property tracking, console execution, and IPC debugging. 

### Process & IPC Scaffolding

```
┌──────────────────────────────────────┐          Monitor IPC          ┌───────────────────────────────┐
│        Target Application            │══════════════════════════════>│       DevTools Process        │
│  (XAML_GUI main loop & WPF Process)  │                               │  • Separate XAML_GUI window   │
│                                      │<══════════════════════════════│  • Live tree view inspector   │
│                                      │          Inspect / Console    │  • Property grid viewer       │
└──────────────────────────────────────┘                               └───────────────────────────────┘
```

1. **Independent Environment:** DevTools runs as its own separate `XAML_GUI` process instance, avoiding interference with the target application's main thread and UI state.
2. **Monitor IPC:** The target application registers the global `XAML_DevTools_Instance` variable. Whenever IPC commands or events traverse between AHK and WPF, the traffic is duplicated and piped directly to the DevTools log window.
3. **Inspect Live Tree:** DevTools queries the target WPF process via a specialized `DEVTOOLS|GetTree` command. The C# bridge walks the visual tree, serializes the node types, coordinates, and lines, and returns them to DevTools to populate its `TreeView` element.
4. **Interactive Highlighting:** Selecting an element in the DevTools tree sends a `DEVTOOLS|Highlight|<Hash>` request. The WPF process draws a temporary semi-transparent overlay bounding box around the targeted control for easy identification.

### Developer Tabs

- **Elements Tab:** Traverses the full layout hierarchy. Features a collapsible **inspect** button allowing the user to hover over controls on the target window and click to auto-select them in the visual tree. Displays three property sub-tabs:
  - *Styles:* Shows applied local and inherited WPF styles.
  - *Computed:* Shows the box model layout (Margin, Border, Padding, and actual dimensions).
  - *Properties:* Offers real-time inspection of WPF dependency properties and fields, searchable and filterable by preset categories.
- **Pipeline Tab:** Displays a chronological, microsecond-accurate log of all `WM_COPYDATA` messages. Shows headers, byte sizes, and base64-decoded payloads.
- **Console Tab:** An interactive command-line prompt to evaluate AHK expressions or send direct mutation commands to the target rendering engine.

---

## 13. Production Builds

### Export Workflow

```ahk
app.ExportBAML()
```

1. Serializes XAML to a temporary `<ScriptName>.xaml` file wrapped in a `<ResourceDictionary>`.
2. Creates a temporary MSBuild project file (`.csproj`).
3. Invokes the local MSBuild toolchain (bundled with Windows/Visual Studio) to compile the XAML to a native WPF `.baml` file.
4. Outputs `<ScriptName>.baml` to the script directory.

### Distribution Model

A production deployment consists of:
```
MyApp.exe          ← Compiled AHK script
ahk-xaml.dll       ← Pre-compiled WPF engine (via FileInstall)
MyApp.baml         ← Compiled UI binary resource
```

At runtime:
1. AHK extracts `ahk-xaml.dll` from resources if needed.
2. AHK runs in "production mode" by skipping the `XAML_Generator` GUI building code completely.
3. Launches the engine with `<ScriptName>.baml` as the asset path.
4. The engine loads the UI instantly natively using `Baml2006Reader` — no C# compiler required and no XML parsing overhead.

---

## 14. File Map

```
ahk-xaml/
├── lib/
│   ├── XAML_Host.ahk             # Core IPC bridge, engine compilation, message dispatch
│   ├── XAML_Generator.ahk        # Chainable AST → XAML compiler
│   ├── XAML_GUI.ahk              # High-level app scaffolding (window, tabs, sidebar, themes)
│   ├── XAML_Config.ahk           # Global flags (XAML_DEBUG, XAML_ENABLE_WEBVIEW)
│   ├── XAML_Components.ahk       # Standard components, composites, data grids, rating, emoji
│   ├── XAML_Adv_Components.ahk   # Advanced components (NodeGraph, CodeEditor, WebView, etc.)
│   ├── XAML_DevTools.ahk         # Floating inspect panel, property inspector, console, and IPC log
│   ├── XAML_Dialog.ahk           # Modal dialog system (XDialog)
│   ├── XAML_AHK_Bridge.cs        # C# WPF engine source (compiled at runtime)
│   ├── xaml.components.xaml       # WPF ResourceDictionary (all control templates & styles)
│   ├── xaml.components.baml       # Pre-compiled binary BAML (generated via MSBuild)
│   ├── ahk-xaml.dll              # Compiled WPF engine binary (cached)
│   └── WebView2/                 # WebView2 runtime DLLs (optional)
├── examples/
│   ├── example.ahk               # Full showcase with all component tabs
│   ├── example_advanced.ahk      # NodeGraph, Media, SVG, Code Editor, etc.
│   ├── example_docking.ahk       # Multi-panel docking workspace
│   ├── example_webview.ahk       # WebView2 browser demo
│   ├── example_basic.ahk         # Minimal starter
│   ├── ribbon_example.ahk        # Office-style ribbon toolbar
│   └── themes.ini                # Theme color definitions
├── README.md                     # Quick start guide
├── Components.md                 # Full component reference
├── SyntaxAndPrinciples.md        # Generator syntax & theming
└── ARCHITECTURE.md               # This document
```
