#Requires AutoHotkey v2.0
#Include "..\..\lib\XAML_GUI.ahk"
#Include "..\..\lib\XAML_Adv_Components.ahk"
#Include "..\..\lib\XAML_Dialog.ahk"

; ==============================================================================
; STATE MANAGEMENT & DUMMY DATA
; ==============================================================================
global AppState := {
    NightLight: false,
    Brightness: 75,
    Volume: 50,
    Bluetooth: true,
    Wifi: true,
    DarkMode: true
}

global Devices := [
    { Name: "Logitech MX Master 3", Type: "Mouse", Connected: true, Icon: Chr(0xE962) },
    { Name: "AirPods Pro", Type: "Audio", Connected: false, Icon: Chr(0xE7F6) },
    { Name: "Keychron K2", Type: "Keyboard", Connected: true, Icon: Chr(0xE765) }
]

global WifiNetworks := [
    { Name: "MyHomeNetwork_5G", Status: "Connected, secured", Signal: Chr(0xE871) },
    { Name: "Guest_WiFi", Status: "Open", Signal: Chr(0xE873) },
    { Name: "CoffeeShop", Status: "Secured", Signal: Chr(0xE872) }
]

; ==============================================================================
; WINDOWS 11 SETTINGS CLONE
; ==============================================================================

global PersState := {
    CurrentTheme: "Dark Mica (Win 11)",
    Transparency: true,
    BlurEffect: "Mica",
    Rounding: 12,
    Opacity: 56, ; Corresponding to hex alpha 90 (90/FF = 56%)
    BgTint: "#111114",
    Accent: "#0A84FF"
}

global ThemeTiles := ["Dark Mica (Win 11)", "Light Frosted Mode", "Dracula", "Nord", "Cyberpunk Neon", "Sakura"]

global AccentColors := [
    { Id: "Blue", Color: "#0078D7", Name: "Royal Blue" },
    { Id: "Purple", Color: "#744DA9", Name: "Purple" },
    { Id: "Red", Color: "#E81123", Name: "Crimson" },
    { Id: "Orange", Color: "#FF8C00", Name: "Orange" },
    { Id: "Green", Color: "#107C41", Name: "Green" },
    { Id: "Teal", Color: "#00B7C3", Name: "Teal" }
]

global TintColors := [
    { Id: "Midnight", Color: "#111114", Name: "Midnight Black" },
    { Id: "Navy", Color: "#0F172A", Name: "Navy Blue" },
    { Id: "Slate", Color: "#1E293B", Name: "Slate Gray" },
    { Id: "White", Color: "#F8FAFC", Name: "Light White" },
    { Id: "Pink", Color: "#FFF0F5", Name: "Sakura Pink" },
    { Id: "Green", Color: "#F2F6F2", Name: "Sage Green" }
]

global ThemeDefinitions := Map()
global ThemeNames := []

LoadThemes()

app := XAML_GUI("Settings", { Sidebar: false, BurgerMenu: false, TitleBarHeight: 35, AppIcon: false, Width: 1000, Height: 700 })
app.tabs.Visibility("Collapsed")
app.main.Background("{DynamicResource ControlBg}")

; Main Layout
layout := app.main.Add("Grid").Grid_Row(1)
layout.Cols("300", "*")

; ==============================================================================
; LEFT NAVIGATION (SIDEBAR)
; ==============================================================================
sidebar := layout.Add("Border").Grid_Column(0).Background("{DynamicResource SidebarColor}").Padding("15,10,15,10").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,0,1,0")
sidebarSp := sidebar.Add("StackPanel")

; User Profile Header
userProfile := sidebarSp.Add("Grid").Margin("0,0,0,20")
userProfile.Cols("Auto", "*")
userProfile.Add("Ellipse").Width(50).Height(50).Grid_Column(0).Margin("0,0,15,0").SetProp("Fill", "Gray") ; Placeholder for avatar
userInfo := userProfile.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
userInfo.Add("TextBlock").Text("John Doe").Foreground("{DynamicResource TextMain}").FontSize(16).FontWeight("SemiBold")
userInfo.Add("TextBlock").Text("Local Account").Foreground("{DynamicResource TextSub}").FontSize(12)

; Search Box
searchBorder := sidebarSp.Add("Border").CornerRadius("4").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Margin("0,0,0,20")
searchBox := searchBorder.Add("TextBox").Text("Find a setting").Background("{DynamicResource DropdownBg}").Foreground("{DynamicResource TextSub}").BorderThickness("0").Padding("10,6,10,6")

global NavItems := []
global Pages := Map()

AddNavItem(sp, id, icon, label, isSelected := false) {
    bg := isSelected ? "{DynamicResource Accent}" : "Transparent"
    fg := isSelected ? "White" : "{DynamicResource TextMain}"
    op := isSelected ? "1.0" : "0.7"
    item := sp.Add("Border").Name("Nav_" id).CornerRadius("4").Background(bg).Padding("10").Margin("0,0,0,5").Cursor("Hand")
    grid := item.Add("Grid")
    grid.Cols("Auto", "*")
    grid.Add("TextBlock").Name("NavIcon_" id).Text(icon).FontFamily("Segoe Fluent Icons").FontSize(16).Foreground(fg).Margin("0,0,15,0").VerticalAlignment("Center").Grid_Column(0)
    grid.Add("TextBlock").Name("NavText_" id).Text(label).FontSize(14).Foreground(fg).Opacity(op).VerticalAlignment("Center").Grid_Column(1)
    
    NavItems.Push(id)
    return item
}

AddNavItem(sidebarSp, "System", Chr(0xE770), "System", true)
AddNavItem(sidebarSp, "Bluetooth", Chr(0xE702), "Bluetooth & devices")
AddNavItem(sidebarSp, "Network", Chr(0xE774), "Network & internet")
AddNavItem(sidebarSp, "Personalization", Chr(0xE771), "Personalization")
AddNavItem(sidebarSp, "Apps", Chr(0xE713), "Apps")
AddNavItem(sidebarSp, "Accounts", Chr(0xE779), "Accounts")
AddNavItem(sidebarSp, "WindowsUpdate", Chr(0xE74C), "Windows Update")

; ==============================================================================
; HELPER FUNCTIONS FOR CARDS
; ==============================================================================

CreatePageContainer(parent, id) {
    scrollArea := parent.Add("ScrollViewer").Name("Page_" id).Grid_Column(1).Padding("30").Visibility("Collapsed")
    sp := scrollArea.Add("StackPanel")
    Pages[id] := scrollArea
    return sp
}

AddSettingCard(parent, icon, title, desc, controlType, name, defaultValue := "") {
    cardName := (controlType == "Chevron") ? name : "Card_" name
    card := parent.Add("Border").Name(cardName).CornerRadius("8").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("15,10,15,10").Margin("0,0,0,10")
    
    
    ; Hover effect for interactive feel on cards
    if (controlType == "Chevron") {
        card.Cursor("Hand")
        card.InjectResources('<Style TargetType="Border"><Setter Property="Background" Value="{DynamicResource DropdownBg}"/><Style.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="{DynamicResource ControlBg}"/></Trigger></Style.Triggers></Style>')
    }

    grid := card.Add("Grid")
    grid.Cols("Auto", "*", "Auto")
    grid.Add("TextBlock").Text(icon).FontFamily("Segoe Fluent Icons").FontSize(18).Foreground("{DynamicResource TextMain}").Grid_Column(0).Margin("0,0,15,0").VerticalAlignment("Center")
    
    texts := grid.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
    texts.Add("TextBlock").Text(title).FontSize(14).Foreground("{DynamicResource TextMain}")
    if (desc != "")
        texts.Add("TextBlock").Text(desc).FontSize(12).Foreground("{DynamicResource TextSub}").Margin("0,2,0,0")
        
    ctrlArea := grid.Add("StackPanel").Grid_Column(2).VerticalAlignment("Center").Orientation("Horizontal")
    
    if (controlType == "Toggle") {
        isChecked := (defaultValue == true) ? "True" : "False"
        ctrlArea.Add("CheckBox").Name(name).IsChecked(isChecked).Style("{StaticResource ToggleSwitch}").Cursor("Hand")
    } else if (controlType == "Slider") {
        ctrlArea.Add("Slider").Name(name).Width(150).Minimum(0).Maximum(100).Value(String(defaultValue)).Margin("0,0,10,0")
        ctrlArea.Add("TextBlock").Name(name "_Val").Text(String(defaultValue)).Foreground("{DynamicResource TextSub}").Width(30).TextAlignment("Right").VerticalAlignment("Center")
    } else if (controlType == "Button") {
        ctrlArea.Add("Button").Name(name).Content(defaultValue).Padding("15,5,15,5")
    } else if (controlType == "Chevron") {
        ctrlArea.Add("TextBlock").Text(Chr(0xE76C)).FontFamily("Segoe Fluent Icons").FontSize(12).Foreground("{DynamicResource TextSub}").VerticalAlignment("Center")
    }
    
    return card
}

; ==============================================================================
; PAGES
; ==============================================================================

; --- SYSTEM PAGE ---
sysPage := CreatePageContainer(layout, "System")
sysPage.Add("TextBlock").Text("System").FontSize(32).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,20")

sysInfoCard := sysPage.Add("Border").CornerRadius("8").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("20").Margin("0,0,0,20")
sysInfoGrid := sysInfoCard.Add("Grid")
sysInfoGrid.Cols("Auto", "*")
sysInfoGrid.Add("TextBlock").Text(Chr(0xE7F8)).FontFamily("Segoe Fluent Icons").FontSize(48).Foreground("{DynamicResource Accent}").Grid_Column(0).Margin("0,0,20,0").VerticalAlignment("Center")
sysInfoText := sysInfoGrid.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
sysInfoText.Add("TextBlock").Text("Desktop-PC-01").FontSize(20).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}")
sysInfoText.Add("TextBlock").Text("Windows 11 Pro").FontSize(14).Foreground("{DynamicResource TextSub}")

sysPage.Add("TextBlock").Text("Display").FontSize(16).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,10")
AddSettingCard(sysPage, Chr(0xE793), "Night light", "Use warmer colors to help block blue light", "Toggle", "TglNightLight", AppState.NightLight)
AddSettingCard(sysPage, Chr(0xE706), "Brightness", "Adjust the brightness of the built-in display", "Slider", "SldBrightness", AppState.Brightness)

sysPage.Add("TextBlock").Text("Sound").FontSize(16).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,20,0,10")
AddSettingCard(sysPage, Chr(0xE767), "Volume", "Adjust the system volume", "Slider", "SldVolume", AppState.Volume)
AddSettingCard(sysPage, Chr(0xE710), "Add a new output device", "", "Button", "BtnAddDevice", "Add device")

; --- BLUETOOTH PAGE ---
btPage := CreatePageContainer(layout, "Bluetooth")
btPage.Add("TextBlock").Text("Bluetooth & devices").FontSize(32).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,20")
AddSettingCard(btPage, Chr(0xE702), "Bluetooth", "Discoverable as Desktop-PC-01", "Toggle", "TglBluetooth", AppState.Bluetooth)
AddSettingCard(btPage, Chr(0xE710), "Add device", "", "Button", "BtnAddBluetooth", "Add device")

btPage.Add("TextBlock").Text("Devices").FontSize(16).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,20,0,10")
btOffMsg := btPage.Add("TextBlock").Name("BtOffMsg").Text("Bluetooth is turned off.").Foreground("{DynamicResource TextSub}").Margin("0,10,0,0").FontStyle("Italic").Visibility("Collapsed")
btList := btPage.Add("StackPanel").Name("BtList")

for dev in Devices {
    status := dev.Connected ? "Connected" : "Paired"
    AddSettingCard(btList, dev.Icon, dev.Name, status, "Chevron", "BtDev_" A_Index)
}

; --- NETWORK PAGE ---
netPage := CreatePageContainer(layout, "Network")
netPage.Add("TextBlock").Text("Network & internet").FontSize(32).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,20")
AddSettingCard(netPage, Chr(0xE774), "Wi-Fi", "", "Toggle", "TglWifi", AppState.Wifi)
AddSettingCard(netPage, Chr(0xE72A), "VPN", "Add, connect, manage", "Chevron", "BtnVPN")

netPage.Add("TextBlock").Text("Available Networks").FontSize(16).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,20,0,10")
wifiOffMsg := netPage.Add("TextBlock").Name("WifiOffMsg").Text("Wi-Fi is turned off.").Foreground("{DynamicResource TextSub}").Margin("0,10,0,0").FontStyle("Italic").Visibility("Collapsed")
wifiList := netPage.Add("StackPanel").Name("WifiList")

for net in WifiNetworks {
    AddSettingCard(wifiList, net.Signal, net.Name, net.Status, "Chevron", "Wifi_" A_Index)
}

; --- PERSONALIZATION PAGE ---
persPage := CreatePageContainer(layout, "Personalization")
persPage.Add("TextBlock").Text("Personalization").FontSize(32).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,10")

; Theme Gallery section
persPage.Add("TextBlock").Text("Select a theme to apply").FontSize(16).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,10,0,10")

galleryBorder := persPage.Add("Border").CornerRadius("8").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("10").Margin("0,0,0,15")
galleryGrid := galleryBorder.Add("UniformGrid").SetProp("Columns", "3").SetProp("Rows", "2")

; Add theme tiles to gallery
for themeName in ThemeTiles {
    CreateThemeTile(galleryGrid, themeName, A_Index)
}

; More Themes dropdown card
AddSettingComboCard(persPage, Chr(0xE790), "Theme selection", "Select one of 21 custom themes from themes.ini", "ComboThemesList", ThemeNames)

persPage.Add("TextBlock").Text("Customise your materials").FontSize(16).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,15,0,10")

; Dark mode setting card
AddSettingCard(persPage, Chr(0xE790), "Dark mode", "Choose your default app mode", "Toggle", "TglDarkMode", AppState.DarkMode)

; Transparency effects setting card
AddSettingCard(persPage, Chr(0xE741), "Transparency effects", "Windows appear translucent (Mica or Acrylic)", "Toggle", "TglTransparency", PersState.Transparency)

; Blur materials card
AddSettingComboCard(persPage, Chr(0xE774), "Material Blur Effect", "Choose the desktop blur material used for the background", "ComboBlurEffect", ["Mica (High Fidelity)", "Acrylic (Frosted Glass)", "Aero (Classic Glass)"])

; Rounding slider card
AddSettingCard(persPage, Chr(0xE700), "Window Rounding", "Adjust the corner radius of the application window", "Slider", "SldRounding", PersState.Rounding)

; Opacity slider card
AddSettingCard(persPage, Chr(0xE7F4), "Mica/Acrylic Opacity", "Adjust background material tint transparency", "Slider", "SldOpacity", PersState.Opacity)

; Accent color palette card
AddColorPaletteCard(persPage, Chr(0xE790), "Accent Color presets", "Choose your primary theme accent color", "Accent", AccentColors)

; Custom Accent Hex box
AddSettingTextBoxCard(persPage, Chr(0xE7B0), "Custom Accent Color (HEX)", "Fine-tune with a custom hex code (e.g. #FF0055)", "TxtCustomAccent", "BtnCustomAccent", PersState.Accent)

; Background tint palette card
AddColorPaletteCard(persPage, Chr(0xE7F4), "Background Tint presets", "Choose a background color tint", "Tint", TintColors)

; Custom Background Hex box
AddSettingTextBoxCard(persPage, Chr(0xE7B0), "Custom Background Tint (HEX)", "Fine-tune with a custom hex code (e.g. #1E1E1E)", "TxtCustomBg", "BtnCustomBg", PersState.BgTint)

; --- APPS PAGE ---
appsPage := CreatePageContainer(layout, "Apps")
appsPage.Add("TextBlock").Text("Apps").FontSize(32).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,10")
appsPage.Add("TextBlock").Text("Installed apps").FontSize(16).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,15")

; Search & Sort bar card
appSearchCard := appsPage.Add("Border").CornerRadius("8").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("15,10,15,10").Margin("0,0,0,20")
appSearchGrid := appSearchCard.Add("Grid")
appSearchGrid.Cols("250", "*", "Auto")

searchBoxBorder := appSearchGrid.Add("Border").Grid_Column(0).CornerRadius("4").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").VerticalAlignment("Center")
appsSearchBox := searchBoxBorder.Add("TextBox").Name("TxtSearchApps").Text("").Background("{DynamicResource DropdownBg}").Foreground("{DynamicResource TextMain}").BorderThickness("0").Padding("10,6,10,6")
    .On("TextChanged", HandleAppSearch)
    .Track()

sortCombo := appSearchGrid.Add("ComboBox").Name("ComboSortApps").Grid_Column(2).Width("150").Height("32").SelectedIndex(0).VerticalAlignment("Center")
sortCombo.Add("ComboBoxItem").Content("Name (A to Z)")
sortCombo.Add("ComboBoxItem").Content("Size (Large to Small)")

; Apps List container
appsListSp := appsPage.Add("StackPanel").Name("AppsListSp")

global AppList := [
    { Id: "Chrome", Name: "Google Chrome", Publisher: "Google LLC", Size: "1.82 GB", Icon: Chr(0xE12B) },
    { Id: "VSCode", Name: "Visual Studio Code", Publisher: "Microsoft Corporation", Size: "842 MB", Icon: Chr(0xE7C3) },
    { Id: "AHK", Name: "AutoHotkey v2", Publisher: "Lexikos", Size: "12.4 MB", Icon: Chr(0xE70F) },
    { Id: "Steam", Name: "Steam", Publisher: "Valve Corp.", Size: "380 MB", Icon: Chr(0xE7FC) },
    { Id: "Spotify", Name: "Spotify", Publisher: "Spotify AB", Size: "180 MB", Icon: Chr(0xE609) }
]

AddAppCard(parent, appObj) {
    card := parent.Add("Border").Name("Card_App_" appObj.Id).CornerRadius("8").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("15,10,15,10").Margin("0,0,0,10")
    grid := card.Add("Grid")
    grid.Cols("Auto", "*", "Auto", "Auto")
    
    ; Icon
    grid.Add("TextBlock").Text(appObj.Icon).FontFamily("Segoe Fluent Icons").FontSize(24).Foreground("{DynamicResource Accent}").Grid_Column(0).Margin("0,0,20,0").VerticalAlignment("Center")
    
    ; Title & Publisher
    texts := grid.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
    texts.Add("TextBlock").Text(appObj.Name).FontSize(14).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}")
    texts.Add("TextBlock").Text(appObj.Publisher).FontSize(12).Foreground("{DynamicResource TextSub}").Margin("0,2,0,0")
    
    ; Size
    grid.Add("TextBlock").Text(appObj.Size).Foreground("{DynamicResource TextSub}").FontSize(13).VerticalAlignment("Center").Grid_Column(2).Margin("0,0,20,0")
    
    ; Action
    ctrlArea := grid.Add("StackPanel").Grid_Column(3).VerticalAlignment("Center")
    ctrlArea.Add("Button").Name("BtnUninstall_" appObj.Id).Content("Uninstall").Padding("12,5,12,5").Cursor("Hand")
    
    return card
}

for appObj in AppList {
    AddAppCard(appsListSp, appObj)
}

; --- ACCOUNTS PAGE ---
accPage := CreatePageContainer(layout, "Accounts")
accPage.Add("TextBlock").Text("Accounts").FontSize(32).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,20")

; Profile Header Card (Aesthetic profile card)
profileCard := accPage.Add("Border").CornerRadius("8").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("20").Margin("0,0,0,20")
profileGrid := profileCard.Add("Grid")
profileGrid.Cols("Auto", "*")

; Circular avatar using an Ellipse
avatarGroup := profileGrid.Add("Grid").Grid_Column(0).Margin("0,0,20,0")
avatarGroup.Add("Ellipse").Width(70).Height(70).Fill("{DynamicResource Accent}").VerticalAlignment("Center")
avatarGroup.Add("TextBlock").Text(Chr(0xE77B)).FontFamily("Segoe Fluent Icons").FontSize(32).Foreground("White").HorizontalAlignment("Center").VerticalAlignment("Center")

profileText := profileGrid.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
profileText.Add("TextBlock").Text("John Doe").FontSize(22).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}")
profileText.Add("TextBlock").Text("john.doe@outlook.com").FontSize(14).Foreground("{DynamicResource TextSub}").Margin("0,2,0,0")
profileText.Add("TextBlock").Text("Administrator").FontSize(12).Foreground("{DynamicResource TextSub}").FontStyle("Italic").Margin("0,2,0,0")

accPage.Add("TextBlock").Text("Account settings").FontSize(16).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,10,0,10")

AddSettingCard(accPage, Chr(0xE77B), "Your info", "Manage your local and Microsoft accounts, profile picture", "Chevron", "CardYourInfo")
AddSettingCard(accPage, Chr(0xE710), "Email & accounts", "Emails used by other apps, work/school accounts", "Chevron", "CardEmailAccs")
AddSettingCard(accPage, Chr(0xE6A7), "Sign-in options", "Windows Hello PIN, fingerprint, security keys, password", "Chevron", "CardSignInOpts")
AddSettingCard(accPage, Chr(0xE77A), "Family & other users", "Add family members, setup kiosk, guest accounts", "Chevron", "CardFamily")

; --- WINDOWS UPDATE PAGE ---
wuPage := CreatePageContainer(layout, "WindowsUpdate")
wuPage.Add("TextBlock").Text("Windows Update").FontSize(32).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,0,0,20")

; Update Status Card (Highly Dynamic!)
statusCard := wuPage.Add("Border").CornerRadius("8").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("20").Margin("0,0,0,20")
statusGrid := statusCard.Add("Grid")
statusGrid.Cols("Auto", "*", "Auto")

; Status Icon (Big checkmark/spinner)
statusGrid.Add("TextBlock").Name("WuStatusIcon").Text(Chr(0xE73E)).FontFamily("Segoe Fluent Icons").FontSize(36).Foreground("Green").Grid_Column(0).Margin("0,0,20,0").VerticalAlignment("Center")

statusTextSp := statusGrid.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
statusTextSp.Add("TextBlock").Name("WuStatusTitle").Text("You're up to date").FontSize(18).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}")
statusTextSp.Add("TextBlock").Name("WuStatusDesc").Text("Last checked: Today, 9:24 PM").FontSize(13).Foreground("{DynamicResource TextSub}").Margin("0,2,0,0")

; Progress Bar (For update checking simulation)
wuProgBdr := statusTextSp.Add("Border").Name("WuProgBdr").Margin("0,10,0,0").Visibility("Collapsed").Height(4).CornerRadius("2").Background("{DynamicResource ControlBorder}").ClipToBounds("True")
wuProgressBar := wuProgBdr.Add("ProgressBar").Name("WuProgBar").Minimum(0).Maximum(100).Value(0).Height(4).BorderThickness(0).Background("Transparent").Foreground("{DynamicResource Accent}")

statusGrid.Add("Button").Name("BtnCheckUpdates").Content("Check for updates").Grid_Column(2).Padding("15,8,15,8").FontWeight("SemiBold").Cursor("Hand")
    .On("Click", HandleCheckUpdates)

wuPage.Add("TextBlock").Text("More options").FontSize(16).FontWeight("SemiBold").Foreground("{DynamicResource TextMain}").Margin("0,10,0,10")

; Pause updates card
AddSettingComboCard(wuPage, Chr(0xE769), "Pause updates", "Temporarily pause installing new updates on this device", "ComboPauseUpdates", ["Pause for 1 week", "Pause for 2 weeks", "Pause for 3 weeks"])

AddSettingCard(wuPage, Chr(0xE74D), "Update history", "View KB updates and driver history installed on this device", "Chevron", "CardUpdateHistory")
AddSettingCard(wuPage, Chr(0xE115), "Advanced options", "Delivery optimization, optional updates, active hours", "Chevron", "CardWuAdvanced")


; ==============================================================================
; INITIALIZATION & ROUTING
; ==============================================================================
; Set initial page
Pages["System"].Visibility("Visible")

ui := app.Compile()
ui.Track("TxtCustomAccent")
ui.Track("TxtCustomBg")

; --- Apps Event Handlers ---
for appObj in AppList {
    ui.OnEvent("BtnUninstall_" appObj.Id, "Click", HandleUninstallApp.Bind(appObj))
}

; --- Accounts Event Handlers ---
ui.OnEvent("CardYourInfo", "MouseLeftButtonDown", (*) => XDialog.Show({ Title: "Your Info", Message: "User Account Profile:`n`nName: John Doe`nEmail: john.doe@outlook.com`nGroup: Administrators`nLocal Account: Yes", Icon: Chr(0xE77B), Buttons: ["OK"], Owner: ui.wpfHwnd, Theme: "Dark Mica (Win 11)" }))
ui.OnEvent("CardEmailAccs", "MouseLeftButtonDown", (*) => XDialog.Show({ Title: "Email & accounts", Message: "Accounts used by other apps:`n`n1. john.doe@outlook.com (Microsoft Account)`n2. work.jdoe@company.com (Work Account)", Icon: Chr(0xE710), Buttons: ["OK"], Owner: ui.wpfHwnd, Theme: "Dark Mica (Win 11)" }))
ui.OnEvent("CardSignInOpts", "MouseLeftButtonDown", (*) => XDialog.Show({ Title: "Sign-in options", Message: "Available Sign-in Options:`n`n- Windows Hello Fingerprint (Configured)`n- Windows Hello PIN (Configured)`n- Password (Configured)", Icon: Chr(0xE6A7), Buttons: ["OK"], Owner: ui.wpfHwnd, Theme: "Dark Mica (Win 11)" }))
ui.OnEvent("CardFamily", "MouseLeftButtonDown", (*) => XDialog.Show({ Title: "Family & other users", Message: "Family Group members:`n`n- Jane Doe (Child - Screen time: 2 hrs)`n- Little Timmy (Child - Screen time: 1 hr)", Icon: Chr(0xE77A), Buttons: ["OK"], Owner: ui.wpfHwnd, Theme: "Dark Mica (Win 11)" }))

; --- Windows Update Event Handlers ---
ui.OnEvent("ComboPauseUpdates", "SelectionChanged", HandlePauseUpdates)
ui.OnEvent("CardUpdateHistory", "MouseLeftButtonDown", (*) => XDialog.Show({ Title: "Update history", Message: "Update history on this device:`n`n1. 2026-05 Security Update for Windows 11 (KB5037771) - Installed on 5/14/2026`n2. 2026-05 Cumulative Update for .NET Framework 3.5 and 4.8.1 (KB5037591) - Installed on 5/13/2026`n3. Windows Malicious Software Removal Tool x64 (KB890830) - Installed on 5/13/2026`n4. Realtek Semiconductor Corp. - Extension - 1.0.0.3 - Installed on 5/10/2026", Icon: Chr(0xE74D), Buttons: ["OK"], Owner: ui.wpfHwnd, Theme: "Dark Mica (Win 11)" }))
ui.OnEvent("CardWuAdvanced", "MouseLeftButtonDown", (*) => XDialog.Show({ Title: "Advanced options", Message: "Advanced Update settings configured by policy:`n`n- Receive updates for other Microsoft products: On`n- Get me up to date: Restart as soon as possible: Off`n- Download updates over metered connections: Off`n- Active hours: Automatic (8:00 AM to 5:00 PM)", Icon: Chr(0xE115), Buttons: ["OK"], Owner: ui.wpfHwnd, Theme: "Dark Mica (Win 11)" }))


; Event Handlers for Navigation
for id in NavItems {
    ui.OnEvent("Nav_" id, "MouseLeftButtonDown", ObjBindMethod(AppRouter, "SwitchPage", id))
}

; Event Handlers for Themes and Customizations
for themeName in ThemeTiles {
    ui.OnEvent("Tile_" A_Index, "MouseLeftButtonDown", HandleTileClick.Bind(themeName))
}

ui.OnEvent("ComboThemesList", "SelectionChanged", HandleThemeSelection)
ui.OnEvent("TglTransparency", "Checked", (*) => HandleTransparency(true))
ui.OnEvent("TglTransparency", "Unchecked", (*) => HandleTransparency(false))
ui.OnEvent("ComboBlurEffect", "SelectionChanged", HandleBlurEffect)
ui.OnEvent("SldRounding", "ValueChanged", HandleRounding)
ui.OnEvent("SldOpacity", "ValueChanged", HandleOpacity)

; Accent colors
for item in AccentColors {
    ui.OnEvent("Accent_" item.Id, "MouseLeftButtonDown", HandleAccent.Bind(item.Color))
}
ui.OnEvent("BtnCustomAccent", "Click", HandleCustomAccent)
ui.OnEvent("BtnCustomAccent_Pick", "Click", HandleCustomAccentPick)

; Tint colors
for item in TintColors {
    ui.OnEvent("Tint_" item.Id, "MouseLeftButtonDown", HandleTint.Bind(item.Color))
}
ui.OnEvent("BtnCustomBg", "Click", HandleCustomBg)
ui.OnEvent("BtnCustomBg_Pick", "Click", HandleCustomBgPick)

; Listen to Loaded to apply initial theme settings after window shows
ui.OnEvent("Window", "Loaded", HandleWindowLoaded)

class AppRouter {
    static CurrentPage := "System"
    
    static SwitchPage(targetId, state, ctrl, event) {
        if (targetId == this.CurrentPage || !Pages.Has(targetId))
            return
            
        ; Update visibility
        for id, page in Pages {
            ui.Update("Page_" id, "Visibility", (id == targetId) ? "Visible" : "Collapsed")
        }
        
        ; Update sidebar visual state
        for id in NavItems {
            isSelected := (id == targetId)
            bg := isSelected ? "{DynamicResource Accent}" : "Transparent"
            fg := isSelected ? "White" : "{DynamicResource TextMain}"
            op := isSelected ? "1.0" : "0.7"
            
            ui.Update("Nav_" id, "Background", bg)
            ui.Update("NavIcon_" id, "Foreground", fg)
            ui.Update("NavText_" id, "Foreground", fg)
            ui.Update("NavText_" id, "Opacity", op)
        }
        
        this.CurrentPage := targetId
    }
}

; ==============================================================================
; INTERACTIVITY EVENT HANDLERS
; ==============================================================================
ui.OnEvent("TglNightLight", "Checked", (*) => HandleNightLight("True"))
ui.OnEvent("TglNightLight", "Unchecked", (*) => HandleNightLight("False"))
HandleNightLight(val) {
    AppState.NightLight := (val == "True")
    XDialog.Show({ Title: "Night Light", Message: "Night light is now " (AppState.NightLight ? "On" : "Off"), Icon: Chr(0xE793), Buttons: ["OK"], Owner: ui.wpfHwnd, Theme: "Dark Mica (Win 11)" })
}

ui.OnEvent("SldBrightness", "ValueChanged", HandleBrightness)
HandleBrightness(state, *) {
    val := Round(Number(state["SldBrightness"]))
    AppState.Brightness := val
    ui.Update("SldBrightness_Val", "Text", String(val))
}

ui.OnEvent("SldVolume", "ValueChanged", HandleVolume)
HandleVolume(state, *) {
    val := Round(Number(state["SldVolume"]))
    AppState.Volume := val
    ui.Update("SldVolume_Val", "Text", String(val))
}

ui.OnEvent("BtnAddDevice", "Click", (*) => HandleAddDevice())
ui.OnEvent("BtnAddBluetooth", "Click", (*) => HandleAddDevice())
HandleAddDevice() {
    XDialog.Show({ Title: "Add Device", Message: "Searching for nearby devices...", Icon: Chr(0xE710), Buttons: ["Cancel"], Owner: ui.wpfHwnd, Theme: "Dark Mica (Win 11)" })
}

ui.OnEvent("TglBluetooth", "Checked", (*) => HandleBluetooth("True"))
ui.OnEvent("TglBluetooth", "Unchecked", (*) => HandleBluetooth("False"))
HandleBluetooth(val) {
    AppState.Bluetooth := (val == "True")
    ui.Update("BtList", "Visibility", AppState.Bluetooth ? "Visible" : "Collapsed")
    ui.Update("BtOffMsg", "Visibility", AppState.Bluetooth ? "Collapsed" : "Visible")
}

ui.OnEvent("TglWifi", "Checked", (*) => HandleWifi("True"))
ui.OnEvent("TglWifi", "Unchecked", (*) => HandleWifi("False"))
HandleWifi(val) {
    AppState.Wifi := (val == "True")
    ui.Update("WifiList", "Visibility", AppState.Wifi ? "Visible" : "Collapsed")
    ui.Update("WifiOffMsg", "Visibility", AppState.Wifi ? "Collapsed" : "Visible")
}

ui.OnEvent("TglDarkMode", "Checked", (*) => HandleDarkModeSetting(true))
ui.OnEvent("TglDarkMode", "Unchecked", (*) => HandleDarkModeSetting(false))

; ==============================================================================
; PERSONALIZATION HELPER FUNCTIONS & EVENT HANDLERS
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

CreateThemeTile(parent, themeName, index) {
    themeMap := ThemeDefinitions[themeName]
    bgColor := themeMap.Has("Resource_BgColor") ? themeMap["Resource_BgColor"] : "#1E1E1E"
    sidebarColor := themeMap.Has("Resource_SidebarColor") ? themeMap["Resource_SidebarColor"] : "#10000000"
    accentColor := themeMap.Has("Resource_Accent") ? themeMap["Resource_Accent"] : "#0078D7"
    textColor := themeMap.Has("Resource_TextMain") ? themeMap["Resource_TextMain"] : "#FFFFFF"
    
    tileBorder := parent.Add("Border").Name("Tile_" index).Width(150).Height(110).CornerRadius("8").Background(bgColor).BorderBrush("{DynamicResource ControlBorder}").BorderThickness("2").Margin("5").Cursor("Hand")
    
    tileLayout := tileBorder.Add("Grid")
    tileLayout.Rows("*", "Auto")
    
    ; Preview container
    previewArea := tileLayout.Add("Grid").Grid_Row(0).Margin("4,4,4,0")
    previewArea.Cols("40", "*")
    
    ; Sidebar preview
    previewArea.Add("Border").Grid_Column(0).Background(sidebarColor).CornerRadius("4,0,0,4").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("0,0,1,0")
    
    ; Content preview
    contentArea := previewArea.Add("Grid").Grid_Column(1).Margin("5")
    contentArea.Rows("Auto", "*")
    
    ; Tiny title bar
    contentArea.Add("Border").Grid_Row(0).Background(accentColor).Height(4).CornerRadius("2").Width(30).HorizontalAlignment("Left")
    
    ; Tiny card
    tinyCard := contentArea.Add("Border").Grid_Row(1).Background("{DynamicResource ControlBg}").Height(25).CornerRadius("3").Margin("0,5,0,0").Padding("4")
    tinyCardGrid := tinyCard.Add("Grid")
    tinyCardGrid.Cols("Auto", "*")
    tinyCardGrid.Add("Ellipse").Width(8).Height(8).Fill(accentColor).VerticalAlignment("Center").Grid_Column(0).Margin("0,0,5,0")
    tinyCardGrid.Add("Border").Height(3).Background(textColor).Width(25).CornerRadius("1.5").VerticalAlignment("Center").Grid_Column(1).HorizontalAlignment("Left")
    
    ; Theme Label
    labelBorder := tileLayout.Add("Border").Grid_Row(1).Background("#90000000").Padding("5,4,5,4").CornerRadius("0,0,6,6")
    labelBorder.Add("TextBlock").Text(themeName).FontSize(11).Foreground("White").FontWeight("SemiBold").HorizontalAlignment("Center").TextTrimming("CharacterEllipsis")
    
    return tileBorder
}

AddSettingComboCard(parent, icon, title, desc, name, itemsList) {
    card := parent.Add("Border").Name("Card_" name).CornerRadius("8").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("15,10,15,10").Margin("0,0,0,10")
    grid := card.Add("Grid")
    grid.Cols("Auto", "*", "Auto")
    grid.Add("TextBlock").Text(icon).FontFamily("Segoe Fluent Icons").FontSize(18).Foreground("{DynamicResource TextMain}").Grid_Column(0).Margin("0,0,15,0").VerticalAlignment("Center")
    
    texts := grid.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
    texts.Add("TextBlock").Text(title).FontSize(14).Foreground("{DynamicResource TextMain}")
    if (desc != "")
        texts.Add("TextBlock").Text(desc).FontSize(12).Foreground("{DynamicResource TextSub}").Margin("0,2,0,0")
        
    ctrlArea := grid.Add("StackPanel").Grid_Column(2).VerticalAlignment("Center").Orientation("Horizontal")
    combo := ctrlArea.Add("ComboBox").Name(name).Width(150).Height(30)
    for item in itemsList {
        combo.Add("ComboBoxItem").Content(item)
    }
    return card
}

AddColorPaletteCard(parent, icon, title, desc, namePrefix, colorsList) {
    card := parent.Add("Border").Name("Card_" namePrefix).CornerRadius("8").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("15,10,15,10").Margin("0,0,0,10")
    grid := card.Add("Grid")
    grid.Cols("Auto", "*", "Auto")
    grid.Add("TextBlock").Text(icon).FontFamily("Segoe Fluent Icons").FontSize(18).Foreground("{DynamicResource TextMain}").Grid_Column(0).Margin("0,0,15,0").VerticalAlignment("Center")
    
    texts := grid.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
    texts.Add("TextBlock").Text(title).FontSize(14).Foreground("{DynamicResource TextMain}")
    if (desc != "")
        texts.Add("TextBlock").Text(desc).FontSize(12).Foreground("{DynamicResource TextSub}").Margin("0,2,0,0")
        
    ctrlArea := grid.Add("StackPanel").Grid_Column(2).VerticalAlignment("Center").Orientation("Horizontal")
    for item in colorsList {
        circle := ctrlArea.Add("Border").Name(namePrefix "_" item.Id).Width(24).Height(24).CornerRadius("12").Background(item.Color).Margin("5,0,5,0").Cursor("Hand").BorderThickness(1).BorderBrush("{DynamicResource ControlBorder}")
        circle.ToolTip(item.Name)
    }
    return card
}

AddSettingTextBoxCard(parent, icon, title, desc, name, btnName, defaultValue) {
    card := parent.Add("Border").Name("Card_" name).CornerRadius("8").Background("{DynamicResource DropdownBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Padding("15,10,15,10").Margin("0,0,0,10")
    grid := card.Add("Grid")
    grid.Cols("Auto", "*", "Auto")
    grid.Add("TextBlock").Text(icon).FontFamily("Segoe Fluent Icons").FontSize(18).Foreground("{DynamicResource TextMain}").Grid_Column(0).Margin("0,0,15,0").VerticalAlignment("Center")
    
    texts := grid.Add("StackPanel").Grid_Column(1).VerticalAlignment("Center")
    texts.Add("TextBlock").Text(title).FontSize(14).Foreground("{DynamicResource TextMain}")
    if (desc != "")
        texts.Add("TextBlock").Text(desc).FontSize(12).Foreground("{DynamicResource TextSub}").Margin("0,2,0,0")
        
    ctrlArea := grid.Add("StackPanel").Grid_Column(2).VerticalAlignment("Center").Orientation("Horizontal")
    
    ; Wrap TextBox inside a Border to support rounded corners gracefully
    tbBorder := ctrlArea.Add("Border").Width(100).Height(30).CornerRadius("4").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1").Background("{DynamicResource DropdownBg}").Margin("0,0,10,0").Padding("5,1,5,1")
    tbBorder.Add("TextBox").Name(name).Text(defaultValue).Background("Transparent").Foreground("{DynamicResource TextMain}").BorderThickness("0").VerticalAlignment("Center")
    
    ctrlArea.Add("Button").Name(btnName "_Pick").Content(Chr(0xEF3C)).FontFamily("Segoe Fluent Icons").FontSize(14).Width(32).Height(30).VerticalAlignment("Center").Margin("0,0,10,0").Cursor("Hand").BorderThickness("1").BorderBrush("{DynamicResource ControlBorder}").Background(defaultValue).Foreground(GetContrastingColor(defaultValue))
    ctrlArea.Add("Button").Name(btnName).Content("Apply").Padding("12,5,12,5").Cursor("Hand").Background("{DynamicResource ControlBg}").BorderBrush("{DynamicResource ControlBorder}").BorderThickness("1")
    return card
}

ApplyTheme(themeName) {
    if !ThemeDefinitions.Has(themeName)
        return
        
    themeMap := ThemeDefinitions[themeName]
    
    ; Apply TitleBar defaults first so switching themes works cleanly
    titleBarColor := themeMap.Has("Resource_TitleBarColor") ? themeMap["Resource_TitleBarColor"] : "Transparent"
    titleBarForeground := themeMap.Has("Resource_TitleBarForeground") ? themeMap["Resource_TitleBarForeground"] : (themeMap.Has("Resource_TextMain") ? themeMap["Resource_TextMain"] : "#000000")
    ui.Update("Resource", "TitleBarColor", titleBarColor)
    ui.Update("Resource", "TitleBarForeground", titleBarForeground)

    ; Apply all parameters of this theme
    for key, val in themeMap {
        if (key == "Window_DWM") {
            ui.Update("Window", "DWM", val)
            dwmParts := StrSplit(val, ",")
            if (dwmParts.Length == 2) {
                effect := Integer(dwmParts[1])
                mode := Integer(dwmParts[2])
                
                PersState.Transparency := (effect > 0)
                PersState.BlurEffect := (effect == 2) ? "Mica" : ((effect == 3) ? "Acrylic" : ((effect == 1) ? "Aero" : "Solid"))
                PersState.DarkMode := (mode == 1)
                
                ui.Update("TglTransparency", "IsChecked", PersState.Transparency ? "True" : "False")
                ui.Update("ComboBlurEffect", "SelectedIndex", (effect == 2) ? "0" : ((effect == 3) ? "1" : "2"))
                ui.Update("TglDarkMode", "IsChecked", PersState.DarkMode ? "True" : "False")
            }
        } else if (InStr(key, "Resource_") == 1) {
            resName := SubStr(key, 10)
            ui.Update("Resource", resName, val)
            
            if (resName == "WindowRadius") {
                radiusVal := 12
                if RegExMatch(val, "\d+", &m) {
                    radiusVal := Integer(m[0])
                }
                PersState.Rounding := radiusVal
                ui.Update("SldRounding", "Value", String(radiusVal))
                ui.Update("SldRounding_Val", "Text", String(radiusVal))
            } else if (resName == "BgColor") {
                hexColor := val
                if (SubStr(hexColor, 1, 1) == "#" && StrLen(hexColor) >= 9) {
                    alphaHex := SubStr(hexColor, 2, 2)
                    rgbHex := SubStr(hexColor, 4)
                    
                    alphaVal := Round((Integer("0x" alphaHex) / 255) * 100)
                    PersState.Opacity := alphaVal
                    PersState.BgTint := "#" rgbHex
                    
                    ui.Update("SldOpacity", "Value", String(alphaVal))
                    ui.Update("SldOpacity_Val", "Text", String(alphaVal) "%")
                    ui.Update("TxtCustomBg", "Text", "#" rgbHex)
                }
            } else if (resName == "Accent") {
                PersState.Accent := val
                ui.Update("TxtCustomAccent", "Text", val)
            }
        }
    }
    
    ; Update Custom Pick Buttons
    ui.Update("BtnCustomAccent_Pick", "Background", PersState.Accent)
    ui.Update("BtnCustomAccent_Pick", "Foreground", GetContrastingColor(PersState.Accent))
    ui.Update("BtnCustomBg_Pick", "Background", PersState.BgTint)
    ui.Update("BtnCustomBg_Pick", "Foreground", GetContrastingColor(PersState.BgTint))
}

RecomputeTheme() {
    effectNum := 0
    if (PersState.Transparency) {
        if (PersState.BlurEffect == "Mica")
            effectNum := 2
        else if (PersState.BlurEffect == "Acrylic")
            effectNum := 3
        else if (PersState.BlurEffect == "Aero")
            effectNum := 1
    }
    modeNum := PersState.DarkMode ? 1 : 0
    ui.Update("Window", "DWM", effectNum "," modeNum)
    
    alphaByte := Round((PersState.Opacity / 100) * 255)
    alphaHex := Format("{:02X}", alphaByte)
    
    bgColorHex := "#" alphaHex SubStr(PersState.BgTint, 2)
    ui.Update("Resource", "BgColor", bgColorHex)
    
    ui.Update("Resource", "WindowRadius", "CornerRadius:" PersState.Rounding)
    ui.Update("Resource", "Accent", PersState.Accent)
    
    sidebarAlpha := PersState.DarkMode ? "30" : "50"
    sidebarColorHex := "#" sidebarAlpha (PersState.DarkMode ? "000000" : "FFFFFF")
    ui.Update("Resource", "SidebarColor", sidebarColorHex)
    
    if (PersState.DarkMode) {
        ui.Update("Resource", "TextMain", "#FFFFFF")
        ui.Update("Resource", "TextSub", "#AAAAAA")
        ui.Update("Resource", "ControlBg", "#15FFFFFF")
        ui.Update("Resource", "ControlBorder", "#20FFFFFF")
        ui.Update("Resource", "DropdownBg", "#1E1E1E")
    } else {
        ui.Update("Resource", "TextMain", "#111111")
        ui.Update("Resource", "TextSub", "#444444")
        ui.Update("Resource", "ControlBg", "#80FFFFFF")
        ui.Update("Resource", "ControlBorder", "#40000000")
        ui.Update("Resource", "DropdownBg", "#FAFAFA")
    }
    
    ; Update Custom Pick Buttons
    ui.Update("BtnCustomAccent_Pick", "Background", PersState.Accent)
    ui.Update("BtnCustomAccent_Pick", "Foreground", GetContrastingColor(PersState.Accent))
    ui.Update("BtnCustomBg_Pick", "Background", PersState.BgTint)
    ui.Update("BtnCustomBg_Pick", "Foreground", GetContrastingColor(PersState.BgTint))
}

GetContrastingColor(hex) {
    r := 128, g := 128, b := 128
    cleanHex := hex
    if (SubStr(cleanHex, 1, 1) == "#")
        cleanHex := SubStr(cleanHex, 2)
    cleanHex := Trim(cleanHex)
    try {
        if (StrLen(cleanHex) == 3) {
            r := Integer("0x" SubStr(cleanHex, 1, 1) SubStr(cleanHex, 1, 1))
            g := Integer("0x" SubStr(cleanHex, 2, 1) SubStr(cleanHex, 2, 1))
            b := Integer("0x" SubStr(cleanHex, 3, 1) SubStr(cleanHex, 3, 1))
        } else if (StrLen(cleanHex) >= 6) {
            r := Integer("0x" SubStr(cleanHex, 1, 2))
            g := Integer("0x" SubStr(cleanHex, 3, 2))
            b := Integer("0x" SubStr(cleanHex, 5, 2))
        }
    }
    brightness := (r * 299 + g * 587 + b * 114) / 1000
    return (brightness > 128) ? "#000000" : "#FFFFFF"
}

HandleWindowLoaded(state, ctrl, event) {
    ApplyTheme("Dark Mica (Win 11)")
}

HandleTileClick(themeName, state, ctrl, event) {
    ApplyTheme(themeName)
    for index, name in ThemeNames {
        if (name == themeName) {
            ui.Update("ComboThemesList", "SelectedIndex", String(index - 1))
            break
        }
    }
}

HandleThemeSelection(state, *) {
    if !state.Has("ComboThemesList")
        return
    themeName := state["ComboThemesList"]
    ApplyTheme(themeName)
}

HandleDarkModeSetting(isDark) {
    AppState.DarkMode := isDark
    PersState.DarkMode := isDark
    RecomputeTheme()
}

HandleTransparency(enabled) {
    PersState.Transparency := enabled
    RecomputeTheme()
}

HandleBlurEffect(state, *) {
    if !state.Has("ComboBlurEffect")
        return
    selected := state["ComboBlurEffect"]
    if (selected == "Mica (High Fidelity)")
        PersState.BlurEffect := "Mica"
    else if (selected == "Acrylic (Frosted Glass)")
        PersState.BlurEffect := "Acrylic"
    else if (selected == "Aero (Classic Glass)")
        PersState.BlurEffect := "Aero"
    RecomputeTheme()
}

HandleRounding(state, *) {
    val := Round(Number(state["SldRounding"]))
    PersState.Rounding := val
    ui.Update("SldRounding_Val", "Text", String(val))
    RecomputeTheme()
}

HandleOpacity(state, *) {
    val := Round(Number(state["SldOpacity"]))
    PersState.Opacity := val
    ui.Update("SldOpacity_Val", "Text", String(val) "%")
    RecomputeTheme()
}

HandleAccent(color, *) {
    PersState.Accent := color
    ui.Update("TxtCustomAccent", "Text", color)
    RecomputeTheme()
}

HandleCustomAccent(state, *) {
    hex := state["TxtCustomAccent"]
    if (SubStr(hex, 1, 1) != "#" || StrLen(hex) != 7) {
        XDialog.Show({ Title: "Invalid Color", Message: "Please enter a valid hex color starting with # (e.g. #FF0055).", Icon: Chr(0xE7BA), Buttons: ["OK"], Owner: ui.wpfHwnd })
        return
    }
    PersState.Accent := hex
    RecomputeTheme()
}

HandleTint(color, *) {
    PersState.BgTint := color
    ui.Update("TxtCustomBg", "Text", color)
    RecomputeTheme()
}

HandleCustomBg(state, *) {
    hex := state["TxtCustomBg"]
    if (SubStr(hex, 1, 1) != "#" || StrLen(hex) != 7) {
        XDialog.Show({ Title: "Invalid Color", Message: "Please enter a valid hex color starting with # (e.g. #1E1E1E).", Icon: Chr(0xE7BA), Buttons: ["OK"], Owner: ui.wpfHwnd })
        return
    }
    PersState.BgTint := hex
    RecomputeTheme()
}

HandleAppSearch(state, *) {
    if !state.Has("TxtSearchApps")
        return
        
    query := state["TxtSearchApps"]
    
    for appObj in AppList {
        isMatch := (query == "" || InStr(appObj.Name, query) || InStr(appObj.Publisher, query))
        ui.Update("Card_App_" appObj.Id, "Visibility", isMatch ? "Visible" : "Collapsed")
    }
}

HandleUninstallApp(appObj, state, *) {
    res := XDialog.Show({
        Title: "Uninstall " appObj.Name,
        Message: "This app and its related info will be uninstalled.",
        Icon: appObj.Icon,
        Buttons: ["Uninstall", "Cancel"],
        Owner: ui.wpfHwnd,
        Theme: "Dark Mica (Win 11)",
        Modal: true,
        DarkenOwner: true
    })
    
    if (res.Button == "Uninstall") {
        ui.Update("Card_App_" appObj.Id, "Visibility", "Collapsed")
        
        for index, item in AppList {
            if (item.Id == appObj.Id) {
                AppList.RemoveAt(index)
                break
            }
        }
        
        XDialog.Show({
            Title: "Uninstall complete",
            Message: appObj.Name " was successfully uninstalled.",
            Icon: Chr(0xE73E),
            Buttons: ["OK"],
            Owner: ui.wpfHwnd,
            Theme: "Dark Mica (Win 11)"
        })
    }
}

global UpdateProgressVal := 0

HandleCheckUpdates(state, *) {
    global UpdateProgressVal
    UpdateProgressVal := 0
    
    ui.Update("BtnCheckUpdates", "IsEnabled", "False")
    
    ui.Update("WuStatusTitle", "Text", "Checking for updates...")
    ui.Update("WuStatusDesc", "Text", "Contacting update servers...")
    ui.Update("WuStatusIcon", "Text", Chr(0xE895)) ; Sync icon
    ui.Update("WuStatusIcon", "Foreground", "{DynamicResource Accent}")
    
    ui.Update("WuProgBdr", "Visibility", "Visible")
    ui.Update("WuProgBar", "Value", "0")
    
    SetTimer(SimulateUpdateProgress, 100)
}

SimulateUpdateProgress() {
    global UpdateProgressVal
    if (UpdateProgressVal >= 100) {
        SetTimer(SimulateUpdateProgress, 0)
        FinishUpdateCheck()
        return
    }
    
    RandomVal := Random(3, 12)
    UpdateProgressVal += RandomVal
    if (UpdateProgressVal > 100) {
        UpdateProgressVal := 100
    }
    
    ui.Update("WuProgBar", "Value", String(UpdateProgressVal))
    
    if (UpdateProgressVal < 30) {
        ui.Update("WuStatusDesc", "Text", "Checking for Windows security updates (" String(UpdateProgressVal) "%)...")
    } else if (UpdateProgressVal < 60) {
        ui.Update("WuStatusDesc", "Text", "Checking for .NET Framework updates (" String(UpdateProgressVal) "%)...")
    } else if (UpdateProgressVal < 90) {
        ui.Update("WuStatusDesc", "Text", "Checking for driver updates (" String(UpdateProgressVal) "%)...")
    } else {
        ui.Update("WuStatusDesc", "Text", "Finalizing update checks (" String(UpdateProgressVal) "%)...")
    }
}

FinishUpdateCheck() {
    ui.Update("WuStatusTitle", "Text", "You're up to date")
    
    timeStr := FormatTime(, "h:mm tt")
    ui.Update("WuStatusDesc", "Text", "Last checked: Today, " timeStr)
    
    ui.Update("WuStatusIcon", "Text", Chr(0xE73E)) ; Checkmark
    ui.Update("WuStatusIcon", "Foreground", "Green")
    
    ui.Update("WuProgBdr", "Visibility", "Collapsed")
    
    ui.Update("BtnCheckUpdates", "IsEnabled", "True")
    
    XDialog.Show({
        Title: "Windows Update",
        Message: "All updates are successfully installed! Your PC is running the latest version of Windows 11.",
        Icon: Chr(0xE73E),
        Buttons: ["OK"],
        Owner: ui.wpfHwnd,
        Theme: "Dark Mica (Win 11)"
    })
}

HandlePauseUpdates(state, *) {
    if !state.Has("ComboPauseUpdates")
        return
    
    selectedText := state["ComboPauseUpdates"]
    if (selectedText == "")
        return
        
    weeks := 1
    if (selectedText == "Pause for 2 weeks")
        weeks := 2
    else if (selectedText == "Pause for 3 weeks")
        weeks := 3
        
    days := weeks * 7
    resumeDate := DateAdd(A_Now, days, "days")
    resumeDateStr := FormatTime(resumeDate, "MMMM d, yyyy")
    
    ui.Update("WuStatusTitle", "Text", "Updates paused")
    ui.Update("WuStatusDesc", "Text", "Updates will resume on " resumeDateStr)
    ui.Update("WuStatusIcon", "Text", Chr(0xE769)) ; Pause icon
    ui.Update("WuStatusIcon", "Foreground", "Gold")
    
    XDialog.Show({
        Title: "Updates Paused",
        Message: "Windows Update has been paused for " weeks " week(s).`n`nAutomatic updates will resume on " resumeDateStr ". You can resume updates manually at any time by clicking 'Check for updates'.",
        Icon: Chr(0xE769),
        Buttons: ["OK"],
        Owner: ui.wpfHwnd,
        Theme: "Dark Mica (Win 11)"
    })
}

HandleCustomAccentPick(state, *) {
    originalHex := PersState.Accent
    currentHex := state.Has("TxtCustomAccent") ? state["TxtCustomAccent"] : PersState.Accent
    if (SubStr(currentHex, 1, 1) != "#" || (StrLen(currentHex) != 4 && StrLen(currentHex) != 7))
        currentHex := PersState.Accent
    newHex := ShowColorPicker("Pick Accent Color", currentHex, ui.wpfHwnd, "Accent")
    if (newHex != "") {
        ui.Update("TxtCustomAccent", "Text", newHex)
        PersState.Accent := newHex
        RecomputeTheme()
    } else {
        ui.Update("TxtCustomAccent", "Text", originalHex)
        PersState.Accent := originalHex
        RecomputeTheme()
    }
}

HandleCustomBgPick(state, *) {
    originalHex := PersState.BgTint
    currentHex := state.Has("TxtCustomBg") ? state["TxtCustomBg"] : PersState.BgTint
    if (SubStr(currentHex, 1, 1) != "#" || (StrLen(currentHex) != 4 && StrLen(currentHex) != 7))
        currentHex := PersState.BgTint
    newHex := ShowColorPicker("Pick Background Tint", currentHex, ui.wpfHwnd, "Bg")
    if (newHex != "") {
        ui.Update("TxtCustomBg", "Text", newHex)
        PersState.BgTint := newHex
        RecomputeTheme()
    } else {
        ui.Update("TxtCustomBg", "Text", originalHex)
        PersState.BgTint := originalHex
        RecomputeTheme()
    }
}

global SelectedPickerColor := ""
global PickerResponse := ""
global colorPickerUi := ""
global ActiveColorType := ""

ShowColorPicker(title, initialHex, ownerHwnd, colorType := "") {
    global SelectedPickerColor, PickerResponse, colorPickerUi, ActiveColorType
    
    SelectedPickerColor := initialHex
    PickerResponse := ""
    ActiveColorType := colorType
    
    ; Parse initial Hex to R, G, B
    r := 128, g := 128, b := 128
    cleanHex := Trim(initialHex)
    if (SubStr(cleanHex, 1, 1) == "#")
        cleanHex := SubStr(cleanHex, 2)
    try {
        if (StrLen(cleanHex) == 3) {
            r := Integer("0x" SubStr(cleanHex, 1, 1) SubStr(cleanHex, 1, 1))
            g := Integer("0x" SubStr(cleanHex, 2, 1) SubStr(cleanHex, 2, 1))
            b := Integer("0x" SubStr(cleanHex, 3, 1) SubStr(cleanHex, 3, 1))
        } else if (StrLen(cleanHex) >= 6) {
            r := Integer("0x" SubStr(cleanHex, 1, 2))
            g := Integer("0x" SubStr(cleanHex, 3, 2))
            b := Integer("0x" SubStr(cleanHex, 5, 2))
        }
    }
    
    ; Define beautiful XAML layout for the Color Picker dialog
    xaml := '
    (
    <Border CornerRadius="8" Background="{DynamicResource DropdownBg}" BorderBrush="{DynamicResource ControlBorder}" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="40"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            
            <!-- Draggable Titlebar -->
            <Grid Grid.Row="0" Name="DragArea" Background="Transparent">
                <TextBlock Text="%title%" Foreground="{DynamicResource TextMain}" FontSize="12" FontWeight="SemiBold" VerticalAlignment="Center" Margin="15,0,0,0"/>
                <Button Name="BtnClose" Style="{StaticResource CloseButtonStyle}" Width="45" HorizontalAlignment="Right" WindowChrome.IsHitTestVisibleInChrome="True">
                    <TextBlock Text="&#xE8BB;" FontFamily="Segoe Fluent Icons" FontSize="10" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                </Button>
            </Grid>
            
            <!-- Preview Box -->
            <Border Grid.Row="1" Margin="20,10,20,15" Height="100" CornerRadius="6" Name="ColorPreview" Background="%initialHex%" BorderBrush="{DynamicResource ControlBorder}" BorderThickness="1">
                <TextBlock Name="ColorPreviewText" Text="%initialHex%" Foreground="White" FontSize="18" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center">
                    <TextBlock.Effect>
                        <DropShadowEffect BlurRadius="4" ShadowDepth="1" Opacity="0.8" Color="Black"/>
                    </TextBlock.Effect>
                </TextBlock>
            </Border>
            
            <!-- Sliders and Presets -->
            <StackPanel Grid.Row="2" Margin="20,0,20,15">
                <!-- Red Slider -->
                <Grid Margin="0,0,0,12">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="20"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="35"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="0" Text="R" Foreground="Red" FontWeight="Bold" VerticalAlignment="Center"/>
                    <Slider Grid.Column="1" Name="SldR" Minimum="0" Maximum="255" Value="%r%" Margin="10,0,10,0" VerticalAlignment="Center"/>
                    <TextBlock Grid.Column="2" Name="ValR" Text="%r%" Foreground="{DynamicResource TextSub}" TextAlignment="Right" VerticalAlignment="Center"/>
                </Grid>
                
                <!-- Green Slider -->
                <Grid Margin="0,0,0,12">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="20"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="35"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="0" Text="G" Foreground="Green" FontWeight="Bold" VerticalAlignment="Center"/>
                    <Slider Grid.Column="1" Name="SldG" Minimum="0" Maximum="255" Value="%g%" Margin="10,0,10,0" VerticalAlignment="Center"/>
                    <TextBlock Grid.Column="2" Name="ValG" Text="%g%" Foreground="{DynamicResource TextSub}" TextAlignment="Right" VerticalAlignment="Center"/>
                </Grid>
                
                <!-- Blue Slider -->
                <Grid Margin="0,0,0,15">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="20"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="35"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="0" Text="B" Foreground="Blue" FontWeight="Bold" VerticalAlignment="Center"/>
                    <Slider Grid.Column="1" Name="SldB" Minimum="0" Maximum="255" Value="%b%" Margin="10,0,10,0" VerticalAlignment="Center"/>
                    <TextBlock Grid.Column="2" Name="ValB" Text="%b%" Foreground="{DynamicResource TextSub}" TextAlignment="Right" VerticalAlignment="Center"/>
                </Grid>
                
                <!-- Presets Title -->
                <TextBlock Text="Presets" FontSize="12" FontWeight="SemiBold" Foreground="{DynamicResource TextMain}" Margin="0,0,0,8"/>
                
                <!-- Presets Grid -->
                <UniformGrid Columns="6" Rows="2" Height="65">
                    <Border Name="P1" Background="#FF3B30" Width="24" Height="24" CornerRadius="12" Margin="3" Cursor="Hand" BorderThickness="1" BorderBrush="{DynamicResource ControlBorder}"/>
                    <Border Name="P2" Background="#FF9500" Width="24" Height="24" CornerRadius="12" Margin="3" Cursor="Hand" BorderThickness="1" BorderBrush="{DynamicResource ControlBorder}"/>
                    <Border Name="P3" Background="#FFCC00" Width="24" Height="24" CornerRadius="12" Margin="3" Cursor="Hand" BorderThickness="1" BorderBrush="{DynamicResource ControlBorder}"/>
                    <Border Name="P4" Background="#34C759" Width="24" Height="24" CornerRadius="12" Margin="3" Cursor="Hand" BorderThickness="1" BorderBrush="{DynamicResource ControlBorder}"/>
                    <Border Name="P5" Background="#5AC8FA" Width="24" Height="24" CornerRadius="12" Margin="3" Cursor="Hand" BorderThickness="1" BorderBrush="{DynamicResource ControlBorder}"/>
                    <Border Name="P6" Background="#007AFF" Width="24" Height="24" CornerRadius="12" Margin="3" Cursor="Hand" BorderThickness="1" BorderBrush="{DynamicResource ControlBorder}"/>
                    <Border Name="P7" Background="#5856D6" Width="24" Height="24" CornerRadius="12" Margin="3" Cursor="Hand" BorderThickness="1" BorderBrush="{DynamicResource ControlBorder}"/>
                    <Border Name="P8" Background="#FF2D55" Width="24" Height="24" CornerRadius="12" Margin="3" Cursor="Hand" BorderThickness="1" BorderBrush="{DynamicResource ControlBorder}"/>
                    <Border Name="P9" Background="#000000" Width="24" Height="24" CornerRadius="12" Margin="3" Cursor="Hand" BorderThickness="1" BorderBrush="{DynamicResource ControlBorder}"/>
                    <Border Name="P10" Background="#3A3A3C" Width="24" Height="24" CornerRadius="12" Margin="3" Cursor="Hand" BorderThickness="1" BorderBrush="{DynamicResource ControlBorder}"/>
                    <Border Name="P11" Background="#AEAEB2" Width="24" Height="24" CornerRadius="12" Margin="3" Cursor="Hand" BorderThickness="1" BorderBrush="{DynamicResource ControlBorder}"/>
                    <Border Name="P12" Background="#FFFFFF" Width="24" Height="24" CornerRadius="12" Margin="3" Cursor="Hand" BorderThickness="1" BorderBrush="{DynamicResource ControlBorder}"/>
                </UniformGrid>
            </StackPanel>
            
            <!-- Buttons Footer -->
            <Border Grid.Row="3" Background="{DynamicResource ControlBg}" Padding="15" CornerRadius="0,0,8,8">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button Name="BtnSelect" Style="{StaticResource AccentButtonStyle}" Content="Select" Width="80" Margin="0,0,10,0" Cursor="Hand" Height="28" FontWeight="SemiBold"/>
                    <Button Name="BtnCancel" Style="{StaticResource PremiumButtonStyle}" Content="Cancel" Width="80" Cursor="Hand" Height="28"/>
                </StackPanel>
            </Border>
        </Grid>
    </Border>
    )'
    
    ; Replace placeholders in xaml
    xaml := StrReplace(xaml, "%title%", title)
    xaml := StrReplace(xaml, "%initialHex%", initialHex)
    xaml := StrReplace(xaml, "%r%", String(r))
    xaml := StrReplace(xaml, "%g%", String(g))
    xaml := StrReplace(xaml, "%b%", String(b))
    
    ; Compile modal window
    dialogTemplate := '
    (
        <Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
                Width="320" Height="450"
                WindowStyle="None" AllowsTransparency="True" Background="Transparent"
                WindowStartupLocation="CenterOwner"
                TextElement.Foreground="{DynamicResource TextMain}" FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif">
            
            <Window.Resources>
                <!-- Standard Button Style with Rounding and Hover Triggers -->
                <Style x:Key="PremiumButtonStyle" TargetType="Button">
                    <Setter Property="Background" Value="Transparent"/>
                    <Setter Property="BorderThickness" Value="1"/>
                    <Setter Property="BorderBrush" Value="{DynamicResource ControlBorder}"/>
                    <Setter Property="Foreground" Value="{DynamicResource TextMain}"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="Button">
                                <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4">
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                    <Style.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter Property="Background" Value="#15FFFFFF"/>
                        </Trigger>
                        <Trigger Property="IsPressed" Value="True">
                            <Setter Property="Background" Value="#30FFFFFF"/>
                        </Trigger>
                    </Style.Triggers>
                </Style>

                <!-- Accent/Select Button Style -->
                <Style x:Key="AccentButtonStyle" TargetType="Button">
                    <Setter Property="Background" Value="{DynamicResource Accent}"/>
                    <Setter Property="Foreground" Value="White"/>
                    <Setter Property="BorderThickness" Value="0"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="Button">
                                <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4">
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                    <Style.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter Property="Opacity" Value="0.9"/>
                        </Trigger>
                        <Trigger Property="IsPressed" Value="True">
                            <Setter Property="Opacity" Value="0.75"/>
                        </Trigger>
                    </Style.Triggers>
                </Style>

                <!-- Close Button Style with Red Hover -->
                <Style x:Key="CloseButtonStyle" TargetType="Button">
                    <Setter Property="Background" Value="Transparent"/>
                    <Setter Property="Foreground" Value="{DynamicResource TextMain}"/>
                    <Setter Property="BorderThickness" Value="0"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="Button">
                                <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="0,8,0,0">
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                    <Style.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter Property="Background" Value="#E81123"/>
                            <Setter Property="Foreground" Value="White"/>
                        </Trigger>
                        <Trigger Property="IsPressed" Value="True">
                            <Setter Property="Background" Value="#F1707A"/>
                            <Setter Property="Foreground" Value="White"/>
                        </Trigger>
                    </Style.Triggers>
                </Style>
            </Window.Resources>
            
            <WindowChrome.WindowChrome>
                <WindowChrome GlassFrameThickness="-1" CaptionHeight="30" CornerRadius="{DynamicResource WindowRadius}" />
            </WindowChrome.WindowChrome>
        
            %app%
        </Window>
    )'
    
    fullXaml := StrReplace(dialogTemplate, "%app%", xaml)
    
    WinSetEnabled(0, "ahk_id " ownerHwnd)
    
    colorPickerUi := XAMLHost(fullXaml, "", ownerHwnd)
    colorPickerUi.OnEvent("Window", "LoadedHwnd", (*) => colorPickerUi.Update("Window", "NativeOwner", ownerHwnd))
    
    colorPickerUi.OnEvent("SldR", "ValueChanged", OnColorSliderChange)
    colorPickerUi.OnEvent("SldG", "ValueChanged", OnColorSliderChange)
    colorPickerUi.OnEvent("SldB", "ValueChanged", OnColorSliderChange)
    
    presets := ["#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#5AC8FA", "#007AFF", "#5856D6", "#FF2D55", "#000000", "#3A3A3C", "#AEAEB2", "#FFFFFF"]
    for idx, hex in presets {
        colorPickerUi.OnEvent("P" String(idx), "MouseLeftButtonDown", OnPresetClick.Bind(hex))
    }
    
    colorPickerUi.OnEvent("BtnSelect", "Click", (*) => OnPickerSelect())
    colorPickerUi.OnEvent("BtnCancel", "Click", (*) => OnPickerCancel())
    colorPickerUi.OnEvent("BtnClose", "Click", (*) => OnPickerCancel())
    
    colorPickerUi.Track("SldR")
    colorPickerUi.Track("SldG")
    colorPickerUi.Track("SldB")
    
    colorPickerUi.Show()
    
    startWait := A_TickCount
    while (!colorPickerUi.wpfHwnd && A_TickCount - startWait < 2000) {
        Sleep(50)
    }
    
    while (PickerResponse == "" && colorPickerUi.wpfHwnd) {
        Sleep(50)
    }
    
    WinSetEnabled(1, "ahk_id " ownerHwnd)
    
    if (PickerResponse == "Select") {
        return SelectedPickerColor
    }
    return ""
}

OnColorSliderChange(state, *) {
    global SelectedPickerColor, colorPickerUi, ActiveColorType
    if !state.Has("SldR") || !state.Has("SldG") || !state.Has("SldB")
        return
        
    r := Round(Number(state["SldR"]))
    g := Round(Number(state["SldG"]))
    b := Round(Number(state["SldB"]))
    
    hex := Format("#{:02X}{:02X}{:02X}", r, g, b)
    SelectedPickerColor := hex
    
    colorPickerUi.Update("ValR", "Text", String(r))
    colorPickerUi.Update("ValG", "Text", String(g))
    colorPickerUi.Update("ValB", "Text", String(b))
    
    colorPickerUi.Update("ColorPreview", "Background", hex)
    colorPickerUi.Update("ColorPreviewText", "Text", hex)
    
    ; Real-time Live Preview
    if (ActiveColorType == "Accent") {
        PersState.Accent := hex
        ui.Update("TxtCustomAccent", "Text", hex)
        RecomputeTheme()
    } else if (ActiveColorType == "Bg") {
        PersState.BgTint := hex
        ui.Update("TxtCustomBg", "Text", hex)
        RecomputeTheme()
    }
}

OnPresetClick(hexColor, state, *) {
    global SelectedPickerColor, colorPickerUi, ActiveColorType
    SelectedPickerColor := hexColor
    
    r := Integer("0x" SubStr(hexColor, 2, 2))
    g := Integer("0x" SubStr(hexColor, 4, 2))
    b := Integer("0x" SubStr(hexColor, 6, 2))
    
    colorPickerUi.Update("SldR", "Value", String(r))
    colorPickerUi.Update("SldG", "Value", String(g))
    colorPickerUi.Update("SldB", "Value", String(b))
    
    colorPickerUi.Update("ValR", "Text", String(r))
    colorPickerUi.Update("ValG", "Text", String(g))
    colorPickerUi.Update("ValB", "Text", String(b))
    
    colorPickerUi.Update("ColorPreview", "Background", hexColor)
    colorPickerUi.Update("ColorPreviewText", "Text", hexColor)
    
    ; Real-time Live Preview
    if (ActiveColorType == "Accent") {
        PersState.Accent := hexColor
        ui.Update("TxtCustomAccent", "Text", hexColor)
        RecomputeTheme()
    } else if (ActiveColorType == "Bg") {
        PersState.BgTint := hexColor
        ui.Update("TxtCustomBg", "Text", hexColor)
        RecomputeTheme()
    }
}

OnPickerSelect() {
    global PickerResponse, colorPickerUi
    PickerResponse := "Select"
    colorPickerUi.Update("Window", "Close", "")
}

OnPickerCancel() {
    global PickerResponse, colorPickerUi
    PickerResponse := "Cancel"
    colorPickerUi.Update("Window", "Close", "")
}

app.Show()
