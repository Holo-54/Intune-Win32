$TeamsClassicReg = $false
$TeamsClassic = Test-Path C:\Users\*\AppData\Local\Microsoft\Teams\current\Teams.exe
$TeamsNew = Get-ChildItem "C:\Program Files\WindowsApps" -Filter "MSTeams_*"

$UserSID = Get-ChildItem 'HKLM:Software/Microsoft/Windows NT/CurrentVersion/ProfileList' | Where-Object {$_.getvalue('ProfileImagePath') } | ForEach-Object {
    [PSCustomObject]@{
        SID         = $_.PSChildName
        Username    = $_.GetValue('ProfileImagePath')
    }
}
foreach ($User in $UserSID) {
    if ($User.Username -like "C:\Users\*") {
        $HiveFile = "$($User.Username)\NTUSER.DAT"
        $HiveLoad = Start-Process -FilePath cmd -windowstyle Hidden -verb runas -ArgumentList "/c reg.exe load HKU\TeamsDetection $($HiveFile)" -PassThru -Wait

        if ($HiveLoad.ExitCode -eq 0) { # Hive loaded successfully, not current user
            $TeamsClassicRegPath = "Registry::HKU\TeamsDetection\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
            if (Test-Path $TeamsClassicRegPath) {
                $TeamsClassicReg = $true
            }
            [System.GC]::Collect()
            Start-Process -FilePath cmd -windowstyle Hidden -verb runas -ArgumentList "/c reg.exe unload HKU\TeamsDetection" -PassThru -Wait
            Start-Sleep -Seconds 1
            if ($TeamsClassicReg) {break}
        }
        else { # Hive belongs to current user, pre-loaded
            $TeamsClassicRegPath = "Registry::HKU\$($User.SID)\Software\Microsoft\Windows\CurrentVersion\Uninstall\Teams"
            if (Test-Path $TeamsClassicRegPath) {
                $TeamsClassicReg = $true
                break
            }
        }
    }
}

if(!$TeamsClassic -and !$TeamsClassicReg -and $TeamsNew){
    Write-Host "Installed"
    exit 0
}else{
    exit 1
}