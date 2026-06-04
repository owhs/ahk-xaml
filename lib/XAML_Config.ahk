; ==============================================================================
; AHK-XAML Global Configuration
; ==============================================================================

; --- Engine Compilation ---
; When true, the C# engine (.dll) is recompiled from XAML_AHK_Bridge.cs on every run.
; When false, uses the pre-compiled ahk-xaml.dll from the lib/dep directory.
global XAML_FORCE_DYNAMIC_COMPILE := true

; --- Developer Diagnostics ---
; When true, crash dialogs show interactive "Skip Property" / "Skip Element" buttons
; for rapid iteration. Disable in production for a cleaner user experience.
global XAML_DIAGNOSTICS_ENABLED := true

; Enable to dump the AXML Abstract Syntax Tree to a local file when parsing AXML files
global XAML_AXML_DEBUG_MODE := true

; --- Logging System ---
; When true, the framework writes trace and error logs to disk (e.g., AhkWpfError.log).
; Set to false to disable all disk I/O for logging.
global XAML_ENABLE_LOGGING := true

; --- XAML Line Tracing ---
; Enable XAML line-number and file tracing comments (<!-- [ahk:File.ahk:LineNumber] -->)
; during generation. Turn off for production or to reduce XAML string size.
global XAML_ENABLE_TRACING := true

; --- WebView2 ---
global XAML_ENABLE_WEBVIEW := false

; --- WebView2 User Data Directory ---
; The directory where WebView2 stores its browser cache, cookies, and user data.
; If not specified, defaults to A_Temp "\AhkWpf\WebView2Data".
global XAML_WEBVIEW_USER_DATA_DIR := ""

; --- AvalonEdit IDE Component ---
; When true, compiles with ICSharpCode.AvalonEdit for a robust code editor
; with syntax highlighting, code folding, line numbers, autocomplete, and LSP hooks.
; Requires AvalonEdit DLLs in lib/dep/AvalonEdit/ (auto-downloaded from NuGet if missing).
global XAML_ENABLE_AVALONEDIT := true

; --- Document Editor ---
; When true, compiles with OpenXml SDK + NPOI for rich document viewing/editing
; with DOCX/DOC import/export, formatting toolbar, tables, images, and more.
; Requires DLLs in lib/dep/OpenXml/ (auto-downloaded from NuGet if missing).
global XAML_ENABLE_DOCUMENT := false

; --- Auto-Prewarm Engine ---
; When true, automatically spins up the background WPF engine as soon as the script launches.
; This completely eliminates the ~300ms cold-start delay when the dialog is shown!
global XAML_AUTO_PREWARM := false

; --- Developer Tools ---
; When true, enables the premium developer tools panel.
; Pressing F12 in any active app window opens the floating DevTools suite.
global XAML_ENABLE_DEVTOOLS := true

; --- In-Process CLR Hosting (Opt-In) ---
; When true, boots the WPF engine in-process inside the parent AHK thread using CLR hosting.
; When false, spawns a separate background daemon process (default, robust).
global XAML_IN_PROCESS_PREVIEW := true

; --- Designer Auto-Backups ---
; When true, the designer automatically saves a backup of your layout to a `.backups/`
; directory relative to the project root every 5 seconds (debounced).
global XAML_DESIGNER_BACKUPS_ENABLED := true
global XAML_DESIGNER_MAX_BACKUPS := 50