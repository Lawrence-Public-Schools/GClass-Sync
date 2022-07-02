﻿Using module .\OneRoster.psm1

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
        $SStudentGuardianInvitations = @()
        $StudentGuardians += Get-GSStudentGuardian -StudentId $Student.email
        $StudentGuardianInvitations += Get-GSStudentGuardianInvitation -StudentId $Student.email
        $Student.agentSourcedIds | ForEach-Object -Begin {
            $InvSented = @()
        } -Process {
            $GuardianId = $_
            $Guardian = $null
            $StudentGuardian = $null
            If ($GUsersHT.ContainsKey($GuardianId))
            {
                $Guardian = $GUsersHT[$GuardianId]
                $StudentGuardian = $StudentGuardians | Where-Object -Property InvitedEmailAddress -EQ -Value $Guardian.email
                $StudentGuardianInvitation = $StudentGuardianInvitations | Where-Object -Property InvitedEmailAddress -EQ -Value $Guardian.email
            }
            If ($Guardian -ceq $null)
            {
                Write-Verbose -Message ("Skipping {0} for blan email" -f $GuardianId)
            }
            ElseIf ($StudentGuardian -cne $null)
            {
                #Write-Host -Object ("{0} already have {1}" -f $Student.Iemail,$Guardian.email)
            }
            ElseIf ($StudentGuardianInvitation -cne $null)
            {
                #Write-Host -Object ("{0} already invite {1}" -f $Student.Iemail,$Guardian.email)
            }
            ElseIf ([String]::IsNullOrWhiteSpace($Guardian.email))
            {
                Write-Verbose -Message ("Skipping {0} for empty email" -f $GuardianId)
            }
            ElseIf ($Guardian.email -in $InvSented)
            {
                Write-Verbose -Message ("Already sented {0} an invite" -f $Guardian.email)
            }
            Else
            {
                $InvSented += $Guardian.email
                New-GSStudentGuardianInvitation -StudentId $Student.email -GuardianEmail $Guardian.email
                Write-Host -Object ("{0} invited {1}" -f $Student.email,$Guardian.email)
            }
        } -End {
        } -Verbose
    } -End {
    } #-Verbose
    Write-Host -Object ("Sent out {0} Guardian Invitations" -f $invs.Count)

    return $invs
}

$r = Invite_guardian -WorkFolder $WorkFolder -Verbose