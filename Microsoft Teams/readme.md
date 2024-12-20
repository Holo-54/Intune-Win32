# Microsoft Teams
## **Please first refer to Microsoft's newest document for uninstalling Teams classic using a script: https://learn.microsoft.com/en-us/microsoftteams/teams-client-uninstall-script**
This package will uninstall Microsoft Teams classic and install the new Microsoft Teams using Microsoft's bootstrapper, built-in functions of Teams classic, and powershell.

An issue I ran into when working on this was the bootstrapper would not uninstall Microsoft Teams classic completely. User registry keys were left intact due to the hive being unloaded, resulting in Microsoft Teams classic being detected and reported as a security vulnerability post-uninstall.
To remedy this issue, I altered a script found from here: https://scloud.work/new-teams-client-and-cleanup-the-classic-intune/#cleanup-teams-classic-the-easynew-way

This script will follow the same process as the original script with some additional steps for registry cleanup.
- Remove the Teams Machine Wide Installer
- Uninstall Microsoft Teams classic
- Remove stray registry keys
- Install new Microsoft Teams

### Intune information:
- Package file: ```MicrosoftTeams.intunewin```
- Install command: ```%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\install.ps1```
- Uninstall command: ```%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\uninstall.ps1```
- Detection: Use a custom detection script
  - Upload file ```detection.ps1```

### Installation logs
Installation transcript default location: ```C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\MicrosoftTeamsNEW-install.log```
- This can be changed by modifying the variables ```$PackageName``` and ```$LogPath``` in lines 1-2 of ```install.ps1```

### Customization
To customize the script to your liking, you can find all files that were packed into ```MicrosoftTeams.intunewin``` in the ```Package Contents``` directory
