Using module .\OneRoster.psm1

Param(
    [String]$InputFolder = $null,
    [String]$OutputFolder = ".\gclass-OneRoster\",
    [String]$OrgFilter = ""
)

Get-Module -Name OneRoster| Remove-Module; Import-Module .\OneRoster.psm1

$TLOG = ((".\Logs\" + (Get-Date -Format u) +"-Filter.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

If (Test-Path -Path variable:global:psISE)
{
    $ErrorActionPreference = "Inquire"
}
Else
{
    $ErrorActionPreference = "Stop"
}

Function main_split_by_org
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [String]$InputFolder = ".",
        [Parameter(Mandatory = $false)]
        [String]$OutputFolder = ".",
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]$OrgFilter = ""
    )
    PROCESS
    {
        $Orgs = $null
        If ($OrgFilter -EQ "")
        {
            $Orgs = Find-OROrgs -FolderPath $InputFolder
        }
        Else
        {
            $Orgs = Find-OROrgs -FolderPath $InputFolder | Where-Object -FilterScript {($_.sourcedId -eq $OrgFilter) -or ($_.parentSourcedId -eq $OrgFilter)}
        }
        Write-Host -Object "Spliting Courses"
        $Orgs | Split-ORCourses -SourceFolderPath $InputFolder -DestFolderPath $OutputFolder -XMLOutput $true -ErrorAction Continue
        Write-Host -Object "Spliting Classes"
        $Orgs | Split-ORClasses -SourceFolderPath $InputFolder -DestFolderPath $OutputFolder -XMLInput $false -XMLOutput $true
        Write-Host -Object "Spliting Enrollments"
        $Orgs | Split-OREnrollments -SourceFolderPath $InputFolder -DestFolderPath $OutputFolder -XMLInput $true -XMLOutput $true
        Write-Host -Object "Spliting Users"
        $Orgs | Split-ORUSers -SourceFolderPath $InputFolder -DestFolderPath $OutputFolder -XMLInput $true -XMLOutput $true
    }
}

Function process_fixup_user
{
    [OutputType('OR_User')]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline=$true)]
        [OR_User]
        $user_E
    )
    BEGIN
    {
        Write-Progress -Activity "Fixing up user email addresses" -Status "Processing" -Id 0
        $TEACHERS_Domain = Get-PSGSuiteConfig -ConfigName TEACHERS -PassThru | Select-Object -ExpandProperty Domain
        $STUDENTS_Domain = Get-PSGSuiteConfig -ConfigName STUDENTS -PassThru | Select-Object -ExpandProperty Domain
        $TEACHERS_Domain_omc = $($TEACHERS_Domain -replace "\.", "") + ".onmicrosoft.com"
    }
    PROCESS
    {
        If ($user_E.role -In ([OR_RoleType]::parent,[OR_RoleType]::guardian,[OR_RoleType]::relative))
        {
            Write-Progress -Activity "Fixing up user email addresses" -Id 0 -CurrentOperation $user_E.sourcedId
            Return $user_E
        }
        If ($user_E.email -like "*Clerk.view@$($TEACHERS_Domain)")
        {
            $user_E.role = [OR_RoleType]::null
        }
        If ($user_E.role -eq [OR_RoleType]::student)
        {
            If ($false -eq $user_E.enabledUser)
            {
                Write-Progress -Activity "Fixing up user email addresses" -Id 0 -CurrentOperation "Skipping"
                Write-Verbose "Skipping disabled user: $($user_E.email)"
                Return
            }
            Write-Progress -Activity "Fixing up user email addresses" -Id 0 -CurrentOperation $user_E.sourcedId
            $ID_EMAIL = "$($user_E.identifier)@$($STUDENTS_Domain)"
            If ($ID_EMAIL -cne $user_E.email)
            {
                Write-Warning "Student #$($user_E.identifier) have the wrong email address"
                $user_E.email = $ID_EMAIL
            }
            Return $user_E
        }
        Write-Progress -Activity "Fixing up user email addresses" -Id 0 -CurrentOperation $user_E.email
        If ($user_E.email -like "*@$($TEACHERS_Domain)")
        {
            Return $user_E
        }
        If ($user_E.email -like "*@$($TEACHERS_Domain_omc)")
        {
            $user_E.email = $user_E.email -replace "@$($TEACHERS_Domain_omc)","@$($TEACHERS_Domain)"
            Return $user_E
        }
        If ($user_E.email -like "*@*.$($TEACHERS_Domain)")
        {
            Return $user_E
        }
        If ($true -eq $user_E.enabledUser)
        {
            Write-Warning "Found active user outside of domain: $($user_E.email): $($user_E.sourcedId)"
        }
        Return
    }
    END
    {
        Write-Progress Activity "Fixing up user email addresses" -Id 0 -Completed
    }
}

Function main_fixup_users
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [String]$InputFolder = ".",
        [Parameter(Mandatory = $false)]
        [String]$OutputFolder = ".",
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]$OrgFilter = ""
    )
    PROCESS
    {
        $Users_O_FP = Join-Path -Path $OutputFolder -ChildPath "users.xml"
        Write-Host -Object "Fixup Users: Loading"
        If ($OrgFilter -EQ "")
        {
            Read-ORUsers -FolderPath $InputFolder  | process_fixup_user | Export-Clixml -Path $Users_O_FP -Depth 2 -Encoding UTF8
        }
        Else
        {
            Read-ORUsers -FolderPath $InputFolder | Where-Object -FilterScript {$OrgFilter -In $_.orgSourcedIds} | process_fixup_user | Export-Clixml -Path $Users_O_FP -Depth 2 -Encoding UTF8
        }
        Write-Host -Object "Fixup Users: Done"
    }
}

Function process_fixup_enrollment
{
    [OutputType('OR_enrollment')]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline=$true)]
        [OR_enrollment]
        $enrollment_E,
        [String]
        $FolderPath_O
    )
    BEGIN
    {
        Write-Progress -Activity "Fixing up enrollments" -Status "Now Loading Users" -Id 0
        $users_I = Read-ORUsers -FolderPath $FolderPath_O -LoadXML $true
        Write-Progress -Activity "Fixing up enrollments" -Status "Building User list" -Id 0
        $users_L = $users_I.sourcedId
        Write-Progress -Activity "Fixing up enrollments" -Status "Building User Lookup" -Id 0
        $users_G = $users_I | Group-Object -Property sourcedId -AsHashTable
        $Missing = @()
        $Inactive = @()
    }
    PROCESS
    {
        $sourcedId = $enrollment_E.sourcedId
        $userSourcedId = $enrollment_E.userSourcedId
        Write-Progress -Activity "Fixing up enrollments" -Status "Looking for $($userSourcedId) in Users.csv for $($sourcedId)" -Id 0
        If ($userSourcedId -notin $users_L)
        {
            If ($userSourcedId -Notin $userSourcedId)
            {
                Write-Warning "User Id missing: $($userSourcedId)"
                $Missing += $userSourcedId
            }
            $enrollment_E.role = [OR_RoleType]::null
        }
        else
        {
            $user_R = $users_G[$userSourcedId]
            If ($false -eq $user_R.enabledUser -and $userSourcedId -notin $Inactive)
            {
                Write-Warning "disabled user used: $($user_R.email)"
                $Inactive += $userSourcedId
            }
        }
        Return $enrollment_E
    }
    END
    {
        Write-Progress -Activity "Fixing up enrollments" -Id 0 -Completed
    }
}


Function process_fixup_classes
{
    [OutputType('OR_class')]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline=$true)]
        [OR_class]
        $Class_E,
        [String]
        $FolderPath_O
    )
    BEGIN
    {
        Write-Progress -Activity "Fixing up classes" -Status "Now Loading enrollments" -Id 0
        $enrollments_I = Read-ORenrollments -FolderPath $FolderPath_O
        Write-Progress -Activity "Fixing up classes" -Status "Loaded Classes and enrollments" -Id 0
        $enrollments_IP = $enrollments_I | Where-Object -Property primary -EQ -Value $true
        $enrollments_IS = $enrollments_I | Where-Object -Property role -EQ -Value "student"
        $enrollments_LP = $enrollments_IP.classSourcedId
        $enrollments_LS = $enrollments_IS | Group-Object -Property classSourcedId -NoElement | Select-Object -ExpandProperty Name
        $Org_I = Read-OROrgs -FolderPath $FolderPath_O
    }
    PROCESS
    {
        $classsourcedId = $Class_E.sourcedId
        $classtitle = $Class_E.title
        $schoolId = $Class_E.schoolSourcedId
        $Org = $Org_I | Where-Object -Property sourcedId -EQ -Value $schoolId
        Write-Progress -Activity "Fixing up classes" -Status "Looking for $($classsourcedId) in Enrollments.csv for: $($classtitle)" -Id 0
        If (($classsourcedId -notin $enrollments_LP))
        {
            If ($classsourcedId -in $enrollments_LS)
            {
                Write-Warning "Primary teacher for missing: $($Org.sourcedId)/$($classsourcedId): $($Org.name)/$($classtitle)"
            }
            Else
            {
                Write-Warning "students for missing: $($Org.sourcedId)/$($classsourcedId): $($Org.name)/$($classtitle)"
            }
        }
        Return $Class_E
    }
    END
    {
        Write-Progress -Activity "Fixing up classes" -Id 0 -Completed
    }
}


Function main_fixup_enrollments
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [String]$InputFolder = ".",
        [Parameter(Mandatory = $false)]
        [String]$OutputFolder = "."
    )
    PROCESS
    {
        $enrollments_O_FP = Join-Path -Path $OutputFolder -ChildPath "enrollments.xml"
        Write-Host -Object "Fixup enrollments: Loading"
        $BeginLayway = [TimeSpan]::FromDays(21)
        $EndLayway = [TimeSpan]::FromDays(-7)
        Read-ORenrollments -FolderPath $InputFolder | Limit-OREnrollmentByDate -BeginLayway $BeginLayway -EndLayway $EndLayway | process_fixup_enrollment -FolderPath_O $OutputFolder | Export-Clixml -Path $enrollments_O_FP
        Write-Host -Object "Fixup enrollments: Done"
    }
}

Function main_fixup_classes
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [String]$InputFolder = ".",
        [Parameter(Mandatory = $false)]
        [String]$OutputFolder = ".",
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [String]$OrgFilter = ""
    )
    PROCESS
    {
        $classes_O_FP = Join-Path -Path $OutputFolder -ChildPath "classes.xml"
        Write-Host -Object "Fixup classes: Loading"
        If ($OrgFilter -EQ "")
        {
            Read-ORclasses -FolderPath $InputFolder | process_fixup_classes -FolderPath_O $OutputFolder | Export-Clixml -Path $classes_O_FP
        }
        Else
        {
            Read-ORclasses -FolderPath $InputFolder | Where-Object -Property schoolSourcedId -EQ -Value $OrgFilter | process_fixup_classes -FolderPath_O $OutputFolder | Export-Clixml -Path $classes_O_FP
        }
        Write-Host -Object "Fixup classes: Done"
    }
}

Function main_copy_csv
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [String]$InputFolder = ".",
        [Parameter(Mandatory = $false)]
        [String]$OutputFolder = "."
    )
    PROCESS
    {
        Get-ChildItem -Path $InputFolder -Filter "*.csv" -Depth 0 -File | Copy-Item -Destination $OutputFolder -Force -Container
    }
}

Function main
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$InputFolder,
        [Parameter(Mandatory = $true)]
        [String]$OutputFolder,
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]$OrgFilter
    )
    PROCESS
    {
        If (-Not (Test-Path -Path $OutputFolder -PathType Container))
        {
            New-Item -Path $OutputFolder -ItemType Directory -Force -Verbose | Out-Null
        }
        main_copy_csv -InputFolder $InputFolder -OutputFolder $OutputFolder
        If ($OrgFilter -ne "")
        {
            Write-Host -Object "Filtering ORGS file with filter: $($OrgFilter)"
            $FilteredOrgs = Read-OROrgs -FolderPath $InputFolder | Where-Object -FilterScript {($_.parentSourcedId -eq $OrgFilter) -or ($_.sourcedId -eq $OrgFilter)}
            Write-Host -Object "Filtered ORGS file down to $($FilteredOrgs.Count)"
            $FilteredOrgs | Out-ORorg -FilePath (Join-Path -Path $OutputFolder -ChildPath "orgs.csv")
        }
        main_fixup_users -InputFolder $InputFolder -OutputFolder $OutputFolder -OrgFilter $OrgFilter
        main_fixup_enrollments -InputFolder $InputFolder -OutputFolder $OutputFolder
        main_fixup_classes -OutputFolder $OutputFolder -OrgFilter $OrgFilter
        main_split_by_org -InputFolder $OutputFolder -OutputFolder $OutputFolder -OrgFilter $OrgFilter
    }
}

Function filter_empty_class #TODO
{
    [OutputType('Object')]
    Param
    (
        [parameter(Mandatory = $true, ValueFromPipeline=$true)]
        [Object]
        $Classes_I,
        [parameter(Mandatory = $true)]
        [Object]
        $Enrollments_I,
        [Parameter(Mandatory=$true)]
        [Int32]$Class_Count
    )
    BEGIN
    {
        Write-Progress -Activity "Filtering out classrooms without a teacher" -Status "Ready" -Id 0 -PercentComplete 0
        $enrollments_T = @()
        $enrollments_T += $enrollments_I | Where-Object -Property role -EQ -Value ([OR_RoleType]::teacher)
        $enrollments_PT = @()
        $enrollments_PT += $enrollments_T | Where-Object -Property primary -EQ -Value $true
        $enrollments_CT = @()
        $enrollments_CT += $enrollments_T | Where-Object -Property primary -EQ -Value $false
        $Enrollments_S = @()
        $Enrollments_S += $Enrollments_I |  Where-Object -Property role -EQ -Value ([OR_RoleType]::student)
        Write-Progress -Activity "Filtering out classrooms without a teacher" -Status "Processing $($Class_Count)" -Id 0 -PercentComplete 0
    }
    PROCESS
    {
        Write-Progress -Activity "Filtering out classrooms" -Status "Classroom $($Class_Counter + 1) of $($Class_Count): $($Classes_I.Title)" -Id 0 -PercentComplete (($Class_Counter * 100) /$Class_Count)
        $Class_Counter += 1
        $Enrollments_PT_ = @()
        Write-Progress -Activity "Filtering out classroomser" -Id 0 -CurrentOperation "Filtering Primary Teachers Enrollments"
        $Enrollments_PT_ += $Enrollments_PT  | Where-Object -Property classSourcedId -CIn $Classes_I.sourcedid
        If ($Enrollments_PT_.Count -eq 0)
        {
            Return
        }
        Return $Classes_I
        $Enrollments_S_ = @()
        Write-Progress -Activity "Filtering out classrooms" -Id 0 -CurrentOperation "Filtering Student Enrollments"
        $Enrollments_S_ += $Enrollments_S  | Where-Object -Property classSourcedId -In $Classes_I.sourcedid
        If ($Enrollments_S_.Count -eq 0)
        {
            #Return
        }
        Return $Classes_I
        $Enrollments_CT_ = @()
        Write-Progress -Activity "Filtering out classrooms" -Id 0 -CurrentOperation "Filtering Co- Teachers Enrollments"
        $Enrollments_CT_ += $Enrollments_CT  | Where-Object -Property classSourcedId -In $Classes_I.sourcedid
    }
    END
    {
        Write-Progress -Activity "Filtering out classrooms without a teacher" -Status "Done" -Id 0 -Completed
    }
}

main -InputFolder $InputFolder -OutputFolder $OutputFolder -OrgFilter $OrgFilter
