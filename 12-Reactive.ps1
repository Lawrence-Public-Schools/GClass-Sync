Using module .\OneRoster.psm1

Param(
    [String]$WorkFolder = ".\gclass-OneRoster\"
)

Get-Module -Name OneRoster| Remove-Module; Import-Module .\OneRoster.psm1

Import-Module PSGSuite
Get-Module -Name PSGSHelp | Remove-Module
Import-Module $PSScriptRoot\PSGSHelp.psm1

$TLOG = ((".\Log\" + (Get-Date -Format u) +"-Reactive.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

#$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Inquire"

Function Reactive_students()
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$WorkFolder
    )
    If ($(Show-PSGSuiteConfig).ConfigName -ne "STUDENTS")
    {
        Write-Host -Object "Switching to STUDENTS"
        Set-PSGSuiteConfig STUDENTS
    }

    Write-Host -Object "Making list of users that should be active"
    $emails = Read-ORUsers -FolderPath $WorkFolder -LoadXML $true | Where-Object -Property enabledUser -EQ -Value $true | Select-Object -ExpandProperty email
    Write-Host -Object "There should $($emails.Count) active users"
    Write-Host -Object "Getting List of inactives Google accounts users"
    $GSUsers = Get-GSUser -Filter "isSuspended=true" -Projection Basic | Where-Object PrimaryEmail -In $emails

    If ($GSUsers.Count -eq 0)
    {
        Write-Host "No inactive users found that should be active"
        Return
    }

    $r = $GSUsers | ForEach-Object -Begin {
        Write-Host -Object "Found $($GSUsers.Count) inactives users that should be active"
    } -Process {
        Update-GSUser -User $_.PrimaryEmail -Suspended:$False -Confirm:$false -Verbose
    } -End {
        Write-Host -Object "Done reenabling users"
    } -Verbose
    
    If ($r.Count -eq 0)
    {
        Write-Warning -Message "Could not active any Google accounts"
    }
    Else
    {
        Write-Host -Object "Reenabled $($r.Count) Google accounts"
    }

    return $r
}


Function Disactive_students()
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$WorkFolder
    )
    If ($(Show-PSGSuiteConfig).ConfigName -ne "STUDENTS")
    {
        Write-Host -Object "Switching to STUDENTS"
        Set-PSGSuiteConfig STUDENTS
    }

    Write-Host -Object "Making list of users that should be disabled"
    $emails = Read-ORUsers -FolderPath $WorkFolder -LoadXML $false | Where-Object -Property enabledUser -EQ -Value $false | Select-Object -ExpandProperty email
    Write-Host -Object "There should $($emails.Count) disabled users"
    Write-Host -Object "Getting List of actives Google accounts users"
    $GSUsers = Get-GSUser -Filter "isSuspended=False" -Projection Basic
    $GSUsers = $GSUsers | Where-Object PrimaryEmail -In $emails

    If ($GSUsers.Count -eq 0)
    {
        Write-Host "No active users found that should disactive"
        Return
    }

    $r = $GSUsers | ForEach-Object -Begin {
        Write-Host -Object "Found $($GSUsers.Count) actives users that should be inactive"
    } -Process {
        Update-GSUser -User $_.PrimaryEmail -Suspended:$true -Confirm:$false -Verbose
    } -End {
        Write-Host -Object "Done disabling users"
    } -Verbose
    
    If ($r.Count -eq 0)
    {
        Write-Warning -Message "Could not disable any Google accounts"
    }
    Else
    {
        Write-Host -Object "Disabled $($r.Count) Google accounts"
    }

    return $r
}

$r = Reactive_students -WorkFolder $WorkFolder -Verbose
$r = Disactive_students -WorkFolder $WorkFolder -Verbose