#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Components.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"

; ==============================================================================
; CUSTOM DIALOG STYLING & HELPER
; ==============================================================================
global CustomDialogOptions := {
    FontFamily: "Georgia, Segoe UI, sans-serif",
    TitleForeground: "#D4AF37",
    TitleFontFamily: "Georgia",
    TitleFontWeight: "Bold",
    TitleFontSize: 13,
    MessageForeground: "#CDD6F4",
    MessageFontFamily: "Georgia",
    MessageFontSize: 13,
    FooterBackground: "#0D0E10",
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
                            <Ellipse x:Name="Ring" Stroke="#AA7C11" StrokeThickness="1.2" Fill="#111317"/>
                            <Ellipse x:Name="Gem" Margin="3" Fill="#A02A10" Stroke="#500" StrokeThickness="0.8"/>
                            <Path Data="M 0,0 L 6,6 M 6,0 L 0,6" Stroke="#FFF" StrokeThickness="1.8" HorizontalAlignment="Center" VerticalAlignment="Center" IsHitTestVisible="False"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Gem" Property="Fill" Value="#E52B10"/>
                                <Setter TargetName="Ring" Property="Stroke" Value="#D4AF37"/>
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
            <GradientStop Color="#25253D59" Offset="0"/>
            <GradientStop Color="#00000000" Offset="1"/>
        </RadialGradientBrush>
        <LinearGradientBrush x:Key="GoldMetalBrush" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#8C7853" Offset="0.0"/>
            <GradientStop Color="#FFE57F" Offset="0.2"/>
            <GradientStop Color="#D4AF37" Offset="0.4"/>
            <GradientStop Color="#AA7C11" Offset="0.7"/>
            <GradientStop Color="#FFE57F" Offset="0.9"/>
            <GradientStop Color="#8C7853" Offset="1.0"/>
        </LinearGradientBrush>
        <SolidColorBrush x:Key="TextMain" Color="#CDD6F4" />
        <SolidColorBrush x:Key="TextSub" Color="#8A94A6" />
        <SolidColorBrush x:Key="Accent" Color="#00A3FF" />
        <SolidColorBrush x:Key="ControlBg" Color="#111317" />
        <SolidColorBrush x:Key="ControlBorder" Color="#2A2C30" />
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#0C0D10"/>
            <Setter Property="Foreground" Value="#FFF"/>
            <Setter Property="BorderBrush" Value="#2A2C30"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border x:Name="border" CornerRadius="4" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
                            <ScrollViewer x:Name="PART_ContentHost" Focusable="false" HorizontalScrollBarVisibility="Hidden" VerticalScrollBarVisibility="Hidden"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsFocused" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="#D4AF37"/>
                                <Setter TargetName="border" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="#D4AF37" BlurRadius="6" ShadowDepth="0"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="#4A4E57"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="DialogBtn" TargetType="Button">
            <Setter Property="Background" Value="#092533"/>
            <Setter Property="Foreground" Value="#D4AF37"/>
            <Setter Property="BorderBrush" Value="#AA7C11"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontFamily" Value="Georgia"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Border x:Name="Body" CornerRadius="4" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{TemplateBinding Background}"/>
                            <Border x:Name="InnerBorder" CornerRadius="3" Margin="2" BorderBrush="#30D4AF37" BorderThickness="1" IsHitTestVisible="False"/>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="15,6"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Body" Property="Background" Value="#0E394E"/>
                                <Setter Property="BorderBrush" Value="#D4AF37"/>
                                <Setter Property="Foreground" Value="#F3E5AB"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="DialogPrimaryBtn" TargetType="Button">
            <Setter Property="Background" Value="#103F54"/>
            <Setter Property="Foreground" Value="#FFF"/>
            <Setter Property="BorderBrush" Value="#D4AF37"/>
            <Setter Property="BorderThickness" Value="1.2"/>
            <Setter Property="FontFamily" Value="Georgia"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Border x:Name="Body" CornerRadius="4" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                        <GradientStop Color="#1A5975" Offset="0"/>
                                        <GradientStop Color="#0E394E" Offset="1"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                            </Border>
                            <Border x:Name="InnerBorder" CornerRadius="3" Margin="2" BorderBrush="#50D4AF37" BorderThickness="1" IsHitTestVisible="False"/>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="15,6"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Body" Property="Background">
                                    <Setter.Value>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                            <GradientStop Color="#257E9E" Offset="0"/>
                                            <GradientStop Color="#124D68" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Setter.Value>
                                </Setter>
                                <Setter Property="BorderBrush" Value="#FFE57F"/>
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
    frame := bgGrid.Add("Border").CornerRadius("8").BorderThickness("1.5").Background("#16191D")
    bgGrid.Add("Border").SetProp("IsHitTestVisible", "False").Background("{StaticResource CustomRadialGlow}")
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
    ; Create a few cluster centers for organic grouping of fractures
    centers := []
    Loop Random(3, 5) {
        centers.Push({
            x: Random(50, 890),
            y: Random(50, 600)
        })
    }

    Loop count {
        ; Pick a random cluster center
        center := centers[Random(1, centers.Length)]

        ; Apply Gaussian-like offset to cluster the scratches organically
        offsetX := (Random(-180, 180) + Random(-180, 180)) / 2
        offsetY := (Random(-140, 140) + Random(-140, 140)) / 2

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

        shadowOpacity := Integer(Random(15, 30) * opacityMult)
        if (shadowOpacity > 50)
            shadowOpacity := 50
        shadowBrush := "#" . Format("{1:02X}", shadowOpacity) . "000000"
        bgGrid.Add("Path").Data(pathData).Stroke(shadowBrush).StrokeThickness(String(thickness)).SetProp("IsHitTestVisible", "False")

        highlightOpacity := Integer(Random(8, 16) * opacityMult)
        if (highlightOpacity > 30)
            highlightOpacity := 30
        highlightBrush := "#" . Format("{1:02X}", highlightOpacity) . "00A3FF"
        bgGrid.Add("Path").Data(pathData).Stroke(highlightBrush).StrokeThickness(String(thickness * 0.5)).Margin("1,1,0,0").SetProp("IsHitTestVisible", "False")
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
    GraphicQuality: "High Fidelity"
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

            AppState.LookLeft := IniRead(iniFile, "Movement", "LookLeft", "a")
            AppState.LookRight := IniRead(iniFile, "Movement", "LookRight", "d")
            AppState.Forward := IniRead(iniFile, "Movement", "Forward", "w")
            AppState.Backwards := IniRead(iniFile, "Movement", "Backwards", "s")
            AppState.MoveLeft := IniRead(iniFile, "Movement", "MoveLeft", "u")
            AppState.MoveRight := IniRead(iniFile, "Movement", "MoveRight", "o")

            AppState.GraphicQuality := IniRead(iniFile, "Display", "GraphicQuality", "High Fidelity")
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
    <!-- Custom Styles for RPG Settings UI -->
    <SolidColorBrush x:Key="TextMain" Color="#CDD6F4" />
    <SolidColorBrush x:Key="TextSub" Color="#8A94A6" />
    <SolidColorBrush x:Key="Accent" Color="#00A3FF" />
    <SolidColorBrush x:Key="ControlBg" Color="#111317" />
    <SolidColorBrush x:Key="ControlBorder" Color="#2A2C30" />
    <CornerRadius x:Key="CloseBtnRadius">0,12,0,0</CornerRadius>
    <CornerRadius x:Key="WindowRadius">12</CornerRadius>
    
    <Style x:Key="WindowFrameStyle" TargetType="Border">
        <Setter Property="CornerRadius" Value="12"/>
        <Setter Property="BorderThickness" Value="3.5"/>
        <Setter Property="BorderBrush">
            <Setter.Value>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#8C7853" Offset="0.0"/>
                    <GradientStop Color="#D4AF37" Offset="0.3"/>
                    <GradientStop Color="#AA7C11" Offset="0.7"/>
                    <GradientStop Color="#D4AF37" Offset="1.0"/>
                </LinearGradientBrush>
            </Setter.Value>
        </Setter>
        <Setter Property="Background">
            <Setter.Value>
                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                    <GradientStop Color="#16191D" Offset="0.0"/>
                    <GradientStop Color="#0D0E10" Offset="1.0"/>
                </LinearGradientBrush>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="CentralGlow" TargetType="Border">
        <Setter Property="IsHitTestVisible" Value="False"/>
        <Setter Property="Background">
            <Setter.Value>
                <RadialGradientBrush Center="0.5,0.5" RadiusX="0.75" RadiusY="0.75">
                    <GradientStop Color="#253D59" Offset="0"/>
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
                    <GradientStop Color="#1A2A1E0D" Offset="0"/>
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
        <Setter Property="Background" Value="#B20C0D10"/>
        <Setter Property="BorderBrush" Value="#2A2E38"/>
        <Setter Property="BorderThickness" Value="1"/>
        <Setter Property="CornerRadius" Value="8"/>
        <Setter Property="Padding" Value="18,15,18,15"/>
        <Setter Property="Margin" Value="0,0,0,15"/>
        <Setter Property="Effect">
            <Setter.Value>
                <DropShadowEffect Color="#000000" BlurRadius="12" ShadowDepth="4" Opacity="0.5"/>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="SectionHeader" TargetType="TextBlock">
        <Setter Property="FontFamily" Value="Georgia"/>
        <Setter Property="FontWeight" Value="Bold"/>
        <Setter Property="FontSize" Value="16"/>
        <Setter Property="Foreground" Value="#E2C175"/>
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
                            <Border x:Name="Box" Width="18" Height="18" CornerRadius="4" 
                                    Background="#08090A" BorderBrush="#333A42" BorderThickness="1.5">
                                <Path x:Name="Check" Width="9" Height="7" Margin="1"
                                      Stretch="Fill" Fill="#00A3FF" 
                                      Data="M 0,3.5 L 3,6.5 L 9,0.5" 
                                      Stroke="#00A3FF" StrokeThickness="2"
                                      Visibility="Collapsed">
                                    <Path.Effect>
                                        <DropShadowEffect Color="#00A3FF" BlurRadius="6" ShadowDepth="0"/>
                                    </Path.Effect>
                                </Path>
                            </Border>
                        </BulletDecorator.Bullet>
                        <ContentPresenter Margin="8,0,0,0" VerticalAlignment="Center"/>
                    </BulletDecorator>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsChecked" Value="True">
                            <Setter TargetName="Box" Property="BorderBrush" Value="#00A3FF"/>
                            <Setter TargetName="Check" Property="Visibility" Value="Visible"/>
                            <Setter TargetName="Box" Property="Effect">
                                <Setter.Value>
                                    <DropShadowEffect Color="#00A3FF" BlurRadius="6" ShadowDepth="0"/>
                                </Setter.Value>
                            </Setter>
                        </Trigger>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Box" Property="BorderBrush" Value="#D4AF37"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="KeybindBox" TargetType="TextBox">
        <Setter Property="Background" Value="#0C0D10"/>
        <Setter Property="Foreground" Value="#FFF"/>
        <Setter Property="BorderBrush" Value="#2A2C30"/>
        <Setter Property="BorderThickness" Value="1"/>
        <Setter Property="HorizontalContentAlignment" Value="Center"/>
        <Setter Property="VerticalContentAlignment" Value="Center"/>
        <Setter Property="FontFamily" Value="Consolas, Courier New, monospace"/>
        <Setter Property="FontWeight" Value="Bold"/>
        <Setter Property="FontSize" Value="13.5"/>
        <Setter Property="CaretBrush" Value="Transparent"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="TextBox">
                    <Border x:Name="border" CornerRadius="4" 
                            Background="{TemplateBinding Background}" 
                            BorderBrush="{TemplateBinding BorderBrush}" 
                            BorderThickness="{TemplateBinding BorderThickness}">
                        <ScrollViewer x:Name="PART_ContentHost" Focusable="false" 
                                      HorizontalScrollBarVisibility="Hidden" 
                                      VerticalScrollBarVisibility="Hidden"/>
                    </Border>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsFocused" Value="True">
                            <Setter TargetName="border" Property="BorderBrush" Value="#D4AF37"/>
                            <Setter TargetName="border" Property="Effect">
                                <Setter.Value>
                                    <DropShadowEffect Color="#D4AF37" BlurRadius="6" ShadowDepth="0"/>
                                </Setter.Value>
                            </Setter>
                        </Trigger>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="border" Property="BorderBrush" Value="#4A4E57"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="InfoButton" TargetType="Button">
        <Setter Property="Width" Value="18"/>
        <Setter Property="Height" Value="18"/>
        <Setter Property="Background" Value="#2D323B"/>
        <Setter Property="Foreground" Value="#A0AAB8"/>
        <Setter Property="FontFamily" Value="Georgia"/>
        <Setter Property="FontStyle" Value="Italic"/>
        <Setter Property="FontWeight" Value="Bold"/>
        <Setter Property="FontSize" Value="10"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Grid>
                        <Ellipse x:Name="Bg" Fill="{TemplateBinding Background}" Stroke="#1F232B" StrokeThickness="1"/>
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,1,1"/>
                    </Grid>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bg" Property="Fill" Value="#D4AF37"/>
                            <Setter Property="Foreground" Value="#000"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="OrnateButton" TargetType="Button">
        <Setter Property="Background" Value="#E50F3346"/>
        <Setter Property="Foreground" Value="#D4AF37"/>
        <Setter Property="BorderBrush" Value="#AA7C11"/>
        <Setter Property="BorderThickness" Value="1"/>
        <Setter Property="FontFamily" Value="Georgia"/>
        <Setter Property="FontWeight" Value="Bold"/>
        <Setter Property="FontSize" Value="15"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Grid>
                        <Border x:Name="Body" CornerRadius="4" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}">
                            <Border.Background>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                    <GradientStop Color="#103F54" Offset="0"/>
                                    <GradientStop Color="#092533" Offset="1"/>
                                </LinearGradientBrush>
                            </Border.Background>
                        </Border>
                        
                        <Border x:Name="InnerBorder" CornerRadius="3" Margin="2" 
                                BorderBrush="#40D4AF37" BorderThickness="1" IsHitTestVisible="False"/>
                        
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="15,8,15,8"/>
                        
                        <Path Data="M 1,8 L 1,1 L 8,1" Stroke="#AA7C11" StrokeThickness="1.5" HorizontalAlignment="Left" VerticalAlignment="Top" IsHitTestVisible="False"/>
                        <Ellipse Width="3" Height="3" Fill="#AA7C11" Margin="3,3,0,0" HorizontalAlignment="Left" VerticalAlignment="Top" IsHitTestVisible="False"/>
                        
                        <Path Data="M 1,1 L 8,1 L 8,8" Stroke="#AA7C11" StrokeThickness="1.5" HorizontalAlignment="Right" VerticalAlignment="Top" IsHitTestVisible="False"/>
                        <Ellipse Width="3" Height="3" Fill="#AA7C11" Margin="0,3,3,0" HorizontalAlignment="Right" VerticalAlignment="Top" IsHitTestVisible="False"/>
                        
                        <Path Data="M 1,1 L 1,8 L 8,8" Stroke="#AA7C11" StrokeThickness="1.5" HorizontalAlignment="Left" VerticalAlignment="Bottom" IsHitTestVisible="False"/>
                        <Ellipse Width="3" Height="3" Fill="#AA7C11" Margin="3,0,0,3" HorizontalAlignment="Left" VerticalAlignment="Bottom" IsHitTestVisible="False"/>
                        
                        <Path Data="M 8,1 L 8,8 L 1,8" Stroke="#AA7C11" StrokeThickness="1.5" HorizontalAlignment="Right" VerticalAlignment="Bottom" IsHitTestVisible="False"/>
                        <Ellipse Width="3" Height="3" Fill="#AA7C11" Margin="0,0,3,3" HorizontalAlignment="Right" VerticalAlignment="Bottom" IsHitTestVisible="False"/>
                    </Grid>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Body" Property="Background">
                                <Setter.Value>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                        <GradientStop Color="#1A5975" Offset="0"/>
                                        <GradientStop Color="#0E394E" Offset="1"/>
                                    </LinearGradientBrush>
                                </Setter.Value>
                            </Setter>
                            <Setter Property="BorderBrush" Value="#D4AF37"/>
                            <Setter Property="Foreground" Value="#F3E5AB"/>
                            <Setter TargetName="InnerBorder" Property="BorderBrush" Value="#90D4AF37"/>
                        </Trigger>
                        <Trigger Property="IsPressed" Value="True">
                            <Setter TargetName="Body" Property="Background">
                                <Setter.Value>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                        <GradientStop Color="#071E2B" Offset="0"/>
                                        <GradientStop Color="#0E394E" Offset="1"/>
                                    </LinearGradientBrush>
                                </Setter.Value>
                            </Setter>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style TargetType="ComboBox">
        <Setter Property="Foreground" Value="#CDD6F4"/>
        <Setter Property="Background" Value="#0C0D10"/>
        <Setter Property="BorderBrush" Value="#AA7C11"/>
        <Setter Property="BorderThickness" Value="1"/>
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
                                    <Border x:Name="Border" CornerRadius="4" 
                                             Background="{TemplateBinding Background}" 
                                             BorderBrush="{TemplateBinding BorderBrush}" 
                                             BorderThickness="{TemplateBinding BorderThickness}">
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*" />
                                                <ColumnDefinition Width="30" />
                                            </Grid.ColumnDefinitions>
                                            <Path x:Name="Arrow" Grid.Column="1" HorizontalAlignment="Center" VerticalAlignment="Center" 
                                                   Stroke="#AA7C11" StrokeThickness="1.5" Data="M 0,1 L 4,5 L 8,1"/>
                                        </Grid>
                                    </Border>
                                    <ControlTemplate.Triggers>
                                        <Trigger Property="IsMouseOver" Value="True">
                                            <Setter TargetName="Border" Property="Background" Value="#15181C"/>
                                            <Setter TargetName="Border" Property="BorderBrush" Value="#D4AF37"/>
                                            <Setter TargetName="Arrow" Property="Stroke" Value="#D4AF37"/>
                                            <Setter TargetName="Arrow" Property="Effect">
                                                <Setter.Value>
                                                    <DropShadowEffect Color="#D4AF37" BlurRadius="4" ShadowDepth="0"/>
                                                </Setter.Value>
                                            </Setter>
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
                                <Border Name="DropDownBorder" Background="#0C0D10" BorderBrush="#AA7C11" BorderThickness="1" CornerRadius="0,0,4,4" />
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
        <Setter Property="Background" Value="#0C0D10"/>
        <Setter Property="Foreground" Value="#CDD6F4"/>
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
                            <Setter TargetName="Bg" Property="Background" Value="#AA7C11"/>
                            <Setter Property="Foreground" Value="White"/>
                        </Trigger>
                        <Trigger Property="IsSelected" Value="True">
                            <Setter TargetName="Bg" Property="Background" Value="#785B0D"/>
                            <Setter Property="Foreground" Value="White"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <!-- Phase 2 Gold Metal, God Rays, Rivet, and Bracket Styles -->
    <LinearGradientBrush x:Key="GoldMetalBrush" StartPoint="0,0" EndPoint="1,1">
        <GradientStop Color="#8C7853" Offset="0.0"/>
        <GradientStop Color="#FFE57F" Offset="0.2"/>
        <GradientStop Color="#D4AF37" Offset="0.4"/>
        <GradientStop Color="#AA7C11" Offset="0.7"/>
        <GradientStop Color="#FFE57F" Offset="0.9"/>
        <GradientStop Color="#8C7853" Offset="1.0"/>
    </LinearGradientBrush>
    
    <Style x:Key="GodRay1" TargetType="Path">
        <Setter Property="IsHitTestVisible" Value="False"/>
        <Setter Property="Fill">
            <Setter.Value>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#09FFFFFF" Offset="0"/>
                    <GradientStop Color="#03FFFFFF" Offset="0.4"/>
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
                    <GradientStop Color="#06FFFFFF" Offset="0"/>
                    <GradientStop Color="#02FFFFFF" Offset="0.5"/>
                    <GradientStop Color="#00FFFFFF" Offset="1"/>
                </LinearGradientBrush>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="RivetStyle" TargetType="Ellipse">
        <Setter Property="Width" Value="4"/>
        <Setter Property="Height" Value="4"/>
        <Setter Property="Fill" Value="{StaticResource GoldMetalBrush}"/>
        <Setter Property="Stroke" Value="#55000000"/>
        <Setter Property="StrokeThickness" Value="0.8"/>
        <Setter Property="Effect">
            <Setter.Value>
                <DropShadowEffect Color="#000" BlurRadius="2" ShadowDepth="1" Opacity="0.5"/>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="BracketStyle" TargetType="Path">
        <Setter Property="Fill" Value="{StaticResource GoldMetalBrush}"/>
        <Setter Property="Stroke" Value="#AA7C11"/>
        <Setter Property="StrokeThickness" Value="0.8"/>
        <Setter Property="Effect">
            <Setter.Value>
                <DropShadowEffect Color="#000" BlurRadius="4" ShadowDepth="1.5" Opacity="0.6"/>
            </Setter.Value>
        </Setter>
    </Style>
)'

app.main.InjectResources(customStyles)

; Find and restyle default window close/minimize buttons to thematic circles
btnClose := app.X.Find("BtnClose")
if btnClose {
    btnClose._Children := []
    btnClose._Props["Width"] := "22"
    btnClose._Props["Height"] := "22"
    btnClose._Props["VerticalAlignment"] := "Top"
    btnClose._Props["Margin"] := "0,9,55,0"
    btnClose.InjectResources('
    (
        <Style TargetType="Button">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Ellipse x:Name="Ring" Stroke="#AA7C11" StrokeThickness="1.5" Fill="#111317"/>
                            <Ellipse x:Name="Gem" Margin="3.5" Fill="#A02A10" Stroke="#500" StrokeThickness="1"/>
                            <Ellipse Margin="5,5,8,8" Fill="#40FFFFFF"/>
                            <Path Data="M 0,0 L 6,6 M 6,0 L 0,6" Stroke="#FFF" StrokeThickness="1.8" HorizontalAlignment="Center" VerticalAlignment="Center" IsHitTestVisible="False"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Gem" Property="Fill" Value="#E52B10"/>
                                <Setter TargetName="Ring" Property="Stroke" Value="#D4AF37"/>
                                <Setter TargetName="Ring" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="#D4AF37" BlurRadius="6" ShadowDepth="0"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Gem" Property="Fill" Value="#701205"/>
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
    btnMin._Props["Margin"] := "0,9,8,0"
    btnMin.InjectResources('
    (
        <Style TargetType="Button">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Ellipse x:Name="Ring" Stroke="#AA7C11" StrokeThickness="1.5" Fill="#111317"/>
                            <Ellipse x:Name="Gem" Margin="3.5" Fill="#1A4A60" Stroke="#0A2A3A" StrokeThickness="1"/>
                            <Ellipse Margin="5,5,8,8" Fill="#40FFFFFF"/>
                            <Path Data="M 0,0 L 6,0" Stroke="#FFF" StrokeThickness="2" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,3,0,0" IsHitTestVisible="False"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Gem" Property="Fill" Value="#2A7A9A"/>
                                <Setter TargetName="Ring" Property="Stroke" Value="#D4AF37"/>
                                <Setter TargetName="Ring" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="#D4AF37" BlurRadius="6" ShadowDepth="0"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Gem" Property="Fill" Value="#0A2A3A"/>
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
innerGoldBdr := windowFrame.Add("Border").Margin("2").BorderThickness("1").BorderBrush("#25D4AF37").CornerRadius("9")

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

; Ornate Gold Celtic Inlay Border Path (octagonal chamfered with diamond center notches)
bgGrid.Add("Path").Data("M 30,16 L 455,16 L 470,31 L 485,16 L 910,16 L 924,30 L 924,285 L 909,300 L 924,315 L 924,570 L 910,584 L 485,584 L 470,569 L 455,584 L 30,584 L 16,570 L 16,315 L 31,300 L 16,285 L 16,30 Z").Stroke("{StaticResource GoldMetalBrush}").StrokeThickness("1.2").SetProp("IsHitTestVisible", "False").Opacity("0.35")

; Glowing abstract circles in the empty bottom-left background area
bgCircleLeft := bgGrid.Add("Grid").Width(340).Height(340).HorizontalAlignment("Left").VerticalAlignment("Bottom").Margin("50,0,0,50")
bgCircleLeft.SetProp("IsHitTestVisible", "False")
bgCircleLeft.Add("Ellipse").Stroke("#05D4AF37").StrokeThickness("1.5").SetProp("StrokeDashArray", "8 6")
bgCircleLeft.Add("Ellipse").Margin("15").Stroke("#03D4AF37").StrokeThickness("1")
bgCircleLeft.Add("Ellipse").Margin("25").Stroke("#02D4AF37").StrokeThickness("1.5").SetProp("StrokeDashArray", "2 4")
bgCircleLeft.Add("Ellipse").Margin("45").Stroke("#048C7853").StrokeThickness("1")
bgCircleLeft.Add("Path").Data("M 170,15 L 170,325 M 15,170 L 325,170").Stroke("#02D4AF37").StrokeThickness("1")
bgCircleLeft.Add("Path").Data("M 58,58 L 282,282 M 58,282 L 282,58").Stroke("#01D4AF37").StrokeThickness("1")
bgCircleLeft.Add("Ellipse").Margin("136").Fill("#01D4AF37")
bgCircleLeft.Add("Polygon").SetProp("Points", "170,150 185,170 170,190 155,170").Fill("#03D4AF37")

; Secondary larger abstract circles/geometry in upper-right to balance layout
bgCircleRight := bgGrid.Add("Grid").Width(460).Height(460).HorizontalAlignment("Right").VerticalAlignment("Top").Margin("0,20,-120,0")
bgCircleRight.SetProp("IsHitTestVisible", "False")
bgCircleRight.Add("Ellipse").Stroke("#03D4AF37").StrokeThickness("1.5").SetProp("StrokeDashArray", "10 8")
bgCircleRight.Add("Ellipse").Margin("25").Stroke("#02D4AF37").StrokeThickness("1")
bgCircleRight.Add("Ellipse").Margin("50").Stroke("#02D4AF37").StrokeThickness("1").SetProp("StrokeDashArray", "4 4")
bgCircleRight.Add("Path").Data("M 230,10 L 230,450 M 10,230 L 450,230").Stroke("#02D4AF37").StrokeThickness("1")
bgCircleRight.Add("Path").Data("M 77,77 L 383,383 M 77,383 L 383,77").Stroke("#01D4AF37").StrokeThickness("1")
bgCircleRight.Add("Polygon").SetProp("Points", "230,25 435,230 230,435 25,230").Stroke("#02D4AF37").StrokeThickness("1")
bgCircleRight.Add("Polygon").SetProp("Points", "85,85 375,85 375,375 85,375").Stroke("#02D4AF37").StrokeThickness("1")

; Ornate Heavy Gold Window Corner Brackets & Rivets
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

; 3D Slate Veins / Fractures (groove shadow + lit cyan edge highlight)
; Vein 1
bgGrid.Add("Path").Data("M -50,120 C 120,90 180,240 330,190 C 420,160 480,300 620,230 C 720,210 820,330 990,290 M 330,190 C 290,270 250,320 220,400 M 620,230 C 650,130 690,90 720,20").Stroke("#35000000").StrokeThickness("1.6").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Path").Data("M -50,120 C 120,90 180,240 330,190 C 420,160 480,300 620,230 C 720,210 820,330 990,290 M 330,190 C 290,270 250,320 220,400 M 620,230 C 650,130 690,90 720,20").Stroke("#1F00A3FF").StrokeThickness("0.8").Margin("1,1,0,0").SetProp("IsHitTestVisible", "False")

; Vein 2
bgGrid.Add("Path").Data("M 280,-50 C 240,160 350,270 300,420 C 270,530 380,580 320,650 M 300,420 C 210,440 160,500 90,540 M 320,650 C 340,560 410,520 480,480").Stroke("#30000000").StrokeThickness("1.4").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Path").Data("M 280,-50 C 240,160 350,270 300,420 C 270,530 380,580 320,650 M 300,420 C 210,440 160,500 90,540 M 320,650 C 340,560 410,520 480,480").Stroke("#1A00A3FF").StrokeThickness("0.7").Margin("1,1,0,0").SetProp("IsHitTestVisible", "False")

; Vein 3
bgGrid.Add("Path").Data("M 990,80 C 840,130 790,50 630,130 C 520,170 420,85 320,160 C 190,230 130,190 -50,260 M 630,130 C 570,240 540,340 500,480").Stroke("#32000000").StrokeThickness("1.5").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Path").Data("M 990,80 C 840,130 790,50 630,130 C 520,170 420,85 320,160 C 190,230 130,190 -50,260 M 630,130 C 570,240 540,340 500,480").Stroke("#1C00A3FF").StrokeThickness("0.8").Margin("1,1,0,0").SetProp("IsHitTestVisible", "False")

; Organic Gold Ore Vein (New thematic element!)
bgGrid.Add("Path").Data("M 150,-50 C 180,80 120,180 250,280 C 300,320 220,480 350,650").Stroke("#30000000").StrokeThickness("1.5").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Path").Data("M 150,-50 C 180,80 120,180 250,280 C 300,320 220,480 350,650").Stroke("#1C00A3FF").StrokeThickness("0.8").Margin("1,1,0,0").SetProp("IsHitTestVisible", "False")

; Generate procedural minor background scratches/fractures (75 scratches all over)
GenerateBackgroundScratches(bgGrid, 300)

; Ornate Gold separator line below the title bar with a center diamond ornament
app.main.Add("Path").Grid_Row(0).VerticalAlignment("Bottom").Height("12").Data("M 0,2 L 440,2 L 448,5 L 458,5 L 470,11 L 482,5 L 492,5 L 500,2 L 940,2").Stroke("#40D4AF37").StrokeThickness("1.5").SetProp("IsHitTestVisible", "False")
app.main.Add("Ellipse").Grid_Row(0).Width(5).Height(5).Fill("#D4AF37").HorizontalAlignment("Center").VerticalAlignment("Top").Margin("18,36.5,0,0").SetProp("IsHitTestVisible", "False")

; ==============================================================================
; CONTENT AREAS AND COLUMN PRE-SETTING
; ==============================================================================

contentGrid := app.main.Add("Grid").Grid_Row(1).Margin("25,10,25,10")
contentGrid.Cols("1*", "30", "1*")
contentGrid.Rows("Auto", "*", "Auto", "Auto")

; Clean centered gothic title block
contentGrid.Add("TextBlock").Grid_Row(0).Grid_Column(0).Grid_ColumnSpan(3).Text("GAME SETTINGS").FontFamily("Georgia").FontSize(24).FontWeight("Bold").Foreground("#D4AF37").HorizontalAlignment("Center").Margin("0,10,0,15")

leftCol := contentGrid.Add("StackPanel").Grid_Column(0).Grid_Row(1)
rightCol := contentGrid.Add("StackPanel").Grid_Column(2).Grid_Row(1)

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
    lbl.InjectResources('<Style TargetType="TextBlock"><Setter Property="Foreground" Value="#CBD5E1"/><Style.Triggers><DataTrigger Binding="{Binding IsChecked, ElementName=' name '}" Value="True"><Setter Property="Foreground" Value="#F0F9FF"/><Setter Property="Effect"><Setter.Value><DropShadowEffect Color="#00A3FF" BlurRadius="6" ShadowDepth="0" Opacity="0.9"/></Setter.Value></Setter></DataTrigger></Style.Triggers></Style>')

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
    lbl.InjectResources('<Style TargetType="TextBlock"><Setter Property="Foreground" Value="#CBD5E1"/><Style.Triggers><DataTrigger Binding="{Binding IsChecked, ElementName=TglAutoRun}" Value="True"><Setter Property="Foreground" Value="#F0F9FF"/><Setter Property="Effect"><Setter.Value><DropShadowEffect Color="#00A3FF" BlurRadius="6" ShadowDepth="0" Opacity="0.9"/></Setter.Value></Setter></DataTrigger></Style.Triggers></Style>')

    rightSp := rowGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(1).VerticalAlignment("Center")

    setupBtn := rightSp.Add("Button").Name("BtnSetupShortcut").Content("Setup").Background("Transparent").Foreground("#D4AF37").BorderThickness("0").Cursor("Hand").FontWeight("Bold").Margin("0,0,8,0").VerticalAlignment("Center")
    setupBtn.InjectResources('<Style TargetType="Button"><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><TextBlock Text="{TemplateBinding Content}" TextDecorations="Underline"/></ControlTemplate></Setter.Value></Setter></Style>')

    rightSp.Add("CheckBox").Name("TglAutoRun").Style("{StaticResource CustomCheckBox}").IsChecked(AppState.AutoRunEnabled ? "True" : "False").Cursor("Hand").Margin("0,0,8,0").VerticalAlignment("Center")
    rightSp.Add("Button").Name("InfoAutoRun").Style("{StaticResource InfoButton}").Content("i").VerticalAlignment("Center")

    infoDescriptions["InfoAutoRun"] := { Title: "Auto-Run Shortcut", Desc: "Allows binding a dedicated key to automatically run or perform macro actions." }
}

AddDropdownRow(parent, name, label, selectedVal, items) {
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

    rightSp.Add("Button").Name("Info_" name).Style("{StaticResource InfoButton}").Content("i").VerticalAlignment("Center")
    infoDescriptions["Info_" name] := { Title: label, Desc: "Selects the graphics rendering fidelity preset. Higher presets enable better shadows and texture resolution." }
}

; --- LEFT COLUMN SECTIONS ---
gameplaySp := CreateSectionBox(leftCol, "GAMEPLAY CONFIGURATION")
AddCheckboxRow(gameplaySp, "TglRightMouse", "Mouselook with Right Mouse Button", AppState.RightMouseLook, "InfoRightMouse", "Enables camera control when holding down the Right Mouse Button.")
AddCheckboxRow(gameplaySp, "TglMoveLook", "Mouselook while Moving Forward/Backwards", AppState.MoveLook, "InfoMoveLook", "Allows adjusting orientation with mouse while moving.")

specialSp := CreateSectionBox(leftCol, "SPECIAL KEY ASSIGNMENTS")
AddKeybindRow(specialSp, "KeyVanityCamera", "Orbit Camera", AppState.VanityKey, "InfoVanityCamera", "Switches the viewport to a dramatic orbiting angle.")
AddKeybindRow(specialSp, "KeyCombatArt", "Ability Key", AppState.CombatKey, "InfoCombatKey", "Executes the selected action or ability.")
AddAutoRunRow(specialSp)

; --- RIGHT COLUMN SECTIONS ---
movementSp := CreateSectionBox(rightCol, "MOVEMENT ACTIONS", "InfoMovementKeys", "Configure the default keyboard movements for camera panning, movement directions, and looking offsets.")
movementSp.Add("TextBlock").Text("Make sure these are the same as your in-game controls!").Foreground("#8A94A6").FontSize(11).FontStyle("Italic").Margin("0,0,0,12")
AddKeybindRow(movementSp, "KeyLookLeft", "Look Left", AppState.LookLeft)
AddKeybindRow(movementSp, "KeyLookRight", "Look Right", AppState.LookRight)
AddKeybindRow(movementSp, "KeyForward", "Forward", AppState.Forward)
AddKeybindRow(movementSp, "KeyBackwards", "Backwards", AppState.Backwards)
AddKeybindRow(movementSp, "KeyMoveLeft", "Move Left", AppState.MoveLeft)
AddKeybindRow(movementSp, "KeyMoveRight", "Move Right", AppState.MoveRight)

displaySp := CreateSectionBox(rightCol, "DISPLAY SETTINGS")
AddDropdownRow(displaySp, "ComboGraphics", "Display Quality Preset", AppState.GraphicQuality, ["Low Performance", "Medium Quality", "High Fidelity", "Ultra / Cinematic"])

; ==============================================================================
; ORNATE SAVE & RELOAD BUTTON
; ==============================================================================

btnBorder := contentGrid.Add("Border").Grid_Row(2).Grid_Column(0).Grid_ColumnSpan(3).HorizontalAlignment("Center").Margin("0,10,0,15")
saveBtn := btnBorder.Add("Button").Name("BtnSaveReload").Content("SAVE & RELOAD").Style("{StaticResource OrnateButton}").Width(260).Height(45)

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

    iconColor := "#D4AF37"
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

ui.OnEvent("LinkNexus", "Click", (*) => Run("https://www.nexusmods.com"))
ui.OnEvent("LinkGithub", "Click", (*) => Run("https://github.com"))
ui.OnEvent("LinkAbout", "Click", (*) => ShowCustomDialog({ Title: "About Game Settings", Message: "Game Settings Configurator Demo v1.2`nCreated with AHK-XAML vector graphics.`n`nProcedural vectors ensure perfect rendering sharpness at any resolution.", Icon: Chr(0xE7E7), IconColor: "#FF4D4D", Owner: ui.wpfHwnd, Modal: true }))

; Dynamically bind all info buttons
for infoBtnName, descObj in infoDescriptions {
    ui.OnEvent(infoBtnName, "Click", OnInfoClick)
}

OnInfoClick(state, ctrl, event) {
    if infoDescriptions.Has(ctrl) {
        info := infoDescriptions[ctrl]
        ShowCustomDialog({
            Title: info.Title,
            Message: info.Desc,
            Icon: Chr(0xE946),
            IconColor: "#D4AF37",
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
        IconColor: "#D4AF37",
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

    res := ui.Query("TglRightMouse", "TglMoveLook", "KeyVanityCamera", "KeyCombatArt", "TglAutoRun", "KeyLookLeft", "KeyLookRight", "KeyForward", "KeyBackwards", "KeyMoveLeft", "KeyMoveRight", "ComboGraphics")

    iniFile := A_ScriptDir "\game_settings.ini"
    try {
        IniWrite(res["TglRightMouse"] == "True" ? "1" : "0", iniFile, "Gameplay", "RightMouseLook")
        IniWrite(res["TglMoveLook"] == "True" ? "1" : "0", iniFile, "Gameplay", "MoveLook")
        IniWrite(res["KeyVanityCamera"], iniFile, "Gameplay", "VanityKey")
        IniWrite(res["KeyCombatArt"], iniFile, "Gameplay", "CombatKey")
        IniWrite(res["TglAutoRun"] == "True" ? "1" : "0", iniFile, "Gameplay", "AutoRunEnabled")

        IniWrite(res["KeyLookLeft"], iniFile, "Movement", "LookLeft")
        IniWrite(res["KeyLookRight"], iniFile, "Movement", "LookRight")
        IniWrite(res["KeyForward"], iniFile, "Movement", "Forward")
        IniWrite(res["KeyBackwards"], iniFile, "Movement", "Backwards")
        IniWrite(res["KeyMoveLeft"], iniFile, "Movement", "MoveLeft")
        IniWrite(res["KeyMoveRight"], iniFile, "Movement", "MoveRight")

        IniWrite(res["ComboGraphics"], iniFile, "Display", "GraphicQuality")

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