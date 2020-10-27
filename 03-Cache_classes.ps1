Using module .\OneRoster.psm1

Param(
    [String]$WorkFolder = ".\gclass-OneRoster\"
)

Get-Module -Name GClass | Remove-Module; Import-Module .\GClass.psm1

$TLOG = ((".\Logs\" + (Get-Date -Format u) +"-Cache.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Inquire"

Function Find_classes()
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
        Set-PSGSuiteConfig -ConfigName TEACHERS -ErrorAction Continue
    }

    #Clear-_GSCourse -Domain $(Show-PSGSuiteConfig).Domain
    #Clear-_GSCourseAlias -Domain $(Show-PSGSuiteConfig).Domain
    #Write-Host -Object "Getting fresh Class data"
    #Read-ORclasses -FolderPath $WorkFolder -LoadXML $true | Select-Object -ExpandProperty sourcedId | New-ClassAlias | Get-_GSCourse -SkipCache $true | Out-Null
    #Write-Host -Object "Done getting Class data"
    Return Read-OROrgs -FolderPath $WorkFolder | ForEach-Object -Process {
        #Imports
        Write-Host -Object "Importing classes For: $($_.name)"
        $classes_I = @()
        $classes_I += Read-ORclasses -FolderPath $WorkFolder -Org $_ -LoadXML $true #| Where-Object -Property status -NE ([OR_StatusType]::inactive)

        If ($classes_I.Count -gt 0)
        {
            Write-Host -Object "Caching classes datas: $($classes_I.Count)"
            $classes_I.sourcedId | New-ClassAlias | Get-_GSCourse -SkipCache $true
        }
        Else
        {
            Write-Host -Object "No classes to cache"
        }

        Return
    }
}

Function Link_classes()
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
        Set-PSGSuiteConfig -ConfigName TEACHERS -ErrorAction Continue
    }

    #Clear-_GSCourse -Domain $(Show-PSGSuiteConfig).Domain
    #Clear-_GSCourseAlias -Domain $(Show-PSGSuiteConfig).Domain
    #Write-Host -Object "Getting fresh Class data"
    #Read-ORclasses -FolderPath $WorkFolder -LoadXML $true | Select-Object -ExpandProperty sourcedId | New-ClassAlias | Get-_GSCourse -SkipCache $true | Out-Null
    #Write-Host -Object "Done getting Class data"
    Return Read-OROrgs -FolderPath $WorkFolder | ForEach-Object -Process {
        #Imports
        Write-Host -Object "Importing classes For: $($_.name)"
        $classes_I = @()
        $classes_I += Read-ORclasses -FolderPath $WorkFolder -Org $_ -LoadXML $true #| Where-Object -Property status -NE ([OR_StatusType]::inactive)

        If ($classes_I.Count -gt 0)
        {
            Write-Host -Object "Caching classes links: $($classes_I.Count)"
            $classes_I.sourcedId | Update-ClassLink -SkipCache $false -Domain $(Show-PSGSuiteConfig).Domain
        }
        Else
        {
            Write-Host -Object "No classes to cache"
        }

        Return
    }
}

Function Export-classes
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$WorkFolder
    )
    $r = Find_classes -WorkFolder $WorkFolder
    $r = Link_classes -WorkFolder $WorkFolder
    #Export-ClassLink -InputObject $r
    #Return $r
}

$r = Export-classes -WorkFolder $WorkFolder
