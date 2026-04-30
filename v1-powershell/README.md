# ahk-xaml: v1-powershell (Legacy)

This is the legacy version of `ahk-xaml`, utilizing PowerShell to dynamically launch and bridge WPF User Interfaces with AutoHotkey.

**Key Characteristics:**
- **Engine:** PowerShell (`powershell.exe`)
- **Compilation:** It takes the XAML input and creates a temporary (or locally specified) `.ps1` script to execute the WPF window.
- **Legacy Status:** This version is considered legacy and does not maintain feature parity with the newer CSC-compiled versions.

## Usage

```ahk
#Include "xaml.ahk"

; Read your XAML layout
myXaml := FileRead("my_layout.xaml")

; Initialize the GUI engine
; By default, the .ps1 file is placed in A_Temp
; You can optionally pass a second argument to specify a local path:
ui := XAMLGUI(myXaml, A_ScriptDir "\my_interface.ps1")

; Show the UI
ui.Show()
```
