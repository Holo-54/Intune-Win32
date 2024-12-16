# Microsoft Teams
This package will uninstall Microsoft Teams classic and install the new Microsoft Teams using Microsoft's bootstrapper, built-in functions of Teams classic, and powershell.

An issue I ran into when working on this was the bootstrapper would not uninstall Microsoft Teams classic completely. User registry keys were left intact due to the hive being unloaded, resulting in Microsoft Teams classic being detected and reported as a security vulnerability post-uninstall.
To remedy this issue, I altered a script found from here: https://scloud.work/new-teams-client-and-cleanup-the-classic-intune/#cleanup-teams-classic-the-easynew-way

This script will follow the same process as the original script with some additional steps for registry cleanup.
- Remove the Teams Machine Wide Installer
- Uninstall Microsoft Teams classic
- Remove stray registry keys
- Install new Microsoft Teams

Intune information:
- Install command: ```%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\install.ps1```
- Uninstall command: ```%SystemRoot%\sysnative\WindowsPowerShell\v1.0\powershell.exe -windowstyle hidden -executionpolicy bypass -command .\uninstall.ps1```
- Detection: Use a custom detection script
  - Upload file ```detection.ps1```
