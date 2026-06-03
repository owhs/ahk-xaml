#Requires AutoHotkey v2.0
; ==============================================================================
; FLUID UI WORKBENCH — basic_components.ahk
; ==============================================================================

; --- Core Libraries (always needed) ---
#Include "../../lib/XAML_Host.ahk"
#Include "../data/MockData.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Dialog.ahk"
#Include "../../lib/XAML_Components.ahk"
#Include "../../lib/XAML_Adv_Components.ahk"

; --- Shared globals (needed in both modes) ---
global myGrid := ""
global myDatePicker := ""
global tabList := ["DEPLOYMENT", "DATA GRID", "DATAGRID EX", "UI COMPONENTS", "ADVANCED INPUTS", "FLUID DIALOGS", "RICH COMPONENTS", "ADVANCED UI"]

; Toggle these flags for Dev vs Production
global XAML_FORCE_DYNAMIC_COMPILE := true
global BUILD_DLL := false

app := XAML_GUI("Fluid UI")

if (XAML_FORCE_DYNAMIC_COMPILE) {
    ;; you can comment out these includes in production and just use the pre-compiled DLL
    #Include "../../lib/XAML_Generator.ahk"
    #Include "basic_components/basic_components_gui.ahk"
    BuildFullGUI(app)
    ui := app.Compile()
} else {
    ui := app.Load("gui.dll")
}

; --- Event Handlers (always needed) ---
#Include "basic_components/basic_components_events.ahk"

; --- Launch ---
app.Show()
ui.Update("MyEmoji_EmojiScroll", "TrapScroll", "")