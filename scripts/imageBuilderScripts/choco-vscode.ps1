### Start  Script 
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install vscode -y
choco install -y azure-cli
choco install pwsh -y
choco install azd -y
choco install git -y
choco install python -y
choco install nodejs -y
# Refresh path variables
RefreshEnv.cmd
### End