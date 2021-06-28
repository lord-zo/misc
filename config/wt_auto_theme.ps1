#!/usr/bin/env -S powershell.exe -ExecutionPolicy Bypass
# Adapt the terminal theme to the current Windows theme
$lightTerminal = 'lxvmLightScheme'
$darkTerminal = 'Campbell'

# Path of the terminal's settings.json
$path = $env:LOCALAPPDATA + "\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

$colorSchemeRegex = '"colorScheme"\s?:\s?"(.*?)"'

function changeColorScheme($colorScheme){
    if (!($colorScheme -eq $null)) {
        $json = Get-Content $path
        $json = $json -replace $colorSchemeRegex, """colorScheme"": ""$colorScheme"""
        $json | Set-Content $path
    } else {
        echo "You must pass a color scheme."
    }
}

# Check current Windows theme and change theme accordingly
$lightTheme = (Get-ItemProperty -path HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize).AppsUseLightTheme

if ($lightTheme -eq 1) {
    changeColorScheme $lightTerminal
} else {
    changeColorScheme $darkTerminal
}
