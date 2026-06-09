# Power Usage — Deep Engine Hooks & Feature Reference

This document covers every special tag, update command, and deep engine feature available in AHK-XAML. These go beyond basic property setting — they unlock scroll control, drag-and-drop, canvas manipulation, media playback, embedded browsers, and more.

---

## 1. Tag Modifiers

Tags are set on elements via `.Tag("...")` and modify how the engine handles events for that control.

### `Throttle:N`

Throttles event dispatching to every `N` milliseconds. Essential for high-frequency events like slider dragging.

```ahk
; 60fps slider updates (16ms between events)
panel.Add("Slider").Name("SldVolume").Tag("Throttle:16")
    .Track().On("ValueChanged", OnVolumeChanged)
```

Without throttling, a `ValueChanged` event fires on every single pixel of mouse movement — flooding IPC and causing lag. `Throttle:16` limits it to ~60 events/second.

### `AllowPassive`

Allows `TextChanged` and `ValueChanged` events to fire even when the control **doesn't have keyboard/mouse focus**. By default, the engine suppresses these events during programmatic updates to prevent event loops.

```ahk
; This TextBox fires TextChanged even when updated via ui.Update()
panel.Add("TextBox").Name("TxtLive").Tag("AllowPassive")
    .On("TextChanged", OnLiveUpdate)
```

**Use case:** Live-updating displays, two-way data binding, or controls that receive programmatic text updates and need to react.

---

## 2. Scroll Control

### `TrapScroll`

Traps mouse wheel events inside a `ScrollViewer`, preventing them from bubbling up to a parent scrollable container.

```ahk
; After compile, trap scroll on a specific ScrollViewer
ui.Update("MyEmojiScroll", "TrapScroll", "")
```

**Use case:** Horizontal carousels or emoji pickers embedded inside a vertically-scrolling page. Without `TrapScroll`, scrolling inside the carousel would also scroll the outer page — ruining the UX. With `TrapScroll`, the inner container captures wheel events until its content is fully scrolled, then optionally "leaks" overflow back to the parent.

### `BringIntoView`

Scrolls a control into the visible viewport area.

```ahk
ui.Update("MyElement", "BringIntoView", "")
```

---

## 3. Drag & Drop

AHK-XAML has four distinct drag-and-drop systems, each designed for different use cases.

### `EnableDrag` — Canvas Element Dragging

Makes a `FrameworkElement` freely draggable on a `Canvas`. Used internally by the Node Graph editor.

```ahk
; Enable dragging for a node on a canvas
ui.Update("NodeElement", "EnableDrag", "")
```

The engine automatically updates `Canvas.Left` and `Canvas.Top` as the user drags, and fires `DragMove` events with coordinates.

### `EnableListBoxDragDrop` — ListBox Item Transfer

Enables drag-and-drop of items **between** `ListBox` controls. Used by the Kanban Board.

```ahk
; Enable drag-drop on a Kanban column ListBox
ui.Update("KanbanCol1", "EnableListBoxDragDrop", "")
```

When an item is dropped on a different ListBox, an `ItemDropped` event fires with the source box name and item content: `SourceBoxName|CardText`.

### `EnableDragSource` — Generic Drag Source

Makes any `UIElement` a drag source that carries typed data.

```ahk
; Make a button draggable with a custom data format
ui.Update("MyButton", "EnableDragSource", "DesignerComponent")
```

When dragging starts, a `DragStarted` event is fired. The data format string (`"DesignerComponent"`) is used as the clipboard format identifier.

### `EnableDropTarget` — Generic Drop Target

Makes any `UIElement` accept drops of a specific data format.

```ahk
; Accept drops of "DesignerComponent" data
ui.Update("CanvasArea", "EnableDropTarget", "DesignerComponent")
```

When a matching drag source is dropped, an `ItemDropped` event fires with the dropped data.

### File Drop

Elements support native Windows file drag-and-drop via the `Drop` event:

```ahk
panel.Add("Border").Name("MyDropZone").AllowDrop("True")
    .On("Drop", OnFileDrop)

OnFileDrop(state, ctrl, event) {
    files := state["DropFiles"]  ; Array of file paths
    for path in files
        MsgBox(path)
}
```

---

## 4. Canvas & Node Graph

### `EnableZoomPan`

Enables scroll-to-zoom and middle-click-to-pan on a `Canvas`.

```ahk
ui.Update("MyCanvas", "EnableZoomPan", "")
```

- **Scroll wheel:** Zoom in/out (0.2x – 5.0x range)
- **Middle-click drag:** Pan the canvas
- **Right-click:** Fires `ContextMenuOpened` with coordinates

### `SetCanvasMode`

Switch the canvas interaction mode:

```ahk
ui.Update("MyCanvas", "SetCanvasMode", "Pan")     ; Middle-click pan (default)
ui.Update("MyCanvas", "SetCanvasMode", "Select")   ; Left-click rubber-band selection
ui.Update("MyCanvas", "SetCanvasMode", "Knife")    ; Left-click knife tool (cut connections)
```

### `ZoomAll`

Auto-fit all canvas content into the visible viewport:

```ahk
ui.Update("MyCanvas", "ZoomAll", "")
```

### `Zoom`

Programmatic zoom by a factor:

```ahk
ui.Update("MyCanvas", "Zoom", "1.2")   ; Zoom in 20%
ui.Update("MyCanvas", "Zoom", "0.8")   ; Zoom out 20%
```

### `SetPosition`

Move an element to specific coordinates on a `Canvas`:

```ahk
ui.Update("NodeElement", "SetPosition", "150,200")
```

---

## 5. Focus & Input Control

### `Focus`

Programmatically focus or blur a control:

```ahk
ui.Update("TxtInput", "Focus", "True")    ; Focus the control
ui.Update("TxtInput", "Focus", "False")   ; Clear focus (blur)
```

### `Invoke`

Programmatically "click" a button via its automation peer:

```ahk
ui.Update("BtnSubmit", "Invoke", "")
```

This triggers the button's Click event as if the user had clicked it, without requiring the button to be visible or focused.

---

## 6. Text Manipulation

### `AppendText`

Append text to a `TextBox` and auto-scroll to the end:

```ahk
ui.Update("LogOutput", "AppendText", "New log entry...\n")
```

### `InsertText`

Insert text at the current cursor position in a `TextBox`:

```ahk
ui.Update("CodeEditor", "InsertText", "function() {}")
```

### Item Management (`AddItem`, `RemoveItem`, `ClearItems`, `AddXamlItem`)

Dynamically manage children of `ItemsControl`-based elements (`ListBox`, `ComboBox`, `StackPanel`, `TabControl`):

```ahk
; Add a simple text item
ui.Update("MyList", "AddItem", "New item")

; Remove an item by content match
ui.Update("MyList", "RemoveItem", "Old item")

; Clear all items
ui.Update("MyList", "ClearItems", "")

; Add a rich XAML element (parsed from string)
xaml := '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">'
    . '<TextBlock Text="Rich content" FontWeight="Bold"/>'
    . '</StackPanel>'
ui.Update("MyPanel", "AddXamlItem", xaml)
```

---

## 7. Media Playback

Control `MediaElement` components programmatically:

```ahk
ui.Update("MyVideo", "Play", "")
ui.Update("MyVideo", "Pause", "")
ui.Update("MyVideo", "Stop", "")
ui.Update("MyVideo", "Seek", "30.5")   ; Seek to 30.5 seconds
```

### `StartPositionTimer`

Begin periodic position tracking for media playback. The engine sends `PositionChanged` events with the current playback position:

```ahk
ui.Update("MyVideo", "StartPositionTimer", "")
; Now you'll receive PositionChanged events with current time
```

---

## 8. WebView2 (Chromium Browser)

Full Chromium browser embedded in WPF, with bidirectional AHK ↔ JavaScript communication.

### Navigation

```ahk
ui.Update("MyBrowser", "Navigate", "https://example.com")
ui.Update("MyBrowser", "GoBack", "")
ui.Update("MyBrowser", "GoForward", "")
ui.Update("MyBrowser", "Refresh", "")
```

### JavaScript Execution

```ahk
; Run JavaScript in the browser context
ui.Update("MyBrowser", "ExecuteScript", "document.title = 'Hello from AHK'")
```

### AHK ↔ JavaScript Bridge

**AHK → JavaScript:**
```ahk
ui.Update("MyBrowser", "PostWebMessage", "Hello from AutoHotkey!")
```

**JavaScript → AHK:**
```javascript
// In your web page:
window.chrome.webview.postMessage("Hello from JavaScript!");
```

```ahk
; In AHK, receive messages:
myBrowser.OnMessage((msg) => MsgBox("Got: " msg))
```

### DevTools

```ahk
ui.Update("MyBrowser", "OpenDevTools", "")
```

---

## 9. Window Management

### DWM Effects (Mica / Acrylic)

Control Desktop Window Manager effects for native Windows 11 styling:

```ahk
; Apply DWM backdrop effect
; Values: "Mica", "MicaAlt", "Acrylic", "Tabbed", "None"
ui.Update("Window", "DWM", "Mica")
```

### `NativeOwner`

Set a native Win32 HWND as the WPF window's owner (for AHK-to-WPF window parenting):

```ahk
ui.Update("Window", "NativeOwner", String(ahkGuiHwnd))
```

### Win32 Window Docking (`SetParent`)

To embed a WPF preview window directly inside an AutoHotkey GUI panel or container (e.g., for creating a unified IDE / Designer layout), you can use the `XAMLHost.DockWindow` static helper method. 

This helper attaches the child WPF window handle to the parent AHK window, strips the window chrome (borders, title bar, caption/titlebar, shadow), and sizes it to fit the host container bounds:

```ahk
; 1. Compile the UI (it holds the WPF window)
ui := app.Compile()

; 2. Show the WPF window (generates its HWND)
app.Show()

; 3. Dock the WPF window inside the parent AHK GUI panel container
; Arguments: childHwnd, parentHwnd, x, y, width, height
XAMLHost.DockWindow(ui.wpfHwnd, myPanelHwnd, 0, 0, panelW, panelH)
```

#### Handling Parent Resizing

When the parent AutoHotkey GUI is resized, the docked child WPF window does not automatically scale. You must handle the parent GUI's `Size` event and re-dock (or resize) the child:

```ahk
myGui := Gui("+Resize")
myGui.OnEvent("Size", OnGuiSize)
panel := myGui.Add("Text", "w600 h400") ; Host panel for docking

; ... Compile and show WPF UI ...

OnGuiSize(guiObj, minMax, width, height) {
    if (minMax == -1)
        return
    ; Calculate new dimensions for the host panel
    panelW := width - 40
    panelH := height - 60
    panel.Move(,, panelW, panelH)
    
    ; Resize and reposition the child WPF window
    if (ui.wpfHwnd) {
        XAMLHost.DockWindow(ui.wpfHwnd, panel.Hwnd, 0, 0, panelW, panelH)
    }
}
```

#### Keyboard Focus & Input Routing

The Win32 `SetParent` API introduces distinct behaviors depending on the engine's process boundaries:

- **Out-of-Process Mode (`XAML_IN_PROCESS_PREVIEW := false`):** Because the WPF window lives in a separate C# daemon process, Windows isolates their message loops. Keystrokes (like Tab, cursor keys, and hotkeys) may not route between AHK and WPF controls naturally.
- **In-Process CLR Mode (`XAML_IN_PROCESS_PREVIEW := true`):** The WPF STA thread runs in the same process space as AHK. Message hooks resolve input routing instantly, enabling perfect keyboard navigation, standard tab order traversal, and zero-latency focus switching.

> [!TIP]
> **Performance Recommendation:**
> For active designer workspaces, workspaces with inline code editors (AvalonEdit), or browser previews (WebView2), always enable **In-Process CLR Mode** to get smooth, desktop-native input routing.

#### Safe Window Teardown

When the parent AutoHotkey GUI window is destroyed, Windows automatically terminates any docked child windows assigned via `SetParent`. However, for a clean teardown under in-process CLR hosting, it is good practice to explicitly close the WPF window resource to release thread resources:

```ahk
myGui.OnEvent("Close", OnGuiClose)

OnGuiClose(*) {
    if (ui.wpfHwnd) {
        ui.Update("Window", "Close", "")
    }
}
```

### `GlassFrameThickness`

Control the extent of DWM glass framing (extends glass into the client area):

```ahk
ui.Update("Window", "GlassFrameThickness", "-1")  ; Extend glass to entire window
```

### Dynamic Corner Radius

```ahk
ui.Update("Window", "WindowRadius", "8")    ; Set window corner radius
ui.Update("Window", "PanelRadius", "6")     ; Set panel corner radius
```

### `ScrollBarWidth`

Change scrollbar thickness globally for the window:

```ahk
ui.Update("Window", "ScrollBarWidth", "6")   ; Thin scrollbars
```

### `Close`

Programmatically close the WPF window:

```ahk
ui.Update("Window", "Close", "")
```

---

## 10. Storyboard Animations

Trigger pre-defined XAML storyboard animations:

```ahk
ui.Update("MyElement", "BeginStoryboard", "FadeInAnimation")
```

The storyboard must be defined in the XAML resources. The engine finds the named storyboard and starts it.

---

## 11. Shape Properties

Direct property updates for `Shape`-derived elements (`Path`, `Ellipse`, `Rectangle`, `Line`):

```ahk
ui.Update("MyCircle", "Stroke", "#FF0000")
ui.Update("MyCircle", "Fill", "#00FF00")
ui.Update("MyCircle", "StrokeThickness", "2")
ui.Update("GaugeArc", "StrokeDashOffset", "5.5")  ; Animate radial gauges
```

The `StrokeDashOffset` property is particularly useful for radial gauge animations — by adjusting the dash offset on a circular `Path`, you create smooth arc-fill effects.

---

## 12. Rich Document Support

### RichTextBox Document

Load FlowDocument content into a `RichTextBox`:

```ahk
ui.Update("MyRichText", "Document", flowDocumentXaml)
```

---

## 13. Event Modifiers

### Keyboard Events

Key events include the key name as a suffix:

```ahk
panel.Add("TextBox").Name("TxtInput")
    .On("KeyDown", OnKeyDown)

OnKeyDown(state, ctrl, event) {
    ; event = "KeyDown:Return", "KeyDown:Escape", "KeyDown:A", etc.
    key := StrSplit(event, ":")[2]
    if (key == "Return")
        MsgBox("Enter pressed!")
}
```

### Context Menu Events

Canvas right-click provides coordinates:

```ahk
ui.OnEvent("MyCanvas", "ContextMenuOpened", OnCtxMenu)

OnCtxMenu(state, ctrl, event) {
    coords := state["ContextMenuOpened"]  ; "150.5,200.3"
}
```

### Drag Coordinate Events

During drag operations, `DragMove` events provide live coordinates:

```ahk
OnDragMove(state, ctrl, event) {
    coords := state["DragCoords"]  ; "X,Y"
}
```

---

## 14. Lightweight Events Mode

Reduce IPC payload size for high-performance apps:

```ahk
app.lightweightEvents := true  ; Set before Show()
```

In lightweight mode, event state maps only include the **triggering control's value**, not all tracked controls. Use `ui.Query()` to fetch other values on demand:

```ahk
OnButtonClick(state, ctrl, event) {
    ; state only has the button's value
    ; Fetch others explicitly:
    name := ui.Query("TxtInput")
    slider := ui.Query("SldVolume")
}
```

---

## 15. Production Pipeline

### `.On()` and `.Track()`

Inline event and tracking registration — the modern, recommended API:

```ahk
panel.Add("TextBox").Name("TxtName").Track()
panel.Add("Button").Name("BtnSave")
    .On("Click", OnSaveClick)

ui := app.Compile()  ; Events auto-collected from tree
```

### `ui.OnEvent()` and `ui.Track()` (Legacy)

The explicit post-compile binding API. Still fully supported, and necessary for:
- **Window-level events:** `ui.OnEvent("Window", "Loaded", handler)`
- **Dynamic elements:** Controls created at runtime via `ui.Update("AddItem", ...)`
- **Loop bindings:** Events bound in a loop over dynamically enumerated controls

```ahk
ui := app.Compile()
ui.OnEvent("Window", "Loaded", OnWindowLoaded)
ui.Track("ComboTheme")
```

---

## 16. Auto-Bind (Component Lifecycle)

Composite components created via factory methods (`.KanbanBoard()`, `.NodeGraph()`, `.NavigationView()`, etc.) are **automatically bound** during `Compile()`. No manual `.Bind(ui)` calls needed.

### How it works

1. Factory method creates the component and registers it with `XAML_GUI`
2. `Compile()` iterates all registered components and calls `.Bind(ui)` on each
3. If `.EnableDrag()` was called (no args), drag is enabled after bind

### `.EnableDrag()` — Chainable Flag

Call `.EnableDrag()` with **no arguments** to flag a component for auto-enabling drag during compile:

```ahk
kb := panel.KanbanBoard("MyBoard")
kb.AddColumn("Todo", cards)
kb.EnableDrag()  ; Flagged — actual enabling happens at compile

ng := canvas.NodeGraph("MyGraph")
ng.AddNode(...)
ng.EnableDrag()  ; Same pattern
```

### `.Hotkey()` — Flyout & Command Palette Hotkeys

Set a hotkey on `XFlyout` or `XCommandPalette` that gets applied during auto-bind:

```ahk
fly := XFlyout("Settings", "Left", "Push", 300)
fly.Build(layout).Grid_Column(0)
fly.Hotkey("^+S")  ; Applied automatically during Compile()

cmdPal := app.overlay.CommandPalette("CmdPal")
cmdPal.Hotkey("^+P")
```

### Standalone Components (XFlyout)

`XFlyout` is not a factory method — it's instantiated standalone. Auto-registration happens when `.Build(parent)` is called, since that's when the flyout attaches to the element tree.

```ahk
; Old pattern (still works):
fly := XFlyout("Menu", "Left", "Push", 250)
fly.Build(layout)
ui := app.Compile()
fly.Bind(ui, "^+L")  ; Manual

; New pattern:
fly := XFlyout("Menu", "Left", "Push", 250)
fly.Build(layout)
fly.Hotkey("^+L")    ; Stored
ui := app.Compile()   ; Auto-bound with hotkey
```

### Element-Level `.Hotkey()` — Any Named Element

Any element with a `Name` can have a global hotkey registered inline:

```ahk
; Default action is "Invoke" (programmatic click/toggle)
panel.Add("Button").Name("BtnSave").Content("Save")
    .On("Click", OnSave)
    .Hotkey("^s")              ; Ctrl+S → clicks the button

; Focus a textbox
panel.Add("TextBox").Name("TxtSearch")
    .Hotkey("^f", "Focus")     ; Ctrl+F → focuses the search box

; Custom callback
panel.Add("Button").Name("BtnReset")
    .Hotkey("^+r", (*) => ResetAll())  ; Ctrl+Shift+R → custom function
```

**Built-in actions:**

| Action | Effect |
|--------|--------|
| `"Invoke"` / `"Click"` / `"Toggle"` | Programmatically clicks/toggles the element |
| `"Focus"` | Focuses the element |
| `"Blur"` | Removes focus from the element |
| Callback function | Runs the custom callback |

---

## 17. Dynamic Elements & Event Re-Binding

When building dynamic UI elements like Recent Files menus, list items, or dynamic tabs, elements are created and destroyed at runtime. AHK-XAML handles this dynamically using a clean unregistration and re-binding cycle.

### Hooking Events to Dynamic Elements
Because dynamic elements are added after compile, you must explicitly bind their event handlers:
1. Parse and add the new element via `AddXamlItem`. Ensure the element has a `Name` (e.g., `RecentItem_1`).
2. Call `ui.Update("ControlName", "BindEvent", "Click")` to register the event with the WPF bridge.
3. Map the AHK callback using `ui.OnEvent("ControlName", "Click", Callback)`.

```ahk
; 1. Add the item dynamically
xaml := '<MenuItem xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Name="RecentItem_1" Header="MyFile.txt"/>'
ui.Update("RecentMenu", "AddXamlItem", xaml)

; 2. Bind the click event on the WPF side
ui.Update("RecentItem_1", "BindEvent", "Click")

; 3. Hook the event to an AHK handler
ui.OnEvent("RecentItem_1", "Click", OpenRecentFile)
```

### Destruction & Clean Re-Binding
When calling `ClearItems` or `RemoveItem` on a container (e.g., `RecentMenu`), the engine automatically performs a deep cleanup:
* Unregisters all child names from the WPF `NameScope`.
* Removes all bound events for those child elements from the engine's internal `_boundEvents` registry.

This allows you to safely **reuse element names** (e.g., clearing the menu and adding a new set of items with names `RecentItem_1`, `RecentItem_2`, etc.) without encountering "Control not found" or "Name already registered" errors.

### Reentrancy Guards in AHK
Dynamic menus that are refreshed upon user interaction or file loading (like the recent files menu) can easily trigger infinite event loops if the file load itself fires a `DocumentLoaded` event that triggers another menu rebuild.

Always protect such update functions with a static boolean reentrancy guard in AHK:

```ahk
UpdateRecentFilesMenu() {
    static isUpdating := false
    if (isUpdating)
        return
    isUpdating := true

    ; Clear and rebuild menu items here...
    ui.Update("RecentMenu", "ClearItems", "")
    
    ; Rebuild items...
    
    isUpdating := false
}
```
