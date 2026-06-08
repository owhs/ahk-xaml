#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Components.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"

; ==============================================================================
; CUSTOM DIALOG STYLING & HELPER
; ==============================================================================
global CustomDialogOptions := {
    FontFamily: "Segoe UI, Trebuchet MS, sans-serif",
    TitleForeground: "#00E5FF",
    TitleFontFamily: "Segoe UI",
    TitleFontWeight: "Bold",
    TitleFontSize: 13,
    MessageForeground: "#E0F7FA",
    MessageFontFamily: "Segoe UI",
    MessageFontSize: 13,
    FooterBackground: "#060A12",
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
                            <Rectangle x:Name="Box" Stroke="#00838F" StrokeThickness="1.2" Fill="#060A12" RadiusX="2" RadiusY="2"/>
                            <Path x:Name="Symbol" Data="M 0,0 L 8,8 M 8,0 L 0,8" Width="8" Height="8" Stretch="Uniform" Stroke="#FF6D00" StrokeThickness="2.0" HorizontalAlignment="Center" VerticalAlignment="Center" IsHitTestVisible="False"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Box" Property="Stroke" Value="#00E5FF"/>
                                <Setter TargetName="Box" Property="Fill" Value="#1000E5FF"/>
                                <Setter TargetName="Symbol" Property="Stroke" Value="#FF9E00"/>
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
            <GradientStop Color="#3000E5FF" Offset="0"/>
            <GradientStop Color="#00000000" Offset="1"/>
        </RadialGradientBrush>
        <LinearGradientBrush x:Key="CyberCyanBrush" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#004D40" Offset="0.0"/>
            <GradientStop Color="#00B0FF" Offset="0.3"/>
            <GradientStop Color="#00E5FF" Offset="0.5"/>
            <GradientStop Color="#00838F" Offset="0.7"/>
            <GradientStop Color="#00E5FF" Offset="0.9"/>
            <GradientStop Color="#004D40" Offset="1.0"/>
        </LinearGradientBrush>
        <SolidColorBrush x:Key="TextMain" Color="#E0F7FA" />
        <SolidColorBrush x:Key="TextSub" Color="#64B5F6" />
        <SolidColorBrush x:Key="Accent" Color="#00E5FF" />
        <SolidColorBrush x:Key="ControlBg" Color="#0C101B" />
        <SolidColorBrush x:Key="ControlBorder" Color="#1B3B52" />
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#03050A"/>
            <Setter Property="Foreground" Value="#FFF"/>
            <Setter Property="BorderBrush" Value="#1B3B52"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border x:Name="border" CornerRadius="0" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
                            <ScrollViewer x:Name="PART_ContentHost" Focusable="false" HorizontalScrollBarVisibility="Hidden" VerticalScrollBarVisibility="Hidden"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsFocused" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="#00E5FF"/>
                                <Setter TargetName="border" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="#00E5FF" BlurRadius="6" ShadowDepth="0"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="#00838F"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="DialogBtn" TargetType="Button">
            <Setter Property="Background" Value="#101A30"/>
            <Setter Property="Foreground" Value="#00E5FF"/>
            <Setter Property="BorderBrush" Value="#00838F"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Border x:Name="Body" CornerRadius="0" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Background="{TemplateBinding Background}"/>
                            <Border x:Name="InnerBorder" CornerRadius="0" Margin="2" BorderBrush="#3000E5FF" BorderThickness="1" IsHitTestVisible="False"/>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="15,6"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Body" Property="Background" Value="#152E4A"/>
                                <Setter Property="BorderBrush" Value="#00E5FF"/>
                                <Setter Property="Foreground" Value="#E0F7FA"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="DialogPrimaryBtn" TargetType="Button">
            <Setter Property="Background" Value="#004D5A"/>
            <Setter Property="Foreground" Value="#FFF"/>
            <Setter Property="BorderBrush" Value="#00E5FF"/>
            <Setter Property="BorderThickness" Value="1.2"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid>
                            <Border x:Name="Body" CornerRadius="0" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                        <GradientStop Color="#007E91" Offset="0"/>
                                        <GradientStop Color="#004D5A" Offset="1"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                            </Border>
                            <Border x:Name="InnerBorder" CornerRadius="0" Margin="2" BorderBrush="#5000E5FF" BorderThickness="1" IsHitTestVisible="False"/>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="15,6"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Body" Property="Background">
                                    <Setter.Value>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                            <GradientStop Color="#00A5BD" Offset="0"/>
                                            <GradientStop Color="#006C7E" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Setter.Value>
                                </Setter>
                                <Setter Property="BorderBrush" Value="#E0F7FA"/>
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
    bgGrid.Add("Border").CornerRadius("0").Background("#080C14")
    bgGrid.Add("Border").SetProp("IsHitTestVisible", "False").Background("{StaticResource CustomRadialGlow}")
    
    fgGrid := main.Add("Grid").Grid_Row(0).Grid_RowSpan(3)
    fgGrid.SetProp("Panel.ZIndex", "10")
    fgGrid.SetProp("IsHitTestVisible", "False")
    frame := fgGrid.Add("Border").CornerRadius("0").BorderThickness("1.5").Background("Transparent")
    frame.BorderBrush("{StaticResource CyberCyanBrush}")
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

GenerateSciFiGrid(bgGrid) {
    ; Horizontal grid lines (subtle cyan #0500E5FF)
    y := 40
    Loop 12 {
        bgGrid.Add("Path").Data("M 10," y " L 930," y).Stroke("#0500E5FF").StrokeThickness("1").SetProp("IsHitTestVisible", "False")
        y += 50
    }
    ; Vertical grid lines
    x := 50
    Loop 18 {
        bgGrid.Add("Path").Data("M " x ",40 L " x ",610").Stroke("#0500E5FF").StrokeThickness("1").SetProp("IsHitTestVisible", "False")
        x += 50
    }
    ; Tech corner markers
    bgGrid.Add("Path").Data("M 40,30 L 30,30 L 30,40 M 900,30 L 910,30 L 910,40 M 30,610 L 30,620 L 40,620 M 910,610 L 910,620 L 900,620").Stroke("#2000E5FF").StrokeThickness("1.5").SetProp("IsHitTestVisible", "False")
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
    <!-- Custom Styles for Sci-Fi Settings UI -->
    <LinearGradientBrush x:Key="CyberCyanBrush" StartPoint="0,0" EndPoint="1,1">
        <GradientStop Color="#004D40" Offset="0.0"/>
        <GradientStop Color="#00B0FF" Offset="0.3"/>
        <GradientStop Color="#00E5FF" Offset="0.5"/>
        <GradientStop Color="#00838F" Offset="0.7"/>
        <GradientStop Color="#00E5FF" Offset="0.9"/>
        <GradientStop Color="#004D40" Offset="1.0"/>
    </LinearGradientBrush>

    <SolidColorBrush x:Key="TextMain" Color="#E0F7FA" />
    <SolidColorBrush x:Key="TextSub" Color="#64B5F6" />
    <SolidColorBrush x:Key="Accent" Color="#00E5FF" />
    <SolidColorBrush x:Key="ControlBg" Color="#0C101B" />
    <SolidColorBrush x:Key="ControlBorder" Color="#1B3B52" />
    <CornerRadius x:Key="CloseBtnRadius">0</CornerRadius>
    <CornerRadius x:Key="WindowRadius">0</CornerRadius>
    
    <!-- Themed Scrollbar Styles -->
    <Style x:Key="ThemedScrollBarThumb" TargetType="Thumb">
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Thumb">
                    <Border x:Name="border" Background="#00838F" CornerRadius="0" Margin="1" Opacity="0.7"/>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="border" Property="Background" Value="#00E5FF"/>
                            <Setter TargetName="border" Property="Opacity" Value="0.9"/>
                        </Trigger>
                        <Trigger Property="IsDragging" Value="True">
                            <Setter TargetName="border" Property="Background" Value="#E0F7FA"/>
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
                    <Grid Background="#03050A">
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
                            <Grid Background="#03050A">
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

    <DrawingBrush x:Key="ScanlineBrush" TileMode="Tile" Viewport="0,0,4,4" ViewportUnits="Absolute">
        <DrawingBrush.Drawing>
            <GeometryDrawing Brush="#1500E5FF">
                <GeometryDrawing.Geometry>
                    <RectangleGeometry Rect="0,0,4,1"/>
                </GeometryDrawing.Geometry>
            </GeometryDrawing>
        </DrawingBrush.Drawing>
    </DrawingBrush>

    <Style x:Key="WindowFrameStyle" TargetType="Border">
        <Setter Property="CornerRadius" Value="0"/>
        <Setter Property="BorderThickness" Value="2"/>
        <Setter Property="BorderBrush" Value="{StaticResource CyberCyanBrush}"/>
        <Setter Property="Background">
            <Setter.Value>
                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                    <GradientStop Color="#080C14" Offset="0.0"/>
                    <GradientStop Color="#03050A" Offset="1.0"/>
                </LinearGradientBrush>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="CentralGlow" TargetType="Border">
        <Setter Property="IsHitTestVisible" Value="False"/>
        <Setter Property="Background">
            <Setter.Value>
                <RadialGradientBrush Center="0.5,0.5" RadiusX="0.75" RadiusY="0.75">
                    <GradientStop Color="#1A00E5FF" Offset="0"/>
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
                    <GradientStop Color="#1000A3FF" Offset="0"/>
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
                    <GradientStop Color="#0500E5FF" Offset="0"/>
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
                    <GradientStop Color="#08000000" Offset="0"/>
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
                        <GeometryDrawing Brush="#02FFFFFF">
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
        <Setter Property="Background" Value="#E5070B12"/>
        <Setter Property="BorderBrush" Value="#1B3B52"/>
        <Setter Property="BorderThickness" Value="1"/>
        <Setter Property="CornerRadius" Value="0"/>
        <Setter Property="Padding" Value="18,15,18,15"/>
        <Setter Property="Margin" Value="0,0,0,15"/>
        <Setter Property="Effect">
            <Setter.Value>
                <DropShadowEffect Color="#00E5FF" BlurRadius="6" ShadowDepth="0" Opacity="0.15"/>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="SectionHeader" TargetType="TextBlock">
        <Setter Property="FontFamily" Value="Segoe UI, Trebuchet MS, sans-serif"/>
        <Setter Property="FontWeight" Value="Bold"/>
        <Setter Property="FontSize" Value="14"/>
        <Setter Property="Foreground" Value="#00E5FF"/>
        <Setter Property="Margin" Value="0,0,0,15"/>
    </Style>
    
    <Style x:Key="CustomCheckBox" TargetType="CheckBox">
        <Setter Property="Foreground" Value="#E0F7FA"/>
        <Setter Property="FontSize" Value="13"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="CheckBox">
                    <BulletDecorator Background="Transparent">
                        <BulletDecorator.Bullet>
                            <Grid Width="18" Height="18">
                                <Border x:Name="Box" CornerRadius="0" Background="#03050A" BorderBrush="#1B3B52" BorderThickness="1.2">
                                    <Grid x:Name="Check" Visibility="Collapsed">
                                        <Rectangle Fill="#00E5FF" Margin="3"/>
                                    </Grid>
                                </Border>
                                <Path x:Name="CornerTL" Data="M 0,2 L 0,0 L 2,0" Stroke="#00E5FF" StrokeThickness="1" HorizontalAlignment="Left" VerticalAlignment="Top" Visibility="Collapsed" IsHitTestVisible="False"/>
                                <Path x:Name="CornerTR" Data="M 0,0 L 2,0 L 2,2" Stroke="#00E5FF" StrokeThickness="1" HorizontalAlignment="Right" VerticalAlignment="Top" Visibility="Collapsed" IsHitTestVisible="False"/>
                                <Path x:Name="CornerBL" Data="M 0,0 L 0,2 L 2,2" Stroke="#00E5FF" StrokeThickness="1" HorizontalAlignment="Left" VerticalAlignment="Bottom" Visibility="Collapsed" IsHitTestVisible="False"/>
                                <Path x:Name="CornerBR" Data="M 2,0 L 2,2 L 0,2" Stroke="#00E5FF" StrokeThickness="1" HorizontalAlignment="Right" VerticalAlignment="Bottom" Visibility="Collapsed" IsHitTestVisible="False"/>
                            </Grid>
                        </BulletDecorator.Bullet>
                        <ContentPresenter Margin="8,0,0,0" VerticalAlignment="Center"/>
                    </BulletDecorator>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsChecked" Value="True">
                            <Setter TargetName="Box" Property="BorderBrush" Value="#00E5FF"/>
                            <Setter TargetName="Check" Property="Visibility" Value="Visible"/>
                            <Setter TargetName="CornerTL" Property="Visibility" Value="Visible"/>
                            <Setter TargetName="CornerTR" Property="Visibility" Value="Visible"/>
                            <Setter TargetName="CornerBL" Property="Visibility" Value="Visible"/>
                            <Setter TargetName="CornerBR" Property="Visibility" Value="Visible"/>
                            <Setter TargetName="Box" Property="Effect">
                                <Setter.Value>
                                    <DropShadowEffect Color="#00E5FF" BlurRadius="5" ShadowDepth="0" Opacity="0.5"/>
                                </Setter.Value>
                            </Setter>
                        </Trigger>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Box" Property="BorderBrush" Value="#00E5FF"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="KeybindBox" TargetType="TextBox">
        <Setter Property="Background" Value="#03050A"/>
        <Setter Property="Foreground" Value="#FFF"/>
        <Setter Property="BorderBrush" Value="#1B3B52"/>
        <Setter Property="BorderThickness" Value="1"/>
        <Setter Property="HorizontalContentAlignment" Value="Center"/>
        <Setter Property="VerticalContentAlignment" Value="Center"/>
        <Setter Property="FontFamily" Value="Consolas, Courier New, monospace"/>
        <Setter Property="FontWeight" Value="Bold"/>
        <Setter Property="FontSize" Value="13"/>
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
                            <Setter TargetName="border" Property="BorderBrush" Value="#00E5FF"/>
                            <Setter TargetName="border" Property="Effect">
                                <Setter.Value>
                                    <DropShadowEffect Color="#00E5FF" BlurRadius="6" ShadowDepth="0"/>
                                </Setter.Value>
                            </Setter>
                        </Trigger>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="border" Property="BorderBrush" Value="#00838F"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="InfoButton" TargetType="Button">
        <Setter Property="Width" Value="18"/>
        <Setter Property="Height" Value="18"/>
        <Setter Property="Background" Value="#101A30"/>
        <Setter Property="Foreground" Value="#64B5F6"/>
        <Setter Property="FontFamily" Value="Segoe UI, sans-serif"/>
        <Setter Property="FontStyle" Value="Normal"/>
        <Setter Property="FontWeight" Value="Bold"/>
        <Setter Property="FontSize" Value="10"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Grid>
                        <Ellipse x:Name="Bg" Fill="{TemplateBinding Background}" Stroke="#1B3B52" StrokeThickness="1"/>
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,1,1"/>
                    </Grid>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Bg" Property="Fill" Value="#00E5FF"/>
                            <Setter Property="Foreground" Value="#03050A"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="OrnateButton" TargetType="Button">
        <Setter Property="Background" Value="#101A30"/>
        <Setter Property="Foreground" Value="#00E5FF"/>
        <Setter Property="BorderBrush" Value="#00838F"/>
        <Setter Property="BorderThickness" Value="1"/>
        <Setter Property="FontFamily" Value="Segoe UI, sans-serif"/>
        <Setter Property="FontWeight" Value="Bold"/>
        <Setter Property="FontSize" Value="14"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Button">
                    <Grid>
                        <Border x:Name="Body" CornerRadius="0" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}"
                                Background="{TemplateBinding Background}"/>
                        
                        <Border x:Name="InnerBorder" CornerRadius="0" Margin="2" 
                                BorderBrush="#3000E5FF" BorderThickness="1" IsHitTestVisible="False"/>
                        
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="10,8,10,8"/>
                        
                        <!-- Diagonal corner tech notches -->
                        <Path Data="M 0,3 L 3,0" Stroke="#00E5FF" StrokeThickness="1" HorizontalAlignment="Left" VerticalAlignment="Top" IsHitTestVisible="False"/>
                        <Path Data="M 0,-3 L 3,0" Stroke="#00E5FF" StrokeThickness="1" HorizontalAlignment="Left" VerticalAlignment="Bottom" IsHitTestVisible="False"/>
                        <Path Data="M 0,3 L -3,0" Stroke="#00E5FF" StrokeThickness="1" HorizontalAlignment="Right" VerticalAlignment="Top" IsHitTestVisible="False"/>
                        <Path Data="M 0,-3 L -3,0" Stroke="#00E5FF" StrokeThickness="1" HorizontalAlignment="Right" VerticalAlignment="Bottom" IsHitTestVisible="False"/>
                    </Grid>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Body" Property="Background" Value="#152E4A"/>
                            <Setter Property="BorderBrush" Value="#00E5FF"/>
                            <Setter Property="Foreground" Value="#E0F7FA"/>
                            <Setter TargetName="InnerBorder" Property="BorderBrush" Value="#6000E5FF"/>
                        </Trigger>
                        <Trigger Property="IsPressed" Value="True">
                            <Setter TargetName="Body" Property="Background" Value="#0A1E33"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style TargetType="ComboBox">
        <Setter Property="Foreground" Value="#E0F7FA"/>
        <Setter Property="Background" Value="#03050A"/>
        <Setter Property="BorderBrush" Value="#00838F"/>
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
                                                   Stroke="#00838F" StrokeThickness="1.5" Data="M 0,1 L 4,5 L 8,1"/>
                                        </Grid>
                                    </Border>
                                    <ControlTemplate.Triggers>
                                        <Trigger Property="IsMouseOver" Value="True">
                                            <Setter TargetName="Border" Property="Background" Value="#101A30"/>
                                            <Setter TargetName="Border" Property="BorderBrush" Value="#00E5FF"/>
                                            <Setter TargetName="Arrow" Property="Stroke" Value="#00E5FF"/>
                                            <Setter TargetName="Arrow" Property="Effect">
                                                <Setter.Value>
                                                    <DropShadowEffect Color="#00E5FF" BlurRadius="4" ShadowDepth="0"/>
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
                                <Border Name="DropDownBorder" Background="#03050A" BorderBrush="#00838F" BorderThickness="1" CornerRadius="0" />
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
        <Setter Property="Background" Value="#03050A"/>
        <Setter Property="Foreground" Value="#E0F7FA"/>
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
                            <Setter TargetName="Bg" Property="Background" Value="#00838F"/>
                            <Setter Property="Foreground" Value="White"/>
                        </Trigger>
                        <Trigger Property="IsSelected" Value="True">
                            <Setter TargetName="Bg" Property="Background" Value="#004D5A"/>
                            <Setter Property="Foreground" Value="White"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <!-- Phase 2 Sci-Fi God Rays, Rivet (LED), and Bracket Styles -->
    
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
        <Setter Property="Width" Value="5"/>
        <Setter Property="Height" Value="5"/>
        <Setter Property="Fill" Value="#00E5FF"/>
        <Setter Property="Stroke" Value="#004D40"/>
        <Setter Property="StrokeThickness" Value="0.5"/>
        <Setter Property="Effect">
            <Setter.Value>
                <DropShadowEffect Color="#00E5FF" BlurRadius="8" ShadowDepth="0" Opacity="1.0"/>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="BracketStyle" TargetType="Path">
        <Setter Property="Fill" Value="{StaticResource CyberCyanBrush}"/>
        <Setter Property="Stroke" Value="#00838F"/>
        <Setter Property="StrokeThickness" Value="1"/>
        <Setter Property="Effect">
            <Setter.Value>
                <DropShadowEffect Color="#00E5FF" BlurRadius="6" ShadowDepth="0" Opacity="0.7"/>
            </Setter.Value>
        </Setter>
    </Style>
    
    <Style x:Key="GoldSlider" TargetType="Slider">
        <Setter Property="Background" Value="#0C101B"/>
        <Setter Property="BorderBrush" Value="#1B3B52"/>
        <Setter Property="BorderThickness" Value="1"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Slider">
                    <Grid Margin="0,5">
                        <Border x:Name="TrackBackground" Height="4" CornerRadius="0" Background="#03050A" BorderBrush="#00838F" BorderThickness="1"/>
                        <Track x:Name="PART_Track">
                           <Track.Thumb>
                               <Thumb Width="12" Height="12" Cursor="Hand">
                                   <Thumb.Template>
                                       <ControlTemplate TargetType="Thumb">
                                           <Grid>
                                               <Rectangle Fill="#0C101B" Stroke="#00E5FF" StrokeThickness="1.5"/>
                                               <Rectangle Fill="#00E5FF" Margin="2.5"/>
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
)'

app.main.InjectResources(customStyles)

; Find and restyle default window close/minimize buttons to thematic circles
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
                            <Rectangle x:Name="Box" Stroke="#00838F" StrokeThickness="1.5" Fill="#03050A" RadiusX="2" RadiusY="2"/>
                            <Path x:Name="Symbol" Data="M 0,0 L 8,8 M 8,0 L 0,8" Width="8" Height="8" Stretch="Uniform" Stroke="#FF6D00" StrokeThickness="2.2" HorizontalAlignment="Center" VerticalAlignment="Center" IsHitTestVisible="False"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Box" Property="Stroke" Value="#00E5FF"/>
                                <Setter TargetName="Box" Property="Fill" Value="#1000E5FF"/>
                                <Setter TargetName="Symbol" Property="Stroke" Value="#FF9E00"/>
                                <Setter TargetName="Box" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="#00E5FF" BlurRadius="6" ShadowDepth="0" Opacity="0.8"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Box" Property="Fill" Value="#2000E5FF"/>
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
                            <Rectangle x:Name="Box" Stroke="#00838F" StrokeThickness="1.5" Fill="#03050A" RadiusX="2" RadiusY="2"/>
                            <Path x:Name="Symbol" Data="M 0,0 L 8,0" Width="8" Height="2" Stretch="Uniform" Stroke="#00E5FF" StrokeThickness="2.2" HorizontalAlignment="Center" VerticalAlignment="Center" IsHitTestVisible="False"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Box" Property="Stroke" Value="#00E5FF"/>
                                <Setter TargetName="Box" Property="Fill" Value="#1000E5FF"/>
                                <Setter TargetName="Symbol" Property="Stroke" Value="#00E5FF"/>
                                <Setter TargetName="Box" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="#00E5FF" BlurRadius="6" ShadowDepth="0" Opacity="0.8"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Box" Property="Fill" Value="#2000E5FF"/>
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

; Inner accent border for double-cyan tech pinstripe
innerCyanBdr := windowFrame.Add("Border").Margin("2").BorderThickness("1.5").BorderBrush("#4000E5FF").CornerRadius("0")

; Inner background grid (canvas for atmospheric glow + vector veins)
bgGrid := innerCyanBdr.Add("Grid")
bgGrid.Add("Border").Style("{StaticResource CentralGlow}")
bgGrid.Add("Border").Style("{StaticResource WarmGlow}")

; Add large soft radial splotches for organic tech variations
bgGrid.Add("Border").Style("{StaticResource LightSplotch}")
bgGrid.Add("Border").Style("{StaticResource DarkSplotch}")

; Grain overlay for screen noise/tactile texture
bgGrid.Add("Border").Style("{StaticResource GrainOverlay}")

; Volumetric light rays (God Rays)
bgGrid.Add("Path").Data("M 50,-50 L 150,-50 L 800,650 L 650,650 Z").Style("{StaticResource GodRay1}")
bgGrid.Add("Path").Data("M 200,-50 L 380,-50 L 990,550 L 780,600 Z").Style("{StaticResource GodRay2}")
bgGrid.Add("Path").Data("M -50,50 L -50,180 L 580,650 L 420,650 Z").Style("{StaticResource GodRay2}")

; Scanline overlay layer with Flicker binding name
bgGrid.Add("Border").Name("bgFlickerLayer").Background("{StaticResource ScanlineBrush}").SetProp("IsHitTestVisible", "False").Opacity("0.95")

; Futuristic Tech Inlay Border Path (octagonal chamfered)
bgGrid.Add("Path").Data("M 30,16 L 455,16 L 470,31 L 485,16 L 910,16 L 924,30 L 924,285 L 909,300 L 924,315 L 924,570 L 910,584 L 485,584 L 470,569 L 455,584 L 30,584 L 16,570 L 16,315 L 31,300 L 16,285 L 16,30 Z").Stroke("#2000E5FF").StrokeThickness("1.0").SetProp("IsHitTestVisible", "False").Opacity("0.3")

; Glowing radar/HUD circles in the bottom-left background area
bgCircleLeft := bgGrid.Add("Grid").Width(340).Height(340).HorizontalAlignment("Left").VerticalAlignment("Bottom").Margin("50,0,0,50")
bgCircleLeft.SetProp("IsHitTestVisible", "False")
bgCircleLeft.Add("Ellipse").Stroke("#1000E5FF").StrokeThickness("1.5").SetProp("StrokeDashArray", "8 6")
bgCircleLeft.Add("Ellipse").Margin("15").Stroke("#0800E5FF").StrokeThickness("1")
bgCircleLeft.Add("Ellipse").Margin("25").Stroke("#1200E5FF").StrokeThickness("1.5").SetProp("StrokeDashArray", "2 4")
bgCircleLeft.Add("Ellipse").Margin("45").Stroke("#0600838F").StrokeThickness("1")
bgCircleLeft.Add("Path").Data("M 170,15 L 170,325 M 15,170 L 325,170").Stroke("#0800E5FF").StrokeThickness("1")
bgCircleLeft.Add("Path").Data("M 58,58 L 282,282 M 58,282 L 282,58").Stroke("#0600E5FF").StrokeThickness("1")
bgCircleLeft.Add("Ellipse").Margin("136").Fill("#0400E5FF")
bgCircleLeft.Add("Polygon").SetProp("Points", "170,150 185,170 170,190 155,170").Fill("#1000E5FF")

; Secondary larger tactical HUD circles/geometry in upper-right
bgCircleRight := bgGrid.Add("Grid").Width(460).Height(460).HorizontalAlignment("Right").VerticalAlignment("Top").Margin("0,20,-120,0")
bgCircleRight.SetProp("IsHitTestVisible", "False")
bgCircleRight.Add("Ellipse").Stroke("#0A00E5FF").StrokeThickness("1.5").SetProp("StrokeDashArray", "10 8")
bgCircleRight.Add("Ellipse").Margin("25").Stroke("#0600E5FF").StrokeThickness("1")
bgCircleRight.Add("Ellipse").Margin("50").Stroke("#0600E5FF").StrokeThickness("1").SetProp("StrokeDashArray", "4 4")
bgCircleRight.Add("Path").Data("M 230,10 L 230,450 M 10,230 L 450,230").Stroke("#0600E5FF").StrokeThickness("1")
bgCircleRight.Add("Path").Data("M 77,77 L 383,383 M 77,383 L 383,77").Stroke("#0400E5FF").StrokeThickness("1")
bgCircleRight.Add("Polygon").SetProp("Points", "230,25 435,230 230,435 25,230").Stroke("#0600E5FF").StrokeThickness("1")
bgCircleRight.Add("Polygon").SetProp("Points", "85,85 375,85 375,375 85,375").Stroke("#0600E5FF").StrokeThickness("1")

; Sleek Sci-Fi chamfered corner brackets (instead of RPG ornaments)
; Top-Left Corner
bgGrid.Add("Path").Data("M 0,40 L 0,0 L 40,0 L 40,8 L 12,8 L 8,12 L 8,40 Z").Style("{StaticResource BracketStyle}").HorizontalAlignment("Left").VerticalAlignment("Top").Margin("4,4,0,0").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Left").VerticalAlignment("Top").Margin("25,6,0,0").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Left").VerticalAlignment("Top").Margin("6,25,0,0").SetProp("IsHitTestVisible", "False")

; Top-Right Corner
bgGrid.Add("Path").Data("M 40,40 L 40,0 L 0,0 L 0,8 L 28,8 L 32,12 L 32,40 Z").Style("{StaticResource BracketStyle}").HorizontalAlignment("Right").VerticalAlignment("Top").Margin("0,4,4,0").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Right").VerticalAlignment("Top").Margin("0,6,25,0").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Right").VerticalAlignment("Top").Margin("0,25,6,0").SetProp("IsHitTestVisible", "False")

; Bottom-Left Corner
bgGrid.Add("Path").Data("M 0,0 L 0,40 L 40,40 L 40,32 L 12,32 L 8,28 L 8,0 Z").Style("{StaticResource BracketStyle}").HorizontalAlignment("Left").VerticalAlignment("Bottom").Margin("4,0,0,4").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Left").VerticalAlignment("Bottom").Margin("25,0,0,6").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Left").VerticalAlignment("Bottom").Margin("6,0,0,25").SetProp("IsHitTestVisible", "False")

; Bottom-Right Corner
bgGrid.Add("Path").Data("M 40,0 L 40,40 L 0,40 L 0,32 L 28,32 L 32,28 L 32,0 Z").Style("{StaticResource BracketStyle}").HorizontalAlignment("Right").VerticalAlignment("Bottom").Margin("0,0,4,4").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Right").VerticalAlignment("Bottom").Margin("0,0,25,6").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Ellipse").Style("{StaticResource RivetStyle}").HorizontalAlignment("Right").VerticalAlignment("Bottom").Margin("0,0,6,25").SetProp("IsHitTestVisible", "False")

; Glowing Rectilinear Circuit Tracks (Futuristic cyber traces)
bgGrid.Add("Path").Data("M -50,150 L 200,150 L 250,200 L 400,200 L 450,150 L 600,150 L 650,200 L 990,200").Stroke("#1500E5FF").StrokeThickness("4").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Path").Data("M -50,150 L 200,150 L 250,200 L 400,200 L 450,150 L 600,150 L 650,200 L 990,200").Stroke("#8000E5FF").StrokeThickness("1").SetProp("IsHitTestVisible", "False")

bgGrid.Add("Path").Data("M 150,-50 L 150,100 L 200,150 L 200,450 L 250,500 L 250,650").Stroke("#1500E5FF").StrokeThickness("3").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Path").Data("M 150,-50 L 150,100 L 200,150 L 200,450 L 250,500 L 250,650").Stroke("#8000E5FF").StrokeThickness("0.8").SetProp("IsHitTestVisible", "False")

bgGrid.Add("Path").Data("M 990,100 L 750,100 L 700,150 L 700,400 L 650,450 L -50,450").Stroke("#1500E5FF").StrokeThickness("3").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Path").Data("M 990,100 L 750,100 L 700,150 L 700,400 L 650,450 L -50,450").Stroke("#8000E5FF").StrokeThickness("0.8").SetProp("IsHitTestVisible", "False")

; Glowing Circuit Junction Nodes (Diamond markers)
bgGrid.Add("Path").Data("M 197,150 L 200,147 L 203,150 L 200,153 Z").Fill("#00E5FF").Stroke("#004D40").StrokeThickness("0.5").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Path").Data("M 397,200 L 400,197 L 403,200 L 400,203 Z").Fill("#00E5FF").Stroke("#004D40").StrokeThickness("0.5").SetProp("IsHitTestVisible", "False")
bgGrid.Add("Path").Data("M 697,400 L 700,397 L 703,400 L 700,403 Z").Fill("#00E5FF").Stroke("#004D40").StrokeThickness("0.5").SetProp("IsHitTestVisible", "False")

; Generate Sci-Fi Grid overlay
GenerateSciFiGrid(bgGrid)

; Tech cyan separator line below the title bar with a center diamond notch and glow
app.main.Add("Path").Grid_Row(0).VerticalAlignment("Bottom").Height("12").Margin("6,0,0,0").Data("M 0,2 L 440,2 L 448,5 L 458,5 L 470,11 L 482,5 L 492,5 L 500,2 L 940,2").Stroke("#8000E5FF").StrokeThickness("1.5").SetProp("IsHitTestVisible", "False")

; ==============================================================================
; CONTENT AREAS AND COLUMN PRE-SETTING
; ==============================================================================

contentGrid := app.main.Add("Grid").Grid_Row(1).Margin("25,10,25,10")
contentGrid.Cols("190", "20", "*")
contentGrid.Rows("Auto", "*", "Auto", "Auto")

; Clean centered futuristic title block
contentGrid.Add("TextBlock").Grid_Row(0).Grid_Column(0).Grid_ColumnSpan(3).Text("SYSTEM CONFIGURATION").FontFamily("Segoe UI").FontSize(22).FontWeight("SemiBold").Foreground("#00E5FF").HorizontalAlignment("Center").Margin("0,10,0,15")

; Sidebar StackPanel on Column 0, Row 1
sidebarSp := contentGrid.Add("StackPanel").Grid_Column(0).Grid_Row(1)

; Categories stack
AddSidebarButton(sp, name, label, isFirst := false) {
    btn := sp.Add("Button").Name("BtnNav" name).Style("{StaticResource OrnateButton}").Height(38).Margin("0,0,0,10")
    btnGrid := btn.Add("Grid")
    btnGrid.Cols("Auto", "*")
    
    indText := isFirst ? "▶" : "  "
    indColor := isFirst ? "#00E5FF" : "#64B5F6"
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
    lbl.InjectResources('<Style TargetType="TextBlock"><Setter Property="Foreground" Value="#CBD5E1"/><Style.Triggers><DataTrigger Binding="{Binding IsChecked, ElementName=' name '}" Value="True"><Setter Property="Foreground" Value="#F0F9FF"/><Setter Property="Effect"><Setter.Value><DropShadowEffect Color="#00E5FF" BlurRadius="6" ShadowDepth="0" Opacity="0.9"/></Setter.Value></Setter></DataTrigger></Style.Triggers></Style>')

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
    lbl.InjectResources('<Style TargetType="TextBlock"><Setter Property="Foreground" Value="#CBD5E1"/><Style.Triggers><DataTrigger Binding="{Binding IsChecked, ElementName=TglAutoRun}" Value="True"><Setter Property="Foreground" Value="#F0F9FF"/><Setter Property="Effect"><Setter.Value><DropShadowEffect Color="#00E5FF" BlurRadius="6" ShadowDepth="0" Opacity="0.9"/></Setter.Value></Setter></DataTrigger></Style.Triggers></Style>')

    rightSp := rowGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(1).VerticalAlignment("Center")

    setupBtn := rightSp.Add("Button").Name("BtnSetupShortcut").Content("Setup").Background("Transparent").Foreground("#00E5FF").BorderThickness("0").Cursor("Hand").FontWeight("Bold").Margin("0,0,8,0").VerticalAlignment("Center")
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
    leftSp.Add("TextBlock").Name(name "Val").Text(String(currentVal) suffix).Foreground("#00E5FF").FontSize(13).FontWeight("Bold").VerticalAlignment("Center")

    rightSp := rowGrid.Add("StackPanel").Orientation("Horizontal").Grid_Column(1).VerticalAlignment("Center")
    rightSp.Add("Slider").Name(name).Style("{StaticResource GoldSlider}").Width(150).Height(24).Minimum(minVal).Maximum(maxVal).Value(String(currentVal)).Margin("0,0,8,0")

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

    iconColor := "#00E5FF"
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
ui.OnEvent("LinkAbout", "Click", (*) => ShowCustomDialog({ Title: "About Game Settings", Message: "Game Settings Configurator Demo v2.0`nCreated with AHK-XAML RPG vector style.`n`nRedesigned with multi-page category selector sidebar.", Icon: Chr(0xE7E7), IconColor: "#FF4D4D", Owner: ui.wpfHwnd, Modal: true }))

; Dynamically bind all info buttons
for infoBtnName, descObj in infoDescriptions {
    ui.OnEvent(infoBtnName, "Click", OnInfoClick)
}

SwitchCategory(cat) {
    categories := ["Gameplay", "Controls", "Graphics", "Audio"]
    for c in categories {
        if (c == cat) {
            ui.Update("Panel" c, "Visibility", "Visible")
            ui.Update("Ind" c, "Text", "✦")
            ui.Update("Ind" c, "Foreground", "#00E5FF")
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
            IconColor: "#00E5FF",
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
        IconColor: "#00E5FF",
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

SetTimer(FlickerTimer, 120)
app.Show()

FlickerTimer() {
    try {
        ; Slightly fluctuate opacity to simulate scanline flicker
        val := Format("{1:.3f}", Random(88, 100) / 100.0)
        ui.Update("bgFlickerLayer", "Opacity", val)
    }
}