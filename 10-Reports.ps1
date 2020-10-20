Using module .\OneRoster.psm1

Param(
    [String]$WorkFolder = ".\gclass-OneRoster",
    [String]$ReportFolder = ".\Reports"
)

Get-Module -Name GClass | Remove-Module; Import-Module .\GClass.psm1

$Parameters = "classroom:num_courses_created,classroom:num_posts_created,classroom:role,classroom:last_interaction_time,accounts:admin_set_name,accounts:first_name,accounts:last_name,accounts:last_login_time,accounts:last_sso_time"

$TLOG = ((".\Log\" + (Get-Date -Format u) +"-Report.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

#$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Inquire"

function Reports_Classroom_Usage
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$WorkFolder,
        [Parameter(Mandatory = $true)]
        [String]$Domain,
        [Parameter(Mandatory = $true)]
        [String]$ReportFolder
    )
    If ($(Show-PSGSuiteConfig).ConfigName -ne $Domain)
    {
        Write-Host -Object "Switching to $($Domain)"
        Set-PSGSuiteConfig $Domain
        $DNSDomain = $(Show-PSGSuiteConfig).Domain
    }

    If ((Test-Path -Path $ReportFolder -PathType Leaf))
    {
        Write-Error "Report Folder ($ReportFolder) is a file, not a folder"
        Return
    }
    ElseIf (-not (Test-Path -Path $ReportFolder -PathType Container))
    {
        New-Item -Path $ReportFolder -ItemType Directory | Out-Null
    }

    $Sessions = Read-ORAcademicSessions -FolderPath $WorkFolder
    $schoolYears = $Sessions | Where-Object -Property type -EQ -Value ([OR_SessionType]::schoolYear)
    $startDate = $schoolYears[-1].startDate

    $Date = (Get-Date).AddDays(-7)
    $Date.AddHours(0 - $Date.Hour)
    $Date.AddHours(0 - $date.Minute)
    $Date.AddMilliseconds(0 - $Date.Millisecond)

    $r = Read-OROrgs -FolderPath $WorkFolder | ForEach-Object {
        $org_ = $_
        $Users_F = @()
        $Users_F += Read-ORUsers -FolderPath $WorkFolder -Org $org_ -LoadXML $true | Where-Object -Property email -Like "*@$($DNSDomain)"
        If ($Users_F.Count -eq 0)
        {
            Return
        }
        $Reports = $Users_F.email | ForEach-Object {
            Get-GSUsageReport -UserKey $_ -Date $Date -Parameters $Parameters -Flat:$true
        }
        $Report_FP = Join-Path -Path $ReportFolder -ChildPath "$($Domain)_$($org_.sourcedId).xml"
        $Reports | Export-Clixml -Path $Report_FP -Encoding UTF8
        $Report_FP = Join-Path -Path $ReportFolder -ChildPath "$($Domain)_$($org_.sourcedId).csv"
        $Reports | Select-Object -Property UserEMail,accounts:*,classroom:* | Export-Csv -Path $Report_FP -NoTypeInformation
    }
    Return $r
}

Function Classroom_Listing {
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$WorkFolder,
        [Parameter(Mandatory = $true)]
        [String]$Domain,
        [Parameter(Mandatory = $true)]
        [String]$ReportFolder
    )
    
    #If ($(Show-PSGSuiteConfig).ConfigName -ne $Domain)
    #{
    #    Write-Host -Object "Switching to $($Domain)"
    #    Set-PSGSuiteConfig $Domain
    #    $DNSDomain = $(Show-PSGSuiteConfig).Domain
    #}
    
    $Report_FP = Join-Path -Path $ReportFolder -ChildPath "Listing.csv"
    Read-ORclasses -FolderPath $WorkFolder -LoadXML $true | ForEach-Object -Begin {
        Write-Host -Object "Loadding Schools"
        $School = Read-OROrgs -FolderPath $WorkFolder | Group-Object -Property sourcedId -AsHashTable
        Write-Host -object "Loading ClassLink"
        $ClassLink  = (Import-ClassLink) | Group-Object -Property sourcedId -AsHashTable
        Write-Host -Object "Making Class Report listing"
        $New_Row = [PSCustomObject]@{
            "School"    = $null
            "Name"      = $null
            "Period"    = $null
            "Section"   = $null
            "Code"      = $null
            "State"     = $null
            "Lead"      = $null
                                   }
    } -Process {
        $Class_S = $_.title.SpliT("|")
        $Row = $New_Row.PsObject.Copy()
        $Row.School = $School[$_.schoolSourcedId].name
        $Row.Name = $Class_S[-3].Trim()
        $Row.Period = (($Class_S[-2].Trim()) -replace "Per ","")
        $Row.Section = (($Class_S[-1].Trim()) -replace "Sec ","")
        $Row.Code = $ClassLink[$_.sourcedId].EnrollmentCode
        $Row.State = $ClassLink[$_.sourcedId].CourseState
        $Row.Lead = $ClassLink[$_.sourcedId].EmailAddress
        $Row
    } -End {
        Write-Host -Object "Done with making Classroom report"
    } -Verbose | Export-Csv -LiteralPath $Report_FP -Encoding UTF8 -NoTypeInformation
}

#$r = Reports_Classroom_Usage -WorkFolder $WorkFolder -Domain  -ReportFolder $ReportFolder
#$r = Reports_Classroom_Usage -WorkFolder $WorkFolder -Domain STUDENTS -ReportFolder $ReportFolder
$r = Classroom_Listing -WorkFolder $WorkFolder -Domain TEACHERS -ReportFolder $ReportFolder