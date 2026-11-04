
$ErrorActionPreference = "Stop"

# Project configuration
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "       SHOPEASY ONE-CLICK DEPLOYMENT" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# 1. Check for staged changes
Write-Host "[1/5] Checking Git..." -ForegroundColor Yellow

git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    throw "Uncommitted staged changes detected. Review them before deployment."
}

# Stage only application and deployment files
git add -- app Dockerfile ansible/deploy.yml deploy.ps1

if ($LASTEXITCODE -ne 0) {
    throw "Git add failed."
}

# Commit only if there are changes
git diff --cached --quiet

if ($LASTEXITCODE -ne 0) {
    git commit -m "Update ShopEasy application"

    if ($LASTEXITCODE -ne 0) {
        throw "Git commit failed."
    }
}
else {
    Write-Host "No new application changes to commit." -ForegroundColor Gray
}

git push origin main

if ($LASTEXITCODE -ne 0) {
    throw "Git push failed."
}

Write-Host "GitHub synchronization successful." -ForegroundColor Green

# 2. Check Terraform infrastructure
Write-Host "`n[2/5] Checking AWS infrastructure..." -ForegroundColor Yellow

terraform -chdir=terraform plan -detailed-exitcode -no-color
$TerraformExitCode = $LASTEXITCODE

if ($TerraformExitCode -eq 1) {
    throw "Terraform plan failed. Check the error above."
}
elseif ($TerraformExitCode -eq 2) {
    throw "Terraform detected infrastructure changes. Deployment stopped to protect your existing EC2 instance."
}
elseif ($TerraformExitCode -ne 0) {
    throw "Unexpected Terraform exit code: $TerraformExitCode"
}

Write-Host "Infrastructure unchanged. Existing EC2 will be reused." -ForegroundColor Green

# 3. Read existing EC2 public IP
Write-Host "`n[3/5] Reading EC2 details..." -ForegroundColor Yellow

$PublicIp = (terraform -chdir=terraform output -raw public_ip).Trim()

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($PublicIp)) {
    throw "Could not retrieve EC2 public IP from Terraform."
}

Write-Host "Using existing EC2: $PublicIp" -ForegroundColor Green

# Refresh ignored Ansible inventory
$InventoryContent = @"
[webservers]
$PublicIp ansible_user=ubuntu ansible_ssh_private_key_file=/home/swati/.ssh/ecommerce-key.pem ansible_python_interpreter=/usr/bin/python3
"@

Set-Content -Path "$ProjectRoot\ansible\inventory.ini" -Value $InventoryContent -Encoding ascii

# 4. Run Ansible through WSL
Write-Host "`n[4/5] Deploying ShopEasy using Ansible..." -ForegroundColor Yellow

$WslProjectPath = (wsl wslpath -a "$ProjectRoot").Trim()

if ($LASTEXITCODE -ne 0) {
    throw "Could not resolve project path in WSL."
}

$AnsibleCommand = "cd '$WslProjectPath' && ansible-playbook -i ansible/inventory.ini ansible/deploy.yml"

wsl bash -lc $AnsibleCommand

if ($LASTEXITCODE -ne 0) {
    throw "Ansible deployment failed."
}

Write-Host "Ansible deployment completed." -ForegroundColor Green

# 5. Verify application health
Write-Host "`n[5/5] Checking ShopEasy health..." -ForegroundColor Yellow

$HealthUrl = "http://${PublicIp}:5000/health"
$Health = $null

for ($Attempt = 1; $Attempt -le 5; $Attempt++) {
    try {
        $Health = Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 10
        break
    }
    catch {
        Write-Host "Health check attempt $Attempt failed. Retrying..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
}

if ($null -eq $Health -or $Health.status -ne "healthy") {
    throw "ShopEasy health verification failed."
}

Write-Host "`n======================================" -ForegroundColor Green
Write-Host "       DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

Write-Host "Application : $($Health.application)"
Write-Host "Status      : $($Health.status)"
Write-Host "Website     : http://${PublicIp}:5000"

Write-Host "`nShopEasy is live!" -ForegroundColor Green
