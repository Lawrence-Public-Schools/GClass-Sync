Using module .\OneRoster.psm1

Param(
    [String]$WorkFolder = ".\gclass-OneRoster"
)

Get-Module -Name OneRoster| Remove-Module; Import-Module .\OneRoster.psm1

Import-Module PSGSuite
Get-Module -Name PSGSHelp | Remove-Module
Import-Module $PSScriptRoot\PSGSHelp.psm1

$TLOG = ((".\Log\" + (Get-Date -Format u) +"-Admins.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Inquire"

Function Make_class_alias()
{
    [OutputType('String')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$ClassId
    )
    BEGIN
    {
    }
    PROCESS
    {
        Return "d:PowerSchool-class_id-$($ClassId)"
    }
    END
    {
    }
}

function Add_Admins_to_Org
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$WorkFolder
    )
    If ($(Show-PSGSuiteConfig).ConfigName -ne "TEACHERS")
    {
        Write-Host -Object "Switching to TEACHERS"
        Set-PSGSuiteConfig TEACHERS
    }

    $Admins_CSV = Join-Path -Path "." -ChildPath "Admins.csv"
    If (-not (Test-Path -Path $Admins_CSV -PathType Leaf))
    {
        Write-Host -Object "No Admins.csv was found"
        Return
    }
    $Admins = Import-Csv -Path $Admins_CSV
    If ($Admins.Count -eq 0)
    {
        Write-Host -Object "Empty Admins.CSV file"
        Return
    }
    $SchoolFilter = $Admins.orgSourcedId
    $r = Read-OROrgs -FolderPath $WorkFolder | Where-Object -Property sourcedId -In $SchoolFilter | ForEach-Object -Begin {
        Write-Host -Object "Looking at Google Classroom to add Admins"
        $GoodLink = (Import-Clixml -Path "Cache_ClassLink.xml") | Where-Object -Property CourseState -In -Value ("ACTIVE", "_PROVISIONED")
        $FakeTeacher = "test.staff@$($Default_Domain)"
        $FakeProfile = $FakeTeacher | Get-_GSClassroomUserProfile #-BypassCache $true -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile
    } -Process {
        $Org = $_
        Write-Host -Object "Looking at $($Org.name)"
        $Admins_F = @()
        $Admins_F += $Admins | Where-Object -Property orgSourcedId -CEQ $Org.sourcedId
        If ($Admins_F.Count -eq 0)
        {
            Return
        }
        $Classes = @()
        $Classes += Read-ORclasses -FolderPath $WorkFolder -Org $Org -LoadXML $true | Where-Object sourcedId -In $GoodLink.sourcedId
        If ($Classes.Count -eq 0)
        {
            Return
        }
        $Classes.sourcedId | Make_class_alias | ForEach-Object {
            $GSCourse_ID = $_
            $Teachers = @()
            $Teachers += Get-_GSCourseParticipant -CourseId $GSCourse_ID -Role Teacher
            $Admins_Add = $Admins_F | Where-Object -Property email -NotIn $Teachers.Profile.EmailAddress
            If ($Admins_Add.Count -eq 0)
            {
                Return
            }
            $Admins_Add | ForEach-Object {
                Add-GSCourseParticipant -CourseId $GSCourse_ID -Teacher $_.email -Verbose
            }
        }
    } -Verbose
    Return $r
}

$r = Add_Admins_to_Org -WorkFolder $WorkFolder