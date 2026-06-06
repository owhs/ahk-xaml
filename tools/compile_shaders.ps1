# Compile HLSL shaders (.fx) to Pixel Shader bytecode (.ps) and output Base64 for C# embedding

$fxcPath = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\fxc.exe"
if (-not (Test-Path $fxcPath)) {
    # Search fallback paths
    $kits = Get-ChildItem "C:\Program Files (x86)\Windows Kits\10\bin" -ErrorAction SilentlyContinue
    if ($kits) {
        $latest = $kits | Sort-Object Name -Descending | Select-Object -First 1
        $fxcPath = Join-Path $latest.FullName "x64\fxc.exe"
    }
}

if (-not (Test-Path $fxcPath)) {
    Write-Error "Could not locate fxc.exe compiler!"
    exit 1
}

Write-Output "Using compiler: $fxcPath"

$shaderDir = Join-Path $PSScriptRoot "..\lib\shaders"
if (-not (Test-Path $shaderDir)) {
    Write-Error "Shader directory does not exist: $shaderDir"
    exit 1
}

$fxFiles = Get-ChildItem $shaderDir -Filter *.fx

foreach ($file in $fxFiles) {
    $name = $file.BaseName
    $psPath = Join-Path $shaderDir "$name.ps"
    Write-Output "Compiling $name.fx..."
    
    # Confetti uses ps_3_0, others use ps_2_0
    $profile = "ps_2_0"
    if ($name -eq "confetti") {
        $profile = "ps_3_0"
    }
    
    # Run fxc compiler
    # Redirect fxc standard output/error to a temp variable or to the pipeline
    $compOutput = & $fxcPath /T $profile /E main /Fo $psPath $file.FullName 2>&1
    Write-Output $compOutput
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to compile $name.fx"
        continue
    }
    
    # Read bytes and convert to Base64
    $bytes = [System.IO.File]::ReadAllBytes($psPath)
    $base64 = [System.Convert]::ToBase64String($bytes)
    
    # Output C# format
    Write-Output "`n// --- Base64 bytecode for $name (profile: $profile) ---"
    Write-Output "public static readonly string $($name)Bytecode = `"$base64`";`n"
}
