$PackageName = "MicrosoftTeamsNEW"
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$PackageName-install.log"

# Start transcript logging
Start-Transcript -Path $LogPath -Force

###########################################################
# Teams Classic cleanup
###########################################################

# Function to uninstall Teams Classic
function Uninstall-TeamsClassic($TeamsPath) {
    try {
        $process = Start-Process -FilePath "$TeamsPath\Update.exe" -ArgumentList "--uninstall /s" -PassThru -Wait -ErrorAction STOP

        if ($process.ExitCode -ne 0) {
            Write-Error "Uninstallation failed with exit code $($process.ExitCode)."
        }
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

# Function to clean up Teams Classic user registry key
function Uninstall-TeamsClassicReg($KeyPath, $Username) {
    if (Test-Path $TeamsClassicRegPath) {
        Write-Host "  Removing registry key for user: $($Username)"
        try {
            Remove-Item -Path $KeyPath -Force
        }
        catch {
            Write-Error $_.Exception.Message
        } 
    }
    else {
        Write-host "  Teams classic registry key not found for user: $($Username)"
    }
}

# Remove Teams Machine-Wide Installer
Write-Host "Removing Teams Machine-wide Installer"

# Windows Uninstaller Registry Path
$registryPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

# Get all subkeys and match the subkey that contains "Teams Machine-Wide Installer" DisplayName.
$MachineWide = Get-ItemProperty -Path $registryPath | Where-Object -Property DisplayName -eq "Teams Machine-Wide Installer"

if ($MachineWide) {
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/x ""$($MachineWide.PSChildName)"" /qn" -NoNewWindow -Wait
}
else {
    Write-Host "Teams Machine-Wide Installer not found"
}

# Get all Users
$AllUsers = Get-ChildItem -Path "$($ENV:SystemDrive)\Users"

# Fetch user SID and input into object
$UserSID = Get-ChildItem 'HKLM:Software/Microsoft/Windows NT/CurrentVersion/ProfileList' | Where-Object {$_.getvalue('ProfileImagePath') } | ForEach-Object {
    [PSCustomObject]@{
        SID         = $_.PSChildName
        Username    = $_.GetValue('ProfileImagePath')
    }
}

# Process all Users
foreach ($User in $AllUsers) {
    Write-Host "Processing user: $($User.Name)"

    # Locate installation folder
    $localAppData = "$($ENV:SystemDrive)\Users\$($User.Name)\AppData\Local\Microsoft\Teams"
    $programData = "$($env:ProgramData)\$($User.Name)\Microsoft\Teams"
    $userDirectory = "$($ENV:SystemDrive)\Users\$($User.Name)"
    
    # Remove instances for known paths
    if (Test-Path "$localAppData\Current\Teams.exe") {
        Write-Host "  Uninstall Teams for user $($User.Name)"
        Uninstall-TeamsClassic -TeamsPath $localAppData
    }
    elseif (Test-Path "$programData\Current\Teams.exe") {
        Write-Host "  Uninstall Teams for user $($User.Name)"
        Uninstall-TeamsClassic -TeamsPath $programData
    }
    else {
        Write-Host "  Teams installation not found for user $($User.Name)"
    }

    # Registry Cleanup Starts Here
    $HiveFile = "$($userDirectory)\NTUSER.DAT"
    
    Write-Host "  Attempting to load user hive: $($User.Name)"
    # Need to try loading the hive first to determine if we are on the active user
    $HiveLoad = Start-Process -FilePath cmd -windowstyle Hidden -verb runas -ArgumentList "/c reg.exe load HKU\TeamsRemoval $($HiveFile)" -PassThru -Wait

    if ($HiveLoad.ExitCode -eq 0) { # Hive loaded successfully, not current user
        Write-Host "  Hive loaded for $($User.Name)"
        $TeamsClassicRegPath = "Registry::HKU\TeamsRemoval\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
        Uninstall-TeamsClassicReg -KeyPath $TeamsClassicRegPath -Username $User.Name
        Write-Host "  Unloading hive for $($User.Name)"
        [System.GC]::Collect()
        $HiveUnload = Start-Process -FilePath cmd -windowstyle Hidden -verb runas -ArgumentList "/c reg.exe unload HKU\TeamsRemoval" -PassThru -Wait
        Start-Sleep -Seconds 1
        if ($HiveUnload.ExitCode -ne 0) {
            Write-Host "    Failed to unload hive for $($User.Name)"
        } else {Write-Host "   Unloaded hive for $($User.Name)"}
    }
    else { # Hive belongs to current user, pre-loaded
        Write-Host "  Hive preloaded for $($User.Name) - Current User"
        $CurrentSID = ($UserSID | Where-Object {$_.Username -eq $userDirectory}).SID # Grab SID of current user for registry path
        $TeamsClassicRegPath = "Registry::HKU\$($CurrentSID)\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
        Uninstall-TeamsClassicReg -KeyPath $TeamsClassicRegPath -Username $User.Name
        # No hive unload because there is no hive to unload
    }
}

# Remove old Teams folders and icons
$TeamsFolder_old = "$($ENV:SystemDrive)\Users\*\AppData\Local\Microsoft\Teams"
$TeamsIcon_old = "$($ENV:SystemDrive)\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Teams*.lnk"
Get-Item $TeamsFolder_old | Remove-Item -Force -Recurse
Get-Item $TeamsIcon_old | Remove-Item -Force -Recurse

###########################################################
# New Teams installation
###########################################################

Write-Host "Installing new Teams"
& '.\teamsbootstrapper.exe' -p

# Stop transcript logging
Stop-Transcript