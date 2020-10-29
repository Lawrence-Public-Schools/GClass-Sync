Using module .\OneRoster.psm1

Param(
    [String]$WorkFolder = ".\gclass-OneRoster\"
)

Get-Module -Name OneRoster| Remove-Module; Import-Module .\OneRoster.psm1

Import-Module PSGSuite
Get-Module -Name PSGSHelp | Remove-Module
Import-Module $PSScriptRoot\PSGSHelp.psm1

$TLOG = ((".\Logs\" + (Get-Date -Format u) +"-Rename.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Inquire"

Function Rename_students()
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$WorkFolder
    )
    If ((Show-PSGSuiteConfig | Select-Object -ExpandProperty ConfigName) -ne "STUDENTS")
    {
        Write-Host -Object "Switching to STUDENTS"
        Switch-PSGSuiteConfig -ConfigName STUDENTS
    }

    $r = @()
    $r += Read-OROrgs -FolderPath $WorkFolder | ForEach-Object {
        Write-Host -Object "Updating student's names"
        }, {
        $Org = $_
        $users_O = Read-ORUsers -FolderPath $WorkFolder -LoadXML $true -Org $Org | Where-Object -Property role -EQ ([OR_RoleType]::student)
        If ($users_O.Count -eq 0)
        {
            Write-Host -Object "No students for: $($Org.name)"
        }
        Else
        {
            $GSU_N = $users_O | ForEach-Object -Begin {
                Write-Host -Object "Looking up $($users_O.Count) students for: $($Org.name)"
            } -Process {
                $OGN = $_.givenName
                $OFN = $_.familyName
                $GEM = $_.email
                $GCP = $GEM | Get-_GSClassroomUserProfile -CacheOnly $true -StoreBad $false
                $GGN = $null
                $GFN = $null
                $GEA = $null
                If ($null -eq $GCP)
                {
                    Return
                }
                ElseIf ($null -eq $GCP.Name)
                {
                    Return
                }
                Else
                {
                    $GGN = $GCP.Name.GivenName
                    $GFN = $GCP.Name.FamilyName
                    $GEA = $GCP.EmailAddress
                }
                If (($OGN -eq $GGN) -and ($OFN -eq $GFN))
                {
                    Return
                }
                ElseIf (($OGN -ne $GGN) -and ($OFN -ne $GFN))
                {
                    Update-GSUser -User $GEA -GivenName $OGN -FamilyName $OFN -Confirm:$false -Verbose
                }
                ElseIf (($OGN -ne $GGN) -and ($OFN -eq $GFN))
                {
                    Update-GSUser -User $GEA -GivenName $OGN -Confirm:$false -Verbose
                }
                ElseIf (($OGN -eq $GGN) -and ($OFN -ne $GFN))
                {
                    Update-GSUser -User $GEA -FamilyName $OFN -Confirm:$false -Verbose
                }
            } -Verbose
            If ($GSU_N.Count -eq 0)
            {
                Return
            }
            Else
            {
                Write-Verbose -Message "Updating $($GSU_N.Count) accounts to cache"
                $GSU_N.PrimaryEmail | Get-_GSClassroomUserProfile -SkipCache $true -Verbose
            }
        }
    }

    return $r
}

$r = Rename_students -WorkFolder $WorkFolder -Verbose