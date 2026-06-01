#Requires AutoHotkey v2.0
#Include "XAML_GUI.ahk"
#Include "XAML_Config.ahk"

global XAML_DevTools_Instance := ""

class XAML_DevTools {
    static ShowFor(targetHost) {
        global XAML_DevTools_Instance
        if (IsSet(XAML_DevTools_Instance) && XAML_DevTools_Instance != "") {
            try {
                WinActivate("ahk_id " XAML_DevTools_Instance.app.host.wpfHwnd)
                return
            }
        }
        XAML_DevTools_Instance := XAML_DevTools(targetHost)
    }

    __New(targetGui) {
        this.targetGui := targetGui
        this.target := targetGui.host
        global XAML_DevTools_Instance := this

        this.hashToName := Map()
        this.pipelineLogs := []

        ; Register event callbacks on target host's background engine
        this.target.OnEvent("Engine", "DevToolsTree", ObjBindMethod(this, "OnTreeReceived"))
        this.target.OnEvent("Engine", "DevToolsProps", ObjBindMethod(this, "OnPropsReceived"))

        this.app := XAML_GUI("Developer Tools - " this.target.id, Map("Sidebar", true, "TitleBarHeight", 45))

        ; Setup theme and list defaults
        this.app.X.InjectResources('
        (
            <Style TargetType="TextBlock">
                <Setter Property="Foreground" Value="{DynamicResource TextMain}" />
                <Setter Property="Padding" Value="2" />
            </Style>
            <Style TargetType="ToggleButton">
                <Setter Property="Background" Value="{DynamicResource ControlBg}" />
                <Setter Property="Foreground" Value="{DynamicResource TextMain}" />
                <Setter Property="BorderBrush" Value="{DynamicResource ControlBorder}" />
                <Setter Property="BorderThickness" Value="1" />
                <Setter Property="Padding" Value="10,2" />
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="ToggleButton">
                            <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsChecked" Value="True">
                                    <Setter TargetName="border" Property="Background" Value="{DynamicResource Accent}" />
                                    <Setter Property="Foreground" Value="White" />
                                    <Setter TargetName="border" Property="BorderBrush" Value="{DynamicResource Accent}" />
                                </Trigger>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="border" Property="Opacity" Value="0.8" />
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
            <Style TargetType="TabControl">
                <Setter Property="BorderThickness" Value="0,1,0,0" />
                <Setter Property="BorderBrush" Value="{DynamicResource ControlBorder}" />
                <Setter Property="Background" Value="Transparent" />
                <Setter Property="Padding" Value="0" />
            </Style>
            <Style TargetType="TabItem">
                <Setter Property="HeaderTemplate">
                    <Setter.Value>
                        <DataTemplate>
                            <ContentPresenter Content="{TemplateBinding Content}" Margin="10,5,10,5"/>
                        </DataTemplate>
                    </Setter.Value>
                </Setter>
                <Setter Property="Background" Value="Transparent" />
                <Setter Property="Foreground" Value="{DynamicResource TextSub}" />
                <Setter Property="BorderThickness" Value="0" />
                <Setter Property="Cursor" Value="Hand" />
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="TabItem">
                            <Border x:Name="Border" Background="{TemplateBinding Background}" BorderThickness="0,0,0,2" BorderBrush="Transparent" SnapsToDevicePixels="true">
                                <ContentPresenter x:Name="ContentSite" ContentSource="Header" RecognizesAccessKey="True" HorizontalAlignment="Center" VerticalAlignment="Center" SnapsToDevicePixels="true"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsSelected" Value="true">
                                    <Setter TargetName="Border" Property="BorderBrush" Value="{DynamicResource Accent}" />
                                    <Setter Property="Foreground" Value="{DynamicResource TextMain}" />
                                    <Setter Property="FontWeight" Value="SemiBold" />
                                </Trigger>
                                <Trigger Property="IsMouseOver" Value="true">
                                    <Setter Property="Foreground" Value="{DynamicResource TextMain}" />
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
        )')

        this.app.AddTab("Elements", ObjBindMethod(this, "BuildElementsTab"))
        this.app.AddTab("Pipeline", ObjBindMethod(this, "BuildPipelineTab"))
        this.app.AddTab("Console", ObjBindMethod(this, "BuildConsoleTab"))

        this.app.Compile()

        ; Replicate parent window theme
        if (targetGui.HasProp("currentThemeName") && targetGui.currentThemeName != "") {
            try this.app.ThemeChanged(Map("ComboTheme", targetGui.currentThemeName), "ComboTheme", "")
        }

        ; Wire events on DevTools own compiled window
        this.app.host.OnEvent("BtnRefreshTree", "Click", ObjBindMethod(this, "RequestTree"))
        this.app.host.OnEvent("BtnInspect", "Click", ObjBindMethod(this, "OnInspectToggle"))

        ; Listen for global events from the target application (sent from background engine)
        this.targetGui.host.OnEvent("AppWindow", "InspectPicked", ObjBindMethod(this, "OnInspectPicked"))

        this.app.host.OnEvent("TreeElements", "SelectedItemChanged", ObjBindMethod(this, "OnElementSelected"))
        this.app.host.OnEvent("BtnConsoleRun", "Click", ObjBindMethod(this, "OnConsoleRun"))
        this.app.host.OnEvent("BtnClearPipeline", "Click", ObjBindMethod(this, "OnClearPipeline"))
        this.app.host.OnEvent("LogPipeline", "SelectionChanged", ObjBindMethod(this, "OnPipelineSelected"))
        this.app.host.OnEvent("BtnTogglePipelineDetails", "Click", ObjBindMethod(this, "OnTogglePipelineDetails"))
        this.app.host.OnEvent("BtnClearConsole", "Click", (*) => this.app.host.Update("LogConsole", "Text", ""))

        this.app.host.OnEvent("BtnFilterAlpha", "Click", ObjBindMethod(this, "OnPropFilterChanged"))
        this.app.host.OnEvent("BtnFilterGroup", "Click", ObjBindMethod(this, "OnPropFilterChanged"))
        this.app.host.OnEvent("BtnFilterLocal", "Click", ObjBindMethod(this, "OnPropFilterChanged"))
        this.app.host.OnEvent("BtnFilterValid", "Click", ObjBindMethod(this, "OnPropFilterChanged"))
        this.app.host.OnEvent("BtnFilterEdit", "Click", ObjBindMethod(this, "OnPropFilterChanged"))
        this.app.host.OnEvent("TxtPropSearch", "TextChanged", ObjBindMethod(this, "OnPropFilterChanged"))
        this.app.host.OnEvent("TxtEventSearch", "TextChanged", ObjBindMethod(this, "OnPropFilterChanged"))
        this.app.host.OnEvent("ComboPresets", "SelectionChanged", ObjBindMethod(this, "OnPropFilterChanged"))

        this.app.host.OnEvent("Window", "Closed", ObjBindMethod(this, "OnClosed"))

        this.app.Show()

        ; Initial request
        this.RequestTree()

        ; Initial request
        this.RequestTree()
    }

    BuildElementsTab(tab) {
        grid := tab.Add("Grid")
        grid.Cols("2*", "5", "1*")

        leftPanel := grid.Add("Grid").Grid_Column(0)
        leftPanel.Rows("Auto", "*")

        toolbar := leftPanel.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,5")
        toolbar.Add("Button").Name("BtnRefreshTree").Content("Refresh Tree").Use("PrimaryBtn").Width(100).Height(25)
        toolbar.Add("ToggleButton").Name("BtnInspect").Content("Inspect").Use("PrimaryBtn").Width(80).Height(25).Margin("5,0,0,0")

        leftPanel.Add("Border").Grid_Row(1).Use("CardPanel").Add("TreeView").Name("TreeElements").Background("Transparent").BorderThickness(0)

        grid.Add("GridSplitter").Grid_Column(1).Width(5).HorizontalAlignment("Center").Background("Transparent")

        rightPanel := grid.Add("Grid").Grid_Column(2)
        rightPanel.Rows("Auto", "*")

        topRight := rightPanel.Add("Grid").Grid_Row(0)
        topRight.Cols("*", "Auto")
        topRight.Add("TextBlock").Name("TxtSelectedElement").Text("Select an element").FontWeight("Bold").FontSize(14).Margin("0,0,0,10").Foreground("{DynamicResource TextMain}")

        innerTab := rightPanel.Add("TabControl").Name("PropsTabs").Grid_Row(1).Background("Transparent").BorderThickness("0,1,0,0").BorderBrush("{DynamicResource ControlBorder}")

        ; Styles tab
        tabStyles := innerTab.Add("TabItem").Header("Styles")
        svStyles := tabStyles.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").Margin("0,10,0,0")
        this.propsPanelStyles := svStyles.Add("StackPanel").Name("PanelPropsStyles").Margin("0,10,0,10")

        ; Computed tab
        tabComputed := innerTab.Add("TabItem").Header("Computed")
        svComputed := tabComputed.Add("ScrollViewer").VerticalScrollBarVisibility("Auto").Margin("0,10,0,0")
        this.propsPanelComputed := svComputed.Add("StackPanel").Name("PanelPropsComputed").Margin("0,10,0,10")

        ; Properties tab
        tabProps := innerTab.Add("TabItem").Header("Properties")
        propsGrid := tabProps.Add("Grid").Margin("0,10,0,0")
        propsGrid.Rows("Auto", "*")

        propsFiltersPanel := propsGrid.Add("Grid").Grid_Row(0).Margin("0,0,0,5")
        propsFiltersPanel.Rows("Auto", "Auto")

        toolbarProps := propsFiltersPanel.Add("WrapPanel").Orientation("Horizontal").Margin("0,0,0,5")

        ; Filter popover trigger
        filterBtn := toolbarProps.Add("ToggleButton").Name("BtnPropsFilters").Content("Filter Options ▾").Width(110).Height(24).ToolTip("Toggle Property Filters").Margin("0,0,5,0")

        ; Create a popover stacked with checkboxes
        pop := filterBtn.AddRichPopover()
        pop.MinWidth(220)
        pop.Add("TextBlock").Text("Filter Properties").FontWeight("Bold").FontSize(12).Margin("0,0,0,10").Foreground("{DynamicResource TextMain}")

        pop.Add("CheckBox").Name("BtnFilterAlpha").Content("Sort Alphabetically (A-Z)").Margin("0,4,0,4").IsChecked("True")
        pop.Add("CheckBox").Name("BtnFilterGroup").Content("Group by Category").Margin("0,4,0,4").IsChecked("True")
        pop.Add("CheckBox").Name("BtnFilterLocal").Content("Show Local Properties Only").Margin("0,4,0,4")
        pop.Add("CheckBox").Name("BtnFilterValid").Content("Hide Empty / Null Values").Margin("0,4,0,4")
        pop.Add("CheckBox").Name("BtnFilterEdit").Content("Show Writeable Only (R/W)").Margin("0,4,0,4")

        cb := toolbarProps.Add("ComboBox").Name("ComboPresets").Width(100).Height(24).Margin("0,0,5,0").Foreground("{DynamicResource TextMain}").Background("{DynamicResource ControlBg}")
        cb.Add("ComboBoxItem").Content("All").IsSelected("True")
        cb.Add("ComboBoxItem").Content("Events")
        cb.Add("ComboBoxItem").Content("Mouse & Keys")
        cb.Add("ComboBoxItem").Content("Layout")
        cb.Add("ComboBoxItem").Content("Theme")
        cb.Add("ComboBoxItem").Content("Scroll")

        searchGrid := propsFiltersPanel.Add("Grid").Grid_Row(1).Margin("0,0,0,10")
        searchGrid.Cols("*", "Auto")
        searchGrid.Add("TextBox").Name("TxtPropSearch").Height(24).Background("{DynamicResource ControlBg}").Foreground("{DynamicResource TextMain}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("4,2").ToolTip("Search Properties...").SetProp("Tag", "Search properties...")

        svProps := propsGrid.Add("ScrollViewer").Grid_Row(1).VerticalScrollBarVisibility("Auto")
        this.propsPanel := svProps.Add("StackPanel").Name("PanelProps").Margin("0,10,0,10")

        ; Events tab
        tabEvents := innerTab.Add("TabItem").Header("Events")
        eventsGrid := tabEvents.Add("Grid").Margin("0,10,0,0")
        eventsGrid.Rows("Auto", "*")

        eventsSearchGrid := eventsGrid.Add("Grid").Grid_Row(0).Margin("0,0,0,10")
        eventsSearchGrid.Add("TextBox").Name("TxtEventSearch").Height(24).Background("{DynamicResource ControlBg}").Foreground("{DynamicResource TextMain}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("4,2").ToolTip("Search Events...").SetProp("Tag", "Search events...")

        svEvents := eventsGrid.Add("ScrollViewer").Grid_Row(1).VerticalScrollBarVisibility("Auto")
        this.propsPanelEvents := svEvents.Add("StackPanel").Name("PanelPropsEvents").Margin("0,10,0,10")
    }

    BuildPipelineTab(tab) {
        grid := tab.Add("Grid")
        grid.Rows("Auto", "*")

        toolbar := grid.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,5")
        toolbar.Add("Button").Name("BtnClearPipeline").Content("Clear Log").Use("PrimaryBtn").Width(80).Height(25)
        toolbar.Add("ToggleButton").Name("BtnTogglePipelineDetails").Content("Show Details").Use("PrimaryBtn").Width(100).Height(25).Margin("5,0,0,0").IsChecked("True")

        mainGrid := grid.Add("Grid").Grid_Row(1)
        mainGrid.Cols("*", "Auto", "Auto")

        leftBorder := mainGrid.Add("Border").Grid_Column(0).Use("CardPanel")
        leftBorder.Add("ListBox").Name("LogPipeline").Background("Transparent").BorderThickness(0).Foreground("{DynamicResource TextMain}").FontFamily("Consolas").Padding("5").SetProp("ScrollViewer.HorizontalScrollBarVisibility", "Disabled")

        mainGrid.Add("GridSplitter").Name("PipelineSplitter").Grid_Column(1).Width(5).HorizontalAlignment("Center").Background("Transparent")

        rightBorder := mainGrid.Add("Border").Name("PipelineDetails").Grid_Column(2).Width(300).Use("CardPanel").Margin("5,0,0,0")
        rightBorder.Add("TextBox").Name("TxtPipelineDetails").Background("Transparent").BorderThickness(0).Foreground("{DynamicResource TextMain}").IsReadOnly("True").VerticalScrollBarVisibility("Auto").TextWrapping("Wrap").FontFamily("Consolas").Padding("5")
    }

    BuildConsoleTab(tab) {
        grid := tab.Add("Grid")
        grid.Rows("Auto", "*", "Auto")

        toolbar := grid.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,5")
        toolbar.Add("Button").Name("BtnClearConsole").Content("Clear").Use("PrimaryBtn").Width(80).Height(25)

        grid.Add("Border").Grid_Row(1).Use("CardPanel").Margin("0,0,0,10").Add("TextBox").Name("LogConsole").Background("Transparent").BorderThickness(0).Foreground("{DynamicResource TextMain}").IsReadOnly("True").VerticalScrollBarVisibility("Auto").TextWrapping("Wrap").FontFamily("Consolas")

        inputGrid := grid.Add("Grid").Grid_Row(2)
        inputGrid.Cols("*", "Auto")
        inputGrid.Add("TextBox").Name("InputConsole").FontFamily("Consolas").Height(30)
        inputGrid.Add("Button").Name("BtnConsoleRun").Grid_Column(1).Content("Run").Use("PrimaryBtn").Width(80).Margin("10,0,0,0")
    }

    RequestTree(*) {
        this.target.Update("DEVTOOLS", "GetTree", "")
    }

    OnTreeReceived(state, ctrl, event) {
        rawTree := state["DevToolsTree"]
        if (rawTree == "")
            return

        this.hashToName := Map()
        lines := StrSplit(rawTree, "`n", "`r")
        xml := ""
        openLevels := []
        itemCount := 0

        for index, line in lines {
            if (line == "")
                continue

            parts := StrSplit(line, "|")
            if (parts.Length < 7)
                continue

            level := Integer(parts[1])
            type := parts[2]
            name := parts[3]
            size := parts[4] "x" parts[5]
            visibility := parts[6]
            hash := parts[7]

            this.hashToName[hash] := name

            displayName := type
            if (name != "")
                displayName .= " (" name ")"
            displayName .= "  [" size "]"

            uid := parts.Length >= 8 ? parts[8] : ""
            if (uid != "")
                displayName .= " [Line: " uid "]"

            displayName := StrReplace(displayName, '"', "&quot;")
            displayName := StrReplace(displayName, '<', "&lt;")
            displayName := StrReplace(displayName, '>', "&gt;")

            ; Close any open items that are at a level >= the current level
            while (openLevels.Length > 0 && openLevels[openLevels.Length] >= level) {
                openLevels.Pop()
                xml .= "</TreeViewItem>`n"
            }

            itemCount++
            if (itemCount == 1) {
                xml .= '<TreeViewItem xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Header="' displayName '" Tag="' hash '" IsExpanded="True">'
            } else {
                xml .= '<TreeViewItem Header="' displayName '" Tag="' hash '" IsExpanded="False">`n'
            }

            openLevels.Push(level)
        }

        ; Close any remaining open items
        while (openLevels.Length > 0) {
            openLevels.Pop()
            xml .= "</TreeViewItem>`n"
        }

        this.app.host.Update("TreeElements", "ClearItems", "")
        this.app.host.Update("TreeElements", "AddXamlItem", xml)

        if (this.HasProp("selectedHash") && this.selectedHash != "") {
            this.app.host.Update("TreeElements", "SelectByTag", this.selectedHash)
        }
    }

    OnElementSelected(state, ctrl, event) {
        selectedHash := state["TreeElements"]
        if (selectedHash == "")
            return

        this.selectedHash := selectedHash

        ; Query target window's elements to highlight and get properties
        this.target.Update("DEVTOOLS", "Highlight", selectedHash)
        this.target.Update("DEVTOOLS", "GetProps", selectedHash)
    }

    OnPropsReceived(state, ctrl, event) {
        rawProps := state["DevToolsProps"]
        if (rawProps == "")
            return

        lines := StrSplit(rawProps, "`n", "`r")
        if (lines.Length == 0)
            return

        elementName := lines[1]
        this.app.host.Update("TxtSelectedElement", "Text", "Element: " elementName)

        this.currentProps := []

        loop lines.Length {
            if (A_Index == 1 || lines[A_Index] == "")
                continue

            line := lines[A_Index]

            parts := StrSplit(line, "|", , 4)
            if (parts.Length < 4)
                continue

            category := parts[1]
            isLocal := parts[2] == "1"
            isReadOnly := parts[3] == "1"
            rest := parts[4]

            pos := InStr(rest, "=")
            if !pos
                continue

            leftPart := SubStr(rest, 1, pos - 1)
            rightPart := SubStr(rest, pos + 1)

            colPos := InStr(leftPart, ":")
            if !colPos
                continue

            propType := SubStr(leftPart, 1, colPos - 1)
            propName := SubStr(leftPart, colPos + 1)

            ; Decode value values escaped by C# bridge
            propVal := rightPart
            propVal := StrReplace(propVal, "&#x7C;", "|")
            propVal := StrReplace(propVal, "&#x3D;", "=")
            propVal := StrReplace(propVal, "&#x0A;", "`n")
            propVal := StrReplace(propVal, "&#x0D;", "`r")

            ; Translate NaN on width/height to "Auto"
            lname := StrLower(propName)
            if (propVal == "NaN" && (InStr(lname, "width") || InStr(lname, "height"))) {
                propVal := "Auto"
            }

            this.currentProps.Push({
                Cat: category,
                Local: isLocal,
                ReadOnly: isReadOnly,
                Type: propType,
                Name: propName,
                Val: propVal
            })
        }

        this.RenderProps()
    }

    OnPropFilterChanged(*) {
        this.RenderProps()
    }

    GetPropVal(name, defaultVal := "0") {
        if (!this.HasProp("currentProps"))
            return defaultVal
        for p in this.currentProps {
            if (p.Name == name)
                return p.Val
        }
        return defaultVal
    }

    ParseThickness(val) {
        if (val == "null" || val == "" || val == "NaN")
            return { Left: "0", Top: "0", Right: "0", Bottom: "0" }

        parts := StrSplit(val, ",")
        if (parts.Length == 1) {
            v := Trim(parts[1])
            if (v == "")
                v := "0"
            return { Left: v, Top: v, Right: v, Bottom: v }
        } else if (parts.Length == 2) {
            h := Trim(parts[1])
            v := Trim(parts[2])
            return { Left: h, Right: h, Top: v, Bottom: v }
        } else if (parts.Length == 4) {
            return { Left: Trim(parts[1]), Top: Trim(parts[2]), Right: Trim(parts[3]), Bottom: Trim(parts[4]) }
        }
        return { Left: "0", Top: "0", Right: "0", Bottom: "0" }
    }

    EscapeXml(str) {
        str := StrReplace(str, "&", "&amp;")
        str := StrReplace(str, '"', "&quot;")
        str := StrReplace(str, "<", "&lt;")
        str := StrReplace(str, ">", "&gt;")
        if (SubStr(str, 1, 1) = "{") {
            str := "{}" . str
        }
        return str
    }

    RenderProps() {
        if (!this.HasProp("currentProps"))
            return

        alpha := this.app.host.Query("BtnFilterAlpha") == "True"
        group := this.app.host.Query("BtnFilterGroup") == "True"
        filterLocal := this.app.host.Query("BtnFilterLocal") == "True"
        valid := this.app.host.Query("BtnFilterValid") == "True"
        editOnly := this.app.host.Query("BtnFilterEdit") == "True"
        searchQ := StrLower(this.app.host.Query("TxtPropSearch"))
        preset := this.app.host.Query("ComboPresets")

        ; Clear all four panels
        this.app.host.Update("PanelPropsStyles", "ClearItems", "")
        this.app.host.Update("PanelPropsComputed", "ClearItems", "")
        this.app.host.Update("PanelProps", "ClearItems", "")
        this.app.host.Update("PanelPropsEvents", "ClearItems", "")

        props := []
        for p in this.currentProps
            props.Push(p)

        if (alpha) {
            ; Simple bubble sort for AHK
            n := props.Length
            loop n - 1 {
                i := A_Index
                loop n - i {
                    j := A_Index
                    if (StrCompare(props[j].Name, props[j + 1].Name) > 0) {
                        temp := props[j]
                        props[j] := props[j + 1]
                        props[j + 1] := temp
                    }
                }
            }
        }

        ; --- 1. RENDER STYLES TAB ---
        stylesXml := '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Margin="5,10,5,10">'

        ; Local styles block
        stylesXml .= '<TextBlock Text="element.style {" Foreground="#DCDCAA" FontFamily="Consolas" FontSize="12" FontWeight="Bold" Margin="0,0,0,5"/>'
        localStyleCount := 0
        for p in props {
            if (p.Cat == "Style" && p.Local) {
                localStyleCount++
                displayName := this.EscapeXml(p.Name)
                displayVal := this.EscapeXml(p.Val)

                opacity := p.ReadOnly ? "0.45" : "1.0"
                roComment := p.ReadOnly ? '  <Run Text="  /* read-only */" Foreground="#6A9955" FontStyle="Italic"/>' : ''

                stylesXml .= Format('
                ( LTrim
                    <Grid Margin="15,2,5,2" Opacity="{5}">
                    <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto" />
                    <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Text="•" Foreground="#666666" Margin="0,0,8,0" FontFamily="Consolas" FontSize="11.5" />
                    <TextBlock Grid.Column="1" FontFamily="Consolas" FontSize="11.5" TextWrapping="Wrap" ToolTip="{4}">
                    <Run Text="{1}" Foreground="#4EC9B0" />
                    <Run Text=": " Foreground="#CCCCCC" />
                    <Run Text="{2}" Foreground="#CE9178" />
                    <Run Text=";" Foreground="#CCCCCC" />
                    {3}
                    </TextBlock>
                    </Grid>
                )', displayName, displayVal, roComment, p.Type, opacity)
            }
        }

        if (localStyleCount == 0) {
            stylesXml .= '<TextBlock Text="  /* no local styles applied */" Foreground="#6A9955" FontFamily="Consolas" FontSize="11.5" FontStyle="Italic" Margin="15,2,5,2"/>'
        }
        stylesXml .= '<TextBlock Text="}" Foreground="#DCDCAA" FontFamily="Consolas" FontSize="12" FontWeight="Bold" Margin="0,5,0,15"/>'

        ; Inherited styles block
        stylesXml .= '<TextBlock Text="Style (Inherited / Resources) {" Foreground="#DCDCAA" FontFamily="Consolas" FontSize="12" FontWeight="Bold" Margin="0,0,0,5"/>'
        inheritedStyleCount := 0
        for p in props {
            if (p.Cat == "Style" && !p.Local) {
                inheritedStyleCount++
                displayName := this.EscapeXml(p.Name)
                displayVal := this.EscapeXml(p.Val)

                opacity := p.ReadOnly ? "0.45" : "1.0"
                roComment := p.ReadOnly ? '  <Run Text="  /* read-only */" Foreground="#6A9955" FontStyle="Italic"/>' : ''

                stylesXml .= Format('
                ( LTrim
                    <Grid Margin="15,2,5,2" Opacity="{5}">
                    <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto" />
                    <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Text="•" Foreground="#666666" Margin="0,0,8,0" FontFamily="Consolas" FontSize="11.5" />
                    <TextBlock Grid.Column="1" FontFamily="Consolas" FontSize="11.5" TextWrapping="Wrap" ToolTip="{4}">
                    <Run Text="{1}" Foreground="#9CDCFE" />
                    <Run Text=": " Foreground="#CCCCCC" />
                    <Run Text="{2}" Foreground="#CE9178" />
                    <Run Text=";" Foreground="#CCCCCC" />
                    {3}
                    </TextBlock>
                    </Grid>
                )', displayName, displayVal, roComment, p.Type, opacity)
            }
        }

        if (inheritedStyleCount == 0) {
            stylesXml .= '<TextBlock Text="  /* no inherited styles */" Foreground="#6A9955" FontFamily="Consolas" FontSize="11.5" FontStyle="Italic" Margin="15,2,5,2"/>'
        }
        stylesXml .= '<TextBlock Text="}" Foreground="#DCDCAA" FontFamily="Consolas" FontSize="12" FontWeight="Bold" Margin="0,5,0,0"/>'
        stylesXml .= '</StackPanel>'

        this.app.host.Update("PanelPropsStyles", "AddXamlItem", stylesXml)


        ; --- 2. RENDER COMPUTED BOX MODEL TAB ---
        marginThick := this.ParseThickness(this.GetPropVal("Margin", "0"))
        paddingThick := this.ParseThickness(this.GetPropVal("Padding", "0"))
        borderThick := this.ParseThickness(this.GetPropVal("BorderThickness", "0"))

        actW := this.GetPropVal("ActualWidth", "-")
        actH := this.GetPropVal("ActualHeight", "-")
        if (actW != "-") {
            try actW := Round(Number(actW))
        }
        if (actH != "-") {
            try actH := Round(Number(actH))
        }

        compXml := '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" HorizontalAlignment="Center" Margin="5,15,5,15" Background="Transparent">'
        compXml .= '<Border Background="#F9CC9D" CornerRadius="2" BorderThickness="1" BorderBrush="#E5B98A" Padding="4">'
        compXml .= '<Grid><TextBlock Text="margin" Foreground="#555555" FontSize="9" FontWeight="Bold" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="2,0,0,0"/>'
        compXml .= '<StackPanel Orientation="Vertical">'
        compXml .= '<TextBlock Text="' marginThick.Top '" Foreground="#444444" FontSize="10" HorizontalAlignment="Center" Margin="0,2,0,2"/>'
        compXml .= '<Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>'
        compXml .= '<TextBlock Grid.Column="0" Text="' marginThick.Left '" Foreground="#444444" FontSize="10" VerticalAlignment="Center" Margin="2,0,10,0"/>'

        ; Border Box
        compXml .= '<Border Grid.Column="1" Background="#FDE89C" CornerRadius="2" BorderThickness="1" BorderBrush="#E5D38A" Padding="4">'
        compXml .= '<Grid><TextBlock Text="border" Foreground="#555555" FontSize="9" FontWeight="Bold" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="2,0,0,0"/>'
        compXml .= '<StackPanel Orientation="Vertical">'
        compXml .= '<TextBlock Text="' borderThick.Top '" Foreground="#444444" FontSize="10" HorizontalAlignment="Center" Margin="0,2,0,2"/>'
        compXml .= '<Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>'
        compXml .= '<TextBlock Grid.Column="0" Text="' borderThick.Left '" Foreground="#444444" FontSize="10" VerticalAlignment="Center" Margin="2,0,10,0"/>'

        ; Padding Box
        compXml .= '<Border Grid.Column="1" Background="#C3E88D" CornerRadius="2" BorderThickness="1" BorderBrush="#B2D381" Padding="4">'
        compXml .= '<Grid><TextBlock Text="padding" Foreground="#555555" FontSize="9" FontWeight="Bold" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="2,0,0,0"/>'
        compXml .= '<StackPanel Orientation="Vertical">'
        compXml .= '<TextBlock Text="' paddingThick.Top '" Foreground="#444444" FontSize="10" HorizontalAlignment="Center" Margin="0,2,0,2"/>'
        compXml .= '<Grid><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>'
        compXml .= '<TextBlock Grid.Column="0" Text="' paddingThick.Left '" Foreground="#444444" FontSize="10" VerticalAlignment="Center" Margin="2,0,10,0"/>'

        ; Content Box
        compXml .= '<Border Grid.Column="1" Background="#A6D3F9" CornerRadius="2" BorderThickness="1" BorderBrush="#94BEE2" Padding="15,6">'
        compXml .= '<TextBlock Text="' actW ' × ' actH '" Foreground="#222222" FontSize="10.5" FontWeight="Bold" HorizontalAlignment="Center" VerticalAlignment="Center"/>'
        compXml .= '</Border>'

        compXml .= '<TextBlock Grid.Column="2" Text="' paddingThick.Right '" Foreground="#444444" FontSize="10" VerticalAlignment="Center" Margin="10,0,2,0"/>'
        compXml .= '</Grid>'
        compXml .= '<TextBlock Text="' paddingThick.Bottom '" Foreground="#444444" FontSize="10" HorizontalAlignment="Center" Margin="0,2,0,2"/>'
        compXml .= '</StackPanel></Grid></Border>'

        compXml .= '<TextBlock Grid.Column="2" Text="' borderThick.Right '" Foreground="#444444" FontSize="10" VerticalAlignment="Center" Margin="10,0,2,0"/>'
        compXml .= '</Grid>'
        compXml .= '<TextBlock Text="' borderThick.Bottom '" Foreground="#444444" FontSize="10" HorizontalAlignment="Center" Margin="0,2,0,2"/>'
        compXml .= '</StackPanel></Grid></Border>'

        compXml .= '<TextBlock Grid.Column="2" Text="' marginThick.Right '" Foreground="#444444" FontSize="10" VerticalAlignment="Center" Margin="10,0,2,0"/>'
        compXml .= '</Grid>'
        compXml .= '<TextBlock Text="' marginThick.Bottom '" Foreground="#444444" FontSize="10" HorizontalAlignment="Center" Margin="0,2,0,2"/>'
        compXml .= '</StackPanel></Grid></Border>'
        compXml .= '</Grid>'

        layoutXml := '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Margin="0,15,0,0">'
        layoutXml .= '<TextBlock Text="Computed Layout Properties" Foreground="{DynamicResource TextSub}" FontWeight="Bold" FontSize="11" Margin="5,0,0,10"/>'

        layoutIndex := 0
        for p in props {
            lname := StrLower(p.Name)
            if (InStr(lname, "margin") || InStr(lname, "padding") || InStr(lname, "align") || InStr(lname, "width") || InStr(lname, "height") || InStr(lname, "grid.") || InStr(lname, "canvas.") || InStr(lname, "row") || InStr(lname, "column") || InStr(lname, "thickness") || InStr(lname, "visibility") || InStr(lname, "dock")) {

                layoutIndex++
                displayName := this.EscapeXml(p.Name)
                displayVal := this.EscapeXml(p.Val)

                labelColor := p.Local ? "#4EC9B0" : "#9CDCFE"
                bgColor := (Mod(layoutIndex, 2) == 0) ? "#0AFFFFFF" : "Transparent"
                opacity := p.ReadOnly ? "0.45" : "1.0"

                layoutXml .= Format('
                ( LTrim
                    <Grid Margin="0" Background="{6}" Opacity="{7}">
                    <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="140" />
                    <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Text="{1}" Foreground="{4}" FontWeight="Normal" VerticalAlignment="Center" Margin="5,4,5,4" ToolTip="{2} (Local: {5})" TextTrimming="CharacterEllipsis" />
                    <TextBox Grid.Column="1" Text="{3}" Background="Transparent" Foreground="#CCCCCC" BorderThickness="0" Padding="5,4" IsReadOnly="True" />
                    </Grid>
                )', displayName, p.Type, displayVal, labelColor, p.Local ? "Yes" : "No", bgColor, opacity)
            }
        }
        layoutXml .= '</StackPanel>'

        this.app.host.Update("PanelPropsComputed", "AddXamlItem", compXml)
        this.app.host.Update("PanelPropsComputed", "AddXamlItem", layoutXml)


        ; --- 3. RENDER ALL PROPERTIES TAB ---
        xml := '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">'

        groups := Map()
        if (group) {
            groups["Style"] := []
            groups["Properties"] := []
            groups["Events"] := []
            groups["Other"] := []
        } else {
            groups["All"] := []
        }

        for p in props {
            if (filterLocal && !p.Local)
                continue
            if (editOnly && p.ReadOnly)
                continue
            if (valid && (p.Val == "null" || p.Val == ""))
                continue

            if (searchQ != "") {
                if (!InStr(StrLower(p.Name), searchQ) && !InStr(StrLower(p.Val), searchQ))
                    continue
            }

            if (preset != "" && preset != "All") {
                lname := StrLower(p.Name)
                match := false
                if (preset == "Mouse & Keys" && (InStr(lname, "mouse") || InStr(lname, "key") || InStr(lname, "click") || InStr(lname, "focus")))
                    match := true
                else if (preset == "Layout" && (InStr(lname, "margin") || InStr(lname, "padding") || InStr(lname, "align") || InStr(lname, "width") || InStr(lname, "height") || InStr(lname, "size")))
                    match := true
                else if (preset == "Theme" && (InStr(lname, "background") || InStr(lname, "foreground") || InStr(lname, "brush") || InStr(lname, "color") || InStr(lname, "border") || InStr(lname, "opacity") || InStr(lname, "fill") || InStr(lname, "stroke")))
                    match := true
                else if (preset == "Scroll" && InStr(lname, "scroll"))
                    match := true
                else if (preset == "Text" && (InStr(lname, "font") || InStr(lname, "text")))
                    match := true
                else if (preset == "Events" && p.Cat == "Events")
                    match := true

                if (!match)
                    continue
            }

            cat := group ? p.Cat : "All"
            if (!groups.Has(cat))
                groups[cat] := []
            groups[cat].Push(p)
        }

        for cat, list in groups {
            if (list.Length == 0)
                continue

            if (group) {
                xml .= '<Expander IsExpanded="True" Margin="0,2,0,0"><Expander.Header><TextBlock Text="' cat '" Foreground="#E6E6E6" FontWeight="Bold" Margin="0"/></Expander.Header><StackPanel Margin="0,2,0,5">'
            }

            for index, p in list {
                displayName := this.EscapeXml(p.Name)
                displayVal := this.EscapeXml(p.Val)

                labelColor := p.Local ? "#4EC9B0" : "#9CDCFE"
                bgColor := (Mod(index, 2) == 0) ? "#0AFFFFFF" : "Transparent"
                opacity := p.ReadOnly ? "0.45" : "1.0"

                xml .= Format('
                ( LTrim
                    <Grid Margin="0" Background="{6}" Opacity="{7}">
                    <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="140" />
                    <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Text="{1}" Foreground="{4}" FontWeight="Normal" VerticalAlignment="Center" Margin="5,4,5,4" ToolTip="{2} (Local: {5})" TextTrimming="CharacterEllipsis" />
                    <TextBox Grid.Column="1" Text="{3}" Background="Transparent" Foreground="#CCCCCC" BorderThickness="0" Padding="5,4" IsReadOnly="True" />
                    </Grid>
                )', displayName, p.Type, displayVal, labelColor, p.Local ? "Yes" : "No", bgColor, opacity)
            }

            if (group) {
                xml .= '</StackPanel></Expander>'
            }
        }

        xml .= '</StackPanel>'

        this.app.host.Update("PanelProps", "AddXamlItem", xml)


        ; --- 4. RENDER EVENTS TAB ---
        eventSearchQ := StrLower(this.app.host.Query("TxtEventSearch"))
        eventsXml := '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">'

        eventIndex := 0
        for p in props {
            if (p.Cat == "Events") {
                if (eventSearchQ != "") {
                    if (!InStr(StrLower(p.Name), eventSearchQ) && !InStr(StrLower(p.Val), eventSearchQ))
                        continue
                }

                eventIndex++
                displayName := this.EscapeXml(p.Name)
                displayVal := this.EscapeXml(p.Val)

                ; Check if target has AHK event callback registered
                ctrlName := ""
                if (this.HasProp("selectedHash") && this.selectedHash != "" && this.hashToName.Has(this.selectedHash)) {
                    ctrlName := this.hashToName[this.selectedHash]
                }

                isHooked := false
                hookedText := displayVal
                if (ctrlName != "" && this.target.events.Has(ctrlName) && this.target.events[ctrlName].Has(p.Name)) {
                    evtList := this.target.events[ctrlName][p.Name]
                    if (evtList.Length > 0) {
                        isHooked := true
                        cb := evtList[1].Callback
                        cbName := this.GetCallbackName(cb)
                        hookedText := "Hooked: " . cbName
                    }
                }

                labelColor := isHooked ? "#A6E3A1" : "#BD93F9" ; Green if hooked, Purple for normal CLR event
                bgColor := (Mod(eventIndex, 2) == 0) ? "#0AFFFFFF" : "Transparent"

                eventsXml .= Format('
                ( LTrim
                    <Grid Margin="0" Background="{4}">
                    <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="160" />
                    <ColumnDefinition Width="*" />
                    </Grid.ColumnDefinitions>
                    <TextBlock Text="{2}" Foreground="{3}" FontWeight="SemiBold" VerticalAlignment="Center" Margin="5,4,5,4" ToolTip="{2}" TextTrimming="CharacterEllipsis" />
                    <TextBox Grid.Column="1" Text="{1}" Background="Transparent" Foreground="#CCCCCC" BorderThickness="0" Padding="5,4" IsReadOnly="True" />
                    </Grid>
                )', this.EscapeXml(hookedText), displayName, labelColor, bgColor)
            }
        }

        if (eventIndex == 0) {
            eventsXml .= '<TextBlock Text="No events registered." Foreground="{DynamicResource TextSub}" Margin="5,10,0,0" FontStyle="Italic"/>'
        }

        eventsXml .= '</StackPanel>'

        this.app.host.Update("PanelPropsEvents", "AddXamlItem", eventsXml)
    }

    LogIPC(dir, payload) {
        ts := FormatTime(, "HH:mm:ss") "." A_MSec
        dirIcon := (dir == "IN") ? "<-" : "->"
        
        summary := ts . " " . dirIcon . " " . this.SummarizePayload(dir, payload)
        
        ; Save raw message with timestamp for details look up
        rawMsg := ts . " " . dirIcon . " " . payload
        this.pipelineLogs.Push(rawMsg)
        
        this.app.host.Update("LogPipeline", "AddItem", summary)
    }

    GetCallbackName(cb) {
        if (Type(cb) == "String")
            return cb
        try {
            if (HasProp(cb, "Name"))
                return cb.Name
        }
        try {
            return cb.Name
        }
        return Type(cb)
    }

    OnClearPipeline(*) {
        this.pipelineLogs := []
        this.app.host.Update("LogPipeline", "ClearItems", "")
        this.app.host.Update("TxtPipelineDetails", "Text", "")
    }

    OnPipelineSelected(state, ctrl, event) {
        selectedText := state["LogPipeline"]
        if (selectedText == "")
            return
            
        pos := InStr(selectedText, " ")
        if (!pos)
            return
        ts := SubStr(selectedText, 1, pos - 1)
        
        rawMsg := ""
        for item in this.pipelineLogs {
            if (SubStr(item, 1, pos - 1) == ts) {
                rawMsg := item
                break
            }
        }
        
        if (rawMsg != "") {
            formatted := this.FormatRawPayload(rawMsg)
            this.app.host.Update("TxtPipelineDetails", "Text", formatted)
        }
    }

    OnTogglePipelineDetails(state, ctrl, event) {
        isChecked := state["BtnTogglePipelineDetails"] == "True"
        this.app.host.Update("PipelineSplitter", "Visibility", isChecked ? "Visible" : "Collapsed")
        this.app.host.Update("PipelineDetails", "Visibility", isChecked ? "Visible" : "Collapsed")
    }

    SummarizePayload(dir, payload) {
        if (SubStr(payload, 1, 6) == "EVENT|") {
            parts := StrSplit(payload, "|", , 5)
            if (parts.Length >= 4) {
                ctrlName := parts[3]
                eventName := parts[4]
                return "EVENT [" . ctrlName . " : " . eventName . "]"
            }
        }
        
        parts := StrSplit(payload, "|", , 3)
        if (parts.Length >= 2) {
            ctrl := parts[1]
            prop := parts[2]
            return ctrl . " [" . prop . "]"
        }
        
        return payload
    }

    FormatRawPayload(rawMsg) {
        pos := InStr(rawMsg, "EVENT|")
        if (pos) {
            tsDir := SubStr(rawMsg, 1, pos - 1)
            payload := SubStr(rawMsg, pos)
            
            parts := StrSplit(payload, "|")
            res := tsDir . "`n"
            res .= "Type: " . parts[1] . "`n"
            if (parts.Length >= 2) res .= "Window ID: " . parts[2] . "`n"
            if (parts.Length >= 3) res .= "Control: " . parts[3] . "`n"
            if (parts.Length >= 4) res .= "Event: " . parts[4] . "`n"
            if (parts.Length >= 5) {
                res .= "Payload:`n----------------`n"
                pVal := parts[5]
                pVal := StrReplace(pVal, "&#x7C;", "|")
                pVal := StrReplace(pVal, "&#x3D;", "=")
                pVal := StrReplace(pVal, "&#x0A;", "`n")
                pVal := StrReplace(pVal, "&#x0D;", "`r")
                res .= pVal
            }
            return res
        }
        
        pos := InStr(rawMsg, " -> ")
        if (pos) {
            tsDir := SubStr(rawMsg, 1, pos + 3)
            payload := SubStr(rawMsg, pos + 4)
            parts := StrSplit(payload, "|")
            res := tsDir . "`n"
            if (parts.Length >= 1) res .= "Control: " . parts[1] . "`n"
            if (parts.Length >= 2) res .= "Property: " . parts[2] . "`n"
            if (parts.Length >= 3) {
                res .= "Value: " . parts[3] . "`n"
            }
            return res
        }
        
        return rawMsg
    }

    OnConsoleRun(*) {
        cmd := this.app.host.Query("InputConsole")
        if (cmd == "")
            return

        this.app.host.Update("InputConsole", "Text", "")
        this.LogConsole(">> " cmd)

        ; Console evaluator logic
        if (SubStr(cmd, 1, 1) == "/") {
            ; Elements direct edit: /Background Red
            if (!this.HasProp("selectedHash") || this.selectedHash == "") {
                this.LogConsole("Error: No element selected in Tree view.")
                return
            }

            parts := StrSplit(SubStr(cmd, 2), " ", , 2)
            if (parts.Length < 2) {
                this.LogConsole("Usage: /Property Value  (e.g., /Background Red)")
                return
            }

            propName := parts[1]
            propVal := parts[2]

            this.target.Update(this.selectedHash, propName, propVal)
            this.LogConsole("Applied property update: " propName " = " propVal)

            ; Refresh properties list
            SetTimer(() => this.target.Update("DEVTOOLS", "GetProps", this.selectedHash), -200)
        }
        else if (SubStr(cmd, 1, 6) == "query ") {
            ctrlName := Trim(SubStr(cmd, 7))
            if (ctrlName == "")
                return
            try {
                res := this.target.Query(ctrlName)
                if (Type(res) == "Map") {
                    out := "Map:`n"
                    for k, v in res
                        out .= "  " k " = " v "`n"
                    this.LogConsole(Trim(out, "`n"))
                } else {
                    this.LogConsole("= " res)
                }
            } catch as err {
                this.LogConsole("Query failed: " err.Message)
            }
        }
        else {
            this.LogConsole("Unknown command. Supported:")
            this.LogConsole("  /Property Value - Write a property to the selected element (e.g. /Background Red)")
            this.LogConsole("  query Name      - Read a control's current value (e.g. query TxtName)")
            this.LogConsole("  query *         - Read all tracked values")
        }
    }

    LogConsole(text) {
        current := this.app.host.Query("LogConsole")
        this.app.host.Update("LogConsole", "Text", (current != "" ? current "`n" : "") text)
    }

    OnInspectToggle(state, ctrl, event) {
        isChecked := state["BtnInspect"] == "True"
        this.targetGui.host.Update("AppWindow", "InspectMode", isChecked ? "1" : "0")
    }

    OnInspectPicked(state, ctrl, event) {
        hash := state.Has("InspectPicked") ? state["InspectPicked"] : ""
        if (hash == "")
            return
        this.app.host.Update("BtnInspect", "IsChecked", "False")

        ; Try to expand the tree item via C# (will add support to Bridge)
        this.app.host.Update("TreeElements", "SelectByTag", hash)
    }

    OnClosed(*) {
        try this.target.Update("DEVTOOLS", "Highlight", "")
        global XAML_DevTools_Instance := ""
    }
}