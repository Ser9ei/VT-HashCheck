#
# SPDX-License-Identifier: GPL-3.0
# Copyright (C) 2026 Ser9ei
#

# ============================================================
# VirusTotal context menu installer
# ============================================================

$Menu = 'Registry::HKEY_CURRENT_USER\Software\Classes\*\shell\VirusTotalHash'

# Paths - current installer directory
$AppFolder = $PSScriptRoot
$Script = Join-Path $AppFolder 'VT-HashCheck.ps1'
$Icon = Join-Path $AppFolder 'VirusTotal.ico'

# Check main script
if (!(Test-Path -LiteralPath $Script -PathType Leaf)) {
    Write-Host "ERROR: VT-HashCheck.ps1 not found: $Script" -ForegroundColor Red
    exit 1
}

# Check icon
if (!(Test-Path -LiteralPath $Icon -PathType Leaf)) {
    Write-Host "WARNING: VirusTotal.ico not found: $Icon" -ForegroundColor Yellow
    Write-Host "Using default PowerShell icon." -ForegroundColor Yellow
    $Icon = 'powershell.exe'
}

# Create registry keys
New-Item -Path "$Menu\command" -Force -ErrorAction Stop | Out-Null

# Context menu title
Set-ItemProperty -Path $Menu `
    -Name '(Default)' `
    -Value 'VT-HashCheck: Check hash on VirusTotal' `
    -ErrorAction Stop

# Menu icon
Set-ItemProperty -Path $Menu `
    -Name 'Icon' `
    -Value $Icon `
    -ErrorAction Stop

# Command
$Command = 'cmd.exe /c start "" /min powershell.exe -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $Script + '" "%1"'

Set-ItemProperty -Path "$Menu\command" `
    -Name '(Default)' `
    -Value $Command `
    -ErrorAction Stop

Write-Host ""
Write-Host "VirusTotal context menu installed successfully!" -ForegroundColor Green
Write-Host "Application folder: $AppFolder"
Write-Host "Script: $Script"
Write-Host "Icon:   $Icon"
Write-Host ""