Using module .\OneRoster.psm1

Param(
    [String]$WorkFolder = ".\gclass-OneRoster\"
)

Get-Module -Name GClass | Remove-Module; Import-Module .\GClass.psm1

$TLOG = ((".\Log\" + (Get-Date -Format u) +"-Roster.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Inquire"

Function invite_class_student()
{
    [OutputType('student')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [OR_class]
        $Class,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [OutputType('System.Collections.Hashtable')]
        $Cache_CourseAlias,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        $Cache_Course,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [Object]
        $Cache_ClassroomUserProfile,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [Object]
        $Cache_Teachers,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [Object]
        $Cache_Students,
        [String]$WorkFolder = ".",
        [Parameter(Mandatory=$true)]
        [Int32]$Class_Count = 0,
        [Parameter(Mandatory=$true)]
        [OR_Org]$Org
    )
    BEGIN
    {
        $Class_Counter = 0
        Write-Progress -Activity "Resync Student enrollments in Google Classroom" -Status "Started" -Id 0 -PercentComplete 0
        Write-Host -Object "Importing enrollments"
        $enrollments_I = Read-ORenrollments -FolderPath $WorkFolder -Org $Org -LoadXML $true
        Write-Host -Object "Filtering enrollments for primary teachers, normal teachers, aides then admins"
        $enrollments_F = $enrollments_I | Limit-OREnrollmentByrole -role teacher,aide,administrator
        $enrollments_O = @()
        $enrollments_S = $enrollments_F| Limit-OREnrollmentIsPrimary -primary $false
        $enrollments_O += $enrollments_F | Limit-OREnrollmentOnlyPrimaryTeacher
        $enrollments_O += $enrollments_S | Limit-OREnrollmentByrole -role teacher
        $enrollments_O += $enrollments_S | Limit-OREnrollmentByrole -role aide
        $enrollments_O += $enrollments_S | Limit-OREnrollmentByrole -role administrator
        $enrollments_O_G = $enrollments_O | Group-Object -Property classSourcedId
        Write-Host -Object "Filtering enrollments for students"
        $enrollments_S = $enrollments_I | Limit-OREnrollmentByrole -role student
        Write-Host -Object "Importing users"
        $users_I = Read-ORUsers -FolderPath $WorkFolder -Org $Org -LoadXML $true
        Write-Host -Object "Filtering users for students"
        $users_S = $users_I | Limit-ORUserByRole -role student
        Write-Host -Object "Filtering users for teachers, aides and admins only"
        $users_T = $users_I | Limit-ORUserByRole -role teacher,aide,administrator
        $Default_Domain = (Show-PSGSuiteConfig).Domain
        $Domain_Filter = "*@$($Default_Domain)"
        Write-Host -Object "Checking students in Google Classrooms"
        Write-Progress -Activity "Resync Student enrollments in Google Classroom" -Status "Processing $($Class_Count) Classes" -Id 0 -PercentComplete (($Class_Counter * 100) /$Class_Count)
        $CloseSection = "ERROR AT CLOSING POWERSCHOOL CLASSROOM"
        $ClassLink = Import-ClassLink
        $ClassLink_G = $ClassLink | Group-Object -Property sourcedId -AsHashTable
    }
    PROCESS
    {
        Write-Progress -Activity "Resync Student enrollments in Google Classroom" -Status "Class $($Class_Counter + 1) of $($Class_Count): $($Class.title)" -Id 0 -PercentComplete (($Class_Counter * 100) /$Class_Count)
        $Class_Counter += 1
        $sourcedId = $Class.sourcedId
        $ClassLink_ = $ClassLink_G[$sourcedId] #$ClassLink | Where-Object sourcedId -EQ $sourcedId
        $ClassId = $ClassLink_.CourseAlias

        If ($enrollments_I.Count -eq 0)
        {
            Update-GSCourse -Id $ClassId -CourseState ARCHIVED -Verbose | Out-Null
            Return
        }

        $GCR = @()
        $GCR += Get-_GSCourse -Id $ClassId -CacheOnly $true -Cache_GSCourse $Cache_Course -Cache_GSCourseAlias $Cache_CourseAlias

        If ($GCR.Count -eq 0)
        {
            Write-Host -Object "No Google Classroom for $($Class.sourcedid)"
            Return
        }
        ElseIf ($GCR.Count -ne 1)
        {
            Write-Host -Object "Found more then one Google Classroom for $($Class.sourcedid)"
            Return
        }
        $Teacher = $null
        If ($ClassLink_.Count -eq 1)
        {
            $Teacher = $ClassLink_.EmailAddress
        }
        $enrollments_C = @()
        $users_C = @()
        $enrollments_C_O = @()
        If ($enrollments_O.Count -gt 0 -and $null -eq $Teacher) #Look in the local school cache
        {
            $enrollments_C += ($enrollments_O_G | Where-Object -Property Name -EQ -Value $Class.sourcedId).Group #$enrollments_O | Limit-OREnrollmentByclassSourcedId -classSourcedId $Class.sourcedId
            If ($enrollments_C.Count -gt 0)
            {
                $users_C += $users_T | Limit-ORUserBySourcedId -sourcedId $enrollments_C.userSourcedId
                If ($users_C.Count -gt 0)
                {
                    $enrollments_C_O = $enrollments_C | Where-Object -Property userSourcedId -NotIn $users_S_.sourcedId
                }
                Else
                {
                    $enrollments_C_O = $enrollments_C
                }
            }
        }
        If ($users_C.Count -gt 0)
        {
            $Lookup_E = @()
            $Lookup_E += $enrollments_C | Limit-OREnrollmentOnlyPrimaryTeacher
            $Lookup_U = @()
            If ($Lookup_E.Count -gt 0)
            {
                $Lookup_U += $users_C | Limit-ORUserBySourcedId -sourcedId $Lookup_E.userSourcedId
            }
            If ($Lookup_U.Count -gt 0)
            {
                $Teacher = $Lookup_U[0].email
            }
        }
        If ($null -eq $Teacher)
        {
            $PT = $null
            $PT = Get-_GSClassroomUserProfile -UserId $GCR.OwnerId -BypassCache $true -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile -StoreBad $true
            If ($null -ne $PT -and $PT.EmailAddress -ne "")
            {
                $Teacher = $PT.EmailAddress
            }
        }
        If ($null -eq $Teacher)
        {
            $Teachers = @()
            $Teachers += Get-_GSCourseParticipant -CourseId $ClassId -Role Teacher
            $Teachers_profiles = @()
            $Teachers_profiles += $Teachers.Profile | Where-Object -Property EmailAddress -NE -Value ""
            If ($Teachers_profiles.Count -gt 0)
            {
                $Teacher = $Teachers_profiles[0].EmailAddress
            }
        }
        If ($null -eq $Teacher)
        {
            If ($enrollments_C_O.Count -gt 0)
            {
                Write-Warning "Found Teachers outside the School for $($ClassId)"
                $users_C += $Cache_Teachers | Limit-ORUserBysourcedId -sourcedId $enrollments_C_O.userSourcedId
            }
            If ($users_C.Count -eq 0)
            {
                Write-Warning "No Users account found for $($Class.sourcedid)"
                If ($enrollments_C.Count -gt 0)
                {
                    Write-Warning "There are enrollments records: $($enrollments_C | ConvertTo-Json)"
                }
            }
            Else
            {
                $Teacher = $users_C[0].email
            }
        }
        If ($null -eq $Teacher)
        {
            Write-Host -Object "Could find a teacher to act as in Class: $($Class.sourcedid)"
            Return
        }

        $GCR_Participants = @()
        $GCR_Participants += Get-_GSCourseParticipant -CourseId $ClassId -Role Student
        $GCR_Teachers = @()
        $GCR_Students = @()
        $GCR_Locals = @()
        $Outsiders = @()
        If ($GCR_Participants.Count -gt 0)
        {
            $GCR_AllStudents = $GCR_Participants.UserId | Get-_GSClassroomUserProfile -BypassCache $true -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile -StoreBad $true -CacheOnly $true | Where-Object -FilterScript {$null -ne $_}
            $GCR_Students += $GCR_AllStudents | Where-Object EmailAddress -NotLike $Domain_Filter | Where-Object -Property EmailAddress -NE -Value ""
            $GCR_Locals += $GCR_AllStudents | Where-Object EmailAddress -Like $Domain_Filter
            $Outsiders = $GCR_AllStudents.Profile | Where-Object -Property EmailAddress -EQ -Value ""
        }
        If ($Outsiders.Count -gt 0)
        {
            Write-Warning "Google Classroom $($ClassId) have outsiders as students"
            $Outsiders | ConvertTo-Json | Write-Warning
        }
        $GCR_Invitations = @()
        $GCR_Invitations += Get-_GSCourseInvitation -CourseId $ClassId -Role STUDENT
        $GCR_Incoming = @()
        If ($GCR_Invitations.Count -gt 0)
        {
            $GCR_Invitations_Good = @()
            $GCR_Invitations_Good += $GCR_Invitations | Where-Object -Property UserId -NE -Value "" | Where-Object -Property UserId -NE -Value $null
            If ($GCR_Invitations_Good.Count -gt 0)
            {
                $GCR_Incoming += $GCR_Invitations_Good | Get-_GSClassroomUserProfile -BypassCache $true -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile -StoreBad $true -CacheOnly $true | Where-Object -FilterScript {$null -ne $_}
                #$GCR_Incoming += $GCR_Invitations_Good | ForEach-Object {
                #  return Get-_GSClassroomUserProfile -UserId $_.UserId -BypassCache $true -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile -StoreBad $true
                #} | Where-Object -Property EmailAddress -NE -Value "" | Where-Object -Property EmailAddress -NE -Value $null
            }
            If ($GCR_Incoming.Count -gt 0)
            {
                $GCR_Teachers += $GCR_Incoming | Where-Object -Property EmailAddress -Like -Value $Domain_Filter
                $GCR_Students += $GCR_Incoming | Where-Object -Property EmailAddress -NotLike -Value $Domain_Filter | Where-Object -Property EmailAddress -Like "*@*"
            }
            $GCR_Invitations_Bad = @()
            $GCR_Invitations_Bad += $GCR_Invitations | Where-Object -Property UserId -EQ -Value ""
            $GCR_Invitations_Bad += $GCR_Invitations | Where-Object -Property UserId -EQ -Value $null
            If ($GCR_Invitations_Bad.Count -gt 0)
            {
                $GCR_Invitations_Bad | Remove-_GSCourseInvitation -User $Teacher | Out-Null
            }
            If ($GCR_Teachers.Count -gt 0)
            {
                Write-Warning "There are incoming Teachers for $($ClassId) as Students, converting to Teacher invites: $($GCR_Teachers.EmailAddress -join ",")"
                $GCR_Invitations_Good | Where-Object UserId -IN $GCR_Teachers.Id | Remove-_GSCourseInvitation -User $Teacher | Out-Null
                $GCR_Invitations_Good | Where-Object UserId -IN $GCR_Teachers.Id | New-_GSCourseInvitation -CourseId $ClassId -Role TEACHER -User $Teacher | Out-Null
            }
        }

        $enrollments_S_ = @()
        $enrollments_S_O = @()
        $enrollments_S_ += $enrollments_S | Limit-OREnrollmentByclassSourcedId -classSourcedId $Class.sourcedId
        $users_S_ = @()
        If ($enrollments_S_.Count -gt 0)
        {
            $users_S_ += $users_S | Limit-ORUserBysourcedId -sourcedId $enrollments_S_.usersourcedid
            $enrollments_S_O = $enrollments_S_ | Where-Object -Property userSourcedId -NotIn $users_S_.sourcedId #Limit-OREnrollmentNotByuserSourcedId -userSourcedId $users_S_.sourcedId
        }
        If ($enrollments_S_O.Count -gt 0)
        {
            #Write-Warning "Found Students outside the School for $($ClassId)"
            $users_S_ += $Cache_Students | Limit-ORUserBysourcedId -sourcedId $enrollments_S_O.userSourcedId
        }
        $OR_Students = @()
        If ($users_S_.Count -gt 0)
        {
            $users_S_V = $users_S_.email | Get-_GSClassroomUserProfile -BypassCache $true -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile -StoreBad $true -CacheOnly $true | Where-Object -Property Id -NE -Value $null
            If ($users_S_V.Count -gt 0)
            {
                $OR_Students = $users_S_V
            }
        }
        $CP_Add = @()
        $CP_Del = @()
        If ($OR_Students.Count -gt 0 -and $GCR_Students.Count -gt 0)
        {
            $diff = Compare-Object -ReferenceObject ($OR_Students) -DifferenceObject ($GCR_Students) -Property EmailAddress -Verbose 
            $diff_RO = @()
            $diff_DO = @()
            $diff_RO += $diff | Where-Object -Property SideIndicator -CEQ "<="
            $diff_DO += $diff | Where-Object -Property SideIndicator -CEQ "=>"
            If($diff_RO.Count -gt 0)
            {
                $CP_Add += $diff_RO.EmailAddress
            }
            If($diff_DO.Count -gt 0)
            {
                $CP_Del += $diff_DO.EmailAddress
            }
        }
        ElseIf ($OR_Students.Count -gt 0 -and $GCR_Students.Count -eq 0)
        {
            $CP_Add += $OR_Students.EmailAddress
        }
        ElseIf ($OR_Students.Count -eq 0 -and $GCR_Students.Count -gt 0)
        {
            $CP_Del += $GCR_Students.EmailAddress | Where-Object EmailAddress -NotLike $Domain_Filter
        }

        $DP = @()
        $DS = @()
        $DI = @()
        If ($CP_Del.Count -gt 0)
        {
            $DP += $CP_Del | Get-_GSClassroomUserProfile -BypassCache $true -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile -StoreBad $true -CacheOnly $true
        }
        If ($DP.Count -gt 0)
        {
            $DI += $GCR_Invitations_Good | Where-Object UserId -In $DP.Id | Where-Object UserId -In $GCR_Invitations.UserId
            $DS += $GCR_Students | Where-Object Id -In $DP.Id | Where-Object Id -In $GCR_Participants.UserId
            Write-Warning "Remove Students for $($ClassID): $($DP.EmailAddress -join ",")"
        }
        If ($DI.Count -gt 0)
        {
            $DI | Remove-_GSCourseInvitation -User $Teacher -Verbose | Out-Null
        }
        If ($DS.Count -gt 0)
        {
            $DS | Remove-_GSCourseParticipant -CourseId $ClassId -User $Teacher -Verbose | Out-Null
        }

        $r = @()

        If ($GCR_Incoming.Count -gt 0)
        {
            If ($CP_Del.Count -eq 0)
            {
                $r += $GCR_Students.EmailAddress
            }
            Else
            {
                $More = @() + ($GCR_Students | Where-Object -Property EmailAddress -NotIn -Value $CP_Del)
                If ($More.Count -gt 0)
                {
                    $r += $More.EmailAddress
                }
            }
        }

        If ($CP_Add.Count -gt 0)
        {
            Write-Verbose "Adding Students for $($ClassID): $($CP_Add -join ",")"
            
            If ($CP_Add.Count -gt 40)
            {
                Write-Warning -Message "Setting limit of invites to the first 40 students"
                $CP_Add = $CP_Add | Select-Object -First 40
            }

            $NewInvites = @()
            $NewInvites += $CP_Add | New-_GSCourseInvitation -CourseId $ClassId -Role STUDENT -User $Teacher
            If ($NewInvites.Count -gt 0)
            {
                $r += ($OR_Students | Where-Object -Property Id -In -Value $NewInvites.UserId).EmailAddress
            }
        }

        If ($r.Count -gt 0)
        {
            #Write-Verbose "Adding Students for $($ClassID): $($r -join ",")"
            Return $r
        }

        Return
    }
    END
    {
        Write-Progress -Activity "Resync Student enrollments in Google Classroom" -Status "Done" -Id 0 -Completed
        Write-Host -Object "Done processing for Google Classroom invites"
        If ($RateLimit_Inv.Count -gt 0)
        {
            Write-Host -Object "We hit a ratelimt for:"
            Write-Host -Object $RateLimit_Inv
        }
    }
}

Function add_students()
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

    $Cache_Domain = $(Show-PSGSuiteConfig).Domain
    Write-Host -Object "Loading CourseAlias Cache"
    $Cache_CourseAlias = Import-_GSCourseAlias -Domain $Cache_Domain
    Write-Host -Object "Loading Course Cache"
    $Cache_Course = Import-_GSCourse -Domain $Cache_Domain
    Write-Host -Object "Loading Profile Cache for Students"
    #$Cache_ClassroomUserProfile = @()
    #$Cache_ClassroomUserProfile += Import-_GSClassroomUserProfile -Domain "students.$($Cache_Domain)"
    $Cache_ClassroomUserProfile = Import-_GSClassroomUserProfile -Domain "students.$($Cache_Domain)"
    #$Cache_ClassroomUserProfile += Import-_GSClassroomUserProfile -Domain $($Cache_Domain)
    Write-Host -Object "Loading Users Cache"
    $Users_I = Read-ORUsers -FolderPath $WorkFolder -LoadXML $true
    Write-Host -Object "Limit Users Cache to teachers, aide and admins"
    $Users_T = $Users_I | Limit-ORUserByRole -role teacher,aide,administrator
    Write-Host -Object "Limit Users Cache to students"
    $Users_S = $Users_I | Limit-ORUserByRole -role student
    $Invite_File = Join-Path -Path "." -ChildPath "TODO_Invite.xml"
    $Orgs = Read-OROrgs -FolderPath $WorkFolder
    $r = $Orgs | ForEach-Object {
        $students_N = @()
        If (Test-Path -Path $Invite_File -PathType Leaf)
        {
            $students_N += Import-Clixml -Path $Invite_File
        }
        $ClassLink = Import-ClassLink
        $GoodLink = $ClassLink | Where-Object CourseState -In ("ACTIVE", "PROVISIONED_")
    }, {
        $Org = $_
        Write-Host -Object "Importing classes For $($Org.name)"
        $classes_I = @()
        $classes_I += Read-ORclasses -FolderPath $WorkFolder -Org $Org -LoadXML $true | Where-Object sourcedId -In $GoodLink.sourcedId

        If ($classes_I.Count -eq 0)
        {
            Write-Host -Object "No classes to work on"
            Return
        }

        $students_N_ = @()
        $students_N_ += $classes_I | invite_class_student -WorkFolder $WorkFolder -Cache_CourseAlias $Cache_CourseAlias -Cache_Course $Cache_Course -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile -Cache_Teachers $Users_T -Cache_Students $Users_S -Class_Count $classes_I.Count -Org $Org -Verbose

        If ($students_N_.count -gt 0)
        {
            Write-Host -Object "New invite for students was created"
            $students_U = $students_N + ( $students_N_ | Sort-Object -Unique )
            Write-Host -Object "Export students to confirm Invites"
            Export-Clixml -InputObject $students_U -Path $Invite_File
            $students_N = $students_U
        }
        Return $students_N_
    }, {
        If ($students_N.count -eq 0)
        {
            Write-Host -Object "No new invites for students was created"
            If (Test-Path -Path $Invite_File -PathType Leaf)
            {
                Remove-Item -Path $Invite_File
            }
        }
    }
    Return $r
}

$r = add_students -WorkFolder $WorkFolder