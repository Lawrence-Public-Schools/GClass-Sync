Using module .\OneRoster.psm1

Param(
    [String]$WorkFolder = ".\gclass-OneRoster\"
)

Get-Module -Name GClass | Remove-Module; Import-Module .\GClass.psm1

$TLOG = ((".\Logs\" + (Get-Date -Format u) +"-Dead.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Inquire"

Function Dead-classes
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$WorkFolder
    )

    If ((Show-PSGSuiteConfig | Select-Object -ExpandProperty ConfigName) -ne "TEACHERS")
    {
        Write-Host -Object "Switching to TEACHERS"
        Switch-PSGSuiteConfig -ConfigName TEACHERS
    }

    $Caches = Import-ClassLink
    $classes = @()
    $classes += Read-ORclasses -FolderPath $WorkFolder -LoadXML $true #| Where-Object -Property status -NE ([OR_StatusType]::inactive)

    $BadCaches  = @()
    $BadCaches += $Caches | Where-Object -Property sourcedId -CNotIn -Value $Classes.sourcedId | Where-Object -Property CourseState -CNE -Value $null

    If($BadCaches.Count -gt 0)
    {
        Write-Host -Object "Caching classes links: $($BadCaches.Count)"
        $BadCaches.CourseAlias | Get-_GSCourse -BypassCache $true | Out-Null
        $BadCaches.sourcedId | Update-ClassLink -SkipCache $false -Domain $(Show-PSGSuiteConfig).Domain
    }
    Else
    {
        Write-Host -Object "No Dead classes to cache"
    }
}

Function Break-classes
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$WorkFolder
    )

    If ((Show-PSGSuiteConfig | Select-Object -ExpandProperty ConfigName) -ne "TEACHERS")
    {
        Write-Host -Object "Switching to TEACHERS"
        Switch-PSGSuiteConfig -ConfigName TEACHERS
    }

    $Caches = Import-ClassLink
    $classes = @()
    $classes += Read-ORclasses -FolderPath $WorkFolder -LoadXML $true #| Where-Object -Property status -NE ([OR_StatusType]::inactive)

    $BadCaches  = @()
    $BadCaches += $Caches | Where-Object -Property sourcedId -CNotIn -Value $Classes.sourcedId | Where-Object -Property CourseState -CNE -Value $null

    $OldActive = @()
    $OldActive += $BadCaches | Where-Object -Property CourseState -EQ "ACTIVE"

    $OldSetup = @()
    $OldSetup += $BadCaches | Where-Object -Property CourseState -EQ "PROVISIONED"

    $NeedUpdate = @()
    If($OldActive.Count -gt 0)
    {
        Write-Host -Object "Archiving dead classes: $($OldActive.Count)"
        $NewArchived = @()
        $NewArchived += $OldActive.CourseId |  Update-_GSCourseState -CourseState ARCHIVED -Verbose
        $NeedUpdate += $BadCaches | Where-Object -Property CourseId -CIn -Value $NewArchived.Id
    }

    If($OldSetup.Count -gt 0)
    {
        Write-Host -Object "Hiding dead classes: $($OldSetup.Count)"
        $NewSetup = @()
        $NewSetup += $OldSetup.CourseId | Update-_GSCourseState -CourseState DECLINED -Verbose
        $NeedUpdate += $BadCaches | Where-Object -Property CourseId -CIn -Value $NewSetup.Id
    }

    If($NeedUpdate.Count -gt 0)
    {
        Write-Host -Object "Updating dead classes: $($NeedUpdate.Count)"
        $NeedUpdate.sourcedId | Update-ClassLink -SkipCache $false -Domain $(Show-PSGSuiteConfig).Domain -Verbose
    }
}
$r = Dead-classes -WorkFolder $WorkFolder
$r = Break-classes -WorkFolder $WorkFolder

