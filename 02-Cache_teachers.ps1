Using module .\OneRoster.psm1

Param(
    [String]$WorkFolder = ".\gclass-OneRoster\"
)

Get-Module -Name OneRoster| Remove-Module; Import-Module .\OneRoster.psm1

Import-Module PSGSuite
Get-Module -Name PSGSHelp | Remove-Module
Import-Module $PSScriptRoot\PSGSHelp.psm1

$TLOG = ((".\Logs\" + (Get-Date -Format u) +"-Teachers.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Inquire"

filter dropdeaduser
{
    Return $_ | Where-Object -Property role -NE ([OR_RoleType]::null) | Where-Object -Property enabledUser -EQ -Value $true
}

filter rolelimit
{
    Return $_ | Where-Object -Property role -In ([OR_RoleType]::administrator,[OR_RoleType]::aide,[OR_RoleType]::teacher)
}

Function Find_teachers()
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$WorkFolder
    )
    $TEACHERS_Domain = Get-PSGSuiteConfig -ConfigName TEACHERS -PassThru | Select-Object -ExpandProperty Domain
    $STUDENTS_Domain = Get-PSGSuiteConfig -ConfigName STUDENTS -PassThru | Select-Object -ExpandProperty Domain
    If ((Show-PSGSuiteConfig | Select-Object -ExpandProperty ConfigName) -ne "TEACHERS")
    {
        Write-Host -Object "Switching to TEACHERS"
        Switch-PSGSuiteConfig -ConfigName TEACHERS
    }

    $bad = @()
    $good = @()
    $bad += Import-_GSClassroomUserProfile_Bad -Domain $STUDENTS_Domain

    If ($bad.Count -gt 0)
    {
       Write-Host -Object "Cacheing users from STUDENTS's Bad cache"
        $good += $bad | Get-_GSClassroomUserProfile
    }

    If ($good.Count -gt 0)
    {
        Write-Host -Object "Convert bad hits into good hits: $($good.EmailAddress)"
        $hits = @()
        $hits += $good.EmailAddress
        $hits += $good.Id
        $sbad = $bad | Where-Object -FilterScript {$_ -notin $hits}
        If ($sbad.count -eq 0)
        {
            Clear-_GSClassroomUserProfile_Bad -Domain $STUDENTS_Domain
        }
        Else
        {
            Export-_GSClassroomUserProfile_Bad -InputObject $sbad -Domain $STUDENTS_Domain
        }
        $r += $good
    }

    $r = @()
    Get-_GSClassroomUserProfile -StoreBad $true -UserId "test.staff@$($TEACHERS_Domain)" | Out-Null
    $r += Read-OROrgs -FolderPath $WorkFolder | ForEach-Object {
       Write-Host -Object "Caching teachers"
        }, {
        $Org = $_
        $users_O = Read-ORUsers -FolderPath $WorkFolder -LoadXML $true -Org $Org | dropdeaduser | rolelimit
        If ($users_O.Count -eq 0)
        {
           Write-Host -Object "No teachers for: $($Org.name)"
        }
        Else
        {
            Write-Host -Object "Looking up $($users_O.Count) teachers for: $($Org.name)"
            $CP = $users_O.email | Get-_GSClassroomUserProfile -StoreBad $true -SkipCache $true
            Write-Host -Object "Checking for mismatch Google Accounts"
            If ($CP.Count -eq 0)
            {
                    Write-Warning "Missing Classroom User Profiles?:"
                    Write-Warning ('"' + $($users_O.email -join '","') + '"')
            }
            Else
            {
                $diff = Compare-Object -ReferenceObject $users_O.email -DifferenceObject $CP.EmailAddress -Verbose | Where-Object -Property SideIndicator -NE "=>"
                If ($diff.Count -gt 0)
                {
                    Write-Warning "Missing Classroom User Profiles?:"
                    Write-Warning ('"' + $($diff.InputObject -join '","') + '"')
                }
                Return $CP
            }
        }
    }

    Return $r

}

$r = Find_teachers -WorkFolder $WorkFolder