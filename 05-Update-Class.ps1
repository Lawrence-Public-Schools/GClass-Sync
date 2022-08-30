Using module .\OneRoster.psm1

Param(
    [String]$WorkFolder = ".\gclass-OneRoster\"
)

Get-Module -Name GClass | Remove-Module; Import-Module .\GClass.psm1

$TLOG = ((".\Logs\" + (Get-Date -Format u) +"-Update.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

#$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Inquire"

Function update_per_class()
{
    [OutputType('String')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [OR_class]$Class,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [Object]$Cache_CourseAlias,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [Object]$Cache_Course,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [Object]$Cache_ClassroomUserProfile,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [Object]
        $Cache_Teachers,
        [Parameter(Mandatory=$true)]
        [Int32]$Class_Count,
        [Parameter(Mandatory=$true)]
        [OR_Org]$Org,
        [String]$WorkPath = "."
    )
    BEGIN
    {
        $Class_Counter = 0
        Write-Progress -Activity "Updating Google Classrooms' Metadata" -Status "Started" -Id 0 -PercentComplete 0
        Write-Host -Object "Importing enrollments"
        $enrollments_I = Read-ORenrollments -FolderPath $WorkPath -Org $Org -LoadXML $true
        Write-Host -Object "Filtering enrollments for primary teachers, normal teachers, aides then admins"
        $enrollments_I_G = $enrollments_I | Group-Object -Property role
        $enrollments_O = ($enrollments_I_G | Where-Object -Property Name -In -Value ("teacher","aide","administrator")).Group

        $enrollments_O_G = $enrollments_O | Group-Object -Property classSourcedId
        Write-Host -Object "Filtering enrollments for students"
        $enrollments_S = ($enrollments_I_G | Where-Object -Property Name -Eq -Value "student").Group
        $enrollments_S_G = $enrollments_S | Group-Object -Property classSourcedId

        $Default_Domain = (Show-PSGSuiteConfig).Domain
        Write-Host -Object "Update classes metadata"
        Write-Progress -Activity "Updating Google Classrooms' Metadata" -Status "Processing $($Class_Count) Classes" -Id 0 -PercentComplete 0
        $FakeTeacher = "test.staff@$($Default_Domain)"
        $FakeProfile = $FakeTeacher | Get-_GSClassroomUserProfile #-BypassCache $true -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile
    }
    PROCESS
    {
        Write-Progress -Activity "Updating Google Classrooms' Metadata" -Status "Class $($Class_Counter  + 1) of $($Class_Count): $($Class.title)" -Id 0 -PercentComplete (($Class_Counter * 100) /$Class_Count)
        $Class_Counter += 1

        $sourcedId = $Class.sourcedId
        $ClassId = $sourcedId | New-ClassAlias
        $Course = $null
        $Course = Get-_GSCourse -BypassCache $true -Id $ClassId -Cache_GSCourse $Cache_Course -Cache_GSCourseAlias $Cache_CourseAlias
        $bState = $false
        If ($null -eq $Course)
        {
            Write-Verbose "No Google Classroom for $($sourcedId)"
            $sourcedId | Update-ClassLink -Domain $(Show-PSGSuiteConfig).Domain -Verbose
            Return
        }
        Else
        {
            $OldCourse = $Course
        }
        $CourseName = $Course.Name
        $enrollments_S_ = @()
        $enrollments_S_ += $enrollments_S_G | Where-Object -Property Name -CEQ $Class.sourcedId | Select-Object -ExpandProperty Group #$enrollments_S | Limit-OREnrollmentByclassSourcedId -classSourcedId $Class.sourcedId
        $Room = $null
        $Section = $null
        Switch ($Course.CourseState)
        {
            "COURSE_STATE_UNSPECIFIED"
            {
                Write-Warning "Can not get $($ClassId)'s State"
                Return
            }
            "ACTIVE"
            {
                If ($enrollments_S_.Count -eq 0)
                {
                    If ($Course.OwnerId -eq $FakeProfile.Id)
                    {
                        $Course = Update-GSCourse -Id $ClassId -CourseState DECLINED
                        Write-Verbose "Updating Empty $($ClassId) Of Faker"
                        $bState = $true
                    }
                    Else
                    {
                        $Course = Update-GSCourse -Id $ClassId -CourseState ARCHIVED
                        Write-Verbose "Updating Empty $($ClassId) Of Real"
                        $bState = $true
                    }
                }
                Else {}
            }
            "ARCHIVED"
            {
                If ($enrollments_S_.Count -eq 0) {}
                Else
                {
                    If ($Course.OwnerId -eq $FakeProfile.Id) {}
                    Else
                    {
                        $Course = Update-GSCourse -Id $ClassId -CourseState PROVISIONED
                        #Write-Verbose "Updating Old $($ClassId) Of Real"
                        $bState = $true
                    }
                }
            }
            "PROVISIONED"
            {
                If ($enrollments_S_.Count -eq 0)
                {
                    If ($Course.OwnerId -eq $FakeProfile.Id)
                    {
                        $Course = Update-GSCourse -Id $ClassId -CourseState DECLINED
                        Write-Verbose "Updating Blank $($ClassId) Of Faker"
                        $bState = $true
                    }
                    Else
                    {
                        $Course = Update-GSCourse -Id $ClassId -CourseState DECLINED
                        Write-Verbose "Updating Blank $($ClassId) Of Real"
                        $bState = $true
                    }
                }
                Else {}
            }
            "DECLINED"
            {
                If ($enrollments_S_.Count -eq 0) {}
                Else
                {
                    If ($Course.OwnerId -eq $FakeProfile.Id) {}
                    Else
                    {
                        $Course = Update-GSCourse -Id $ClassId -CourseState PROVISIONED
                        Write-Verbose "Resetting Filled $($ClassId) Of Real"
                        $bState = $true
                    }
                }
            }
            default
            {
                Write-Warning "Can not handle $($ClassId)'s State $($Course.CourseState)"
            }
        }
        $HomeRoom = $Class.location
        If ($null -eq $Room)
        {
            If ($HomeRoom -eq "" -or $null -eq $HomeRoom)
            {
                $HomeRoom = "HomeRoom"
            }
            $Room = "$($HomeRoom) At $($Org.name)"
        }
        If ($null -eq $Section)
        {
            $Section = "$($Class.title) (PowerSchool #$($sourcedId)) of School $($Org.name) (PowerSchool #$($Org.sourcedId))"
        }
        If ($null -eq $Course)
        {
            $Course = Get-_GSCourse -Id $ClassId
        }
        If ($null -ne $Course -and $Course.Room -cne $Room -or $Course.Section -cne $Section)
        {
            #$bState = $true
            $oldState = $Course.CourseState
            If ($Course.CourseState -notin ("PROVISIONED","ARCHIVED","ACTIVE"))
            {
                Write-Warning "Updating $($ClassId)'s Room/Section while in $($Course.CourseState)"
            }
            [console]::TreatControlCAsInput = $true
            If ($Course.CourseState -in ("ARCHIVED", "DECLINED"))
            {
                $Course = Update-GSCourse -Id $ClassId -CourseState PROVISIONED
            }
            If ($Course.Room -cne $Room -and $Course.Section -cne $Section)
            {
                $Course = Update-GSCourse -Id $ClassId -Room $Room -Section $Section
            }
            ElseIf ($Course.Room -cne $Room)
            {
                $Course = Update-GSCourse -Id $ClassId -Room $Room
            }
            ElseIf ($Course.Section -cne $Section)
            {
                $Course = Update-GSCourse -Id $ClassId -Section $Section
            }
            If ($Course.CourseState -ne $oldState)
            {
                $Course = Update-GSCourse -Id $ClassId -CourseState $oldState
            }
            [console]::TreatControlCAsInput = $false
        }
        $users_C = @()
        $enrollments_C = @()
        $enrollments_C_O = @()
        If ($enrollments_O.Count -gt 0) #Look in the local school cache
        {
            $enrollments_C += $enrollments_O_G | Where-Object -Property Name -CEQ $Class.sourcedId | Select-Object -ExpandProperty Group #$enrollments_O | Limit-OREnrollmentByclassSourcedId -classSourcedId $Class.sourcedId
            If ($enrollments_C.Count -gt 0)
            {
                $users_C += $Cache_Teachers | Limit-ORUserBySourcedId -sourcedId $enrollments_C.userSourcedId
                If ($users_C.Count -gt 0)
                {
                    $enrollments_C_O += $enrollments_C | Where-Object -Property userSourcedId -NotIn $users_C.sourcedId
                }
                Else
                {
                    $enrollments_C_O += $enrollments_C
                }
            }
        }
        $Teacher = $null
        If ($users_C.Count -gt 0)
        {
            $Lookup_E = @()
            $Lookup_E += $enrollments_C | Limit-OREnrollmentOnlyPrimaryTeacher
            $Lookup_U = @()
            If ($Lookup_E.Count -gt 0)
            {
                $Lookup_U += $Users_C | Limit-ORUserBySourcedId -sourcedId $Lookup_E.userSourcedId
            }
            If ($Lookup_U.Count -gt 0)
            {
                $Teacher = $Lookup_U.email | Get-_GSClassroomUserProfile | Where-Object -Property VerifiedTeacher -CEQ -Value "True" | Select-Object -First 1 -ExpandProperty EmailAddress
            }
        }
        $Users_C_O = @()
        If ($enrollments_C_O.Count -gt 0)
        {
            #Write-Warning "Could not find teachers inside the School for $($ClassId)"
            $users_C_O += $Cache_Teachers | Limit-ORUserBySourcedId -sourcedId $enrollments_C_O.userSourcedId
            $users_C += $users_C_O
        }
        If ($users_C_O.Count -gt 0)
        {
            $Lookup_E = @()
            $Lookup_E += $enrollments_C_O | Limit-OREnrollmentOnlyPrimaryTeacher
            $Lookup_U = @()
            If ($Lookup_E.Count -gt 0)
            {
                $Lookup_U += $users_C_O | Limit-ORUserBySourcedId -sourcedId $Lookup_E.userSourcedId
            }
            If ($Lookup_U.Count -gt 0 -and $null -eq $Teacher)
            {
                $Teacher = $Lookup_U.email | Get-_GSClassroomUserProfile | Where-Object -Property VerifiedTeacher -CEQ -Value "True" | Select-Object -First 1 -ExpandProperty EmailAddress
            }
        }
        If ($null -eq $Teacher -and $enrollments_S_.Count -gt 0)
        {
            If ($users_C.Count -gt 0 -or $enrollments_C.Count -gt 0)
            {
                Write-Warning "No Primary Teacher account found for $($ClassId)"
            }
            If ($users_C.Count -gt 0)
            {
                Write-Warning -Message ("There are user records: {0}" -f $users_C.sourcedId -join ";")
            }
            If ($enrollments_C.Count -gt 0 -and $users_C.Count -ne $enrollments_C.Count)
            {
                Write-Warning -Message ("There are enrollment records: {0}" -f $enrollments_C.sourcedId -join ";")
            }
        }
        $OwnerProfile = @()
        $OwnerProfile += Get-_GSClassroomUserProfile -UserId $Course.OwnerId -BypassCache $false -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile
        $OldOwner = $null
        If ($OwnerProfile.Count -eq 1 -and $null -ne $OwnerProfile[0].EmailAddress -and "" -ne $OwnerProfile[0].EmailAddress)
        {
            $OldOwner = $OwnerProfile.EmailAddress
        }
        ElseIf ($OwnerProfile.Count -eq 0)
        {
            Write-Warning "Could not find Owner of $($Cache_CourseAlias)"
        }
        Else
        {
            Write-Warning "Odd Ownership of $($Cache_CourseAlias): $($OwnerProfile | ConvertTo-Json -Depth 1)"
        }
        $Teachers = @()
        $Teachers_woP = @()
        $Teachers_wP = @()
        $FakerIn = $false
        $Teachers += Get-_GSCourseParticipant -CourseId $ClassId -Role Teacher
        $CoTeachers_emails = @()
        $Outsiders = @()
        $Insiders = @()
        If ($Teachers.Count -gt 0)
        {
            $Teachers_woP += $Teachers | Where-Object -Property Profile -EQ $null
            $Teachers_wP += $Teachers | Where-Object -Property Profile -NE $null
            If ($Teachers_wP.Count -gt 0)
            {
                $Outsiders += $Teachers_wP.Profile | Where-Object -Property EmailAddress -EQ $null
                $Outsiders += $Teachers_wP.Profile | Where-Object -Property EmailAddress -EQ ""
                $Insiders += $Teachers_wP.Profile | Where-Object -Property Id -NE $OwnerProfile.Id | Where-Object -Property EmailAddress -NE $null | Where-Object -Property EmailAddress -NE ""
                If ($FakeProfile.Id -in $Insiders.Id)
                {
                    $FakerIn = $true
                }
            }
            If ($Insiders.Count -gt 0)
            {
                $CoTeachers_emails += $Insiders.EmailAddress
            }
            If ($Outsiders.Count -gt 0)
            {
                Write-Warning "Google Classrom $($ClassId) have outsiders as teachers"
                $Outsiders | Select-Object -Property Id, PhotoUrl | ConvertTo-Json | Write-Warning
            }
            If ($Teachers_woP.Count -gt 0)
            {
                Write-Warning "Google Classrom $($ClassId) have teachers with empty profiles"
                $Teachers_woP | ConvertTo-Json | Write-Warning
            }
        }
        If ($OldOwner -eq $FakeTeacher)
        {
            $FakerIn = $true
        }
        $Helpers = @()
        If ($users_C.Count -gt 0)
        {
            $Helpers += $users_C | Where-Object email -NE $OwnerProfile.EmailAddress
            ForEach ($Co in $Helpers)
            {
                If ($Co.email -inotin $CoTeachers_emails)
                {
                    #Write-Warning "Adding Teacher $($Co.email) to $($ClassId)"
                    Add-_GSCourseTeacher -CourseId $ClassId -Teacher $Co.email -Verbose | Out-Null
                }
            }
        }
        If ($null -eq $Teacher -and $Course.CourseState -notin ("ARCHIVED","PROVISIONED"))
        {
            If ($OldOwner -ne $FakeTeacher -and $false)
            {
                #Write-Warning "Can not find a teacher to use for $($ClassId), Old Owner is $($OldOwner)"
                If ($FakerIn -eq $false)
                {
                    Add-_GSCourseTeacher -CourseId $ClassId -Teacher $FakeTeacher -Verbose | Out-Null
                    $FakerIn = $true
                }
                $Teacher = $FakeTeacher
            }
        }
        ElseIf ($FakerIn -eq $true -and $OldOwner -ne $FakeTeacher)
        {
            Remove-GSCourseParticipant -CourseId $ClassId -Teacher $FakeTeacher -User $FakeTeacher -Confirm:$false | Out-Null
            $FakerIn = $false
        }
        $TeacherProfile = @()
        If ($null -ne $Teacher)
        {
            $TeacherProfile += Get-_GSClassroomUserProfile -UserId $Teacher -BypassCache $true -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile
        }
        If ($enrollments_S_.Count -eq 0)
        {
            $All_Invites = @()
            $All_Invites += Get-_GSCourseInvitation -CourseId $ClassId -Role OWNER, TEACHER, STUDENT
            $Remover = $null
            If ($FakerIn -eq $true -or $Teacher -eq $FakeTeacher)
            {
                $Remover = $FakeTeacher
            }
            ElseIf ($null -ne $OldOwner)
            {
                $Remover = $OldOwner
            }
            ElseIf ($All_Invites.Count -gt 0)
            {
                Write-Warning "Can not find a teacher to remove invites with for $($ClassId)"
            }
            If ($All_Invites.Count -gt 0 -and $null -ne $Remover)
            {
                Write-Verbose "Removing $($All_Invites.Count) Invites for $($ClassId)"
                $All_Invites | Remove-_GSCourseInvitation -User $Remover -Verbose
            }
        }
        ElseIf (($null -ne $Teacher) -and ($OldOwner -ne $Teacher))
        {
            If ($Teacher -eq $FakeTeacher)
            {
                #Write-Warning "Not Changing Ownership from $($OldOwner) to $($Teacher) for $($ClassId)"
            }
            ElseIf ($OwnerProfile.Id -eq $TeacherProfile.Id)
            {
                Write-Warning "Tried to change ownership but $($Teacher) is already the owner"
            }
            Else
            {
                Write-Warning "Changing Ownership from $($OldOwner) to $($Teacher) for $($ClassId) In $($Course.CourseState)"
                If ($Course.CourseState -in ("DECLINED"))
                {
                    $Course = Update-GSCourse -Id $ClassId -CourseState PROVISIONED
                }
                $Course = $null
                $Course = Update-GSCourse -Id $ClassId -OwnerId $Teacher
                $bState = $true
                If ($null -ne $Course)
                {
                    $Owner = $Teacher
                    If ($FakerIn -eq $true -and $Teacher -ne $FakeTeacher)
                    {
                        Remove-GSCourseParticipant -CourseId $ClassId -Teacher $FakeTeacher -User $Owner -Confirm:$false -Verbose | Out-Null
                    }
                }
            }
        }
        If ($true -eq $bState)
        {
            $sourcedId | Update-ClassLink -Domain $(Show-PSGSuiteConfig).Domain -Verbose
        }
        If ($null -eq $OldOwner)
        {
            $OldOwner = $Teacher
        }
        If ($Course.CourseState -in ("PROVISIONED","DECLINED"))
        {
            $Broken_Invites = @()
            $Broken_Invites += Get-_GSCourseInvitation -CourseId $ClassId -Role STUDENT
            If ($Broken_Invites.Count -gt 0)
            {
                Write-Host "Found  $($Broken_Invites.Count) broken Invites for $($ClassId)"
                $Broken_Invites | Remove-_GSCourseInvitation -User $OldOwner -Verbose
            }
        }
        Return
    }
    END
    {
        Write-Progress -Activity "Updating Google Classrooms' Metadata"-Status "Done" -Id 0 -Completed
        Write-Host -Object "Done updating classes for Metadata"
    }
}

Function update_classes()
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$WorkFolder
    )

    If ((Show-PSGSuiteConfig | Select-Object -ExpandProperty ConfigName) -ne "TEACHERS")
    {
        Write-Host -Object "Switching to TEACHERS"
        Switch-PSGSuiteConfig -ConfigName TEACHERS
    }

    $classes_C = Read-OROrgs -FolderPath $WorkFolder | ForEach-Object {
        $Cache_Domain = $(Show-PSGSuiteConfig).Domain
        Write-Host -Object "Loading CourseAlias Cache"
        $Cache_CourseAlias = Import-_GSCourseAlias -Domain $Cache_Domain #-Path $WorkFolder
        Write-Host -Object "Loading Course Cache"
        $Cache_Course = Import-_GSCourse -Domain $Cache_Domain #-Path $WorkFolder
        Write-Host -Object "Loading Profile Cache"
        $Cache_ClassroomUserProfile = Import-_GSClassroomUserProfile -Domain $Cache_Domain #-Path $WorkFolder
        Write-Host -Object "Loading Large Teacher Cache"
        $Users_I = @()
        $Users_I += Read-ORUsers -FolderPath $WorkFolder -LoadXML $true | Where-Object email -NE "" | Limit-ORUserByRole -role teacher,aide,administrator
    },{
        $Org = $_
        Write-Host -Object "Importing classes for: $($Org.name)"
        $classes_I = Read-ORclasses -FolderPath $WorkFolder -LoadXML $true -Org $Org

        If ($classes_I.Count -eq 0)
        {
            Write-Host -Object "No classes to work on"
            Return
        }

        $Enrollment_I = Read-ORenrollments -FolderPath $WorkFolder -LoadXML $true -Org $Org
        $Users_T = $Users_I | Where-Object -Property sourcedId -In $Enrollment_I.userSourcedId
        $Cache_ClassroomUserProfile_ = $Cache_ClassroomUserProfile | Where-Object -Property EmailAddress -In $Users_T.email

        $classes_U = @()
        $classes_U += $classes_I | update_per_class -Cache_CourseAlias $Cache_CourseAlias -Cache_Course $Cache_Course -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile_ -Cache_Teachers $Users_T -Class_Count $classes_I.Count -Org $Org -WorkPath $WorkFolder -Verbose

        If ($classes_U.Count -gt 0)
        {
            Write-Host -Object "Changed Google Classes to cache"
            #$classes_U | Get-_GSCourse -SkipCache $true | Out-Null
        }

        Return $classes_U
    }
    If ($classes_C.count -gt 0)
    {
        #Write-Warning "Updating $($classes_C.count) Classes: $($classes_C)"
        #$classes_C | Update-ClassLink -Domain $(Show-PSGSuiteConfig).Domain
    }

    Return $classes_C
}

$r = update_classes -WorkFolder $WorkFolder