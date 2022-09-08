Using module .\OneRoster.psm1

Param(
    [String]$WorkFolder = ".\gclass-OneRoster\"
)

Get-Module -Name OneRoster| Remove-Module; Import-Module .\OneRoster.psm1

Import-Module PSGSuite
Get-Module -Name PSGSHelp | Remove-Module
Import-Module $PSScriptRoot\PSGSHelp.psm1

$TLOG = ((".\Logs\" + (Get-Date -Format u) +"-Guardian.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

#$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Inquire"

Function Invite_guardian()
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

    $SGUsers = Read-ORUsers -FolderPath $WorkFolder -LoadXML $true | Where-Object -Property enabledUser -EQ -Value $true | Where-Object -Property role -IN -Value @(([OR_RoleType]::student),[OR_RoleType]::guardian)
    $SUsers = $SGUsers | Where-Object -Property role -EQ -Value ([OR_RoleType]::student)
    $GUsers = $SGUsers | Where-Object -Property role -EQ -Value ([OR_RoleType]::guardian)

    $SUserswG = $SUsers | Where-Object -FilterScript {($_.agentSourcedIds -join ",") -cne ""}
    Write-Host -Object ("Find {0} students with guardians" -f $SUserswG.Count)
    $GUsersHT = $GUsers | Where-Object -Property email -CNE -Value "" | Group-Object -AsHashTable -Property sourcedId

    $invs = @()
    $invs += $SUserswG | ForEach-Object -Begin {
    } -Process {
        $Student = $_
        $StudentGuardians = @()
        $StudentGuardianInvitations = @()
        $StudentGuardians += Get-GSStudentGuardian -StudentId $Student.email
        $StudentGuardianInvitations += Get-GSStudentGuardianInvitation -StudentId $Student.email
        $Student.agentSourcedIds | ForEach-Object -Begin {
            $InvSented = @()
        } -Process {
            $GuardianId = $_
            $Guardian = $null
            $StudentGuardian = $null
            $Guardianemail = $null
            If ($GUsersHT.ContainsKey($GuardianId))
            {
                $Guardian = $GUsersHT[$GuardianId]
                $Guardianemail = $Guardian.email.Trim()
                If ($Guardianemail -cne $Guardian.email)
                {
                    Write-Verbose -Message ("Email have whitespace in email: {0}" -f $GuardianId)
                }
                $StudentGuardian = $StudentGuardians | Where-Object -Property InvitedEmailAddress -EQ -Value $Guardianemail
                $StudentGuardianInvitation = $StudentGuardianInvitations | Where-Object -Property InvitedEmailAddress -EQ -Value $Guardianemail
            }

            If ($null -ceq $Guardian )
            {
                #Write-Verbose -Message ("Skipping {0} for blank email" -f $GuardianId)
            }
            ElseIf ($null -cne $StudentGuardian)
            {
                #Write-Host -Object ("{0} already have {1}" -f $Student.Iemail,$Guardianemail)
            }
            ElseIf ($null -cne $StudentGuardianInvitation)
            {
                #Write-Host -Object ("{0} already invite {1}" -f $Student.Iemail,$Guardianemail)
            }
            ElseIf ([String]::IsNullOrWhiteSpace($Guardianemail))
            {
                Write-Verbose -Message ("Skipping {0} for empty email" -f $GuardianId)
            }
            ElseIf ($Guardianemail -in $InvSented)
            {
                Write-Verbose -Message ("Already sented {0} an invite" -f $Guardianemail)
            }
            Else
            {
                $InvSented += $Guardianemail
                New-GSStudentGuardianInvitation -StudentId $Student.email -GuardianEmail $Guardianemail
                Write-Host -Object ("{0} invited {1}" -f $Student.email,$Guardianemail)
            }
        } -End {
        } -Verbose
    } -End {
    } #-Verbose
    Write-Host -Object ("Sent out {0} Guardian Invitations" -f $invs.Count)

    return $invs
}

$r = Invite_guardian -WorkFolder $WorkFolder -Verbose