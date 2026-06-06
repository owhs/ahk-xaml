#Requires AutoHotkey v2.0
#Include "../../lib/XAML_Host.ahk"
#Include "../../lib/XAML_Generator.ahk"
#Include "../../lib/XAML_Dialog.ahk"
#Include "../../lib/XAML_GUI.ahk"
#Include "../../lib/XAML_Components.ahk"
#Include "../../lib/XAML_Adv_Components.ahk"

try {
    ; 1. Initialize App with default theme options
    app := XAML_GUI("DirectX 9 Shader Showcase", Map("BurgerMenu", true, "Sidebar", true))

    ; Setup globals for active values controlled by color pickers
    global currentGlowColor := "#FF00F2FE"
    global currentGradColor1 := "#FF00F2FE"
    global currentGradColor2 := "#FFFD008C"
    global currentGradColor3 := "#FF8D00FF"
    global currentAcrylicTintBase := "000000"
    global currentAcrylicOpacity := 30
    global xamlAssembly := SubStr(XAMLHost.GetEngineDllName(), 1, -4)

    ; Timer state for glow pulse animation
    global glowTime := 0.0
    global glowBaseSize := 30.0
    global glowPulseSpeed := 2.0

    ; Timer state for gradient animation
    global gradTime := 0.0

    ; Create the showcase pages using WPF TabControl
    app.AddTab("Acrylic Glass", BuildAcrylicTab)
    app.AddTab("Neon Glow", BuildGlowTab)
    app.AddTab("Water Ripple", BuildRippleTab)
    app.AddTab("Cyberpunk Gradient", BuildGradientTab)

    ; Compile the UI
    ui := app.Compile()

    ; Start timers for continuous animations (driven from AHK side)
    SetTimer(UpdateGlowPulse, 33)    ; ~30fps for glow pulse
    SetTimer(UpdateGradTime, 33)     ; ~30fps for gradient

    ; Show the UI window
    app.Show()
} catch Any as err {
    try FileAppend("Error: " err.Message "`nFile: " err.File "`nLine: " err.Line "`nStack: " err.Stack "`n", A_ScriptDir "\error.log", "UTF-8")
    ExitApp()
}


; ==============================================================================
; TIMER CALLBACKS
; ==============================================================================

UpdateGlowPulse() {
    global glowTime, glowBaseSize, glowPulseSpeed, ui
    glowTime += 0.033
    ; Pulse the DropShadowEffect's BlurRadius for a breathing glow effect
    blurVal := glowBaseSize + (glowBaseSize * 0.5) * Sin(glowTime * glowPulseSpeed)
    try ui.Update("GlowBorder", "Effect.BlurRadius", String(blurVal))
}

UpdateGradTime() {
    global gradTime, ui
    gradTime += 0.033
    try ui.Update("GradBorder", "Effect.Time", String(gradTime))
}

GetAcrylicTintColor() {
    global currentAcrylicTintBase, currentAcrylicOpacity
    alphaVal := Round(currentAcrylicOpacity * 2.55)
    alphaHex := Format("{:02X}", alphaVal)
    return "#" . alphaHex . currentAcrylicTintBase
}


; ==============================================================================
; TAB 1: ACRYLIC GLASS
; ==============================================================================
; Two-layer approach for proper backdrop-blur:
;   Layer 1: Copy of backdrop image + WPF BlurEffect (strong Gaussian blur)
;   Layer 2: Semi-transparent tint overlay
;   Layer 3: Text content (no effect, crisp and sharp)

BuildAcrylicTab(tabItem) {
    grid := tabItem.Add("Grid").Name("AcrylicTabGrid")
    grid.Cols("*", "300")
    WallpaperPath := RegRead("HKEY_CURRENT_USER\Control Panel\Desktop", "Wallpaper")

    ; Left Showcase Area — full-bleed backdrop image (named so VisualBrush can reference it)
    sandbox := grid.Add("Grid").Grid_Column(0).Margin("20").ClipToBounds("True")
    backdropBdr := sandbox.Add("Border").Name("BackdropBorder").CornerRadius("10").ClipToBounds("True")
    backdropBdr.Add("Image").Source(WallpaperPath).Stretch("UniformToFill")

    ; Acrylic card — layered Grid centered over the backdrop
    acrylicCardHost := sandbox.Add("Grid").Width("420").Height("260").HorizontalAlignment("Center").VerticalAlignment("Center")

    ; Layer 1: VisualBrush references the actual backdrop element.
    ; With Stretch=None and center alignment, the brush shows the EXACT region behind the card.
    ; BlurEffect then blurs that matching region — true backdrop-blur.
    blurLayer := acrylicCardHost.Add("Border").Name("AcrylicBlurLayer").CornerRadius("12").ClipToBounds("True")
    bgProp := blurLayer.Add("Border.Background")
    bgProp.Add("VisualBrush").SetProp("Visual", "{Binding ElementName=BackdropBorder}").Stretch("None").AlignmentX("Center").AlignmentY("Center")
    blurEffectProp := blurLayer.Add("Border.Effect")
    blurEffectProp.Add("BlurEffect").SetProp("Radius", "25").SetProp("KernelType", "Gaussian")

    ; Layer 2: Tint overlay
    tintLayer := acrylicCardHost.Add("Border").Name("AcrylicTintLayer").CornerRadius("12").Background(GetAcrylicTintColor()).BorderThickness("1").BorderBrush("#40FFFFFF")

    ; Layer 3: Text content (NOT blurred — crisp and sharp)
    content := acrylicCardHost.Add("Grid").Margin("25")
    content.Rows("Auto", "*", "Auto")
    content.Add("TextBlock").Text("Acrylic Glass Effect").FontSize("22").FontWeight("SemiBold").Foreground("#FFFFFF").Grid_Row(0)

    bodyText := content.Add("TextBlock").Grid_Row(1).Margin("0,15,0,0").TextWrapping("Wrap").FontSize("13").Foreground("#E0E0E0")
    bodyText.Text("WPF pixel shaders are executed entirely on the GPU, allowing complex blur algorithms like frosted glass without impacting CPU performance. Adjust the sliders on the right to witness instant, real-time feedback.")

    footer := content.Add("StackPanel").Grid_Row(2).Orientation("Horizontal").HorizontalAlignment("Right")
    footer.Add("TextBlock").Text(Chr(0xE7E7)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize("16").Foreground("#A0A0A0").Margin("0,0,10,0").VerticalAlignment("Center")
    footer.Add("TextBlock").Text("GPU Accelerated").FontSize("12").Foreground("#A0A0A0").VerticalAlignment("Center")

    ; Right Configuration Sidebar
    controls := grid.Add("StackPanel").Grid_Column(1).Margin("20,10,20,10")
    controls.Add("TextBlock").Text("ACRYLIC OPTIONS").FontSize("12").FontWeight("Bold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,15")

    controls.Add("TextBlock").Text("Blur Radius").FontSize("11").Foreground("{DynamicResource TextSub}").Margin("0,10,0,5")
    controls.Add("Slider").Name("AcrylicBlurSlider").Minimum("0.0").Maximum("40.0").Value("25.0").TickFrequency("1.0").IsSnapToTickEnabled("True").Track()
        .On("ValueChanged", OnAcrylicBlurChange).Limit(60)

    controls.Add("TextBlock").Text("Tint Opacity (%)").FontSize("11").Foreground("{DynamicResource TextSub}").Margin("0,15,0,5")
    controls.Add("Slider").Name("AcrylicOpacitySlider").Minimum("0.0").Maximum("100.0").Value("30.0").TickFrequency("5.0").IsSnapToTickEnabled("True").Track()
        .On("ValueChanged", OnAcrylicOpacityChange).Limit(60)

    controls.Add("TextBlock").Text("Tint Color Preset").FontSize("11").Foreground("{DynamicResource TextSub}").Margin("0,15,0,5")
    tintCombo := controls.Add("ComboBox").Name("AcrylicTintCombo").Height("32").Track()
        .On("SelectionChanged", OnAcrylicTintChange)
    tintCombo.Add("ComboBoxItem").Content("Dark Tint (Black)").Tag("000000")
    tintCombo.Add("ComboBoxItem").Content("Light Tint (White)").Tag("FFFFFF")
    tintCombo.Add("ComboBoxItem").Content("Neon Blue").Tag("00C2FF")
    tintCombo.Add("ComboBoxItem").Content("Neon Magenta").Tag("FF00AA")
    tintCombo.SelectedIndex(0)
}

OnAcrylicBlurChange(state, ctrl, event) {
    if state.Has("AcrylicBlurSlider")
        ui.Update("AcrylicBlurLayer", "Effect.Radius", state["AcrylicBlurSlider"])
}

OnAcrylicTintChange(state, ctrl, event) {
    global currentAcrylicTintBase, ui
    if state.Has("AcrylicTintCombo") {
        currentAcrylicTintBase := state["AcrylicTintCombo"]
        ui.Update("AcrylicTintLayer", "Background", GetAcrylicTintColor())
    }
}

OnAcrylicOpacityChange(state, ctrl, event) {
    global currentAcrylicOpacity, ui
    if state.Has("AcrylicOpacitySlider") {
        currentAcrylicOpacity := Integer(state["AcrylicOpacitySlider"])
        ui.Update("AcrylicTintLayer", "Background", GetAcrylicTintColor())
    }
}


; ==============================================================================
; TAB 2: NEON GLOW
; ==============================================================================
; Uses WPF's built-in DropShadowEffect with ShadowDepth=0 for reliable neon glow.
; DropShadowEffect IS a GPU pixel shader — it just works more reliably than
; the custom 8-neighbor glow shader which has single-pass sampling limitations.
; Pulsing animation driven by varying BlurRadius via AHK timer.

BuildGlowTab(tabItem) {
    grid := tabItem.Add("Grid").Name("GlowTabGrid")
    grid.Cols("*", "300")

    ; Left Showcase Area
    sandbox := grid.Add("Grid").Grid_Column(0).Margin("20")

    ; Circular element with DropShadowEffect neon glow
    ; ShadowDepth=0 centers the shadow behind the element.
    ; BlurRadius controls how far the glow extends.
    ; The glow naturally follows the circular shape via the rendered bitmap.
    glowBorder := sandbox.Add("Border").Name("GlowBorder").Width("200").Height("200").CornerRadius("100").Background("#151515").HorizontalAlignment("Center").VerticalAlignment("Center")
    effectProp := glowBorder.Add("Border.Effect")
    effectProp.Add("DropShadowEffect").SetProp("ShadowDepth", "0").SetProp("BlurRadius", "30").SetProp("Color", "#00F2FE").SetProp("Opacity", "0.9")

    ; Content inside the circle
    glowContent := glowBorder.Add("StackPanel").VerticalAlignment("Center").HorizontalAlignment("Center")
    glowContent.Add("TextBlock").Text(Chr(0xE945)).FontFamily("Segoe Fluent Icons, Segoe MDL2 Assets").FontSize("48").Foreground("#FF00F2FE").HorizontalAlignment("Center").Margin("0,0,0,15")
    glowContent.Add("TextBlock").Text("NEON GLOW").FontSize("16").FontWeight("Bold").Foreground("#FFFFFF").HorizontalAlignment("Center")

    ; Right Configuration Sidebar
    controls := grid.Add("StackPanel").Grid_Column(1).Margin("20,10,20,10")
    controls.Add("TextBlock").Text("GLOW OPTIONS").FontSize("12").FontWeight("Bold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,15")

    controls.Add("TextBlock").Text("Glow Size").FontSize("11").Foreground("{DynamicResource TextSub}").Margin("0,10,0,5")
    controls.Add("Slider").Name("GlowSizeSlider").Minimum("5.0").Maximum("60.0").Value("30.0").TickFrequency("1.0").IsSnapToTickEnabled("True").Track()
        .On("ValueChanged", OnGlowSizeChange).Limit(60)

    controls.Add("TextBlock").Text("Pulse Speed").FontSize("11").Foreground("{DynamicResource TextSub}").Margin("0,15,0,5")
    controls.Add("Slider").Name("GlowPulseSpeedSlider").Minimum("0.0").Maximum("6.0").Value("2.0").TickFrequency("0.1").IsSnapToTickEnabled("True").Track()
        .On("ValueChanged", OnGlowPulseSpeedChange).Limit(60)

    controls.Add("TextBlock").Text("Glow Color").FontSize("11").Foreground("{DynamicResource TextSub}").Margin("0,15,0,5")
    glowSp := controls.Add("StackPanel").Orientation("Horizontal")
    glowSp.Add("Border").Name("GlowColorPreview").Width("28").Height("28").CornerRadius("14").Background(currentGlowColor).BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1.5").Margin("0,0,10,0")
    glowSp.Add("Button").Name("BtnPickGlowColor").Content("Pick Color...").Width("120").Height("30").Use("PrimaryBtn").Cursor("Hand")
        .On("Click", OnPickGlowColor)
}

OnGlowSizeChange(state, ctrl, event) {
    global glowBaseSize
    if state.Has("GlowSizeSlider")
        glowBaseSize := Float(state["GlowSizeSlider"])
}

OnGlowPulseSpeedChange(state, ctrl, event) {
    global glowPulseSpeed
    if state.Has("GlowPulseSpeedSlider")
        glowPulseSpeed := Float(state["GlowPulseSpeedSlider"])
}

OnPickGlowColor(state, ctrl, event) {
    global currentGlowColor, ui
    res := XColorPicker.Show({
        Title: "Choose Glow Color",
        DefaultColor: currentGlowColor,
        Owner: ui.wpfHwnd,
        Modal: true,
        Theme: app.currentThemeName
    })
    if (res.Status == "OK") {
        currentGlowColor := res.Color
        ui.Update("GlowColorPreview", "Background", res.Color)
        ui.Update("GlowBorder", "Effect.Color", res.Color)
    }
}


; ==============================================================================
; TAB 3: WATER RIPPLE
; ==============================================================================

BuildRippleTab(tabItem) {
    grid := tabItem.Add("Grid").Name("RippleTabGrid")
    grid.Cols("*", "300")
    WallpaperPath := RegRead("HKEY_CURRENT_USER\Control Panel\Desktop", "Wallpaper")

    ; Left Showcase Area
    sandbox := grid.Add("Grid").Grid_Column(0).Margin("20")

    rippleCard := sandbox.Add("Border").Name("RippleCard").Width("500").Height("350").CornerRadius("10").ClipToBounds("True").HorizontalAlignment("Center").VerticalAlignment("Center").Cursor("Hand")
        .On("MouseLeftButtonDown", OnRippleClick)
    effectProp := rippleCard.Add("Border.Effect")
    rippleEffect := effectProp.Add("eff:RippleEffect").SetProp("xmlns:eff", "clr-namespace:AhkEffects;assembly=" xamlAssembly)
    rippleEffect.Center("0.5,0.5").Amplitude("0.03").Frequency("30.0").Speed("1.2").Time("2.0")

    cardGrid := rippleCard.Add("Grid")
    cardGrid.Add("Image").Source(WallpaperPath).Stretch("UniformToFill")

    instruction := cardGrid.Add("TextBlock").Text("CLICK ANYWHERE ON IMAGE TO RIPPLE").FontSize("12").FontWeight("Bold").Foreground("#A0FFFFFF").HorizontalAlignment("Center").VerticalAlignment("Bottom").Margin("0,0,0,20")
    instruction.Add("TextBlock.Effect").Add("DropShadowEffect").SetProp("BlurRadius", "6").SetProp("ShadowDepth", "0").SetProp("Color", "Black").SetProp("Opacity", "0.8")

    ; Right Configuration Sidebar
    controls := grid.Add("StackPanel").Grid_Column(1).Margin("20,10,20,10")
    controls.Add("TextBlock").Text("RIPPLE OPTIONS").FontSize("12").FontWeight("Bold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,15")

    controls.Add("TextBlock").Text("Amplitude").FontSize("11").Foreground("{DynamicResource TextSub}").Margin("0,10,0,5")
    controls.Add("Slider").Name("RippleAmpSlider").Minimum("0.0").Maximum("0.08").Value("0.03").TickFrequency("0.002").IsSnapToTickEnabled("True").Track()
        .On("ValueChanged", OnRippleAmpChange).Limit(60)

    controls.Add("TextBlock").Text("Frequency").FontSize("11").Foreground("{DynamicResource TextSub}").Margin("0,15,0,5")
    controls.Add("Slider").Name("RippleFreqSlider").Minimum("10.0").Maximum("80.0").Value("30.0").TickFrequency("1.0").IsSnapToTickEnabled("True").Track()
        .On("ValueChanged", OnRippleFreqChange).Limit(60)

    controls.Add("TextBlock").Text("Wave Speed").FontSize("11").Foreground("{DynamicResource TextSub}").Margin("0,15,0,5")
    controls.Add("Slider").Name("RippleSpeedSlider").Minimum("0.2").Maximum("3.0").Value("1.2").TickFrequency("0.1").IsSnapToTickEnabled("True").Track()
        .On("ValueChanged", OnRippleSpeedChange).Limit(60)

    controls.Add("Button").Name("BtnTriggerRipple").Content("Manual Trigger").Use("PrimaryBtn").Height("35").Margin("0,25,0,0").Cursor("Hand")
        .On("Click", (*) => TriggerRippleManual())
}

OnRippleClick(state, ctrl, event) {
    if state.Has("RippleCard") {
        coords := state["RippleCard"]
        parts := StrSplit(coords, ",")
        if (parts.Length == 2) {
            x := Float(parts[1])
            y := Float(parts[2])
            u := x / 500.0
            v := y / 350.0
            ui.Update("RippleCard", "Effect.Center", u "," v)
            StartRippleAnimation()
        }
    }
}

TriggerRippleManual() {
    ui.Update("RippleCard", "Effect.Center", "0.5,0.5")
    StartRippleAnimation()
}

StartRippleAnimation() {
    global rippleTime := 0.0
    SetTimer(UpdateRippleTime, 33)
}

UpdateRippleTime() {
    global rippleTime, ui
    rippleTime += 0.033
    if (rippleTime >= 2.0) {
        SetTimer(UpdateRippleTime, 0)
        return
    }
    try ui.Update("RippleCard", "Effect.Time", String(rippleTime))
}

OnRippleAmpChange(state, ctrl, event) {
    if state.Has("RippleAmpSlider")
        ui.Update("RippleCard", "Effect.Amplitude", state["RippleAmpSlider"])
}

OnRippleFreqChange(state, ctrl, event) {
    if state.Has("RippleFreqSlider")
        ui.Update("RippleCard", "Effect.Frequency", state["RippleFreqSlider"])
}

OnRippleSpeedChange(state, ctrl, event) {
    if state.Has("RippleSpeedSlider")
        ui.Update("RippleCard", "Effect.Speed", state["RippleSpeedSlider"])
}


; ==============================================================================
; TAB 4: CYBERPUNK GRADIENT
; ==============================================================================

BuildGradientTab(tabItem) {
    grid := tabItem.Add("Grid").Name("GradientTabGrid")
    grid.Cols("*", "300")

    ; Left Showcase Area
    sandbox := grid.Add("Grid").Grid_Column(0).Margin("20")

    gradCard := sandbox.Add("Border").Name("GradBorder").Width("420").Height("260").CornerRadius("12").BorderThickness("1").BorderBrush("#40FFFFFF").HorizontalAlignment("Center").VerticalAlignment("Center")
    effectProp := gradCard.Add("Border.Effect")
    gradEffect := effectProp.Add("eff:CyberpunkGradientEffect").SetProp("xmlns:eff", "clr-namespace:AhkEffects;assembly=" xamlAssembly)
    gradEffect.Color1(currentGradColor1).Color2(currentGradColor2).Color3(currentGradColor3).Angle("45.0").Speed("0.5").Brightness("1.0").Time("0")

    gradContent := gradCard.Add("Grid")
    gradContent.Rows("Auto", "*")
    gradContent.Add("TextBlock").Text("Cyberpunk Gradient").FontSize("22").FontWeight("Bold").Foreground("White").HorizontalAlignment("Center").Grid_Row(0).Margin("0,25,0,0")

    logoText := gradContent.Add("TextBlock").Grid_Row(1).Text("AHK-XAML").FontSize("48").FontWeight("Black").Foreground("White").HorizontalAlignment("Center").VerticalAlignment("Center")
    logoText.Add("TextBlock.Effect").Add("DropShadowEffect").SetProp("BlurRadius", "15").SetProp("ShadowDepth", "0").SetProp("Color", "Black").SetProp("Opacity", "0.6")

    ; Right Configuration Sidebar
    controls := grid.Add("StackPanel").Grid_Column(1).Margin("20,10,20,10")
    controls.Add("TextBlock").Text("GRADIENT OPTIONS").FontSize("12").FontWeight("Bold").Foreground("{DynamicResource TextSub}").Margin("0,0,0,15")

    controls.Add("TextBlock").Text("Animation Speed").FontSize("11").Foreground("{DynamicResource TextSub}").Margin("0,10,0,5")
    controls.Add("Slider").Name("GradSpeedSlider").Minimum("0.0").Maximum("2.5").Value("0.5").TickFrequency("0.05").IsSnapToTickEnabled("True").Track()
        .On("ValueChanged", OnGradSpeedChange).Limit(60)

    controls.Add("TextBlock").Text("Gradient Angle").FontSize("11").Foreground("{DynamicResource TextSub}").Margin("0,15,0,5")
    controls.Add("Slider").Name("GradAngleSlider").Minimum("0.0").Maximum("360.0").Value("45.0").TickFrequency("5.0").IsSnapToTickEnabled("True").Track()
        .On("ValueChanged", OnGradAngleChange).Limit(60)

    controls.Add("TextBlock").Text("Brightness Boost").FontSize("11").Foreground("{DynamicResource TextSub}").Margin("0,15,0,5")
    controls.Add("Slider").Name("GradBrightnessSlider").Minimum("0.0").Maximum("2.0").Value("1.0").TickFrequency("0.05").IsSnapToTickEnabled("True").Track()
        .On("ValueChanged", OnGradBrightnessChange).Limit(60)

    controls.Add("TextBlock").Text("Gradient Palette").FontSize("11").Foreground("{DynamicResource TextSub}").Margin("0,15,0,5")
    palSp := controls.Add("StackPanel").Orientation("Horizontal").HorizontalAlignment("Left")

    palSp.Add("Border").Name("Grad1Preview").Width("28").Height("28").CornerRadius("14").Background(currentGradColor1).BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1.5").Margin("0,0,10,0")
    palSp.Add("Button").Name("BtnPickGrad1").Content("Color 1").Width("60").Height("28").Use("PrimaryBtn").Cursor("Hand").Margin("0,0,10,0")
        .On("Click", (*) => PickGradColor(1))

    palSp.Add("Border").Name("Grad2Preview").Width("28").Height("28").CornerRadius("14").Background(currentGradColor2).BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1.5").Margin("0,0,10,0")
    palSp.Add("Button").Name("BtnPickGrad2").Content("Color 2").Width("60").Height("28").Use("PrimaryBtn").Cursor("Hand").Margin("0,0,10,0")
        .On("Click", (*) => PickGradColor(2))

    palSp.Add("Border").Name("Grad3Preview").Width("28").Height("28").CornerRadius("14").Background(currentGradColor3).BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1.5").Margin("0,0,10,0")
    palSp.Add("Button").Name("BtnPickGrad3").Content("Color 3").Width("60").Height("28").Use("PrimaryBtn").Cursor("Hand")
        .On("Click", (*) => PickGradColor(3))
}

OnGradSpeedChange(state, ctrl, event) {
    if state.Has("GradSpeedSlider")
        ui.Update("GradBorder", "Effect.Speed", state["GradSpeedSlider"])
}

OnGradAngleChange(state, ctrl, event) {
    if state.Has("GradAngleSlider")
        ui.Update("GradBorder", "Effect.Angle", state["GradAngleSlider"])
}

OnGradBrightnessChange(state, ctrl, event) {
    if state.Has("GradBrightnessSlider")
        ui.Update("GradBorder", "Effect.Brightness", state["GradBrightnessSlider"])
}

PickGradColor(index) {
    global currentGradColor1, currentGradColor2, currentGradColor3, ui
    currColor := index == 1 ? currentGradColor1 : (index == 2 ? currentGradColor2 : currentGradColor3)
    res := XColorPicker.Show({
        Title: "Choose Gradient Color " index,
        DefaultColor: currColor,
        Owner: ui.wpfHwnd,
        Modal: true,
        Theme: app.currentThemeName
    })
    if (res.Status == "OK") {
        if (index == 1) {
            currentGradColor1 := res.Color
            ui.Update("Grad1Preview", "Background", res.Color)
            ui.Update("GradBorder", "Effect.Color1", res.Color)
        } else if (index == 2) {
            currentGradColor2 := res.Color
            ui.Update("Grad2Preview", "Background", res.Color)
            ui.Update("GradBorder", "Effect.Color2", res.Color)
        } else {
            currentGradColor3 := res.Color
            ui.Update("Grad3Preview", "Background", res.Color)
            ui.Update("GradBorder", "Effect.Color3", res.Color)
        }
    }
}


Persistent()