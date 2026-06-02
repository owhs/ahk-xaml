# AHK-XAML Styling & Element Reference

A comprehensive guide to building UI elements, using shorthands, templates, events, and querying component data.

---

## 1. Element Construction

### Chainable Methods (Standard)

```ahk
panel.Add("Button").Name("BtnSubmit").Content("Say Hello").Width(120).Height(32).HorizontalAlignment("Left")
```

### Object-Style Construction

Pass a Map or Object as the second parameter to `Add()`:

```ahk
panel.Add("Button", {
    Name: "BtnSubmit",
    Content: "Say Hello",
    W: 120,
    H: 32,
    HAlign: "Left"
})
```

Both styles are fully equivalent and can be mixed:

```ahk
panel.Add("Button", { Name: "BtnSubmit", W: 120, H: 32 })
    .Content("Say Hello")
    .Use("PrimaryBtn")
    .On("Click", OnSubmitClick)
```

### Apply (Bulk Properties)

Apply a batch of properties to any existing element:

```ahk
el := panel.Add("TextBlock")
el.Apply({ Size: 24, Bold: true, Fg: "{DynamicResource TextMain}" })
```

---

## 2. Shorthand Aliases

All shorthands work in chaining, object-style `Add()`, `Apply()`, `SetDefaults()`, and `.axml` files.

### One-Parameter Shorthands

| Shorthand | Expands To | Category |
|-----------|------------|----------|
| `W(n)` | `Width(n)` | Layout |
| `H(n)` | `Height(n)` | Layout |
| `M(v)` | `Margin(v)` | Spacing |
| `Pad(v)` | `Padding(v)` | Spacing |
| `HAlign(v)` | `HorizontalAlignment(v)` | Layout |
| `VAlign(v)` | `VerticalAlignment(v)` | Layout |
| `HContentAlign(v)` | `HorizontalContentAlignment(v)` | Layout |
| `VContentAlign(v)` | `VerticalContentAlignment(v)` | Layout |
| `Fg(v)` | `Foreground(v)` | Color |
| `Bg(v)` | `Background(v)` | Color |
| `Color(v)` | `Foreground(v)` | Color |
| `Colour(v)` | `Foreground(v)` | Color |
| `BgColor(v)` | `Background(v)` | Color |
| `BgColour(v)` | `Background(v)` | Color |
| `BorderColor(v)` | `BorderBrush(v)` | Color |
| `Size(n)` | `FontSize(n)` | Typography |
| `Weight(v)` | `FontWeight(v)` | Typography |
| `Family(v)` | `FontFamily(v)` | Typography |
| `Radius(v)` | `CornerRadius(v)` | Border |
| `Border(v)` | `BorderThickness(v)` | Border |
| `Show(v)` | `Visibility(v)` | Visibility |

### Zero-Parameter Shorthands

These take no arguments — just call them:

| Shorthand | Sets |
|-----------|------|
| `.Bold()` | `FontWeight="Bold"` |
| `.Italic()` | `FontStyle="Italic"` |
| `.Wrap()` | `TextWrapping="Wrap"` |
| `.NoWrap()` | `TextWrapping="NoWrap"` |
| `.Center()` | `HorizontalAlignment="Center"` |
| `.Left()` | `HorizontalAlignment="Left"` |
| `.Right()` | `HorizontalAlignment="Right"` |
| `.Stretch()` | `HorizontalAlignment="Stretch"` |
| `.Top()` | `VerticalAlignment="Top"` |
| `.Bottom()` | `VerticalAlignment="Bottom"` |
| `.VCenter()` | `VerticalAlignment="Center"` |
| `.Collapsed()` | `Visibility="Collapsed"` |
| `.Clip()` | `ClipToBounds="True"` |
| `.Mono()` | `FontFamily="Cascadia Code, Consolas, Courier New"` |

In object-style, use `true` for zero-param shorthands:

```ahk
panel.Add("TextBlock", { Text: "Hello", Bold: true, Center: true, Wrap: true })
```

### Tag-Aware Aliases

| Alias | Behavior |
|-------|----------|
| `.Text("...")` on `Button` | Resolves to `.Content("...")` — Button uses Content, not Text |
| `.Text("...")` on `TextBlock` | Stays as `.Text("...")` — TextBlock uses Text natively |
| `.Text("...")` on `TextBox` | Stays as `.Text("...")` — TextBox uses Text natively |

This means you can always use `.Text("...")` and it does the right thing for the element type.

---

## 3. Templates & `Use()`

### Built-in Templates

| Template Name | Applied To | Description |
|---------------|------------|-------------|
| `PrimaryBtn` | Button | Accent-colored button with hover effect |
| `IconBtn` | Button / ToggleButton | Transparent background with hover highlight |
| `CardPanel` | Border | Bordered card with rounded corners |
| `PageTitle` | TextBlock | Large (28px) semibold title |
| `SubtitleText` | TextBlock | Small (11px) bold subtitle label |
| `BodyText` | TextBlock | Wrapped body text (13px) |

```ahk
panel.Add("Button").Use("PrimaryBtn").Text("Submit")
panel.Add("Border").Use("CardPanel").Pad("15")
```

### Custom Templates

Define your own templates at the root level:

```ahk
; Object template
app.X.DefineTemplate("DangerBtn", {
    Bg: "#E74C3C",
    Fg: "White",
    Bold: true,
    Radius: 5
})

; Function template (for complex logic)
app.X.DefineTemplate("HeroText", (el) => (
    el.Size(32).Bold().Fg("{DynamicResource Accent}").M("0,0,0,20")
))
```

### Cascading Defaults

Set default properties for all children of a specific type:

```ahk
panel.SetDefaults("TextBlock", { Fg: "{DynamicResource TextSub}", Size: 11, Bold: true })
panel.Add("TextBlock").Text("SECTION TITLE")  ; inherits defaults
```

---

## 4. Event Hooking

> [!TIP]
> **`.On()` is the recommended API.** Inline `.On()` registers events directly on the element tree, keeping your UI definition and event bindings together. The legacy `ui.OnEvent()` still works and is needed for Window-level events, dynamic elements, and forward references. See [Power Usage](power-usage.md) for when to use each.

### Inline Events (`.On()`)

```ahk
panel.Add("Button").Name("BtnSave").On("Click", OnSaveClick)
panel.Add("TextBox").Name("TxtSearch").On("TextChanged", OnSearchChanged)
panel.Add("Slider").Name("SldVolume").On("ValueChanged", OnVolumeChanged)
```

Features:
- **CSV multi-event**: `.On("Click,GotFocus", handler)`
- **String function name**: `.On("Click", "OnSaveClick")` — auto-generates skeleton if missing
- **Inline closure**: `.On("Click", (s,c,e) => DoThing())`
- **Chainable**: `.Name("X").On("Click", fn).Track().W(120)`

### State Tracking (`.Track()`)

Mark an element to include its value in event state maps:

```ahk
panel.Add("TextBox").Name("TxtName").Track()
panel.Add("Slider").Name("SldValue").Track().On("ValueChanged", OnChanged)
```

### Custom WPF Events

The framework supports ANY WPF event — not just Click/TextChanged. Examples:

```ahk
; Focus/Blur
ui.OnEvent("TxtInput", "GotFocus", OnInputFocus)
ui.OnEvent("TxtInput", "LostFocus", OnInputBlur)

; Mouse
ui.OnEvent("MyPanel", "MouseEnter", OnMouseEnter)
ui.OnEvent("MyPanel", "MouseLeave", OnMouseLeave)
ui.OnEvent("MyPanel", "PreviewMouseDown", OnMouseDown)

; Scroll
ui.OnEvent("MyScrollViewer", "ScrollChanged", OnScrollChanged)

; Keyboard (key name appended to event)
ui.OnEvent("TxtInput", "KeyDown", OnKeyDown)
; In callback: event = "KeyDown:Return", "KeyDown:Escape", etc.

; Context menu
ui.OnEvent("MyCanvas", "ContextMenuOpened", OnContextMenu)
; In callback: event data contains coordinates

; Drag & Drop
ui.OnEvent("MyDropZone", "Drop", OnFileDrop)
; In callback: event data contains file paths
```

### Lightweight Events Mode

Reduce IPC payload — events only send the triggering control's value:

```ahk
app.lightweightEvents := true   ; before Show()

OnButtonClick(state, ctrl, event) {
    ; state only has the button's value — use Query for others
    name := ui.Query("TxtInput")
}
```

---

## 5. Querying Component Data

### Basic Queries

```ahk
val := ui.Query("TxtName")                     ; single → string
state := ui.Query("TxtName", "SldValue")        ; multi → Map
allState := ui.Query("*")                        ; wildcard → Map of all tracked
```

### Rich Queries (`>` Delimiter)

Use `>` to query specific properties of rich components:

```ahk
; ListBox
count := ui.Query("MyList>Count")               ; total items
items := ui.Query("MyList>Items")                ; pipe-delimited: "A|B|C"
idx := ui.Query("MyList>SelectedIndex")          ; selected index

; DataGrid
rowCount := ui.Query("MyGrid>Count")             ; total rows
filtered := ui.Query("MyGrid>FilteredCount")     ; visible after filter
row := ui.Query("MyGrid>SelectedRow")            ; pipe-delimited cell values
idx := ui.Query("MyGrid>SelectedIndex")          ; selected index

; TabControl
tab := ui.Query("MainTabs>SelectedIndex")        ; active tab index
header := ui.Query("MainTabs>SelectedHeader")    ; active tab header text

; TextBlock (read back dynamic text)
text := ui.Query("TxtStatus>Text")               ; or just ui.Query("TxtStatus")

; Canvas / Node Editor
nodes := ui.Query("Canvas1>Nodes")               ; "NodeA:100,200:tag|NodeB:300,400"
conns := ui.Query("Canvas1>Connections")          ; "NodeA→NodeB|NodeB→NodeC"
selected := ui.Query("Canvas1>SelectedNode")      ; "NodeA"

; Generic property read (any .NET property)
val := ui.Query("MyControl>IsEnabled")            ; "True" / "False"
val := ui.Query("MyControl>ActualWidth")          ; "450.5"
```

> [!WARNING]
> **Do NOT use underscores in control names** (e.g., `Name("My_Control")`). The framework uses `_` internally for attached property notation (`Grid_Column` → `Grid.Column`). Use camelCase or PascalCase: `MyControl`, `TxtUserName`, `BtnSubmit`.
> 
> The legacy `_CaretIndex` suffix still works for backward compatibility, but new queries should use the `>` delimiter.

### Supported Default Value Extraction

| Control Type | Default Value (no suffix) |
|---|---|
| TextBox | `.Text` |
| PasswordBox | `.Password` |
| CheckBox / ToggleButton | `.IsChecked` ("True"/"False") |
| Slider / ProgressBar | `.Value` |
| ComboBox | Selected item's `.Tag` or `.Content` |
| ListBox | Selected item's `.Tag` or `.Content` |
| TreeView | Selected item's `.Tag` |
| TextBlock | `.Text` |
| TabControl | `.SelectedIndex` |
| DataGrid | `.SelectedIndex` |
| Image | `.Source` (URI string) |

---

## 6. Production Pipeline

The `.On()` and `.Track()` APIs work with both development (`Compile()`) and production (`Load()`) paths:

```ahk
; ========== YOUR UI CODE (always runs) ==========
panel.Add("Button").Name("BtnSave").On("Click", OnSaveClick)
panel.Add("TextBox").Name("TxtName").Track()

; ========== COMPILE / LOAD SWITCH ==========
if (XAML_FORCE_DYNAMIC_COMPILE) {
    ui := app.Compile()
    app.ExportBundle("gui.dll")   ; serialize events into bundle
} else {
    ui := app.Load("gui.dll")     ; .On() events are harvested from tree
}

app.Show()
```

Both paths call `_CollectInlineEvents()` which walks the element tree (built by your `.Add()` and `.On()` calls) and registers events on the host. No extra steps needed.

---

## 7. AXML Compatibility

Since the AXML parser bypasses method-chaining and writes properties directly, you should use standard WPF property names (rather than shorthand aliases) inside `.axml` files.

```yaml
StackPanel:
  Margin: "20"
  
  TextBlock:
    Text: "Welcome!"
    FontSize: 24
    FontWeight: "Bold"
    
  Button (BtnSubmit):
    Content: "Submit"
    Width: 120
    Height: 32
    HorizontalAlignment: "Left"
    OnClick: HandleClick
```

AXML-specific features:
- **Event shorthand**: `OnClick: HandlerName` instead of calling `On("Click", "HandlerName")` in AHK.
- **State binding**: `Value: $MyVariable` for automatic two-way state binding.

---

## 8. Customizing Control Templates (Abstract Sliders)

AHK-XAML provides premium, fully abstracted property builders for the `Slider` control. This completely eliminates the need to write raw XAML or inject templates when customizing sliders.

Instead, you can configure the visuals (such as shapes, widths, colors, borders, shadows, and track click snapping) directly using chainable AHK methods!

### Configurable Slider Options

| Method | Description | Default |
|---|---|---|
| `ThumbShape(value)` | Sets the thumb shape: `"Circle"`, `"Ellipse"`, `"Line"`, or `"Rectangle"`. | `"Circle"` |
| `ThumbWidth(number)` | Width of the thumb. | `18` |
| `ThumbHeight(number)` | Height of the thumb. | `18` |
| `ThumbColor(color)` | Fill color of the thumb. | `"{DynamicResource Accent}"` |
| `ThumbBorderColor(color)`| Border brush color. | `"Transparent"` |
| `ThumbBorderThickness(n)`| Thickness of the thumb border. | `0` |
| `ThumbCornerRadius(n)` | Corner radius of the thumb (only applies to `"Line"`/`"Rectangle"`). | `1.5` |
| `ThumbShadow(boolean)` | Enables/disables a drop shadow effect on the thumb (`true` or `false`). | `false` |
| `TrackHeight(number)` | Height of the hit-test and visual track area. | `6` |
| `TrackColor(color)` | Color of the active portion of the track (left/decrease repeat button). | `"{DynamicResource Accent}"` |
| `TrackBackground(color)`| Color of the inactive portion of the track (right/increase repeat button).| `"{DynamicResource ControlBorder}"` |
| `IsMoveToPointEnabled(b)`| Enable native point-snapping (click-to-jump) on the track. | `true` (when customized) |

### Examples

#### Modern Tactile Line Slider
Create a sleek slider with a vertical line marker thumb, a transparent track background (perfect for overlays like gradients or color pickers), and drop shadows:

```ahk
main.Add("Slider").Name("MySlider")
    .ThumbShape("Line")
    .ThumbWidth(8)
    .ThumbHeight(20)
    .ThumbColor("#FFFFFF")
    .ThumbBorderColor("#FF222222")
    .ThumbBorderThickness(1.5)
    .ThumbCornerRadius(1.5)
    .ThumbShadow(true)
    .TrackHeight(24)
    .TrackColor("Transparent")
    .TrackBackground("Transparent")
```

#### Custom Themed Circular Slider
Create a styled circular slider with specific track colors and shadows:

```ahk
main.Add("Slider").Name("Volume")
    .ThumbShape("Circle")
    .ThumbWidth(16)
    .ThumbHeight(16)
    .ThumbColor("#0A84FF")
    .ThumbShadow(true)
    .TrackHeight(8)
    .TrackColor("#0A84FF")
    .TrackBackground("#20ffffff")
```

### Integration with `DefineTemplate`

You can combine these options with `DefineTemplate` to define styles at the application level and use them elegantly with chaining:

```ahk
; Register a template named "LineThumbSlider"
app.X.DefineTemplate("LineThumbSlider", (slider) => slider
    .ThumbShape("Line")
    .ThumbWidth(8)
    .ThumbHeight(20)
    .ThumbColor("#FFFFFF")
    .ThumbBorderColor("#FF222222")
    .ThumbBorderThickness(1.5)
    .ThumbCornerRadius(1.5)
    .ThumbShadow(true)
    .TrackHeight(24)
    .TrackColor("Transparent")
    .TrackBackground("Transparent")
)

; Usage is clean and concise
main.Add("Slider").Name("Brightness").Use("LineThumbSlider")
main.Add("Slider").Name("Contrast").Use("LineThumbSlider")
```
