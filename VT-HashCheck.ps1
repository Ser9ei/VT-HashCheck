#
# SPDX-License-Identifier: GPL-3.0
# Copyright (C) 2026 Ser9ei
#

param(
    [string]$FilePath
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
# Configuration
# ============================================================

$ApiKeyFile = Join-Path $PSScriptRoot 'virustotal-api.key'
$ApiBase = 'https://www.virustotal.com/api/v3/files/'

$script:Hash = $null
$script:ReportURL = $null
$script:ApiKey = $null
$script:IsBusy = $false

$GitHubRep = "https://github.com/Ser9ei/VT-HashCheck"
$ShowGitHubLink = $true
$ScriptVersion = "1.0.0"

# ============================================================
# Window
# ============================================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "VT-HashCheck - VirusTotal File Hash Checker v$ScriptVersion"
# Window icon
$IconFile = Join-Path $PSScriptRoot 'VirusTotal.ico'
if (Test-Path -LiteralPath $IconFile -PathType Leaf) {
    $form.Icon = New-Object System.Drawing.Icon($IconFile)
}
$form.ClientSize = New-Object System.Drawing.Size(700, 440)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)

# File name
$labelFile = New-Object System.Windows.Forms.Label
$labelFile.Location = New-Object System.Drawing.Point(15, 15)
$labelFile.Size = New-Object System.Drawing.Size(650, 20)
$labelFile.Text = "File:"
$form.Controls.Add($labelFile)

$textFile = New-Object System.Windows.Forms.TextBox
$textFile.Location = New-Object System.Drawing.Point(15, 40)
$textFile.Size = New-Object System.Drawing.Size(650, 25)
$textFile.ReadOnly = $true
$textFile.Text = $FilePath
$form.Controls.Add($textFile)

# SHA256
$labelHash = New-Object System.Windows.Forms.Label
$labelHash.Location = New-Object System.Drawing.Point(15, 80)
$labelHash.Size = New-Object System.Drawing.Size(650, 20)
$labelHash.Text = "SHA-256:"
$form.Controls.Add($labelHash)

$textHash = New-Object System.Windows.Forms.TextBox
$textHash.Location = New-Object System.Drawing.Point(15, 105)
$textHash.Size = New-Object System.Drawing.Size(650, 25)
$textHash.ReadOnly = $true
$form.Controls.Add($textHash)

# Copy hash
$btnCopy = New-Object System.Windows.Forms.Button
$btnCopy.Location = New-Object System.Drawing.Point(15, 140)
$btnCopy.Size = New-Object System.Drawing.Size(140, 30)
$btnCopy.Text = "Copy SHA-256"
$btnCopy.Enabled = $false
$form.Controls.Add($btnCopy)

# Analysis result
$labelResult = New-Object System.Windows.Forms.Label
$labelResult.Location = New-Object System.Drawing.Point(15, 185)
$labelResult.Size = New-Object System.Drawing.Size(650, 35)
$labelResult.Font = New-Object System.Drawing.Font(
    "Segoe UI", 17, [System.Drawing.FontStyle]::Bold
)
$labelResult.Text = "Initializing..."
$form.Controls.Add($labelResult)

# Result description
$labelMessage = New-Object System.Windows.Forms.Label
$labelMessage.Location = New-Object System.Drawing.Point(15, 225)
$labelMessage.Size = New-Object System.Drawing.Size(650, 35)
$labelMessage.Text = "Preparing..."
$form.Controls.Add($labelMessage)

# Detailed statistics
$labelStats = New-Object System.Windows.Forms.Label
$labelStats.Location = New-Object System.Drawing.Point(15, 260)
$labelStats.Size = New-Object System.Drawing.Size(650, 25)
$form.Controls.Add($labelStats)

# Last analysis date
$labelDate = New-Object System.Windows.Forms.Label
$labelDate.Location = New-Object System.Drawing.Point(15, 290)
$labelDate.Size = New-Object System.Drawing.Size(650, 25)
$form.Controls.Add($labelDate)

# Status
$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Location = New-Object System.Drawing.Point(15, 310)
$labelStatus.Size = New-Object System.Drawing.Size(670, 22)
$form.Controls.Add($labelStatus)

# Registration link
$linkRegister = New-Object System.Windows.Forms.LinkLabel
$linkRegister.Location = New-Object System.Drawing.Point(15, 345)
$linkRegister.Size = New-Object System.Drawing.Size(155, 22)
$linkRegister.Text = "VirusTotal registration"
$linkRegister.Visible = $false
$form.Controls.Add($linkRegister)

# API key link
$linkApiKey = New-Object System.Windows.Forms.LinkLabel
$linkApiKey.Location = New-Object System.Drawing.Point(175, 345)
$linkApiKey.Size = New-Object System.Drawing.Size(110, 22)
$linkApiKey.Text = "Get API key"
$linkApiKey.Visible = $false
$form.Controls.Add($linkApiKey)

# Open API key file
$btnKeyFile = New-Object System.Windows.Forms.Button
$btnKeyFile.Location = New-Object System.Drawing.Point(295, 341)
$btnKeyFile.Size = New-Object System.Drawing.Size(150, 30)
$btnKeyFile.Text = "Open API key file"
$btnKeyFile.Visible = $false
$form.Controls.Add($btnKeyFile)

# Refresh button
$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Location = New-Object System.Drawing.Point(470, 396)
$btnRefresh.Size = New-Object System.Drawing.Size(90, 30)
$btnRefresh.Text = "Refresh"
$btnRefresh.Enabled = $false
$form.Controls.Add($btnRefresh)

# Open VirusTotal
$btnVT = New-Object System.Windows.Forms.Button
$btnVT.Location = New-Object System.Drawing.Point(565, 396)
$btnVT.Size = New-Object System.Drawing.Size(120, 30)
$btnVT.Text = "Open VirusTotal"
$btnVT.Enabled = $false
$form.Controls.Add($btnVT)

# GitHub repository link
$linkGitHub = New-Object System.Windows.Forms.LinkLabel
$linkGitHub.Location = New-Object System.Drawing.Point(15, 400)
$linkGitHub.Size = New-Object System.Drawing.Size(150, 22)
$linkGitHub.Text = "GitHub Repository"
$linkGitHub.Visible = $ShowGitHubLink
$linkGitHub.LinkBehavior = [System.Windows.Forms.LinkBehavior]::AlwaysUnderline
$linkGitHub.LinkColor = $LinkColor
$linkGitHub.ActiveLinkColor = $LinkColor
$linkGitHub.VisitedLinkColor = $LinkColor
$form.Controls.Add($linkGitHub)

# ============================================================
# Windows theme detection
# ============================================================

$ThemePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'

try {
    $Theme = (Get-ItemProperty -Path $ThemePath -Name AppsUseLightTheme -ErrorAction Stop).AppsUseLightTheme
}
catch {
    $Theme = 1
}

if ($Theme -eq 0) {

    $BackColor = [System.Drawing.Color]::FromArgb(32, 32, 32)
    $TextColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $InputColor = [System.Drawing.Color]::FromArgb(48, 48, 48)
    $ButtonColor = [System.Drawing.Color]::FromArgb(55, 55, 55)
    $BorderColor = [System.Drawing.Color]::FromArgb(85, 85, 85)
    $LinkColor = [System.Drawing.Color]::FromArgb(100, 170, 255)

}
else {

    $BackColor = [System.Drawing.Color]::FromArgb(243, 243, 243)
    $TextColor = [System.Drawing.Color]::FromArgb(32, 32, 32)
    $InputColor = [System.Drawing.Color]::White
    $ButtonColor = [System.Drawing.Color]::FromArgb(250, 250, 250)
    $BorderColor = [System.Drawing.Color]::FromArgb(190, 190, 190)
    $LinkColor = [System.Drawing.Color]::FromArgb(0, 100, 190)

}

$form.BackColor = $BackColor
$form.ForeColor = $TextColor

foreach ($Control in $form.Controls) {

    if ($Control -is [System.Windows.Forms.TextBox]) {

        $Control.BackColor = $InputColor
        $Control.ForeColor = $TextColor
        $Control.BorderStyle = 'FixedSingle'

    }
    elseif ($Control -is [System.Windows.Forms.Button]) {

        $Control.BackColor = $ButtonColor
        $Control.ForeColor = $TextColor
        $Control.FlatStyle = 'Flat'
        $Control.FlatAppearance.BorderColor = $BorderColor

    }
    elseif ($Control -is [System.Windows.Forms.LinkLabel]) {

        $Control.LinkColor = $LinkColor
        $Control.ActiveLinkColor = $LinkColor
        $Control.VisitedLinkColor = $LinkColor

    }
    else {

        $Control.BackColor = $BackColor
        $Control.ForeColor = $TextColor

    }
}


# ============================================================
# Configuration error
# ============================================================

function Show-ConfigurationError {

    param(
        [string]$Title,
        [string]$Message
    )

    $labelResult.ForeColor = [System.Drawing.Color]::DarkOrange
    $labelResult.Text = $Title

    $labelMessage.Text = $Message

	$labelStatus.Text = "API key: $ApiKeyFile"
	$labelStatus.ForeColor = $LinkColor
	$labelStatus.Location = New-Object System.Drawing.Point(15, 310)
	
	$linkRegister.Visible = $true
	$linkApiKey.Visible = $true
	$btnKeyFile.Visible = $true

	$labelStats.Visible = $false
	$labelDate.Visible = $false

	$btnRefresh.Enabled = [bool]$script:Hash

    $form.Cursor = [System.Windows.Forms.Cursors]::Default
}

# ============================================================
# Load API key
# ============================================================

function Load-ApiKey {

    $script:ApiKey = $null

    if (!(Test-Path -LiteralPath $ApiKeyFile -PathType Leaf)) {

        Show-ConfigurationError `
            -Title "API key not found" `
            -Message "Register at VirusTotal, obtain your API key and save it to virustotal-api.key."

        return $false
    }

    try {

        $script:ApiKey = (
            Get-Content -LiteralPath $ApiKeyFile -Raw -ErrorAction Stop
        ).Trim()

    }
    catch {

        Show-ConfigurationError `
            -Title "Cannot read API key" `
            -Message "Check access permissions for virustotal-api.key."

        return $false
    }

    if ([string]::IsNullOrWhiteSpace($script:ApiKey)) {

        Show-ConfigurationError `
            -Title "API key is empty" `
            -Message "Register at VirusTotal, obtain your API key and paste it into virustotal-api.key."

        return $false
    }
	
	$labelStatus.Location = New-Object System.Drawing.Point(15, 320)

	$linkRegister.Visible = $false
	$linkApiKey.Visible = $false
	$btnKeyFile.Visible = $false

	$labelStats.Visible = $true
	$labelDate.Visible = $true

    return $true
}

# ============================================================
# Get VirusTotal report
# ============================================================

function Get-VTReport {

    if (!$script:Hash -or $script:IsBusy) {
        return
    }

    $script:IsBusy = $true

    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $btnRefresh.Enabled = $false

    $labelResult.ForeColor = $TextColor
    $labelResult.Text = "Checking VirusTotal..."
    $labelMessage.ForeColor = $TextColor
    $labelMessage.Text = "Requesting report..."
    $labelStats.Text = ""
    $labelDate.Text = ""
    $labelStatus.Text = ""

    $form.Refresh()

    try {

        # Reload API key every time Refresh is pressed
        if (!(Load-ApiKey)) {
            return
        }

        $Headers = @{
            "x-apikey" = $script:ApiKey
            "Accept" = "application/json"
        }

        $Response = Invoke-RestMethod `
            -Uri ($ApiBase + $script:Hash) `
            -Headers $Headers `
            -Method Get `
            -TimeoutSec 25 `
            -ErrorAction Stop

        $Attributes = $Response.data.attributes
        $Stats = $Attributes.last_analysis_stats

        $Malicious = [int]$Stats.malicious
        $Suspicious = [int]$Stats.suspicious
        $Harmless = [int]$Stats.harmless
        $Undetected = [int]$Stats.undetected

        $Total = $Malicious + $Suspicious + $Harmless + $Undetected

        $labelResult.Text = "$Malicious / $Total"

        if ($Malicious -gt 0) {

            $labelResult.ForeColor = [System.Drawing.Color]::Red
            $labelMessage.ForeColor = [System.Drawing.Color]::Red

            $labelMessage.Text = "WARNING: Security vendors flagged this file as malicious!"

        }
        elseif ($Suspicious -gt 0) {

            $labelResult.ForeColor = [System.Drawing.Color]::DarkOrange
            $labelMessage.ForeColor = [System.Drawing.Color]::DarkOrange

            $labelMessage.Text = "Some security vendors flagged this file as suspicious."

        }
        else {

            $labelResult.ForeColor = [System.Drawing.Color]::Green
            $labelMessage.ForeColor = [System.Drawing.Color]::Green

            $labelMessage.Text = "No security vendors flagged this file as malicious"

        }

        $labelStats.Text = "Malicious: $Malicious | Suspicious: $Suspicious | Harmless: $Harmless | Undetected: $Undetected"

        if ($Attributes.last_analysis_date) {

            $Date = [DateTimeOffset]::FromUnixTimeSeconds(
                [long]$Attributes.last_analysis_date
            ).ToLocalTime()

            $labelDate.Text = "Last analysis: $($Date.ToString('yyyy-MM-dd HH:mm:ss'))"

        }

        $labelStatus.ForeColor = [System.Drawing.Color]::Gray
        $labelStatus.Text = "Report successfully received."

    }
    catch {

        $StatusCode = 0
        $ErrorMessage = $_.Exception.Message

        if ($_.Exception.Response) {

            try {
                $StatusCode = [int]$_.Exception.Response.StatusCode
            }
            catch {
                $StatusCode = 0
            }

        }

        $labelResult.ForeColor = [System.Drawing.Color]::DarkOrange

        switch ($StatusCode) {

            400 {
                $labelResult.Text = "Bad request"
                $labelMessage.Text = "VirusTotal rejected the request."
                $labelStatus.Text = "HTTP 400: Check request parameters."
            }

            401 {
                $labelResult.Text = "Invalid API key"
                $labelMessage.Text = "VirusTotal did not accept your API key."
                $labelStatus.Text = "Check virustotal-api.key or obtain a new API key."
            }

            403 {
                $labelResult.Text = "Access denied"
                $labelMessage.Text = "Access to this API operation is forbidden."
                $labelStatus.Text = "HTTP 403: Check your API permissions and account."
            }

            404 {
                $labelResult.Text = "Not found"
                $labelMessage.Text = "This file has not been analyzed by VirusTotal."
                $labelStatus.Text = "No report available for this SHA-256."
            }

            429 {
                $labelResult.Text = "Rate limit exceeded"
                $labelMessage.Text = "VirusTotal API request limit exceeded."
                $labelStatus.Text = "Wait before making another request."
            }

            default {
                $labelResult.Text = "Connection error"
                $labelMessage.Text = $ErrorMessage
                $labelStatus.Text = "HTTP status: $StatusCode"
            }
        }
    }
    finally {

        $script:IsBusy = $false

        $form.Cursor = [System.Windows.Forms.Cursors]::Default

        # Refresh available whenever SHA256 exists
        $btnRefresh.Enabled = [bool]$script:Hash

    }
}

# ============================================================
# Initialize: calculate hash
# ============================================================

function Initialize-Check {

    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    $labelResult.ForeColor = $TextColor
    $labelResult.Text = "Calculating SHA-256..."
    $labelMessage.Text = "Please wait..."
    $labelStatus.Text = ""

    $form.Refresh()

    if ([string]::IsNullOrWhiteSpace($FilePath) -or
        !(Test-Path -LiteralPath $FilePath -PathType Leaf)) {

        $form.Cursor = [System.Windows.Forms.Cursors]::Default

        $labelResult.ForeColor = [System.Drawing.Color]::Red
        $labelResult.Text = "File not found"
        $labelMessage.Text = "The selected file does not exist."

        return
    }

    try {

        $script:Hash = (
            Get-FileHash -LiteralPath $FilePath -Algorithm SHA256 -ErrorAction Stop
        ).Hash.ToLower()

        $textHash.Text = $script:Hash

        $script:ReportURL = "https://www.virustotal.com/gui/file/$($script:Hash)"

        $btnCopy.Enabled = $true
        $btnVT.Enabled = $true
        $btnRefresh.Enabled = $true

    }
    catch {

        $form.Cursor = [System.Windows.Forms.Cursors]::Default

        $labelResult.ForeColor = [System.Drawing.Color]::Red
        $labelResult.Text = "Hash calculation error"
        $labelMessage.Text = $_.Exception.Message

        return
    }

    Get-VTReport
}


# ============================================================
# Buttons and links
# ============================================================

# Copy SHA-256
$btnCopy.Add_Click({

    if ($script:Hash) {

        [System.Windows.Forms.Clipboard]::SetText($script:Hash)
        $labelStatus.Text = "SHA-256 copied to clipboard."

    }

})

# Open VirusTotal report
$btnVT.Add_Click({

    if ($script:ReportURL) {

        Start-Process $script:ReportURL

    }

})

# Refresh report and reload API key
$btnRefresh.Add_Click({

    if ($script:Hash -and !$script:IsBusy) {

        Get-VTReport

    }

})

# VirusTotal registration
$linkRegister.Add_Click({

    Start-Process "https://www.virustotal.com/gui/join-us"

})

# Get API key
$linkApiKey.Add_Click({

    Start-Process "https://www.virustotal.com/gui/my-apikey"

})

# Open API key file or its folder
$btnKeyFile.Add_Click({

    if (Test-Path -LiteralPath $ApiKeyFile -PathType Leaf) {

        Start-Process notepad.exe -ArgumentList "`"$ApiKeyFile`""

    }
    else {

        Start-Process explorer.exe -ArgumentList "`"$PSScriptRoot`""

    }

})

# GitHub repository
$linkGitHub.Add_Click({

    Start-Process "$GitHubRep"

})

# ============================================================
# Show window first, then initialize
# ============================================================

$form.Add_Shown({

    $form.BeginInvoke([Action]{

        Initialize-Check

    }) | Out-Null

})

[void]$form.ShowDialog()
