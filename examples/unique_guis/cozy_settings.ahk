#Requires AutoHotkey v2.0
#SingleInstance Force

; Include core AHK-XAML libraries
#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Config.ahk"

; Pre-warm compilation cache
XAMLHost.Prewarm()

; Define Layout & Settings file
layoutIni := A_ScriptDir "\cozy_layout.ini"
avatarPath := A_ScriptDir "\..\data\cozy_avatar.png"

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

ReadIniStr(file, section, key, defaultVal) {
    try {
        return IniRead(file, section, key, defaultVal)
    } catch {
        return defaultVal
    }
}

; Load saved settings
global savedX := ReadIniStr(layoutIni, "Window", "X", "")
global savedY := ReadIniStr(layoutIni, "Window", "Y", "")
global savedTab := ReadIniStr(layoutIni, "Settings", "ActiveTab", "Settings")
global savedVolume := ReadIniInt(layoutIni, "Settings", "Volume", 60)
global savedSFX := ReadIniStr(layoutIni, "Settings", "SFX", "1")
global savedMusic := ReadIniStr(layoutIni, "Settings", "Music", "1")
global savedPlayerName := ReadIniStr(layoutIni, "Settings", "PlayerName", "Cozy Buddy")
global savedTheme := ReadIniStr(layoutIni, "Settings", "Theme", "Warm Honey")

; XAML String representing the cute cozy clipboard/diary frame
xamlString := '
(
    <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            Title="Cozy Settings" Width="490" Height="470"
            AllowsTransparency="True" Background="Transparent" WindowStyle="None"
            WindowStartupLocation="CenterScreen">
    
        <Window.Resources>
            <!-- Dynamic Theme Colors -->
            <SolidColorBrush x:Key="CozyOuterBg" Color="#B85328"/>
            <SolidColorBrush x:Key="CozyInnerBg" Color="#FED39E"/>
            <SolidColorBrush x:Key="CozyOutline" Color="#4D2514"/>
            <SolidColorBrush x:Key="CozySecOutline" Color="#853E1E"/>
            <SolidColorBrush x:Key="CozyText" Color="#5C3214"/>
            
            <!-- 3D Squishy Buttons styling -->
            
            <!-- Cozy Green Button -->
            <Style x:Key="CozyGreenButton" TargetType="Button">
                <Setter Property="Foreground" Value="White"/>
                <Setter Property="FontFamily" Value="Comic Sans MS, Segoe UI, sans-serif"/>
                <Setter Property="FontWeight" Value="Bold"/>
                <Setter Property="FontSize" Value="13"/>
                <Setter Property="Height" Value="36"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Grid Name="ButtonGrid">
                                <Border CornerRadius="12" Background="#3D6B00" Margin="0,3,0,-3" Name="ShadowBorder"/>
                                <Border CornerRadius="12" BorderThickness="2.5" BorderBrush="#E2FFB3" Margin="0" Name="ButtonFace">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                            <GradientStop Color="#8CE400" Offset="0"/>
                                            <GradientStop Color="#539600" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,0,2"/>
                                </Border>
                            </Grid>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="ButtonFace" Property="Background">
                                        <Setter.Value>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                                <GradientStop Color="#A2F51C" Offset="0"/>
                                                <GradientStop Color="#60AA00" Offset="1"/>
                                            </LinearGradientBrush>
                                        </Setter.Value>
                                    </Setter>
                                </Trigger>
                                <Trigger Property="IsPressed" Value="True">
                                    <Setter TargetName="ButtonFace" Property="Margin" Value="0,2,0,-2"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
    
            <!-- Cozy Blue Button -->
            <Style x:Key="CozyBlueButton" TargetType="Button">
                <Setter Property="Foreground" Value="White"/>
                <Setter Property="FontFamily" Value="Comic Sans MS, Segoe UI, sans-serif"/>
                <Setter Property="FontWeight" Value="Bold"/>
                <Setter Property="FontSize" Value="13"/>
                <Setter Property="Height" Value="34"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Grid Name="ButtonGrid">
                                <Border CornerRadius="12" Background="#154CA3" Margin="0,3,0,-3" Name="ShadowBorder"/>
                                <Border CornerRadius="12" BorderThickness="2.5" BorderBrush="#D1E4FF" Margin="0" Name="ButtonFace">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                            <GradientStop Color="#5DA5F9" Offset="0"/>
                                            <GradientStop Color="#1D64D6" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,0,2"/>
                                </Border>
                            </Grid>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="ButtonFace" Property="Background">
                                        <Setter.Value>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                                <GradientStop Color="#77B5FF" Offset="0"/>
                                                <GradientStop Color="#2C75EB" Offset="1"/>
                                            </LinearGradientBrush>
                                        </Setter.Value>
                                    </Setter>
                                </Trigger>
                                <Trigger Property="IsPressed" Value="True">
                                    <Setter TargetName="ButtonFace" Property="Margin" Value="0,2,0,-2"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
    
            <!-- Cozy Red Button -->
            <Style x:Key="CozyRedButton" TargetType="Button">
                <Setter Property="Foreground" Value="White"/>
                <Setter Property="FontFamily" Value="Comic Sans MS, Segoe UI, sans-serif"/>
                <Setter Property="FontWeight" Value="Bold"/>
                <Setter Property="FontSize" Value="13"/>
                <Setter Property="Height" Value="36"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Grid Name="ButtonGrid">
                                <Border CornerRadius="12" Background="#6E0D08" Margin="0,3,0,-3" Name="ShadowBorder"/>
                                <Border CornerRadius="12" BorderThickness="2.5" BorderBrush="#FFCDD2" Margin="0" Name="ButtonFace">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                            <GradientStop Color="#EA5434" Offset="0"/>
                                            <GradientStop Color="#A71D16" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,0,2"/>
                                </Border>
                            </Grid>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="ButtonFace" Property="Background">
                                        <Setter.Value>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                                <GradientStop Color="#FF6E4A" Offset="0"/>
                                                <GradientStop Color="#BF241C" Offset="1"/>
                                            </LinearGradientBrush>
                                        </Setter.Value>
                                    </Setter>
                                </Trigger>
                                <Trigger Property="IsPressed" Value="True">
                                    <Setter TargetName="ButtonFace" Property="Margin" Value="0,2,0,-2"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
    
            <!-- Cozy Orange Button -->
            <Style x:Key="CozyOrangeButton" TargetType="Button">
                <Setter Property="Foreground" Value="White"/>
                <Setter Property="FontFamily" Value="Comic Sans MS, Segoe UI, sans-serif"/>
                <Setter Property="FontWeight" Value="Bold"/>
                <Setter Property="FontSize" Value="13"/>
                <Setter Property="Height" Value="36"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Grid Name="ButtonGrid">
                                <Border CornerRadius="12" Background="#A1420C" Margin="0,3,0,-3" Name="ShadowBorder"/>
                                <Border CornerRadius="12" BorderThickness="2.5" BorderBrush="#FFE0B2" Margin="0" Name="ButtonFace">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                            <GradientStop Color="#FFA726" Offset="0"/>
                                            <GradientStop Color="#FB8C00" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,0,2"/>
                                </Border>
                            </Grid>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="ButtonFace" Property="Background">
                                        <Setter.Value>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                                <GradientStop Color="#FFB74D" Offset="0"/>
                                                <GradientStop Color="#FB8C00" Offset="1"/>
                                            </LinearGradientBrush>
                                        </Setter.Value>
                                    </Setter>
                                </Trigger>
                                <Trigger Property="IsPressed" Value="True">
                                    <Setter TargetName="ButtonFace" Property="Margin" Value="0,2,0,-2"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
    
            <!-- Cozy Round Green Button -->
            <Style x:Key="CozyRoundButton" TargetType="Button">
                <Setter Property="Width" Value="46"/>
                <Setter Property="Height" Value="46"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Grid Name="ButtonGrid">
                                <Border CornerRadius="23" Background="#3D6B00" Margin="0,3,0,-3" Name="ShadowBorder"/>
                                <Border CornerRadius="23" BorderThickness="2" BorderBrush="#E2FFB3" Margin="0" Name="ButtonFace">
                                    <Border.Background>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                            <GradientStop Color="#8CE400" Offset="0"/>
                                            <GradientStop Color="#539600" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Border.Background>
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,0,2"/>
                                </Border>
                            </Grid>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="ButtonFace" Property="Background">
                                        <Setter.Value>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                                <GradientStop Color="#A2F51C" Offset="0"/>
                                                <GradientStop Color="#60AA00" Offset="1"/>
                                            </LinearGradientBrush>
                                        </Setter.Value>
                                    </Setter>
                                </Trigger>
                                <Trigger Property="IsPressed" Value="True">
                                    <Setter TargetName="ButtonFace" Property="Margin" Value="0,2,0,-2"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
    
            <!-- Cozy TextBox with Inset Tray effect -->
            <Style x:Key="CozyTextBox" TargetType="TextBox">
                <Setter Property="Foreground" Value="{DynamicResource CozyText}"/>
                <Setter Property="Background" Value="#FFF6E5"/>
                <Setter Property="BorderBrush" Value="{DynamicResource CozySecOutline}"/>
                <Setter Property="BorderThickness" Value="3"/>
                <Setter Property="FontSize" Value="13"/>
                <Setter Property="FontFamily" Value="Comic Sans MS, Segoe UI, sans-serif"/>
                <Setter Property="FontWeight" Value="SemiBold"/>
                <Setter Property="Padding" Value="10,6"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="TextBox">
                            <Grid>
                                <!-- Inner bevel shadow -->
                                <Border CornerRadius="12" Background="#FFF6E5" BorderThickness="3.5" BorderBrush="#DDB692">
                                    <Border CornerRadius="8" BorderThickness="1.5" BorderBrush="#AA7043" Padding="5,2">
                                        <ScrollViewer x:Name="PART_ContentHost" VerticalAlignment="Center"/>
                                    </Border>
                                </Border>
                            </Grid>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
    
            <!-- Cozy Slider Styling (Grooved wood track + Strawberry thumb) -->
            <Style x:Key="CozySlider" TargetType="Slider">
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Slider">
                            <Grid Margin="0,5">
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto" MinHeight="{TemplateBinding MinHeight}"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
                                <Border x:Name="TrackBackground" Grid.Row="1" Height="14" CornerRadius="7" Background="{DynamicResource CozySecOutline}" BorderBrush="{DynamicResource CozyInnerBg}" BorderThickness="2.5">
                                    <Canvas Margin="-7,-1">
                                        <Rectangle x:Name="PART_SelectionRange" Fill="#FFF5EE" Height="10" Visibility="Collapsed"/>
                                    </Canvas>
                                </Border>
                                <Track x:Name="PART_Track" Grid.Row="1">
                                    <Track.DecreaseRepeatButton>
                                        <RepeatButton Command="{x:Static Slider.DecreaseLarge}">
                                            <RepeatButton.Template>
                                                <ControlTemplate TargetType="RepeatButton">
                                                    <Border Background="Transparent"/>
                                                </ControlTemplate>
                                            </RepeatButton.Template>
                                        </RepeatButton>
                                    </Track.DecreaseRepeatButton>
                                    <Track.IncreaseRepeatButton>
                                        <RepeatButton Command="{x:Static Slider.IncreaseLarge}">
                                            <RepeatButton.Template>
                                                <ControlTemplate TargetType="RepeatButton">
                                                    <Border Background="Transparent"/>
                                                </ControlTemplate>
                                            </RepeatButton.Template>
                                        </RepeatButton>
                                    </Track.IncreaseRepeatButton>
                                    <Track.Thumb>
                                        <Thumb Width="24" Height="24" Cursor="Hand">
                                            <Thumb.Template>
                                                <ControlTemplate TargetType="Thumb">
                                                    <Grid>
                                                        <Ellipse Fill="{DynamicResource CozyOutline}" Margin="0,2,0,-2"/>
                                                        <Ellipse StrokeThickness="1.5" Stroke="#FFE3E7" Name="ThumbFace">
                                                            <Ellipse.Fill>
                                                                <RadialGradientBrush GradientOrigin="0.3,0.3">
                                                                    <GradientStop Color="#FF7DA1" Offset="0"/>
                                                                    <GradientStop Color="#EA3F6A" Offset="1"/>
                                                                </RadialGradientBrush>
                                                            </Ellipse.Fill>
                                                        </Ellipse>
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
    
            <!-- Cozy CheckBox (Star Checkmark) -->
            <Style x:Key="CozyCheckBox" TargetType="CheckBox">
                <Setter Property="Foreground" Value="{DynamicResource CozyText}"/>
                <Setter Property="FontFamily" Value="Comic Sans MS, Segoe UI, sans-serif"/>
                <Setter Property="FontWeight" Value="Bold"/>
                <Setter Property="FontSize" Value="13"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="CheckBox">
                            <BulletDecorator Background="Transparent" Cursor="Hand">
                                <BulletDecorator.Bullet>
                                    <Grid Width="22" Height="22" Margin="0,0,10,0">
                                        <Border CornerRadius="6" Background="{DynamicResource CozyOutline}" Margin="0,2,0,-2"/>
                                        <Border CornerRadius="6" BorderThickness="2.5" BorderBrush="{DynamicResource CozyOutline}" Background="#FFF5EE" Name="BoxFace">
                                            <TextBlock Name="CheckMark" Text="★" Foreground="#EA3F6A" FontSize="12" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center" Visibility="Collapsed"/>
                                        </Border>
                                    </Grid>
                                </BulletDecorator.Bullet>
                                <ContentPresenter VerticalAlignment="Center" Name="ContentArea"/>
                            </BulletDecorator>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsChecked" Value="True">
                                    <Setter TargetName="CheckMark" Property="Visibility" Value="Visible"/>
                                    <Setter TargetName="BoxFace" Property="Background" Value="#FFE2E7"/>
                                </Trigger>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="BoxFace" Property="BorderBrush" Value="{DynamicResource CozySecOutline}"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
    
            <!-- Cozy Dynamic Side Tab Style with White Translucent Hover Overlay -->
            <Style x:Key="CozyTab" TargetType="Button">
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Grid Name="TabGrid">
                                <Border CornerRadius="0,16,16,0" Background="{DynamicResource CozyOutline}" Margin="0,3,0,-3" Name="ShadowBorder"/>
                                <Border CornerRadius="0,16,16,0" BorderThickness="4" BorderBrush="{DynamicResource CozyOutline}" Background="{DynamicResource CozyOuterBg}" Name="TabFace" Padding="12,0,8,0">
                                    <Grid>
                                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        <!-- Dynamic Translucent Overlay for Universal Hover Glow -->
                                        <Border Name="HoverOverlay" Background="White" Opacity="0" CornerRadius="0,12,12,0"/>
                                    </Grid>
                                </Border>
                            </Grid>
                            <ControlTemplate.Triggers>
                                <Trigger Property="Tag" Value="Active">
                                    <Setter TargetName="TabFace" Property="Background" Value="{DynamicResource CozyInnerBg}"/>
                                    <Setter TargetName="TabFace" Property="BorderThickness" Value="0,4,4,4"/>
                                    <Setter TargetName="TabFace" Property="BorderBrush" Value="{DynamicResource CozySecOutline}"/>
                                    <Setter TargetName="TabGrid" Property="Margin" Value="-8,0,0,0"/>
                                    <Setter Property="Foreground" Value="{DynamicResource CozySecOutline}"/>
                                </Trigger>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="HoverOverlay" Property="Opacity" Value="0.15"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
        </Window.Resources>
    
        <Grid Margin="15">
            <Grid.RowDefinitions>
                <RowDefinition Height="30"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="380"/>
                <ColumnDefinition Width="80"/>
            </Grid.ColumnDefinitions>
    
            <!-- Side Tabs -->
            <StackPanel Grid.Row="1" Grid.Column="1" VerticalAlignment="Top" Margin="-4,20,0,0">
                <Button Name="BtnTabSettings" Width="70" Height="50" Margin="0,0,0,8" Cursor="Hand" Style="{StaticResource CozyTab}">
                    <TextBlock Name="TxtSettingsTab" Text="&#xE713;" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="White" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                </Button>
                <Button Name="BtnTabProfile" Width="70" Height="50" Margin="0,0,0,8" Cursor="Hand" Style="{StaticResource CozyTab}">
                    <TextBlock Name="TxtProfileTab" Text="&#xE77B;" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="White" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                </Button>
                <Button Name="BtnTabMail" Width="70" Height="50" Margin="0,0,0,8" Cursor="Hand" Style="{StaticResource CozyTab}">
                    <TextBlock Name="TxtMailTab" Text="&#xE715;" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="White" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                </Button>
            </StackPanel>
    
            <!-- Main Board Dialogue Container -->
            <Grid Grid.Row="1" Grid.Column="0">
                <!-- 3D Base Drop Shadow Border -->
                <Border CornerRadius="28" Background="{DynamicResource CozyOutline}" Margin="0,4,0,-4" Name="MainBoardShadow">
                    <Border.Effect>
                        <DropShadowEffect Color="#000000" BlurRadius="12" ShadowDepth="4" Opacity="0.3"/>
                    </Border.Effect>
                </Border>
                
                <!-- Main Board Colored Frame -->
                <Border CornerRadius="28" Background="{DynamicResource CozyOuterBg}" BorderThickness="4" BorderBrush="{DynamicResource CozyOutline}" Padding="6" Name="MainBoardOuter">
                    <!-- Inner Board (The beige writing area) -->
                    <Border CornerRadius="20" Background="{DynamicResource CozyInnerBg}" BorderThickness="4" BorderBrush="{DynamicResource CozySecOutline}" Padding="15,20,15,15" Name="MainBoardInner">
                        <Grid>
                            <!-- Grid 1: General Settings Page -->
                            <Grid Name="GridSettings" Visibility="Visible">
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                </Grid.RowDefinitions>
    
                                <TextBlock Grid.Row="0" Text="COZY OPTIONS" FontFamily="Comic Sans MS, Segoe UI, sans-serif" FontSize="18" FontWeight="Bold" Foreground="{DynamicResource CozyText}" Name="TxtHeader" HorizontalAlignment="Center" Margin="0,0,0,15"/>
    
                                <!-- Green Squishy Circular Toggles -->
                                <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,20">
                                    <Button Name="BtnMute" Style="{StaticResource CozyRoundButton}" Margin="0,0,15,0" ToolTip="Mute Audio">
                                        <TextBlock Name="TxtMuteIcon" Text="&#xE767;" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="White" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                                    </Button>
                                    <Button Name="BtnMusic" Style="{StaticResource CozyRoundButton}" Margin="0,0,15,0" ToolTip="Toggle BGM">
                                        <TextBlock Name="TxtMusicIcon" Text="&#xE8D6;" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="White" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                                    </Button>
                                    <Button Name="BtnHelp" Style="{StaticResource CozyRoundButton}" ToolTip="Show Help">
                                        <TextBlock Name="TxtHelpIcon" Text="?" FontFamily="Comic Sans MS" FontSize="20" FontWeight="Bold" Foreground="White" VerticalAlignment="Center" HorizontalAlignment="Center" Margin="0,0,0,2"/>
                                    </Button>
                                </StackPanel>
    
                                <!-- Volume Slider Section -->
                                <StackPanel Grid.Row="2" Margin="10,0,10,15">
                                    <TextBlock Name="TxtVolumeLabel" Text="Master Volume: 60%" FontFamily="Comic Sans MS, Segoe UI, sans-serif" FontSize="13" FontWeight="Bold" Foreground="{DynamicResource CozyText}" Margin="0,0,0,5"/>
                                    <Slider Name="SliderVolume" Minimum="0" Maximum="100" Value="60" Style="{StaticResource CozySlider}" Focusable="False"/>
                                </StackPanel>
    
                                <!-- CheckBox Section -->
                                <StackPanel Grid.Row="3" VerticalAlignment="Center" Margin="10,0,10,5">
                                    <CheckBox Name="ChkSFX" Style="{StaticResource CozyCheckBox}" Content="Enable cute interface sound effects" IsChecked="True" Focusable="False"/>
                                </StackPanel>
                            </Grid>
    
                            <!-- Grid 2: Profile Page -->
                            <Grid Name="GridProfile" Visibility="Collapsed">
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
    
                                <TextBlock Grid.Row="0" Text="ADVENTURER CARD" FontFamily="Comic Sans MS, Segoe UI, sans-serif" FontSize="18" FontWeight="Bold" Foreground="{DynamicResource CozyText}" Name="TxtProfileHeader" HorizontalAlignment="Center" Margin="0,0,0,15"/>
    
                                <!-- Character Name TextBox -->
                                <StackPanel Grid.Row="1" Margin="10,0,10,15">
                                    <TextBlock Name="TxtCharNameLabel" Text="Character Name:" FontFamily="Comic Sans MS, Segoe UI, sans-serif" FontSize="13" FontWeight="Bold" Foreground="{DynamicResource CozyText}" Margin="0,0,0,4"/>
                                    <TextBox Name="TxtCharacterName" Text="Cozy Adventurer" Style="{StaticResource CozyTextBox}" MaxLength="18"/>
                                </StackPanel>
    
                                <!-- Avatar & Welcome Message Row -->
                                <Grid Grid.Row="2" Margin="10,0,10,10">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="Auto"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
    
                                    <!-- Circular Frame for image with EllipseGeometry Clip -->
                                    <Border Grid.Column="0" Width="80" Height="80" CornerRadius="40" BorderThickness="3.5" BorderBrush="{DynamicResource CozySecOutline}" Background="{DynamicResource CozyOutline}" VerticalAlignment="Center">
                                        <Grid Width="72" Height="72" HorizontalAlignment="Center" VerticalAlignment="Center">
                                            <Image Name="ImgAvatar" Source="%avatar_path%" Stretch="UniformToFill" Width="72" Height="72">
                                                <Image.Clip>
                                                    <EllipseGeometry Center="36,36" RadiusX="36" RadiusY="36"/>
                                                </Image.Clip>
                                            </Image>
                                        </Grid>
                                    </Border>
    
                                    <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="15,0,0,0">
                                        <TextBlock Name="TxtGreeting" Text="Welcome, Cozy Adventurer!" FontFamily="Comic Sans MS, Segoe UI, sans-serif" FontSize="13" FontWeight="Bold" Foreground="{DynamicResource CozySecOutline}" TextWrapping="Wrap"/>
                                        <TextBlock Text="Level 99 Cozy Master" FontFamily="Comic Sans MS, Segoe UI, sans-serif" FontSize="11" Foreground="{DynamicResource CozyText}" Opacity="0.75" Margin="0,2,0,0"/>
                                    </StackPanel>
                                </Grid>
    
                                <!-- Cycle Theme Button -->
                                <Button Grid.Row="3" Name="BtnCycleTheme" Style="{StaticResource CozyOrangeButton}" Content="Palette: Warm Honey" Margin="10,0,10,5"/>
                            </Grid>
    
                            <!-- Grid 3: Mail Page -->
                            <Grid Name="GridMail" Visibility="Collapsed">
                                <Grid.RowDefinitions>
                                    <RowDefinition Height="Auto"/>
                                    <RowDefinition Height="*"/>
                                    <RowDefinition Height="Auto"/>
                                </Grid.RowDefinitions>
    
                                <TextBlock Grid.Row="0" Text="GUILD MAILBOX" FontFamily="Comic Sans MS, Segoe UI, sans-serif" FontSize="18" FontWeight="Bold" Foreground="{DynamicResource CozyText}" Name="TxtMailHeader" HorizontalAlignment="Center" Margin="0,0,0,10"/>
    
                                <Grid Grid.Row="1" Margin="5,0,5,10">
                                    <Grid.RowDefinitions>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="Auto"/>
                                        <RowDefinition Height="*"/>
                                    </Grid.RowDefinitions>
    
                                    <Button Grid.Row="0" Name="BtnMail1" Style="{StaticResource CozyBlueButton}" Content="★ System Welcome Reward" Margin="0,0,0,6"/>
                                    <Button Grid.Row="1" Name="BtnMail2" Style="{StaticResource CozyBlueButton}" Content="✉ Daily Quest Resets Today" Margin="0,0,0,6"/>
                                    <Button Grid.Row="2" Name="BtnMail3" Style="{StaticResource CozyBlueButton}" Content="♥ Friend Request Received" Margin="0,0,0,6"/>
    
                                    <!-- Recessed Mail Details Inset -->
                                    <Border Grid.Row="3" CornerRadius="12" Background="#FFF5EE" BorderThickness="3.5" BorderBrush="{DynamicResource CozySecOutline}" Padding="10">
                                        <Border CornerRadius="8" BorderThickness="1.5" BorderBrush="#AA7043" Padding="8">
                                            <TextBlock Name="TxtMailDetail" Text="Select a letter to open it!" FontFamily="Comic Sans MS, Segoe UI, sans-serif" FontSize="11.5" Foreground="{DynamicResource CozyText}" TextWrapping="Wrap" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                                        </Border>
                                    </Border>
                                </Grid>
    
                                <!-- Claim Button -->
                                <Button Grid.Row="2" Name="BtnClaimAll" Style="{StaticResource CozyGreenButton}" Content="Claim All Rewards" Margin="5,0,5,5"/>
                            </Grid>
                        </Grid>
                    </Border>
                </Border>
    
                <!-- Cute Close Button (X) in Top Right Corner -->
                <Button Name="BtnCloseWindow" Width="30" Height="30" VerticalAlignment="Top" HorizontalAlignment="Right" Margin="0,12,12,0" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Grid>
                                <Ellipse Fill="{DynamicResource CozyOutline}" Margin="0,2,0,-2"/>
                                <Ellipse StrokeThickness="1.5" Stroke="#FFEBEE" Name="BtnFace">
                                    <Ellipse.Fill>
                                        <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                            <GradientStop Color="#FF5252" Offset="0"/>
                                            <GradientStop Color="#C62828" Offset="1"/>
                                        </LinearGradientBrush>
                                    </Ellipse.Fill>
                                </Ellipse>
                                <TextBlock Text="✕" Foreground="White" FontSize="13" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,0,0,1"/>
                            </Grid>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="BtnFace" Property="Fill">
                                        <Setter.Value>
                                            <LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
                                                <GradientStop Color="#FF8A80" Offset="0"/>
                                                <GradientStop Color="#D50000" Offset="1"/>
                                            </LinearGradientBrush>
                                        </Setter.Value>
                                    </Setter>
                                </Trigger>
                                <Trigger Property="IsPressed" Value="True">
                                    <Setter TargetName="BtnFace" Property="Margin" Value="0,1.5,0,-1.5"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
            </Grid>
    
            <!-- Top Header Tag (SETTINGS) -->
            <Grid Grid.Row="0" Grid.RowSpan="2" Grid.Column="0" VerticalAlignment="Top" HorizontalAlignment="Center" Height="46" Margin="0,4,0,0">
                <Border CornerRadius="16" Background="{DynamicResource CozyOutline}" Width="180" Height="40" Margin="0,3,0,-3" Name="TitleTagShadow"/>
                <Border CornerRadius="16" Background="{DynamicResource CozyOuterBg}" BorderThickness="4" BorderBrush="{DynamicResource CozyOutline}" Width="180" Height="40" Name="TitleTagOuter" Cursor="SizeAll">
                    <TextBlock Name="TitleTagText" Text="SETTINGS" Foreground="White" FontFamily="Comic Sans MS, Segoe UI, sans-serif" FontSize="15" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center">
                        <TextBlock.Effect>
                            <DropShadowEffect Color="#4D2514" BlurRadius="1" ShadowDepth="2.5" Direction="270"/>
                        </TextBlock.Effect>
                    </TextBlock>
                </Border>
            </Grid>
        </Grid>
    </Window>
)'

; Replace %avatar_path% with absolute avatar file path
xamlString := StrReplace(xamlString, "%avatar_path%", avatarPath)

; Instantiate the XAML Host
host := XAMLHost(xamlString)

; Set up event handlers
host.OnEvent("BtnCloseWindow", "Click", (*) => ExitApp())
host.OnEvent("BtnTabSettings", "Click", (*) => SwitchTab("Settings"))
host.OnEvent("BtnTabProfile", "Click", (*) => SwitchTab("Profile"))
host.OnEvent("BtnTabMail", "Click", (*) => SwitchTab("Mail"))

; Draggability via top title tag
host.OnEvent("TitleTagOuter", "MouseDown", (*) => OnTitleTagMouseDown())

; Settings Page event handlers
host.OnEvent("BtnMute", "Click", (*) => OnMuteClicked())
host.OnEvent("BtnMusic", "Click", (*) => OnMusicClicked())
host.OnEvent("BtnHelp", "Click", (*) => OnHelpClicked())
host.OnEvent("SliderVolume", "ValueChanged", (state, ctrl, event) => OnVolumeChanged(state))
host.Track("SliderVolume")
host.OnEvent("ChkSFX", "Click", (state, ctrl, event) => OnSFXToggled(state))
host.Track("ChkSFX")

; Profile Page event handlers
host.OnEvent("TxtCharacterName", "TextChanged", (state, ctrl, event) => OnNameChanged(state))
host.Track("TxtCharacterName")
host.OnEvent("BtnCycleTheme", "Click", (*) => CycleTheme())

; Mail Page event handlers
host.OnEvent("BtnMail1", "Click", (*) => OnMailClicked(1))
host.OnEvent("BtnMail2", "Click", (*) => OnMailClicked(2))
host.OnEvent("BtnMail3", "Click", (*) => OnMailClicked(3))
host.OnEvent("BtnClaimAll", "Click", (*) => OnClaimAllClicked())

; Global tracking states
global activeTab := savedTab
global currentTheme := savedTheme
global isMuted := savedVolume == 0
global prevVolume := savedVolume == 0 ? 50 : savedVolume
global isMusicOn := savedMusic == "1"
global isSFXOn := savedSFX == "1"

; Cozy Theme Palette Database
global Themes := Map(
    "Warm Honey", {
        OuterBg: "#B85328",
        InnerBg: "#FED39E",
        Outline: "#4D2514",
        SecOutline: "#853E1E",
        Text: "#5C3214",
        TitleText: "SETTINGS",
        AccentColor: "#FF8F00"
    },
    "Matcha Latte", {
        OuterBg: "#5F8544",
        InnerBg: "#E2EFD9",
        Outline: "#2A401A",
        SecOutline: "#44632F",
        Text: "#273B1B",
        TitleText: "MATCHA COZY",
        AccentColor: "#4CAF50"
    },
    "Sweet Berry", {
        OuterBg: "#D35271",
        InnerBg: "#FFDDE2",
        Outline: "#5E1728",
        SecOutline: "#8F2D44",
        Text: "#6B1226",
        TitleText: "BERRY COZY",
        AccentColor: "#E91E63"
    },
    "Starry Night", {
        OuterBg: "#3C4472",
        InnerBg: "#D1D6EB",
        Outline: "#151A36",
        SecOutline: "#262B54",
        Text: "#1D2240",
        TitleText: "STARRY COZY",
        AccentColor: "#3F51B5"
    }
)
global ThemeList := ["Warm Honey", "Matcha Latte", "Sweet Berry", "Starry Night"]

; --- Interactive Functions ---

OnTitleTagMouseDown() {
    try PostMessage(0xA1, 2, 0, , "ahk_id " host.wpfHwnd) ; WM_NCLBUTTONDOWN = 0xA1, HTCAPTION = 2
}

SwitchTab(tabName) {
    global activeTab, host
    activeTab := tabName

    ; Reset tabs
    host.Update("BtnTabSettings", "Tag", "")
    host.Update("BtnTabProfile", "Tag", "")
    host.Update("BtnTabMail", "Tag", "")

    ; Reset visibility
    host.Update("GridSettings", "Visibility", "Collapsed")
    host.Update("GridProfile", "Visibility", "Collapsed")
    host.Update("GridMail", "Visibility", "Collapsed")

    ; Activate selected
    host.Update("BtnTab" tabName, "Tag", "Active")
    host.Update("Grid" tabName, "Visibility", "Visible")

    ; Re-sync theme resource properties
    ApplyTheme(currentTheme)

    PlaySFX()
}

OnVolumeChanged(state) {
    global savedVolume, host, isMuted
    val := Round(Float(state["SliderVolume"]))
    savedVolume := val
    host.Update("TxtVolumeLabel", "Text", "Master Volume: " val "%")

    ; Update speaker icon in Segoe MDL2 Assets
    if (val > 0 && isMuted) {
        isMuted := false
        host.Update("TxtMuteIcon", "Text", Chr(0xE767))
    } else if (val == 0 && !isMuted) {
        isMuted := true
        host.Update("TxtMuteIcon", "Text", Chr(0xE74F))
    }
}

OnSFXToggled(state) {
    global isSFXOn
    isSFXOn := state["ChkSFX"] == "True"
    PlaySFX()
}

SetVolume(val) {
    global savedVolume, host, isMuted
    savedVolume := val
    host.Update("SliderVolume", "Value", String(val))
    host.Update("TxtVolumeLabel", "Text", "Master Volume: " val "%")

    if (val > 0) {
        isMuted := false
        host.Update("TxtMuteIcon", "Text", Chr(0xE767))
    } else {
        isMuted := true
        host.Update("TxtMuteIcon", "Text", Chr(0xE74F))
    }
}

OnMuteClicked() {
    global isMuted, host, savedVolume, prevVolume
    isMuted := !isMuted
    PlaySFX()

    if (isMuted) {
        prevVolume := savedVolume
        SetVolume(0)
        ToolTip("Volume Muted!")
    } else {
        targetVol := prevVolume == 0 ? 50 : prevVolume
        SetVolume(targetVol)
        ToolTip("Volume Unmuted!")
    }
    SetTimer(() => ToolTip(), -1500)
}

OnMusicClicked() {
    global isMusicOn, host
    isMusicOn := !isMusicOn
    PlaySFX()

    if (isMusicOn) {
        host.Update("TxtMusicIcon", "Opacity", "1.0")
        ToolTip("Background Music: ON")
    } else {
        host.Update("TxtMusicIcon", "Opacity", "0.4")
        ToolTip("Background Music: OFF")
    }
    SetTimer(() => ToolTip(), -1500)
}

OnHelpClicked() {
    PlaySFX()
    MsgBox("♥ Cozy Dialogue & Settings Console ♥`n`n• Drag by clicking the brown background or the SETTINGS title tab.`n• Switch between options, character profile, and mailbox using side tabs.`n• Adjust slider and text inputs to customize your game parameters.`n• Click Cycle Theme to repaint the GUI in 4 cute colors!`n`nEnjoy your cozy stay!", "Cozy Help Info", "OK Iconi")
}

OnNameChanged(state) {
    global savedPlayerName, host
    nameVal := state["TxtCharacterName"]
    if (nameVal == "") {
        nameVal := "Cozy Adventurer"
    }
    savedPlayerName := nameVal
    host.Update("TxtGreeting", "Text", "Welcome, " nameVal "!")
}

CycleTheme() {
    global currentTheme, ThemeList, host
    PlaySFX()

    idx := 1
    for i, name in ThemeList {
        if (name == currentTheme) {
            idx := i
            break
        }
    }
    idx := Mod(idx, ThemeList.Length) + 1
    currentTheme := ThemeList[idx]

    ApplyTheme(currentTheme)
}

ApplyTheme(themeName) {
    global Themes, host
    t := Themes[themeName]

    try {
        ; Update core WPF Resource SolidColorBrushes for dynamic styling
        host.Update("Resource", "CozyOuterBg", t.OuterBg)
        host.Update("Resource", "CozyInnerBg", t.InnerBg)
        host.Update("Resource", "CozyOutline", t.Outline)
        host.Update("Resource", "CozySecOutline", t.SecOutline)
        host.Update("Resource", "CozyText", t.Text)

        ; Force-sync active tab foreground icon color in real-time
        if (activeTab == "Settings") {
            host.Update("TxtSettingsTab", "Foreground", t.SecOutline)
            host.Update("TxtProfileTab", "Foreground", "White")
            host.Update("TxtMailTab", "Foreground", "White")
        } else if (activeTab == "Profile") {
            host.Update("TxtSettingsTab", "Foreground", "White")
            host.Update("TxtProfileTab", "Foreground", t.SecOutline)
            host.Update("TxtMailTab", "Foreground", "White")
        } else if (activeTab == "Mail") {
            host.Update("TxtSettingsTab", "Foreground", "White")
            host.Update("TxtProfileTab", "Foreground", "White")
            host.Update("TxtMailTab", "Foreground", t.SecOutline)
        }

        ; Update static label elements (like text shadow, header texts)
        host.Update("TitleTagText", "Text", t.TitleText)
        host.Update("TitleTagText", "Effect.Color", t.Outline)
        host.Update("BtnCycleTheme", "Content", "Palette: " themeName)

    } catch as err {
        ; Ignore errors during early load transitions
    }
}

OnMailClicked(mailNum) {
    global host
    PlaySFX()

    mailText := ""
    if (mailNum == 1) {
        mailText := "From: System Guild`n`nDear Adventurer, welcome to our cozy world! Please accept this starter reward of 500 gold. Enjoy your journey!"
    } else if (mailNum == 2) {
        mailText := "From: Guild Board`n`nDaily quests have been updated. Make sure to complete them to earn sweet rewards before the day ends!"
    } else if (mailNum == 3) {
        mailText := "From: FluffyBunny`n`nHey! I love your character name! Let's team up and explore the green fields together. Send me a request back!"
    }

    host.Update("TxtMailDetail", "Text", mailText)
}

OnClaimAllClicked() {
    global host
    PlaySFX()
    host.Update("TxtMailDetail", "Text", "All rewards claimed! Received 500 Gold and 1 Fluffy Carrot! ♥")
}

PlaySFX() {
    global isSFXOn
    if (isSFXOn) {
        SoundPlay("*64")
    }
}

; --- Main Entry Point ---

; Compile and display the window
host.Show()

; Wait for HWND compilation
while (!host.wpfHwnd) {
    Sleep(10)
}

; Strip maximize box to prevent Windows snap layouts
WinSetStyle("-0x10000", "ahk_id " host.wpfHwnd)

; Enable drag area finder directly inside C# bridge
host.Update("MainBoardOuter", "Name", "DragArea")

; Restore saved state values
SetVolume(savedVolume)
host.Update("TxtCharacterName", "Text", savedPlayerName)
host.Update("TxtGreeting", "Text", "Welcome, " savedPlayerName "!")
host.Update("ChkSFX", "IsChecked", isSFXOn ? "True" : "False")

host.Update("TxtMusicIcon", "Text", Chr(0xEC4F))
if (isMusicOn) {
    host.Update("TxtMusicIcon", "Opacity", "1.0")
} else {
    host.Update("TxtMusicIcon", "Opacity", "0.4")
}

; Apply initial theme resource mapping
ApplyTheme(currentTheme)

; Restore active tab
SwitchTab(activeTab)

; Restore window position
if (savedX != "" && savedY != "") {
    WinMove(Integer(savedX), Integer(savedY), , , "ahk_id " host.wpfHwnd)
}

; Exit routine
OnExit(SaveCozyState)

SaveCozyState(*) {
    global host, layoutIni, currentTheme, activeTab, savedVolume, isSFXOn, isMusicOn, savedPlayerName
    if (host.wpfHwnd && WinExist("ahk_id " host.wpfHwnd)) {
        WinGetPos(&x, &y, , , "ahk_id " host.wpfHwnd)
        if (x != "" && y != "" && x > -10000 && y > -10000) {
            IniWrite(x, layoutIni, "Window", "X")
            IniWrite(y, layoutIni, "Window", "Y")
        }
    }
    IniWrite(activeTab, layoutIni, "Settings", "ActiveTab")
    IniWrite(String(savedVolume), layoutIni, "Settings", "Volume")
    IniWrite(isSFXOn ? "1" : "0", layoutIni, "Settings", "SFX")
    IniWrite(isMusicOn ? "1" : "0", layoutIni, "Settings", "Music")
    IniWrite(savedPlayerName, layoutIni, "Settings", "PlayerName")
    IniWrite(currentTheme, layoutIni, "Settings", "Theme")
}

; Disable Win+Arrow snapping hotkeys for the active cozy window
#HotIf (host.wpfHwnd && WinActive("ahk_id " host.wpfHwnd))
#Left:: return
#Right:: return
#Up:: return
#Down:: return
#HotIf