#Requires -Version 5.1
<#
.SYNOPSIS
    Atez Win Optimizer - A Windows debloat, tweak, and optimization utility with a GUI.
.DESCRIPTION
    Single-file PowerShell tool for removing bloatware, applying privacy/performance tweaks,
    installing common software via winget, and managing Windows Update.
.NOTES
    Run as Administrator. Windows 10/11 only. Create a restore point before applying tweaks.
#>
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process powershell -Verb RunAs -ArgumentList $arguments
    exit
}

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$Host.UI.RawUI.WindowTitle = "Atez Win Optimizer"


$Global:DebloatApps = @(
    @{ Name="3D Viewer";              Id="Microsoft.Microsoft3DViewer" }
    @{ Name="Bing News";              Id="Microsoft.BingNews" }
    @{ Name="Bing Weather";           Id="Microsoft.BingWeather" }
    @{ Name="Clipchamp";              Id="Clipchamp.Clipchamp" }
    @{ Name="Cortana";                Id="Microsoft.549981C3F5F10" }
    @{ Name="Feedback Hub";           Id="Microsoft.WindowsFeedbackHub" }
    @{ Name="Get Help";               Id="Microsoft.GetHelp" }
    @{ Name="Mixed Reality Portal";   Id="Microsoft.MixedReality.Portal" }
    @{ Name="Office Hub";             Id="Microsoft.MicrosoftOfficeHub" }
    @{ Name="OneNote (Store)";        Id="Microsoft.Office.OneNote" }
    @{ Name="People";                 Id="Microsoft.People" }
    @{ Name="Skype";                  Id="Microsoft.SkypeApp" }
    @{ Name="Solitaire Collection";   Id="Microsoft.MicrosoftSolitaireCollection" }
    @{ Name="Sticky Notes";           Id="Microsoft.MicrosoftStickyNotes" }
    @{ Name="Teams (Consumer)";       Id="MicrosoftTeams" }
    @{ Name="Tips";                   Id="Microsoft.Getstarted" }
    @{ Name="To Do";                  Id="Microsoft.Todos" }
    @{ Name="Xbox App";               Id="Microsoft.XboxApp" }
    @{ Name="Xbox Game Overlay";      Id="Microsoft.XboxGamingOverlay" }
    @{ Name="Xbox Identity Provider"; Id="Microsoft.XboxIdentityProvider" }
    @{ Name="Xbox Speech";            Id="Microsoft.XboxSpeechToTextOverlay" }
    @{ Name="Your Phone / Link";      Id="Microsoft.YourPhone" }
    @{ Name="Zune Music";             Id="Microsoft.ZuneMusic" }
    @{ Name="Zune Video";             Id="Microsoft.ZuneVideo" }
)

# --- Software installable via winget ---
$Global:SoftwareCatalog = @(
    @{ Name="7-Zip";                Id="7zip.7zip" }
    @{ Name="Google Chrome";        Id="Google.Chrome" }
    @{ Name="Mozilla Firefox";      Id="Mozilla.Firefox" }
    @{ Name="Visual Studio Code";   Id="Microsoft.VisualStudioCode" }
    @{ Name="VLC Media Player";     Id="VideoLAN.VLC" }
    @{ Name="Notepad++";            Id="Notepad++.Notepad++" }
    @{ Name="PowerToys";            Id="Microsoft.PowerToys" }
    @{ Name="Git";                  Id="Git.Git" }
    @{ Name="WinRAR";               Id="RARLab.WinRAR" }
    @{ Name="Spotify";              Id="Spotify.Spotify" }
    @{ Name="Discord";              Id="Discord.Discord" }
    @{ Name="Steam";                Id="Valve.Steam" }
    @{ Name="Zoom";                 Id="Zoom.Zoom" }
    @{ Name="Adobe Acrobat Reader"; Id="Adobe.Acrobat.Reader.64-bit" }
)


$Global:Tweaks = [ordered]@{

    # ---------------- ESSENTIAL ----------------
    "Telemetry - Disable" = @{
        Group = "Essential"
        Description = "Turns off Windows diagnostic data collection (DiagTrack service) and sets telemetry to the minimum level allowed by your edition."
        Apply = {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord
            Set-Service -Name DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
            Stop-Service -Name DiagTrack -Force -ErrorAction SilentlyContinue
        }
        Undo = {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 3 -Type DWord -ErrorAction SilentlyContinue
            Set-Service -Name DiagTrack -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name DiagTrack -ErrorAction SilentlyContinue
        }
    }
    "Activity History - Disable" = @{
        Group = "Essential"
        Description = "Stops Windows from recording and syncing your app/document activity timeline."
        Apply = {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0 -Type DWord
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0 -Type DWord
        }
        Undo = {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        }
    }
    "ConsumerFeatures - Disable" = @{
        Group = "Essential"
        Description = "Prevents Windows from installing suggested/promoted third-party apps and 'consumer experience' content automatically."
        Apply = {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord
        }
        Undo = { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
    }
    "Location Tracking - Disable" = @{
        Group = "Essential"
        Description = "Turns off the system-wide location service so apps can't query your device location."
        Apply = {
            New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Type String
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        }
        Undo = {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Allow" -Type String -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        }
    }
    "BitLocker - Disable" = @{
        Group = "Essential"
        Description = "Decrypts and turns off BitLocker on the system drive. Can take time; ensure you have a recovery key backed up first."
        Apply = { Disable-BitLocker -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue }
        Undo = $null
    }
    "Delivery Optimization - Disable" = @{
        Group = "Essential"
        Description = "Stops Windows from uploading update/store packages to other PCs on your network or the internet (peer-to-peer update sharing)."
        Apply = {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0 -Type DWord
            Set-Service -Name dosvc -StartupType Disabled -ErrorAction SilentlyContinue
        }
        Undo = {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 3 -Type DWord -ErrorAction SilentlyContinue
            Set-Service -Name dosvc -StartupType Automatic -ErrorAction SilentlyContinue
        }
    }
    "Windows AI - Disable And Remove" = @{
        Group = "Essential"
        Description = "Disables Windows Copilot and Recall/AI data analysis features via policy."
        Apply = {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1 -Type DWord
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "AllowRecallEnablement" -Value 0 -Type DWord
        }
        Undo = {
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "AllowRecallEnablement" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        }
    }
    "Xbox & Gaming Components - Remove" = @{
        Group = "Essential"
        Description = "Removes the Xbox app and related Xbox appx packages, and disables Xbox background services."
        Apply = {
            $pkgs = "Microsoft.XboxApp","Microsoft.XboxGamingOverlay","Microsoft.XboxIdentityProvider","Microsoft.XboxSpeechToTextOverlay","Microsoft.GamingApp"
            foreach ($p in $pkgs) {
                Get-AppxPackage -Name $p -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            }
            foreach ($svc in "XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc") {
                Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
            }
        }
        Undo = {
            foreach ($svc in "XblAuthManager","XblGameSave","XboxGipSvc","XboxNetApiSvc") {
                Set-Service -Name $svc -StartupType Manual -ErrorAction SilentlyContinue
            }
        }
    }
    "Microsoft Edge - Remove" = @{
        Group = "Essential"
        Description = "Attempts to fully uninstall Microsoft Edge (Stable) using its own setup utility. May not remove it completely on all builds."
        Apply = {
            $setup = Get-ChildItem "C:\Program Files (x86)\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($setup) {
                Start-Process -FilePath $setup.FullName -ArgumentList "--uninstall --system-level --verbose-logging --force-uninstall" -Wait -ErrorAction SilentlyContinue
            }
        }
        Undo = $null
    }
    "Microsoft OneDrive - Remove" = @{
        Group = "Essential"
        Description = "Uninstalls OneDrive and removes its startup entry and leftover folder."
        Apply = {
            Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
            $setup = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
            if (-not (Test-Path $setup)) { $setup = "$env:SystemRoot\System32\OneDriveSetup.exe" }
            if (Test-Path $setup) { Start-Process $setup -ArgumentList "/uninstall" -Wait -ErrorAction SilentlyContinue }
            Remove-Item -Path "$env:UserProfile\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Undo = $null
    }
    "Unwanted Pre-Installed Apps - Remove" = @{
        Group = "Essential"
        Description = "Removes the same bundled apps listed on the Debloat tab in one step (Bing apps, Solitaire, Skype, Teams consumer, etc.)."
        Apply = { foreach ($app in $Global:DebloatApps) { Get-AppxPackage -Name $app.Id -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } }
        Undo = $null
    }
    "Widgets - Remove" = @{
        Group = "Essential"
        Description = "Removes the Widgets board app and disables the widgets/news-and-interests taskbar icon."
        Apply = {
            Get-AppxPackage -Name "MicrosoftWindows.Client.WebExperience" -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0 -Type DWord
        }
        Undo = { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
    }
    "Temporary Files - Remove" = @{
        Group = "Essential"
        Description = "Deletes files in your user Temp folder and the Windows Temp folder."
        Apply = {
            Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path "$env:WINDIR\Temp" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        Undo = $null
    }
    "Restore Point - Create" = @{
        Group = "Essential"
        Description = "Creates a system restore point before you apply other changes, so you can roll back if needed."
        Apply = {
            Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description "Atez Win Optimizer - Snapshot" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
        }
        Undo = $null
    }
    "Start Menu Previous Layout - Enable" = @{
        Group = "Essential"
        Description = "Switches the Windows 11 Start menu to the 'More pins' layout, closer to the classic look."
        Apply = {
            New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" -Name "Start_Layout" -Value 1 -Type DWord
        }
        Undo = { Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Start" -Name "Start_Layout" -ErrorAction SilentlyContinue }
    }
    "Right-Click Menu Previous Layout - Enable" = @{
        Group = "Essential"
        Description = "Restores the full classic right-click context menu in File Explorer instead of the condensed Windows 11 menu."
        Apply = {
            New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(default)" -Value "" -Type String
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        }
        Undo = {
            Remove-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" -Recurse -Force -ErrorAction SilentlyContinue
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        }
    }


    "Adobe URL Block List - Enable" = @{
        Group = "Advanced"
        Description = "Adds known Adobe telemetry/update domains to the hosts file, pointing them to 0.0.0.0 to block them."
        Apply = {
            $hosts = "$env:WINDIR\System32\drivers\etc\hosts"
            $domains = @("lm.licenses.adobe.com","na1r.services.adobe.com","hlrcv.stage.adobe.com","practivate.adobe.com","activate.adobe.com","genuine.adobe.com")
            $lines = $domains | ForEach-Object { "0.0.0.0 $_" }
            $current = Get-Content $hosts -ErrorAction SilentlyContinue
            $toAdd = $lines | Where-Object { $current -notcontains $_ }
            if ($toAdd) { Add-Content -Path $hosts -Value $toAdd }
        }
        Undo = {
            $hosts = "$env:WINDIR\System32\drivers\etc\hosts"
            $domains = @("lm.licenses.adobe.com","na1r.services.adobe.com","hlrcv.stage.adobe.com","practivate.adobe.com","activate.adobe.com","genuine.adobe.com")
            $content = Get-Content $hosts -ErrorAction SilentlyContinue | Where-Object { $line = $_; -not ($domains | Where-Object { $line -match [regex]::Escape($_) }) }
            Set-Content -Path $hosts -Value $content -Force
        }
    }
    "Background Apps - Disable" = @{
        Group = "Advanced"
        Description = "Prevents Store apps from running in the background and consuming resources/battery when not in use."
        Apply = {
            New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord
        }
        Undo = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
    }
    "Brave Browser - Debloat" = @{
        Group = "Advanced"
        Description = "Applies policies to Brave (if installed) disabling Brave Rewards, Brave Wallet, VPN promos, and first-run offers."
        Apply = {
            New-Item -Path "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" -Name "BraveRewardsDisabled" -Value 1 -Type DWord
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" -Name "BraveWalletDisabled" -Value 1 -Type DWord
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" -Name "BraveVPNDisabled" -Value 1 -Type DWord
        }
        Undo = { Remove-Item -Path "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" -Recurse -Force -ErrorAction SilentlyContinue }
    }
    "Date & Time - Set Time to UTC" = @{
        Group = "Advanced"
        Description = "Stores the hardware clock as UTC instead of local time. Useful for dual-booting with Linux, where clocks otherwise drift."
        Apply = { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Value 1 -Type DWord }
        Undo = { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation" -Name "RealTimeIsUniversal" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
    }
    "Disable Reserved Storage" = @{
        Group = "Advanced"
        Description = "Frees the disk space Windows normally reserves for updates/temp files (a few GB), making it available for general use."
        Apply = { DISM /Online /Set-ReservedStorageState /State:Disabled | Out-Null }
        Undo = { DISM /Online /Set-ReservedStorageState /State:Enabled | Out-Null }
    }
    "File Explorer Home and Gallery - Disable" = @{
        Group = "Advanced"
        Description = "Hides the 'Home' and 'Gallery' entries from File Explorer's navigation pane."
        Apply = {
            New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "HubMode" -Value 1 -Type DWord
        }
        Undo = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "HubMode" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
    }
    "File Explorer Automatic Folder Discovery - Disable" = @{
        Group = "Advanced"
        Description = "Stops Explorer from auto-detecting folder content type (Documents/Pictures/Music) and changing the folder template automatically."
        Apply = {
            Remove-Item -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\Bags" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\BagMRU" -Recurse -Force -ErrorAction SilentlyContinue
        }
        Undo = $null
    }
    "Fullscreen Optimizations - Disable" = @{
        Group = "Advanced"
        Description = "Turns off the fullscreen-optimization compatibility layer for games globally, which can reduce input lag in some titles."
        Apply = {
            New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 0 -Type DWord
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord
        }
        Undo = {
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 0 -Type DWord -ErrorAction SilentlyContinue
        }
    }
    "IPv6 - Disable" = @{
        Group = "Advanced"
        Description = "Unbinds IPv6 from all network adapters. Only do this if you're sure your network doesn't need it."
        Apply = { Get-NetAdapter | Disable-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue }
        Undo = { Get-NetAdapter | Enable-NetAdapterBinding -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue }
    }
    "IPv6 - Set IPv4 as Preferred" = @{
        Group = "Advanced"
        Description = "Keeps IPv6 enabled but tells Windows to prefer IPv4 when both are available, which fixes some connectivity quirks."
        Apply = { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 32 -Type DWord }
        Undo = { Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -ErrorAction SilentlyContinue }
    }
    "Microsoft Edge - Debloat" = @{
        Group = "Advanced"
        Description = "Keeps Edge installed but turns off its first-run promos, shopping assistant, collections, and personalized recommendations via policy."
        Apply = {
            $p = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
            New-Item -Path $p -Force | Out-Null
            Set-ItemProperty -Path $p -Name "HideFirstRunExperience" -Value 1 -Type DWord
            Set-ItemProperty -Path $p -Name "PersonalizationReportingEnabled" -Value 0 -Type DWord
            Set-ItemProperty -Path $p -Name "ShowRecommendationsEnabled" -Value 0 -Type DWord
            Set-ItemProperty -Path $p -Name "EdgeCollectionsEnabled" -Value 0 -Type DWord
            Set-ItemProperty -Path $p -Name "EdgeShoppingAssistantEnabled" -Value 0 -Type DWord
        }
        Undo = { Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Recurse -Force -ErrorAction SilentlyContinue }
    }
    "Razer Software Auto-Install - Disable" = @{
        Group = "Advanced"
        Description = "Stops Windows Update from automatically fetching and installing Razer peripheral driver/software packages."
        Apply = {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "SearchOrderConfig" -Value 0 -Type DWord
        }
        Undo = { Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DriverSearching" -Name "SearchOrderConfig" -ErrorAction SilentlyContinue }
    }
    "RDP Unsigned File Warnings - Disable" = @{
        Group = "Advanced"
        Description = "Suppresses the 'publisher could not be verified' prompt when opening .rdp files from a trusted source."
        Apply = {
            New-Item -Path "HKCU:\Software\Microsoft\Terminal Server Client" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Terminal Server Client" -Name "AuthenticationLevelOverride" -Value 0 -Type DWord
        }
        Undo = { Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Terminal Server Client" -Name "AuthenticationLevelOverride" -ErrorAction SilentlyContinue }
    }
    "Storage Sense - Disable" = @{
        Group = "Advanced"
        Description = "Turns off automatic disk cleanup of temp files and Recycle Bin contents that Storage Sense runs on a schedule."
        Apply = { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
        Undo = { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
    }
    "System Tray Notifications & Calendar - Disable" = @{
        Group = "Advanced"
        Description = "Hides Action Center, notification toasts, and the taskbar clock's calendar flyout."
        Apply = {
            New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 1 -Type DWord
        }
        Undo = { Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
    }
    "Teredo - Disable" = @{
        Group = "Advanced"
        Description = "Disables the Teredo IPv6 tunneling protocol, sometimes recommended for reducing certain NAT/gaming connection issues."
        Apply = { netsh interface teredo set state disabled | Out-Null }
        Undo = { netsh interface teredo set state default | Out-Null }
    }
    "Visual Effects - Set to Best Performance" = @{
        Group = "Advanced"
        Description = "Turns off animations, shadows, and transparency effects to reduce UI overhead on lower-end hardware."
        Apply = { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -ErrorAction SilentlyContinue }
        Undo = { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
    }
    "Disk Cleanup - Run" = @{
        Group = "Advanced"
        Description = "Launches the built-in Disk Cleanup utility to remove temp/system files."
        Apply = { Start-Process cleanmgr -ArgumentList "/d $($env:SystemDrive.TrimEnd(':'))" }
        Undo = $null
    }
    "End Task With Right Click - Enable" = @{
        Group = "Advanced"
        Description = "Adds an 'End Task' option when you right-click an app directly on the taskbar (Windows 11 dev feature)."
        Apply = {
            New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 1 -Type DWord
        }
        Undo = { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name "TaskbarEndTask" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
    }
    "Microsoft Store Recommended Search Results - Disable" = @{
        Group = "Advanced"
        Description = "Removes promoted/recommended results from Microsoft Store search."
        Apply = {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "DisableRecommendedResults" -Value 1 -Type DWord
        }
        Undo = { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore" -Name "DisableRecommendedResults" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
    }
    "Services - Set to Manual" = @{
        Group = "Advanced"
        Description = "Sets a curated list of non-essential services (Fax, Remote Registry, Maps Broker, Windows Media Player Network Sharing, etc.) to Manual startup so they only run when needed."
        Apply = {
            foreach ($svc in "Fax","RemoteRegistry","MapsBroker","WMPNetworkSvc","WSearch","SysMain") {
                Set-Service -Name $svc -StartupType Manual -ErrorAction SilentlyContinue
            }
        }
        Undo = {
            foreach ($svc in "Fax","RemoteRegistry","MapsBroker","WMPNetworkSvc","WSearch","SysMain") {
                Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
            }
        }
    }
    "Windows Platform Binary Table (WPBT) - Disable" = @{
        Group = "Advanced"
        Description = "Prevents Windows from executing the vendor-supplied binary some OEMs embed in firmware (WPBT), often used for bundled bloatware injection."
        Apply = {
            New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" -Name "DisableWpbtExecution" -Value 1 -Type DWord
        }
        Undo = { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" -Name "DisableWpbtExecution" -Value 0 -Type DWord -ErrorAction SilentlyContinue }
    }


    "Web Search in Start Menu - Disable" = @{
        Group = "Essential"
        Description = "Removes Bing web results from Start menu search, showing only local results."
        Apply = {
            New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Type DWord
        }
        Undo = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
    }
    "Cortana - Disable" = @{
        Group = "Essential"
        Description = "Disables Cortana via policy so it can't run or be invoked."
        Apply = {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord
        }
        Undo = { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
    }
    "Dark Mode - Enable" = @{
        Group = "Essential"
        Description = "Switches both apps and system UI (taskbar, Settings, Explorer) to dark theme."
        Apply = {
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord
        }
        Undo = {
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 1 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        }
    }
    "Game DVR / Game Bar - Disable" = @{
        Group = "Advanced"
        Description = "Turns off background game recording and the Game Bar overlay, which can free up resources during gameplay."
        Apply = {
            New-Item -Path "HKCU:\System\GameConfigStore" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord
        }
        Undo = { Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
    }
    "Hibernation - Disable" = @{
        Group = "Essential"
        Description = "Turns off hibernation and deletes hiberfil.sys, freeing disk space equal to your RAM size."
        Apply = { powercfg /hibernate off }
        Undo  = { powercfg /hibernate on }
    }
    "Startup Delay - Disable" = @{
        Group = "Advanced"
        Description = "Removes the artificial delay Windows adds before launching startup apps after sign-in."
        Apply = {
            New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -Value 0 -Type DWord
        }
        Undo = { Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Name "StartupDelayInMSec" -ErrorAction SilentlyContinue }
    }
    "Power Plan - Set to High Performance" = @{
        Group = "Essential"
        Description = "Switches the active Windows power plan to High Performance for maximum CPU responsiveness (uses more power)."
        Apply = { powercfg /setactive SCHEME_MIN }
        Undo  = { powercfg /setactive SCHEME_BALANCED }
    }
    "Show File Extensions" = @{
        Group = "Advanced"
        Description = "Makes File Explorer always show file extensions (.txt, .exe, etc.) instead of hiding known ones."
        Apply = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord }
        Undo  = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 1 -Type DWord -ErrorAction SilentlyContinue }
    }
    "Show Hidden Files" = @{
        Group = "Advanced"
        Description = "Makes File Explorer display hidden files and folders."
        Apply = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord }
        Undo  = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 2 -Type DWord -ErrorAction SilentlyContinue }
    }
}


[xml]$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Atez Win Optimizer" Height="760" Width="1040"
        WindowStartupLocation="CenterScreen"
        Background="#1E1E2E">
    <Window.Resources>
        <Style TargetType="TabItem">
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Margin" Value="4,4,4,4"/>
            <Setter Property="Foreground" Value="#EAEAEA"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="Margin" Value="6"/>
            <Setter Property="Background" Value="#7C3AED"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>
        <Style TargetType="GroupBox">
            <Setter Property="Foreground" Value="#EAEAEA"/>
            <Setter Property="Margin" Value="6"/>
            <Setter Property="FontWeight" Value="Bold"/>
        </Style>
        <Style TargetType="ToolTip">
            <Setter Property="MaxWidth" Value="320"/>
            <Setter Property="Background" Value="#2A2A3D"/>
            <Setter Property="Foreground" Value="#EAEAEA"/>
            <Setter Property="Padding" Value="8"/>
        </Style>
    </Window.Resources>
    <DockPanel>
        <Border DockPanel.Dock="Top" Background="#7C3AED" Padding="16,10">
            <StackPanel Orientation="Horizontal">
                <TextBlock Text="Atez Win Optimizer" FontSize="22" FontWeight="Bold" Foreground="White"/>
                <TextBlock Text="  |  Windows Debloat &amp; Tweak Utility" FontSize="13" Foreground="#EDE9FE" VerticalAlignment="Bottom" Margin="8,0,0,4"/>
            </StackPanel>
        </Border>
        <Border DockPanel.Dock="Bottom" Background="#161622" Padding="10">
            <TextBlock Name="StatusText" Text="Ready." Foreground="#9CA3AF" FontSize="12"/>
        </Border>
        <TabControl Name="MainTabs" Background="#1E1E2E" Margin="8">
            <TabItem Header="Debloat">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <ScrollViewer Grid.Row="0">
                        <WrapPanel Name="DebloatPanel" Orientation="Vertical" Height="540" Margin="10"/>
                    </ScrollViewer>
                    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Button Name="BtnSelectAllDebloat" Content="Select All"/>
                        <Button Name="BtnSelectNoneDebloat" Content="Select None"/>
                        <Button Name="BtnRunDebloat" Content="Remove Selected Apps" Background="#DC2626"/>
                    </StackPanel>
                </Grid>
            </TabItem>
            <TabItem Header="Tweaks">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <ScrollViewer Grid.Row="0">
                        <StackPanel Margin="10">
                            <GroupBox Header="Essential Tweaks">
                                <StackPanel Name="EssentialTweaksPanel" Margin="6"/>
                            </GroupBox>
                            <GroupBox Header="Advanced Tweaks">
                                <StackPanel Name="AdvancedTweaksPanel" Margin="6"/>
                            </GroupBox>
                        </StackPanel>
                    </ScrollViewer>
                    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Button Name="BtnSelectAllTweaks" Content="Select All"/>
                        <Button Name="BtnSelectNoneTweaks" Content="Select None"/>
                        <Button Name="BtnApplyTweaks" Content="Apply Selected Tweaks"/>
                        <Button Name="BtnUndoTweaks" Content="Undo Selected Tweaks" Background="#374151"/>
                    </StackPanel>
                </Grid>
            </TabItem>
            <TabItem Header="Install Software">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <ScrollViewer Grid.Row="0">
                        <WrapPanel Name="SoftwarePanel" Orientation="Vertical" Height="540" Margin="10"/>
                    </ScrollViewer>
                    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Left">
                        <Button Name="BtnSelectAllSoftware" Content="Select All"/>
                        <Button Name="BtnSelectNoneSoftware" Content="Select None"/>
                        <Button Name="BtnInstallSoftware" Content="Install Selected"/>
                    </StackPanel>
                </Grid>
            </TabItem>
            <TabItem Header="Maintenance">
                <StackPanel Margin="16">
                    <TextBlock Text="System Maintenance" FontSize="16" FontWeight="Bold" Foreground="#EAEAEA" Margin="0,0,0,10"/>
                    <Button Name="BtnCleanTemp" Content="Clean Temp Files" HorizontalAlignment="Left" Width="260"/>
                    <Button Name="BtnFlushDns" Content="Flush DNS Cache" HorizontalAlignment="Left" Width="260"/>
                    <Button Name="BtnSfcScan" Content="Run SFC /scannow" HorizontalAlignment="Left" Width="260"/>
                    <Button Name="BtnCheckUpdates" Content="Check for Windows Updates" HorizontalAlignment="Left" Width="260"/>
                    <Button Name="BtnRestorePoint" Content="Create Restore Point" HorizontalAlignment="Left" Width="260"/>
                </StackPanel>
            </TabItem>
            <TabItem Header="About">
                <StackPanel Margin="20">
                    <TextBlock Text="Atez Win Optimizer" FontSize="20" FontWeight="Bold" Foreground="#EAEAEA"/>
                    <TextBlock Text="An independent Windows debloat and tweak utility." Foreground="#9CA3AF" Margin="0,6,0,0" TextWrapping="Wrap"/>
                    <TextBlock Text="Hover the (?) next to any tweak to see what it does. Always review changes before applying them to a production machine, and create a restore point first." Foreground="#9CA3AF" Margin="0,10,0,0" TextWrapping="Wrap"/>
                </StackPanel>
            </TabItem>
        </TabControl>
    </DockPanel>
</Window>
"@

$Reader = (New-Object System.Xml.XmlNodeReader $Xaml)
$Window = [Windows.Markup.XamlReader]::Load($Reader)


$Controls = @{}
$Xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    $Controls[$_.Name] = $Window.FindName($_.Name)
}

function Set-Status {
    param([string]$Message)
    $Controls.StatusText.Text = $Message
    $Controls.StatusText.Dispatcher.Invoke([Action]{}, "Render")
}


$Global:DebloatCheckboxes = @{}
foreach ($app in $Global:DebloatApps) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $app.Name
    $cb.Tag = $app.Id
    $cb.Width = 260
    $Controls.DebloatPanel.Children.Add($cb) | Out-Null
    $Global:DebloatCheckboxes[$app.Id] = $cb
}


$Global:TweakCheckboxes = @{}

function Add-TweakRow {
    param($Name, $Data, $TargetPanel)

    $row = New-Object System.Windows.Controls.StackPanel
    $row.Orientation = "Horizontal"
    $row.Margin = "2,4,2,4"

    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $Name
    $cb.Tag = $Name
    $cb.FontSize = 13
    $cb.VerticalAlignment = "Center"
    $cb.Width = 380

    $help = New-Object System.Windows.Controls.TextBlock
    $help.Text = "(?)"
    $help.Foreground = "#60A5FA"
    $help.Cursor = "Help"
    $help.Margin = "6,0,0,0"
    $help.VerticalAlignment = "Center"

    $tipText = New-Object System.Windows.Controls.TextBlock
    $tipText.Text = $Data.Description
    $tipText.TextWrapping = "Wrap"
    $tipText.MaxWidth = 320

    $tip = New-Object System.Windows.Controls.ToolTip
    $tip.Content = $tipText
    $tip.MaxWidth = 340
    [System.Windows.Controls.ToolTipService]::SetToolTip($help, $tip)
    [System.Windows.Controls.ToolTipService]::SetInitialShowDelay($help, 150)

    $row.Children.Add($cb) | Out-Null
    $row.Children.Add($help) | Out-Null
    $TargetPanel.Children.Add($row) | Out-Null

    $Global:TweakCheckboxes[$Name] = $cb
}

foreach ($key in $Global:Tweaks.Keys) {
    $data = $Global:Tweaks[$key]
    if ($data.Group -eq "Advanced") {
        Add-TweakRow -Name $key -Data $data -TargetPanel $Controls.AdvancedTweaksPanel
    } else {
        Add-TweakRow -Name $key -Data $data -TargetPanel $Controls.EssentialTweaksPanel
    }
}


$Global:SoftwareCheckboxes = @{}
foreach ($sw in $Global:SoftwareCatalog) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $sw.Name
    $cb.Tag = $sw.Id
    $cb.Width = 260
    $Controls.SoftwarePanel.Children.Add($cb) | Out-Null
    $Global:SoftwareCheckboxes[$sw.Id] = $cb
}


function Set-AllCheckboxes {
    param($HashOfCheckboxes, [bool]$Checked)
    foreach ($cb in $HashOfCheckboxes.Values) { $cb.IsChecked = $Checked }
}

$Controls.BtnSelectAllDebloat.Add_Click({ Set-AllCheckboxes $Global:DebloatCheckboxes $true })
$Controls.BtnSelectNoneDebloat.Add_Click({ Set-AllCheckboxes $Global:DebloatCheckboxes $false })
$Controls.BtnSelectAllTweaks.Add_Click({ Set-AllCheckboxes $Global:TweakCheckboxes $true })
$Controls.BtnSelectNoneTweaks.Add_Click({ Set-AllCheckboxes $Global:TweakCheckboxes $false })
$Controls.BtnSelectAllSoftware.Add_Click({ Set-AllCheckboxes $Global:SoftwareCheckboxes $true })
$Controls.BtnSelectNoneSoftware.Add_Click({ Set-AllCheckboxes $Global:SoftwareCheckboxes $false })


$Controls.BtnRunDebloat.Add_Click({
    $selected = $Global:DebloatCheckboxes.GetEnumerator() | Where-Object { $_.Value.IsChecked -eq $true }
    if (-not $selected) { Set-Status "No apps selected."; return }
    foreach ($entry in $selected) {
        $appId = $entry.Key
        Set-Status "Removing $appId ..."
        try {
            Get-AppxPackage -Name $appId -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -eq $appId } |
                ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue | Out-Null }
        } catch {
            Set-Status "Failed to remove $appId : $($_.Exception.Message)"
        }
    }
    Set-Status "Debloat complete. $($selected.Count) app(s) processed."
})


$Controls.BtnApplyTweaks.Add_Click({
    $selected = $Global:TweakCheckboxes.GetEnumerator() | Where-Object { $_.Value.IsChecked -eq $true }
    if (-not $selected) { Set-Status "No tweaks selected."; return }
    foreach ($entry in $selected) {
        $name = $entry.Key
        Set-Status "Applying: $name ..."
        try {
            & $Global:Tweaks[$name].Apply
        } catch {
            Set-Status "Failed to apply '$name': $($_.Exception.Message)"
        }
    }
    Set-Status "Applied $($selected.Count) tweak(s). Some changes require sign-out or restart."
})

$Controls.BtnUndoTweaks.Add_Click({
    $selected = $Global:TweakCheckboxes.GetEnumerator() | Where-Object { $_.Value.IsChecked -eq $true }
    if (-not $selected) { Set-Status "No tweaks selected."; return }
    $skipped = 0
    foreach ($entry in $selected) {
        $name = $entry.Key
        $undo = $Global:Tweaks[$name].Undo
        if (-not $undo) { $skipped++; continue }
        Set-Status "Reverting: $name ..."
        try {
            & $undo
        } catch {
            Set-Status "Failed to undo '$name': $($_.Exception.Message)"
        }
    }
    Set-Status "Undo complete. $skipped tweak(s) have no automatic revert (one-off actions like removals/cleanups)."
})


$Controls.BtnInstallSoftware.Add_Click({
    $selected = $Global:SoftwareCheckboxes.GetEnumerator() | Where-Object { $_.Value.IsChecked -eq $true }
    if (-not $selected) { Set-Status "No software selected."; return }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Set-Status "winget not found. Install 'App Installer' from the Microsoft Store first."
        return
    }
    foreach ($entry in $selected) {
        $id = $entry.Key
        Set-Status "Installing $id ..."
        try {
            Start-Process winget -ArgumentList "install --id $id -e --accept-package-agreements --accept-source-agreements --silent" -Wait -NoNewWindow
        } catch {
            Set-Status "Failed to install $id : $($_.Exception.Message)"
        }
    }
    Set-Status "Software installation complete. $($selected.Count) package(s) processed."
})


$Controls.BtnCleanTemp.Add_Click({
    Set-Status "Cleaning temp files ..."
    try {
        Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Get-ChildItem -Path "$env:WINDIR\Temp" -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        Set-Status "Temp files cleaned."
    } catch { Set-Status "Temp cleanup finished with some items skipped (in use)." }
})

$Controls.BtnFlushDns.Add_Click({
    Set-Status "Flushing DNS cache ..."
    ipconfig /flushdns | Out-Null
    Set-Status "DNS cache flushed."
})

$Controls.BtnSfcScan.Add_Click({
    Set-Status "Running SFC /scannow in a new window ..."
    Start-Process powershell -ArgumentList "-NoExit -Command sfc /scannow"
})

$Controls.BtnCheckUpdates.Add_Click({
    Set-Status "Opening Windows Update ..."
    Start-Process "ms-settings:windowsupdate"
})

$Controls.BtnRestorePoint.Add_Click({
    Set-Status "Creating restore point ..."
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Atez Win Optimizer - Pre-Change Snapshot" -RestorePointType "MODIFY_SETTINGS"
        Set-Status "Restore point created."
    } catch {
        Set-Status "Could not create restore point: $($_.Exception.Message)"
    }
})


$Window.ShowDialog() | Out-Null