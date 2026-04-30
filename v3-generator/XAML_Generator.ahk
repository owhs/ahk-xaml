class XAML_Generator {
    ; Initialize the builder with an optional root node (default is Window)
    __New(rootNode := "Window", rootAttrs := "") {
        this.Root := rootNode
        this.RootAttrs := rootAttrs
        this.Resources := ""
        this.Body := ""
    }

    ; ==========================================
    ; POWER TOOLS & SHORTHANDS
    ; ==========================================

    ; Injects the massive boilerplate styling so your main script stays clean
    LoadDefaultTheme() {
        this.Resources .= '
        (
            <Window.Resources>
                <SolidColorBrush x:Key="BgColor" Color="#90111114"/>
                <SolidColorBrush x:Key="SidebarColor" Color="#30000000"/>
                <SolidColorBrush x:Key="TextMain" Color="#FFFFFF"/>
                <SolidColorBrush x:Key="TextSub" Color="#AAAAAA"/>
                <SolidColorBrush x:Key="ControlBg" Color="#15FFFFFF"/>
                <SolidColorBrush x:Key="ControlBorder" Color="#20FFFFFF"/>
                <SolidColorBrush x:Key="DropdownBg" Color="#1E1E1E"/>
                <SolidColorBrush x:Key="Accent" Color="#0A84FF"/>
                <!-- Styles abstractly bundled. Include your raw styles here. -->
            </Window.Resources>
        )'
        return this
    }

    ; Shorthand for Grid Column Definitions
    Cols(widths*) {
        def := "<Grid.ColumnDefinitions>`n"
        for w in widths
            def .= '    <ColumnDefinition Width="' w '"/>`n'
        def .= "</Grid.ColumnDefinitions>`n"
        return def
    }

    ; Shorthand for Grid Row Definitions
    Rows(heights*) {
        def := "<Grid.RowDefinitions>`n"
        for h in heights
            def .= '    <RowDefinition Height="' h '"/>`n'
        def .= "</Grid.RowDefinitions>`n"
        return def
    }

    ; Shorthand to build a ToggleSwitch with layout
    Toggle(name, label, isChecked := false, tooltip := "") {
        chk := isChecked ? 'IsChecked="True"' : ''
        tt := tooltip ? 'ToolTip="' tooltip '"' : ''
        return this.Tag("Grid", 'Margin="0,0,0,15"', [
            this.Tag("TextBlock", 'Text="' label '" Foreground="{DynamicResource TextMain}" VerticalAlignment="Center"'),
            this.Tag("CheckBox", 'Name="' name '" Style="{StaticResource ToggleSwitch}" HorizontalAlignment="Right" ' chk ' ' tt)
        ])
    }

    ; Shorthand to build a segmented radio button group
    SegmentGroup(groupName, options, selectedIndex := 1) {
        items := []
        for index, opt in options {
            chk := (index == selectedIndex) ? 'IsChecked="True"' : ''
            brd := (index == options.Length) ? 'BorderThickness="0"' : 'BorderThickness="0,0,1,0"'
            items.Push(this.Tag("RadioButton", 'Style="{StaticResource SegmentedBtn}" Content="' opt '" GroupName="' groupName '" ' chk ' ' brd))
        }
        return this.Tag("Border", 'BorderBrush="{DynamicResource ControlBorder}" BorderThickness="1" CornerRadius="6" HorizontalAlignment="Left" Margin="0,0,0,25"', [
            this.Tag("StackPanel", 'Orientation="Horizontal"', items)
        ])
    }

    ; ==========================================
    ; CORE XAML BUILDER ENGINE
    ; ==========================================

    ; Core method to generate a self-closing or wrapping XAML tag
    Tag(nodeName, attrs := "", children := "") {
        attrStr := ""
        if (Type(attrs) == "Object" || Type(attrs) == "Map") {
            for k, v in (Type(attrs) == "Map" ? attrs : attrs.OwnProps())
                attrStr .= ' ' k '="' v '"'
        } else if (attrs != "") {
            attrStr := " " attrs
        }

        if (children == "")
            return "<" nodeName attrStr " />`n"

        childStr := ""
        if (Type(children) == "Array") {
            for child in children
                childStr .= child
        } else {
            childStr := children
        }

        return "<" nodeName attrStr ">`n" childStr "</" nodeName ">`n"
    }

    ; Compile everything into a final XAML string
    Compile(bodyNodes) {
        if (Type(bodyNodes) == "Array") {
            for node in bodyNodes
                this.Body .= node
        } else {
            this.Body := bodyNodes
        }

        finalXAML := "<" this.Root
        if (this.RootAttrs)
            finalXAML .= " " this.RootAttrs
        finalXAML .= ">`n"
        finalXAML .= this.Resources
        finalXAML .= this.Body
        finalXAML .= "</" this.Root ">"

        return this.Body ;finalXAML
    }
}
