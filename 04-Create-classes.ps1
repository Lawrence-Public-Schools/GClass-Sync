Using module .\OneRoster.psm1

Param(
    [String]$WorkFolder = ".\gclass-OneRoster\"
)

Get-Module -Name GClass | Remove-Module; Import-Module .\GClass.psm1

$TLOG = ((".\Logs\" + (Get-Date -Format u) +"-Create.log").Replace(" ", "-")).Replace(":", "-")
Start-Transcript -path $TLOG

$ErrorActionPreference = "Stop"
#$ErrorActionPreference = "Inquire"

Function make_missing_classes
{
    [OutputType('OR_Class')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [OR_class]$Class,
        [Parameter(Mandatory=$true)]
        [String]$WorkFolder,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [Object]$Cache_GSCourse,
        [Parameter(Mandatory=$true)]
        [AllowNull()]
        [Object]$Cache_GSCourseAlias,
        [AllowNull()]
        [Object]$Cache_Teachers,
        [Parameter(Mandatory=$true)]
        [Int32]$Class_Count,
        [Parameter(Mandatory=$true)]
        [OR_org]$Org
    )
    BEGIN
    {
        Write-Host -Object "Importing enrollments"
        $enrollments_I = Read-ORenrollments -FolderPath $WorkFolder -Org $Org -LoadXML $true
        Write-Host -Object "Filtering enrollments for only primary teachers, normal teachers, aides then admins"
        $enrollments_F = $enrollments_I | Limit-OREnrollmentByrole -role teacher,aide,administrator
        $enrollments_O = @()
        $enrollments_O += $enrollments_F | Limit-OREnrollmentOnlyPrimaryTeacher
        $enrollments_O += $enrollments_F | Limit-OREnrollmentIsPrimary -primary $false | Limit-OREnrollmentByrole -role teacher
        $enrollments_O += $enrollments_F | Limit-OREnrollmentIsPrimary -primary $false | Limit-OREnrollmentByrole -role aide
        $enrollments_O += $enrollments_F | Limit-OREnrollmentIsPrimary -primary $false | Limit-OREnrollmentByrole -role administrator
        If ($enrollments_O.Count -eq 0)
        {
            Write-Warning "Empty enrollments for ORG: $($ORG.name)"
        }
        Write-Host -Object "Importing Users"
        $users_I = Read-ORUsers -FolderPath $WorkFolder -LoadXML $true -Org $Org
        Write-Host -Object "Filtering users for teachers only"
        $users_T = $users_I | Limit-ORUserByRole -role teacher,aide,administrator
        Write-Host -Object "Creating classes"
        $Default_Domain = (Show-PSGSuiteConfig).Domain
        $Class_Counter = 0
        Write-Progress -Activity "Making Google Classrooms" -Status "Processing $($Class_Count) Classes" -Id 0 -PercentComplete 0
        $FakeTeacher = "test.staff@$($Default_Domain)"
    }
    PROCESS
    {
        Write-Progress -Activity "Making Google Classrooms" -Status "Class $($Class_Counter + 1) of $($Class_Count): $($Class.title)" -Id 0 -PercentComplete (($Class_Counter * 100) /$Class_Count)
        $Class_Counter += 1
        $ClassId = $Class | New-ClassAlias
        $users_C = @()
        $enrollments_C = @()
        $enrollments_C_O = @()
        If ($enrollments_O.Count -gt 0) #Look in the local school cache
        {
            $enrollments_C += $enrollments_O | Where-Object -Property classSourcedId -EQ -Value $Class.sourcedId #| Limit-OREnrollmentByclassSourcedId -classSourcedId $Class.sourcedId
            If ($enrollments_C.Count -gt 0)
            {
                $users_C += $users_T | Limit-ORUserBySourcedId -sourcedId $enrollments_C.userSourcedId
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
        If ($null -eq $Teacher) #Still no primary teacher? look for a plain teacher
        {
            $Lookup_E = @()
            $Lookup_E += $enrollments_C | Limit-OREnrollmentByrole -role teacher
            $Lookup_U = @()
            If ($Lookup_E.Count -gt 0)
            {
                $Lookup_U += $users_C | Limit-ORUserBySourcedId -sourcedId $Lookup_E.userSourcedId
            }
            If ($Lookup_U.Count -gt 0)
            {
                $Teacher = $Lookup_U.email | Get-_GSClassroomUserProfile | Where-Object -Property VerifiedTeacher -CEQ -Value "True" | Select-Object -First 1 -ExpandProperty EmailAddress
            }
        }
        If ($null -eq $Teacher) #Still no coteacher? look for a plain aide
        {
            $Lookup_E = @()
            $Lookup_E += $enrollments_C | Limit-OREnrollmentByrole -role aide
            $Lookup_U = @()
            If ($Lookup_E.Count -gt 0)
            {
                $Lookup_U += $users_C | Limit-ORUserBySourcedId -sourcedId $Lookup_E.userSourcedId
            }
            If ($Lookup_U.Count -gt 0)
            {
                $Teacher = $Lookup_U.email | Get-_GSClassroomUserProfile | Where-Object -Property VerifiedTeacher -CEQ -Value "True" | Select-Object -First 1 -ExpandProperty EmailAddress
            }
        }

        If ($null -eq $Teacher) #Still no aide? look for a plain admin
        {
            $Lookup_E = @()
            $Lookup_E += $enrollments_C | Limit-OREnrollmentByrole -role administrator
            $Lookup_U = @()
            If ($Lookup_E.Count -gt 0)
            {
                $Lookup_U += $users_C | Limit-ORUserBySourcedId -sourcedId $Lookup_E.userSourcedId
            }
            If ($Lookup_U.Count -gt 0)
            {
                $Teacher = $Lookup_U.email | Get-_GSClassroomUserProfile | Where-Object -Property VerifiedTeacher -CEQ -Value "True" | Select-Object -First 1 -ExpandProperty EmailAddress
            }
        }
        $r = $null
        $r = Get-_GSCourse -Id $ClassId -BypassCache $true -SkipCache $false -Cache_GSCourse $Cache_GSCourse -Cache_GSCourseAlias $Cache_GSCourseAlias
        If ($r -ne $nul)
        {
            #Write-Verbose "Google Classroom for $($Class.sourcedid) already exist?"
            Return $Class.sourcedId
        }
        If ($null -eq $Teacher)
        {
            If ($enrollments_C.Count -gt 0)
            {
                Write-Warning -Message ("Enrollment records: {0}" -f ($enrollments_C.sourcedId -join ";"))
            }
            Else
            {
                Write-Warning -Message ("No Enrollment records found.")
            }
            Write-Warning "There is no teacher for new classroom $($ClassId)"
            Write-Warning "Using fake teacher for new classroom $($ClassId)"
            $Teacher = $FakeTeacher
        }
        $HomeRoom = $Class.location
        If ($HomeRoom -eq "" -or $null -eq $HomeRoom)
        {
            $HomeRoom = "HomeRoom"
        }
        $Room = "$($HomeRoom) At $($Org.name)"
        $sourcedId = $Class.sourcedId
        $Section = "$($Class.title) (PowerSchool #$($sourcedId)) of School $($Org.name) (PowerSchool #$($Org.sourcedId))"
        $r = $null
        $r = New-_GSCourse -Name $Class.title -OwnerId $Teacher -Id $ClassId -Section $Section -Room $Room -CourseState DECLINED -FallBackId $FakeTeacher
        If ($null -eq $r)
        {
            Return
        }
        If ($users_C.Count -gt 0)
        {
            $users_M = @()
            $users_M += $users_C | Where-Object -Property email -NE $Teacher
            ForEach ($User in $users_M)
            {
                Add-_GSCourseTeacher -CourseId $ClassId -Teacher $User.email | Out-Null
            }
        }
        Return $Class.sourcedId
    }
    END
    {
        Write-Progress -Activity "Making Google Classerooms" -Status "Done" -Id 0  -Completed
    }
}

Function make_classes()
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$WorkFolder
    )

    Write-Host -Object "Loading ClassLink"
    $GoodLink = Import-ClassLink | Where-Object -Property CourseState -NE $null | Select-Object -ExpandProperty sourcedId

    If ((Show-PSGSuiteConfig | Select-Object -ExpandProperty ConfigName) -ne "TEACHERS")
    {
        Write-Host -Object "Switching to TEACHERS"
        Switch-PSGSuiteConfig -ConfigName TEACHERS
    }

    Read-OROrgs -FolderPath $WorkFolder | ForEach-Object -Begin {
        $Cache_Domain = $(Show-PSGSuiteConfig).Domain
        Write-Host -Object "Loading CourseAlias Cache"
        $Cache_CourseAlias = Import-_GSCourseAlias -Domain $Cache_Domain
        Write-Host -Object "Loading Course Cache"
        $Cache_Course = Import-_GSCourse -Domain $Cache_Domain
        Write-Host -Object "Loading Large User Cache"
        $Users_T = @()
        $Users_T += Read-ORUsers -FolderPath $WorkFolder -LoadXML $true | Limit-ORUserByRole -role teacher,aide,administrator
    } -Process {
        $Org = $_
        #Imports
        Write-Host -Object "Importing classes For: $($Org.name)"
        $classes_I = Read-ORclasses -FolderPath $WorkFolder -Org $Org -LoadXML $true

        If ($classes_I.Count -eq 0)
        {
            Write-Host -Object "No classes to work on"
            Return
        }

        $classes_M = @()
        Write-Host -Object "Finding missing Google Classrooms"
        $classes_M += $classes_I | Where-Object -Property sourcedId -NotIn -Value $GoodLink
        #$classes_M += $classes_I | Where-Object -Property sourcedId -In -Value $GoodLink | Where-Object -Property CourseState -EQ $null

        If ($classes_M.count -eq 0)
        {
            Write-Host -Object "No missing Googe Classes"
            Return
        }

        $classes_N = @()

        If ($classes_M.Count -gt 0)
        {
            $classes_N += $classes_M | make_missing_Classes -WorkFolder $WorkFolder -Cache_GSCourse $Cache_Course -Cache_GSCourseAlias $Cache_CourseAlias -Cache_Teachers $Users_T -Class_Count $classes_M.Count -Org $Org
        }
        Else
        {
            Write-Host -Object "No new Googe Classes"
            Return
        }

        Write-Host -Object "Adding new Google Classes to cache"
        If (($classes_N).Count -gt 0)
        {
            Return $classes_N
        }
    } -Verbose | Update-ClassLink -Domain $(Show-PSGSuiteConfig).Domain -Verbose

    Return
}

$r = Make_classes -WorkFolder $WorkFolder -Verbose