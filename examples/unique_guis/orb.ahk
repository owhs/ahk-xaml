#Requires AutoHotkey v2.0
#SingleInstance Force

; Include core AHK-XAML libraries
#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Config.ahk"

; Enable dynamic compilation if not already cached
XAMLHost.Prewarm()

; Define a beautiful circular XAML layout using AHK v2 continuation section ( ... )
xamlString := '
(
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Floating Orb"
        Width="350" Height="350"
        AllowsTransparency="True" Background="Transparent" WindowStyle="None"
        WindowStartupLocation="CenterScreen">

    <Grid>
        <!-- Outermost glowing border which serves as the drag region -->
        <Border Name="DragArea" CornerRadius="175" BorderBrush="#FF00D2FF" BorderThickness="2" Margin="15" Cursor="SizeAll">
            <Border.Background>
                <RadialGradientBrush>
                    <GradientStop Color="#FC18181A" Offset="0.0" />
                    <GradientStop Color="#FC0D0D0F" Offset="0.8" />
                    <GradientStop Color="#FC050505" Offset="1.0" />
                </RadialGradientBrush>
            </Border.Background>
            <Border.Effect>
                <DropShadowEffect Color="#FF00D2FF" BlurRadius="18" ShadowDepth="0" Opacity="0.75"/>
            </Border.Effect>
            
            <Grid VerticalAlignment="Center" HorizontalAlignment="Center">
                <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
                    <!-- Pulsing Core Orb -->
                    <Ellipse Name="OrbCore" Width="60" Height="60" Fill="#FF00D2FF" Margin="0,0,0,15">
                        <Ellipse.Effect>
                            <DropShadowEffect Color="#FF00D2FF" BlurRadius="25" ShadowDepth="0" Opacity="0.9"/>
                        </Ellipse.Effect>
                    </Ellipse>
                    
                    <TextBlock Text="ORB CONSOLE" Foreground="#FFFFFF" FontWeight="Bold" FontSize="14" HorizontalAlignment="Center"/>
                    <TextBlock Name="TxtStatus" Text="Pulse Rate: 5.0 Hz" Foreground="#FF00D2FF" FontSize="11" HorizontalAlignment="Center" Margin="0,2,0,15"/>
                    
                    <!-- Interactive Slider to control Pulse Rate -->
                    <TextBlock Text="Pulse Intensity" Foreground="#888888" FontSize="10" HorizontalAlignment="Center" Margin="0,0,0,3"/>
                    <Slider Name="RateSlider" Minimum="1" Maximum="15" Value="5" Width="120" HorizontalAlignment="Center" Margin="0,0,0,15" Focusable="False"/>
                    
                    <Button Name="BtnAction" Content="TRIGGER FLARE" Width="110" Height="28" Foreground="White" BorderThickness="0" Cursor="Hand" Margin="0,0,0,10">
                        <Button.Resources>
                            <Style TargetType="Button">
                                <Setter Property="Background" Value="#FF202022"/>
                                <Setter Property="Template">
                                    <Setter.Value>
                                        <ControlTemplate TargetType="Button">
                                            <Border Background="{TemplateBinding Background}" CornerRadius="14" BorderBrush="#FF00D2FF" BorderThickness="1">
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
                    
                    <Button Name="BtnClose" Content="Shutdown" Width="80" Height="20" Foreground="#FFFF5555" BorderThickness="0" Cursor="Hand">
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
        </Border>
    </Grid>
</Window>
)'

; Instantiate the XAML Host
host := XAMLHost(xamlString)

; Register events
host.OnEvent("Window", "Closed", (*) => ExitApp())
host.OnEvent("BtnAction", "Click", (*) => OnActionClicked())
host.OnEvent("BtnClose", "Click", (*) => ExitApp())
host.OnEvent("RateSlider", "ValueChanged", (state, ctrl, event) => OnRateChanged(state))
host.Track("RateSlider")

; Global animation parameters
global pulseTime := 0.0
global pulseSpeed := 5.0
global flareSize := 60
global isFlaring := false

OnActionClicked() {
    global isFlaring, flareSize
    isFlaring := true
    flareSize := 120
}

OnRateChanged(state) {
    global pulseSpeed, host
    pulseSpeed := Float(state["RateSlider"])
    try host.Update("TxtStatus", "Text", "Pulse Rate: " Format("{:.1f}", pulseSpeed) " Hz")
}

; Core pulsing animation timer
SetTimer(UpdateOrb, 30)

UpdateOrb() {
    global pulseTime, pulseSpeed, isFlaring, flareSize, host
    pulseTime += 0.03 * (pulseSpeed / 5.0)
    
    ; Pulsing opacity and glow
    baseOpacity := 0.5 + 0.4 * Sin(pulseTime * 2 * 3.14159)
    
    ; Handle flare explosion decay
    if (isFlaring) {
        flareSize -= 5
        if (flareSize <= 60) {
            flareSize := 60
            isFlaring := false
        }
    }
    
    try {
        host.Update("OrbCore", "Opacity", String(baseOpacity))
        host.Update("OrbCore", "Width", String(flareSize))
        host.Update("OrbCore", "Height", String(flareSize))
    }
}

; Start the application
host.Show()
while (!host.wpfHwnd) {
    Sleep(10)
}
WinSetStyle("-0x10000", "ahk_id " host.wpfHwnd)

; Disable Win+Arrow snapping hotkeys for the active orb window
#HotIf (host.wpfHwnd && WinActive("ahk_id " host.wpfHwnd))
#Left:: return
#Right:: return
#Up:: return
#Down:: return
+#Left:: return
+#Right:: return
+#Up:: return
+#Down:: return
#HotIf
