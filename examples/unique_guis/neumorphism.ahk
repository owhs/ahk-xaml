#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"

; ==============================================================================
; STATE MANAGEMENT
; ==============================================================================
global ThemeDefinitions := Map()
global ThemeNames := []
global AppState := {
    IsPlaying: false,
    PlayProgress: 77, ; in seconds (1:17)
    PlayDuration: 166, ; in seconds (2:46)
    Volume: 45,
    NotifyServices: true,
    SearchQuery: "",
    ActiveTab: "Overview",
    ShadowBlur: 16,
    ShadowDepth: 5,
    LightShadowOpacity: 0.90,
    DarkShadowOpacity: 0.30
}

; Chart columns defaults
global ChartValues := [45, 95, 60, 115, 75]

global ServicesData := [
    { Name: "Core Audio Engine", Status: "Active", Icon: Chr(0xE767), Color: "#32D74B" },
    { Name: "Network Telemetry", Status: "Active", Icon: Chr(0xE839), Color: "#32D74B" },
    { Name: "Database Sync", Status: "Standby", Icon: Chr(0xE753), Color: "#FF9F0A" },
    { Name: "Shadow Renderer", Status: "Active", Icon: Chr(0xE706), Color: "#32D74B" }
]

; ==============================================================================
; NEUMORPHIC XAML STYLES (INJECTED AT STARTUP)
; ==============================================================================
global NeumorphicStyles := '
(
    
        
        <!-- Raised Card Template -->
        <Style x:Key="NeumorphicCard" TargetType="ContentControl">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ContentControl">
                        <Grid Margin="8">
                            <Border x:Name="L_Shadow" Background="{DynamicResource NeumorphicLightShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Shadow" Background="{DynamicResource NeumorphicDarkShadowBrush}" Visibility="Collapsed"/>
                            
                            <!-- Dark Drop Shadow (bottom-right) -->
                            <Border CornerRadius="16" Background="{DynamicResource NeumorphicBgBrush}">
                                <Border.Effect>
                                    <DropShadowEffect Color="{Binding ElementName=D_Shadow, Path=Background.Color}" BlurRadius="{DynamicResource NeumorphicBlurRadius}" ShadowDepth="{DynamicResource NeumorphicShadowDepth}" Direction="315" Opacity="{DynamicResource NeumorphicDarkShadowOpacity}"/>
                                </Border.Effect>
                            </Border>
                            
                            <!-- Light Glow Shadow (top-left) -->
                            <Border CornerRadius="16" Background="{DynamicResource NeumorphicBgBrush}">
                                <Border.Effect>
                                    <DropShadowEffect Color="{Binding ElementName=L_Shadow, Path=Background.Color}" BlurRadius="{DynamicResource NeumorphicBlurRadius}" ShadowDepth="{DynamicResource NeumorphicShadowDepth}" Direction="135" Opacity="{DynamicResource NeumorphicLightShadowOpacity}"/>
                                </Border.Effect>
                            </Border>
                            
                            <!-- Core Card Body -->
                            <Border CornerRadius="16" Background="{DynamicResource NeumorphicBgBrush}" BorderThickness="1" Padding="{TemplateBinding Padding}">
                                <Border.BorderBrush>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=L_Shadow, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=D_Shadow, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.BorderBrush>
                                <ContentPresenter/>
                            </Border>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- Sunken Card Template -->
        <Style x:Key="NeumorphicCardSunken" TargetType="ContentControl">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ContentControl">
                        <Grid Margin="8">
                            <Border x:Name="L_Shadow" Background="{DynamicResource NeumorphicLightShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Shadow" Background="{DynamicResource NeumorphicDarkShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="L_Recess" Background="{DynamicResource NeumorphicLightRecessBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Recess" Background="{DynamicResource NeumorphicDarkRecessBrush}" Visibility="Collapsed"/>
        
                            <!-- Recessed Gradient Background Pocket -->
                            <Border CornerRadius="16">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=D_Recess, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=L_Recess, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                                <Border.BorderBrush>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=D_Shadow, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=L_Shadow, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.BorderBrush>
                                <Border BorderThickness="1.5" CornerRadius="16" Padding="{TemplateBinding Padding}">
                                    <ContentPresenter/>
                                </Border>
                            </Border>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- Interactive Neumorphic Button -->
        <Style x:Key="NeumorphicBtn" TargetType="Button">
            <Setter Property="Foreground" Value="{DynamicResource TextMain}"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Padding" Value="18,10"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid x:Name="GridContainer">
                            <Border x:Name="L_Shadow" Background="{DynamicResource NeumorphicLightShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Shadow" Background="{DynamicResource NeumorphicDarkShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="L_Recess" Background="{DynamicResource NeumorphicLightRecessBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Recess" Background="{DynamicResource NeumorphicDarkRecessBrush}" Visibility="Collapsed"/>
        
                            <!-- Raised Dark Shadow -->
                            <Border x:Name="DarkShadow" CornerRadius="12" Background="{DynamicResource NeumorphicBgBrush}">
                                <Border.Effect>
                                    <DropShadowEffect Color="{Binding ElementName=D_Shadow, Path=Background.Color}" BlurRadius="{DynamicResource NeumorphicBlurRadius}" ShadowDepth="{DynamicResource NeumorphicShadowDepth}" Direction="315" Opacity="{DynamicResource NeumorphicDarkShadowOpacity}"/>
                                </Border.Effect>
                            </Border>
                            
                            <!-- Raised Light Shadow -->
                            <Border x:Name="LightShadow" CornerRadius="12" Background="{DynamicResource NeumorphicBgBrush}">
                                <Border.Effect>
                                    <DropShadowEffect Color="{Binding ElementName=L_Shadow, Path=Background.Color}" BlurRadius="{DynamicResource NeumorphicBlurRadius}" ShadowDepth="{DynamicResource NeumorphicShadowDepth}" Direction="135" Opacity="{DynamicResource NeumorphicLightShadowOpacity}"/>
                                </Border.Effect>
                            </Border>
        
                            <!-- Sunken Background (shown when pressed) -->
                            <Border x:Name="SunkenBg" CornerRadius="12" Visibility="Collapsed">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=D_Recess, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=L_Recess, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                                <Border.BorderBrush>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=D_Shadow, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=L_Shadow, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.BorderBrush>
                                <Border BorderThickness="1.5" CornerRadius="12"/>
                            </Border>
        
                            <!-- Content Border -->
                            <Border x:Name="ContentBorder" CornerRadius="12" Background="{DynamicResource NeumorphicBgBrush}" BorderThickness="1" Padding="{TemplateBinding Padding}">
                                <Border.BorderBrush>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=L_Shadow, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=D_Shadow, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.BorderBrush>
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="DarkShadow" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="{Binding ElementName=D_Shadow, Path=Background.Color}" BlurRadius="{DynamicResource NeumorphicBlurRadius}" ShadowDepth="{DynamicResource NeumorphicShadowDepth}" Direction="315" Opacity="{DynamicResource NeumorphicDarkShadowOpacity}"/>
                                    </Setter.Value>
                                </Setter>
                                <Setter TargetName="LightShadow" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="{Binding ElementName=L_Shadow, Path=Background.Color}" BlurRadius="{DynamicResource NeumorphicBlurRadius}" ShadowDepth="{DynamicResource NeumorphicShadowDepth}" Direction="135" Opacity="{DynamicResource NeumorphicLightShadowOpacity}"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="DarkShadow" Property="Visibility" Value="Collapsed"/>
                                <Setter TargetName="LightShadow" Property="Visibility" Value="Collapsed"/>
                                <Setter TargetName="ContentBorder" Property="Background" Value="Transparent"/>
                                <Setter TargetName="ContentBorder" Property="BorderBrush" Value="Transparent"/>
                                <Setter TargetName="SunkenBg" Property="Visibility" Value="Visible"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- Interactive Neumorphic Circle Button -->
        <Style x:Key="NeumorphicCircleBtn" TargetType="Button">
            <Setter Property="Foreground" Value="{DynamicResource TextMain}"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Grid x:Name="GridContainer">
                            <Border x:Name="L_Shadow" Background="{DynamicResource NeumorphicLightShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Shadow" Background="{DynamicResource NeumorphicDarkShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="L_Recess" Background="{DynamicResource NeumorphicLightRecessBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Recess" Background="{DynamicResource NeumorphicDarkRecessBrush}" Visibility="Collapsed"/>
        
                            <!-- Raised Shadows -->
                            <Border x:Name="DarkShadow" CornerRadius="100" Background="{DynamicResource NeumorphicBgBrush}">
                                <Border.Effect>
                                    <DropShadowEffect Color="{Binding ElementName=D_Shadow, Path=Background.Color}" BlurRadius="{DynamicResource NeumorphicBlurRadius}" ShadowDepth="{DynamicResource NeumorphicShadowDepth}" Direction="315" Opacity="{DynamicResource NeumorphicDarkShadowOpacity}"/>
                                </Border.Effect>
                            </Border>
                            <Border x:Name="LightShadow" CornerRadius="100" Background="{DynamicResource NeumorphicBgBrush}">
                                <Border.Effect>
                                    <DropShadowEffect Color="{Binding ElementName=L_Shadow, Path=Background.Color}" BlurRadius="{DynamicResource NeumorphicBlurRadius}" ShadowDepth="{DynamicResource NeumorphicShadowDepth}" Direction="135" Opacity="{DynamicResource NeumorphicLightShadowOpacity}"/>
                                </Border.Effect>
                            </Border>
        
                            <!-- Sunken Background -->
                            <Border x:Name="SunkenBg" CornerRadius="100" Visibility="Collapsed">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=D_Recess, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=L_Recess, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                                <Border.BorderBrush>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=D_Shadow, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=L_Shadow, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.BorderBrush>
                                <Border BorderThickness="1.5" CornerRadius="100"/>
                            </Border>
        
                            <!-- Content Border -->
                            <Border x:Name="ContentBorder" CornerRadius="100" Background="{DynamicResource NeumorphicBgBrush}" BorderThickness="1" Padding="{TemplateBinding Padding}">
                                <Border.BorderBrush>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=L_Shadow, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=D_Shadow, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.BorderBrush>
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="DarkShadow" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="{Binding ElementName=D_Shadow, Path=Background.Color}" BlurRadius="{DynamicResource NeumorphicBlurRadius}" ShadowDepth="{DynamicResource NeumorphicShadowDepth}" Direction="315" Opacity="{DynamicResource NeumorphicDarkShadowOpacity}"/>
                                    </Setter.Value>
                                </Setter>
                                <Setter TargetName="LightShadow" Property="Effect">
                                    <Setter.Value>
                                        <DropShadowEffect Color="{Binding ElementName=L_Shadow, Path=Background.Color}" BlurRadius="{DynamicResource NeumorphicBlurRadius}" ShadowDepth="{DynamicResource NeumorphicShadowDepth}" Direction="135" Opacity="{DynamicResource NeumorphicLightShadowOpacity}"/>
                                    </Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="DarkShadow" Property="Visibility" Value="Collapsed"/>
                                <Setter TargetName="LightShadow" Property="Visibility" Value="Collapsed"/>
                                <Setter TargetName="ContentBorder" Property="Background" Value="Transparent"/>
                                <Setter TargetName="ContentBorder" Property="BorderBrush" Value="Transparent"/>
                                <Setter TargetName="SunkenBg" Property="Visibility" Value="Visible"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- Neumorphic Toggle Switch -->
        <Style x:Key="NeumorphicSwitch" TargetType="CheckBox">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Grid Background="Transparent">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
        
                            <Border x:Name="L_Shadow" Background="{DynamicResource NeumorphicLightShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Shadow" Background="{DynamicResource NeumorphicDarkShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="L_Recess" Background="{DynamicResource NeumorphicLightRecessBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Recess" Background="{DynamicResource NeumorphicDarkRecessBrush}" Visibility="Collapsed"/>
        
                            <!-- Switch Track Channel (Sunken) -->
                            <Border x:Name="Track" Grid.Column="0" Width="52" Height="24" CornerRadius="12">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=D_Recess, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=L_Recess, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                                <Border.BorderBrush>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=D_Shadow, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=L_Shadow, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.BorderBrush>
                                <Border BorderThickness="1.5" CornerRadius="12"/>
                            </Border>
        
                            <!-- Switch Knob Handle (Raised Circle) -->
                            <Grid x:Name="Knob" Grid.Column="0" HorizontalAlignment="Left" Width="18" Height="18" Margin="3,3,3,3">
                                <Border CornerRadius="9" Background="{DynamicResource NeumorphicBgBrush}">
                                    <Border.Effect>
                                        <DropShadowEffect Color="{Binding ElementName=D_Shadow, Path=Background.Color}" BlurRadius="4" ShadowDepth="1.5" Direction="315" Opacity="{DynamicResource NeumorphicDarkShadowOpacity}"/>
                                    </Border.Effect>
                                </Border>
                                <Border CornerRadius="9" Background="{DynamicResource NeumorphicBgBrush}">
                                    <Border.Effect>
                                        <DropShadowEffect Color="{Binding ElementName=L_Shadow, Path=Background.Color}" BlurRadius="4" ShadowDepth="1.5" Direction="135" Opacity="{DynamicResource NeumorphicLightShadowOpacity}"/>
                                    </Border.Effect>
                                </Border>
                                <Border CornerRadius="9" Background="{DynamicResource NeumorphicBgBrush}" BorderThickness="0.8">
                                    <Border.BorderBrush>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                            <GradientStop Color="{Binding ElementName=L_Shadow, Path=Background.Color}" Offset="0.0"/>
                                            <GradientStop Color="{Binding ElementName=D_Shadow, Path=Background.Color}" Offset="1.0"/>
                                        </LinearGradientBrush>
                                    </Border.BorderBrush>
                                </Border>
                                <Ellipse x:Name="KnobDot" Width="6" Height="6" Fill="{DynamicResource TextSub}" Opacity="0.6"/>
                            </Grid>
        
                            <ContentPresenter Grid.Column="1" Margin="12,0,0,0" VerticalAlignment="Center"/>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Knob" Property="HorizontalAlignment" Value="Right"/>
                                <Setter TargetName="KnobDot" Property="Fill" Value="{DynamicResource Accent}"/>
                                <Setter TargetName="KnobDot" Property="Opacity" Value="1.0"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- Neumorphic Slider -->
        <Style x:Key="NeumorphicSld" TargetType="Slider">
            <Setter Property="IsMoveToPointEnabled" Value="True"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Slider">
                        <Grid VerticalAlignment="Center">
                            <Border x:Name="L_Shadow" Background="{DynamicResource NeumorphicLightShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Shadow" Background="{DynamicResource NeumorphicDarkShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="L_Recess" Background="{DynamicResource NeumorphicLightRecessBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Recess" Background="{DynamicResource NeumorphicDarkRecessBrush}" Visibility="Collapsed"/>
        
                            <!-- Sunken Track Bar -->
                            <Border Height="8" CornerRadius="4" BorderThickness="1.5">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=D_Recess, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=L_Recess, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                                <Border.BorderBrush>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=D_Shadow, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=L_Shadow, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.BorderBrush>
                            </Border>
        
                            <Track x:Name="PART_Track">
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Command="{x:Static Slider.DecreaseLarge}" BorderThickness="0" Height="8">
                                        <RepeatButton.Template>
                                            <ControlTemplate TargetType="RepeatButton">
                                                <Border Background="{DynamicResource Accent}" CornerRadius="4" Opacity="0.3"/>
                                            </ControlTemplate>
                                        </RepeatButton.Template>
                                    </RepeatButton>
                                </Track.DecreaseRepeatButton>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Command="{x:Static Slider.IncreaseLarge}" BorderThickness="0" Height="8">
                                        <RepeatButton.Template>
                                            <ControlTemplate TargetType="RepeatButton">
                                                <Border Background="Transparent"/>
                                            </ControlTemplate>
                                        </RepeatButton.Template>
                                    </RepeatButton>
                                </Track.IncreaseRepeatButton>
                                
                                <Track.Thumb>
                                    <Thumb Width="20" Height="20">
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="Thumb">
                                                <Grid Cursor="Hand">
                                                    <!-- Local color references in Thumb context -->
                                                    <Border x:Name="L_ThumbShadow" Background="{DynamicResource NeumorphicLightShadowBrush}" Visibility="Collapsed"/>
                                                    <Border x:Name="D_ThumbShadow" Background="{DynamicResource NeumorphicDarkShadowBrush}" Visibility="Collapsed"/>
        
                                                    <!-- Dark Shadow -->
                                                    <Border CornerRadius="10" Background="{DynamicResource NeumorphicBgBrush}">
                                                        <Border.Effect>
                                                            <DropShadowEffect Color="{Binding ElementName=D_ThumbShadow, Path=Background.Color}" BlurRadius="5" ShadowDepth="1.5" Direction="315" Opacity="{DynamicResource NeumorphicDarkShadowOpacity}"/>
                                                        </Border.Effect>
                                                    </Border>
                                                    <!-- Light Shadow -->
                                                    <Border CornerRadius="10" Background="{DynamicResource NeumorphicBgBrush}">
                                                        <Border.Effect>
                                                            <DropShadowEffect Color="{Binding ElementName=L_ThumbShadow, Path=Background.Color}" BlurRadius="5" ShadowDepth="1.5" Direction="135" Opacity="{DynamicResource NeumorphicLightShadowOpacity}"/>
                                                        </Border.Effect>
                                                    </Border>
                                                    <Border CornerRadius="10" Background="{DynamicResource NeumorphicBgBrush}" BorderThickness="1">
                                                        <Border.BorderBrush>
                                                            <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                                                <GradientStop Color="{Binding ElementName=L_ThumbShadow, Path=Background.Color}" Offset="0.0"/>
                                                                <GradientStop Color="{Binding ElementName=D_ThumbShadow, Path=Background.Color}" Offset="1.0"/>
                                                            </LinearGradientBrush>
                                                        </Border.BorderBrush>
                                                    </Border>
                                                    <Ellipse Width="6" Height="6" Fill="{DynamicResource Accent}"/>
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
        
        <!-- Sunken TextBox Style -->
        <Style x:Key="NeumorphicTxt" TargetType="TextBox">
            <Setter Property="Foreground" Value="{DynamicResource TextMain}"/>
            <Setter Property="CaretBrush" Value="{DynamicResource Accent}"/>
            <Setter Property="Padding" Value="12,0"/>
            <Setter Property="MinHeight" Value="36"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Grid>
                            <Border x:Name="L_Shadow" Background="{DynamicResource NeumorphicLightShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Shadow" Background="{DynamicResource NeumorphicDarkShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="L_Recess" Background="{DynamicResource NeumorphicLightRecessBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Recess" Background="{DynamicResource NeumorphicDarkRecessBrush}" Visibility="Collapsed"/>
        
                            <!-- Recessed Pocket Border -->
                            <Border CornerRadius="8" BorderThickness="1.5">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=D_Recess, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=L_Recess, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                                <Border.BorderBrush>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=D_Shadow, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=L_Shadow, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.BorderBrush>
                                <ScrollViewer x:Name="PART_ContentHost" Margin="{TemplateBinding Padding}" VerticalAlignment="{TemplateBinding VerticalContentAlignment}"/>
                            </Border>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- Segmented RadioButton (Sunken when checked) -->
        <Style x:Key="NeumorphicSegment" TargetType="RadioButton">
            <Setter Property="Foreground" Value="{DynamicResource TextMain}"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="RadioButton">
                        <Grid x:Name="GridContainer" Margin="5,0">
                            <Border x:Name="L_Shadow" Background="{DynamicResource NeumorphicLightShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Shadow" Background="{DynamicResource NeumorphicDarkShadowBrush}" Visibility="Collapsed"/>
                            <Border x:Name="L_Recess" Background="{DynamicResource NeumorphicLightRecessBrush}" Visibility="Collapsed"/>
                            <Border x:Name="D_Recess" Background="{DynamicResource NeumorphicDarkRecessBrush}" Visibility="Collapsed"/>
        
                            <!-- Raised State Shadows -->
                            <Border x:Name="DarkShadow" CornerRadius="8" Background="{DynamicResource NeumorphicBgBrush}">
                                <Border.Effect>
                                    <DropShadowEffect Color="{Binding ElementName=D_Shadow, Path=Background.Color}" BlurRadius="{DynamicResource NeumorphicBlurRadius}" ShadowDepth="{DynamicResource NeumorphicShadowDepth}" Direction="315" Opacity="{DynamicResource NeumorphicDarkShadowOpacity}"/>
                                </Border.Effect>
                            </Border>
                            <Border x:Name="LightShadow" CornerRadius="8" Background="{DynamicResource NeumorphicBgBrush}">
                                <Border.Effect>
                                    <DropShadowEffect Color="{Binding ElementName=L_Shadow, Path=Background.Color}" BlurRadius="{DynamicResource NeumorphicBlurRadius}" ShadowDepth="{DynamicResource NeumorphicShadowDepth}" Direction="135" Opacity="{DynamicResource NeumorphicLightShadowOpacity}"/>
                                </Border.Effect>
                            </Border>
        
                            <!-- Sunken Pocket -->
                            <Border x:Name="SunkenBg" CornerRadius="8" Visibility="Collapsed">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=D_Recess, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=L_Recess, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                                <Border.BorderBrush>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=D_Shadow, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=L_Shadow, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.BorderBrush>
                                <Border BorderThickness="1.5" CornerRadius="8"/>
                            </Border>
        
                            <!-- Main Label -->
                            <Border x:Name="ContentBorder" CornerRadius="8" Background="{DynamicResource NeumorphicBgBrush}" BorderThickness="1" Padding="16,8">
                                <Border.BorderBrush>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="{Binding ElementName=L_Shadow, Path=Background.Color}" Offset="0.0"/>
                                        <GradientStop Color="{Binding ElementName=D_Shadow, Path=Background.Color}" Offset="1.0"/>
                                    </LinearGradientBrush>
                                </Border.BorderBrush>
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="DarkShadow" Property="Visibility" Value="Collapsed"/>
                                <Setter TargetName="LightShadow" Property="Visibility" Value="Collapsed"/>
                                <Setter TargetName="ContentBorder" Property="Background" Value="Transparent"/>
                                <Setter TargetName="ContentBorder" Property="BorderBrush" Value="Transparent"/>
                                <Setter TargetName="SunkenBg" Property="Visibility" Value="Visible"/>
                                <Setter Property="TextElement.Foreground" Value="{DynamicResource Accent}"/>
                                <Setter Property="FontWeight" Value="SemiBold"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
)'

; ==============================================================================
; LOAD THEMES FROM THEMES.INI
; ==============================================================================
LoadThemes() {
    iniPath := FileExist("themes.ini") ? "themes.ini" : (FileExist("..\themes.ini") ? "..\themes.ini" : (FileExist("..\..\themes.ini") ? "..\..\themes.ini" : "themes.ini"))
    if !FileExist(iniPath) {
        iniPath := "c:\projects\ahk\ahk-xaml\examples\themes.ini"
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
; NEUMORPHIC COLOR MATH ALGORITHM
; ==============================================================================
CalculateNeumorphicColors(bgHex) {
    hex := StrReplace(bgHex, "#")
    if (StrLen(hex) == 8) {
        alpha := SubStr(hex, 1, 2)
        hex := SubStr(hex, 3)
    } else {
        alpha := "FF"
    }

    ; Parse R, G, B
    r := Integer("0x" SubStr(hex, 1, 2))
    g := Integer("0x" SubStr(hex, 3, 2))
    b := Integer("0x" SubStr(hex, 5, 2))

    ; Determine if background is light or dark (YIQ Brightness Formula)
    brightness := (r * 299 + g * 587 + b * 114) / 1000

    if (brightness < 120) {
        ; --- DARK BACKGROUND ---
        r_l := Min(255, r + 24)
        g_l := Min(255, g + 24)
        b_l := Min(255, b + 28) ; slight cool glow

        r_d := Max(0, r - 15)
        g_d := Max(0, g - 15)
        b_d := Max(0, b - 15)

        r_rec_d := Max(0, r - 7)
        g_rec_d := Max(0, g - 7)
        b_rec_d := Max(0, b - 7)

        r_rec_l := Min(255, r + 8)
        g_rec_l := Min(255, g + 8)
        b_rec_l := Min(255, b + 8)
    } else {
        ; --- LIGHT BACKGROUND ---
        r_l := Min(255, r + (255 - r) * 0.8)
        g_l := Min(255, g + (255 - g) * 0.8)
        b_l := Min(255, b + (255 - b) * 0.8)

        r_d := Max(0, Integer(r * 0.85))
        g_d := Max(0, Integer(g * 0.85))
        b_d := Max(0, Integer(b * 0.87))

        r_rec_d := Max(0, Integer(r * 0.94))
        g_rec_d := Max(0, Integer(g * 0.94))
        b_rec_d := Max(0, Integer(b * 0.95))

        r_rec_l := Min(255, r + (255 - r) * 0.2)
        g_rec_l := Min(255, g + (255 - g) * 0.2)
        b_rec_l := Min(255, b + (255 - b) * 0.2)
    }

    lightHex := "#" alpha . Format("{1:02X}{2:02X}{3:02X}", r_l, g_l, b_l)
    darkHex := "#" alpha . Format("{1:02X}{2:02X}{3:02X}", r_d, g_d, b_d)

    recLightHex := "#" alpha . Format("{1:02X}{2:02X}{3:02X}", r_rec_l, g_rec_l, b_rec_l)
    recDarkHex := "#" alpha . Format("{1:02X}{2:02X}{3:02X}", r_rec_d, g_rec_d, b_rec_d)

    bgOpaque := "#FF" . Format("{1:02X}{2:02X}{3:02X}", r, g, b)

    return {
        Light: lightHex,
        Dark: darkHex,
        RecessLight: recLightHex,
        RecessDark: recDarkHex,
        BgOpaque: bgOpaque,
        IsDark: (brightness < 120)
    }
}

; ==============================================================================
; APP WINDOW SCAFFOLDING
; ==============================================================================
app := XAML_GUI("Neumorphic Studio", {
    Sidebar: true,
    BurgerMenu: true,
    TitleBarHeight: 45,
    AppIcon: false,
    Width: 1000,
    Height: 700,
    Resize: true
})

app.SkipDefaultThemeOnLoad := true
app.tabs.Visibility("Collapsed")
app.main.Background("Transparent")

; Inject Neumorphic XAML Resources globally at root grid level so sidebar has access as well
app.X.InjectResources(NeumorphicStyles)

; Add custom sliders to Sidebar Panel
customSp := app.sidebarPanel.Add("StackPanel").Margin("0,10,0,0")
customSp.Add("TextBlock").Text("NEUMORPHIC SHADOWS").Margin("0,15,0,5").FontSize(11).FontWeight("Bold").Foreground("{DynamicResource TextSub}")

customSp.Add("TextBlock").Text("Blur Radius").Margin("0,5,0,0").FontSize(10).Foreground("{DynamicResource TextSub}")
customSp.Add("Slider").Name("SldBlur").Minimum(2).Maximum(35).Value(String(AppState.ShadowBlur)).Margin("0,0,0,10").Style("{StaticResource NeumorphicSld}")
    .On("ValueChanged", (state, *) => HandleShadowCustomization(state))

customSp.Add("TextBlock").Text("Shadow Depth").Margin("0,5,0,0").FontSize(10).Foreground("{DynamicResource TextSub}")
customSp.Add("Slider").Name("SldDepth").Minimum(1).Maximum(15).Value(String(AppState.ShadowDepth)).Margin("0,0,0,10").Style("{StaticResource NeumorphicSld}")
    .On("ValueChanged", (state, *) => HandleShadowCustomization(state))

customSp.Add("TextBlock").Text("Light Opacity").Margin("0,5,0,0").FontSize(10).Foreground("{DynamicResource TextSub}")
customSp.Add("Slider").Name("SldLightOp").Minimum(0.0).Maximum(1.0).Value(String(AppState.LightShadowOpacity)).Margin("0,0,0,10").Style("{StaticResource NeumorphicSld}")
    .On("ValueChanged", (state, *) => HandleShadowCustomization(state))

customSp.Add("TextBlock").Text("Dark Opacity").Margin("0,5,0,0").FontSize(10).Foreground("{DynamicResource TextSub}")
customSp.Add("Slider").Name("SldDarkOp").Minimum(0.0).Maximum(1.0).Value(String(AppState.DarkShadowOpacity)).Margin("0,0,0,10").Style("{StaticResource NeumorphicSld}")
    .On("ValueChanged", (state, *) => HandleShadowCustomization(state))

; ==============================================================================
; GENERATE THE INTERFACE (AHK BUILDER API)
; ==============================================================================
mainScroll := app.main.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").HorizontalScrollBarVisibility("Disabled")
layoutGrid := mainScroll.Add("Grid").Margin("10,10,10,10")
layoutGrid.Cols("450", "*")

; Hidden global color resources holders at root level for main window scope bindings
globalLShadow := layoutGrid.Add("Border").Name("GlobalLShadow").Background("{DynamicResource NeumorphicLightShadowBrush}").Visibility("Collapsed")
globalDShadow := layoutGrid.Add("Border").Name("GlobalDShadow").Background("{DynamicResource NeumorphicDarkShadowBrush}").Visibility("Collapsed")
globalLRecess := layoutGrid.Add("Border").Name("GlobalLRecess").Background("{DynamicResource NeumorphicLightRecessBrush}").Visibility("Collapsed")
globalDRecess := layoutGrid.Add("Border").Name("GlobalDRecess").Background("{DynamicResource NeumorphicDarkRecessBrush}").Visibility("Collapsed")

; ------------------------------------------------------------------------------
; LEFT PANEL (MUSIC PLAYER & VOL DIAL)
; ------------------------------------------------------------------------------
leftCol := layoutGrid.Add("StackPanel").Grid_Column(0).Margin("10")

; Player Card
playerCard := leftCol.Add("ContentControl").Style("{StaticResource NeumorphicCard}").Padding("20")
playerSp := playerCard.Add("StackPanel")

playerSp.Add("TextBlock").Text("MUSIC PLAYER").FontSize(11).FontWeight("Bold").Foreground("{DynamicResource TextSub}").HorizontalAlignment("Center").Margin("0,0,0,10")

; --- Vinyl Record ---
vinylGrid := playerSp.Add("Grid").Height(140).Width(140).HorizontalAlignment("Center").Margin("0,10,0,15")
vinylGrid.Add("Ellipse").Fill("#18191D").Stroke("#2D3035").StrokeThickness(1)
vinylGrid.Add("Ellipse").Margin("12").Stroke("#232429").StrokeThickness(0.8)
vinylGrid.Add("Ellipse").Margin("24").Stroke("#232429").StrokeThickness(0.8)
vinylGrid.Add("Ellipse").Margin("36").Stroke("#232429").StrokeThickness(0.8)
vinylGrid.Add("Ellipse").Margin("48").Stroke("#232429").StrokeThickness(0.8)
vinylGrid.Add("Ellipse").Margin("52").Fill("{DynamicResource Accent}")
vinylGrid.Add("Ellipse").Margin("63").Fill("{DynamicResource NeumorphicBgBrush}")

playerSp.Add("TextBlock").Text("Low Life").FontSize(18).FontWeight("Bold").Foreground("{DynamicResource TextMain}").HorizontalAlignment("Center")
playerSp.Add("TextBlock").Text("Future ft. The Weeknd").FontSize(13).Foreground("{DynamicResource TextSub}").HorizontalAlignment("Center").Margin("0,2,0,15")

; --- Progress Track Slider ---
sliderContainer := playerSp.Add("Grid").Margin("0,0,0,10")
sliderContainer.Cols("*", "Auto")
playSlider := sliderContainer.Add("Slider").Name("PlayProgressSlider").Style("{StaticResource NeumorphicSld}").Minimum(0).Maximum(String(AppState.PlayDuration)).Value(String(AppState.PlayProgress)).Grid_Column(0)
    .On("ValueChanged", (state, *) => HandleProgressSlide(state))
    .Track()
timeText := sliderContainer.Add("TextBlock").Name("TxtTime").Text("1:17").Width(45).TextAlignment("Right").VerticalAlignment("Center").Grid_Column(1).Foreground("{DynamicResource TextSub}").FontSize(12).Margin("8,0,0,0")

; --- Player Control Buttons ---
btnSp := playerSp.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Center").Margin("0,10,0,5")

btnPrev := btnSp.Add("Button").Name("BtnPrev").Style("{StaticResource NeumorphicCircleBtn}").Width(44).Height(44).Margin("0,0,15,0")
    .On("Click", (*) => OffsetProgress(-15))
btnPrev.Add("TextBlock").Text(Chr(0xE892)).FontFamily("Segoe Fluent Icons").FontSize(14).VerticalAlignment("Center").HorizontalAlignment("Center")

btnPlay := btnSp.Add("Button").Name("BtnPlay").Style("{StaticResource NeumorphicCircleBtn}").Width(56).Height(56).Margin("0,0,15,0")
    .On("Click", (*) => TogglePlay())
btnPlayIcon := btnPlay.Add("TextBlock").Name("BtnPlayIcon").Text(Chr(0xE768)).FontFamily("Segoe Fluent Icons").FontSize(18).VerticalAlignment("Center").HorizontalAlignment("Center")

btnNext := btnSp.Add("Button").Name("BtnNext").Style("{StaticResource NeumorphicCircleBtn}").Width(44).Height(44)
    .On("Click", (*) => OffsetProgress(15))
btnNext.Add("TextBlock").Text(Chr(0xE893)).FontFamily("Segoe Fluent Icons").FontSize(14).VerticalAlignment("Center").HorizontalAlignment("Center")



; --- Rotary Volume Dial Widget ---
dialCard := leftCol.Add("ContentControl").Style("{StaticResource NeumorphicCard}").Padding("15").Margin("0,10,0,0")
dialSp := dialCard.Add("StackPanel")

dialSp.Add("TextBlock").Text("VOLUME CONTROLLER").FontSize(11).FontWeight("Bold").Foreground("{DynamicResource TextSub}").HorizontalAlignment("Center").Margin("0,0,0,10")

dialGrid := dialSp.Add("Grid").Name("DialGrid").Height(120).Width(120).HorizontalAlignment("Center").Margin("0,5,0,10")
    .On("PreviewMouseLeftButtonDown", (state, ctrl, event) => StartDialDrag(state, ctrl, event))
    .On("PreviewMouseLeftButtonUp", (state, ctrl, event) => StopDialDrag(state, ctrl, event))
    .On("PreviewMouseMove", (state, ctrl, event) => ProcessDialDrag(state, ctrl, event))

; Sunken Outer Track ring for the Dial
dialGrid.Add("Ellipse").StrokeThickness(3).Margin("-6").Stroke("{DynamicResource NeumorphicDarkRecessBrush}")

; Dial Knob Grid with RotateTransform
dialKnob := dialGrid.Add("Grid").Name("DialKnob").RenderTransformOrigin("0.5,0.5").Cursor("Hand")

dialKnobRt := dialKnob.Add("Grid.RenderTransform")
dialKnobRt.Add("RotateTransform").SetProp("x:Name", "DialRotate").Angle("162")

; Layered raised borders with dynamic DropShadows
knobBdr1 := dialKnob.Add("Border").CornerRadius("60").Background("{DynamicResource NeumorphicBgBrush}")
eff1 := knobBdr1.Add("Border.Effect").Add("DropShadowEffect")
eff1.SetProp("Color", "{Binding ElementName=GlobalDShadow, Path=Background.Color}").BlurRadius(12).ShadowDepth(4).Direction(315).Opacity("{DynamicResource NeumorphicDarkShadowOpacity}")

knobBdr2 := dialKnob.Add("Border").CornerRadius("60").Background("{DynamicResource NeumorphicBgBrush}")
eff2 := knobBdr2.Add("Border.Effect").Add("DropShadowEffect")
eff2.SetProp("Color", "{Binding ElementName=GlobalLShadow, Path=Background.Color}").BlurRadius(12).ShadowDepth(4).Direction(135).Opacity("{DynamicResource NeumorphicLightShadowOpacity}")

dialKnob.Add("Border").CornerRadius("60").Background("{DynamicResource NeumorphicBgBrush}")

; Indicator dot on the rotary knob representing volume level
dialKnob.Add("Ellipse").Width(8).Height(8).Fill("{DynamicResource Accent}").VerticalAlignment("Top").Margin("0,14,0,0")

; Volume display text inside dial card
dialSp.Add("TextBlock").Name("TxtVolume").Text("Vol: 45%").FontSize(14).FontWeight("Bold").Foreground("{DynamicResource TextMain}").HorizontalAlignment("Center").Margin("0,5,0,0")


; ------------------------------------------------------------------------------
; RIGHT PANEL (FINANCE DASHBOARD & ANALYTICS)
; ------------------------------------------------------------------------------
rightCol := layoutGrid.Add("StackPanel").Grid_Column(1).Margin("10")

; --- Segmented Tab Control ---
tabsGrid := rightCol.Add("Grid").Margin("8,0,8,10")
tabsGrid.Cols("*", "*", "*")

tabOverview := tabsGrid.Add("RadioButton").Name("TabOverview").Style("{StaticResource NeumorphicSegment}").Content("Overview").Grid_Column(0).IsChecked("True")
    .On("Checked", (*) => SwitchTab("Overview"))
tabWallet := tabsGrid.Add("RadioButton").Name("TabWallet").Style("{StaticResource NeumorphicSegment}").Content("Wallet").Grid_Column(1)
    .On("Checked", (*) => SwitchTab("Wallet"))
tabAnalytics := tabsGrid.Add("RadioButton").Name("TabAnalytics").Style("{StaticResource NeumorphicSegment}").Content("Analytics").Grid_Column(2)
    .On("Checked", (*) => SwitchTab("Analytics"))


; --- TAB 1: OVERVIEW CARD (Quick Settings & Form) ---
viewOverview := rightCol.Add("StackPanel").Name("ViewOverview")

overviewCard := viewOverview.Add("ContentControl").Style("{StaticResource NeumorphicCard}").Padding("20")
overviewSp := overviewCard.Add("StackPanel")

overviewSp.Add("TextBlock").Text("SYSTEM SERVICES").FontSize(11).FontWeight("Bold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,15")

; Toggle Switch card item
toggleGrid := overviewSp.Add("Grid").Margin("0,0,0,15")
toggleGrid.Cols("*", "Auto")
toggleGrid.Add("TextBlock").Text("Notify about new services").FontSize(14).Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").Grid_Column(0)
tglServices := toggleGrid.Add("CheckBox").Name("TglServices").Style("{StaticResource NeumorphicSwitch}").IsChecked("True").Grid_Column(1)
    .On("Checked", (*) => HandleToggle(true))
    .On("Unchecked", (*) => HandleToggle(false))

; Input Text Box card item
overviewSp.Add("TextBlock").Text("Search query").FontSize(13).Foreground("{DynamicResource TextSub}").Margin("0,5,0,5")
searchBox := overviewSp.Add("TextBox").Name("TxtSearch").Style("{StaticResource NeumorphicTxt}").Text("").Padding("12,8").Margin("0,0,0,15")
    .On("TextChanged", (state, *) => HandleSearch(state))
    .Track()

; --- Sunken Services List Container ---
servicesPanel := overviewSp.Add("StackPanel").Name("ServicesPanel").Margin("0,10,0,15")
servicesPanel.Add("TextBlock").Text("ACTIVE SYSTEM SERVICES").FontSize(11).FontWeight("Bold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,10")

Loop ServicesData.Length {
    service := ServicesData[A_Index]
    rowBdr := servicesPanel.Add("Border").Name("ServiceRow_" A_Index).Height(48).Margin("0,0,0,10").CornerRadius("8").BorderThickness("1.5")
    
    rowBg := rowBdr.Add("Border.Background").Add("LinearGradientBrush").StartPoint("0,0").EndPoint("1,1")
    rowBg.Add("GradientStop").SetProp("Color", "{Binding ElementName=GlobalDRecess, Path=Background.Color}").Offset("0.0")
    rowBg.Add("GradientStop").SetProp("Color", "{Binding ElementName=GlobalLRecess, Path=Background.Color}").Offset("1.0")
    
    rowBb := rowBdr.Add("Border.BorderBrush").Add("LinearGradientBrush").StartPoint("0,0").EndPoint("1,1")
    rowBb.Add("GradientStop").SetProp("Color", "{Binding ElementName=GlobalDShadow, Path=Background.Color}").Offset("0.0")
    rowBb.Add("GradientStop").SetProp("Color", "{Binding ElementName=GlobalLShadow, Path=Background.Color}").Offset("1.0")
    
    rowGrid := rowBdr.Add("Grid").Margin("12,0,12,0")
    rowGrid.Cols("Auto", "*", "Auto")
    rowGrid.Add("TextBlock").Text(service.Icon).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize(14).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center").Grid_Column(0).Margin("0,0,12,0")
    rowGrid.Add("TextBlock").Text(service.Name).FontSize(13).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").VerticalAlignment("Center").Grid_Column(1)
    
    statusGrid := rowGrid.Add("Grid").Grid_Column(2).VerticalAlignment("Center")
    statusGrid.Cols("Auto", "Auto")
    statusGrid.Add("Ellipse").Name("ServiceDot_" A_Index).Width(8).Height(8).Fill(service.Color).VerticalAlignment("Center").Grid_Column(0).Margin("0,0,6,0")
    statusGrid.Add("TextBlock").Name("ServiceStatus_" A_Index).Text(service.Status).FontSize(12).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center").Grid_Column(1)
}

overviewSp.Add("TextBlock").Text("INTERACTIVE CONTROLS").FontSize(11).FontWeight("Bold").Foreground("{DynamicResource TextSub}").Margin("0,10,0,10")

; Raised action buttons pair
actSp := overviewSp.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Left").Margin("0,5,0,5")
btnTestDialog := actSp.Add("Button").Name("BtnTestDialog").Style("{StaticResource NeumorphicBtn}").Content("Trigger Dialog").Margin("0,0,15,0")
    .On("Click", (*) => ShowNeumorphicDialog())
btnNotify := actSp.Add("Button").Name("BtnNotify").Style("{StaticResource NeumorphicBtn}").Content("Send Toast")
    .On("Click", (*) => app.ShowSnackbar("Neumorphic update complete!"))



; --- TAB 2: WALLET CARD (Credit Card & Limit) ---
viewWallet := rightCol.Add("StackPanel").Name("ViewWallet").Visibility("Collapsed")

walletCard := viewWallet.Add("ContentControl").Style("{StaticResource NeumorphicCard}").Padding("20")
walletSp := walletCard.Add("StackPanel")

walletSp.Add("TextBlock").Text("CRYPTO WALLET").FontSize(11).FontWeight("Bold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,15")

; Render a physical raised card design inside the card!
creditCardBdr := walletSp.Add("Border").Height(140).CornerRadius("12").Padding("20").Margin("0,0,0,20")

ccBg := creditCardBdr.Add("Border.Background").Add("LinearGradientBrush").StartPoint("0,0").EndPoint("1,1")
ccBg.Add("GradientStop").SetProp("Color", "#2A2D3C").Offset("0.0")
ccBg.Add("GradientStop").SetProp("Color", "#161823").Offset("1.0")

ccBorderBrush := creditCardBdr.Add("Border.BorderBrush").Add("LinearGradientBrush").StartPoint("0,0").EndPoint("1,1")
ccBorderBrush.Add("GradientStop").SetProp("Color", "#4A4F65").Offset("0.0")
ccBorderBrush.Add("GradientStop").SetProp("Color", "#202230").Offset("1.0")

creditCardBdr.BorderThickness("1.5")
creditCardBdr.Add("Border.Effect").Add("DropShadowEffect").SetProp("Color", "#000000").BlurRadius(12).ShadowDepth(4).Opacity(0.6)

ccSp := creditCardBdr.Add("Grid")
ccSp.Rows("*", "Auto", "Auto")

ccTop := ccSp.Add("Grid").Grid_Row(0)
ccTop.Cols("*", "Auto")
ccTop.Add("TextBlock").Text("CRYPTO").FontWeight("Bold").FontSize(18).Foreground("#ECEFF4").Grid_Column(0)
ccTop.Add("TextBlock").Text("VISA").FontStyle("Italic").FontWeight("Bold").FontSize(18).Foreground("#ECEFF4").Grid_Column(1)

ccSp.Add("TextBlock").Text("5883 6804 2402 3649").FontFamily("Consolas").FontSize(18).Foreground("#ECEFF4").Grid_Row(1).VerticalAlignment("Center").Margin("0,10,0,10")

ccBottom := ccSp.Add("Grid").Grid_Row(2)
ccBottom.Cols("*", "Auto")
ccBottom.Add("TextBlock").Text("VAL: 08/29").FontSize(12).Foreground("#88C0D0").Grid_Column(0)
ccBottom.Add("TextBlock").Text("JOHN DOE").FontSize(12).Foreground("#88C0D0").Grid_Column(1)

; Balance display underneath in a side-by-side layout with a circular progress ring
balanceGrid := walletSp.Add("Grid").Margin("0,0,0,15")
balanceGrid.Cols("*", "Auto")

balanceSp := balanceGrid.Add("StackPanel").Grid_Column(0)
balanceSp.Add("TextBlock").Text("Current Balance").FontSize(13).Foreground("{DynamicResource TextSub}")
balanceSp.Add("TextBlock").Name("TxtBalance").Text("$14,020.44").FontSize(28).FontWeight("Bold").Foreground("{DynamicResource TextMain}").Margin("0,2,0,15")

; Sunken circular progress gauge
gaugeGrid := balanceGrid.Add("Grid").Grid_Column(1).Width(100).Height(100).Margin("10,0,10,0")
gaugeGrid.Add("Ellipse").Width(90).Height(90).StrokeThickness(8).Stroke("{DynamicResource NeumorphicDarkRecessBrush}")

gaugeActive := gaugeGrid.Add("Ellipse").Name("ProgressRingPath").Width(90).Height(90).StrokeThickness(8).Stroke("{DynamicResource Accent}").StrokeDashCap("Round").RenderTransformOrigin("0.5,0.5")
gaugeActive.SetProp("StrokeDashArray", "32.2, 32.2").SetProp("StrokeDashOffset", "25.116") ; default to 22% (32.2 * (1 - 0.22) = 25.116)

gaugeActiveRt := gaugeActive.Add("Ellipse.RenderTransform")
gaugeActiveRt.Add("RotateTransform").Angle("-90")

gaugeTextSp := gaugeGrid.Add("StackPanel").VerticalAlignment("Center").HorizontalAlignment("Center")
gaugeTextSp.Add("TextBlock").Name("TxtProgressVal").Text("22%").FontSize(16).FontWeight("Bold").Foreground("{DynamicResource TextMain}").HorizontalAlignment("Center")
gaugeTextSp.Add("TextBlock").Text("limit used").FontSize(9).Foreground("{DynamicResource TextSub}").HorizontalAlignment("Center")

; Limit Progress bar in a sunken slot
limitSp := walletSp.Add("StackPanel")
limitSp.Add("TextBlock").Name("TxtLimitUsed").Text("Credit Limit Used: $220 / $1000").FontSize(12).Foreground("{DynamicResource TextSub}").Margin("0,0,0,5")

limitBarSlot := limitSp.Add("Border").Height(8).CornerRadius("4").BorderThickness("1.5")

slotBg := limitBarSlot.Add("Border.Background").Add("LinearGradientBrush").StartPoint("0,0").EndPoint("1,1")
slotBg.Add("GradientStop").SetProp("Color", "{Binding ElementName=GlobalDRecess, Path=Background.Color}").Offset("0.0")
slotBg.Add("GradientStop").SetProp("Color", "{Binding ElementName=GlobalLRecess, Path=Background.Color}").Offset("1.0")

slotBb := limitBarSlot.Add("Border.BorderBrush").Add("LinearGradientBrush").StartPoint("0,0").EndPoint("1,1")
slotBb.Add("GradientStop").SetProp("Color", "{Binding ElementName=GlobalDShadow, Path=Background.Color}").Offset("0.0")
slotBb.Add("GradientStop").SetProp("Color", "{Binding ElementName=GlobalLShadow, Path=Background.Color}").Offset("1.0")

limitBarVal := limitBarSlot.Add("Border").Name("LimitBarVal").Background("{DynamicResource Accent}").CornerRadius("4").HorizontalAlignment("Left").Width("70")


; --- TAB 3: ANALYTICS CARD (Graphs) ---
viewAnalytics := rightCol.Add("StackPanel").Name("ViewAnalytics").Visibility("Collapsed")

chartCard := viewAnalytics.Add("ContentControl").Style("{StaticResource NeumorphicCard}").Padding("20")
chartSp := chartCard.Add("StackPanel")

chartSp.Add("TextBlock").Text("WEEKLY PERFORMANCE").FontSize(11).FontWeight("Bold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,20")

; --- Chart Columns Bar Container ---
chartRow := chartSp.Add("Grid").Height(150).HorizontalAlignment("Center").Margin("0,0,0,20")
chartRow.Cols("Auto", "Auto", "Auto", "Auto", "Auto")

; Create 5 vertical bars
CreateChartBar(chartRow, 0, "Mon", ChartValues[1])
CreateChartBar(chartRow, 1, "Tue", ChartValues[2])
CreateChartBar(chartRow, 2, "Wed", ChartValues[3])
CreateChartBar(chartRow, 3, "Thu", ChartValues[4])
CreateChartBar(chartRow, 4, "Fri", ChartValues[5])

CreateChartBar(parent, index, label, val) {
    cell := parent.Add("StackPanel").Grid_Column(String(index)).Width(50).Margin("10,0").HorizontalAlignment("Center")

    ; Sunken vertical track slot
    trackBdr := cell.Add("Border").Height(120).Width(24).CornerRadius("12").BorderThickness("1.5")

    trackBg := trackBdr.Add("Border.Background").Add("LinearGradientBrush").StartPoint("0,0").EndPoint("1,1")
    trackBg.Add("GradientStop").SetProp("Color", "{Binding ElementName=GlobalDRecess, Path=Background.Color}").Offset("0.0")
    trackBg.Add("GradientStop").SetProp("Color", "{Binding ElementName=GlobalLRecess, Path=Background.Color}").Offset("1.0")

    trackBb := trackBdr.Add("Border.BorderBrush").Add("LinearGradientBrush").StartPoint("0,0").EndPoint("1,1")
    trackBb.Add("GradientStop").SetProp("Color", "{Binding ElementName=GlobalDShadow, Path=Background.Color}").Offset("0.0")
    trackBb.Add("GradientStop").SetProp("Color", "{Binding ElementName=GlobalLShadow, Path=Background.Color}").Offset("1.0")

    ; Fill bar column
    trackBdr.Add("Border").Name("ChartCol_" (index + 1)).Background("{DynamicResource Accent}").CornerRadius("12").VerticalAlignment("Bottom").Height(String(val)).Margin("2")

    cell.Add("TextBlock").Text(label).FontSize(11).Foreground("{DynamicResource TextSub}").HorizontalAlignment("Center").Margin("0,5,0,0")
}

; Chart control buttons Sp
chartBtnSp := chartSp.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Center")
btnRandomize := chartBtnSp.Add("Button").Name("BtnRandomize").Style("{StaticResource NeumorphicBtn}").Content("Randomize Data")
    .On("Click", (*) => RandomizeChart())



; ==============================================================================
; INITIALIZATION & EVENT DISPATCHING
; ==============================================================================
ui := app.Compile()
ui.Track("PlayProgressSlider")
ui.Track("TxtSearch")
ui.Track("SldBlur")
ui.Track("SldDepth")
ui.Track("SldLightOp")
ui.Track("SldDarkOp")
ui.Track("DialGrid")

; Handle dynamic theme loading and first render
ui.OnEvent("Window", "Loaded", HandleWindowLoaded)
ui.OnEvent("Window", "Closing", HandleWindowClosing)
ui.OnEvent("Window", "PreviewMouseLeftButtonUp", StopDialDrag)


; Volume Dial visual update
UpdateVolumeDial(AppState.Volume)

; ==============================================================================
; EVENT HANDLERS
; ==============================================================================
HandleWindowLoaded(state, ctrl, event) {
    ; Default to Dracula theme for that sexy dark neumorphism look on startup
    HandleThemeSelection("Dracula")
}

HandleWindowClosing(state, ctrl, event) {
    SetTimer(UpdatePlayProgress, 0)
    ExitApp()
}

HandleThemeSelection(themeName) {
    if !ThemeDefinitions.Has(themeName)
        return

    app.currentThemeName := themeName
    themeMap := ThemeDefinitions[themeName]


    ; 1. Apply DWM parameters from the themes.ini
    if (themeMap.Has("Window_DWM")) {
        ui.Update("Window", "DWM", themeMap["Window_DWM"])
    }

    ; Apply TitleBar defaults first so switching themes works cleanly
    titleBarColor := themeMap.Has("Resource_TitleBarColor") ? themeMap["Resource_TitleBarColor"] : "Transparent"
    titleBarForeground := themeMap.Has("Resource_TitleBarForeground") ? themeMap["Resource_TitleBarForeground"] : (themeMap.Has("Resource_TextMain") ? themeMap["Resource_TextMain"] : "#000000")
    ui.Update("Resource", "TitleBarColor", titleBarColor)
    ui.Update("Resource", "TitleBarForeground", titleBarForeground)

    ; 2. Feed core resources into the window
    for key, val in themeMap {
        if (InStr(key, "Resource_") == 1) {
            resName := SubStr(key, 10)
            ui.Update("Resource", resName, val)
        }
    }

    ; 3. Fetch background color & calculate Neumorphic light/dark shadow brushes
    bgHex := themeMap.Has("Resource_BgColor") ? themeMap["Resource_BgColor"] : "#F2F4FA"
    neumoColors := CalculateNeumorphicColors(bgHex)

    ; 4. Update the Neumorphic brushes in the WPF resources list
    ui.Update("Resource", "NeumorphicBgBrush", "Brush:" neumoColors.BgOpaque)
    ui.Update("Resource", "NeumorphicLightShadowBrush", "Brush:" neumoColors.Light)
    ui.Update("Resource", "NeumorphicDarkShadowBrush", "Brush:" neumoColors.Dark)
    ui.Update("Resource", "NeumorphicLightRecessBrush", "Brush:" neumoColors.RecessLight)
    ui.Update("Resource", "NeumorphicDarkRecessBrush", "Brush:" neumoColors.RecessDark)

    if (neumoColors.IsDark) {
        AppState.LightShadowOpacity := 0.25
        AppState.DarkShadowOpacity := 0.65
    } else {
        AppState.LightShadowOpacity := 0.90
        AppState.DarkShadowOpacity := 0.30
    }

    ui.Update("Resource", "NeumorphicLightShadowOpacity", "Double:" AppState.LightShadowOpacity)
    ui.Update("Resource", "NeumorphicDarkShadowOpacity", "Double:" AppState.DarkShadowOpacity)
    ui.Update("Resource", "NeumorphicBlurRadius", "Double:" AppState.ShadowBlur)
    ui.Update("Resource", "NeumorphicShadowDepth", "Double:" AppState.ShadowDepth)

    ; Synchronize the sidebar sliders visually
    ui.Update("SldLightOp", "Value", String(AppState.LightShadowOpacity))
    ui.Update("SldDarkOp", "Value", String(AppState.DarkShadowOpacity))
    ui.Update("SldBlur", "Value", String(AppState.ShadowBlur))
    ui.Update("SldDepth", "Value", String(AppState.ShadowDepth))
}

HandleShadowCustomization(state) {
    if state.Has("SldBlur")
        AppState.ShadowBlur := Round(Number(state["SldBlur"]))
    if state.Has("SldDepth")
        AppState.ShadowDepth := Round(Number(state["SldDepth"]))
    if state.Has("SldLightOp")
        AppState.LightShadowOpacity := Number(state["SldLightOp"])
    if state.Has("SldDarkOp")
        AppState.DarkShadowOpacity := Number(state["SldDarkOp"])

    ui.Update("Resource", "NeumorphicBlurRadius", "Double:" AppState.ShadowBlur)
    ui.Update("Resource", "NeumorphicShadowDepth", "Double:" AppState.ShadowDepth)
    ui.Update("Resource", "NeumorphicLightShadowOpacity", "Double:" AppState.LightShadowOpacity)
    ui.Update("Resource", "NeumorphicDarkShadowOpacity", "Double:" AppState.DarkShadowOpacity)
}

; Register callback to synchronize our Neumorphism shadow engine when theme changes
ui.OnEvent("ComboTheme", "SelectionChanged", (state, ctrl, event) => HandleThemeSelection(state["ComboTheme"]))

; --- Navigation Tabs Router ---
SwitchTab(targetTab) {
    AppState.ActiveTab := targetTab
    ui.Update("ViewOverview", "Visibility", (targetTab == "Overview") ? "Visible" : "Collapsed")
    ui.Update("ViewWallet", "Visibility", (targetTab == "Wallet") ? "Visible" : "Collapsed")
    ui.Update("ViewAnalytics", "Visibility", (targetTab == "Analytics") ? "Visible" : "Collapsed")
}

; --- Toggle Switch handler ---
HandleToggle(isChecked) {
    AppState.NotifyServices := isChecked
    statusText := isChecked ? "Enabled" : "Disabled"
    app.ShowSnackbar("Notifications " statusText)
}

; --- Text Input handler ---
HandleSearch(state) {
    if !state.Has("TxtSearch")
        return
    query := state["TxtSearch"]
    AppState.SearchQuery := query

    Loop ServicesData.Length {
        service := ServicesData[A_Index]
        if (query == "" || InStr(service.Name, query) || InStr(service.Status, query)) {
            ui.Update("ServiceRow_" A_Index, "Visibility", "Visible")
        } else {
            ui.Update("ServiceRow_" A_Index, "Visibility", "Collapsed")
        }
    }
}

; --- Music Slider Drag handler ---
HandleProgressSlide(state) {
    if !state.Has("PlayProgressSlider")
        return
    val := Round(Number(state["PlayProgressSlider"]))
    if (Abs(val - AppState.PlayProgress) > 1) {
        AppState.PlayProgress := val
        UpdateTimeText(val)
    }
}

OffsetProgress(seconds) {
    newVal := AppState.PlayProgress + seconds
    if (newVal < 0)
        newVal := 0
    if (newVal > AppState.PlayDuration)
        newVal := AppState.PlayDuration

    AppState.PlayProgress := newVal
    ui.Update("PlayProgressSlider", "Value", String(newVal))
    UpdateTimeText(newVal)
}

UpdateTimeText(secs) {
    m := secs // 60
    s := Mod(secs, 60)
    ui.Update("TxtTime", "Text", m ":" Format("{1:02}", s))
}

; --- Audio Play/Pause simulation ---
TogglePlay() {
    AppState.IsPlaying := !AppState.IsPlaying
    if (AppState.IsPlaying) {
        ; Play glyph -> Pause glyph
        ui.Update("BtnPlayIcon", "Text", Chr(0xE769))
        ui.Update("BtnPlay", "Background", "{DynamicResource Accent}")
        ui.Update("BtnPlayIcon", "Foreground", "White")
        SetTimer(UpdatePlayProgress, 1000)
        app.ShowSnackbar("Playing track...")
    } else {
        ; Pause glyph -> Play glyph
        ui.Update("BtnPlayIcon", "Text", Chr(0xE768))
        ui.Update("BtnPlay", "Background", "{DynamicResource NeumorphicBgBrush}")
        ui.Update("BtnPlayIcon", "Foreground", "{DynamicResource TextMain}")
        SetTimer(UpdatePlayProgress, 0)
        app.ShowSnackbar("Track paused")
    }
}

UpdatePlayProgress() {
    if (AppState.PlayProgress >= AppState.PlayDuration) {
        AppState.PlayProgress := 0
    } else {
        AppState.PlayProgress++
    }
    ui.Update("PlayProgressSlider", "Value", String(AppState.PlayProgress))
    UpdateTimeText(AppState.PlayProgress)
}

global DialDragState := { IsDragging: false }

StartDialDrag(state, ctrl, event) {
    DialDragState.IsDragging := true
    ProcessDialDrag(state, ctrl, event)
}

StopDialDrag(state, ctrl, event) {
    DialDragState.IsDragging := false
}

ProcessDialDrag(state, ctrl, event) {
    if (!DialDragState.IsDragging)
        return

    if (!GetKeyState("LButton", "P")) {
        DialDragState.IsDragging := false
        return
    }

    coords := state.Has("DialGrid") ? state["DialGrid"] : ""
    if (coords == "")
        return

    parts := StrSplit(coords, ",")
    if (parts.Length != 2)
        return

    x := Float(parts[1])
    y := Float(parts[2])

    ; Center of the 120x120 dial grid is (60, 60)
    dx := x - 60
    dy := y - 60

    if (dx == 0 && dy == 0)
        return

    pi := 3.14159265358979
    angleDeg := atan2(dy, dx) * 180 / pi + 90
    if (angleDeg < 0)
        angleDeg += 360

    vol := Round((angleDeg / 360) * 100)
    vol := Min(Max(vol, 0), 100)

    AppState.Volume := vol
    UpdateVolumeDial(vol)
}

UpdateVolumeDial(vol) {
    ; Map 0-100 to 0-360 degrees rotation angle
    angle := (vol / 100) * 360

    ; Update RotateTransform directly inside C#!
    ui.Update("DialRotate", "Angle", String(angle))
    ui.Update("TxtVolume", "Text", "Vol: " vol "%")
}

UpdateProgressRing(p) {
    offset := 32.2 * (1 - p / 100)
    ui.Update("ProgressRingPath", "StrokeDashOffset", String(offset))
    ui.Update("TxtProgressVal", "Text", Round(p) "%")
}

; --- Analytics Graph Randomizer ---
RandomizeChart() {
    ; 1. Randomize weekly performance chart
    Loop 5 {
        val := Random(10, 115)
        ChartValues[A_Index] := val
        ui.Update("ChartCol_" A_Index, "Height", String(val))
    }

    ; 2. Randomize limit progress ring
    randLimit := Random(10, 95)
    UpdateProgressRing(randLimit)

    ; Update credit limit text
    ui.Update("TxtLimitUsed", "Text", "Credit Limit Used: $" Round(randLimit * 10) " / $1000")
    ; Update the visual limit progress bar width
    ui.Update("LimitBarVal", "Width", String(Round(randLimit * 1.5)))

    ; 3. Randomize wallet balance
    randBal := Random(2000, 28000) + (Random(0, 99) / 100)
    balString := "$" . Format("{:,.2f}", randBal)
    ui.Update("TxtBalance", "Text", balString)

    ; 4. Randomize service statuses
    statuses := [
        { Status: "Active", Color: "#32D74B" },
        { Status: "Standby", Color: "#FF9F0A" },
        { Status: "Stopped", Color: "#FF453A" }
    ]
    Loop ServicesData.Length {
        randIdx := Random(1, statuses.Length)
        stat := statuses[randIdx]
        ServicesData[A_Index].Status := stat.Status
        ServicesData[A_Index].Color := stat.Color

        ui.Update("ServiceStatus_" A_Index, "Text", stat.Status)
        ui.Update("ServiceDot_" A_Index, "Fill", stat.Color)
    }

    app.ShowSnackbar("Dashboard data randomized!")
}

; --- Dialog Test trigger ---
ShowNeumorphicDialog() {
    res := XDialog.Show({
        Title: "Confirm Action",
        Message: "Do you want to confirm these Neumorphic settings? This demonstrates our styled modal box.",
        Icon: Chr(0xE73E),
        Buttons: ["Confirm", "Cancel"],
        Owner: ui.wpfHwnd,
        Theme: app.currentThemeName,
        Modal: true,
        DarkenOwner: true
    })
    if (res.Button == "Confirm") {
        app.ShowSnackbar("Confirmed!")
    }
}

atan2(y, x) {
    if (x > 0)
        return atan(y / x)
    else if (x < 0 && y >= 0)
        return atan(y / x) + 3.14159265358979
    else if (x < 0 && y < 0)
        return atan(y / x) - 3.14159265358979
    else if (x == 0 && y > 0)
        return 3.14159265358979 / 2
    else if (x == 0 && y < 0)
        return -3.14159265358979 / 2
    else
        return 0
}

app.Show()