# ahk-xaml: v3-generator

This is the latest and most advanced version of `ahk-xaml`. It uses the `csc.exe` background engine (from `v2-csc`) for maximum performance, but abstracts away raw XAML entirely by introducing the powerful `XAML_Generator` class.

**Key Characteristics:**
- **Engine:** Built-in C# Compiler (`csc.exe`)
- **Generator:** Uses `XAML_Generator.ahk` to programmatically build XAML structures directly via AutoHotkey syntax.
- **Customization:** You can easily extend `XAML_Generator` with your own custom, reusable UI components.
- **Standalone:** The `XAML_Generator.ahk` file is fully decoupled. If you just want to generate XAML strings for another project, you can `#Include` it independently without touching the `xaml.ahk` engine.

## Usage

```ahk
#Requires AutoHotkey v2.0

#Include "xaml.ahk"
#Include "XAML_Generator.ahk"

; Create a custom generator class
class CustomGenerator extends XAML_Generator {
    ; Add app-specific shorthand tags here
}

; 1. Build your UI programmatically
X := CustomGenerator("Window", 'xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"')
X.LoadDefaultTheme()

AppUI := X.Tag("Grid", 'Background="{DynamicResource BgColor}"', [
    X.Tag("TextBlock", 'Text="Hello, World!" Foreground="{DynamicResource TextMain}" HorizontalAlignment="Center" VerticalAlignment="Center"')
])

; Generate the compiled XAML string
CompiledMarkup := X.Compile(AppUI)

; 2. Initialize the GUI engine
ui := XAMLGUI(StrReplace(XAML_TEMPLATE, "%app%", CompiledMarkup))

; Show the UI
ui.Show()
```
