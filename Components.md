# AHK-XAML Component Reference

> The `ahk-xaml` framework bridges AutoHotkey v2 directly to the WPF runtime.  
> **Any valid WPF UIElement** can be instantiated via `.Add("TypeName")` — the components below are the **themed, pre-styled, and abstracted** building blocks optimized for rapid UI development.

---

## Table of Contents

1. [XAML_GUI Application Wrapper](#i-xaml_gui-application-wrapper)
2. [Standard WPF Controls (Themed)](#ii-standard-wpf-controls-themed)
3. [Custom Composites](#iii-custom-composites)
4. [Advanced Components](#iv-advanced-components)
5. [Visualization Components](#v-visualization-components)
6. [Data & Tables](#vi-data--tables)
7. [Overlays & Contexts](#vii-overlays--contexts)
8. [Event System](#viii-event-system)

---

## I. XAML_GUI Application Wrapper

The `XAML_GUI` class scaffolds a complete, modern application window with DWM Mica integration, a custom titlebar, optional sidebar, tab navigation, and theme management.

### Constructor

```ahk
options := Map(
    "Width", 940,            ; Default window width (optional)
    "Height", 700,           ; Default window height (optional)
    "Resize", true,          ; Enable/disable window resizing (optional, default true)
    "Sidebar", true,         ; Show/hide left sidebar
    "BurgerMenu", true,      ; Show/hide hamburger toggle in titlebar
    "MinMaxButtons", true,   ; Show/hide minimize/maximize buttons
    "AppIcon", true          ; Show/hide app icon in titlebar
)

app := XAML_GUI("My Application", options)
```

### Key Methods

| Method | Description |
|---|---|
| `app.AddTab(title, builderFn)` | Register a tab; `builderFn(tab)` receives the tab content panel |
| `app.Show()` | Compile and display the window |
| `app.Export(path)` | Export UI as a compressed `.bin` asset for production |
| `app.ShowSnackbar(msg, duration?)` | Display a toast notification at the bottom |
| `app.RegisterTokenizer(tok)` | Register a Tokenizer for keyboard hooks |
| `app.RegisterNumericInput(num)` | Register a NumericUpDown for arrow key support |
| `app.RegisterHotKeyChange(el, cb)` | Register a HotKeyBox for key capture |
| `app.RegisterSegmentedInput(seg)` | Register a SegmentedNetworkInput for auto-tab |
| `app.main` | Direct reference to the main content area |

### Sidebar Settings

```ahk
; Add settings to the sidebar
app.sidebar.SettingItem("Dark Mode", "Enable dark theme", "ToggleSwitch", "True")
app.sidebar.SettingItem("Scale", "Interface density", "ComboBox", "Balanced")
```

---

## II. Standard WPF Controls (Themed)

All standard WPF controls are automatically styled by `xaml.components.xaml` to match the active theme (Dark Mica, Light Frosted, etc.).

### Layout Containers

| Type | Usage |
|---|---|
| `Grid` | Row/column layouts with `.Rows()` and `.Cols()` |
| `StackPanel` | Linear stacking with `.Orientation("Horizontal")` |
| `DockPanel` | Dock children to edges |
| `WrapPanel` | Auto-wrapping flow layout |
| `ScrollViewer` | Scrollable container |
| `Border` | Rounded containers with `.Use("CardPanel")` |
| `Expander` | Collapsible sections |

```ahk
; Grid with rows and columns
grid := parent.Add("Grid").Margin("10")
grid.Rows("Auto", "*", "Auto")
grid.Cols("200", "*")

; Card Panel (rounded, themed background)
card := parent.Add("Border").Use("CardPanel").Padding("20")

; Expander
exp := parent.Add("Expander").Header("Advanced Settings")
exp.Add("StackPanel").Add("TextBlock").Text("IP: 192.168.1.1")
```

### Buttons

| Style | Usage |
|---|---|
| Default | `parent.Add("Button").Content("Cancel")` |
| Primary | `.Use("PrimaryBtn")` — accent-colored |
| Icon | `.Use("IconBtn")` — compact, subtle |
| Hamburger | `.Style("{StaticResource HamburgerButton}")` |
| ToggleButton | `.Add("ToggleButton").Content("Toggle")` |
| RepeatButton | `.Add("RepeatButton")` — fires while held |

```ahk
; Primary accent button
parent.Add("Button").Content("Save").Use("PrimaryBtn").Cursor("Hand")

; Icon button with Segoe Fluent Icons
parent.Add("Button").Content(Chr(0xE74D)).FontFamily("Segoe Fluent Icons").Use("IconBtn")
```

### CheckBox, RadioButton, ToggleSwitch

```ahk
; Standard checkbox
parent.Add("CheckBox").Content("Remember me").IsChecked("True")

; Toggle Switch (Win11 style)
parent.Add("CheckBox").Content("Wi-Fi").Style("{StaticResource ToggleSwitch}")

; Radio buttons
parent.Add("RadioButton").Content("Option A").GroupName("G1").IsChecked("True")
parent.Add("RadioButton").Content("Option B").GroupName("G1")

; Segmented buttons
parent.Add("RadioButton").Content("Map").Style("{StaticResource SegmentedBtn}").IsChecked("True")
parent.Add("RadioButton").Content("Satellite").Style("{StaticResource SegmentedBtn}")
```

### Text Inputs

```ahk
; Single-line
parent.Add("TextBox").Text("Hello").Name("MyInput")

; Password
parent.Add("PasswordBox").Width(200)

; Multi-line
parent.Add("TextBox").TextWrapping("Wrap").AcceptsReturn("True").Height(100)

; Styled SearchBox
parent.Add("TextBox").Style("{StaticResource SearchBox}").Tag("Search query...")
```

### Progress Indicators

```ahk
; Linear progress bar
parent.Add("ProgressBar").Value(75).Maximum(100).Height(20)

; Indeterminate
parent.Add("ProgressBar").IsIndeterminate("True").Height(4)

; Circular spinner (progress ring)
parent.Add("ProgressBar").Style("{StaticResource ProgressRing}").Width(40).Height(40)

; Glowing pulsing ring
parent.Add("ProgressBar").Style("{StaticResource PulsingRing}")
```

### ComboBox, ListBox, TabControl

```ahk
; ComboBox with items
combo := parent.Add("ComboBox").Width(200).Name("MyCombo")
combo.Add("ComboBoxItem").Content("Option 1").IsSelected("True")
combo.Add("ComboBoxItem").Content("Option 2")

; Tab Control
tabs := parent.Add("TabControl")
tabs.Add("TabItem").Header("General").Add("TextBlock").Text("Content")
```

### Slider

```ahk
parent.Add("Slider").Minimum(0).Maximum(100).Value(50).Name("MySlider")
```

---

## III. Custom Composites

High-level components that inject complex XAML trees automatically.

### Toggle

A pre-formatted toggle switch row with label.

```ahk
panel.Toggle("DarkModeToggle", "Enable Dark Mode", true)
```

### SegmentGroup

A group of radio buttons styled as segmented tabs.

```ahk
panel.SegmentGroup("ViewMode", ["Map", "Satellite", "Hybrid"], 1)
```

### MetricCard

A dashboard KPI card with title, metric, and optional progress bar.

```ahk
panel.MetricCard("MEMORY", "4.2 GB", "+12%", "#32D74B")
panel.MetricCard("DISK", "68%", "", "", 68)  ; With progress bar
```

### TelemetryRow

A status row for monitoring dashboards.

```ahk
panel.TelemetryRow("SRV-01", "US East", "12ms", "Online", "#32D74B")
```

### XColorPicker

A modal color picker dialog with hex input, hue slider, and saturation/brightness plane.

```ahk
result := XColorPicker.Show({
    Title: "Choose Color",
    DefaultColor: "#FF0A84FF",
    Owner: ui.wpfHwnd,
    Modal: true,
    Theme: "Dark Mica (Win 11)"
})

if (result.Status == "OK")
    ui.Update("Preview", "Background", result.Color)
```

### XDialog

A full-featured modal dialog replacement for `MsgBox`.

```ahk
result := XDialog.Show({
    Title: "Error",
    Message: "Parse failed.",
    Icon: Chr(0xE783),
    IconColor: "#FFCC00",
    DetailText: "Line 42: Unexpected identifier",
    Buttons: ["Retry", "Abort"],
    Modal: true,
    Owner: ui.wpfHwnd,
    DarkenOwner: true
})

if (result.Button == "Abort")
    ExitApp()
```

### SettingItem

A pre-formatted row for settings panels: title, description, and an interactive control.

```ahk
; Toggle switch
panel.SettingItem("Hardware Accel", "Use GPU rendering", "ToggleSwitch", "True")

; Button
panel.SettingItem("Clear Cache", "Delete temp files", "Button", "Clear Now")

; ComboBox
panel.SettingItem("Theme", "Visual theme", "ComboBox", "Dark", ["Dark", "Light", "Auto"])
```

### Tokenizer

A tag/pill manager — type and press Enter to add tokens, click X to remove.

```ahk
tok := panel.Tokenizer("Categories", ["AutoHotkey", "WPF", "Design"])
app.RegisterTokenizer(tok)
```

### NumericUpDown

A spinner input with up/down buttons and keyboard arrow support.

```ahk
num := panel.NumericUpDown("FontSize", 8, 72, 14)
app.RegisterNumericInput(num)
```

---

## IV. Advanced Components

Abstracted, self-contained components with rich configuration options.

### CommandBar

A horizontal toolbar with icon buttons and separators.

```ahk
cmdBar := panel.CommandBar("MyToolbar")
cmdBar.AddButton(Chr(0xE74D), "Cut", "BtnCut", "Cut (Ctrl+X)")
cmdBar.AddSeparator()
cmdBar.AddButton(Chr(0xE8C8), "Copy", "BtnCopy", "Copy (Ctrl+C)")
cmdBar.AddButton(Chr(0xE77F), "Paste", "BtnPaste", "Paste (Ctrl+V)")
```

### XCommandPalette

A robust, VS Code-style command palette with real-time search, keyboard navigation, mode switching, and extensible architecture.

**Constructor:**

```ahk
cmdPalette := XCommandPalette(app.overlay, "CmdPal")
```

**Registering Commands:**

```ahk
; Simple command
cmdPalette.AddCommand("reload", "Developer: Reload Window")

; Rich command with icon, shortcut, category, and per-command callback
cmdPalette.AddCommand("settings", "Preferences: Open Settings", {
    Icon: Chr(0xE713),
    Shortcut: "Ctrl+,",
    Category: "Preferences",
    Callback: (id) => OpenSettings()
})
```

**Command Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `Icon` | String | `""` | Segoe Fluent Icons character for the result item |
| `Shortcut` | String | `""` | Keyboard shortcut badge displayed on the right |
| `Category` | String | `""` | Grouping category (for future filtering) |
| `Callback` | Func | `""` | Per-command callback `fn(id)`. If set, fires instead of `OnCommandSelected` |

**Home Screen & Recent History:**

```ahk
; Set which commands appear on the home screen (when input is empty)
cmdPalette.SetHomeCommands(["settings", "terminal", "reload"])

; Recent commands auto-populate the home screen after execution
; (up to 5 most recent, replacing the default home list)
```

**Mode System (Prefix Routing):**

| Prefix | Mode | Description |
|---|---|---|
| *(empty)* | Home | Shows recently used / home commands |
| `>` | Commands | Filters across all registered commands |
| `?` | Help | Shows built-in navigation help items |
| *(custom)* | Custom | Register via `AddMode(prefix, label, filterFn)` |

```ahk
; Custom mode: search files with @ prefix
cmdPalette.AddMode("@", "Files", (query) => SearchFiles(query))
```

**Custom Data Source:**

```ahk
; Append results from external source to any query
cmdPalette.SetDataSource((query) => FetchFromAPI(query))
```

**Binding & Hotkey:**

```ahk
ui := app.Compile()
cmdPalette.Bind(ui, "^+P")  ; Ctrl+Shift+P to open
```

**Global Callback:**

```ahk
cmdPalette.DefineProp("OnCommandSelected", { Call: HandleCommand })
HandleCommand(this, id) {
    if (id == "settings")
        OpenSettings()
    else
        XDialog.Show({ Title: "Executed", Message: id, Buttons: ["OK"] })
}
```

**Keyboard Navigation:**

| Key | Action |
|---|---|
| `↑` / `↓` | Navigate results (wraps around) |
| `Enter` | Execute highlighted command (or first result) |
| `Escape` | Close the palette |
| `Home` / `End` | Jump to first / last result |

**Features:**
- Real-time search with case-insensitive substring matching
- Dynamically injected XAML result items with icon, label, and shortcut badge
- Automatic caret-to-end on every keystroke (unless explicitly repositioned)
- Click-away dismiss via the scrim overlay
- Recent command history (last 5 executed commands auto-populate home screen)
- Theme-aware: all colors use `{DynamicResource ...}` tokens
- Drop shadow and rounded corners for premium appearance

### NavigationView

A sidebar router with page-switching navigation, styled like Win11 Settings.

```ahk
nav := panel.NavigationView("MyNav")

; Build page content
page1 := XAML_Generator("StackPanel")
page1.Add("TextBlock").Text("Dashboard Content")

page2 := XAML_Generator("StackPanel")
page2.Add("TextBlock").Text("Settings Content")

; Add pages
nav.AddPage("Dashboard", Chr(0xE80F), page1)
nav.AddPage("Settings", Chr(0xE713), page2, true)  ; true = bottom item

; Bind events
nav.Bind(ui)
```

### KanbanBoard

A fully functional, drag-and-drop Kanban board supporting dynamic columns, ticket movement, and color-coded tags.

**Setup & Initialization:**
```ahk
kanban := panel.KanbanBoard("MyKanban")

; Add columns with custom accent colors
kanban.AddColumn("To Do", "#FF453A")
kanban.AddColumn("In Progress", "#FF9F0A")
kanban.AddColumn("Done", "#32D74B")

; Add cards to specific columns (1-indexed based on addition order)
kanban.AddCard(1, "Design mockups")
kanban.AddCard(1, "Fix navigation bug")
kanban.AddCard(2, "Write unit tests")
kanban.AddCard(3, "Deploy to production")
```

**Event Wiring & Drag-and-Drop:**
```ahk
; Bind internal events (Selection, Add button clicks)
kanban.Bind(ui)

; Explicitly enable drag-and-drop functionality between columns
kanban.EnableDrag(ui)
```

**Programmatic Updates:**
```ahk
; Move the currently selected card to a different column index
kanban.MoveSelectedTo(3) ; Moves to "Done"
```

### NodeGraph / Visual Scripter

A fully interactive node-based visual programming environment with zoom, pan, drag, connection drawing, and state persistence.

**Setup & Initialization:**
```ahk
graph := panel.NodeGraph("MyGraph")

; Add nodes: ID, Title, X, Y, Type (Input/Process/Output/Action)
graph.AddNode("Input1", "REST API Source", 100, 40, "Input")
graph.AddNode("Filter", "Filter Records", 280, 40, "Process")
graph.AddNode("Output", "Export JSON", 500, 100, "Output")

; Programmatically create Bézier connections between nodes
graph.AddConnection("Input1", "Filter")
graph.AddConnection("Filter", "Output")
```

**Event Wiring & Interaction:**
```ahk
; Bind UI events for mode switching (Select, Pan, Knife)
graph.Bind(ui)

; Enable C#-side drag logic for moving nodes on the canvas
graph.EnableDrag(ui)
```

**State Management & Persistence:**
```ahk
; Save the current layout and connections to disk
graph.SaveState("node_state.ini")

; Load and restore the layout dynamically
graph.LoadState("node_state.ini", ui)
```

**Retrieving Graph State:**
You can iterate through `graph.nodes` and `graph.connections` to generate code or execute logic based on the visual layout.
```ahk
for conn in graph.connections {
    if (conn.Active) {
        MsgBox("Connection from " conn.From " to " conn.To)
    }
}
```

### SliderRange

A dual-thumb range slider for selecting min/max values.

```ahk
slider := panel.SliderRange("Price Filter", 0, 100, 20, 80)
```

### DateRangePickerEx

A highly customized, fully themed date range selector with an interactive calendar grid.

```ahk
myDatePicker := DateRangePickerEx("EventDates", "2026-05-16", "2026-06-16")
myDatePicker.Build(panel)
myDatePicker.Bind(ui)
```

**Selection Logic:**
- Click 1: Sets Start Date
- Click 2: Sets End Date (if before start date, they swap automatically)
- Selected days are styled with `{DynamicResource Accent}`

### BreadcrumbBar

Horizontal path navigation with clickable segments.

```ahk
panel.BreadcrumbBar(["Home", "Projects", "AHK", "XAML_Components.ahk"])
```

### Stepper (Wizard)

A multi-step progress indicator for forms and workflows.

```ahk
panel.Stepper(["Config", "Auth", "Deploy", "Verify"], 3)
```

### SplitPanel

A resizable two-pane layout with a draggable `GridSplitter`.

```ahk
split := panel.SplitPanel("Horizontal", "1:1")
split.LeftPanel.Add("TextBlock").Text("Left")
split.RightPanel.Add("TextBlock").Text("Right")
```

### FileDropZone

A drag-and-drop file target with visual feedback icons.

```ahk
panel.FileDropZone("MyDropZone", "Drop files here", [".txt", ".json"])
```

### HotKeyBox / ShortcutRecorder

An input box that captures physical key combinations and formats them as AHK hotkey strings.

```ahk
hkInput := panel.HotKeyBox("QuickSaveBinding", "^+S", "Press a key combination...")
app.RegisterHotKeyChange(hkInput, (newBind) => MsgBox("New binding: " newBind))
```

**Behavior:**
- Click to focus → shows "Listening..."
- Press any key combo → captures `Ctrl + Shift + S` as `^+S`
- `Escape` cancels, `Backspace` clears
- Modifier keys alone are ignored

### Segmented Network Input

A custom input box for IP addresses or MAC addresses with automatic octet navigation.

```ahk
seg := XSegmentedNetworkInput("MyIP", "IP", ["192", "168", "1", "100"])
seg.Build(panel)
app.RegisterSegmentedInput(seg)
```

**Types:**
- `"IP"` — 4 octets separated by `.`, max 3 digits per octet
- `"MAC"` — 6 octets separated by `:`, max 2 hex chars per octet

**Auto-tab:** Typing a separator character or reaching max length automatically focuses the next octet.

### XRibbon

An Office-style ribbon toolbar with tabs, groups, and large/small buttons.

```ahk
ribbon := XRibbon(panel)
homeTab := ribbon.AddTab("Home")

clipGroup := homeTab.AddGroup("Clipboard")
clipGroup.AddLargeBtn("BtnPaste", "Paste", 0xE77F)
vertStack := clipGroup.AddVerticalStack()
vertStack.AddSmallBtn("BtnCut", "Cut", 0xE8C6)
vertStack.AddSmallBtn("BtnCopy", "Copy", 0xE8C8)

ribbon.BindEvents(ui)
```

**Features:**
- Double-click tab header to collapse/pin the ribbon
- Clicking a tab while collapsed shows it as an overlay
- Groups with separators and title labels

---

## V. Visualization Components

### Sparkline

A compact inline line chart rendered as a WPF `Path`.

```ahk
data := [10, 25, 18, 42, 35, 55, 48, 62, 58, 70]
panel.Sparkline("MySpark", data, 200, 40, "#0A84FF")
```

### RadialGauge / Gauge

A half-circle dashboard gauge with arc fill and percentage display.

```ahk
panel.Gauge("CPU Usage", 45, 100, "%")
panel.RadialGauge("Memory", 3.2, 8, "GB")
```

### StatCard

A dashboard KPI card with title, large metric, and color-coded trend.

```ahk
panel.StatCard("REVENUE", "$45,231", "12.5% increase", true)
panel.StatCard("SERVER LOAD", "89%", "2% above threshold", false)
```

### Timeline

A vertical event log with timestamps, dots, and description boxes.

```ahk
events := [
    { time: "10:00 AM", desc: "System booted." },
    { time: "10:05 AM", desc: "User authenticated." }
]
panel.Timeline(events)
```

### XClock

An analog/digital clock component with real-time updates.

```ahk
clock := panel.Clock("MyClock")
clock.Bind(ui)
```

---

## VI. Data & Tables

### DataTableView

A simple sortable table with alternating rows, header sort buttons, and resizable columns.

```ahk
data := [
    { Name: "Alice", Role: "Admin", Status: "Active" },
    { Name: "Bob", Role: "Dev", Status: "Offline" }
]

parent.DataTableView("MyTable", data)
```

### DataGridEx (Class)

A comprehensive, self-contained data grid with search, filter, sort, pagination, and dynamic row injection.

**Constructor Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `PageSize` | Integer | `50` | Rows per page |
| `ShowSearch` | Boolean | `true` | Show search textbox |
| `ShowFilters` | Boolean | `false` | Show filter popover |
| `ShowPagination` | Boolean | `true` | Show prev/next + page status |
| `ShowReset` | Boolean | `true` | Show reset button |
| `ShowRowCount` | Boolean | `true` | Show filtered row count |
| `FilterColumn` | String | `""` | Column name to filter by |
| `FilterValues` | Array | `[]` | Possible values for filter checkboxes |
| `ColumnWidths` | Object | `{}` | Column width overrides |

**Column Width Formats:**
- `"150"` — Fixed pixel width
- `"2*"` — Star proportional
- `"30%"` — Percentage (converted to star ratio)

```ahk
data := []
loop 200
    data.Push({ Name: "User " A_Index, Role: "Dev", Status: "Active" })

myGrid := DataGridEx("DGX", data, {
    PageSize: 50,
    ShowSearch: true,
    ShowFilters: true,
    FilterColumn: "Status",
    FilterValues: ["Active", "Offline", "Pending"],
    ColumnWidths: { Name: "40%", Role: "30%", Status: "30%" }
})

myGrid.Build(parent)
myGrid.Bind(ui)
```

---

## VII. Overlays & Contexts

### RichPopover

An interactive dropdown panel anchored to a `ToggleButton`. Closes when clicking outside.

```ahk
btn := parent.Add("ToggleButton").Content("Options")
pop := btn.AddRichPopover()
pop.Add("TextBlock").Text("Settings").FontWeight("Bold")
pop.Add("CheckBox").Content("Show Hidden").Margin("0,5,0,0")
pop.Add("CheckBox").Content("Match Case")
```

### Badge

A small notification counter attached to any element.

```ahk
btn := parent.Add("Button").Content("Notifications")
btn.AddBadge("3")            ; Default red
btn.AddBadge("!", "#FF9F0A") ; Custom color
```

### ContextMenu

A native right-click menu. Use `"-"` for separators.

```ahk
btn := parent.Add("Button").Content("Right-Click Me")
btn.AddContextMenu(["Edit", "Copy", "-", "Delete"])
```

### Snackbar

A non-blocking toast notification at the bottom of a panel.

```ahk
; Via XAML_GUI
app.ShowSnackbar("Saved!", 3000)

; Via direct element
panel.Snackbar("Settings applied.", "DISMISS")
```

### SkeletonLoader

A pulsing placeholder that mimics content shape during loading.

```ahk
panel.SkeletonLoader(200, 20)       ; Rectangle
panel.SkeletonLoader(40, 40, true)  ; Circular
```

### SkeletonBlock

A modern loading placeholder with smooth pulsing animation.

```ahk
panel.SkeletonBlock("100%", 120, 8)  ; Full width, 120px tall, 8px corner radius
panel.SkeletonBlock(200, 40)         ; Fixed 200px width
```

### Avatar / PersonaCard

A circular UI element for user profiles. Handles image filling, fallback initials, and optional status dot.

```ahk
panel.Avatar("", "JD", "#34C759")           ; Initials with green status
panel.Avatar("C:\photos\user.jpg", "", "")  ; Image, no status
```

---

## VIII. Advanced Rendering Components

### XCodeEditor

A layered syntax highlighting code editor with debounced token rendering and line numbers.

```ahk
editor := panel.CodeEditor("MyEditor")
editor.SetLanguage("ahk")  ; Supported: ahk, cs, json, xml
editor.SetText(FileRead("script.ahk"))
editor.Bind(ui)
```

**Features:**
- Debounced 250ms syntax highlighting (no input lag)
- Dynamic `isTyping` state with native foreground color during typing
- Line number gutter
- Configurable language tokenizers

### XPropertyGrid / Inspector

An auto-generated property inspector panel. Displays object properties as editable rows.

```ahk
props := [
    { Name: "Width", Value: "100", Type: "Number" },
    { Name: "Color", Value: "#FF0000", Type: "Color" },
    { Name: "Visible", Value: "True", Type: "Bool" }
]
inspector := panel.PropertyGrid("MyInspector")
inspector.SetProperties(props)
inspector.Bind(ui)
```

### XDiffViewer

A side-by-side diff viewer with syntax-colored additions, deletions, and unchanged lines.

```ahk
diff := panel.DiffViewer("MyDiff")
diff.SetLeft(oldText)
diff.SetRight(newText)
diff.Bind(ui)
```

### XMediaPlayerEx

A full media player wrapper with play/pause/stop/seek controls, volume slider, and time display.

```ahk
player := panel.MediaPlayerEx("MyPlayer")
player.SetSource("C:\videos\demo.mp4")
player.Bind(ui)
```

### XImageCropper

An interactive image cropper with drag-to-select region.

```ahk
cropper := panel.ImageCropper("MyCropper")
cropper.SetImage("C:\photos\landscape.jpg")
cropper.Bind(ui)
```

### XWebViewer

A universal web and file viewer utilizing the native `WebBrowser` control. It provides native rendering for HTML, PDF, and Images, while also featuring a specialized rendering pipeline for SVG files with styled grid backgrounds.

```ahk
viewer := panel.WebViewer("MyWebViewer")
viewer.LoadFile("index.html")
viewer.Bind(ui)
```

### XImageViewer

A dedicated raw image viewer for formats like JPG, PNG, WEBP, and GIF, complete with a checkerboard transparency background.

```ahk
imgViewer := panel.ImageViewer("MyImageViewer")
imgViewer.LoadImage("C:\photos\example.png")
imgViewer.Bind(ui)
```

### MarkdownRenderer

Converts Markdown text into styled WPF TextBlock/Paragraph elements.

```ahk
panel.MarkdownRenderer("# Hello World\n\nThis is **bold** and *italic* text.")
```

### XWebView (WebView2)

A full Chromium-based web browser component with toolbar, URL bar, and JavaScript bridge.

> Requires `XAML_ENABLE_WEBVIEW := true` in `XAML_Config.ahk`.

```ahk
wv := panel.WebView("MyBrowser")
wv.Bind(ui)

; Navigate programmatically
wv.Navigate("https://example.com")

; Execute JavaScript
wv.ExecuteJS("document.title")

; Listen for messages from JS
wv.OnMessage((msg) => MsgBox("From JS: " msg))
```

**Toolbar includes:** Back, Forward, Refresh, URL bar, Go, DevTools, Inject JS, Add JS Button.

**JS → AHK Bridge:**
```javascript
// In the webpage:
window.chrome.webview.postMessage("Hello from JavaScript!");
```

### Rating

A configurable star/icon rating selector.

**Options:**

| Option | Type | Default | Description |
|---|---|---|---|
| `Max` | Integer | `5` | Number of rating positions |
| `Default` | Number | `0` | Initial filled value |
| `Icon` | String | `★` (Segoe E735) | Filled icon character |
| `IconEmpty` | String | `☆` (Segoe E734) | Empty icon character |
| `Size` | Integer | `22` | Icon font size (px) |
| `AllowHalf` | Boolean | `false` | Enable half-step selection |
| `Color` | String | `#FFD700` | Filled icon color |
| `EmptyColor` | String | `{DynamicResource TextSub}` | Empty icon color |
| `IconFont` | String | `Segoe Fluent Icons` | Font family |

```ahk
; 5-star rating with default of 3
panel.Rating("MyRating", { Max: 5, Default: 3 })

; 10-heart rating
panel.Rating("Hearts", {
    Max: 10,
    Default: 7,
    Icon: Chr(0xEB52),
    IconEmpty: Chr(0xEB51),
    Color: "#FF453A",
    Size: 18
})
```

**Event Wiring:**
```ahk
RatingBind(ui, "MyRating", 5, false, Chr(0xE735), Chr(0xE734), "#FFD700", "{DynamicResource TextSub}")
```

### EmojiPicker

A popover grid of clickable emoji with categories (Smileys, Gestures, Hearts, Objects). It automatically replaces standard text-based emojis with high-quality, full-color Twemoji PNG images dynamically fetched from a CDN, ensuring beautiful and consistent rendering regardless of the user's OS version.

```ahk
; Basic picker
panel.EmojiPicker("MyEmoji")

; Picker that inserts into a TextBox
panel.EmojiPicker("MyEmoji", { Target: "TxtComment" })
```

**Event Wiring:**
```ahk
emojiList := ["😀","😁","😂", ...]  ; Standard text emoji are automatically converted to images
EmojiPickerBind(ui, "MyEmoji", emojiList)
```

### ImageViewer

A responsive image viewer with a drag-and-drop zone, transparent checkerboard background, and IPC binding for dynamic image loading (handles both file paths and HICON handles natively).

```ahk
imgViewer := panel.ImageViewer("MyImgViewer")
```

**Event Wiring:**
```ahk
; Bind the internal LoadImage mechanism
imgViewer.Bind(ui)

; Load an image dynamically
imgViewer.LoadImage("HICON:" hIconHandle)
imgViewer.LoadImage("C:\path\to\image.png")
```

### Clock

A beautifully styled analog and digital clock widget. The `Bind(ui)` function automatically establishes a 1000ms timer to update the clock hands and text.

```ahk
clk := panel.Clock("MyClock")
```

**Event Wiring:**
```ahk
; Automatically begins ticking
clk.Bind(ui)
```

### WebViewer

A universal web and file viewer utilizing the native `WebBrowser` control. It provides native rendering for HTML, PDF, and Images, while also featuring a specialized rendering pipeline for SVG files with styled grid backgrounds.

```ahk
web := panel.WebViewer("MyWebBrowser")
```

**Event Wiring:**
```ahk
; Bind the internal navigation and drag-and-drop events
web.Bind(ui)

; Load a file or URL
web.LoadFile("C:\path\to\document.pdf")
```

> **Note:** The advanced components like `XCommandPalette`, `KanbanBoard`, and `NodeGraph` are documented in detail (including setup, event wiring, and dynamic data handling) in **Section IV. Advanced Components** higher up in this document.

---

## IX. Event System

All interactivity is managed through the `XAML_Host` event system.

### Registering Events

```ahk
; Click events
ui.OnEvent("BtnSave", "Click", (state, ctrl, ev) => SaveData(state))

; Text changed (live typing)
ui.OnEvent("TxtSearch", "TextChanged", (state, ctrl, ev) => Search(state))

; Toggle
ui.OnEvent("TglDarkMode", "Click", (state, ctrl, ev) => ToggleTheme(state))

; Keyboard
ui.OnEvent("TxtInput", "KeyDown:Return", (state, ctrl, ev) => Submit(state))

; File Drop
ui.OnEvent("MyDropZone", "Drop", (state, ctrl, ev) => HandleFiles(state["DropFiles"]))

; Drag Move (Canvas nodes)
ui.OnEvent("Node_1", "DragMove", (state, ctrl, ev) => OnDrag(state))
```

### Tracking State

Track control values so they appear in the `state` map passed to event handlers:

```ahk
ui.Track("TxtUsername")
ui.Track("ComboRegion")
ui.Track("TglProxy")
```

### Updating Controls

```ahk
; Set property
ui.Update("TxtStatus", "Text", "Connected")
ui.Update("BtnSave", "IsEnabled", "False")
ui.Update("MyPanel", "Background", "#FF0000")
ui.Update("MyPanel", "Visibility", "Collapsed")

; Collection operations
ui.Update("MyList", "ClearItems", "")
ui.Update("MyList", "AddItem", "New entry")
ui.Update("MyList", "AddXamlItem", '<TextBlock xmlns="..." Text="Rich"/>')

; Scroll commands
ui.Update("MyScroll", "LineLeft", "")
ui.Update("MyScroll", "LineRight", "")

; Dynamic resources
ui.Update("Resource", "Brush:Accent", "#0A84FF")

; Window management
ui.Update("Window", "DWM", "2,1")
ui.Update("Window", "Title", "New Title")
ui.Update("Window", "Icon", "HICON:" hIcon)

; Focus
ui.Update("TxtSearch", "Focus", "True")

; Programmatic click
ui.Update("BtnSubmit", "Invoke", "1")
```

### State Map

Every event handler receives a `state` Map containing tracked values:

```ahk
HandleClick(state, ctrl, event) {
    username := state["TxtUsername"]       ; Current text
    region := state["ComboRegion"]         ; Selected combo value
    proxyOn := state["TglProxy"] == "True" ; Toggle state
}
```
