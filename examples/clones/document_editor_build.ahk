#Requires AutoHotkey v2.0
#SingleInstance Force

; Set working directory to the script's directory for safety
SetWorkingDir(A_ScriptDir)

; Determine paths, ask if missing
basePath := "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
if !FileExist(basePath) {
    if (A_AhkPath != "" && InStr(A_AhkPath, "AutoHotkey64.exe")) {
        basePath := A_AhkPath
    } else {
        basePath := FileSelect(1, "C:\Program Files\AutoHotkey", "Select AutoHotkey64.exe Location", "Executables (AutoHotkey64.exe)")
        if (basePath == "") {
            MsgBox("Error: AutoHotkey64.exe is required to build the DLL.", "Build Failed", "Iconx")
            ExitApp()
        }
    }
}

compilerPath := "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
if !FileExist(compilerPath) {
    compilerPath := FileSelect(1, "C:\Program Files\AutoHotkey", "Select Ahk2Exe.exe Location", "Executables (Ahk2Exe.exe)")
    if (compilerPath == "") {
        MsgBox("Error: Ahk2Exe.exe is required to compile.", "Build Failed", "Iconx")
        ExitApp()
    }
}

; 1. Generate the bundled DLL
ToolTip("Step 1: Generating bundled DLL (precompiled BAML + events + embedded OpenXml DLL)...")
RunWait('"' basePath '" document_editor.ahk /build')
ToolTip()

if !FileExist("editor.dll") {
    MsgBox("Error: Failed to generate editor.dll.`nCheck if there were C# compiler errors.", "Build Failed", "Iconx")
    ExitApp()
}

; 2. Compile using Ahk2Exe
ToolTip("Step 2: Compiling AutoHotkey script to standalone EXE...")

; Run Ahk2Exe command to build document_editor.exe
cmd := '"' compilerPath '" /in "document_editor.ahk" /out "document_editor.exe" /base "' basePath '"'
status := RunWait(cmd)
ToolTip()

if (status == 0 && FileExist("document_editor.exe")) {
    MsgBox("Success! document_editor.exe has been compiled successfully.`n`nTo distribute, ship the 'document_editor.exe' and 'editor.dll' side-by-side in the same folder.`n`n(Optional: You can use Enigma Virtual Box on these two files to package them into a single, zero-extraction executable).", "Build Complete", "Iconi")
} else {
    MsgBox("Error: Ahk2Exe compilation failed.", "Build Failed", "Iconx")
}

ExitApp()