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
        this.app.host.OnEvent("BtnClearPipeline", "Click", (*) => (IsSet(XAML_ENABLE_AVALONEDIT) && XAML_ENABLE_AVALONEDIT) ? this.app.host.Update("LogPipeline", "AE_SetText", "") : this.app.host.Update("LogPipeline", "ClearItems", ""))
        this.app.host.OnEvent("BtnClearConsole", "Click", (*) => this.app.host.Update("LogConsole", "Text", ""))

        this.app.host.OnEvent("BtnFilterAlpha", "Click", ObjBindMethod(this, "OnPropFilterChanged"))
        this.app.host.OnEvent("BtnFilterGroup", "Click", ObjBindMethod(this, "OnPropFilterChanged"))
        this.app.host.OnEvent("BtnFilterLocal", "Click", ObjBindMethod(this, "OnPropFilterChanged"))
        this.app.host.OnEvent("BtnFilterValid", "Click", ObjBindMethod(this, "OnPropFilterChanged"))
        this.app.host.OnEvent("TxtPropSearch", "TextChanged", ObjBindMethod(this, "OnPropFilterChanged"))
        this.app.host.OnEvent("ComboPresets", "SelectionChanged", ObjBindMethod(this, "OnPropFilterChanged"))

        if (IsSet(XAML_ENABLE_AVALONEDIT) && XAML_ENABLE_AVALONEDIT) {
            this.app.host.OnEvent("Window", "LoadedHwnd", (*) => (
                this.app.host.Update("LogPipeline", "AE_Init", "Dark"),
                this.app.host.Update("LogPipeline", "AE_SetLanguage", "Log"),
                this.app.host.Update("LogPipeline", "AE_ReadOnly", "1")
            ))
        }
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
        rightPanel.Rows("Auto", "Auto", "*")
        
        topRight := rightPanel.Add("Grid")
        topRight.Cols("*", "Auto")
        topRight.Add("TextBlock").Name("TxtSelectedElement").Text("Select an element").FontWeight("Bold").FontSize(14).Margin("0,0,0,5").Foreground("{DynamicResource TextMain}")
        
        filtersPanel := rightPanel.Add("Grid").Grid_Row(1).Margin("0,0,0,5")
        filtersPanel.Rows("Auto", "Auto")
        
        toolbarProps := filtersPanel.Add("WrapPanel").Orientation("Horizontal").Margin("0,0,0,5")
        toolbarProps.Add("ToggleButton").Name("BtnFilterAlpha").Content("A-Z").Width(40).Height(24).ToolTip("Sort Alphabetically").Margin("0,0,5,0").IsChecked("True")
        toolbarProps.Add("ToggleButton").Name("BtnFilterGroup").Content("Group").Width(55).Height(24).ToolTip("Group Properties").Margin("0,0,5,0").IsChecked("True")
        toolbarProps.Add("ToggleButton").Name("BtnFilterLocal").Content("Local").Width(55).Height(24).ToolTip("Show Local Only").Margin("0,0,5,0")
        toolbarProps.Add("ToggleButton").Name("BtnFilterValid").Content("Valid").Width(55).Height(24).ToolTip("Hide Empty").Margin("0,0,5,0")
        cb := toolbarProps.Add("ComboBox").Name("ComboPresets").Width(100).Height(24).Margin("0,0,5,0").Foreground("{DynamicResource TextMain}").Background("{DynamicResource ControlBg}")
        cb.Add("ComboBoxItem").Content("All").IsSelected("True")
        cb.Add("ComboBoxItem").Content("Events")
        cb.Add("ComboBoxItem").Content("Mouse & Keys")
        cb.Add("ComboBoxItem").Content("Layout")
        cb.Add("ComboBoxItem").Content("Theme")
        cb.Add("ComboBoxItem").Content("Scroll")

        searchGrid := filtersPanel.Add("Grid").Grid_Row(1)
        searchGrid.Cols("*", "Auto")
        searchGrid.Add("TextBox").Name("TxtPropSearch").Height(24).Background("{DynamicResource ControlBg}").Foreground("{DynamicResource TextMain}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("4,2").ToolTip("Search Properties...").SetProp("Tag", "Search properties...")

        sv := rightPanel.Add("Border").Grid_Row(2).Use("CardPanel").Add("ScrollViewer").VerticalScrollBarVisibility("Auto")
        this.propsPanel := sv.Add("StackPanel").Name("PanelProps").Margin("0,10,0,10")
    }

    BuildPipelineTab(tab) {
        grid := tab.Add("Grid")
        grid.Rows("Auto", "*")

        toolbar := grid.Add("StackPanel").Orientation("Horizontal").Margin("0,0,0,5")
        toolbar.Add("Button").Name("BtnClearPipeline").Content("Clear Log").Use("PrimaryBtn").Width(80).Height(25)

        border := grid.Add("Border").Grid_Row(1).Use("CardPanel")
        if (IsSet(XAML_ENABLE_AVALONEDIT) && XAML_ENABLE_AVALONEDIT) {
            border.Add("ContentControl").Name("LogPipeline").Background("Transparent").Margin("2")
        } else {
            border.Add("ListBox").Name("LogPipeline").Background("Transparent").BorderThickness(0).Foreground("{DynamicResource TextMain}").FontFamily("Consolas").Padding("5").SetProp("ScrollViewer.HorizontalScrollBarVisibility", "Disabled")
        }
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
                xml .= '<TreeViewItem xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Header="' displayName '" Tag="' hash '" IsExpanded="True">'`n
            } else {
                xml .= '<TreeViewItem Header="' displayName '" Tag="' hash '" IsExpanded="False">'`n
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
            
            parts := StrSplit(line, "|", , 3)
            if (parts.Length < 3)
                continue
                
            category := parts[1]
            isLocal := parts[2] == "1"
            rest := parts[3]
            
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
            
            this.currentProps.Push({
                Cat: category,
                Local: isLocal,
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

    RenderProps() {
        if (!this.HasProp("currentProps"))
            return
            
        alpha := this.app.host.Query("BtnFilterAlpha") == "True"
        group := this.app.host.Query("BtnFilterGroup") == "True"
        filterLocal := this.app.host.Query("BtnFilterLocal") == "True"
        valid := this.app.host.Query("BtnFilterValid") == "True"
        searchQ := StrLower(this.app.host.Query("TxtPropSearch"))
        preset := this.app.host.Query("ComboPresets")
        
        this.app.host.Update("PanelProps", "ClearItems", "")
        
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
                    if (StrCompare(props[j].Name, props[j+1].Name) > 0) {
                        temp := props[j]
                        props[j] := props[j+1]
                        props[j+1] := temp
                    }
                }
            }
        }
        
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
                displayName := p.Name
                displayName := StrReplace(displayName, '&', "&amp;")
                displayName := StrReplace(displayName, '"', "&quot;")
                displayName := StrReplace(displayName, '<', "&lt;")
                displayName := StrReplace(displayName, '>', "&gt;")

                displayVal := StrReplace(p.Val, '&', "&amp;")
                displayVal := StrReplace(displayVal, '"', "&quot;")
                displayVal := StrReplace(displayVal, '<', "&lt;")
                displayVal := StrReplace(displayVal, '>', "&gt;")
                
                labelColor := p.Local ? "#4EC9B0" : "#9CDCFE"
                bgColor := (Mod(index, 2) == 0) ? "#0AFFFFFF" : "Transparent"
                
                xml .= Format('
                ( LTrim
                    <Grid Margin="0" Background="{6}">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="140" />
                            <ColumnDefinition Width="*" />
                        </Grid.ColumnDefinitions>
                        <TextBlock Text="{1}" Foreground="{4}" FontWeight="Normal" VerticalAlignment="Center" Margin="5,4,5,4" ToolTip="{2} (Local: {5})" TextTrimming="CharacterEllipsis" />
                        <TextBox Grid.Column="1" Text="{3}" Background="Transparent" Foreground="#CCCCCC" BorderThickness="0" Padding="5,4" IsReadOnly="True" />
                    </Grid>
                )', displayName, p.Type, displayVal, labelColor, p.Local ? "Yes" : "No", bgColor)
            }
            
            if (group) {
                xml .= '</StackPanel></Expander>'
            }
        }
        
        xml .= '</StackPanel>'
        
        this.app.host.Update("PanelProps", "AddXamlItem", xml)
    }

    LogIPC(dir, payload) {
        ts := FormatTime(, "HH:mm:ss") "." A_MSec
        dirIcon := (dir == "IN") ? "<-" : "->"
        msg := ts " " dirIcon " " payload

        if (IsSet(XAML_ENABLE_AVALONEDIT) && XAML_ENABLE_AVALONEDIT) {
            b64 := XAMLHost.Base64Encode(msg "`n")
            this.app.host.Update("LogPipeline", "AE_AppendText", b64)
        } else {
            this.app.host.Update("LogPipeline", "AddItem", msg)
        }
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