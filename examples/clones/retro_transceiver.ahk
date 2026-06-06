#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Components.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"

; ==============================================================================
#Requires AutoHotkey v2.0
#SingleInstance Force

; --- GLOBALS & APP STATE ---
global PowerOn := true
global CurrentFreq := 14.23000   ; Default frequency (20m SSTV)
global CurrentBand := "20m"
global CurrentMode := "USB"
global AFGainVal := 65           ; Volume (0..100)
global SquelchVal := 15          ; Squelch (0..100)
global RfGainVal := 80           ; RF Gain (0..100)
global CarrierVal := 50          ; Carrier power (0..100)
global AttActive := false
global NoiseBlankerActive := true
global LockActive := false

global VfoOldValue := 0
global VfoResetting := false
global LogBuffer := []

; Theme definitions mapping
global ThemeDefinitions := Map()
global ThemeNames := []

; --- BAND PRESETS ---
global BandPresets := Map(
    "80m", { Min: 3.500, Max: 4.000, Freq: 3.820, Label: "3.5 - 4.0 MHz" },
    "40m", { Min: 7.000, Max: 7.300, Freq: 7.150, Label: "7.0 - 7.3 MHz" },
    "20m", { Min: 14.000, Max: 14.350, Freq: 14.230, Label: "14.0 - 14.35 MHz" },
    "15m", { Min: 21.000, Max: 21.450, Freq: 21.300, Label: "21.0 - 21.45 MHz" },
    "10m", { Min: 28.000, Max: 29.700, Freq: 28.500, Label: "28.0 - 29.7 MHz" }
)

; --- SIMULATED STATIONS ---
global Stations := [{ Freq: 3.550, Name: "CW Practice Net", Signal: 60, Mode: "CW" }, { Freq: 3.820, Name: "Nets & Ragchews", Signal: 75, Mode: "LSB" }, { Freq: 7.030, Name: "QRP CW Calling", Signal: 50, Mode: "CW" }, { Freq: 7.150, Name: "40m Ragchew Net", Signal: 82, Mode: "LSB" }, { Freq: 14.070, Name: "FT8 Digital Mode", Signal: 90, Mode: "USB" }, { Freq: 14.230, Name: "SSTV Image Net", Signal: 72, Mode: "USB" }, { Freq: 14.300, Name: "Maritime Mobile", Signal: 95, Mode: "USB" }, { Freq: 21.074, Name: "FT8 DX Calling", Signal: 65, Mode: "USB" }, { Freq: 21.285, Name: "15m DX Calling", Signal: 80, Mode: "USB" }, { Freq: 28.074, Name: "10m FT8 Digital", Signal: 55, Mode: "USB" }, { Freq: 28.500, Name: "10m SSB Calling", Signal: 75, Mode: "USB" }
]

; ==============================================================================
; LOAD THEMES FROM INI
; ==============================================================================
LoadThemes() {
    iniPath := FileExist("themes.ini") ? "themes.ini" : (FileExist("..\themes.ini") ? "..\themes.ini" : (FileExist("..\..\themes.ini") ? "..\..\themes.ini" : (FileExist("examples\themes.ini") ? "examples\themes.ini" : "..\examples\themes.ini")))
    if !FileExist(iniPath) {
        iniPath := "c:\projects\ahk\ahk-xaml\examples\themes.ini"
    }
    if !FileExist(iniPath) {
        MsgBox("themes.ini not found! Please place it in the same directory or configure the path.", "Error", "IconX")
        ExitApp()
    }

    sections := IniRead(iniPath)
    Loop Parse, sections, "`n", "`r" {
        themeName := A_LoopField
        if (themeName == "")
            continue
        themeMap := Map()
        themeData := IniRead(iniPath, themeName)
        Loop Parse, themeData, "`n", "`r" {
            parts := StrSplit(A_LoopField, "=", " `t", 2)
            if (parts.Length == 2) {
                themeMap[parts[1]] := parts[2]
            }
        }
        ThemeDefinitions[themeName] := themeMap
        ThemeNames.Push(themeName)
    }
}
LoadThemes()

; ==============================================================================
; CREATE BASE WINDOW AND SETUP INJECTED RESOURCES
; ==============================================================================
app := XAML_GUI("Aether-9000 Transceiver", { Sidebar: false, BurgerMenu: false, TitleBarHeight: 40, AppIcon: false, Width: 840, Height: 520, Resize: false })
app.SkipDefaultThemeOnLoad := true
app.X.Background("Transparent")
app.tabs.Visibility("Collapsed")
app.main.Background("Transparent")

customStyles := '
(
    <!-- Window Frame Backplate -->
    <Style x:Key="WindowFrameStyle" TargetType="Border">
        <Setter Property="CornerRadius" Value="12"/>
        <Setter Property="BorderThickness" Value="4"/>
        <Setter Property="BorderBrush">
            <Setter.Value>
                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                    <GradientStop Color="#555555" Offset="0.0"/>
                    <GradientStop Color="#CCCCCC" Offset="0.3"/>
                    <GradientStop Color="#222222" Offset="0.7"/>
                    <GradientStop Color="#888888" Offset="1.0"/>
                </LinearGradientBrush>
            </Setter.Value>
        </Setter>
        <Setter Property="Background" Value="{DynamicResource BgColor}"/>
    </Style>
    
    <!-- Metallic Separator lines -->
    <Style x:Key="ChassisBezelLine" TargetType="Path">
        <Setter Property="Stroke" Value="{DynamicResource ControlBorder}"/>
        <Setter Property="StrokeThickness" Value="1.5"/>
        <Setter Property="Opacity" Value="0.6"/>
    </Style>
    
    <!-- Titlebar Buttons Styles -->
    <Style x:Key="TitleMinBtn" TargetType="Border">
        <Setter Property="Background" Value="#FFBD2E"/>
        <Style.Triggers>
            <Trigger Property="IsMouseOver" Value="True">
                <Setter Property="Background" Value="#DF9F10"/>
            </Trigger>
        </Style.Triggers>
    </Style>
    <Style x:Key="TitleCloseBtn" TargetType="Border">
        <Setter Property="Background" Value="#FF5F56"/>
        <Style.Triggers>
            <Trigger Property="IsMouseOver" Value="True">
                <Setter Property="Background" Value="#E0433C"/>
            </Trigger>
        </Style.Triggers>
    </Style>
    
    <!-- Large Rotary Tuning Knob (VFO) -->
    <Style x:Key="LargeKnobStyle" TargetType="Slider">
        <Setter Property="Background" Value="Transparent"/>
        <Setter Property="BorderBrush" Value="Transparent"/>
        <Setter Property="IsMoveToPointEnabled" Value="True"/>
        <Setter Property="Orientation" Value="Horizontal"/>
        <Setter Property="Width" Value="86"/>
        <Setter Property="Height" Value="86"/>
        <Setter Property="Minimum" Value="-135"/>
        <Setter Property="Maximum" Value="135"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Slider">
                    <Grid Background="Transparent">
                        <!-- Ticks Bezel -->
                        <Ellipse Margin="2" Stroke="{DynamicResource Accent}" StrokeThickness="1" StrokeDashArray="2,4" IsHitTestVisible="False" Opacity="0.45"/>
                        <Ellipse Margin="6" Fill="#0A0B0E" Stroke="{DynamicResource ControlBorder}" StrokeThickness="2" IsHitTestVisible="False"/>
                        
                        <!-- Rotating Dial -->
                        <Grid x:Name="VisualKnob" Width="66" Height="66" RenderTransformOrigin="0.5,0.5" IsHitTestVisible="False">
                            <Grid.RenderTransform>
                                <RotateTransform Angle="{Binding Value, RelativeSource={RelativeSource TemplatedParent}}" />
                            </Grid.RenderTransform>
                            
                            <!-- Brushed Metal Radial Face -->
                            <Ellipse>
                                <Ellipse.Fill>
                                    <RadialGradientBrush Center="0.5,0.5" RadiusX="0.5" RadiusY="0.5" GradientOrigin="0.3,0.3">
                                        <GradientStop Color="#6B7280" Offset="0"/>
                                        <GradientStop Color="#1F2937" Offset="0.8"/>
                                        <GradientStop Color="#030712" Offset="1"/>
                                    </RadialGradientBrush>
                                </Ellipse.Fill>
                                <Ellipse.Effect>
                                    <DropShadowEffect Color="#000" BlurRadius="8" ShadowDepth="4" Opacity="0.7"/>
                                </Ellipse.Effect>
                            </Ellipse>
                            
                            <!-- Accent highlight rim -->
                            <Ellipse Margin="5" Stroke="{DynamicResource Accent}" StrokeThickness="0.6" Opacity="0.4"/>
                            
                            <!-- Concentric inner indent -->
                            <Ellipse Margin="14" Fill="#111318" Stroke="#222" StrokeThickness="1"/>
                            
                            <!-- Finger crank indent (classic radio styling) -->
                            <Ellipse Width="12" Height="12" Fill="#07080A" Stroke="#444" StrokeThickness="1" VerticalAlignment="Top" HorizontalAlignment="Center" Margin="0,8,0,0"/>
                            
                            <!-- Indicator pointer notch -->
                            <Rectangle Width="3.5" Height="10" Fill="{DynamicResource Accent}" RadiusX="1" RadiusY="1" VerticalAlignment="Top" HorizontalAlignment="Center" Margin="0,2,0,0"/>
                        </Grid>
                        
                        <!-- Invisible active slider track -->
                        <Track x:Name="PART_Track" Margin="8,0,8,0">
                            <Track.DecreaseRepeatButton>
                                <RepeatButton Background="Transparent" BorderBrush="Transparent" Command="{x:Static Slider.DecreaseLarge}" Focusable="False" Opacity="0"/>
                            </Track.DecreaseRepeatButton>
                            <Track.Thumb>
                                <Thumb Width="66" Height="66" Focusable="False">
                                    <Thumb.Template>
                                        <ControlTemplate TargetType="Thumb">
                                            <Ellipse Fill="#01000000" Cursor="SizeWE"/>
                                        </ControlTemplate>
                                    </Thumb.Template>
                                </Thumb>
                            </Track.Thumb>
                            <Track.IncreaseRepeatButton>
                                <RepeatButton Background="Transparent" BorderBrush="Transparent" Command="{x:Static Slider.IncreaseLarge}" Focusable="False" Opacity="0"/>
                            </Track.IncreaseRepeatButton>
                        </Track>
                    </Grid>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <!-- Small Rotary Knob Style -->
    <Style x:Key="SmallKnobStyle" TargetType="Slider">
        <Setter Property="Background" Value="Transparent"/>
        <Setter Property="BorderBrush" Value="Transparent"/>
        <Setter Property="IsMoveToPointEnabled" Value="True"/>
        <Setter Property="Orientation" Value="Horizontal"/>
        <Setter Property="Width" Value="52"/>
        <Setter Property="Height" Value="52"/>
        <Setter Property="Minimum" Value="-135"/>
        <Setter Property="Maximum" Value="135"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="Slider">
                    <Grid Background="Transparent">
                        <!-- Ticks Bezel -->
                        <Ellipse Margin="1" Stroke="{DynamicResource Accent}" StrokeThickness="0.8" StrokeDashArray="2,3" IsHitTestVisible="False" Opacity="0.35"/>
                        <Ellipse Margin="4" Fill="#0E1013" Stroke="{DynamicResource ControlBorder}" StrokeThickness="1.5" IsHitTestVisible="False"/>
                        
                        <!-- Rotating Dial -->
                        <Grid x:Name="VisualKnob" Width="36" Height="36" RenderTransformOrigin="0.5,0.5" IsHitTestVisible="False">
                            <Grid.RenderTransform>
                                <RotateTransform Angle="{Binding Value, RelativeSource={RelativeSource TemplatedParent}}" />
                            </Grid.RenderTransform>
                            
                            <!-- Knob Cap -->
                            <Ellipse>
                                <Ellipse.Fill>
                                    <RadialGradientBrush Center="0.5,0.5" RadiusX="0.5" RadiusY="0.5" GradientOrigin="0.3,0.3">
                                        <GradientStop Color="#4B5563" Offset="0"/>
                                        <GradientStop Color="#111827" Offset="0.8"/>
                                        <GradientStop Color="#030712" Offset="1"/>
                                    </RadialGradientBrush>
                                </Ellipse.Fill>
                                <Ellipse.Effect>
                                    <DropShadowEffect Color="#000" BlurRadius="4" ShadowDepth="2" Opacity="0.6"/>
                                </Ellipse.Effect>
                            </Ellipse>
                            
                            <!-- Indicator dot -->
                            <Ellipse Width="3" Height="3" Fill="{DynamicResource Accent}" VerticalAlignment="Top" HorizontalAlignment="Center" Margin="0,3,0,0"/>
                        </Grid>
                        
                        <!-- Invisible active slider track -->
                        <Track x:Name="PART_Track" Margin="6,0,6,0">
                            <Track.DecreaseRepeatButton>
                                <RepeatButton Background="Transparent" BorderBrush="Transparent" Command="{x:Static Slider.DecreaseLarge}" Focusable="False" Opacity="0"/>
                            </Track.DecreaseRepeatButton>
                            <Track.Thumb>
                                <Thumb Width="36" Height="36" Focusable="False">
                                    <Thumb.Template>
                                        <ControlTemplate TargetType="Thumb">
                                            <Ellipse Fill="#01000000" Cursor="SizeWE"/>
                                        </ControlTemplate>
                                    </Thumb.Template>
                                </Thumb>
                            </Track.Thumb>
                            <Track.IncreaseRepeatButton>
                                <RepeatButton Background="Transparent" BorderBrush="Transparent" Command="{x:Static Slider.IncreaseLarge}" Focusable="False" Opacity="0"/>
                            </Track.IncreaseRepeatButton>
                        </Track>
                    </Grid>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <!-- Satisfying Vertical Metallic Toggle Switch -->
    <Style x:Key="RetroToggleStyle" TargetType="CheckBox">
        <Setter Property="Background" Value="Transparent"/>
        <Setter Property="BorderBrush" Value="Transparent"/>
        <Setter Property="Width" Value="32"/>
        <Setter Property="Height" Value="52"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="CheckBox">
                    <Grid Background="Transparent" Cursor="Hand">
                        <!-- Metallic Outer Bezel Plate -->
                        <Border Width="24" Height="44" CornerRadius="4" BorderThickness="1.5">
                            <Border.BorderBrush>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                    <GradientStop Color="#FFF0F0F0" Offset="0.0"/>
                                    <GradientStop Color="#FFA0A0A0" Offset="0.2"/>
                                    <GradientStop Color="#FFFFFFFF" Offset="0.4"/>
                                    <GradientStop Color="#FF505050" Offset="0.7"/>
                                    <GradientStop Color="#FFD0D0D0" Offset="1.0"/>
                                </LinearGradientBrush>
                            </Border.BorderBrush>
                            <Border.Background>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                    <GradientStop Color="#FFB8B8B8" Offset="0"/>
                                    <GradientStop Color="#FF8A8A8A" Offset="0.3"/>
                                    <GradientStop Color="#FF5C5C5C" Offset="0.7"/>
                                    <GradientStop Color="#FFA3A3A3" Offset="1"/>
                                </LinearGradientBrush>
                            </Border.Background>
                            <Border.Effect>
                                <DropShadowEffect Color="#000" BlurRadius="4" ShadowDepth="2" Opacity="0.5"/>
                            </Border.Effect>
                        </Border>

                        <!-- Recessed Slot Groove -->
                        <Border Width="12" Height="32" CornerRadius="6" BorderBrush="#FF333333" BorderThickness="1">
                            <Border.Background>
                                <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                    <GradientStop Color="#050505" Offset="0"/>
                                    <GradientStop Color="#1A1A1A" Offset="0.5"/>
                                    <GradientStop Color="#050505" Offset="1"/>
                                </LinearGradientBrush>
                            </Border.Background>
                        </Border>

                        <!-- Glowing Slot Background -->
                        <Border x:Name="SlotGlow" Width="10" Height="30" CornerRadius="5" Background="{DynamicResource Accent}" Opacity="0">
                            <Border.Effect>
                                <BlurEffect Radius="5"/>
                            </Border.Effect>
                        </Border>

                        <!-- The Pivoting Lever -->
                        <Grid x:Name="Lever" Width="10" Height="16" VerticalAlignment="Top" Margin="0,10,0,0" RenderTransformOrigin="0.5,1.0">
                            <Grid.RenderTransform>
                                <ScaleTransform x:Name="LeverScale" ScaleY="-1.0"/>
                            </Grid.RenderTransform>

                            <!-- Lever Shaft (tapered) -->
                            <Path Data="M 3,16 L 7,16 L 9,4 L 1,4 Z" Stretch="Fill" Margin="1,2,1,0">
                                <Path.Fill>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,0">
                                        <GradientStop Color="#FFA0A0A0" Offset="0.0"/>
                                        <GradientStop Color="#FFEAEAEA" Offset="0.3"/>
                                        <GradientStop Color="#FFFFFFFF" Offset="0.5"/>
                                        <GradientStop Color="#FF707070" Offset="0.8"/>
                                        <GradientStop Color="#FF404040" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Path.Fill>
                            </Path>

                            <!-- Shiny Chrome Tip -->
                            <Ellipse Width="10" Height="8" VerticalAlignment="Top" HorizontalAlignment="Center">
                                <Ellipse.Fill>
                                    <RadialGradientBrush Center="0.35,0.35" RadiusX="0.6" RadiusY="0.6">
                                        <GradientStop Color="#FFFFFFFF" Offset="0.0"/>
                                        <GradientStop Color="#FFCCCCCC" Offset="0.3"/>
                                        <GradientStop Color="#FF777777" Offset="0.7"/>
                                        <GradientStop Color="#FF222222" Offset="1.0"/>
                                    </RadialGradientBrush>
                                </Ellipse.Fill>
                                <Ellipse.Effect>
                                    <DropShadowEffect Color="#000" BlurRadius="2" ShadowDepth="1" Opacity="0.4"/>
                                </Ellipse.Effect>
                            </Ellipse>
                        </Grid>

                        <!-- Hinge socket cover (drawn on top at the center to hide the pivot seam) -->
                        <Ellipse Width="12" Height="8" Fill="#1E2025" Stroke="#3A3F47" StrokeThickness="1" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                    </Grid>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsChecked" Value="True">
                            <Trigger.EnterActions>
                                <BeginStoryboard>
                                    <Storyboard>
                                        <DoubleAnimation Storyboard.TargetName="LeverScale" Storyboard.TargetProperty="ScaleY" To="1.0" Duration="0:0:0.12">
                                            <DoubleAnimation.EasingFunction>
                                                <BackEase Amplitude="0.3" EasingMode="EaseOut"/>
                                            </DoubleAnimation.EasingFunction>
                                        </DoubleAnimation>
                                        <DoubleAnimation Storyboard.TargetName="SlotGlow" Storyboard.TargetProperty="Opacity" To="0.6" Duration="0:0:0.12"/>
                                    </Storyboard>
                                </BeginStoryboard>
                            </Trigger.EnterActions>
                            <Trigger.ExitActions>
                                <BeginStoryboard>
                                    <Storyboard>
                                        <DoubleAnimation Storyboard.TargetName="LeverScale" Storyboard.TargetProperty="ScaleY" To="-1.0" Duration="0:0:0.12">
                                            <DoubleAnimation.EasingFunction>
                                                <BackEase Amplitude="0.3" EasingMode="EaseOut"/>
                                            </DoubleAnimation.EasingFunction>
                                        </DoubleAnimation>
                                        <DoubleAnimation Storyboard.TargetName="SlotGlow" Storyboard.TargetProperty="Opacity" To="0" Duration="0:0:0.12"/>
                                    </Storyboard>
                                </BeginStoryboard>
                            </Trigger.ExitActions>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <!-- Translucent back-lit push buttons -->
    <Style x:Key="RetroModeBtnStyle" TargetType="RadioButton">
        <Setter Property="Background" Value="{DynamicResource ControlBg}"/>
        <Setter Property="Foreground" Value="{DynamicResource TextSub}"/>
        <Setter Property="BorderBrush" Value="{DynamicResource ControlBorder}"/>
        <Setter Property="BorderThickness" Value="1.5"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="RadioButton">
                    <Grid>
                        <!-- Button Bezel -->
                        <Border x:Name="Border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3" Height="26" Width="44">
                            <Grid>
                                <!-- Accent Color Tint Overlay (Opacity 0 by default, active when checked) -->
                                <Border x:Name="AccentOverlay" Background="{DynamicResource Accent}" Opacity="0" CornerRadius="1.5"/>
                                <!-- Glossy reflection overlay -->
                                <Border x:Name="GlowBorder" CornerRadius="1.5" Margin="0.5" BorderBrush="#15FFFFFF" BorderThickness="0.6" IsHitTestVisible="False"/>
                                <!-- Text content -->
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextBlock.FontSize="10" TextBlock.FontWeight="Bold"/>
                            </Grid>
                        </Border>
                    </Grid>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsChecked" Value="True">
                            <Setter TargetName="AccentOverlay" Property="Opacity" Value="0.25"/>
                            <Setter TargetName="Border" Property="BorderBrush" Value="{DynamicResource Accent}"/>
                            <Setter Property="Foreground" Value="{DynamicResource TextMain}"/>
                        </Trigger>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Border" Property="BorderBrush" Value="{DynamicResource Accent}"/>
                            <Setter Property="Foreground" Value="{DynamicResource TextMain}"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <!-- Band Select Buttons -->
    <Style x:Key="RetroBandBtnStyle" TargetType="RadioButton">
        <Setter Property="Background" Value="{DynamicResource ControlBg}"/>
        <Setter Property="Foreground" Value="{DynamicResource TextSub}"/>
        <Setter Property="BorderBrush" Value="{DynamicResource ControlBorder}"/>
        <Setter Property="BorderThickness" Value="1.5"/>
        <Setter Property="Cursor" Value="Hand"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="RadioButton">
                    <Grid>
                        <Border x:Name="Border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="2" Height="24" Width="42">
                            <Grid>
                                <Border x:Name="AccentOverlay" Background="{DynamicResource Accent}" Opacity="0" CornerRadius="1"/>
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" TextBlock.FontSize="9" TextBlock.FontWeight="Bold"/>
                            </Grid>
                        </Border>
                    </Grid>
                    <ControlTemplate.Triggers>
                        <Trigger Property="IsChecked" Value="True">
                            <Setter TargetName="AccentOverlay" Property="Opacity" Value="0.25"/>
                            <Setter TargetName="Border" Property="BorderBrush" Value="{DynamicResource Accent}"/>
                            <Setter Property="Foreground" Value="{DynamicResource TextMain}"/>
                        </Trigger>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter TargetName="Border" Property="BorderBrush" Value="{DynamicResource Accent}"/>
                            <Setter Property="Foreground" Value="{DynamicResource TextMain}"/>
                        </Trigger>
                    </ControlTemplate.Triggers>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    
    <!-- Spectrum progress bars -->
    <Style x:Key="SpecBarStyle" TargetType="ProgressBar">
        <Setter Property="Orientation" Value="Vertical"/>
        <Setter Property="Background" Value="#08090C"/>
        <Setter Property="BorderThickness" Value="0"/>
        <Setter Property="Minimum" Value="0"/>
        <Setter Property="Maximum" Value="100"/>
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="ProgressBar">
                    <Grid x:Name="TemplateRoot">
                        <Border Background="{TemplateBinding Background}" CornerRadius="1"/>
                        <Border x:Name="PART_Track" Background="Transparent" CornerRadius="1">
                            <Border x:Name="PART_Indicator" Background="{TemplateBinding Foreground}" CornerRadius="1" VerticalAlignment="Bottom"/>
                        </Border>
                    </Grid>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
)'
app.main.InjectResources(customStyles)

; ==============================================================================
; CHASSIS PANEL STRUCTURE
; ==============================================================================
windowFrame := app.main.Add("Border").Grid_Row(0).Grid_RowSpan(3).Name("WindowFrame").Style("{StaticResource WindowFrameStyle}")
windowFrame.SetProp("Panel.ZIndex", "-1")

; Double border pinstripe bezel
innerBezel := windowFrame.Add("Border").Margin("2").BorderThickness("1").BorderBrush("#30FFFFFF").CornerRadius("10")
mainGrid := innerBezel.Add("Grid")
mainGrid.Rows("40", "*", "120")

; --- TOP TITLE BAR / CONTROL SYSTEM ---
titleBarGrid := mainGrid.Add("Grid").Grid_Row(0).Name("TitleBarGrid")
titleBarGrid.Cols("*", "Auto")

titleTextSp := titleBarGrid.Add("StackPanel").Orientation("Horizontal").Margin("15,0,0,0").VerticalAlignment("Center")
titleTextSp.Add("Ellipse").Name("IndicatorLed").Width(10).Height(10).Fill("#10B981").Margin("0,0,10,0") ; Glowing Power LED
titleTextSp.Add("TextBlock").Text("AETHER-9000 MULTIBAND TRANSCEIVER").FontFamily("Georgia, Segoe UI").FontSize(13).FontWeight("Bold").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center")

topControlsSp := titleBarGrid.Add("StackPanel").Grid_Column(1).Orientation("Horizontal").VerticalAlignment("Center").Margin("0,0,15,0")

; Add Theme Dropdown inside Titlebar
topControlsSp.Add("TextBlock").Text("THEME:").FontSize(10).FontWeight("Bold").Foreground("{DynamicResource TextSub}").VerticalAlignment("Center").Margin("0,0,8,0")
comboThemes := topControlsSp.Add("ComboBox").Name("ComboThemesList").Width(130).Height(24).VerticalAlignment("Center").Margin("0,0,15,0").SelectedIndex(0).WindowChrome_IsHitTestVisibleInChrome("True")
for tName in ThemeNames {
    comboThemes.Add("ComboBoxItem").Content(tName)
}

; Close/Min control icons
btnClose := app.X.Find("BtnClose")
if btnClose {
    btnClose.Visibility("Collapsed") ; Hide default Windows Close
}
btnMin := app.X.Find("BtnMinimize")
if btnMin {
    btnMin.Visibility("Collapsed") ; Hide default Windows Min
}
appTitle := app.X.Find("AppTitle")
if appTitle {
    appTitle.Visibility("Collapsed") ; Hide default Windows Title
}
dragArea := app.X.Find("DragArea")
if dragArea {
    dragArea.Visibility("Collapsed") ; Collapse default titlebar area so it doesn't intercept clicks
}

; Custom circular red/blue header buttons for extreme retro styling (Borders with CornerRadius to avoid Button CornerRadius XAML ParseException)
topControlsSp.Add("Border").Name("MinButton").Style("{StaticResource TitleMinBtn}").Width(15).Height(15).CornerRadius("7.5").BorderThickness("0").Margin("0,0,8,0").Cursor("Hand").WindowChrome_IsHitTestVisibleInChrome("True")
topControlsSp.Add("Border").Name("CloseButton").Style("{StaticResource TitleCloseBtn}").Width(15).Height(15).CornerRadius("7.5").BorderThickness("0").Cursor("Hand").WindowChrome_IsHitTestVisibleInChrome("True")

; Bezel Divider line
mainGrid.Add("Path").Grid_Row(0).VerticalAlignment("Bottom").Data("M 0,2 L 840,2").Style("{StaticResource ChassisBezelLine}")

; --- MAIN RACK DECK (ROW 1) ---
rackGrid := mainGrid.Add("Grid").Grid_Row(1).Margin("15,10,15,10")
rackGrid.Cols("380", "15", "*")

leftPanel := rackGrid.Add("StackPanel").Grid_Column(0)
rightPanel := rackGrid.Add("Grid").Grid_Column(2)
rightPanel.Cols("1.4*", "1*")

; --- LEFT PANEL: DETAILED DISPLAYS AND STATUS LEDS ---
displaysGrid := leftPanel.Add("Grid")
displaysGrid.Cols("180", "10", "*")

; Analog S-Meter Design
sMeterBdr := displaysGrid.Add("Border").Grid_Column(0).Width(180).Height(110).CornerRadius("4").Background("#111317").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1.5").VerticalAlignment("Center")
sMeterGrid := sMeterBdr.Add("Grid").ClipToBounds("True")

sMeterBacklight := sMeterGrid.Add("Border").Name("MeterBg").Background("#FAF6EE") ; Dial face paper backing
sMeterGlow := sMeterGrid.Add("Border").Name("MeterGlow").Background("{DynamicResource Accent}").Opacity("0.12") ; Dynamic back-lit color wash
; Glossy glass highlight
sMeterGrid.Add("Border").Background("Transparent").SetProp("IsHitTestVisible", "False").InjectResources('<Style TargetType="Border"><Setter Property="Background"><Setter.Value><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#30FFFFFF" Offset="0"/><GradientStop Color="#00FFFFFF" Offset="0.35"/><GradientStop Color="#00000000" Offset="0.8"/><GradientStop Color="#15000000" Offset="1"/></LinearGradientBrush></Setter.Value></Setter></Style>')

sMeterCanvas := sMeterGrid.Add("Canvas").Width(180).Height(110).Margin("0,5,0,0").HorizontalAlignment("Center")
; Main Scale Arc
sMeterCanvas.Add("Path").Stroke("{DynamicResource TextMain}").StrokeThickness("1.5").Data("M 20,80 A 65,65 0 0 1 160,80")
; Scale labels
sMeterCanvas.Add("TextBlock").Text("S1").FontSize(8).Foreground("{DynamicResource TextMain}").FontWeight("Bold").SetProp("Canvas.Left", "14").SetProp("Canvas.Top", "62")
sMeterCanvas.Add("TextBlock").Text("3").FontSize(8).Foreground("{DynamicResource TextMain}").FontWeight("Bold").SetProp("Canvas.Left", "38").SetProp("Canvas.Top", "40")
sMeterCanvas.Add("TextBlock").Text("5").FontSize(8).Foreground("{DynamicResource TextMain}").FontWeight("Bold").SetProp("Canvas.Left", "66").SetProp("Canvas.Top", "25")
sMeterCanvas.Add("TextBlock").Text("7").FontSize(8).Foreground("{DynamicResource TextMain}").FontWeight("Bold").SetProp("Canvas.Left", "93").SetProp("Canvas.Top", "23")
sMeterCanvas.Add("TextBlock").Text("9").FontSize(8).Foreground("{DynamicResource TextMain}").FontWeight("Bold").SetProp("Canvas.Left", "122").SetProp("Canvas.Top", "28")
sMeterCanvas.Add("TextBlock").Text("+20").FontSize(7.5).Foreground("#DC2626").FontWeight("Bold").SetProp("Canvas.Left", "144").SetProp("Canvas.Top", "52")
sMeterCanvas.Add("TextBlock").Text("dB").FontSize(7.5).Foreground("#DC2626").FontWeight("Bold").SetProp("Canvas.Left", "156").SetProp("Canvas.Top", "68")
sMeterCanvas.Add("TextBlock").Text("SIGNAL").FontSize(8).Foreground("{DynamicResource TextSub}").FontWeight("Bold").SetProp("Canvas.Left", "74").SetProp("Canvas.Top", "50")

; Pivot center screw
sMeterCanvas.Add("Ellipse").Width(12).Height(12).Fill("{DynamicResource ControlBg}").Stroke("{DynamicResource ControlBorder}").StrokeThickness("1").SetProp("Canvas.Left", "84").SetProp("Canvas.Top", "86")
sMeterCanvas.Add("Line").X1("0").Y1("0").X2("8").Y2("0").Stroke("{DynamicResource TextSub}").StrokeThickness("1.5").SetProp("Canvas.Left", "86").SetProp("Canvas.Top", "92")

; The Rotating Needle
sMeterNeedle := sMeterCanvas.Add("Line").Name("SMeterNeedle").X1("90").Y1("92").X2("90").Y2("18").Stroke("#111").StrokeThickness("1.6")
sMeterNeedle.Add("Line.RenderTransform").Add("RotateTransform").SetProp("x:Name", "MeterNeedleRotate").CenterX(90).CenterY(92).Angle(-38)

; Digital VFD Frequency readout display
vfdBdr := displaysGrid.Add("Border").Grid_Column(2).Width(190).Height(110).CornerRadius("4").Background("#040608").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1.5").VerticalAlignment("Center")
vfdGrid := vfdBdr.Add("Grid").ClipToBounds("True")

; Grid mesh overlay for authentic glass cathode VFD tubes
vfdGrid.Add("Border").SetProp("IsHitTestVisible", "False").InjectResources('<Style TargetType="Border"><Setter Property="Opacity" Value="0.05"/><Setter Property="Background"><Setter.Value><DrawingBrush TileMode="Tile" Viewport="0,0,3,3" ViewportUnits="Absolute"><DrawingBrush.Drawing><GeometryDrawing Brush="#FFF"><GeometryDrawing.Geometry><RectangleGeometry Rect="0,0,1,1"/></GeometryDrawing.Geometry></GeometryDrawing></DrawingBrush.Drawing></DrawingBrush></Setter.Value></Setter></Style>')
; Volumetric glass gloss
vfdGrid.Add("Border").Background("Transparent").SetProp("IsHitTestVisible", "False").InjectResources('<Style TargetType="Border"><Setter Property="Background"><Setter.Value><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="#1EFFFFFF" Offset="0"/><GradientStop Color="#00FFFFFF" Offset="0.3"/><GradientStop Color="#00000000" Offset="0.8"/><GradientStop Color="#0F000000" Offset="1"/></LinearGradientBrush></Setter.Value></Setter></Style>')

vfdSp := vfdGrid.Add("StackPanel").Margin("10,6,10,6")

; VFD top row indicators
vfdTopGrid := vfdSp.Add("Grid")
vfdTopGrid.Cols("*", "Auto")
vfdStatusSp := vfdTopGrid.Add("StackPanel").Grid_Column(0).Orientation("Horizontal")
vfdStatusSp.Add("TextBlock").Name("VfdVfoA").Text("VFO-A").FontSize(9).FontWeight("Bold").Foreground("{DynamicResource Accent}").Margin("0,0,8,0").Opacity("1.0")
vfdStatusSp.Add("TextBlock").Name("VfdVfoB").Text("VFO-B").FontSize(9).FontWeight("Bold").Foreground("{DynamicResource Accent}").Margin("0,0,8,0").Opacity("0.15")
vfdStatusSp.Add("TextBlock").Name("VfdLock").Text("LOCK").FontSize(9).FontWeight("Bold").Foreground("#EF4444").Margin("0,0,8,0").Opacity("0.15")
vfdStatusSp.Add("TextBlock").Name("VfdAtt").Text("ATT").FontSize(9).FontWeight("Bold").Foreground("#F59E0B").Opacity("0.15")
vfdTopGrid.Add("TextBlock").Name("VfdModeText").Grid_Column(1).Text("USB").FontSize(9).FontWeight("Bold").Foreground("{DynamicResource Accent}").Opacity("0.9")

; VFD Large Numerical display
vfdReadoutGrid := vfdSp.Add("Grid").Margin("0,4,0,0")
vfdReadoutGrid.Add("TextBlock").Name("VfdFreqBg").Text("88.888.88").FontFamily("Consolas").FontSize(32).FontWeight("Bold").Foreground("#08FFFFFF").HorizontalAlignment("Right").VerticalAlignment("Center")
vfdReadout := vfdReadoutGrid.Add("TextBlock").Name("VfdFreq").Text("14.230.00").FontFamily("Consolas").FontSize(32).FontWeight("Bold").Foreground("{DynamicResource Accent}").HorizontalAlignment("Right").VerticalAlignment("Center")
vfdReadout.Add("TextBlock.Effect").Add("DropShadowEffect").SetProp("x:Name", "VfdFreqGlow").SetProp("Color", "#00FFFF").BlurRadius(8).ShadowDepth(0).Opacity(0.85)

; VFD bottom info row
vfdBottomGrid := vfdSp.Add("Grid").Margin("0,2,0,0")
vfdBottomGrid.Add("TextBlock").Text("SHORTWAVE RCVR").FontSize(8).Foreground("{DynamicResource TextSub}").Opacity("0.5").HorizontalAlignment("Left").VerticalAlignment("Bottom")
vfdBottomGrid.Add("TextBlock").Text("MHz").FontSize(9).FontWeight("Bold").Foreground("{DynamicResource Accent}").HorizontalAlignment("Right").VerticalAlignment("Bottom")

; Mode Selection Buttons row
modeSelectorBdr := leftPanel.Add("Border").CornerRadius("4").Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("10,8,10,8").Margin("0,10,0,10")
modeSelectorSp := modeSelectorBdr.Add("StackPanel")
modeSelectorSp.Add("TextBlock").Text("RECEIVER DEMODULATOR MODE").FontSize(9).FontWeight("Bold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,6")

modeBtnsRow := modeSelectorSp.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Center")
modeBtnsRow.Add("RadioButton").Name("BtnModeLSB").Style("{StaticResource RetroModeBtnStyle}").Content("LSB").Margin("0,0,6,0").GroupName("ModeGroup")
modeBtnsRow.Add("RadioButton").Name("BtnModeUSB").Style("{StaticResource RetroModeBtnStyle}").Content("USB").IsChecked("True").Margin("0,0,6,0").GroupName("ModeGroup")
modeBtnsRow.Add("RadioButton").Name("BtnModeCW").Style("{StaticResource RetroModeBtnStyle}").Content("CW").Margin("0,0,6,0").GroupName("ModeGroup")
modeBtnsRow.Add("RadioButton").Name("BtnModeAM").Style("{StaticResource RetroModeBtnStyle}").Content("AM").Margin("0,0,6,0").GroupName("ModeGroup")
modeBtnsRow.Add("RadioButton").Name("BtnModeFM").Style("{StaticResource RetroModeBtnStyle}").Content("FM").GroupName("ModeGroup")

; Band Selection Buttons row
bandSelectorBdr := leftPanel.Add("Border").CornerRadius("4").Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("10,8,10,8")
bandSelectorSp := bandSelectorBdr.Add("StackPanel")
bandSelectorSp.Add("TextBlock").Text("HF MULTIBAND SELECTOR").FontSize(9).FontWeight("Bold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,6")

bandBtnsRow := bandSelectorSp.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Center")
bandBtnsRow.Add("RadioButton").Name("BtnBand80m").Style("{StaticResource RetroBandBtnStyle}").Content("80M").Margin("0,0,6,0").GroupName("BandGroup")
bandBtnsRow.Add("RadioButton").Name("BtnBand40m").Style("{StaticResource RetroBandBtnStyle}").Content("40M").Margin("0,0,6,0").GroupName("BandGroup")
bandBtnsRow.Add("RadioButton").Name("BtnBand20m").Style("{StaticResource RetroBandBtnStyle}").Content("20M").IsChecked("True").Margin("0,0,6,0").GroupName("BandGroup")
bandBtnsRow.Add("RadioButton").Name("BtnBand15m").Style("{StaticResource RetroBandBtnStyle}").Content("15M").Margin("0,0,6,0").GroupName("BandGroup")
bandBtnsRow.Add("RadioButton").Name("BtnBand10m").Style("{StaticResource RetroBandBtnStyle}").Content("10M").GroupName("BandGroup")

; --- RIGHT PANEL: TUNING DECK ---
; Left column inside Right Deck: Giant VFO Knob + Toggles
vfoCol := rightPanel.Add("StackPanel").Grid_Column(0).HorizontalAlignment("Center").VerticalAlignment("Center")
vfoCol.Add("TextBlock").Text("MAIN TUNING VFO").FontSize(10).FontWeight("Bold").Foreground("{DynamicResource TextSub}").HorizontalAlignment("Center").Margin("0,0,0,5")
vfoCol.Add("Slider").Name("VfoKnob").Style("{StaticResource LargeKnobStyle}").HorizontalAlignment("Center").Value("0")
vfoCol.Add("TextBlock").Name("VfoBandLabel").Text("20m Band (14 MHz)").FontSize(9).Foreground("{DynamicResource TextSub}").HorizontalAlignment("Center").Margin("0,5,0,10")

; Row of Toggle Switches
togglesRow := vfoCol.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Center").Margin("0,5,0,0")

swPowerSp := togglesRow.Add("StackPanel").HorizontalAlignment("Center").Margin("0,0,12,0")
swPowerSp.Add("CheckBox").Name("SwPower").Style("{StaticResource RetroToggleStyle}").IsChecked("True").HorizontalAlignment("Center")
swPowerSp.Add("TextBlock").Text("POWER").FontSize(8).FontWeight("Bold").Foreground("{DynamicResource TextMain}").HorizontalAlignment("Center").Margin("0,2,0,0")

swAttSp := togglesRow.Add("StackPanel").HorizontalAlignment("Center").Margin("0,0,12,0")
swAttSp.Add("CheckBox").Name("SwAtt").Style("{StaticResource RetroToggleStyle}").IsChecked("False").HorizontalAlignment("Center")
swAttSp.Add("TextBlock").Text("ATT").FontSize(8).FontWeight("Bold").Foreground("{DynamicResource TextMain}").HorizontalAlignment("Center").Margin("0,2,0,0")

swNoiseSp := togglesRow.Add("StackPanel").HorizontalAlignment("Center").Margin("0,0,12,0")
swNoiseSp.Add("CheckBox").Name("SwNoise").Style("{StaticResource RetroToggleStyle}").IsChecked("True").HorizontalAlignment("Center")
swNoiseSp.Add("TextBlock").Text("NB").FontSize(8).FontWeight("Bold").Foreground("{DynamicResource TextMain}").HorizontalAlignment("Center").Margin("0,2,0,0")

swLockSp := togglesRow.Add("StackPanel").HorizontalAlignment("Center")
swLockSp.Add("CheckBox").Name("SwLock").Style("{StaticResource RetroToggleStyle}").IsChecked("False").HorizontalAlignment("Center")
swLockSp.Add("TextBlock").Text("LOCK").FontSize(8).FontWeight("Bold").Foreground("{DynamicResource TextMain}").HorizontalAlignment("Center").Margin("0,2,0,0")

; Right column inside Right Deck: 2x2 grid of smaller gain/level knobs
knobsCol := rightPanel.Add("UniformGrid").Grid_Column(1).SetProp("Columns", "2").SetProp("Rows", "2").VerticalAlignment("Center").HorizontalAlignment("Center").Margin("10,0,0,0")

k1 := knobsCol.Add("StackPanel").Margin("10,8,10,8").HorizontalAlignment("Center")
k1.Add("TextBlock").Text("AF GAIN").FontSize(9).FontWeight("Bold").Foreground("{DynamicResource TextMain}").HorizontalAlignment("Center").Margin("0,0,0,2")
k1.Add("Slider").Name("KnobAFGain").Style("{StaticResource SmallKnobStyle}").Value("40").HorizontalAlignment("Center") ; default 65% (mapped to value 40)
k1.Add("TextBlock").Name("KnobAFGain_Val").Text("65%").FontSize(8).Foreground("{DynamicResource TextSub}").HorizontalAlignment("Center")

k2 := knobsCol.Add("StackPanel").Margin("10,8,10,8").HorizontalAlignment("Center")
k2.Add("TextBlock").Text("SQUELCH").FontSize(9).FontWeight("Bold").Foreground("{DynamicResource TextMain}").HorizontalAlignment("Center").Margin("0,0,0,2")
k2.Add("Slider").Name("KnobSquelch").Style("{StaticResource SmallKnobStyle}").Value("-95").HorizontalAlignment("Center") ; default 15% (mapped to value -95)
k2.Add("TextBlock").Name("KnobSquelch_Val").Text("15%").FontSize(8).Foreground("{DynamicResource TextSub}").HorizontalAlignment("Center")

k3 := knobsCol.Add("StackPanel").Margin("10,8,10,8").HorizontalAlignment("Center")
k3.Add("TextBlock").Text("RF GAIN").FontSize(9).FontWeight("Bold").Foreground("{DynamicResource TextMain}").HorizontalAlignment("Center").Margin("0,0,0,2")
k3.Add("Slider").Name("KnobRFGain").Style("{StaticResource SmallKnobStyle}").Value("81").HorizontalAlignment("Center") ; default 80% (mapped to value 81)
k3.Add("TextBlock").Name("KnobRFGain_Val").Text("80%").FontSize(8).Foreground("{DynamicResource TextSub}").HorizontalAlignment("Center")

k4 := knobsCol.Add("StackPanel").Margin("10,8,10,8").HorizontalAlignment("Center")
k4.Add("TextBlock").Text("CARRIER").FontSize(9).FontWeight("Bold").Foreground("{DynamicResource TextMain}").HorizontalAlignment("Center").Margin("0,0,0,2")
k4.Add("Slider").Name("KnobCarrier").Style("{StaticResource SmallKnobStyle}").Value("0").HorizontalAlignment("Center") ; default 50% (mapped to value 0)
k4.Add("TextBlock").Name("KnobCarrier_Val").Text("50%").FontSize(8).Foreground("{DynamicResource TextSub}").HorizontalAlignment("Center")

; Bezel Divider line
mainGrid.Add("Path").Grid_Row(1).VerticalAlignment("Bottom").Data("M 0,2 L 840,2").Style("{StaticResource ChassisBezelLine}")

; --- BOTTOM ANALYZER & TERMINAL SYSTEM (ROW 2) ---
bottomGrid := mainGrid.Add("Grid").Grid_Row(2).Margin("15,8,15,10")
bottomGrid.Cols("380", "15", "*")

; 16-Bar Spectrum Analyzer container
specBdr := bottomGrid.Add("Border").Grid_Column(0).Height(102).CornerRadius("4").Background("#040608").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1.5").Padding("8,6,8,4").VerticalAlignment("Center")
specGrid := specBdr.Add("Grid").ClipToBounds("True")

; Subtle grid lines overlay on spectrum
specGrid.Add("Border").SetProp("IsHitTestVisible", "False").InjectResources('<Style TargetType="Border"><Setter Property="Opacity" Value="0.04"/><Setter Property="Background"><Setter.Value><DrawingBrush TileMode="Tile" Viewport="0,0,4,4" ViewportUnits="Absolute"><DrawingBrush.Drawing><GeometryDrawing Brush="#FFF"><GeometryDrawing.Geometry><RectangleGeometry Rect="0,0,1,1"/></GeometryDrawing.Geometry></GeometryDrawing></DrawingBrush.Drawing></DrawingBrush></Setter.Value></Setter></Style>')

specRowsGrid := specGrid.Add("Grid")
specRowsGrid.Rows("Auto", "*")
specRowsGrid.Add("TextBlock").Text("REAL-TIME SIGNAL SPECTRUM (30 kHz Span)").FontSize(8).FontWeight("Bold").Foreground("{DynamicResource TextSub}").Opacity("0.5").Margin("0,0,0,4").HorizontalAlignment("Center")

specBarsGrid := specRowsGrid.Add("UniformGrid").Grid_Row(1).SetProp("Columns", "16").SetProp("Rows", "1")
Loop 16 {
    specBarsGrid.Add("ProgressBar").Name("SpecBar_" A_Index).Style("{StaticResource SpecBarStyle}").Foreground("{DynamicResource Accent}").Value("15").Margin("1.5,0,1.5,0")
}

; Diagnostic scrolling receiver log box
logBdr := bottomGrid.Add("Border").Grid_Column(2).Height(102).CornerRadius("4").Background("#070B0A").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1.5").Padding("10,6,10,6").VerticalAlignment("Center")
logGrid := logBdr.Add("Grid")
logGrid.Rows("Auto", "*")
logGrid.Add("TextBlock").Text("RECEIVER DIAGNOSTIC TERMINAL LOG").FontSize(8).FontWeight("Bold").Foreground("#00FF66").Opacity("0.6").Margin("0,0,0,4")

; Monospace textbox styled as bright green terminal
logGrid.Add("TextBox").Name("LogBox").Grid_Row(1).FontFamily("Consolas").FontSize(10.5).Foreground("#00FF66").Background("Transparent").BorderThickness("0").IsReadOnly("True").Text("Initializing receiver firmware...`nSystem status ONLINE.`n").VerticalScrollBarVisibility("Hidden").TextWrapping("Wrap")

; ==============================================================================
; COMPILER & EVENT REGISTRY
; ==============================================================================

ui := app.Compile()
ui.Track("VfoKnob")
ui.Track("SwPower")
ui.Track("SwAtt")
ui.Track("SwNoise")
ui.Track("SwLock")
ui.Track("KnobAFGain")
ui.Track("KnobSquelch")
ui.Track("KnobRFGain")
ui.Track("KnobCarrier")
ui.Track("ComboThemesList")

; --- BIND WINDOW CONTROL BUTTONS ---
ui.OnEvent("MinButton", "MouseLeftButtonDown", (*) => WinMinimize(ui.wpfHwnd))
ui.OnEvent("CloseButton", "MouseLeftButtonDown", (*) => ExitApp())

; --- BIND THEME DROP-DOWN ---
ui.OnEvent("ComboThemesList", "SelectionChanged", HandleThemeSelection)

; --- BIND DEMODULATOR MODES ---
ui.OnEvent("BtnModeLSB", "Checked", (*) => HandleModeChange("LSB"))
ui.OnEvent("BtnModeUSB", "Checked", (*) => HandleModeChange("USB"))
ui.OnEvent("BtnModeCW", "Checked", (*) => HandleModeChange("CW"))
ui.OnEvent("BtnModeAM", "Checked", (*) => HandleModeChange("AM"))
ui.OnEvent("BtnModeFM", "Checked", (*) => HandleModeChange("FM"))

; --- BIND HF BANDS ---
ui.OnEvent("BtnBand80m", "Checked", (*) => HandleBandChange("80m"))
ui.OnEvent("BtnBand40m", "Checked", (*) => HandleBandChange("40m"))
ui.OnEvent("BtnBand20m", "Checked", (*) => HandleBandChange("20m"))
ui.OnEvent("BtnBand15m", "Checked", (*) => HandleBandChange("15m"))
ui.OnEvent("BtnBand10m", "Checked", (*) => HandleBandChange("10m"))

; --- BIND TOGGLE SWITCHES ---
ui.OnEvent("SwPower", "Checked", (*) => HandlePowerToggle(true))
ui.OnEvent("SwPower", "Unchecked", (*) => HandlePowerToggle(false))
ui.OnEvent("SwAtt", "Checked", (*) => HandleAttToggle(true))
ui.OnEvent("SwAtt", "Unchecked", (*) => HandleAttToggle(false))
ui.OnEvent("SwNoise", "Checked", (*) => HandleNoiseToggle(true))
ui.OnEvent("SwNoise", "Unchecked", (*) => HandleNoiseToggle(false))
ui.OnEvent("SwLock", "Checked", (*) => HandleLockToggle(true))
ui.OnEvent("SwLock", "Unchecked", (*) => HandleLockToggle(false))

; --- BIND DIAL AND SLIDERS ---
ui.OnEvent("VfoKnob", "ValueChanged", HandleVfoChange)
ui.OnEvent("KnobAFGain", "ValueChanged", HandleAFGainChange)
ui.OnEvent("KnobSquelch", "ValueChanged", HandleSquelchChange)
ui.OnEvent("KnobRFGain", "ValueChanged", HandleRFGainChange)
ui.OnEvent("KnobCarrier", "ValueChanged", HandleCarrierChange)

; Listen to MouseWheel on VfoKnob for analog satisfying tuning
ui.OnEvent("VfoKnob", "MouseWheel", HandleVfoWheel)

; Apply startup configurations after window is shown
ui.OnEvent("Window", "Loaded", HandleWindowLoaded)

; ==============================================================================
; INTERACTION EVENT HANDLERS
; ==============================================================================

HandleWindowLoaded(state, ctrl, event) {
    ; Load theme dropdown contents
    themeIndex := 0
    for idx, tName in ThemeNames {
        if (tName == "Cyberpunk Neon") {
            themeIndex := idx - 1
        }
    }
    ui.Update("ComboThemesList", "SelectedIndex", String(themeIndex))
    ApplyTheme("Cyberpunk Neon")

    LogMessage("Transceiver online. VFO-A active.")
    LogMessage("Ready on " CurrentBand " band. Tuning frequency: " FormatFreq(CurrentFreq) " MHz.")

    ; Start simulation loops
    SetTimer(SimulationTick, 100)
    SetTimer(SpectrumTick, 80)
}

HandleThemeSelection(state, *) {
    if !state.Has("ComboThemesList")
        return
    tName := state["ComboThemesList"]
    ApplyTheme(tName)
}

ApplyTheme(themeName) {
    if !ThemeDefinitions.Has(themeName)
        return

    themeMap := ThemeDefinitions[themeName]

    ; Update DWM styling
    if themeMap.Has("Window_DWM") {
        ui.Update("Window", "DWM", themeMap["Window_DWM"])
    }

    ; Apply TitleBar defaults first so switching themes works cleanly
    titleBarColor := themeMap.Has("Resource_TitleBarColor") ? themeMap["Resource_TitleBarColor"] : "Transparent"
    titleBarForeground := themeMap.Has("Resource_TitleBarForeground") ? themeMap["Resource_TitleBarForeground"] : (themeMap.Has("Resource_TextMain") ? themeMap["Resource_TextMain"] : "#000000")
    ui.Update("Resource", "TitleBarColor", titleBarColor)
    ui.Update("Resource", "TitleBarForeground", titleBarForeground)

    ; Set standard color tokens
    for key, val in themeMap {
        if (InStr(key, "Resource_") == 1) {
            resName := SubStr(key, 10)
            ui.Update("Resource", resName, val)
        }
    }

    ; Procedurally style our vintage components to match the theme color space
    isDarkTheme := true
    if themeMap.Has("Window_DWM") {
        dwmParts := StrSplit(themeMap["Window_DWM"], ",")
        if (dwmParts.Length == 2 && dwmParts[2] == "0") {
            isDarkTheme := false
        }
    }

    ; Theme VFD color glows
    accentColor := themeMap.Has("Resource_Accent") ? themeMap["Resource_Accent"] : "#00FFFF"
    textSubColor := themeMap.Has("Resource_TextSub") ? themeMap["Resource_TextSub"] : "#888888"

    ; Color-match our VFD indicators, frequency, and spectrum
    if (PowerOn) {
        ui.Update("VfdFreq", "Foreground", accentColor)
        ui.Update("VfdFreqGlow", "Color", accentColor)
        ui.Update("VfdVfoA", "Foreground", accentColor)
        ui.Update("VfdVfoB", "Foreground", accentColor)
        ui.Update("VfdModeText", "Foreground", accentColor)
        ui.Update("MeterBg", "Background", isDarkTheme ? "#111317" : "#FAF6EE")
        ui.Update("MeterGlow", "Opacity", isDarkTheme ? "0.15" : "0.08")
        ui.Update("SMeterNeedle", "Stroke", isDarkTheme ? "#E2E8F0" : "#1A202C")
    } else {
        ; Dim colors for power off state
        ui.Update("VfdFreq", "Foreground", "#082025")
        ui.Update("VfdFreqGlow", "Opacity", "0")
        ui.Update("VfdVfoA", "Foreground", "#082025")
        ui.Update("VfdVfoB", "Foreground", "#082025")
        ui.Update("VfdModeText", "Foreground", "#082025")
        ui.Update("MeterBg", "Background", isDarkTheme ? "#0D1117" : "#E2D9C8")
        ui.Update("MeterGlow", "Opacity", "0")
        ui.Update("SMeterNeedle", "Stroke", isDarkTheme ? "#334155" : "#64748B")
    }

    LogMessage("Applied theme: " themeName)
}

; --- GAIN AND INTENSITY CONTROLS ---
KnobToPercent(val) {
    return Round((val + 135) / 270 * 100)
}

HandleAFGainChange(state, *) {
    global AFGainVal
    raw := Number(state["KnobAFGain"])
    AFGainVal := KnobToPercent(raw)
    ui.Update("KnobAFGain_Val", "Text", AFGainVal "%")
}

HandleSquelchChange(state, *) {
    global SquelchVal
    raw := Number(state["KnobSquelch"])
    SquelchVal := KnobToPercent(raw)
    ui.Update("KnobSquelch_Val", "Text", SquelchVal "%")
}

HandleRFGainChange(state, *) {
    global RfGainVal
    raw := Number(state["KnobRFGain"])
    RfGainVal := KnobToPercent(raw)
    ui.Update("KnobRFGain_Val", "Text", RfGainVal "%")
}

HandleCarrierChange(state, *) {
    global CarrierVal
    raw := Number(state["KnobCarrier"])
    CarrierVal := KnobToPercent(raw)
    ui.Update("KnobCarrier_Val", "Text", CarrierVal "%")
}

; --- DEMODULATOR AND BAND SELECTIONS ---
HandleModeChange(modeName) {
    global CurrentMode
    if (!PowerOn)
        return
    CurrentMode := modeName
    ui.Update("VfdModeText", "Text", modeName)
    SoundBeep(900, 20)
    LogMessage("Demodulator mode set to: " modeName)
}

HandleBandChange(bandName) {
    global CurrentBand, CurrentFreq
    if (!PowerOn)
        return
    CurrentBand := bandName
    preset := BandPresets[bandName]
    CurrentFreq := preset.Freq

    ui.Update("VfoBandLabel", "Text", bandName " Band (" preset.Label ")")
    UpdateFrequencyDisplay()
    SoundBeep(700, 25)
    LogMessage("Shifted band to: " bandName " preset. VFO tuned to: " FormatFreq(CurrentFreq) " MHz.")
}

; --- TOGGLE SWITCHES INTERACTION ---
HandlePowerToggle(enabled) {
    global PowerOn
    PowerOn := enabled

    ; Sound click
    SoundBeep(enabled ? 800 : 400, 30)

    ; Power Led state
    ui.Update("IndicatorLed", "Fill", enabled ? "#10B981" : "#EF4444")

    ; Update VFD & analog screen backgrounds
    if (enabled) {
        ui.Update("VfdFreqBg", "Opacity", "1.0")
        ui.Update("VfdFreq", "Text", FormatFreq(CurrentFreq))
        ui.Update("VfdFreqGlow", "Opacity", "0.85")
        ui.Update("VfoBandLabel", "Opacity", "1.0")
        ui.Update("SpecRowsGrid", "Opacity", "1.0")

        ; Re-apply current theme styling to display elements
        if (ThemeNames.Length > 0 && ui.HasProp("wpfHwnd") && ui.wpfHwnd) {
            themeIdx := 0
            try {
                themeIdx := Number(ui.Query("ComboThemesList>SelectedIndex"))
            }
            if (themeIdx >= 0 && themeIdx < ThemeNames.Length) {
                ApplyTheme(ThemeNames[themeIdx + 1])
            }
        }

        LogMessage("Main power system turned ON.")
    } else {
        ; Shut down display backlights and blank out tubes
        ui.Update("VfdFreqBg", "Opacity", "0.05")
        ui.Update("VfdFreq", "Text", "")
        ui.Update("VfdFreqGlow", "Opacity", "0")
        ui.Update("VfoBandLabel", "Opacity", "0.2")
        ui.Update("SpecRowsGrid", "Opacity", "0.1")

        ui.Update("VfdVfoA", "Opacity", "0.05")
        ui.Update("VfdVfoB", "Opacity", "0.05")
        ui.Update("VfdLock", "Opacity", "0.05")
        ui.Update("VfdAtt", "Opacity", "0.05")

        ; Determine if light or dark theme for S-meter off state
        isDark := true
        if (ThemeNames.Length > 0 && ui.HasProp("wpfHwnd") && ui.wpfHwnd) {
            themeIdx := 0
            try {
                themeIdx := Number(ui.Query("ComboThemesList>SelectedIndex"))
            }
            if (themeIdx >= 0 && themeIdx < ThemeNames.Length) {
                tName := ThemeNames[themeIdx + 1]
                if ThemeDefinitions.Has(tName) {
                    themeMap := ThemeDefinitions[tName]
                    if themeMap.Has("Window_DWM") {
                        dwmParts := StrSplit(themeMap["Window_DWM"], ",")
                        if (dwmParts.Length == 2 && dwmParts[2] == "0") {
                            isDark := false
                        }
                    }
                }
            }
        }
        ui.Update("MeterBg", "Background", isDark ? "#0D1117" : "#E2D9C8")
        ui.Update("MeterGlow", "Opacity", "0")
        ui.Update("SMeterNeedle", "Stroke", isDark ? "#334155" : "#64748B")

        LogMessage("System standby. Main transceiver displays offline.")
    }
}

HandleAttToggle(enabled) {
    global AttActive
    if (!PowerOn)
        return
    AttActive := enabled
    ui.Update("VfdAtt", "Opacity", enabled ? "1.0" : "0.15")
    SoundBeep(800, 15)
    LogMessage("Attenuator (ATT -20dB) " (enabled ? "ACTIVATED" : "DEACTIVATED"))
}

HandleNoiseToggle(enabled) {
    global NoiseBlankerActive
    if (!PowerOn)
        return
    NoiseBlankerActive := enabled
    SoundBeep(800, 15)
    LogMessage("Noise Blanker filter (NB) " (enabled ? "ON" : "OFF"))
}

HandleLockToggle(enabled) {
    global LockActive
    if (!PowerOn)
        return
    LockActive := enabled
    ui.Update("VfdLock", "Opacity", enabled ? "1.0" : "0.15")
    SoundBeep(800, 15)
    LogMessage("VFO Dial Lock (LOCK) " (enabled ? "ENGAGED" : "RELEASED"))
}

; --- VFO DIAL ADJUSTMENT AND INTERACTIVE TUNING ---
HandleVfoChange(state, *) {
    global VfoOldValue, VfoResetting, CurrentFreq, LockActive, PowerOn
    if (!PowerOn)
        return
    if (LockActive) {
        ; Restore lock state values
        ui.Update("VfoKnob", "Value", "0")
        return
    }
    if (VfoResetting) {
        VfoResetting := false
        return
    }

    newVal := Number(state["VfoKnob"])
    delta := newVal - VfoOldValue
    VfoOldValue := newVal

    ; Filter out reset jump delta spikes
    if (Abs(delta) > 40)
        return

    ; Fine tune frequency
    TuningDelta(delta * 0.0004) ; 400Hz per degree

    ; Reset slider to center point whenever turned past threshold for infinite rotation feel
    if (Abs(newVal) > 60) {
        VfoResetting := true
        VfoOldValue := 0
        ui.Update("VfoKnob", "Value", "0")
    }
}

; Satisying MouseWheel tuning on VFO dial
HandleVfoWheel(state, ctrl, event) {
    global LockActive, PowerOn
    if (!PowerOn || LockActive)
        return
    ; Wheel delta direction
    wDelta := InStr(event, "-") ? -1 : 1
    TuningDelta(wDelta * 0.001) ; 1 kHz per wheel click

    ; Visually nudge the dial pointer slightly to represent the wheel click
    currentVal := Number(state["VfoKnob"])
    nudgeVal := currentVal + (wDelta * 4)
    if (Abs(nudgeVal) > 135)
        nudgeVal := 0

    ui.Update("VfoKnob", "Value", String(nudgeVal))
    VfoOldValue := nudgeVal
}

TuningDelta(deltaVal) {
    global CurrentFreq, CurrentBand
    preset := BandPresets[CurrentBand]

    CurrentFreq += deltaVal

    ; Clamp frequency to band limits
    if (CurrentFreq < preset.Min) {
        CurrentFreq := preset.Min
        SoundBeep(450, 40) ; Out of bounds low tone beep
    } else if (CurrentFreq > preset.Max) {
        CurrentFreq := preset.Max
        SoundBeep(450, 40) ; Out of bounds high tone beep
    }

    UpdateFrequencyDisplay()
}

UpdateFrequencyDisplay() {
    global CurrentFreq, Stations, CurrentMode
    ui.Update("VfdFreq", "Text", FormatFreq(CurrentFreq))

    ; Check if tuned directly into a station
    for st in Stations {
        if (Abs(CurrentFreq - st.Freq) < 0.0005) { ; exactly centered within 500Hz
            LogMessage(">> Broadcast Tuned: " st.Name " (" st.Mode " mode active)")
            if (st.Mode != CurrentMode) {
                LogMessage("   WARNING: Mode mismatch! Set demodulator to " st.Mode " for best audio quality.")
            }
        }
    }
}

FormatFreq(freqVal) {
    ; Convert 14.23000 to "14.230.00"
    return RegExReplace(Format("{:0.5f}", freqVal), "(\d+)\.(\d{3})(\d{2})", "$1.$2.$3")
}

; ==============================================================================
; SIMULATION ENGINE TIMERS (ANALOG NEEDLE & SPECTRUM FLOW)
; ==============================================================================

GetCurrentSignal() {
    global CurrentFreq, Stations, SquelchVal, RfGainVal, AttActive, PowerOn
    if (!PowerOn)
        return 0

    ; Base static noise floor
    noiseFloor := 8 + Random(-2, 2)
    gainMult := RfGainVal / 100.0
    maxSig := noiseFloor * gainMult

    ; Attenuator cuts noise
    if (AttActive)
        maxSig := maxSig * 0.4

    ; Scan close preset stations
    for st in Stations {
        diff := Abs(CurrentFreq - st.Freq)
        if (diff < 0.012) { ; Within 12 kHz window
            ; Signal rises using bell curve
            sigPower := st.Signal * Exp(-(diff / 0.0045) ** 2)
            if (sigPower > maxSig) {
                maxSig := sigPower
            }
        }
    }

    return maxSig
}

SimulationTick() {
    global PowerOn, SquelchVal, NoiseBlankerActive
    if (!PowerOn) {
        ; Set needle to resting position (-40 degrees)
        ui.Update("MeterNeedleRotate", "Angle", "-40")
        return
    }

    sig := GetCurrentSignal()
    squelchThreshold := SquelchVal

    ; If squelch cuts off, needle drops to squelch point
    if (sig < squelchThreshold) {
        ; Static noise wiggles slightly
        flutter := NoiseBlankerActive ? Random(-0.2, 0.2) : Random(-1.5, 1.5)
        angle := -40 + (flutter * 0.5)
        ui.Update("MeterNeedleRotate", "Angle", String(angle))
        return
    }

    ; Map signal (0..100) to angle (-40..40 degrees)
    targetAngle := -40 + (sig / 100.0) * 80

    ; Add dynamic flutter based on Noise Blanker filter
    flutter := NoiseBlankerActive ? Random(-0.3, 0.3) : Random(-2.0, 2.0)
    finalAngle := targetAngle + flutter

    if (finalAngle > 40)
        finalAngle := 40
    if (finalAngle < -40)
        finalAngle := -40

    ui.Update("MeterNeedleRotate", "Angle", String(finalAngle))
}

CalculateSpecValue(barIndex) {
    global CurrentFreq, Stations, PowerOn, SquelchVal, AFGainVal, RfGainVal, AttActive
    if (!PowerOn)
        return 0

    currentSignal := GetCurrentSignal()
    squelchThreshold := SquelchVal
    isMuted := (currentSignal < squelchThreshold)

    if (isMuted) {
        ; Just tiny base background grid noise wiggles
        return 2 + Random(0, 4)
    }

    ; Volume/RF gain scales vertical spectrum size
    volFactor := AFGainVal / 100.0
    rfFactor := RfGainVal / 100.0

    baseNoise := (4 + Random(0, 6)) * rfFactor * volFactor

    signalPeak := 0
    peakCenterBar := 8

    for st in Stations {
        diff := CurrentFreq - st.Freq ; Difference in MHz
        if (Abs(diff) < 0.024) { ; Within 24 kHz span
            ; Map delta frequency to center bar coordinate (columns 1..16)
            ; diff = -0.012 -> bar 1, diff = 0 -> bar 8, diff = +0.012 -> bar 16
            peakCenterBar := 8 - Round(diff / 0.0015)
            signalPeak := st.Signal * (1.0 - (Abs(diff) / 0.024))
        }
    }

    if (AttActive) {
        signalPeak := signalPeak * 0.4
    }

    barHeight := baseNoise
    if (signalPeak > 0) {
        dist := Abs(barIndex - peakCenterBar)
        bell := Exp(-(dist / 1.6) ** 2)
        barHeight += signalPeak * bell * volFactor * rfFactor
    }

    if (barHeight > 100)
        barHeight := 100
    if (barHeight < 0)
        barHeight := 0

    return Round(barHeight)
}

SpectrumTick() {
    if (!PowerOn) {
        ; Zero out bars
        updates := []
        Loop 16 {
            updates.Push({ ControlName: "SpecBar_" A_Index, PropertyName: "Value", Value: "0" })
        }
        ui.BatchUpdate(updates)
        return
    }

    updates := []
    Loop 16 {
        hVal := CalculateSpecValue(A_Index)
        updates.Push({ ControlName: "SpecBar_" A_Index, PropertyName: "Value", Value: String(hVal) })
    }
    ui.BatchUpdate(updates)
}

; --- RETRO TERMINAL LOG SYSTEM ---
LogMessage(msg) {
    global LogBuffer

    ; Timestamp
    timeStr := FormatTime(, "HH:mm:ss")
    line := "[" timeStr "] " msg

    LogBuffer.Push(line)
    if (LogBuffer.Length > 5) {
        LogBuffer.RemoveAt(1) ; Keep buffer to last 5 lines for clean textbox display
    }

    ; Combine buffer text
    fullText := ""
    for idx, str in LogBuffer {
        fullText .= str "`n"
    }

    if (PowerOn) {
        ui.Update("LogBox", "Text", fullText)
    }
}

app.Show()