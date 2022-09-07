Using module .\OneRoster.psm1

Param(
    [String]$WorkFolder = ".\gclass-OneRoster\"
)

Get-Module -Name OneRoster| Remove-Module; Import-Module .\OneRoster.psm1

Import-Module PSGSuite
Get-Module -Name PSGSHelp | Remove-Module
Import-Module $PSScriptRoot\PSGSHelp.psm1

$TLOG = ((".\Logs\" + (Get-Date -Format u) +"-Students.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Inquire"

filter dropdeaduser
{
    Return $_ | Where-Object -Property role -NE ([OR_RoleType]::null) | Where-Object -Property enabledUser -EQ -Value $true
}

filter rolelimit
{
    Return $_ | Where-Object -Property role -EQ ([OR_RoleType]::student)
}

Function Find_students()
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$WorkFolder
    )
    $TEACHERS_Domain = Get-PSGSuiteConfig -ConfigName TEACHERS -PassThru | Select-Object -ExpandProperty Domain
    $STUDENTS_Domain = Get-PSGSuiteConfig -ConfigName STUDENTS -PassThru | Select-Object -ExpandProperty Domain
    If ((Show-PSGSuiteConfig | Select-Object -ExpandProperty ConfigName) -ne "STUDENTS")
    {
        Write-Host -Object "Switching to STUDENTS"
        Switch-PSGSuiteConfig -ConfigName STUDENTS
    }

    $bad = @()
    $odd = @()
    $good = @()
    $bad += Import-_GSClassroomUserProfile_Bad -Domain $TEACHERS_Domain

    If ($bad.Count -gt 0)
    {
        Write-Host -Object "Cacheing users from TEACHERS's Bad cache"
        Write-Host -Object "$($bad -join ",")"
        $odd += $bad | Get-_GSClassroomUserProfile -BypassCache $true -SkipCache $true -CacheOnly $false -Cache_ClassroomUserProfile $null -StoreBad $false
    }

    If ($odd.Count -gt 0)
    {
        Write-Host -Object ("Convert odd hits into good hits?: {0}" -f $odd.EmailAddress)
    }

    $fat = Read-ORUsers -FolderPath $WorkFolder -LoadXML $true | dropdeaduser | rolelimit
    $good = $odd | Where-Object -Property EmailAddress -In $fat.email

    If ($good.Count -gt 0)
    {
        Write-Verbose -Message ("Convert bad hits into good hits: {0}" -f ($good | ConvertTo-Json -Depth 1))
        $hits = @()
        $hits += $good.EmailAddress
        $hits += $good.Id
        $sbad = $bad | Where-Object -FilterScript {$_ -notin $hits}
        If ($sbad.count -eq 0)
        {
            Clear-_GSClassroomUserProfile_Bad -Domain "$TEACHERS_Domain"
        }
        Else
        {
            Export-_GSClassroomUserProfile_Bad -InputObject $sbad -Domain "$TEACHERS_Domain"
        }
        $r += $odd
    }

    $r = $()
    Get-_GSClassroomUserProfile -StoreBad $true -UserId "test.student@$STUDENTS_Domain" | Out-Null
    $r += Read-OROrgs -FolderPath $WorkFolder | ForEach-Object {
        Write-Host -Object "Caching student"
        }, {
        $Org = $_
        $users_O = Read-ORUsers -FolderPath $WorkFolder -LoadXML $true -Org $Org | Where-Object -Property role -EQ ([OR_RoleType]::student)
        If ($users_O.Count -eq 0)
        {
            Write-Host -Object "No students for: $($Org.name)"
        }
        Else
        {
            Write-Host -Object "Looking up $($users_O.Count) students for: $($Org.name)"
            $CP = $users_O.email | Get-_GSClassroomUserProfile -StoreBad $true
            Write-Host -Object "Checking for mismatch Google Accounts"
            If ($CP.Count -eq 0)
            {
                    Write-Warning "Missing Classroom User Profiles?:"
                    Write-Warning ('"' + $($users_O.email -join '","') + '"')
                    #$users_O | Where-Object -Property email -In $users_O.email | Write-Warning
            }
            Else
            {
                $diff = Compare-Object -ReferenceObject $users_O.email -DifferenceObject $CP.EmailAddress -Verbose | Where-Object -Property SideIndicator -NE "=>"
                If ($diff.Count -gt 0)
                {
                    Write-Warning "Missing Classroom User Profiles?:"
                    Write-Warning ('"' + $($diff.InputObject -join '","') + '"')
                    #$users_O | Where-Object -Property email -In $diff.InputObject | Write-Warning
                }
                Return $CP
            }
        }
    }

    return $r

}

$r = Find_students -WorkFolder $WorkFolder