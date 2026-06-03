#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
; AHK-XAML Generic Builder & Compiler GUI
; ==============================================================================
; A comprehensive tool to bundle assets into a DLL and compile AHK scripts.
; Features discovery of AHK exes, setting caching, BAML compile status detection,
; and fallback to raw XAML bundling.
; ==============================================================================

SetWorkingDir(A_ScriptDir)
settingsFile := "build_settings.ini"

; --- DEFAULT PATH DISCOVERY ---
defaultAhk := "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
if !FileExist(defaultAhk) && A_AhkPath != "" && InStr(A_AhkPath, "AutoHotkey64.exe") {
    defaultAhk := A_AhkPath
}
defaultCompiler := "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"

; --- LOAD CACHED SETTINGS ---
ahkPath := IniRead(settingsFile, "Paths", "AutoHotkey64", defaultAhk)
compilerPath := IniRead(settingsFile, "Paths", "Ahk2Exe", defaultCompiler)
lastScript := IniRead(settingsFile, "History", "LastScript", "")
forceBaml := IniRead(settingsFile, "Options", "ForceBaml", "1") == "1"
optDiag := IniRead(settingsFile, "Options", "Diagnostics", "1") == "1"
optLog := IniRead(settingsFile, "Options", "Logging", "0") == "1"
optTrace := IniRead(settingsFile, "Options", "Tracing", "1") == "1"
optDevTools := IniRead(settingsFile, "Options", "DevTools", "1") == "1"

; Override target script if passed as command line argument
if (A_Args.Length > 0) {
    lastScript := A_Args[1]
}

; Verify if BAML compilation tools are present
bamlPossible := FileExist("compile_baml.ps1")

; --- CREATE GUI ---
myGui := Gui("+Resize -MaximizeBox", "AHK-XAML Application Builder")
myGui.SetFont("s9", "Segoe UI")
myGui.BackColor := "F9F9F9"

myGui.Add("GroupBox", "w560 h110", "Compiler Environment")
myGui.Add("Text", "xp+15 yp+25 w120", "AutoHotkey64.exe:")
txtAhk := myGui.Add("Edit", "x+10 w300 h22 ReadOnly", ahkPath)
btnAhk := myGui.Add("Button", "x+10 w80 h22", "Browse...")
btnAhk.OnEvent("Click", SelectAhkPath)

myGui.Add("Text", "x15 y+15 w120", "Ahk2Exe.exe:")
txtCompiler := myGui.Add("Edit", "x+10 w300 h22 ReadOnly", compilerPath)
btnCompiler := myGui.Add("Button", "x+10 w80 h22", "Browse...")
btnCompiler.OnEvent("Click", SelectCompilerPath)

myGui.Add("GroupBox", "x10 y+25 w560 h100", "Target Application")
myGui.Add("Text", "xp+15 yp+25 w120", "Target AHK Script:")
txtScript := myGui.Add("Edit", "x+10 w300 h22", lastScript)
txtScript.OnEvent("Change", ScriptChanged)
btnScript := myGui.Add("Button", "x+10 w80 h22", "Browse...")
btnScript.OnEvent("Click", SelectScriptPath)

myGui.Add("Text", "x15 y+15 w120", "Custom DLL Name:")
txtDllName := myGui.Add("Edit", "x+10 w150 h22", "")
myGui.Add("Text", "x+10 cGray", "(Optional - defaults to script name)")

myGui.Add("GroupBox", "x10 y+25 w560 h180", "Build Options")
chkBaml := myGui.Add("CheckBox", "xp+15 yp+25 w250 h20 Checked" (forceBaml && bamlPossible ? "1" : "0"), "Enable BAML Compilation (faster load)")
if (!bamlPossible) {
    chkBaml.Value := 0
    chkBaml.Enabled := false
    myGui.Add("Text", "x+10 w250 cD00000", "⚠ compile_baml.ps1 not found (XAML fallback)")
} else {
    myGui.Add("Text", "x+10 w250 c0078D7", "✓ BAML Compiler is available")
}

chkDiag := myGui.Add("CheckBox", "x25 y+10 w520 h20" (optDiag ? " Checked" : ""), "Enable Diagnostics (XAML_DIAGNOSTICS_ENABLED)")
chkLog := myGui.Add("CheckBox", "x25 y+8 w520 h20" (optLog ? " Checked" : ""), "Enable Logging (XAML_ENABLE_LOGGING)")
chkTrace := myGui.Add("CheckBox", "x25 y+8 w520 h20" (optTrace ? " Checked" : ""), "Enable Line Tracing (XAML_ENABLE_TRACING)")
chkDevTools := myGui.Add("CheckBox", "x25 y+8 w520 h20" (optDevTools ? " Checked" : ""), "Enable DevTools (XAML_ENABLE_DEVTOOLS)")

btnBuild := myGui.Add("Button", "x15 y+30 w180 h32 Default", "Build Standalone Application")
btnBuild.OnEvent("Click", RunBuild)

btnExit := myGui.Add("Button", "x+260 w100 h32", "Close")
btnExit.OnEvent("Click", (*) => ExitApp())

statusBox := myGui.Add("Edit", "x10 y+15 w560 h140 ReadOnly +VScroll -Wrap Background1E1E1E cE0E0E0", "Ready.`n")
myGui.SetFont("s8", "Consolas")

myGui.Show("w580 h620")
if (lastScript != "") {
    LoadDllNameFromScript(lastScript)
}

; --- EVENT HANDLERS ---

SelectAhkPath(*) {
    path := FileSelect(1, "C:\Program Files\AutoHotkey", "Select AutoHotkey64.exe", "AutoHotkey64.exe (AutoHotkey64.exe)")
    if (path != "") {
        txtAhk.Value := path
        IniWrite(path, settingsFile, "Paths", "AutoHotkey64")
    }
}

SelectCompilerPath(*) {
    path := FileSelect(1, "C:\Program Files\AutoHotkey", "Select Ahk2Exe.exe", "Ahk2Exe.exe (Ahk2Exe.exe)")
    if (path != "") {
        txtCompiler.Value := path
        IniWrite(path, settingsFile, "Paths", "Ahk2Exe")
    }
}

SelectScriptPath(*) {
    path := FileSelect(1, "", "Select Target AutoHotkey Script", "AutoHotkey Scripts (*.ahk)")
    if (path != "") {
        txtScript.Value := path
        IniWrite(path, settingsFile, "History", "LastScript")
        LoadDllNameFromScript(path)
    }
}

ScriptChanged(*) {
    LoadDllNameFromScript(txtScript.Value)
}

LoadDllNameFromScript(scriptPath) {
    if (scriptPath == "" || !FileExist(scriptPath)) {
        txtDllName.Value := ""
        return
    }
    try {
        scriptContent := FileRead(scriptPath, "UTF-8")
        if RegExMatch(scriptContent, "mi)^[ \t]*(?:global\s+)?CUSTOM_DLL_BUNDLE_NAME\s*:=\s*[\x22\x27]([^\x22\x27]+)[\x22\x27]", &match) {
            txtDllName.Value := match[1]
        } else {
            txtDllName.Value := ""
        }
    } catch {
        txtDllName.Value := ""
    }
}

Log(text) {
    statusBox.Value .= text "`n"
    ; Auto-scroll to end
    SendMessage(0x0115, 7, 0, statusBox.Hwnd)
}

RunBuild(*) {
    ahk := txtAhk.Value
    compiler := txtCompiler.Value
    script := txtScript.Value
    customDll := Trim(txtDllName.Value)

    if (ahk == "" || !FileExist(ahk)) {
        MsgBox("Please select a valid AutoHotkey64.exe path.", "Error", "Iconx")
        return
    }
    if (compiler == "" || !FileExist(compiler)) {
        MsgBox("Please select a valid Ahk2Exe.exe path.", "Error", "Iconx")
        return
    }
    if (script == "" || !FileExist(script)) {
        MsgBox("Please select a valid target AHK script.", "Error", "Iconx")
        return
    }

    statusBox.Value := "Starting build process...`n"
    btnBuild.Enabled := false

    SplitPath(script, &scriptName, &scriptDir, , &nameNoExt)
    
    ; Check if script contains the XAML_Builder include
    scriptContent := FileRead(script, "UTF-8")
    modified := false
    addedBuilderInclude := false

    if !RegExMatch(scriptContent, "i)#Include\s+[\x22\x27][^\x22\x27]*XAML_Builder\.ahk[\x22\x27]") {
        relPath := GetRelativePath(scriptDir, A_ScriptDir "\..\lib\XAML_Builder.ahk")
        ; Try to find .Show() to insert it right before it
        if (pos := RegExMatch(scriptContent, "mi)^[ \t]*\w+\.Show\b")) {
            leftSide := SubStr(scriptContent, 1, pos - 1)
            rightSide := SubStr(scriptContent, pos)
            nl := InStr(scriptContent, "`r`n") ? "`r`n" : "`n"
            if (leftSide != "" && SubStr(leftSide, -1) != "`n") {
                leftSide .= nl
            }
            scriptContent := leftSide '#Include "' relPath '"' nl rightSide
            modified := true
            addedBuilderInclude := true
            Log("✓ Automatically inserted XAML_Builder.ahk include into script.")
        } else {
            MsgBox("Error: Could not locate '.Show()' call in the target script.`nCannot insert builder include. Build aborted.", "Build Error", "Iconx")
            btnBuild.Enabled := true
            return
        }
    }

    targetDll := (customDll != "") ? customDll : nameNoExt "_bundled.dll"
    if (SubStr(targetDll, -4) != ".dll")
        targetDll .= ".dll"

    ; Ensure the script's CUSTOM_DLL_BUNDLE_NAME matches targetDll
    if RegExMatch(scriptContent, "mi)^[ \t]*(?:global\s+)?CUSTOM_DLL_BUNDLE_NAME\s*:=.*$") {
        scriptContent := RegExReplace(scriptContent, "mi)^[ \t]*(?:global\s+)?CUSTOM_DLL_BUNDLE_NAME\s*:=.*$", 'global CUSTOM_DLL_BUNDLE_NAME := "' targetDll '"')
        modified := true
        Log("✓ Updated CUSTOM_DLL_BUNDLE_NAME in script to: " targetDll)
    } else if (customDll != "") {
        if (pos := RegExMatch(scriptContent, "mi)^[ \t]*#Requires\b")) {
            posLineEnd := InStr(scriptContent, "`n", , pos)
            left := SubStr(scriptContent, 1, posLineEnd)
            right := SubStr(scriptContent, posLineEnd + 1)
            scriptContent := left 'global CUSTOM_DLL_BUNDLE_NAME := "' targetDll '"`n' right
        } else {
            scriptContent := 'global CUSTOM_DLL_BUNDLE_NAME := "' targetDll '"`n' scriptContent
        }
        modified := true
        Log("✓ Set CUSTOM_DLL_BUNDLE_NAME in script to: " targetDll)
    }

    if (modified) {
        try {
            FileDelete(script)
            FileAppend(scriptContent, script, "UTF-8")
        } catch Any as err {
            MsgBox("Failed to update script file during build preparation:`n`n" err.Message, "Error", "Iconx")
            btnBuild.Enabled := true
            return
        }
    }

    ; Configure temporary flag values in XAML_Config.ahk
    configPath := A_ScriptDir "\..\lib\XAML_Config.ahk"
    originalConfigContent := ""
    if FileExist(configPath) {
        try {
            originalConfigContent := FileRead(configPath, "UTF-8")
            configContent := originalConfigContent
            configContent := RegExReplace(configContent, "mi)^[ \t]*global\s+XAML_DIAGNOSTICS_ENABLED\s*:=.*$", 'global XAML_DIAGNOSTICS_ENABLED := ' (chkDiag.Value ? "true" : "false"))
            configContent := RegExReplace(configContent, "mi)^[ \t]*global\s+XAML_ENABLE_LOGGING\s*:=.*$", 'global XAML_ENABLE_LOGGING := ' (chkLog.Value ? "true" : "false"))
            configContent := RegExReplace(configContent, "mi)^[ \t]*global\s+XAML_ENABLE_TRACING\s*:=.*$", 'global XAML_ENABLE_TRACING := ' (chkTrace.Value ? "true" : "false"))
            configContent := RegExReplace(configContent, "mi)^[ \t]*global\s+XAML_ENABLE_DEVTOOLS\s*:=.*$", 'global XAML_ENABLE_DEVTOOLS := ' (chkDevTools.Value ? "true" : "false"))
            
            FileDelete(configPath)
            FileAppend(configContent, configPath, "UTF-8")
            Log("✓ Temporarily updated configuration flags in XAML_Config.ahk")
        } catch Any as err {
            Log("⚠ Warning: Failed to temporarily update XAML_Config.ahk: " err.Message)
        }
    }
    
    IniWrite(script, settingsFile, "History", "LastScript")
    IniWrite(chkBaml.Value ? "1" : "0", settingsFile, "Options", "ForceBaml")
    IniWrite(chkDiag.Value ? "1" : "0", settingsFile, "Options", "Diagnostics")
    IniWrite(chkLog.Value ? "1" : "0", settingsFile, "Options", "Logging")
    IniWrite(chkTrace.Value ? "1" : "0", settingsFile, "Options", "Tracing")
    IniWrite(chkDevTools.Value ? "1" : "0", settingsFile, "Options", "DevTools")

    Log("Target Script: " scriptName)
    Log("Working Directory: " scriptDir)
    Log("Output DLL Name: " targetDll)

    ; Set Environment Variable to force XAML bundling if BAML is disabled by user
    if (chkBaml.Value == 0) {
        EnvSet("AHK_XAML_FORCE_XAML", "1")
        Log("BAML compilation disabled. Forcing raw XAML bundling.")
    } else {
        EnvSet("AHK_XAML_FORCE_XAML", "0")
        Log("BAML compilation enabled.")
    }

    try {
        ; Step 1: Generate DLL
        Log("Step 1: Generating bundled DLL via the script's /build flag...")
        
        ; Delete old DLL to verify recreation
        oldDll := scriptDir "\" targetDll
        if FileExist(oldDll) {
            try FileDelete(oldDll)
        }

        cmdLine := '"' ahk '" "' script '" /build "' targetDll '"'
        status := RunWait(cmdLine, scriptDir, "Hide")

        if !FileExist(oldDll) {
            Log("⚠ Build Failed: The script did not generate the DLL asset.")
            Log("Ensure the script includes XAML_Builder.ahk at the end.")
            return
        }
        Log("✓ Bundled DLL created successfully: " targetDll)

        ; Step 2: Compile EXE
        Log("Step 2: Compiling AutoHotkey script using Ahk2Exe...")
        targetExe := scriptDir "\" nameNoExt ".exe"
        if FileExist(targetExe) {
            try FileDelete(targetExe)
        }

        compileCmd := '"' compiler '" /in "' script '" /out "' targetExe '" /base "' ahk '"'
        status := RunWait(compileCmd, scriptDir, "Hide")

        if !FileExist(targetExe) {
            Log("⚠ Build Failed: Ahk2Exe compilation failed.")
            return
        }
        Log("✓ Standalone Executable created successfully: " nameNoExt ".exe")
        Log("--------------------------------------------------")
        Log("SUCCESS! Build complete.")
        Log("To distribute: Ship '" nameNoExt ".exe' and '" targetDll "' side-by-side.")
        
        MsgBox("Success! Standalone build completed successfully.`n`nFiles generated:`n- " nameNoExt ".exe`n- " targetDll, "Build Complete", "Iconi")
    } finally {
        ; Restore temporary changes to script and config files
        RestoreTemporaryChanges(script, addedBuilderInclude, configPath, originalConfigContent)
        btnBuild.Enabled := true
    }
}

GetRelativePath(sourceDir, targetFile) {
    sourceDir := StrReplace(RTrim(sourceDir, "\"), "/", "\")
    targetFile := StrReplace(targetFile, "/", "\")
    sParts := StrSplit(sourceDir, "\")
    tParts := StrSplit(targetFile, "\")
    
    ; Find common prefix
    commonCount := 0
    maxCommon := Min(sParts.Length, tParts.Length)
    loop maxCommon {
        if (Format("{:L}", sParts[A_Index]) == Format("{:L}", tParts[A_Index]))
            commonCount++
        else
            break
    }
    
    relPath := ""
    ; Add parent directories for the remaining sourceDir parts
    loop sParts.Length - commonCount {
        relPath .= "..\"
    }
    
    ; Add the remaining targetFile parts
    loop tParts.Length - commonCount {
        relPath .= tParts[commonCount + A_Index] "\"
    }
    
    return RTrim(relPath, "\")
}

RestoreTemporaryChanges(scriptPath, addedInclude, configPath, originalConfig) {
    try {
        content := FileRead(scriptPath, "UTF-8")
        modified := false
        
        if (addedInclude) {
            content := RegExReplace(content, "mi)^[ \t]*#Include\s+[\x22\x27][^\x22\x27]*XAML_Builder\.ahk[\x22\x27](?:\r?\n)?")
            modified := true
        }
        
        ; Always strip temporary AXML metadata block if present
        newContent := RegExReplace(content, "s)(?:\r?\n)?[ \t]*;=== AXML METADATA ===.*;=== AXML METADATA END ===(?:\r?\n)?")
        if (newContent != content) {
            content := newContent
            modified := true
        }
        
        if (modified) {
            FileDelete(scriptPath)
            FileAppend(content, scriptPath, "UTF-8")
            Log("✓ Restored original script file (cleaned temporary include/metadata).")
        }
    } catch Any as err {
        Log("⚠ Warning: Failed to clean up script file: " err.Message)
    }
    
    if (configPath != "" && originalConfig != "") {
        try {
            FileDelete(configPath)
            FileAppend(originalConfig, configPath, "UTF-8")
            Log("✓ Restored original XAML_Config.ahk flags.")
        } catch Any as err {
            Log("⚠ Warning: Failed to restore XAML_Config.ahk: " err.Message)
        }
    }
}
