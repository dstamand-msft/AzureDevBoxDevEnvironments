Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
choco install -y vscode
choco install 7zip -y
choco install adobereader -y
choco install docker-desktop -y
choco install git -y
choco install kubernetes-cli -y
choco install kubernetes-helm -y
choco install pwsh -y
choco install terraform -y
choco install dotnet

# Clone Application from azure
git clone 'https://github.com/dockersamples/example-voting-app.git' voting-app

# Run application
$cwd = (Get-Location)
Set-Location $cwd/voting-app
docker compose up

# exit script
exit 0




