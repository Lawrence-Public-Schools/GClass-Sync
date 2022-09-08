Import-Module PSGSuite
Get-Module -Name PSGSHelp | Remove-Module
Import-Module $PSScriptRoot\PSGSHelp.psm1

$TLOG = ((".\Logs\" + (Get-Date -Format u) +"-Confirm.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Inquire"

Function eat_invitation
{
    #[OutputType('Void')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$User,
        [Parameter(Mandatory=$true)]
        [Int32]$User_Count
    )
    BEGIN
    {
        $User_Counter = 0
        Write-Host -Object "Loading CourseLink"
        $CourseLink = Import-Clixml -Path "Cache_ClassLink.xml"
        $GoodLink = $CourseLink | Where-Object CourseState -In ("ACTIVE", "PROVISIONED_")
        Write-Host -Object "Confirming Google Classroom invitations"
        Write-Progress -Activity "Confirming Google Classroom invitations" -Status "Processsing $($User_Count) Users" -Id 0 -PercentComplete 0
    }
    PROCESS
    {
        Write-Progress -Activity "Confirming Google Classroom invitations" -Status "User $($User_Counter + 1) of $($User_Count): $($User)" -Id 0 -PercentComplete (($User_Counter * 100) /$User_Count)
        $User_Counter += 1
        $i = @()

        $i += Get-_GSCourseInvitationByUser -UserId $User
        If ($i.Count -gt 0)
        {
            #Write-Verbose -Message "Found $($i.Count) Invite(s) for                           : $($User)"
        }
        Else
        {
            Return
            Write-Host -Object     "Found no Invitations                            : $($User)"
        }

        $b = @()
        #$b += $i | Where-Object -Property CourseId -NotIn $GoodLink.CourseId
        If ($b.Count -gt 0)
        {
            Write-Verbose "Deleting outside $($b.Count) Invitation(s): $($User)"
            $b | Remove-_GSCourseInvitation -user $User | Out-Null
        }

        $g = $i | Where-Object -Property CourseId -In $GoodLink.CourseId
        $r = @()
        If ($g.Count -gt 0)
        {
            Write-Host -Object "Confirming $($g.Count) Invite(s) for $($User)"
            $r += $g | Confirm-_GSCourseInvitation -User $User
        }
        Else
        {
            #Write-Verbose "Found no Invitations under PowerSchool's control: $($User)"
        }

        $b = @()
        $b += $g | Where-Object -Property Id -NotIn $r.Id
        If ($b.Count -gt 0)
        {
            #Write-Host -Object "Found $($b.Count) broken invites"
            #$r | ConvertTo-Json | Write-Warning
            #Return $b
        }
    }
    END
    {
        Write-Progress -Activity "Confirming Google Classroom invitations" -Status "Done" -Id 0 -Completed
        Write-Host -Object "Done confirming invitations"
    }
}

Function confirm_invitation
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$false)]
        [String]$ConfigProfile = "STUDENTS"
    )
    If ((Show-PSGSuiteConfig | Select-Object -ExpandProperty ConfigName) -ne $ConfigProfile)
    {
        Write-Host -Object "Switching to $($ConfigProfile)"
        Switch-PSGSuiteConfig -ConfigName $ConfigProfile
    }
    $basepath = "."
    $Invite_File = Join-Path -Path $basepath -ChildPath "TODO_Invite.xml"
    $Invite_Broken = Join-Path -Path $basepath -ChildPath "Broken_Invite.xml"

    $users_N = @()
    $outsiders_N = @()
    If (Test-Path -Path $Invite_File -PathType Leaf)
    {
        $Invite_Data = @()
        $Invite_Data += Import-Clixml -Path $Invite_File | Sort-Object | Sort-Object -Unique
        $Default_Domain = (Show-PSGSuiteConfig).Domain
        $users_N += $Invite_Data -like "*@$($Default_Domain)"
        $outsiders_N += $Invite_Data -notlike "*@$($Default_Domain)"
    }

    $r = @()
    $b = @()
    If (Test-Path -Path $Invite_Broken -PathType Leaf)
    {
        $r += Import-Clixml -Path $Invite_Broken
    }
    If ($users_N.Count -gt 0)
    {
        Write-Host -Object "Look thur $($users_N.Count) User accounts"
        $r += $users_N | eat_invitation -User_Count $users_N.Count -Verbose
    }

    If ($outsiders_N.Count -eq 0)
    {
        Remove-Item -Path $Invite_File -ErrorAction SilentlyContinue| Out-Null
    }
    Else
    {
        $outsiders_N |  Export-Clixml -Path $Invite_File
    }

    If ($r.Count -gt 0)
    {
        Write-Host -Object "Found Broken Classroom Invites"
        $r | Sort-Object -Property CourseId,UserId,Id,Role,ETag | Export-Clixml -Path $Invite_Broken
    }
    ElseIf (Test-Path -Path $Invite_Broken -PathType Leaf)
    {
        Remove-Item -Path $Invite_Broken -Force | Out-Null
    }
}

$r = confirm_invitation
#$r = confirm_invitation -ConfigProfile TEACHERS