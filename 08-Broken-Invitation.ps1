Import-Module PSGSuite
Get-Module -Name PSGSHelp | Remove-Module
Import-Module $PSScriptRoot\PSGSHelp.psm1

$TLOG = ((".\Logs\" + (Get-Date -Format u) +"-Cleanup.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Inquire"

Function remove_invitation
{
    [OutputType('Google.Apis.Classroom.v1.Data.Invitation')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [Google.Apis.Classroom.v1.Data.Invitation]
        $Invitation,
        [Parameter(Mandatory=$true)]
        [Int32]$Invite_Count
    )
    BEGIN
    {
        $Invite_Counter = 0
        Write-Host -Object "Removing Google Classroom Invitations"
        Write-Progress -Activity "Removing Broken Google Classroom invitations" -Status "Processs $($Invites_Count) Invites" -Id 0 -PercentComplete 0
    }
    PROCESS
    {
        $c = $null
        $c = Get-_GSCourse -Id $Invitation.CourseId
        If ($null -eq $c)
        {
            Write-Warning "Failled to get Course Status on $($Invitation.CourseId)"
            $Count_Counter += 1
            Return $Invitation
        }
        Write-Progress -Activity "Removing Broken Google Classroom invitations" -Status "Invite $($Invite_Counter + 1) of $($Invite_Count): $($c.Name)" -Id 0 -PercentComplete (($Invite_Counter * 100) /$Invite_Count)
        $Invite_Counter += 1
        $s = $c.CourseState
        If ($s -eq "_PROVISIONED_")
        {
            return
        }
        $o = Get-GSClassroomUserProfile -UserId $c.OwnerId
        If ($s -notin ("ACTIVE"))
        {
            [console]::TreatControlCAsInput = $true
            $c = Update-GSCourse -Id $c.Id -CourseState PROVISIONED
        }
        $r = @()
        $r += $Invitation | Remove-_GSCourseInvitation -User $o.EmailAddress
        If ($c.CourseState -ne $s)
        {
            $c = Update-GSCourse -Id $c.Id -CourseState $s
            [console]::TreatControlCAsInput = $false
        }
        If ($r.Count -gt 0)
        {
            Return $r
        }
    }
    END
    {
        Write-Progress -Activity "Removing Broken Google Classroom invitations" -Status "Done" -Id 0 -Completed
        Write-Host -Object "Done removing Invitations"
    }
}
Function broken_invitation
{
    If ((Show-PSGSuiteConfig | Select-Object -ExpandProperty ConfigName) -ne "TEACHERS")
    {
        Write-Host -Object "Switching to TEACHERS"
        Set-PSGSuiteConfig -ConfigName TEACHERS -ErrorAction Continue
    }
    $basepath = "."
    $Invite_Broken = Join-Path -Path $basepath -ChildPath "Broken_Invite.xml"

    $Invites_B = @()
    If (Test-Path -Path $Invite_Broken -PathType Leaf)
    {
        Write-Host -Object "Importing broken invites"
        $Invites_B += Import-Clixml -Path $Invite_Broken
    }
    Else
    {
        Write-Host -Object "No broken invites"
        Return
    }

    $r = @()
    $r += $Invites_B | remove_invitation -Invite_Count $Invites_B.Count

    If ($r.Count -gt 0)
    {
        $r | Export-Clixml -Path $Invite_Broken
    }
    Else
    {
        Remove-Item -Path $Invite_Broken -Force | Out-Null
    }
}

$r = broken_invitation