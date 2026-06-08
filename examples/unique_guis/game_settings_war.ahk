#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Components.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"

; ==============================================================================
; CUSTOM DIALOG STYLING & HELPER
; ==============================================================================
global CustomDialogOptions := {
    FontFamily: "Trebuchet MS, sans-serif",
    TitleForeground: "#FF9000",
    TitleFontFamily: "Impact",
    TitleFontWeight: "Normal",
    TitleFontSize: 16,
    MessageForeground: "#E9ECEF",
    MessageFontFamily: "Trebuchet MS",
    MessageFontSize: 13,
    FooterBackground: "#111315",
    CloseBtnWidth: 20,
    CloseBtnHeight: 20,
    CloseBtnMargin: "0,0,12,0",
    CloseBtnVerticalAlignment: "Center",
    CloseBtnTemplate: '
    (
        <Style TargetType="Button">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Rectangle x:Name="Box" Stroke="#4B5320" StrokeThickness="1.5" Fill="#141618"/>
                            <Path Data="M 0,0 L 8,8 M 8,0 L 0,8" Width="8" Height="8" Stretch="Uniform" Stroke="#8F9E4B" StrokeThickness="2" HorizontalAlignment="Center" VerticalAlignment="Center" IsHitTestVisible="False"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Box" Property="Fill" Value="#1E2225"/>
                                <Setter TargetName="Box" Property="Stroke" Value="#FF9000"/>
                                <Setter Property="Foreground" Value="#FF9000"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    )',
    CustomBackground: CustomDialogCustomBackground,
    Resources: '
    (
        <RadialGradientBrush x:Key="CustomRadialGlow" Center="0.5,0.5" RadiusX="0.75" RadiusY="0.75">
            <GradientStop Color="#15FF9000" Offset="0"/>
            <GradientStop Color="#00000000" Offset="1"/>
        </RadialGradientBrush>
        <LinearGradientBrush x:Key="GoldMetalBrush" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#2C302E" Offset="0.0"/>
            <GradientStop Color="#4B5320" Offset="0.4"/>
            <GradientStop Color="#8F9E4B" Offset="0.6"/>
            <GradientStop Color="#4B5320" Offset="0.8"/>
            <GradientStop Color="#2C302E" Offset="1.0"/>
        </LinearGradientBrush>
        <SolidColorBrush x:Key="TextMain" Color="#E9ECEF" />
        <SolidColorBrush x:Key="TextSub" Color="#9E9E9E" />
        <SolidColorBrush x:Key="Accent" Color="#FF9000" />
        <SolidColorBrush x:Key="ControlBg" Color="#141618" />
        <SolidColorBrush x:Key="ControlBorder" Color="#4B5320" />
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#141618"/>
            <Setter Property="Foreground" Value="#FFF"/>
            <Setter Property="BorderBrush" Value="#4B5320"/>
            <Setter Property="BorderThickness" Value="1.5"/>
            <Setter Property="Padding" Value="8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border x:Name="border" CornerRadius="0" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
                            <ScrollViewer x:Name="PART_ContentHost" Focusable="false" HorizontalScrollBarVisibility="Hidden" VerticalScrollBarVisibility="Hidden"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsFocused" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="#FF9000"/>
                                <Setter TargetName="border" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="#FF9000" BlurRadius="6" ShadowDepth="0" Opacity="0.5"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="#8F9E4B"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="DialogBtn" TargetType="Button">
            <Setter Property="Background" Value="#25282C"/>
            <Setter Property="Foreground" Value="#8F9E4B"/>
            <Setter Property="BorderBrush" Value="#4B5320"/>
            <Setter Property="BorderThickness" Value="1.5"/>
            <Setter Property="FontFamily" Value="Impact"/>
            <Setter Property="FontWeight" Value="Normal"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Border x:Name="Body" CornerRadius="0" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{TemplateBinding Background}"/>
                            <Border x:Name="InnerBorder" CornerRadius="0" Margin="2" BorderBrush="#10FFFFFF" BorderThickness="1" IsHitTestVisible="False"/>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="15,6"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Body" Property="Background" Value="#2E3238"/>
                                <Setter Property="BorderBrush" Value="#8F9E4B"/>
                                <Setter Property="Foreground" Value="#FF9000"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="DialogPrimaryBtn" TargetType="Button">
            <Setter Property="Background" Value="#4B5320"/>
            <Setter Property="Foreground" Value="#FFF"/>
            <Setter Property="BorderBrush" Value="#FF9000"/>
            <Setter Property="BorderThickness" Value="1.5"/>
            <Setter Property="FontFamily" Value="Impact"/>
            <Setter Property="FontWeight" Value="Normal"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Border x:Name="Body" CornerRadius="0" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                        <GradientStop Color="#5E6728" Offset="0"/>
                                        <GradientStop Color="#373D17" Offset="1"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                            </Border>
                            <Border x:Name="InnerBorder" CornerRadius="0" Margin="2" BorderBrush="#20FF9000" BorderThickness="1" IsHitTestVisible="False"/>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="15,6"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Body" Property="Background">
                                    <Setter.Value>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                            <GradientStop Color="#6F792F" Offset="0"/>
                                            <GradientStop Color="#454D1D" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Setter.Value>
                                </Setter>
                                <Setter Property="BorderBrush" Value="#FFB033"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    )'
}

CustomDialogCustomBackground(main) {
    bgGrid := main.Add("Grid").Grid_Row(0).Grid_RowSpan(3)
    bgGrid.SetProp("Panel.ZIndex", "-1")
    bgGrid.Add("Border").CornerRadius("0").Background("#1A1C1E")
    bgGrid.Add("Border").SetProp("IsHitTestVisible", "False").Background("{StaticResource CustomRadialGlow}")
    
    fgGrid := main.Add("Grid").Grid_Row(0).Grid_RowSpan(3)
    fgGrid.SetProp("Panel.ZIndex", "10")
    fgGrid.SetProp("IsHitTestVisible", "False")
    frame := fgGrid.Add("Border").CornerRadius("0").BorderThickness("2").Background("Transparent")
    frame.BorderBrush("{StaticResource GoldMetalBrush}")
}

ShowCustomDialog(opts) {
    mergedOpts := {}
    for k, v in CustomDialogOptions.OwnProps() {
        mergedOpts.%k% := v
    }
    for k, v in opts.OwnProps() {
        mergedOpts.%k% := v
    }
    return XDialog.Show(mergedOpts)
}

GenerateBackgroundScratches(bgGrid, count := 50) {
    ; Create predefined cluster centers around edges and corners
    centers := []
    centers.Push({x: 40, y: 40})   ; Top-left
    centers.Push({x: 900, y: 40})  ; Top-right
    centers.Push({x: 40, y: 610})  ; Bottom-left
    centers.Push({x: 900, y: 610}) ; Bottom-right
    centers.Push({x: 470, y: 30})  ; Top middle
    centers.Push({x: 470, y: 620}) ; Bottom middle
    centers.Push({x: 30, y: 325})  ; Left middle
    centers.Push({x: 910, y: 325}) ; Right middle

    Loop count {
        ; Pick a random cluster center
        center := centers[Random(1, centers.Length)]

        ; Apply tighter offsets to cluster the scratches organically near edges
        offsetX := (Random(-90, 90) + Random(-90, 90)) / 2
        offsetY := (Random(-90, 90) + Random(-90, 90)) / 2

        x0 := center.x + offsetX
        y0 := center.y + offsetY

        ; Power-law distribution of scratch lengths and thicknesses
        r := Random(1, 100)
        if (r < 75) {
            ; 75% micro-scratches
            length := Random(15, 45)
            thickness := Random(5, 9) / 10.0
            opacityMult := 0.6
        } else if (r < 90) {
            ; 21% medium scratches
            length := Random(45, 120)
            thickness := Random(9, 13) / 10.0
            opacityMult := 0.9
        } else {
            ; 4% major fractures
            length := Random(120, 320)
            thickness := Random(13, 18) / 10.0
            opacityMult := 1.2
        }

        ; Geological jointing sets: either horizontal-ish or vertical-ish
        if (Random(1, 100) > 40) {
            angle := Random(-20, 20) * 0.01745329
        } else {
            angle := (Random(0, 1) ? Random(75, 105) : Random(-105, -75)) * 0.01745329
        }

        x3 := x0 + Cos(angle) * length
        y3 := y0 + Sin(angle) * length

        ; Draw a jagged polyline instead of a smooth curve
        segments := Random(2, 4)
        pathData := "M " . Format("{1:.1f},{2:.1f}", x0, y0)

        dx := (x3 - x0) / segments
        dy := (y3 - y0) / segments

        ; Perpendicular vector for offset
        nx := -dy / (length = 0 ? 1 : length)
        ny := dx / (length = 0 ? 1 : length)

        Loop segments - 1 {
            mx := x0 + dx * A_Index
            my := y0 + dy * A_Index
            offset := Random(-15, 15) / 10.0 ; -1.5 to +1.5 pixels jagged offset
            pathData .= " L " . Format("{1:.1f},{2:.1f}", mx + nx * offset, my + ny * offset)
        }
        pathData .= " L " . Format("{1:.1f},{2:.1f}", x3, y3)

        ; Sometimes add a small jagged branch off longer cracks
        if (r >= 75 && Random(1, 100) > 50) {
            bx0 := x0 + dx * (segments // 2)
            by0 := y0 + dy * (segments // 2)
            blen := Random(10, length // 3)
            bangle := angle + (Random(0, 1) ? Random(40, 70) : Random(-70, -40)) * 0.01745329
            bx1 := bx0 + Cos(bangle) * blen
            by1 := by0 + Sin(bangle) * blen
            pathData .= Format(" M {1:.1f},{2:.1f} L {3:.1f},{4:.1f}", bx0, by0, bx1, by1)
        }

        shadowOpacity := Integer(Random(20, 40) * opacityMult)
        if (shadowOpacity > 60)
            shadowOpacity := 60
        ; 50% dark brown rust shadow, 50% black shadow
        colorHex := Random(1, 100) > 50 ? "000000" : "5C2C16"
        shadowBrush := "#" . Format("{1:02X}", shadowOpacity) . colorHex
        bgGrid.Add("Path").Data(pathData).Stroke(shadowBrush).StrokeThickness(String(thickness)).SetProp("IsHitTestVisible", "False")

        highlightOpacity := Integer(Random(10, 25) * opacityMult)
        if (highlightOpacity > 45)
            highlightOpacity := 45
        ; Steel silver highlight (translucent white)
        highlightBrush := "#" . Format("{1:02X}", highlightOpacity) . "FFFFFF"
        bgGrid.Add("Path").Data(pathData).Stroke(highlightBrush).StrokeThickness(String(thickness * 0.6)).Margin("1,1,0,0").SetProp("IsHitTestVisible", "False")
    }
}

; ==============================================================================
; GAME CONFIGURATION UTILITY DEMO
; 1: ; Functional demo showcasing premium custom vector style resources,
;     ; glowing neon checkboxes, specialized ComboBox dropdown, and custom keybinding inputs.
;     ; ==============================================================================

global AppState := {
    RightMouseLook: true,
    MoveLook: true,
    VanityKey: "f10",
    CombatKey: "",
    AutoRunEnabled: true,
    LookLeft: "a",
    LookRight: "d",
    Forward: "w",
    Backwards: "s",
    MoveLeft: "u",
    MoveRight: "o",
    GraphicQuality: "High Fidelity",
    Difficulty: "Normal",
    MouseSensitivity: 5.0,
    InvertY: false,
    Resolution: "2560x1440",
    VSync: false,
    RayTracing: false,
    MaxFPS: 144,
    MasterVolume: 80,
    MusicVolume: 60,
    SFXVolume: 75,
    VoiceChat: true
}

global infoDescriptions := Map()

LoadSettings() {
    iniFile := A_ScriptDir "\game_settings.ini"
    if FileExist(iniFile) {
        try {
            AppState.RightMouseLook := (IniRead(iniFile, "Gameplay", "RightMouseLook", "1") == "1")
            AppState.MoveLook := (IniRead(iniFile, "Gameplay", "MoveLook", "1") == "1")
            AppState.VanityKey := IniRead(iniFile, "Gameplay", "VanityKey", "f10")
            AppState.CombatKey := IniRead(iniFile, "Gameplay", "CombatKey", "")
            AppState.AutoRunEnabled := (IniRead(iniFile, "Gameplay", "AutoRunEnabled", "1") == "1")
            AppState.Difficulty := IniRead(iniFile, "Gameplay", "Difficulty", "Normal")
            AppState.MouseSensitivity := Float(IniRead(iniFile, "Gameplay", "MouseSensitivity", "5.0"))
            AppState.InvertY := (IniRead(iniFile, "Gameplay", "InvertY", "0") == "1")

            AppState.LookLeft := IniRead(iniFile, "Movement", "LookLeft", "a")
            AppState.LookRight := IniRead(iniFile, "Movement", "LookRight", "d")
            AppState.Forward := IniRead(iniFile, "Movement", "Forward", "w")
            AppState.Backwards := IniRead(iniFile, "Movement", "Backwards", "s")
            AppState.MoveLeft := IniRead(iniFile, "Movement", "MoveLeft", "u")
            AppState.MoveRight := IniRead(iniFile, "Movement", "MoveRight", "o")

            AppState.GraphicQuality := IniRead(iniFile, "Display", "GraphicQuality", "High Fidelity")
            AppState.Resolution := IniRead(iniFile, "Display", "Resolution", "2560x1440")
            AppState.VSync := (IniRead(iniFile, "Display", "VSync", "0") == "1")
            AppState.RayTracing := (IniRead(iniFile, "Display", "RayTracing", "0") == "1")
            AppState.MaxFPS := Integer(IniRead(iniFile, "Display", "MaxFPS", "144"))

            AppState.MasterVolume := Integer(IniRead(iniFile, "Audio", "MasterVolume", "80"))
            AppState.MusicVolume := Integer(IniRead(iniFile, "Audio", "MusicVolume", "60"))
            AppState.SFXVolume := Integer(IniRead(iniFile, "Audio", "SFXVolume", "75"))
            AppState.VoiceChat := (IniRead(iniFile, "Audio", "VoiceChat", "1") == "1")
        }
    }
}
LoadSettings()

; Create standard chromeless WPF window using XAML_GUI
app := XAML_GUI("Realm Config", { Sidebar: false, BurgerMenu: false, TitleBarHeight: 40, AppIcon: false, Width: 940, Height: 650, Resize: false })

; Skip standard office style themes.ini application on load
app.SkipDefaultThemeOnLoad := true
app.tabs.Visibility("Collapsed")

; Set base main layout grid backgrounds to transparent (so our custom frame stands out)
app.main.Background("Transparent")

; ==============================================================================
; DEFINE HIGH-FIDELITY VECTOR STYLES & RESOURCE DICTIONARY
; ==============================================================================

customStyles := '
(
    <!-- Custom Styles for Military Tactical Settings UI -->
    <LinearGradientBrush x:Key="GoldMetalBrush" StartPoint="0,0" EndPoint="1,1">
        <GradientStop Color="#2C302E" Offset="0.0"/>
        <GradientStop Color="#4B5320" Offset="0.4"/>
        <GradientStop Color="#8F9E4B" Offset="0.6"/>
        <GradientStop Color="#4B5320" Offset="0.8"/>
        <GradientStop Color="#2C302E" Offset="1.0"/>
    </LinearGradientBrush>

    <DrawingBrush x:Key="HazardStripeBrush" TileMode="Tile" Viewport="0,0,16,16" ViewportUnits="Absolute">
        <DrawingBrush.Drawing>
            <DrawingGroup>
                <!-- Yellow/Orange base -->
                <GeometryDrawing Brush="#D9A000">
                    <GeometryDrawing.Geometry>
                        <RectangleGeometry Rect="0,0,16,16"/>
                    </GeometryDrawing.Geometry>
                </GeometryDrawing>
                <!-- Black diagonal stripe -->
                <GeometryDrawing Brush="#1A1C1E">
                    <GeometryDrawing.Geometry>
                        <PathGeometry Figures="M 0,16 L 8,0 L 16,0 L 8,16 Z"/>
                    </GeometryDrawing.Geometry>
                </GeometryDrawing>
            </DrawingGroup>
        </DrawingBrush.Drawing>
    </DrawingBrush>

    <SolidColorBrush x:Key="TextMain" Color="#E9ECEF" />
    <SolidColorBrush x:Key="TextSub" Color="#9E9E9E" />
    <SolidColorBrush x:Key="Accent" Color="#FF9000" />
    <SolidColorBrush x:Key="ControlBg" Color="#141618" />
    <SolidColorBrush x:Key="ControlBorder" Color="#4B5320" />
    <CornerRadius x:Key="CloseBtnRadius">0</CornerRadius>
    <CornerRadius x:Key="WindowRadius">0</CornerRadius>
    
    <!-- Themed Scrollbar Styles -->
    <Style x:Key="ThemedScrollBarThumb" TargetType="Thumb">
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Thumb">
                    <Border x:Name="border" Background="#4B5320" CornerRadius="0" Margin="1" Opacity="0.7"/>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="border" Property="Background" Value="#8F9E4B"/>
                            <Setter TargetName="border" Property="Opacity" Value="0.9"/>
                        </Trigger>
                        <Trigger Property="IsDragging" Value="True">
                            <Setter TargetName="border" Property="Background" Value="#FF9000"/>
                            <Setter TargetName="border" Property="Opacity" Value="1.0"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <Style TargetType="ScrollBar">
        <Setter Property="OverridesDefaultStyle" Value="True"/>
        <Setter Property="Background" Value="Transparent"/>
        <Setter Property="Width" Value="8"/>
        <Setter Property="Height" Value="8"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="ScrollBar">
                    <Grid Background="#101214">
                        <Track x:Name="PART_Track" IsDirectionReversed="true">
                            <Track.Thumb>
                                <Thumb Style="{StaticResource ThemedScrollBarThumb}"/>
                            </Track.Thumb>
                        </Track>
                    </Grid>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
        <Style.Triggers>
            <Trigger Property="Orientation" Value="Horizontal">
                <Setter Property="Width" Value="Auto"/>
                <Setter Property="Height" Value="8"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="ScrollBar">
                            <Grid Background="#101214">
                                <Track x:Name="PART_Track" IsDirectionReversed="false">
                                    <Track.Thumb>
                                        <Thumb Style="{StaticResource ThemedScrollBarThumb}"/>
                                    </Track.Thumb>
                                </Track>
                            </Grid>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Trigger>
        </Style.Triggers>
    </Style>

    <Style x:Key="WindowFrameStyle" TargetType="Border">
        <Setter Property="CornerRadius" Value="0"/>
        <Setter Property="BorderThickness" Value="4"/>
        <Setter Property="BorderBrush" Value="#4B5320"/>
        <Setter Property="Background" Value="#1A1C1E"/>
    </Style>
    
    <Style x:Key="CentralGlow" TargetType="Border">
        <Setter Property="IsHitTestVisible" Value="False"/>
        <Setter Property="Background">
            <Setter.Value>
                <RadialGradientBrush Center="0.5,0.5" RadiusX="0.75" RadiusY="0.75">
                    <GradientStop Color="#0F4B5320" Offset="0"/>
                    <GradientStop Color="#00000000" Offset="1"/>
                </RadialGradientBrush>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="WarmGlow" TargetType="Border">
        <Setter Property="IsHitTestVisible" Value="False"/>
        <Setter Property="Background">
            <Setter.Value>
                <RadialGradientBrush Center="0.25,0.85" RadiusX="0.65" RadiusY="0.65">
                    <GradientStop Color="#15FF9000" Offset="0"/>
                    <GradientStop Color="#00000000" Offset="1"/>
                </RadialGradientBrush>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="LightSplotch" TargetType="Border">
        <Setter Property="IsHitTestVisible" Value="False"/>
        <Setter Property="Background">
            <Setter.Value>
                <RadialGradientBrush Center="0.15,0.15" RadiusX="0.6" RadiusY="0.6">
                    <GradientStop Color="#0BFFFFFF" Offset="0"/>
                    <GradientStop Color="#00000000" Offset="1"/>
                </RadialGradientBrush>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="DarkSplotch" TargetType="Border">
        <Setter Property="IsHitTestVisible" Value="False"/>
        <Setter Property="Background">
            <Setter.Value>
                <RadialGradientBrush Center="0.85,0.85" RadiusX="0.7" RadiusY="0.7">
                    <GradientStop Color="#1A000000" Offset="0"/>
                    <GradientStop Color="#00000000" Offset="1"/>
                </RadialGradientBrush>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="GrainOverlay" TargetType="Border">
        <Setter Property="IsHitTestVisible" Value="False"/>
        <Setter Property="Background">
            <Setter.Value>
                <DrawingBrush TileMode="Tile" Viewport="0,0,4,4" ViewportUnits="Absolute">
                    <DrawingBrush.Drawing>
                        <GeometryDrawing Brush="#03FFFFFF">
                            <GeometryDrawing.Geometry>
                                <GeometryGroup>
                                    <RectangleGeometry Rect="0,0,2,2"/>
                                    <RectangleGeometry Rect="2,2,2,2"/>
                                </GeometryGroup>
                            </GeometryDrawing.Geometry>
                        </GeometryDrawing>
                    </DrawingBrush.Drawing>
                </DrawingBrush>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="StoneCard" TargetType="Border">
        <Setter Property="Background" Value="#E5181B1E"/>
        <Setter Property="BorderBrush" Value="#2E3238"/>
        <Setter Property="BorderThickness" Value="1.5"/>
        <Setter Property="CornerRadius" Value="0"/>
        <Setter Property="Padding" Value="18,15,18,15"/>
        <Setter Property="Margin" Value="0,0,0,15"/>
        <Setter Property="Effect">
            <Setter.Value>
                <DropShadowEffect Color="#000000" BlurRadius="10" ShadowDepth="4" Opacity="0.6"/>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="SectionHeader" TargetType="TextBlock">
        <Setter Property="FontFamily" Value="Impact"/>
        <Setter Property="FontWeight" Value="Normal"/>
        <Setter Property="FontSize" Value="16"/>
        <Setter Property="Foreground" Value="#FF9000"/>
        <Setter Property="Margin" Value="0,0,0,15"/>
    </Style>
    
    <Style x:Key="CustomCheckBox" TargetType="CheckBox">
        <Setter Property="Foreground" Value="#CBD5E1"/>
        <Setter Property="FontSize" Value="13"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="CheckBox">
                    <BulletDecorator Background="Transparent">
                        <BulletDecorator.Bullet>
                            <Grid Width="18" Height="18">
                                <Border x:Name="Box" Background="#141618" BorderBrush="#4B5320" BorderThickness="2" CornerRadius="0">
                                    <Grid x:Name="CheckGrid" Visibility="Collapsed">
                                        <Path Data="M 3,3 L 11,11 M 11,3 L 3,11" Stroke="#FF9000" StrokeThickness="2.5" StrokeStartLineCap="Square" StrokeEndLineCap="Square"/>
                                    </Grid>
                                </Border>
                            </Grid>
                        </BulletDecorator.Bullet>
                        <ContentPresenter Margin="8,0,0,0" VerticalAlignment="Center"/>
                    </BulletDecorator>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsChecked" Value="True">
                            <Setter TargetName="Box" Property="BorderBrush" Value="#FF9000"/>
                            <Setter TargetName="CheckGrid" Property="Visibility" Value="Visible"/>
                            <Setter TargetName="Box" Property="Effect">
                                <Setter.Value>
                                    <DropShadowEffect Color="#FF9000" BlurRadius="5" ShadowDepth="0" Opacity="0.5"/>
                                </Setter.Value>
                            </Setter>
                        </Trigger>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Box" Property="BorderBrush" Value="#8F9E4B"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="KeybindBox" TargetType="TextBox">
        <Setter Property="Background" Value="#141618"/>
        <Setter Property="Foreground" Value="#FFF"/>
        <Setter Property="BorderBrush" Value="#4B5320"/>
        <Setter Property="BorderThickness" Value="1.5"/>
        <Setter Property="HorizontalContentAlignment" Value="Center"/>
        <Setter Property="VerticalContentAlignment" Value="Center"/>
        <Setter Property="FontFamily" Value="Consolas, monospace"/>
        <Setter Property="FontWeight" Value="Bold"/>
        <Setter Property="FontSize" Value="13.5"/>
        <Setter Property="CaretBrush" Value="Transparent"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="TextBox">
                    <Border x:Name="border" CornerRadius="0" 
                            Background="{TemplateBinding Background}" 
                            BorderBrush="{TemplateBinding BorderBrush}" 
                            BorderThickness="{TemplateBinding BorderThickness}">
                        <ScrollViewer x:Name="PART_ContentHost" Focusable="false" 
                                      HorizontalScrollBarVisibility="Hidden" 
                                      VerticalScrollBarVisibility="Hidden"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsFocused" Value="True">
                            <Setter TargetName="border" Property="BorderBrush" Value="#FF9000"/>
                            <Setter TargetName="border" Property="Effect">
                                <Setter.Value>
                                    <DropShadowEffect Color="#FF9000" BlurRadius="6" ShadowDepth="0" Opacity="0.5"/>
                                </Setter.Value>
                            </Setter>
                        </Trigger>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="border" Property="BorderBrush" Value="#8F9E4B"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="InfoButton" TargetType="Button">
        <Setter Property="Width" Value="18"/>
        <Setter Property="Height" Value="18"/>
        <Setter Property="Background" Value="#25282C"/>
        <Setter Property="Foreground" Value="#8F9E4B"/>
        <Setter Property="FontFamily" Value="Impact"/>
        <Setter Property="FontWeight" Value="Normal"/>
        <Setter Property="FontSize" Value="11"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Grid>
                        <Rectangle x:Name="Bg" Fill="{TemplateBinding Background}" Stroke="#4B5320" StrokeThickness="1"/>
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,-1,0,0"/>
                    </Grid>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bg" Property="Fill" Value="#4B5320"/>
                            <Setter Property="Foreground" Value="#FF9000"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="OrnateButton" TargetType="Button">
        <Setter Property="Background" Value="#2D3238"/>
        <Setter Property="Foreground" Value="#8F9E4B"/>
        <Setter Property="BorderBrush" Value="#4B5320"/>
        <Setter Property="BorderThickness" Value="2"/>
        <Setter Property="FontFamily" Value="Impact"/>
        <Setter Property="FontWeight" Value="Normal"/>
        <Setter Property="FontSize" Value="14"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Grid>
                        <Border x:Name="Body" CornerRadius="0" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{TemplateBinding Background}"/>
                        <Border x:Name="InnerBorder" Margin="2" BorderBrush="#20FFFFFF" BorderThickness="1" IsHitTestVisible="False"/>
                        <Rectangle Width="3" Height="3" Fill="#1E2225" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="4" IsHitTestVisible="False"/>
                        <Rectangle Width="3" Height="3" Fill="#1E2225" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="4" IsHitTestVisible="False"/>
                        <Rectangle Width="3" Height="3" Fill="#1E2225" HorizontalAlignment="Left" VerticalAlignment="Bottom" Margin="4" IsHitTestVisible="False"/>
                        <Rectangle Width="3" Height="3" Fill="#1E2225" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="4" IsHitTestVisible="False"/>
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="10,6,10,6"/>
                    </Grid>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Body" Property="Background" Value="#3E444C"/>
                            <Setter Property="BorderBrush" Value="#8F9E4B"/>
                            <Setter Property="Foreground" Value="#FF9000"/>
                            <Setter TargetName="InnerBorder" Property="BorderBrush" Value="#40FF9000"/>
                        </Trigger>
                        <Trigger Property="IsPressed" Value="True">
                            <Setter TargetName="Body" Property="Background" Value="#1A1D20"/>
                            <Setter Property="BorderBrush" Value="#FF9000"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style TargetType="ComboBox">
        <Setter Property="Foreground" Value="#E9ECEF"/>
        <Setter Property="Background" Value="#141618"/>
        <Setter Property="BorderBrush" Value="#4B5320"/>
        <Setter Property="BorderThickness" Value="1.5"/>
        <Setter Property="Padding" Value="6,3,5,3"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="ComboBox">
                    <Grid>
                        <ToggleButton Name="ToggleButton" 
                                      BorderBrush="{TemplateBinding BorderBrush}" 
                                      BorderThickness="{TemplateBinding BorderThickness}" 
                                      Background="{TemplateBinding Background}" 
                                      ClickMode="Press" Focusable="false"
                                      IsChecked="{Binding Path=IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
                            <ToggleButton.Template>
                                <ControlTemplate TargetType="ToggleButton">
                                    <Border x:Name="Border" CornerRadius="0" 
                                            Background="{TemplateBinding Background}" 
                                            BorderBrush="{TemplateBinding BorderBrush}" 
                                            BorderThickness="{TemplateBinding BorderThickness}">
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*" />
                                                <ColumnDefinition Width="30" />
                                            </Grid.ColumnDefinitions>
                                            <Path x:Name="Arrow" Grid.Column="1" HorizontalAlignment="Center" VerticalAlignment="Center" 
                                                  Stroke="#8F9E4B" StrokeThickness="2" Data="M 2,4 L 6,8 L 10,4"/>
                                        </Grid>
                                    </Border>
                                    <ControlTemplate.Triggers>
                                        <Trigger Property="IsMouseOver" Value="True">
                                            <Setter TargetName="Border" Property="Background" Value="#1E2225"/>
                                            <Setter TargetName="Border" Property="BorderBrush" Value="#8F9E4B"/>
                                            <Setter TargetName="Arrow" Property="Stroke" Value="#FF9000"/>
                                        </Trigger>
                                    </ControlTemplate.Triggers>
                                </ControlTemplate>
                            </ToggleButton.Template>
                        </ToggleButton>
                        <ContentPresenter Name="ContentSite" IsHitTestVisible="False" 
                                           Content="{TemplateBinding SelectionBoxItem}"
                                           ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                           ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}"
                                           Margin="10,3,30,3" VerticalAlignment="Center" HorizontalAlignment="Left" />
                        <Popup Name="Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}" AllowsTransparency="True" Focusable="False" PopupAnimation="Slide">
                            <Grid Name="DropDown" SnapsToDevicePixels="True" MinWidth="{TemplateBinding ActualWidth}" MaxHeight="{TemplateBinding MaxDropDownHeight}">
                                <Border Name="DropDownBorder" Background="#141618" BorderBrush="#4B5320" BorderThickness="1.5" CornerRadius="0" />
                                <ScrollViewer Margin="4" SnapsToDevicePixels="True">
                                    <StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained" />
                                </ScrollViewer>
                            </Grid>
                        </Popup>
                    </Grid>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style TargetType="ComboBoxItem">
        <Setter Property="Background" Value="#141618"/>
        <Setter Property="Foreground" Value="#E9ECEF"/>
        <Setter Property="Padding" Value="8,6,8,6"/>
        <Setter Property="BorderThickness" Value="0"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="ComboBoxItem">
                    <Border x:Name="Bg" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                        <ContentPresenter/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bg" Property="Background" Value="#4B5320"/>
                            <Setter Property="Foreground" Value="#FF9000"/>
                        </Trigger>
                        <Trigger Property="IsSelected" Value="True">
                            <Setter TargetName="Bg" Property="Background" Value="#303514"/>
                            <Setter Property="Foreground" Value="#FF9000"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="GodRay1" TargetType="Path">
        <Setter Property="IsHitTestVisible" Value="False"/>
        <Setter Property="Fill">
            <Setter.Value>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#06FFFFFF" Offset="0"/>
                    <GradientStop Color="#02FFFFFF" Offset="0.4"/>
                    <GradientStop Color="#00FFFFFF" Offset="1"/>
                </LinearGradientBrush>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="GodRay2" TargetType="Path">
        <Setter Property="IsHitTestVisible" Value="False"/>
        <Setter Property="Fill">
            <Setter.Value>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#04FFFFFF" Offset="0"/>
                    <GradientStop Color="#01FFFFFF" Offset="0.5"/>
                    <GradientStop Color="#00FFFFFF" Offset="1"/>
                </LinearGradientBrush>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="RivetStyle" TargetType="Ellipse">
        <Setter Property="Width" Value="7"/>
        <Setter Property="Height" Value="7"/>
        <Setter Property="Fill">
            <Setter.Value>
                <RadialGradientBrush Center="0.3,0.3" RadiusX="0.7" RadiusY="0.7">
                    <GradientStop Color="#8E959C" Offset="0"/>
                    <GradientStop Color="#4E5358" Offset="0.6"/>
                    <GradientStop Color="#23272A" Offset="1.0"/>
                </RadialGradientBrush>
            </Setter.Value>
        </Setter>
        <Setter Property="Stroke" Value="#151719"/>
        <Setter Property="StrokeThickness" Value="1"/>
        <Setter Property="Effect">
            <Setter.Value>
                <DropShadowEffect Color="#000" BlurRadius="2" ShadowDepth="1" Opacity="0.8"/>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="BracketStyle" TargetType="Path">
        <Setter Property="Fill" Value="#34383C"/>
        <Setter Property="Stroke" Value="#4B5320"/>
        <Setter Property="StrokeThickness" Value="1.5"/>
        <Setter Property="Effect">
            <Setter.Value>
                <DropShadowEffect Color="#000" BlurRadius="5" ShadowDepth="2" Opacity="0.8"/>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="GoldSlider" TargetType="Slider">
        <Setter Property="Background" Value="#141618"/>
        <Setter Property="BorderBrush" Value="#4B5320"/>
        <Setter Property="BorderThickness" Value="1"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Slider">
                    <Grid Margin="0,2">
                        <Border x:Name="TrackBackground" Height="6" CornerRadius="0" Background="#141618" BorderBrush="#4B5320" BorderThickness="1.5"/>
                        <Track x:Name="PART_Track">
                            <Track.Thumb>
                                <Thumb Width="12" Height="18" Cursor="Hand">
                                    <Thumb.Template>
                                        <ControlTemplate TargetType="Thumb">
                                            <Grid>
                                                <Rectangle Fill="#2E3238" Stroke="#4B5320" StrokeThickness="1"/>
                                                <Rectangle Width="2" Height="10" Fill="#FF9000" HorizontalAlignment="Center"/>
                                            </Grid>
                                        </ControlTemplate>
                                    </Thumb.Template>
                                </Thumb>
                            </Track.Thumb>
                        </Track>
                    </Grid>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>

    <Style x:Key="LaunchButton" TargetType="Button">
        <Setter Property="Background" Value="#A93226"/>
        <Setter Property="Foreground" Value="#FFF"/>
        <Setter Property="BorderBrush" Value="#E74C3C"/>
        <Setter Property="BorderThickness" Value="2"/>
        <Setter Property="FontFamily" Value="Impact"/>
        <Setter Property="FontWeight" Value="Normal"/>
        <Setter Property="FontSize" Value="16"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Grid>
                        <!-- Underlay/glow -->
                        <Border x:Name="Glow" Background="Transparent" CornerRadius="0" Margin="-2">
                            <Border.Effect>
                                <DropShadowEffect Color="#FF3333" BlurRadius="0" ShadowDepth="0" Opacity="0"/>
                            </Border.Effect>
                        </Border>
                        
                        <!-- Hazard Stripe Sides -->
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="20"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="20"/>
                            </Grid.ColumnDefinitions>
                            
                            <!-- Left Stripe -->
                            <Border Grid.Column="0" Background="{StaticResource HazardStripeBrush}" BorderBrush="#4B5320" BorderThickness="1.5,1.5,0,1.5"/>
                            
                            <!-- Main Button Area -->
                            <Border x:Name="Body" Grid.Column="1" BorderBrush="#4B5320" BorderThickness="1.5" Background="{TemplateBinding Background}">
                                <Grid>
                                    <Border x:Name="InnerGlow" BorderBrush="#30FFFFFF" BorderThickness="1" Margin="1"/>
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="10,6"/>
                                </Grid>
                            </Border>
                            
                            <!-- Right Stripe -->
                            <Border Grid.Column="2" Background="{StaticResource HazardStripeBrush}" BorderBrush="#4B5320" BorderThickness="0,1.5,1.5,1.5"/>
                        </Grid>
                        
                        <!-- Tactical rivets on main body corners -->
                        <Rectangle Width="3" Height="3" Fill="#111" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="23,4,0,0"/>
                        <Rectangle Width="3" Height="3" Fill="#111" HorizontalAlignment="Right" VerticalAlignment="Top" Margin="0,4,23,0"/>
                        <Rectangle Width="3" Height="3" Fill="#111" HorizontalAlignment="Left" VerticalAlignment="Bottom" Margin="23,0,0,4"/>
                        <Rectangle Width="3" Height="3" Fill="#111" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,23,4"/>
                    </Grid>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Body" Property="Background" Value="#C0392B"/>
                            <Setter TargetName="Body" Property="BorderBrush" Value="#FF9000"/>
                            <Setter Property="Foreground" Value="#FFF"/>
                            <Setter TargetName="Glow" Property="Effect">
                                <Setter.Value>
                                    <DropShadowEffect Color="#FF3333" BlurRadius="12" ShadowDepth="0" Opacity="0.7"/>
                                </Setter.Value>
                            </Setter>
                        </Trigger>
                        <Trigger Property="IsPressed" Value="True">
                            <Setter TargetName="Body" Property="Background" Value="#78281F"/>
                            <Setter TargetName="Body" Property="BorderBrush" Value="#FF3333"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
)'

app.main.InjectResources(customStyles)

; Find and restyle default window close/minimize buttons to thematic rectangles
btnClose := app.X.Find("BtnClose")
if btnClose {
    btnClose._Children := []
    btnClose._Props["Width"] := "22"
    btnClose._Props["Height"] := "22"
    btnClose._Props["VerticalAlignment"] := "Top"
    btnClose._Props["Margin"] := "0,9,75,0"
    btnClose.InjectResources('
    (
        <Style TargetType="Button">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Rectangle x:Name="Box" Stroke="#4B5320" StrokeThickness="1.5" Fill="#141618"/>
                            <Rectangle x:Name="Gem" Margin="3" Fill="#C0392B"/>
                            <Path Data="M 0,0 L 6,6 M 6,0 L 0,6" Width="6" Height="6" Stretch="Uniform" Stroke="#FFF" StrokeThickness="2" HorizontalAlignment="Center" VerticalAlignment="Center" IsHitTestVisible="False"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Gem" Property="Fill" Value="#E74C3C"/>
                                <Setter TargetName="Box" Property="Stroke" Value="#FF9000"/>
                                <Setter TargetName="Box" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="#FF9000" BlurRadius="6" ShadowDepth="0" Opacity="0.8"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Gem" Property="Fill" Value="#962D22"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    )')
}

btnMin := app.X.Find("BtnMinimize")
if btnMin {
    btnMin._Children := []
    btnMin._Props["Width"] := "22"
    btnMin._Props["Height"] := "22"
    btnMin._Props["VerticalAlignment"] := "Top"
    btnMin._Props["Margin"] := "0,9,10,0"
    btnMin.InjectResources('
    (
        <Style TargetType="Button">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Rectangle x:Name="Box" Stroke="#4B5320" StrokeThickness="1.5" Fill="#141618"/>
                            <Rectangle x:Name="Gem" Margin="3" Fill="#2C3E50"/>
                            <Path Data="M 0,0 L 6,0" Width="6" Height="2" Stretch="Uniform" Stroke="#FFF" StrokeThickness="2" HorizontalAlignment="Center" VerticalAlignment="Center" IsHitTestVisible="False"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Gem" Property="Fill" Value="#34495E"/>
                                <Setter TargetName="Box" Property="Stroke" Value="#FF9000"/>
                                <Setter TargetName="Box" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="#FF9000" BlurRadius="6" ShadowDepth="0" Opacity="0.8"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Gem" Property="Fill" Value="#1B2631"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    )')
}

; ==============================================================================
; PRE-COMPILE INTERPOLATION: CUSTOM TITLE TEXT SPAN WITH COLORS
; ==============================================================================

titleBlock := app.X.Find("AppTitle")
if (titleBlock) {
    titleBlock.Visibility("Collapsed")
}

; ==============================================================================
; PROCEDURAL GRANITE AND GOLD FRAME BACKGROUND LAYERS
; ==============================================================================

; Double-border beveled stone outer frame
windowFrame := app.main.Add("Border").Grid_Row(0).Grid_RowSpan(3).Name("WindowFrame").Style("{StaticResource WindowFrameStyle}")
windowFrame.SetProp("Panel.ZIndex", "-1")

; Inner accent border for double-gold pinstripe
innerGoldBdr := windowFrame.Add("Border").Margin("2").BorderThickness("1").BorderBrush("#254B5320").CornerRadius("0")

; Inner background grid (canvas for atmospheric glow + vector veins)
bgGrid := innerGoldBdr.Add("Grid")
bgGrid.Add("Border").Style("{StaticResource CentralGlow}")
bgGrid.Add("Border").Style("{StaticResource WarmGlow}")

; Add large soft radial splotches for organic rock tone variations
bgGrid.Add("Border").Style("{StaticResource LightSplotch}")
bgGrid.Add("Border").Style("{StaticResource DarkSplotch}")

; Grain overlay for tactile rock pores
bgGrid.Add("Border").Style("{StaticResource GrainOverlay}")

; Volumetric light rays (God Rays)
bgGrid.Add("Path").Data("M 50,-50 L 150,-50 L 800,650 L 650,650 Z").Style("{StaticResource GodRay1}")
bgGrid.Add("Path").Data("M 200,-50 L 380,-50 L 990,550 L 780,600 Z").Style("{StaticResource GodRay2}")
bgGrid.Add("Path").Data("M -50,50 L -50,180 L 580,650 L 420,650 Z").Style("{StaticResource GodRay2}")

; Inlay Border Path (octagonal chamfered)
bgGrid.Add("Path").Data("M 30,16 L 455,16 L 470,31 L 485,16 L 910,16 L 924,30 L 924,285 L 909,300 L 924,315 L 924,570 L 910,584 L 485,584 L 470,569 L 455,584 L 30,584 L 16,570 L 16,315 L 31,300 L 16,285 L 16,30 Z").Stroke("#204B5320").StrokeThickness("1.0").SetProp("IsHitTestVisible", "False").Opacity("0.4")

; Tactical radar/HUD targeting circles in bottom-left background area
bgCircleLeft := bgGrid.Add("Grid").Width(340).Height(340).HorizontalAlignment("Left").VerticalAlignment("Bottom").Margin("50,0,0,50")
bgCircleLeft.SetProp("IsHitTestVisible", "False")
bgCircleLeft.Add("Ellipse").Stroke("#108F9E4B").StrokeThickness("1.5").SetProp("StrokeDashArray", "8 6")
bgCircleLeft.Add("Ellipse").Margin("15").Stroke("#0A4B5320").StrokeThickness("1")
bgCircleLeft.Add("Ellipse").Margin("25").Stroke("#10FF9000").StrokeThickness("1.5").SetProp("StrokeDashArray", "2 4")
bgCircleLeft.Add("Ellipse").Margin("45").Stroke("#0A4B5320").StrokeThickness("1")
bgCircleLeft.Add("Path").Data("M 170,15 L 170,325 M 15,170 L 325,170").Stroke("#108F9E4B").StrokeThickness("1")
bgCircleLeft.Add("Path").Data("M 58,58 L 282,282 M 58,282 L 282,58").Stroke("#08FF9000").StrokeThickness("1")
bgCircleLeft.Add("Ellipse").Margin("136").Fill("#05FF9000")
bgCircleLeft.Add("Polygon").SetProp("Points", "170,150 185,170 170,190 155,170").Fill("#15FF9000")

; Secondary larger tactical targeting HUD sweeps in upper-right
bgCircleRight := bgGrid.Add("Grid").Width(460).Height(460).HorizontalAlignment("Right").VerticalAlignment("Top").Margin("0,20,-120,0")
bgCircleRight.SetProp("IsHitTestVisible", "False")
bgCircleRight.Add("Ellipse").Stroke("#10FF9000").StrokeThickness("1.5").SetProp("StrokeDashArray", "10 8")
bgCircleRight.Add("Ellipse").Margin("25").Stroke("#0A4B5320").StrokeThickness("1")
bgCircleRight.Add("Ellipse").Margin("50").Stroke("#088F9E4B").StrokeThickness("1").SetProp("StrokeDashArray", "4 4")
bgCircleRight.Add("Path").Data("M 230,10 L 230,450 M 10,230 L 450,230").Stroke("#088F9E4B").StrokeThickness("1")
bgCircleRight.Add("Path").Data("M 77,77 L 383,383 M 77,383 L 383,77").Stroke("#08FF9000").StrokeThickness("1")
bgCircleRight.Add("Polygon").SetProp("Points", "230,25 435,230 230,435 25,230").Stroke("#08FF9000").StrokeThickness("1")
bgCircleRight.Add("Polygon").SetProp("Points", "85,85 375,85 375,375 85,375").Stroke("#084B5320").StrokeThickness("1")

; Ornate Heavy Steel Window Corner Brackets & Bolt Rivets
; Top-Left Corner
bgGrid.Add("Path").Data("M 0,0 L 50,0 L 50,10 L 40,10 L 40,16 C 30,16 16,30 16,40 L 10,40 L 10,50 L 0,50 Z").Style("{StaticResource BracketStyle}").HorizontalAlignment("Left").VerticalAlignment("Top").Margin("4,4,0,0").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Left").VerticalAlignment("Top").Margin("29,7,0,0").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Left").VerticalAlignment("Top").Margin("7,29,0,0").SetProp("IsHitTestVisible", "False")

; Top-Right Corner
bgGrid.Add("Path").Data("M 50,0 L 0,0 L 0,10 L 10,10 L 10,16 C 20,16 34,30 34,40 L 40,40 L 40,50 L 50,50 Z").Style("{StaticResource BracketStyle}").HorizontalAlignment("Right").VerticalAlignment("Top").Margin("0,4,4,0").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Right").VerticalAlignment("Top").Margin("0,7,29,0").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Right").VerticalAlignment("Top").Margin("0,29,7,0").SetProp("IsHitTestVisible", "False")

; Bottom-Left Corner
bgGrid.Add("Path").Data("M 0,50 L 50,50 L 50,40 L 40,40 L 40,34 C 30,34 16,20 16,10 L 10,10 L 10,0 L 0,0 Z").Style("{StaticResource BracketStyle}").HorizontalAlignment("Left").VerticalAlignment("Bottom").Margin("4,0,0,4").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Left").VerticalAlignment("Bottom").Margin("29,0,0,7").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Left").VerticalAlignment("Bottom").Margin("7,0,0,29").SetProp("IsHitTestVisible", "False")

; Bottom-Right Corner
bgGrid.Add("Path").Data("M 50,50 L 0,50 L 0,40 L 10,40 L 10,34 C 20,34 34,20 34,10 L 40,10 L 40,0 L 50,0 Z").Style("{StaticResource BracketStyle}").HorizontalAlignment("Right").VerticalAlignment("Bottom").Margin("0,0,4,4").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Right").VerticalAlignment("Bottom").Margin("0,0,29,7").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Right").VerticalAlignment("Bottom").Margin("0,0,7,29").SetProp("IsHitTestVisible", "False")

; Distressed Armor Plate Scratch Highlights (translucent white highlight + shadow)
; Vein 1
bgGrid.Add("Path").Data("M -50,120 C 120,90 180,240 330,190 C 420,160 480,300 620,230 C 720,210 820,330 990,290 M 330,190 C 290,270 250,320 220,400 M 620,230 C 650,130 690,90 720,20").Stroke("#35000000").StrokeThickness("1.6").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Path").Data("M -50,120 C 120,90 180,240 330,190 C 420,160 480,300 620,230 C 720,210 820,330 990,290 M 330,190 C 290,270 250,320 220,400 M 620,230 C 650,130 690,90 720,20").Stroke("#20FFFFFF").StrokeThickness("0.8").Margin("1,1,0,0").SetProp("IsHitTestVisible", "False")

; Vein 2
bgGrid.Add("Path").Data("M 280,-50 C 240,160 350,270 300,420 C 270,530 380,580 320,650 M 300,420 C 210,440 160,500 90,540 M 320,650 C 340,560 410,520 480,480").Stroke("#30000000").StrokeThickness("1.4").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Path").Data("M 280,-50 C 240,160 350,270 300,420 C 270,530 380,580 320,650 M 300,420 C 210,440 160,500 90,540 M 320,650 C 340,560 410,520 480,480").Stroke("#1AFFFFFF").StrokeThickness("0.7").Margin("1,1,0,0").SetProp("IsHitTestVisible", "False")

; Vein 3
bgGrid.Add("Path").Data("M 990,80 C 840,130 790,50 630,130 C 520,170 420,85 320,160 C 190,230 130,190 -50,260 M 630,130 C 570,240 540,340 500,480").Stroke("#32000000").StrokeThickness("1.5").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Path").Data("M 990,80 C 840,130 790,50 630,130 C 520,170 420,85 320,160 C 190,230 130,190 -50,260 M 630,130 C 570,240 540,340 500,480").Stroke("#1CFFFFFF").StrokeThickness("0.8").Margin("1,1,0,0").SetProp("IsHitTestVisible", "False")

; Armored plate seam
bgGrid.Add("Path").Data("M 150,-50 C 180,80 120,180 250,280 C 300,320 220,480 350,650").Stroke("#30000000").StrokeThickness("1.5").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Path").Data("M 150,-50 C 180,80 120,180 250,280 C 300,320 220,480 350,650").Stroke("#1CFFFFFF").StrokeThickness("0.8").Margin("1,1,0,0").SetProp("IsHitTestVisible", "False")

; Generate clustered background scratches/fractures (120 scratches for clean military detail)
GenerateBackgroundScratches(bgGrid, 120)

; Tactical Stencil Labels in Background
bgGrid.Add("TextBlock").Text("SYS CONFIG // UNIT 04-A").FontFamily("Trebuchet MS").FontSize(10).FontWeight("Bold").Foreground("#25FFFFFF").Margin("70,45,0,0").HorizontalAlignment("Left").VerticalAlignment("Top").SetProp("IsHitTestVisible", "False")
bgGrid.Add("TextBlock").Text("SECURE DATA LINK [OK]").FontFamily("Trebuchet MS").FontSize(10).FontWeight("Bold").Foreground("#25FFFFFF").Margin("70,0,0,50").HorizontalAlignment("Left").VerticalAlignment("Bottom").SetProp("IsHitTestVisible", "False")

; Stenciled hazard stripe separator bar below the title bar
app.main.Add("Rectangle").Grid_Row(0).VerticalAlignment("Bottom").Height("5").Fill("{StaticResource HazardStripeBrush}").Margin("6,0,6,0").SetProp("IsHitTestVisible", "False")

; ==============================================================================
; CONTENT AREAS AND COLUMN PRE-SETTING
; ==============================================================================

contentGrid := app.main.Add("Grid").Grid_Row(1).Margin("25,10,25,10")
contentGrid.Cols("190", "20", "*")
contentGrid.Rows("Auto", "*", "Auto", "Auto")

; Tactical title block with Impact font
contentGrid.Add("TextBlock").Grid_Row(0).Grid_Column(0).Grid_ColumnSpan(3).Text("TACTICAL SYSTEM CONFIG").FontFamily("Impact").FontSize(22).FontWeight("Normal").Foreground("#FF9000").HorizontalAlignment("Center").Margin("0,10,0,15")

; Sidebar StackPanel on Column 0, Row 1
sidebarSp := contentGrid.Add("StackPanel").Grid_Column(0).Grid_Row(1)

; Categories stack
AddSidebarButton(sp, name, label, isFirst := false) {
    btn := sp.Add("Button").Name("BtnNav" name).Style("{StaticResource OrnateButton}").Height(38).Margin("0,0,0,10")
    btnGrid := btn.Add("Grid")
    btnGrid.Cols("Auto", "*")
    
    indText := isFirst ? "▶" : "  "
    indColor := isFirst ? "#FF9000" : "#8A94A6"
    btnGrid.Add("TextBlock").Name("Ind" name).Text(indText).Foreground(indColor).FontWeight("Bold").Margin("0,0,8,0").VerticalAlignment("Center").Grid_Column(0)
    btnGrid.Add("TextBlock").Text(label).VerticalAlignment("Center").Grid_Column(1)
}

AddSidebarButton(sidebarSp, "Gameplay", "Gameplay", true)
AddSidebarButton(sidebarSp, "Controls", "Controls")
AddSidebarButton(sidebarSp, "Graphics", "Video & Display")
AddSidebarButton(sidebarSp, "Audio", "Audio & Sound")

; Right Column: Content grid that holds all overlaid StackPanels
rightCol := contentGrid.Add("Grid").Grid_Column(2).Grid_Row(1)
rightCol.Add("Grid.LayoutTransform").Add("ScaleTransform").ScaleX("1.2").ScaleY("1.2")

scrollCol := rightCol.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled")
scrollCol.SetProp("Padding", "0,0,10,0")
panelContainer := scrollCol.Add("Grid")

; Gameplay Panel
panelGameplay := panelContainer.Add("StackPanel").Name("PanelGameplay").Visibility("Visible")

; Controls Panel
panelControls := panelContainer.Add("StackPanel").Name("PanelControls").Visibility("Collapsed")

; Graphics Panel
panelGraphics := panelContainer.Add("StackPanel").Name("PanelGraphics").Visibility("Collapsed")

; Audio Panel
panelAudio := panelContainer.Add("StackPanel").Name("PanelAudio").Visibility("Collapsed")

; ==============================================================================
; BUILD SECTIONS & CONTROL ROWS
; ==============================================================================

; Helper to build section boxes with optional info buttons in headers
CreateSectionBox(parent, title, infoName := "", infoDesc := "") {
    box := parent.Add("Border").Style("{StaticResource StoneCard}")
    boxSp := box.Add("StackPanel")

    if (infoName != "") {
        headerGrid := boxSp.Add("Grid").Margin("0,0,0,15")
        headerGrid.Cols("*", "Auto")
        headerGrid.Add("TextBlock").Text(title).Style("{StaticResource SectionHeader}").Grid_Column(0).Margin("0")
        headerGrid.Add("Button").Name(infoName).Style("{StaticResource InfoButton}").Content("i").Grid_Column(1).VerticalAlignment("Center")

        infoDescriptions[infoName] := { Title: title, Desc: infoDesc }
    } else {
        boxSp.Add("TextBlock").Text(title).Style("{StaticResource SectionHeader}")
    }
    return boxSp
}

AddCheckboxRow(parent, name, label, isCheckedVal, infoName, infoDesc) {
    rowGrid := parent.Add("Grid").Margin("0,5,0,5")
    rowGrid.Cols("*", "Auto")

    lbl := rowGrid.Add("TextBlock").Text(label).FontSize(13).VerticalAlignment("Center").Grid_Column(0)
    lbl.InjectResources('<Style TargetType="TextBlock"><Setter Property="Foreground" Value="#CBD5E1"/><Style.Triggers><DataTrigger Binding="{Binding IsChecked, ElementName=' name '}" Value="True"><Setter Property="Foreground" Value="#F0F9FF"/><Setter Property="Effect"><Setter.Value><DropShadowEffect Color="#FF9000" BlurRadius="6" ShadowDepth="0" Opacity="0.9"/></Setter.Value></Setter></DataTrigger></Style.Triggers></Style>')

    rightSp := rowGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(1).VerticalAlignment("Center")
    rightSp.Add("CheckBox").Name(name).Style("{StaticResource CustomCheckBox}").IsChecked(isCheckedVal ? "True" : "False").Cursor("Hand").Margin("0,0,8,0")
    rightSp.Add("Button").Name(infoName).Style("{StaticResource InfoButton}").Content("i").VerticalAlignment("Center")

    infoDescriptions[infoName] := { Title: label, Desc: infoDesc }
}

AddKeybindRow(parent, name, label, keyVal, infoName := "", infoDesc := "") {
    rowGrid := parent.Add("Grid").Margin("0,5,0,5")
    rowGrid.Cols("*", "Auto")
    rowGrid.Add("TextBlock").Text(label).Foreground("#CBD5E1").FontSize(13).VerticalAlignment("Center").Grid_Column(0)

    rightSp := rowGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(1).VerticalAlignment("Center")
    rightSp.Add("TextBox").Name(name).Style("{StaticResource KeybindBox}").Width(55).Height(26).Text(keyVal).Margin("0,0,8,0").IsReadOnly("True").Cursor("Hand")

    if (infoName != "") {
        rightSp.Add("Button").Name(infoName).Style("{StaticResource InfoButton}").Content("i").VerticalAlignment("Center")
        infoDescriptions[infoName] := { Title: label, Desc: infoDesc }
    } else {
        ; Transparent spacer placeholder to keep keybind boxes aligned cleanly
        rightSp.Add("Border").Width(18).Height(18)
    }
}

AddAutoRunRow(parent) {
    rowGrid := parent.Add("Grid").Margin("0,5,0,5")
    rowGrid.Cols("*", "Auto")

    lbl := rowGrid.Add("TextBlock").Text("Auto-Run Shortcut").FontSize(13).VerticalAlignment("Center").Grid_Column(0)
    lbl.InjectResources('<Style TargetType="TextBlock"><Setter Property="Foreground" Value="#CBD5E1"/><Style.Triggers><DataTrigger Binding="{Binding IsChecked, ElementName=TglAutoRun}" Value="True"><Setter Property="Foreground" Value="#F0F9FF"/><Setter Property="Effect"><Setter.Value><DropShadowEffect Color="#FF9000" BlurRadius="6" ShadowDepth="0" Opacity="0.9"/></Setter.Value></Setter></DataTrigger></Style.Triggers></Style>')

    rightSp := rowGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(1).VerticalAlignment("Center")

    setupBtn := rightSp.Add("Button").Name("BtnSetupShortcut").Content("Setup").Background("Transparent").Foreground("#FF9000").BorderThickness("0").Cursor("Hand").FontWeight("Bold").Margin("0,0,8,0").VerticalAlignment("Center")
    setupBtn.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><TextBlock Text="{TemplateBinding Content}" TextDecorations="Underline"/></ControlTemplate></Setter.Value></Setter></Style>')

    rightSp.Add("CheckBox").Name("TglAutoRun").Style("{StaticResource CustomCheckBox}").IsChecked(AppState.AutoRunEnabled ? "True" : "False").Cursor("Hand").Margin("0,0,8,0").VerticalAlignment("Center")
    rightSp.Add("Button").Name("InfoAutoRun").Style("{StaticResource InfoButton}").Content("i").VerticalAlignment("Center")

    infoDescriptions["InfoAutoRun"] := { Title: "Auto-Run Shortcut", Desc: "Allows binding a dedicated key to automatically run or perform macro actions." }
}

AddDropdownRow(parent, name, label, selectedVal, items, infoName := "", infoDesc := "") {
    rowGrid := parent.Add("Grid").Margin("0,5,0,5")
    rowGrid.Cols("*", "Auto")
    rowGrid.Add("TextBlock").Text(label).Foreground("#CBD5E1").FontSize(13).VerticalAlignment("Center").Grid_Column(0)

    rightSp := rowGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(1).VerticalAlignment("Center")
    combo := rightSp.Add("ComboBox").Name(name).Width(150).Height(28).Margin("0,0,8,0")

    selectedIdx := 0
    for i, item in items {
        combo.Add("ComboBoxItem").Content(item)
        if (item == selectedVal)
            selectedIdx := i - 1
    }
    combo.SelectedIndex(String(selectedIdx))

    if (infoName != "") {
        rightSp.Add("Button").Name(infoName).Style("{StaticResource InfoButton}").Content("i").VerticalAlignment("Center")
        infoDescriptions[infoName] := { Title: label, Desc: infoDesc }
    } else {
        rightSp.Add("Border").Width(18).Height(18)
    }
}

AddSliderRow(parent, name, label, minVal, maxVal, currentVal, suffix := "", infoName := "", infoDesc := "") {
    rowGrid := parent.Add("Grid").Margin("0,5,0,5")
    rowGrid.Cols("*", "Auto")

    leftSp := rowGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(0).VerticalAlignment("Center")
    leftSp.Add("TextBlock").Text(label).Foreground("#CBD5E1").FontSize(13).VerticalAlignment("Center").Margin("0,0,10,0")
    leftSp.Add("TextBlock").Name(name "Val").Text(String(currentVal) suffix).Foreground("#FF9000").FontSize(13).FontWeight("Bold").VerticalAlignment("Center")

    rightSp := rowGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(1).VerticalAlignment("Center")
    rightSp.Add("Slider").Name(name).Style("{StaticResource GoldSlider}").Width(150).Height(30).Minimum(minVal).Maximum(maxVal).Value(String(currentVal)).Margin("0,0,8,0")

    if (infoName != "") {
        rightSp.Add("Button").Name(infoName).Style("{StaticResource InfoButton}").Content("i").VerticalAlignment("Center")
        infoDescriptions[infoName] := { Title: label, Desc: infoDesc }
    } else {
        rightSp.Add("Border").Width(18).Height(18)
    }
}

; --- POPULATE GAMEPLAY PANEL ---
gameplaySp := CreateSectionBox(panelGameplay, "GAMEPLAY CONFIGURATION")
AddDropdownRow(gameplaySp, "ComboDifficulty", "Campaign Difficulty Level", AppState.Difficulty, ["Story Mode", "Normal", "Hardcore", "Legendary"], "InfoDifficulty", "Adjusts enemy AI strength, combat modifiers, and health scaling.")
AddSliderRow(gameplaySp, "SliderSens", "Mouse Look Sensitivity", 1.0, 10.0, AppState.MouseSensitivity, "", "InfoSens", "Adjusts the speed at which the camera rotates when dragging the mouse.")
AddCheckboxRow(gameplaySp, "TglRightMouse", "Mouselook with Right Mouse Button", AppState.RightMouseLook, "InfoRightMouse", "Enables camera control when holding down the Right Mouse Button.")
AddCheckboxRow(gameplaySp, "TglMoveLook", "Mouselook while Moving Forward/Backwards", AppState.MoveLook, "InfoMoveLook", "Allows adjusting orientation with mouse while moving.")
AddCheckboxRow(gameplaySp, "TglInvertY", "Invert Mouse Y-Axis", AppState.InvertY, "InfoInvertY", "Inverts the pitch vertical camera axis for flight or space preferences.")

; --- POPULATE CONTROLS PANEL ---
specialSp := CreateSectionBox(panelControls, "SPECIAL KEY ASSIGNMENTS")
AddKeybindRow(specialSp, "KeyVanityCamera", "Orbit Camera", AppState.VanityKey, "InfoVanityCamera", "Switches the viewport to a dramatic orbiting angle.")
AddKeybindRow(specialSp, "KeyCombatArt", "Ability Key", AppState.CombatKey, "InfoCombatKey", "Executes the selected action or ability.")
AddAutoRunRow(specialSp)

movementSp := CreateSectionBox(panelControls, "MOVEMENT ACTIONS", "InfoMovementKeys", "Configure the default keyboard movements for camera panning, movement directions, and looking offsets.")
movementSp.Add("TextBlock").Text("Make sure these are the same as your in-game controls!").Foreground("#8A94A6").FontSize(11).FontStyle("Italic").Margin("0,0,0,8")

keyGrid := movementSp.Add("UniformGrid").SetProp("Columns", "2")
AddKeybindRow(keyGrid, "KeyForward", "Forward", AppState.Forward)
AddKeybindRow(keyGrid, "KeyBackwards", "Backwards", AppState.Backwards)
AddKeybindRow(keyGrid, "KeyLookLeft", "Look Left", AppState.LookLeft)
AddKeybindRow(keyGrid, "KeyLookRight", "Look Right", AppState.LookRight)
AddKeybindRow(keyGrid, "KeyMoveLeft", "Move Left", AppState.MoveLeft)
AddKeybindRow(keyGrid, "KeyMoveRight", "Move Right", AppState.MoveRight)

; --- POPULATE GRAPHICS PANEL ---
displaySp := CreateSectionBox(panelGraphics, "VIDEO & DISPLAY SETTINGS")
AddDropdownRow(displaySp, "ComboGraphics", "Display Quality Preset", AppState.GraphicQuality, ["Low Performance", "Medium Quality", "High Fidelity", "Ultra / Cinematic"], "InfoGraphics", "Selects the graphics rendering fidelity preset. Higher presets enable better shadows and texture resolution.")
AddDropdownRow(displaySp, "ComboResolution", "Screen Resolution", AppState.Resolution, ["1280x720", "1920x1080", "2560x1440", "3840x2160"], "InfoResolution", "Sets the horizontal and vertical pixel density for rendering.")
AddSliderRow(displaySp, "SliderMaxFPS", "Maximum FPS Limit", 30, 300, AppState.MaxFPS, " FPS", "InfoMaxFPS", "Caps the rendering frame rate to reduce GPU stress and temperature.")
AddCheckboxRow(displaySp, "TglVSync", "Enable Vertical Sync (V-Sync)", AppState.VSync, "InfoVSync", "Synchronizes frame rate with monitor refresh rate to prevent tearing.")
AddCheckboxRow(displaySp, "TglRayTracing", "Enable Ray Tracing Shadows", AppState.RayTracing, "InfoRayTracing", "Enables hardware-accelerated realistic shadow rendering and lighting.")

; --- POPULATE AUDIO PANEL ---
audioSp := CreateSectionBox(panelAudio, "AUDIO & VOLUME")
AddSliderRow(audioSp, "SliderMasterVol", "Master Volume Level", 0, 100, AppState.MasterVolume, "%", "InfoMasterVol", "Main volume scaling for all game audio channels.")
AddSliderRow(audioSp, "SliderMusicVol", "Background Music Volume", 0, 100, AppState.MusicVolume, "%", "InfoMusicVol", "Volume level for ambient music and cinematic scores.")
AddSliderRow(audioSp, "SliderSFXVol", "Sound Effects (SFX) Volume", 0, 100, AppState.SFXVolume, "%", "InfoSFXVol", "Volume level for player actions, spells, and environmental sounds.")
AddCheckboxRow(audioSp, "TglVoiceChat", "Enable Positional Voice Chat", AppState.VoiceChat, "InfoVoiceChat", "Enables proximity-based voice communications with team members.")

; ==============================================================================
; ORNATE SAVE & RELOAD BUTTON
; ==============================================================================

btnBorder := contentGrid.Add("Border").Grid_Row(2).Grid_Column(0).Grid_ColumnSpan(3).HorizontalAlignment("Center").Margin("0,10,0,15")
saveBtn := btnBorder.Add("Button").Name("BtnSaveReload").Content("SAVE & LAUNCH SYSTEM").Style("{StaticResource LaunchButton}").Width(280).Height(45)

; ==============================================================================
; FOOTER NAVIGATION LINKS
; ==============================================================================

footerSp := contentGrid.Add("StackPanel").Grid_Row(3).Grid_Column(0).Grid_ColumnSpan(3)
footerSp.Orientation("Horizontal").HorizontalAlignment("Center").Margin("0,10,0,0")

AddFooterLink(sp, name, iconChar, text) {
    linkBtn := sp.Add("Button").Name(name).Background("Transparent").BorderThickness("0").Cursor("Hand").Margin("15,0,15,0")
    linkBtn.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Background="{TemplateBinding Background}"><ContentPresenter/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Opacity" Value="0.85"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>')

    btnGrid := linkBtn.Add("Grid")
    btnGrid.Cols("Auto", "*")

    iconColor := "#FF9000"
    if (InStr(name, "Nexus"))
        iconColor := "#FF7A00"
    else if (InStr(name, "Github"))
        iconColor := "#CBD5E1"
    else if (InStr(name, "About"))
        iconColor := "#FF4D4D"

    btnGrid.Add("TextBlock").Text(iconChar).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(14).Foreground(iconColor).VerticalAlignment("Center").Grid_Column(0).Margin("0,0,6,0")
    btnGrid.Add("TextBlock").Text(text).Foreground("#CBD5E1").FontSize(12).VerticalAlignment("Center").Grid_Column(1)
}

AddFooterLink(footerSp, "LinkNexus", Chr(0xE734), "Mod page on NexusMods")
AddFooterLink(footerSp, "LinkGithub", Chr(0xE7C3), "Open Source on Github")
AddFooterLink(footerSp, "LinkAbout", Chr(0xE7E7), "About")

; ==============================================================================
; COMPCOMPILE AND COMPONENT BINDING
; ==============================================================================

ui := app.Compile()

; Register keybind textboxes as hotkey capture boxes in XAML_GUI
ValidateKeybinds() {
    bindNames := [
        "KeyVanityCamera", "KeyCombatArt", "KeyLookLeft", "KeyLookRight",
        "KeyForward", "KeyBackwards", "KeyMoveLeft", "KeyMoveRight"
    ]

    vals := ui.Query(bindNames*)
    valueCount := Map()
    for name in bindNames {
        val := vals.Has(name) ? vals[name] : ""
        if (val != "") {
            if (!valueCount.Has(val))
                valueCount[val] := []
            valueCount[val].Push(name)
        }
    }

    ; Reset all borders
    for name in bindNames {
        ui.Update(name, "BorderBrush", "#2A2C30")
    }

    hasClash := false
    for val, names in valueCount {
        if (names.Length > 1) {
            hasClash := true
            for name in names {
                ui.Update(name, "BorderBrush", "#FF453A")
            }
        }
    }
    return hasClash
}

OnKeybindChange(name, newBind) {
    ValidateKeybinds()
}

; Register keybind textboxes as hotkey capture boxes in XAML_GUI
app.RegisterHotKeyChange(app.X.Find("KeyVanityCamera"), (val) => OnKeybindChange("KeyVanityCamera", val), true)
app.RegisterHotKeyChange(app.X.Find("KeyCombatArt"), (val) => OnKeybindChange("KeyCombatArt", val), true)
app.RegisterHotKeyChange(app.X.Find("KeyLookLeft"), (val) => OnKeybindChange("KeyLookLeft", val), true)
app.RegisterHotKeyChange(app.X.Find("KeyLookRight"), (val) => OnKeybindChange("KeyLookRight", val), true)
app.RegisterHotKeyChange(app.X.Find("KeyForward"), (val) => OnKeybindChange("KeyForward", val), true)
app.RegisterHotKeyChange(app.X.Find("KeyBackwards"), (val) => OnKeybindChange("KeyBackwards", val), true)
app.RegisterHotKeyChange(app.X.Find("KeyMoveLeft"), (val) => OnKeybindChange("KeyMoveLeft", val), true)
app.RegisterHotKeyChange(app.X.Find("KeyMoveRight"), (val) => OnKeybindChange("KeyMoveRight", val), true)

; Bind event handlers
ui.OnEvent("Window", "LoadedHwnd", (*) => ValidateKeybinds())
ui.OnEvent("BtnSaveReload", "Click", SaveAndReload)
ui.OnEvent("BtnSetupShortcut", "Click", OnSetupClick)

ui.OnEvent("BtnNavGameplay", "Click", (*) => SwitchCategory("Gameplay"))
ui.OnEvent("BtnNavControls", "Click", (*) => SwitchCategory("Controls"))
ui.OnEvent("BtnNavGraphics", "Click", (*) => SwitchCategory("Graphics"))
ui.OnEvent("BtnNavAudio", "Click", (*) => SwitchCategory("Audio"))

ui.OnEvent("SliderSens", "ValueChanged", OnSliderChanged)
ui.OnEvent("SliderMaxFPS", "ValueChanged", OnSliderChanged)
ui.OnEvent("SliderMasterVol", "ValueChanged", OnSliderChanged)
ui.OnEvent("SliderMusicVol", "ValueChanged", OnSliderChanged)
ui.OnEvent("SliderSFXVol", "ValueChanged", OnSliderChanged)

ui.Track("ComboDifficulty")
ui.Track("ComboResolution")
ui.Track("TglInvertY")
ui.Track("TglVSync")
ui.Track("TglRayTracing")
ui.Track("TglVoiceChat")
ui.Track("SliderSens")
ui.Track("SliderMaxFPS")
ui.Track("SliderMasterVol")
ui.Track("SliderMusicVol")
ui.Track("SliderSFXVol")

ui.OnEvent("LinkNexus", "Click", (*) => Run("https://www.nexusmods.com"))
ui.OnEvent("LinkGithub", "Click", (*) => Run("https://github.com"))
ui.OnEvent("LinkAbout", "Click", (*) => ShowCustomDialog({ Title: "About Game Settings", Message: "Game Settings Configurator Demo v2.0`nCreated with AHK-XAML Military Tactical style.`n`nRedesigned with multi-page category selector sidebar.", Icon: Chr(0xE7E7), IconColor: "#FF4D4D", Owner: ui.wpfHwnd, Modal: true }))

; Dynamically bind all info buttons
for infoBtnName, descObj in infoDescriptions {
    ui.OnEvent(infoBtnName, "Click", OnInfoClick)
}

SwitchCategory(cat) {
    categories := ["Gameplay", "Controls", "Graphics", "Audio"]
    for c in categories {
        if (c == cat) {
            ui.Update("Panel" c, "Visibility", "Visible")
            ui.Update("Ind" c, "Text", "▶")
            ui.Update("Ind" c, "Foreground", "#FF9000")
        } else {
            ui.Update("Panel" c, "Visibility", "Collapsed")
            ui.Update("Ind" c, "Text", "  ")
            ui.Update("Ind" c, "Foreground", "#8A94A6")
        }
    }
}

OnSliderChanged(state, ctrl, event) {
    if state.Has(ctrl) {
        val := state[ctrl]
        if (ctrl == "SliderSens") {
            formatted := Format("{1:.1f}", Float(val))
            ui.Update(ctrl "Val", "Text", formatted)
        } else if (ctrl == "SliderMaxFPS") {
            ui.Update(ctrl "Val", "Text", Integer(Float(val)) " FPS")
        } else {
            ui.Update(ctrl "Val", "Text", Integer(Float(val)) "%")
        }
    }
}

OnInfoClick(state, ctrl, event) {
    if infoDescriptions.Has(ctrl) {
        info := infoDescriptions[ctrl]
        ShowCustomDialog({
            Title: info.Title,
            Message: info.Desc,
            Icon: Chr(0xE946),
            IconColor: "#FF9000",
            Owner: ui.wpfHwnd,
            Modal: true
        })
    }
}

OnSetupClick(state, ctrl, event) {
    ShowCustomDialog({
        Title: "Macro Setup",
        Message: "Entering Auto-Run Action Macro Setup...`n`n[MOCKED SETUP] Action coordinates configured for:`n- City Center (Active)`n- Marketplace (Active)`n- Guild Hall (Inactive)",
        Icon: Chr(0xE713),
        IconColor: "#FF9000",
        Owner: ui.wpfHwnd,
        Modal: true
    })
}

SaveAndReload(state, ctrl, event) {
    if (ValidateKeybinds()) {
        ShowCustomDialog({
            Title: "Keybind Conflict Detected",
            Message: "Multiple actions are assigned to the same key.`n`nPlease resolve conflicts (highlighted in red) before saving.",
            Icon: Chr(0xE7BA),
            IconColor: "#FF453A",
            Owner: ui.wpfHwnd,
            Modal: true
        })
        return
    }

    res := ui.Query("TglRightMouse", "TglMoveLook", "KeyVanityCamera", "KeyCombatArt", "TglAutoRun", "KeyLookLeft", "KeyLookRight", "KeyForward", "KeyBackwards", "KeyMoveLeft", "KeyMoveRight", "ComboGraphics", "ComboDifficulty", "SliderSens", "TglInvertY", "ComboResolution", "SliderMaxFPS", "TglVSync", "TglRayTracing", "SliderMasterVol", "SliderMusicVol", "SliderSFXVol", "TglVoiceChat")

    iniFile := A_ScriptDir "\game_settings.ini"
    try {
        IniWrite(res["TglRightMouse"] == "True" ? "1" : "0", iniFile, "Gameplay", "RightMouseLook")
        IniWrite(res["TglMoveLook"] == "True" ? "1" : "0", iniFile, "Gameplay", "MoveLook")
        IniWrite(res["KeyVanityCamera"], iniFile, "Gameplay", "VanityKey")
        IniWrite(res["KeyCombatArt"], iniFile, "Gameplay", "CombatKey")
        IniWrite(res["TglAutoRun"] == "True" ? "1" : "0", iniFile, "Gameplay", "AutoRunEnabled")
        IniWrite(res["ComboDifficulty"], iniFile, "Gameplay", "Difficulty")
        IniWrite(Format("{1:.1f}", Float(res["SliderSens"])), iniFile, "Gameplay", "MouseSensitivity")
        IniWrite(res["TglInvertY"] == "True" ? "1" : "0", iniFile, "Gameplay", "InvertY")

        IniWrite(res["KeyLookLeft"], iniFile, "Movement", "LookLeft")
        IniWrite(res["KeyLookRight"], iniFile, "Movement", "LookRight")
        IniWrite(res["KeyForward"], iniFile, "Movement", "Forward")
        IniWrite(res["KeyBackwards"], iniFile, "Movement", "Backwards")
        IniWrite(res["KeyMoveLeft"], iniFile, "Movement", "MoveLeft")
        IniWrite(res["KeyMoveRight"], iniFile, "Movement", "MoveRight")

        IniWrite(res["ComboGraphics"], iniFile, "Display", "GraphicQuality")
        IniWrite(res["ComboResolution"], iniFile, "Display", "Resolution")
        IniWrite(res["TglVSync"] == "True" ? "1" : "0", iniFile, "Display", "VSync")
        IniWrite(res["TglRayTracing"] == "True" ? "1" : "0", iniFile, "Display", "RayTracing")
        IniWrite(String(Integer(Float(res["SliderMaxFPS"]))), iniFile, "Display", "MaxFPS")

        IniWrite(String(Integer(Float(res["SliderMasterVol"]))), iniFile, "Audio", "MasterVolume")
        IniWrite(String(Integer(Float(res["SliderMusicVol"]))), iniFile, "Audio", "MusicVolume")
        IniWrite(String(Integer(Float(res["SliderSFXVol"]))), iniFile, "Audio", "SFXVolume")
        IniWrite(res["TglVoiceChat"] == "True" ? "1" : "0", iniFile, "Audio", "VoiceChat")

        ShowCustomDialog({
            Title: "Settings Saved",
            Message: "Configuration saved successfully!`n`nPress OK to reload the configuration GUI.",
            Icon: Chr(0xE73E),
            IconColor: "#00A3FF",
            Owner: ui.wpfHwnd,
            Modal: true
        })
        Reload()
    } catch as e {
        MsgBox("Failed to save settings: " e.Message)
    }
}

app.Show()