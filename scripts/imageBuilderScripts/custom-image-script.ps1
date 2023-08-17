
Write-Host "Installing Chocolatey..."
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
Write-Host "Chocolatey Installed"

Write-Host "Installing Packages..."
choco install vscode -y
choco install 7zip -y
choco install pwsh -y
choco install adobereader -y
#choco install docker-desktop -y
#choco install kubernetes-cli -y
#choco install kubernetes-helm -y
choco install terraform -y
Write-Host "All Packages Installed"

Write-Host "Installing Azure CLI..."
# Clone Application from azure
choco install winget-cli
winget install --id Git.Git -e --accept-source-agreements
winget install --id Docker.DockerDesktop -e --accept-source-agreements

# Create-folder
New-Item -Path "C:\workingdir" -ItemType "directory" -Force
Set-Location "C:\workingdir"
git clone 'https://github.com/dockersamples/example-voting-app.git' voting-app
Write-Host "Cloning Application from Azure"
# Run application
$cwd = (Get-Location)
Set-Location $cwd/voting-app
#docker compose up

# exit script
exit 0




