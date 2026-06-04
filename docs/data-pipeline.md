# AHK-XAML Data Pipeline & IPC Protocol

This document describes the Inter-Process Communication (IPC) architecture between the AHK script and the WPF/C# rendering engine, including the data encoding format, event flow, and query API.

## Architecture Overview

```
┌─────────────────────┐     WM_COPYDATA (0x004A)     ┌─────────────────────┐
│                     │ ──────────────────────────────▶ │                     │
│   AHK Script        │     UTF-8 pipe-delimited       │   C# WPF Engine     │
│   (XAML_Host.ahk)   │                                │   (XAML_AHK_Bridge)  │
│                     │ ◀────────────────────────────── │                     │
│                     │     Length-prefixed state       │                     │
└─────────────────────┘                                └─────────────────────┘
```

Both directions use Windows `WM_COPYDATA` (`0x004A`) messages with `COPYDATASTRUCT`. The payload is always UTF-8 encoded.

> [!NOTE]
> **In-Process CLR Mode Optimization:**
> When `XAML_IN_PROCESS_PREVIEW := true` is active, the communication channel still employs the `WM_COPYDATA` protocol, but the message transfer occurs inside the same process space between threads. This allows Windows to bypass cross-process marshalling and paging overhead, resulting in synchronous, near-zero-latency event loops and queries.

---

## 1. AHK → C# (Updates)

### Single Update

```
ui.Update("ControlName", "PropertyName", "Value")
```

**Wire format:** `ControlName|PropertyName|Value`

The C# engine splits by `|` with max 3 parts, so the value (3rd part) can contain `|` characters safely.

### Batch Update

```ahk
ui.BatchUpdate([
    { ControlName: "Ctrl1", PropertyName: "Text",       Value: "Hello" },
    { ControlName: "Ctrl2", PropertyName: "Background",  Value: "#FF0000" }
])
```

**Wire format** (newline-delimited):
```
Ctrl1|Text|Hello
Ctrl2|Background|#FF0000
```

Sent as a single `WM_COPYDATA` message. The C# `ProcessMessage()` splits by `\n` and processes each line individually.

---

## 2. C# → AHK (Events + State)

When a UI event fires (button click, text change, etc.), the C# engine sends an event back to AHK. There are two modes:

### Full Mode (Default)

The event includes the values of ALL tracked controls:

1. Calls `DumpState()` → `CollectState()` iterates every tracked control
2. Sends the event header + full state dump

### Lightweight Mode (`app.lightweightEvents := true`)

The event only includes the **triggering control's value**:

1. Calls `DumpState()` → `GetControlValue(triggerName)` for just one control
2. Sends the event header + only that control's value
3. Use `ui.Query()` when you need other controls' values

Lightweight mode dramatically reduces IPC payload for UIs with many tracked controls.

```ahk
; Opt-in before Show():
app.lightweightEvents := true

; In callbacks, use ui.Query() for other controls:
OnSubmitClick(state, ctrl, event) {
    name := ui.Query("TxtInput")  ; on-demand fetch
}
```

### Event Wire Format (Length-Prefixed)

```
EVENT|windowId|ControlName|EventName
TxtInput=5:Hello
SldValue=2:50
ComboRegion=9:US-East-1
```

Each state line uses **length-prefixed encoding**: `key=BYTELEN:rawvalue`

- `BYTELEN` = UTF-8 byte count of the value
- The value after `:` contains exactly that many UTF-8 bytes
- This allows ANY characters in values: emojis (😀 = 4 bytes), pipes (`|`), newlines (`\n`), null chars, CJK characters, etc.

### Event Data (5th field)

Some events include extra data in the event header:

```
EVENT|winId|MyDropZone|Drop|42:C:\path\to\file.txt|C:\another\file.doc
EVENT|winId|Canvas1|DragMove|7:100,200
EVENT|winId|Canvas1|ContextMenuOpened|11:150.5,200.3
```

The length prefix (`42:`, `7:`, `11:`) tells the parser exactly how many bytes to read, so embedded `|` and `\n` in the data are safe.

### Parsing Algorithm (AHK side)

```
Input: "TxtInput=16:Hello😀 Worl|d\nCtrl2=3:Foo\n"

1. Find "=" at pos 9 → key = "TxtInput"
2. Read digits "16" → byteLen = 16
3. Skip past ":" → value starts here
4. Count chars that span 16 UTF-8 bytes:
   H(1) e(1) l(1) l(1) o(1) 😀(4) _(1) W(1) o(1) r(1) l(1) |(1) d(1) = 16 ✓
5. Extract: "Hello😀 Worl|d"
6. Skip \n → next line
7. Repeat for "Ctrl2=3:Foo"
```

The `UTF8BytesToCharCount()` helper walks the string char-by-char, accumulating UTF-8 byte counts using codepoint arithmetic:
- `cp <= 0x7F` → 1 byte (ASCII)
- `cp <= 0x7FF` → 2 bytes (Latin extended, accented chars)
- `cp <= 0xFFFF` → 3 bytes (CJK, most symbols)
- `cp > 0xFFFF` → 4 bytes (emoji, rare chars)

---

## 3. Query API (On-Demand Reads)

The Query API allows reading control values on-demand without waiting for an event. It uses a batched `MQUERY`/`MRESPONSE` protocol.

### Single Query

```ahk
val := ui.Query("TxtInput")
; Returns: "Hello World" (string)
```

### Multi Query (one IPC call)

```ahk
state := ui.Query("TxtInput", "SldValue", "ComboRegion")
; Returns: Map("TxtInput" => "Hello", "SldValue" => "50", "ComboRegion" => "US-East-1")
```

### Wildcard Query

```ahk
allState := ui.Query("*")
; Returns: Map of ALL tracked controls and their current values
```

### Wire Protocol

```
AHK → C#:  MQUERY|TxtInput,SldValue,ComboRegion
           (or MQUERY|* for all tracked)

C# → AHK:  MRESPONSE|windowId|3
            TxtInput=5:Hello
            SldValue=2:50
            ComboRegion=9:US-East-1
```

The C# engine processes all requested controls in a single pass using the shared `GetControlValue()` helper (same logic as `CollectState()`).

---

## 4. Inline Event Registration

### New API: `.On()` and `.Track()`

Instead of manually calling `ui.OnEvent()` and `ui.Track()` after `Compile()`, you can declare events and tracking directly on elements during build:

```ahk
; NEW: Inline events — declared at build time
panel.Add("TextBox").Name("TxtName").Track().On("TextChanged", OnNameChanged)
panel.Add("Button").Name("BtnSubmit").On("Click", OnSubmitClick)
panel.Add("Slider").Name("SldValue").Track().On("ValueChanged", OnSliderChanged)
```

#### Features

| Feature | Syntax | Example |
|---------|--------|---------|
| Single event | `.On("Event", handler)` | `.On("Click", OnClick)` |
| Multi-event (CSV) | `.On("Evt1,Evt2", handler)` | `.On("Click,Focus", OnEvent)` |
| String function name | `.On("Event", "FuncName")` | `.On("Click", "OnClick")` |
| Inline closure | `.On("Event", (s,c,e) => ...)` | `.On("Click", (s,c,e) => DoThing())` |
| Track value | `.Track()` | `.Name("X").Track()` |

All methods are chainable.

#### How It Works

During `app.Compile()`, the framework walks the entire element tree and:
1. Finds all elements with `.On()` registrations
2. Resolves string function names to actual function references
3. Calls `ui.OnEvent()` and `ui.Track()` automatically
4. **No separate `AutoBind()` step needed**

### Auto-Generated Event Stubs

When `XAML_AUTO_GENERATE_EVENTS := true` is set and a string function name can't be resolved, the framework automatically creates a skeleton handler in `<ScriptName>.events.ahk`:

```ahk
; Auto-generated event handler for BtnSubmit.Click
OnSubmitClick(state, ctrl, event) {
    ; TODO: Implement handler
}
```

This only runs when executing as a script (not compiled).

---

## 5. Legacy API (Still Supported)

The traditional `ui.OnEvent()` and `ui.Track()` API remains fully functional:

```ahk
ui := app.Compile()

; Legacy: manual registration after Compile
ui.Track("TxtName")
ui.Track("SldValue")
ui.OnEvent("BtnSubmit", "Click", OnSubmitClick)
ui.OnEvent("TxtName", "TextChanged", OnNameChanged)

app.Show()
```

Both APIs can be mixed — use `.On()` for new elements and `ui.OnEvent()` for dynamic/runtime registrations.

---

## 6. Supported Control Types for Value Extraction

The `GetControlValue()` / `CollectState()` logic extracts values based on control type:

| Control Type | Default Value |
|---|---|
| `TextBox` | `.Text` |
| `PasswordBox` | `.Password` |
| `ToggleButton` / `CheckBox` | `.IsChecked` ("True"/"False") |
| `Slider` / `RangeBase` / `ProgressBar` | `.Value` (numeric string) |
| `ComboBox` | Selected item's `.Tag` or `.Content` |
| `TreeView` | Selected item's `.Tag` |
| `ListBox` | Selected item's `.Tag`, `.Content`, or `.ToString()` |
| `TextBlock` | `.Text` |
| `TabControl` | `.SelectedIndex` |
| `DataGrid` | `.SelectedIndex` |
| `Image` | `.Source` (URI string) |

---

## 7. Rich Queries (`>` Delimiter)

Use the `>` delimiter to query specific properties of rich components:

```ahk
ui.Query("MyList>Count")           ; total items in ListBox/ComboBox
ui.Query("MyList>Items")           ; all items pipe-delimited: "A|B|C"
ui.Query("MyList>SelectedIndex")   ; selected index (-1 if none)
ui.Query("MyGrid>SelectedRow")     ; DataGrid selected row pipe-delimited
ui.Query("MyGrid>FilteredCount")   ; DataGrid visible row count after filter
ui.Query("MainTabs>SelectedHeader") ; TabControl active tab header text
ui.Query("Canvas1>Nodes")          ; Node editor: "Name:x,y:tag|Name:x,y"
ui.Query("Canvas1>Connections")    ; Node connections: "A→B|B→C"
ui.Query("Canvas1>SelectedNode")   ; Currently selected node name
ui.Query("MyControl>IsEnabled")    ; Generic: any .NET property by name
ui.Query("MyControl>ActualWidth")  ; Generic: read computed layout values
```

### Available Suffixes

| Suffix | Controls | Returns |
|--------|----------|---------|
| `>Count` | Any `ItemsControl` (ListBox, ComboBox, DataGrid) | Item count |
| `>Items` | Any `ItemsControl` | Pipe-delimited item values |
| `>SelectedIndex` | Selector, TabControl | Selected index (int) |
| `>SelectedHeader` | TabControl | Active tab header text |
| `>SelectedRow` | DataGrid | Pipe-delimited cell values |
| `>FilteredCount` | DataGrid | Visible rows after filtering |
| `>CaretIndex` | TextBox | Cursor position |
| `>Nodes` | Canvas (node editor) | `Name:x,y:tag` per node |
| `>Connections` | Canvas (node editor) | Path elements tagged `conn:` |
| `>SelectedNode` | Canvas (node editor) | Node with "selected" tag |
| `>(PropertyName)` | Any control | Generic .NET property read |

> [!WARNING]
> The legacy `_CaretIndex` suffix still works for backward compatibility. New code should use `>CaretIndex`.

---

## 8. Custom Event Hooking

The framework supports ANY WPF event via `OnEvent()` or `.On()`:

```ahk
; Focus / Blur
.On("GotFocus", OnFocus)
.On("LostFocus", OnBlur)

; Mouse
.On("MouseEnter", OnHover)
.On("MouseLeave", OnLeave)
.On("PreviewMouseDown", OnMouseDown)

; Scroll
ui.OnEvent("MyScrollViewer", "ScrollChanged", OnScroll)

; Keyboard (key name appended: "KeyDown:Return")
.On("KeyDown", OnKeyDown)
.On("PreviewKeyDown", OnPreviewKey)

; Context menu (coordinates in event data)
.On("ContextMenuOpened", OnContextMenu)

; Drag & Drop (file paths in event data)
.On("Drop", OnFileDrop)

; Canvas / Node Editor
.On("DragMove", OnNodeDrag)       ; coordinate data
.On("DragCompleted", OnNodeDrop)
```

### Custom Events on Rich Components

For DataGridEx, NodeEditor, and other rich components that build their own sub-elements:

1. Use the component's built-in event API if available
2. For raw WPF events, target the sub-element name (e.g. `"MyGrid_TableSV"` for the scroll viewer inside DataGridEx)
3. Use `ui.Query("ctrl>PropertyName")` to read any .NET property generically

---

## 9. Naming Conventions

> [!IMPORTANT]
> **Do NOT use underscores in control names.** The framework uses `_` to convert attached properties: `Grid_Column` → `Grid.Column`. A name like `My_Control` would conflict with this system.

✅ Recommended naming:
- `TxtUserName`, `BtnSubmit`, `SldVolume`, `MyListBox`

❌ Avoid:
- `Txt_User_Name`, `btn_submit`, `my_list_box`

---

## 10. Configuration Flags

| Flag | Default | Description |
|------|---------|-------------|
| `app.lightweightEvents` | `false` | Property on app/GUI. When true, events only send the triggering control's value (use `ui.Query()` for others). |
| `XAML_FORCE_DYNAMIC_COMPILE` | `true` | When true, the C# engine (.dll) is recompiled from `XAML_AHK_Bridge.cs` on every run. When false, uses the pre-compiled DLL from `lib/dep/`. |
| `XAML_DIAGNOSTICS_ENABLED` | `true` | When true, crash dialogs show interactive "Skip Property" / "Skip Element" buttons for rapid iteration. |
| `XAML_AXML_DEBUG_MODE` | `true` | When true, dumps the AXML Abstract Syntax Tree to a local file when parsing AXML files. |
| `XAML_ENABLE_LOGGING` | `true` | When true, the framework writes trace and error logs to disk (e.g., `AhkTrace.log`, `AhkWpfError.log`). |
| `XAML_ENABLE_TRACING` | `true` | When true, enables XAML line-number and file tracing comments (`<!-- [ahk:File.ahk:LineNumber] -->`) during generation. |
| `XAML_AUTO_PREWARM` | `false` | When true, automatically spins up the background WPF engine as soon as the script launches to eliminate cold-start delay. |
| `XAML_ENABLE_DEVTOOLS` | `true` | When true, enables the premium developer tools panel (opens with F12 in any active app window). |
| `XAML_AUTO_GENERATE_EVENTS` | `false` | When true, auto-creates skeleton event handlers in `<ScriptName>.events.ahk` for missing string function names. |
| `XAML_ENABLE_WEBVIEW` | `false` | When true, compiles the engine with Microsoft WebView2 browser support. |
| `XAML_WEBVIEW_USER_DATA_DIR` | `""` | The directory where WebView2 stores its cache and user data. Defaults to `A_Temp "\AhkWpf\WebView2Data"`. |
| `XAML_ENABLE_AVALONEDIT` | `false` | When true, compiles with AvalonEdit for a robust code editor with syntax highlighting, line numbers, folding, and autocomplete. |
| `XAML_ENABLE_DOCUMENT` | `false` | When true, compiles with OpenXml SDK + NPOI for rich document viewing/editing (DOCX import/export, tables, etc.). |
