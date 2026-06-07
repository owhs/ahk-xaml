#Requires AutoHotkey v2.0
#SingleInstance Force

; Include core libraries and PanelManager
#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Config.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Generator.ahk"
#Include "../../lib/XAML_Components.ahk"
#Include "../../lib/XAML_PanelManager.ahk"

; Pre-warm the background WPF engine
XAMLHost.Prewarm()

; Define Layout Save File
layoutIni := A_ScriptDir "\pyramid_layout.ini"
PanelManager.IniFile := layoutIni
PanelManager.FollowMode := true

ReadIniInt(file, section, key, defaultVal) {
    try {
        valStr := IniRead(file, section, key, String(defaultVal))
        if (valStr == "" || !RegExMatch(valStr, "^-?\d+$"))
            return defaultVal
        return Integer(valStr)
    } catch {
        return defaultVal
    }
}

ReadIniBool(file, section, key, defaultVal) {
    try {
        valStr := IniRead(file, section, key, defaultVal ? "True" : "False")
        return (valStr == "True" || valStr == "1")
    } catch {
        return defaultVal
    }
}

; Load saved MiddleFace position and Topmost state, and settings safely
global defaultMX := ReadIniInt(layoutIni, "MiddleFace", "X", 405)
global defaultMY := ReadIniInt(layoutIni, "MiddleFace", "Y", 400)
global isTopmost := ReadIniBool(layoutIni, "Global", "Topmost", false)
global savedGlow := ReadIniBool(layoutIni, "Global", "Glow", false)
global savedPulse := ReadIniBool(layoutIni, "Global", "Pulse", false)
global powerVal := ReadIniInt(layoutIni, "Global", "Power", 50)
global isPulsing := savedPulse

; 1. Define XAML templates for the three triangular faces
; - Left Face (pointing UP)
leftFaceXaml := '
(
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Pyramid Left" Width="220" Height="200"
        AllowsTransparency="True" Background="Transparent" WindowStyle="None">

    <Grid>
        <Polygon Name="DragArea" Points="110,5 215,190 5,190" Stroke="#FFFD008C" StrokeThickness="2" Cursor="SizeAll">
            <Polygon.Fill>
                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                    <GradientStop Color="#FC1D1D21" Offset="0.0"/>
                    <GradientStop Color="#FC0D0D0F" Offset="1.0"/>
                </LinearGradientBrush>
            </Polygon.Fill>
            <Polygon.Effect>
                <DropShadowEffect Color="#FFFD008C" BlurRadius="15" ShadowDepth="0" Opacity="0.8"/>
            </Polygon.Effect>
        </Polygon>
        
        <Grid Margin="30,75,30,20">
            <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="LEFT FACE" Foreground="#FFFD008C" FontWeight="Bold" FontSize="12" HorizontalAlignment="Center"/>
                <TextBlock Text="Telemetry Module" Foreground="#888888" FontSize="9" HorizontalAlignment="Center" Margin="0,2,0,8"/>
                
                <CheckBox Name="ChkGlow" Content="Enable Glow" Foreground="White" FontSize="11" HorizontalAlignment="Center" Margin="0,0,0,5" Focusable="False"/>
                <CheckBox Name="ChkPulse" Content="Enable Pulse" Foreground="White" FontSize="11" HorizontalAlignment="Center" Margin="0,0,0,5" Focusable="False"/>
                <CheckBox Name="ChkTopmost" Content="Always on Top" Foreground="White" FontSize="11" HorizontalAlignment="Center" Focusable="False"/>
            </StackPanel>
        </Grid>
    </Grid>
</Window>
)'

; - Middle Face (pointing DOWN - upside down)
middleFaceXaml := '
(
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Pyramid Middle" Width="220" Height="200"
        AllowsTransparency="True" Background="Transparent" WindowStyle="None">

    <Grid>
        <Polygon Name="DragArea" Points="5,5 215,5 110,190" Stroke="#FF00D2FF" StrokeThickness="2" Cursor="SizeAll">
            <Polygon.Fill>
                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                    <GradientStop Color="#FC1D1D21" Offset="0.0"/>
                    <GradientStop Color="#FC0D0D0F" Offset="1.0"/>
                </LinearGradientBrush>
            </Polygon.Fill>
            <Polygon.Effect>
                <DropShadowEffect Color="#FF00D2FF" BlurRadius="15" ShadowDepth="0" Opacity="0.8"/>
            </Polygon.Effect>
        </Polygon>
        
        <Grid Margin="30,20,30,65">
            <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="MIDDLE FACE" Foreground="#FF00D2FF" FontWeight="Bold" FontSize="12" HorizontalAlignment="Center"/>
                <TextBlock Text="Reactor Control" Foreground="#888888" FontSize="9" HorizontalAlignment="Center" Margin="0,2,0,5"/>
                <TextBlock Name="TxtStatus" Text="" Foreground="#FF00D2FF" FontSize="9" HorizontalAlignment="Center" Margin="0,0,0,8"/>
                
                <Button Name="BtnSync" Content="SYNC FACES" Width="80" Height="22" Foreground="White" BorderThickness="0" Cursor="Hand" Margin="0,0,0,12">
                    <Button.Resources>
                        <Style TargetType="Button">
                            <Setter Property="Background" Value="#FF252528"/>
                            <Setter Property="Template">
                                <Setter.Value>
                                    <ControlTemplate TargetType="Button">
                                        <Border Background="{TemplateBinding Background}" CornerRadius="11" BorderBrush="#FF00D2FF" BorderThickness="1">
                                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Border>
                                        <ControlTemplate.Triggers>
                                            <Trigger Property="IsMouseOver" Value="True">
                                                <Setter Property="Background" Value="#FF00D2FF"/>
                                                <Setter Property="Foreground" Value="Black"/>
                                            </Trigger>
                                        </ControlTemplate.Triggers>
                                    </ControlTemplate>
                                </Setter.Value>
                            </Setter>
                        </Style>
                    </Button.Resources>
                </Button>
                
                <Button Name="BtnClose" Content="Exit System" Width="70" Height="18" Foreground="#FFFF5555" BorderThickness="0" Cursor="Hand">
                    <Button.Resources>
                        <Style TargetType="Button">
                            <Setter Property="Background" Value="Transparent"/>
                            <Setter Property="Template">
                                <Setter.Value>
                                    <ControlTemplate TargetType="Button">
                                        <Border Background="{TemplateBinding Background}">
                                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Border>
                                        <ControlTemplate.Triggers>
                                            <Trigger Property="IsMouseOver" Value="True">
                                                <Setter Property="Foreground" Value="White"/>
                                            </Trigger>
                                        </ControlTemplate.Triggers>
                                    </ControlTemplate>
                                </Setter.Value>
                            </Setter>
                        </Style>
                    </Button.Resources>
                </Button>
            </StackPanel>
        </Grid>
    </Grid>
</Window>
)'

; - Right Face (pointing UP)
rightFaceXaml := '
(
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Pyramid Right" Width="220" Height="200"
        AllowsTransparency="True" Background="Transparent" WindowStyle="None">

    <Grid>
        <Polygon Name="DragArea" Points="110,5 215,190 5,190" Stroke="#FF8D00FF" StrokeThickness="2" Cursor="SizeAll">
            <Polygon.Fill>
                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                    <GradientStop Color="#FC1D1D21" Offset="0.0"/>
                    <GradientStop Color="#FC0D0D0F" Offset="1.0"/>
                </LinearGradientBrush>
            </Polygon.Fill>
            <Polygon.Effect>
                <DropShadowEffect Color="#FF8D00FF" BlurRadius="15" ShadowDepth="0" Opacity="0.8"/>
            </Polygon.Effect>
        </Polygon>
        
        <Grid Margin="30,75,30,20">
            <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
                <TextBlock Text="RIGHT FACE" Foreground="#FF8D00FF" FontWeight="Bold" FontSize="12" HorizontalAlignment="Center"/>
                <TextBlock Text="Reactor Output" Foreground="#888888" FontSize="9" HorizontalAlignment="Center" Margin="0,2,0,8"/>
                
                <TextBlock Text="Power Level: 50%" Name="TxtPower" Foreground="White" FontSize="10" HorizontalAlignment="Center" Margin="0,0,0,3"/>
                <Slider Name="PowerSlider" Tag="AllowPassive" Minimum="0" Maximum="100" Value="50" Width="100" HorizontalAlignment="Center" Focusable="False"/>
            </StackPanel>
        </Grid>
    </Grid>
</Window>
)'

; 2. Define panels in PanelManager
; Mathematically precise snapped layout (perfect fit, zero gaps):
; - Left Face (pointing UP) at (300, 400)
; - Middle Face (pointing DOWN) at (405, 400)
; - Right Face (pointing UP) at (510, 400)
PanelManager.RegisterPanel("LeftFace", "Pyramid Left", defaultMX - 110, defaultMY, 220, 200)
PanelManager.RegisterPanel("MiddleFace", "Pyramid Middle", defaultMX, defaultMY, 220, 200)
PanelManager.RegisterPanel("RightFace", "Pyramid Right", defaultMX + 110, defaultMY, 220, 200)

; Ensure they are prejoined and pinned by default if not set in INI
if (!PanelManager.Panels["LeftFace"].Pinned) {
    PanelManager.Panels["LeftFace"].Pinned := true
    PanelManager.Panels["LeftFace"].PinOffsetX := -110
    PanelManager.Panels["LeftFace"].PinOffsetY := 0
}
if (!PanelManager.Panels["RightFace"].Pinned) {
    PanelManager.Panels["RightFace"].Pinned := true
    PanelManager.Panels["RightFace"].PinOffsetX := 110
    PanelManager.Panels["RightFace"].PinOffsetY := 0
}

; 3. Instantiate the three custom XAML hosts
leftFaceHost := XAMLHost(leftFaceXaml)
middleFaceHost := XAMLHost(middleFaceXaml)
rightFaceHost := XAMLHost(rightFaceXaml)

; Associate them with the PanelManager data structures
PanelManager.Panels["LeftFace"].Instance := leftFaceHost
PanelManager.Panels["MiddleFace"].Instance := middleFaceHost
PanelManager.Panels["RightFace"].Instance := rightFaceHost

; 4. Set up interactive event handlers
leftFaceHost.OnEvent("ChkGlow", "Click", (state, ctrl, event) => OnGlowToggled(state))
leftFaceHost.OnEvent("ChkPulse", "Click", (state, ctrl, event) => OnPulseToggled(state))
leftFaceHost.OnEvent("ChkTopmost", "Click", (state, ctrl, event) => OnTopmostToggled(state))
leftFaceHost.OnEvent("Window", "Closing", (*) => ExitApp())
leftFaceHost.Track("ChkGlow")
leftFaceHost.Track("ChkPulse")
leftFaceHost.Track("ChkTopmost")

rightFaceHost.OnEvent("PowerSlider", "ValueChanged", (state, ctrl, event) => OnPowerChanged(state))
rightFaceHost.OnEvent("Window", "Closing", (*) => ExitApp())
rightFaceHost.Track("PowerSlider")

middleFaceHost.OnEvent("BtnSync", "Click", (*) => OnSyncClicked())
middleFaceHost.OnEvent("BtnClose", "Click", (*) => ExitApp())
middleFaceHost.OnEvent("Window", "Closing", (*) => ExitApp())

; 5. Show windows asynchronously
leftFaceHost.Show()
middleFaceHost.Show()
rightFaceHost.Show()

; Disable DWM Glass Frame on load to get pure custom shape transparency
leftFaceHost.Update("Window", "GlassFrameThickness", "0")
middleFaceHost.Update("Window", "GlassFrameThickness", "0")
rightFaceHost.Update("Window", "GlassFrameThickness", "0")

; Wait for WPF HWNDs to be initialized
while (!leftFaceHost.wpfHwnd || !middleFaceHost.wpfHwnd || !rightFaceHost.wpfHwnd) {
    Sleep(10)
}

WinSetStyle("-0x10000", "ahk_id " leftFaceHost.wpfHwnd)
WinSetStyle("-0x10000", "ahk_id " middleFaceHost.wpfHwnd)
WinSetStyle("-0x10000", "ahk_id " rightFaceHost.wpfHwnd)


; 6. Populate HWNDs and initialize PanelManager follow-dragging
PanelManager.Panels["LeftFace"].GuiHwnd := leftFaceHost.wpfHwnd
PanelManager.Panels["MiddleFace"].GuiHwnd := middleFaceHost.wpfHwnd
PanelManager.Panels["RightFace"].GuiHwnd := rightFaceHost.wpfHwnd

; Use the MiddleFace as the main controller hook for the WinEvent follow hook
PanelManager.Init(middleFaceHost, layoutIni)

; Move MiddleFace (main window) to its saved or default position
WinMove(defaultMX, defaultMY, , , "ahk_id " middleFaceHost.wpfHwnd)

; Ensure panels are positioned and synced to the main window immediately
PanelManager.ShowPanel("LeftFace")
PanelManager.ShowPanel("RightFace")

; Apply saved Topmost state
leftFaceHost.Update("Window", "Topmost", isTopmost ? "True" : "False")
middleFaceHost.Update("Window", "Topmost", isTopmost ? "True" : "False")
rightFaceHost.Update("Window", "Topmost", isTopmost ? "True" : "False")
leftFaceHost.Update("ChkTopmost", "IsChecked", isTopmost ? "True" : "False")

; Apply saved Glow state
leftFaceHost.Update("ChkGlow", "IsChecked", savedGlow ? "True" : "False")
leftFaceHost.Update("DragArea", "Effect.Opacity", savedGlow ? "0.8" : "0.0")

; Apply saved Pulse state
leftFaceHost.Update("ChkPulse", "IsChecked", isPulsing ? "True" : "False")

; Apply saved Power level state
rightFaceHost.Update("PowerSlider", "Value", String(powerVal))
rightFaceHost.Update("TxtPower", "Text", "Power Level: " powerVal "%")
colorHex := Format("{:02X}", Round(powerVal * 2.55))
rightFaceHost.Update("DragArea", "Stroke", "#FF" colorHex "00FF")


; 7. Interactive Callback Functions
OnGlowToggled(state) {
    hasGlow := state["ChkGlow"] == "True"
    try {
        leftFaceHost.Update("DragArea", "Effect.Opacity", hasGlow ? "0.8" : "0.0")
    }
}

OnPulseToggled(state) {
    global isPulsing
    isPulsing := state["ChkPulse"] == "True"
}

OnPowerChanged(state) {
    power := Round(Float(state["PowerSlider"]))
    try {
        rightFaceHost.Update("TxtPower", "Text", "Power Level: " power "%")
        colorHex := Format("{:02X}", Round(power * 2.55))
        rightFaceHost.Update("DragArea", "Stroke", "#FF" colorHex "00FF")
    }
}

global syncTimer := 0

OnSyncClicked() {
    try {
        middleFaceHost.Update("TxtStatus", "Text", "Syncing reactor...")
        
        global syncTimer
        if (syncTimer) {
            SetTimer(syncTimer, 0)
        }
        
        currentVal := Float(rightFaceHost.Query("PowerSlider"))
        targetVal := 80.0
        
        syncTimer := () => (
            currentVal := currentVal + (targetVal - currentVal) * 0.15,
            (Abs(targetVal - currentVal) < 1.0) ? (
                rightFaceHost.Update("PowerSlider", "Value", "80"),
                middleFaceHost.Update("TxtStatus", "Text", "Reactor Synchronized!"),
                SetTimer(syncTimer, 0),
                syncTimer := 0
            ) : (
                rightFaceHost.Update("PowerSlider", "Value", String(currentVal))
            )
        )
        SetTimer(syncTimer, 30)
    }
}

OnTopmostToggled(state) {
    global isTopmost
    isTopmost := (state["ChkTopmost"] == "True")
    leftFaceHost.Update("Window", "Topmost", isTopmost ? "True" : "False")
    middleFaceHost.Update("Window", "Topmost", isTopmost ? "True" : "False")
    rightFaceHost.Update("Window", "Topmost", isTopmost ? "True" : "False")
}

; Register exit routine to save position and topmost settings
OnExit(SavePyramidState)

SavePyramidState(*) {
    global isTopmost, isPulsing
    ; Save MiddleFace (Main Window) position safely
    if (middleFaceHost.wpfHwnd && WinExist("ahk_id " middleFaceHost.wpfHwnd)) {
        WinGetPos(&mX, &mY, , , "ahk_id " middleFaceHost.wpfHwnd)
        if (mX != "" && mY != "" && mX > -10000 && mY > -10000) {
            IniWrite(mX, layoutIni, "MiddleFace", "X")
            IniWrite(mY, layoutIni, "MiddleFace", "Y")
        }
    }
    
    ; Save Topmost setting
    try {
        IniWrite(isTopmost ? "True" : "False", layoutIni, "Global", "Topmost")
    }
    
    ; Save other settings
    try {
        ; Glow
        glowState := leftFaceHost.Query("ChkGlow")
        if (glowState != "") {
            IniWrite(glowState, layoutIni, "Global", "Glow")
        }
        
        ; Pulse
        IniWrite(isPulsing ? "True" : "False", layoutIni, "Global", "Pulse")
        
        ; Power
        powerVal := rightFaceHost.Query("PowerSlider")
        if (powerVal != "") {
            IniWrite(powerVal, layoutIni, "Global", "Power")
        }
    }
}

; Simple pulsing color animation loop
global animTime := 0.0
SetTimer(PulseLoop, 33)

PulseLoop() {
    global isPulsing, animTime
    if (!isPulsing)
        return
    animTime += 0.05
    intensity := 120 + Round(80 * Sin(animTime))
    colorHex := Format("{:02X}", intensity)
    try {
        leftFaceHost.Update("DragArea", "Stroke", "#FFFF00" colorHex)
    }
}

; Disable Win+Arrow snapping hotkeys for the active pyramid window
#HotIf (leftFaceHost.wpfHwnd && WinActive("ahk_id " leftFaceHost.wpfHwnd)) || (middleFaceHost.wpfHwnd && WinActive("ahk_id " middleFaceHost.wpfHwnd)) || (rightFaceHost.wpfHwnd && WinActive("ahk_id " rightFaceHost.wpfHwnd))
#Left:: return
#Right:: return
#Up:: return
#Down:: return
+#Left:: return
+#Right:: return
+#Up:: return
+#Down:: return
#HotIf

