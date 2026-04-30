# ahk-xaml: v2-csc (Raw XAML)

This version uses `csc.exe` (the built-in C# compiler) to dynamically compile a C# background engine into an executable (`.exe`). This provides better performance and reliability compared to the legacy PowerShell version.

**Key Characteristics:**
- **Engine:** Built-in C# Compiler (`csc.exe`)
- **Compilation:** Compiles your UI into an executable. It caches the executable (by default in `A_Temp`), so subsequent runs boot instantly.
- **Input:** It takes raw XAML input (e.g., from a `.xaml` file) and bridges it with AutoHotkey logic.

## Usage

```ahk
#Include "xaml.ahk"

; Read your XAML layout and replace the %app% placeholder
myXaml := StrReplace(XAML_TEMPLATE, "%app%", FileRead(A_ScriptDir "\example-rawXAML.xaml", "UTF-8"))

; Initialize the GUI engine
; By default, the compiled .exe is cached in A_Temp
; You can optionally pass a second argument to specify a local path:
ui := XAMLGUI(myXaml, A_ScriptDir "\my_interface.exe")

; Show the UI
ui.Show()
```
