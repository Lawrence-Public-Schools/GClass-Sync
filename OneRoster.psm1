#---------------------------------------------------------------------------------------------------------------------------------
#Base
#---------------------------------------------------------------------------------------------------------------------------------

$OneRoster_Source = @"

using System;
using System.Management.Automation;
using System.Collections.Generic;

namespace OneRoster_FastSearch
{

    public static class Search
    {
        public static List<Object> FindAll(PSObject[] collection, string column, string data)
        {
            List<Object> results = new List<Object>();

            if (null == collection)
            {
                return results;
            }

            foreach(PSObject item in collection)
            {
                if (item.Properties[column].Value.ToString() == data) { results.Add(item); }
            }

            return results;
        }

        public static object FindOne(PSObject[] collection, string column, string data)
        {
            if (null == collection)
            {
                return null;
            }

            foreach(PSObject item in collection)
            {
                if (item.Properties[column].Value.ToString() == data) { return item; }
            }

            return null;
        }
    }
}
"@

Add-Type -ReferencedAssemblies $Assem -TypeDefinition $OneRoster_Source -Language CSharp

class OneRoster
{
    static [bool] BooleanFrom([String]$CSV)
    {
        Switch -CaseSensitive ($CSV)
        {
            "true"
            {
                Return $true
            }
            "false"
            {
                Return $false
            }
            ""
            {
                Return $false
            }
        }
        Return [System.Convert]::ToBoolean($CSV)
    }

    static [String] StringFrom([bool]$bool)
    {
        Switch ($bool)
        {
            $true
            {
                Return "true"
            }
            $false
            {
                Return "false"
            }
        }
        Return [System.Convert]::ToString($bool)
    }

    static [DateTime] DateFrom([String]$CSV)
    {
        If ($CSV -eq "")
        {
            Return Get-Date -Year 1 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
        }
        Return Get-Date -Date $CSV
    }

    static [String] StringFrom([DateTime]$Date)
    {
        If ($Date -eq 0)
        {
            Return ""
        }
        Return Get-Date -Date $Date -Format "yyyy-MM-dd"
    }

    static [double] FloatFrom([String]$CSV)
    {
        Return [System.Convert]::ToDouble($CSV)
    }

    static [String] StringFrom([Float]$Float)
    {
        Return [System.Convert]::ToString($Float)
    }

    static [DateTime] gYearFrom([String]$CSV)
    {
        Return Get-Date -Year $CSV -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
    }

    static [String] TogYear([DateTime]$gYear)
    {
        Return [System.Convert]::ToString($gYear.Year)
    }

    static [OR_OrgType] OrgFrom([String]$CSV)
    {
        Switch -CaseSensitive ($CSV)
        {
            "department"
            {
                Return [OR_OrgType]::department
            }
            "school"
            {
                Return [OR_OrgType]::school
            }
            "district"
            {
                Return [OR_OrgType]::district
            }
            "local"
            {
                Return [OR_OrgType]::local
            }
            "state"
            {
                Return [OR_OrgType]::state
            }
            "national"
            {
                Return [OR_OrgType]::national
            }
        }
        Return [OR_OrgType]::null
    }

    static [OR_ClassType] ClassFrom([String]$CSV)
    {
        Switch -CaseSensitive ($CSV)
        {
            "homeroom"
            {
                Return [OR_ClassType]::department
            }
            "scheduled"
            {
                Return [OR_ClassType]::scheduled
            }
        }
        Return [OR_ClassType]::null
    }

    static [OR_StatusType] StatusFrom([String]$CSV)
    {
        Switch -CaseSensitive ($CSV)
        {
            "active"
            {
                Return [OR_StatusType]::active
            }
            "inactive"
            {
                Return [OR_StatusType]::inactive
            }
            "tobedeleted"
            {
                Return [OR_StatusType]::tobedeleted
            }
        }
        Return [OR_StatusType]::null
    }

    static [OR_SessionType] SessionFrom([String]$CSV)
    {
        Switch -CaseSensitive ($CSV)
        {
            "term"
            {
                Return [OR_SessionType]::term
            }
            "gradingPeriod"
            {
                Return [OR_SessionType]::gradingPeriod
            }
            "schoolYear"
            {
                Return [OR_SessionType]::schoolYear
            }
            "semester"
            {
                Return [OR_SessionType]::semester
            }
        }
        Return [OR_SessionType]::null
    }

    static [OR_Roletype] RoleFrom([String]$CSV)
    {
        Switch -CaseSensitive ($CSV)
        {
            "teacher"
            {
                Return [OR_RoleType]::teacher
            }
            "student"
            {
                Return [OR_RoleType]::student
            }
            "parent"
            {
                Return [OR_RoleType]::parent
            }
            "guardian"
            {
                Return [OR_RoleType]::guardian
            }
            "relative"
            {
                Return [OR_RoleType]::relative
            }
            "aide"
            {
                Return [OR_RoleType]::aide
            }
            "administrator"
            {
                Return [OR_RoleType]::administrator
            }
        }
        Return [OR_RoleType]::null
    }
}

Enum OR_ClassType
{
    null
    homeroom
    scheduled
}

Enum OR_OrgType
{
    null
    department
    school
    district
    local
    state
    national
}

Enum OR_RoleType
{
    null
    teacher
    student
    parent
    guardian
    relative
    aide
    administrator
}

Enum OR_SessionType
{
    null
    term
    gradingPeriod
    schoolYear
    semester
}

Enum OR_StatusType
{
    null
    active
    inactive
    tobedelteted
}

#---------------------------------------------------------------------------------------------------------------------------------
#academicSession
#---------------------------------------------------------------------------------------------------------------------------------

class OR_academicSession:OneRoster
{
    [String]$sourcedId
    [OR_StatusType]$status
    [DateTime]$dateLastModified
    [String]$title
    [OR_SessionType]$type
    [DateTime]$startDate
    [DateTime]$endDate
    [String]$parentSourcedId
    [DateTime]$schoolYear

    OR_academicSession(
        [Object]$InputObject
    )
    {
        If ($InputObject.Count -gt 1)
        {
            Write-Error "More then one academicSession object"
        }
        If (($InputObject |Get-Member).TypeName -eq "Deserialized.OR_academicSession")
        {
            $this.status = $InputObject.status
            $this.dateLastModified = $InputObject.datelastmodified
            $this.type = $InputObject.type
            $this.startDate = $InputObject.startDate
            $this.endDate = $InputObject.endDate
            $this.schoolyear = $InputObject.schoolyear
        }
        Else
        {
            $this.status = [OneRoster]::StatusFrom($InputObject.status)
            $this.dateLastModified = [OneRoster]::DateFrom($InputObject.datelastmodified)
            $this.type = [OneRoster]::SessionFrom($InputObject.type)
            $this.startDate = [OneRoster]::DateFrom($InputObject.startDate)
            $this.endDate = [OneRoster]::DateFrom($InputObject.endDate)
            $this.schoolyear = [OneRoster]::gYearFrom($InputObject.schoolyear)
        }
        $this.sourcedId = $InputObject.sourcedId
        $this.title = $InputObject.title
        $this.parentsourcedid = $InputObject.parentsourcedid
    }

    [String] ToString()
    {
        $l = New-Object Collections.Generic.List[String]
        $l.Add('"')
        $l.Add($this.sourcedId)
        $l.Add('","')
        $l.Add($this.status)
        $l.Add('","')
        $l.Add([OneRoster]::StringFrom($this.dateLastModified))
        $l.Add('","')
        $l.Add($this.title)
        $l.Add('","')
        $l.Add($this.type)
        $l.Add('","')
        $l.Add([OneRoster]::StringFrom($this.startDate))
        $l.Add('","')
        $l.Add([OneRoster]::StringFrom($this.endDate))
        $l.Add('","')
        $l.Add($this.parentSourcedId)
        $l.Add('",')
        $l.Add([OneRoster]::TogYear($this.schoolYear))
        Return $l -join ""
    }
}

Function Convert-ORacademicSession
{
    [OutputType('OR_academicSession')]
    [cmdletbinding()]
    Param
    (
        [parameter(Mandatory = $true,ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
        [Object[]]
        $InputPipe
    )
    PROCESS
    {
        Return [OR_academicSession]::new($InputPipe)
    }
}

Function Import-ORacademicSession
{
    [OutputType('OR_academicSession')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,
        [parameter(Mandatory = $false)]
        [String]
        $Encoding = "UTF8"
    )
    BEGIN
    {
        $private:l = $Null
        If ((Test-Path -Path $Path -PathType Leaf))
        {
            $private:l = Get-ChildItem -Path $Path
        }
        $private:OR_Path_TMP = New-TemporaryFile
    }
    PROCESS
    {
        If ($null -ceq $private:l)
        {
            Return
        }
        Return Import-Csv -LiteralPath (Copy-Item -Path $Path -Destination $private:OR_Path_TMP -PassThru) -Encoding $Encoding -ErrorAction Stop | Convert-ORacademicSession
    }
    END
    {
        If ($null -ceq $private:l)
        {
            Return
        }
        $private:OR_Path_TMP | Remove-Item
    }
}

Function Out-ORacademicSession
{
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [OR_academicSession[]]$InputObject,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $FilePath,
        [parameter(Mandatory = $false)]
        [String]
        $Encoding = "UTF8"
    )
    BEGIN
    {
        '"sourcedId","status","dateLastModified","title","type","startDate","endDate","parentSourcedId","schoolYear"'  | Out-File -Encoding $Encoding -FilePath $FilePath
    }
    PROCESS
    {
        $InputObject | ForEach-Object {
            $_.ToString()
        } | Out-File -Append -Encoding $Encoding -FilePath $FilePath
    }
}

Function Read-ORAcademicSessions
{
    [OutputType('OR_academicSessions')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [String]$FolderPath = "."
    )
    BEGIN
    {
        $FilePath = Join-Path -Path $FolderPath -ChildPath "academicSessions.csv"
    }
    PROCESS
    {
        Import-ORacademicSession -Path $FilePath
    }
    END
    {
    }
}


#---------------------------------------------------------------------------------------------------------------------------------
#Org
#---------------------------------------------------------------------------------------------------------------------------------

class OR_org
{
    [String]$sourcedId
    [OR_statusType]$status
    [DateTime]$dateLastModified
    [String]$name
    [OR_OrgType]$type
    [string]$identifier
    [string]$parentSourcedId

    OR_org(
        [object]$InputObject
    )
    {
        If ($InputObject.Count -gt 1)
        {
            Write-Error "More then one org object"
        }
        If (($InputObject |Get-Member).TypeName -eq "Deserialized.OR_org")
        {
            $this.status = $InputObject.status
            $this.dateLastModified = $InputObject.datelastmodified
            $this.type = $InputObject.type
        }
        Else
        {
            $this.status = [OneRoster]::StatusFrom($InputObject.status)
            $this.dateLastModified = [OneRoster]::DateFrom($InputObject.datelastmodified)
            $this.type = [OneRoster]::OrgFrom($InputObject.type)
        }
        $this.sourcedId = $InputObject.sourcedId
        $this.name = $InputObject.name
        $this.identifier = $InputObject.identifier
        $this.parentSourcedId = $this.parentSourcedId
    }

    OR_org(
        [OR_org]$InputObject
    )
    {
        Out-Null
    }

    [String] ToString()
    {
        $l = New-Object Collections.Generic.List[String]
        $l.Add('"')
        $l.Add($this.sourcedId)
        $l.Add('","')
        $l.Add($this.status)
        $l.Add('","')
        $l.Add([OneRoster]::StringFrom($this.dateLastModified))
        $l.Add('","')
        $l.Add($this.name)
        $l.Add('","')
        $l.Add($this.type)
        $l.Add('","')
        $l.Add($this.identifier)
        $l.Add('","')
        $l.Add($this.parentSourcedId)
        $l.Add('"')
        Return $l -join ""
    }
}

Function Convert-ORorg
{
    [OutputType('OR_org')]
    [cmdletbinding()]
    Param
    (
        [parameter(Mandatory = $true,ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
        [Object[]]
        $InputPipe
    )
    PROCESS
    {
        Return [OR_org]::new($InputPipe)
    }
}

Function Import-ORorg
{
    [OutputType('OR_org')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,
        [parameter(Mandatory = $false)]
        [String]
        $Encoding = "UTF8"

    )
    BEGIN
    {
        $private:l = $Null
        If ((Test-Path -Path $Path -PathType Leaf))
        {
            $private:l = Get-ChildItem -Path $Path
        }
        $private:OR_Path_TMP = New-TemporaryFile
    }
    PROCESS
    {
        If ($null -ceq $private:l)
        {
            Return
        }
        Return Import-Csv -LiteralPath (Copy-Item -Path $Path -Destination $private:OR_Path_TMP -PassThru) -Encoding $Encoding -ErrorAction Stop | Convert-ORorg
    }
    END
    {
        If ($null -ceq $private:l)
        {
            Return
        }
        $private:OR_Path_TMP | Remove-Item
    }
}

Function Out-ORorg
{
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [OR_Org[]]$InputObject,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $FilePath,
        [parameter(Mandatory = $false)]
        [String]
        $Encoding = "UTF8"
    )
    BEGIN
    {
        '"sourcedId","status","dateLastModified","name","type","identifier","parentSourcedId"' | Out-File -Encoding $Encoding -FilePath $FilePath
    }
    PROCESS
    {
        $InputObject | ForEach-Object {
            $_.ToString()
        } | Out-File -Append -Encoding $Encoding -FilePath $FilePath
    }
}

Function Read-OROrgs
{
    [OutputType('OR_org')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [String]$FolderPath = ".",
        [Parameter(Mandatory = $false)]
        [Bool]$LoadXML = $false
    )
    BEGIN
    {
        $FilePath = Join-Path -Path $FolderPath -ChildPath "orgs.csv"
        If ($LoadXML -eq $true)
        {
            $FileName = "orgs.xml"
        }
        Else
        {
             $FileName = "orgs.csv"
        }
        $FilePath = Join-Path -Path $FolderPath -ChildPath $FileName
    }
    PROCESS
    {
        If (-not (Test-Path -Path $FilePath -PathType Leaf))
        {
            Return
        }
        If ($LoadXML)
        {
            Import-Clixml -Path $FilePath -ErrorAction Stop
        }
        Else
        {
            Import-ORorg -Path $FilePath
        }
    }
    END
    {
    }
}

#---------------------------------------------------------------------------------------------------------------------------------
#Course
#---------------------------------------------------------------------------------------------------------------------------------

class OR_course
{
    [String]$sourcedId
    [OR_statusType]$status
    [DateTime]$dateLastModified
    [string]$schoolYearSourcedId
    [String]$title
    [String]$courseCode
    [String[]]$grades
    [String]$orgSourcedId
    [String]$subjects
    [String]$subjectCodes

    OR_course(
        [object]$InputObject
    )
    {
        If ($InputObject.Count -gt 1)
        {
            Write-Error "More then one course object"
        }
        If (($InputObject |Get-Member).TypeName -eq "Deserialized.OR_course")
        {
            $this.status = $InputObject.status
            $this.dateLastModified = $InputObject.datelastmodified
            $this.grades = $InputObject.grades
            $this.subjects = $InputObject.subjects
        }
        Else
        {
            $this.status = [OneRoster]::StatusFrom($InputObject.status)
            $this.dateLastModified = [OneRoster]::DateFrom($InputObject.datelastmodified)
            $this.grades = $InputObject.grades -split ","
            $this.subjects = $InputObject.subjects -split ","
        }
        $this.sourcedId = $InputObject.sourcedId
        $this.schoolYearSourcedId = $InputObject.schoolYearSourcedId
        $this.title = $InputObject.title
        $this.courseCode = $InputObject.courseCode
        $this.orgSourcedId = $InputObject.orgSourcedId
        $this.subjectCodes = $InputObject.subjectCodes
    }

    [String] ToString()
    {
        $l = New-Object Collections.Generic.List[String]
        $l.Add('"')
        $l.Add($this.sourcedId)
        $l.Add('","')
        $l.Add($this.status)
        $l.Add('","')
        $l.Add([OneRoster]::StringFrom($this.dateLastModified))
        $l.Add('","')
        $l.Add($this.schoolYearSourcedId)
        $l.Add('","')
        $l.Add($this.title)
        $l.Add('","')
        $l.Add($this.courseCode)
        $l.Add('","')
        $l.Add($this.grades -join ",")
        $l.Add('","')
        $l.Add($this.orgSourcedId)
        $l.Add('","')
        $l.Add($this.subjects -join ",")
        $l.Add('","')
        $l.Add($this.subjectCodes)
        $l.Add('"')
        Return $l -join ""
    }
}

Function Convert-ORcourse
{
    [OutputType('OR_course')]
    [cmdletbinding()]
    Param
    (
        [parameter(Mandatory = $true,ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
        [Object[]]
        $InputPipe
    )
    PROCESS
    {
        Return [OR_course]::new($InputPipe)
    }
}

Function Import-ORcourse
{
    [OutputType('OR_course')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,
        [parameter(Mandatory = $false)]
        [String]
        $Encoding = "UTF8"

    )
    BEGIN
    {
        $private:l = $Null
        If ((Test-Path -Path $Path -PathType Leaf))
        {
            $private:l = Get-ChildItem -Path $Path
        }
        $private:OR_Path_TMP = New-TemporaryFile
    }
    PROCESS
    {
        If ($null -ceq $private:l)
        {
            Return
        }
        Return Import-Csv -LiteralPath (Copy-Item -Path $Path -Destination $private:OR_Path_TMP -PassThru) -Encoding $Encoding -ErrorAction Stop | Convert-ORcourse
    }
    END
    {
        If ($null -ceq $private:l)
        {
            Return
        }
        $private:OR_Path_TMP | Remove-Item
    }
}

Function Out-ORcourse
{
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [OR_course[]]$InputObject,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $FilePath,
        [parameter(Mandatory = $false)]
        [String]
        $Encoding = "UTF8"
    )
    BEGIN
    {
        '"sourcedId","status","dateLastModified","schoolYearSourcedId","title","courseCode","grades","orgSourcedId","subjects","subjectCodes"' | Out-File -Encoding $Encoding -FilePath $FilePath
    }
    PROCESS
    {
        $InputObject | ForEach-Object {
            $_.ToString()
        } | Out-File -Append -Encoding $Encoding -FilePath $FilePath
    }
}

Function Read-ORCourses
{
    [OutputType('OR_course')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [String]$FolderPath = "."
    )
    BEGIN
    {
        $FilePath = Join-Path -Path $FolderPath -ChildPath "courses.csv"
    }
    PROCESS
    {
        Import-ORcourse -Path $FilePath
    }
    END
    {
    }
}

#---------------------------------------------------------------------------------------------------------------------------------
#Enrollment
#---------------------------------------------------------------------------------------------------------------------------------

class OR_enrollment
{
    [String]$sourcedId
    [OR_statusType]$status
    [DateTime]$dateLastModified
    [String]$classSourcedId
    [String]$schoolSourcedId
    [String]$userSourcedId
    [OR_RoleType]$role
    [bool]$primary
    [DateTime]$beginDate
    [DateTime]$endDate

    OR_enrollment(
        [object]$InputObject
    )
    {
        If ($InputObject.Count -gt 1)
        {
            Write-Error "More then one enrollment object"
        }
        If (($InputObject |Get-Member).TypeName -eq "Deserialized.OR_enrollment")
        {
            $this.status = $InputObject.status
            $this.dateLastModified = $InputObject.dateLastModified
            $this.role = $InputObject.role
            $this.primary = $InputObject.primary
            $this.beginDate = $InputObject.beginDate
            $this.endDate = $InputObject.endDate
        }
        Else
        {
            $this.status = [OneRoster]::StatusFrom($InputObject.status)
            $this.dateLastModified = [OneRoster]::DateFrom($InputObject.dateLastModified)
            $this.role = [OneRoster]::RoleFrom($InputObject.role)
            $this.primary = [OneRoster]::BooleanFrom($InputObject.primary)
            $this.beginDate = [OneRoster]::DateFrom($InputObject.beginDate)
            $this.endDate = [OneRoster]::DateFrom($InputObject.endDate)
        }
        $this.sourcedId = $InputObject.sourcedId
        $this.classSourcedId = $InputObject.classSourcedId
        $this.schoolSourcedId = $InputObject.schoolSourcedId
        $this.userSourcedId = $InputObject.userSourcedId
    }

    [String] ToString()
    {
        $l = New-Object Collections.Generic.List[String]
        $l.Add('"')
        $l.Add($this.sourcedId)
        $l.Add('","')
        $l.Add($this.status)
        $l.Add('","')
        $l.Add([OneRoster]::StringFrom($this.dateLastModified))
        $l.Add('","')
        $l.Add($this.classSourcedId)
        $l.Add('","')
        $l.Add($this.schoolSourcedId)
        $l.Add('","')
        $l.Add($this.userSourcedId)
        $l.Add('","')
        $l.Add($this.role)
        $l.Add('","')
        $l.Add([OneRoster]::StringFrom($this.primary))
        $l.Add('","')
        $l.Add([OneRoster]::StringFrom($this.beginDate))
        $l.Add('","')
        $l.Add([OneRoster]::StringFrom($this.endDate))
        $l.Add('"')
        Return $l -join ""
    }
}

Function Convert-ORenrollment
{
    [OutputType('OR_enrollment')]
    [cmdletbinding()]
    Param
    (
        [parameter(Mandatory = $true,ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
        [Object[]]
        $InputPipe
    )
    PROCESS
    {
        Return [OR_enrollment]::new($InputPipe)
    }
}

Function Import-ORenrollment
{
    [OutputType('OR_enrollment')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,
        [parameter(Mandatory = $false)]
        [String]
        $Encoding = "UTF8"

    )
    BEGIN
    {
        $private:l = $Null
        If ((Test-Path -Path $Path -PathType Leaf))
        {
            $private:l = Get-ChildItem -Path $Path
        }
        $private:OR_Path_TMP = New-TemporaryFile
    }
    PROCESS
    {
        If ($null -ceq $private:l)
        {
            Return
        }
        Return Import-Csv -LiteralPath (Copy-Item -Path $Path -Destination $private:OR_Path_TMP -PassThru) -Encoding $Encoding -ErrorAction Stop | Convert-ORenrollment
    }
    END
    {
        If ($null -ceq $private:l)
        {
            Return
        }
        $private:OR_Path_TMP | Remove-Item
    }
}

Function Out-ORenrollment
{
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [OR_enrollment[]]$InputObject,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $FilePath,
        [parameter(Mandatory = $false)]
        [String]
        $Encoding = "UTF8"
    )
    BEGIN
    {
        '"sourcedId","status","dateLastModified","classSourcedId","schoolSourcedId","userSourcedId","role","primary","beginDate","endDate"' | Out-File -Encoding $Encoding -FilePath $FilePath
    }
    PROCESS
    {
        $InputObject | ForEach-Object {
            $_.ToString()
        } | Out-File -Append -Encoding $Encoding -FilePath $FilePath
    }
}

Function Read-ORenrollments
{
    #[OutputType('OR_enrollment')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [String]$FolderPath = ".",
        [Parameter(Mandatory = $false)]
        [OR_Org]$Org = $null,
        [Parameter(Mandatory = $false)]
        [Bool]$LoadXML = $false
    )
    BEGIN
    {
        If ($LoadXML -eq $true)
        {
            If ($null -ceq $Org)
            {
                $FileName = "enrollments.xml"
            }
            Else
            {
                $FileName = "enrollments_$($Org.sourcedId).xml"
            }
        }
        Else
        {
            If ($null -ceq $Org)
            {
                $FileName = "enrollments.csv"
            }
            Else
            {
                $FileName = "enrollments_$($Org.sourcedId).csv"
            }
        }
        $FilePath = Join-Path -Path $FolderPath -ChildPath $FileName
    }
    PROCESS
    {
        If (-not (Test-Path -Path $FilePath -PathType Leaf))
        {
            Return
        }
        If ($LoadXML)
        {
            Import-Clixml -Path $FilePath -ErrorAction Stop
        }
        Else
        {
            Import-ORenrollment -Path $FilePath
        }
    }
    END
    {
    }
}

#---------------------------------------------------------------------------------------------------------------------------------
#Class
#---------------------------------------------------------------------------------------------------------------------------------

class OR_class
{
    [String]$sourcedId
    [OR_StatusType]$status
    [DateTime]$dateLastModified
    [String]$title
    [String[]]$grades
    [String]$courseSourcedId
    [String]$classCode
    [OR_ClassType]$classType
    [String]$location
    [String]$schoolSourcedId
    [String[]]$termSourcedIds
    [String[]]$subjects
    [String[]]$subjectCodes
    [String[]]$periods

    OR_class(
        [object]$InputObject
    )
    {
        If ($InputObject.Count -gt 1)
        {
            Write-Error "More then one class object"
        }
        If (($InputObject |Get-Member).TypeName -eq "Deserialized.OR_class")
        {
            $this.status = $InputObject.status
            $this.dateLastModified = $InputObject.datelastmodified
            $this.classType = $InputObject.classType
            $this.grades = $InputObject.grades
            $this.termSourcedIds = $InputObject.termSourcedIds
            $this.subjects = $InputObject.subjects
            $this.subjectCodes = $InputObject.subjectCodes
            $this.periods = $InputObject.periods
        }
        Else
        {
            $this.status = [OneRoster]::StatusFrom($InputObject.status)
            $this.dateLastModified = [OneRoster]::DateFrom($InputObject.datelastmodified)
            $this.classType = [OneRoster]::ClassFrom($InputObject.classType)
            $this.grades = $InputObject.grades -split ","
            $this.termSourcedIds = $InputObject.termSourcedIds -split ","
            $this.subjects = $InputObject.subjects -split ","
            $this.subjectCodes = $InputObject.subjectCodes -split ","
            $this.periods = $InputObject.periods -split ","
        }
        $this.sourcedId = $InputObject.sourcedId
        $this.title = $InputObject.title
        $this.courseSourcedId = $InputObject.courseSourcedId
        $this.classCode = $InputObject.classCode
        $this.location = $InputObject.location
        $this.schoolSourcedId = $InputObject.schoolSourcedId
    }

    [String] ToString()
    {
        $l = New-Object Collections.Generic.List[String]
        $l.Add('"')
        $l.Add($this.sourcedId)
        $l.Add('","')
        $l.Add($this.status)
        $l.Add('","')
        $l.Add([OneRoster]::StringFrom($this.dateLastModified))
        $l.Add('","')
        $l.Add($this.title)
        $l.Add('","')
        $l.Add($this.grades -join ",")
        $l.Add('","')
        $l.Add($this.courseSourcedId)
        $l.Add('","')
        $l.Add($this.classCode)
        $l.Add('","')
        $l.Add($this.classType)
        $l.Add('","')
        $l.Add($this.location)
        $l.Add('","')
        $l.Add($this.schoolSourcedId)
        $l.Add('","')
        $l.Add($this.termSourcedIds -join ",")
        $l.Add('","')
        $l.Add($this.subjects -join ",")
        $l.Add('","')
        $l.Add($this.subjectCodes -join ",")
        $l.Add('","')
        $l.Add($this.periods -join ",")
        $l.Add('"')
        return $l -join ""
    }
}

Function Convert-ORclass
{
    [OutputType('OR_class')]
    [cmdletbinding()]
    Param
    (
        [parameter(Mandatory = $true,ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
        [Object[]]
        $InputPipe
    )
    PROCESS
    {
        Return [OR_class]::new($InputPipe)
    }
}

Function Import-ORclass
{
    [OutputType('OR_class')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,
        [parameter(Mandatory = $false)]
        [String]
        $Encoding = "UTF8"

    )
    BEGIN
    {
        $private:l = $Null
        If ((Test-Path -Path $Path -PathType Leaf))
        {
            $private:l = Get-ChildItem -Path $Path
        }
        $private:OR_Path_TMP = New-TemporaryFile
    }
    PROCESS
    {
        If ($null -ceq $private:l)
        {
            Return
        }
        Return Import-Csv -LiteralPath (Copy-Item -Path $Path -Destination $private:OR_Path_TMP -PassThru) -Encoding $Encoding -ErrorAction Stop | Convert-ORclass
    }
    END
    {
        If ($null -ceq $private:l)
        {
            Return
        }
        $private:OR_Path_TMP | Remove-Item
    }
}

Function Out-ORclass
{
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [OR_class[]]$InputObject,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $FilePath,
        [parameter(Mandatory = $false)]
        [String]
        $Encoding = "UTF8"
    )
    BEGIN
    {
        '"sourcedId","status","dateLastModified","title","grades","courseSourcedId","classCode","classType","location","schoolSourcedId","termSourcedIds","subjects","subjectCodes","periods"' | Out-File -Encoding $Encoding -FilePath $FilePath
    }
    PROCESS
    {
        $InputObject | ForEach-Object {
            $_.ToString()
        } | Out-File -Append -Encoding $Encoding -FilePath $FilePath
    }
}

Function Read-ORclasses
{
    [OutputType('OR_class')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [String]$FolderPath = ".",
        [Parameter(Mandatory = $false)]
        [OR_Org]$Org = $null,
        [Parameter(Mandatory = $false)]
        [Bool]$LoadXML = $false
    )
    BEGIN
    {
        If ($LoadXML -eq $true)
        {
            If ($null -ceq $Org)
            {
                $FileName = "classes.xml"
            }
            Else
            {
                $FileName = "classes_$($Org.sourcedId).xml"
            }
        }
        Else
        {
            If ($null -ceq $Org)
            {
                $FileName = "classes.csv"
            }
            Else
            {
                $FileName = "classes_$($Org.sourcedId).csv"
            }
        }
        $FilePath = Join-Path -Path $FolderPath -ChildPath $FileName
    }
    PROCESS
    {
        If (-not (Test-Path -Path $FilePath -PathType Leaf))
        {
            Return
        }
        If ($LoadXML)
        {
            Import-Clixml -Path $FilePath -ErrorAction Stop
        }
        Else
        {
            Import-ORclass -Path $FilePath
        }
    }
    END
    {
    }
}

#---------------------------------------------------------------------------------------------------------------------------------
#User
#---------------------------------------------------------------------------------------------------------------------------------

class OR_user
{
    [String]$sourcedId
    [OR_StatusType]$status
    [DateTime]$dateLastModified
    [bool]$enabledUser
    [String[]]$orgSourcedIds
    [OR_RoleType]$role
    [String]$username
    [String[]]$userIds
    [String]$givenName
    [String]$familyName
    [String]$MiddleName
    [String]$identifier
    [String]$email
    [String]$sms
    [String]$phone
    [String[]]$agentSourcedIds
    [String]$grades
    [String]$password

    OR_user(
        [object]$InputObject
    )
    {
        If ($InputObject.Count -gt 1)
        {
            Write-Error "More then one user object"
        }
        If (($InputObject |Get-Member).TypeName -eq "Deserialized.OR_user")
        {
            $this.status = $InputObject.status
            $this.dateLastModified = $InputObject.datelastmodified
            $this.enabledUser = $InputObject.enabledUser
            $this.orgSourcedIds = $InputObject.orgSourcedIds
            $this.role = $InputObject.role
            $this.userIds = $InputObject.userIds
            $this.agentSourcedIds = $InputObject.agentSourcedIds
        }
        Else
        {
            $this.status = [OneRoster]::StatusFrom($InputObject.status)
            $this.dateLastModified = [OneRoster]::DateFrom($InputObject.datelastmodified)
            $this.enabledUser = [OneRoster]::BooleanFrom($InputObject.enabledUser)
            $this.orgSourcedIds = $InputObject.orgSourcedIds -split ","
            $this.role = [OneRoster]::RoleFrom($InputObject.role)
            $this.userIds = $InputObject.userIds -split ","
            $this.agentSourcedIds = $InputObject.agentSourcedIds -split ","
        }
        $this.sourcedId = $InputObject.sourcedId
        $this.username = $InputObject.username
        $this.givenName = $InputObject.givenName
        $this.familyName = $InputObject.familyName
        $this.MiddleName = $InputObject.MiddleName
        $this.identifier = $InputObject.identifier
        $this.email = $InputObject.email
        $this.sms = $InputObject.sms
        $this.phone = $InputObject.phone
        $this.grades = $InputObject.grades
        $this.password = $InputObject.password
    }

    [String] ToString()
    {
        $l = New-Object Collections.Generic.List[String]
        $l.Add('"')
        $l.Add($this.sourcedId)
        $l.Add('","')
        $l.Add($this.status)
        $l.Add('","')
        $l.Add([OneRoster]::StringFrom($this.dateLastModified))
        $l.Add('","')
        $l.Add([OneRoster]::StringFrom($this.enabledUser))
        $l.Add('","')
        $l.Add($this.orgSourcedIds -join ",")
        $l.Add('","')
        $l.Add($this.role)
        $l.Add('","')
        $l.Add($this.username)
        $l.Add('","')
        $l.Add($this.userIds -join ",")
        $l.Add('","')
        $l.Add($this.givenName)
        $l.Add('","')
        $l.Add($this.familyName)
        $l.Add('","')
        $l.Add($this.MiddleName)
        $l.Add('","')
        $l.Add($this.identifier)
        $l.Add('","')
        $l.Add($this.email)
        $l.Add('","')
        $l.Add($this.sms)
        $l.Add('","')
        $l.Add($this.phone)
        $l.Add('","')
        $l.Add($this.agentSourcedIds -join ",")
        $l.Add('","')
        $l.Add($this.grades)
        $l.Add('","')
        $l.Add($this.password)
        $l.Add('"')
        Return $l -join ""
    }
}

Function Convert-ORuser
{
    [OutputType('OR_user')]
    [cmdletbinding()]
    Param
    (
        [parameter(Mandatory = $true,ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
        [Object[]]
        $InputPipe
    )
    PROCESS
    {
        Return [OR_user]::new($InputPipe)
    }
}

Function Import-ORuser
{
    [OutputType('OR_user')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,
        [parameter(Mandatory = $false)]
        [String]
        $Encoding = "UTF8"

    )
    BEGIN
    {
        $private:l = $Null
        If ((Test-Path -Path $Path -PathType Leaf))
        {
            $private:l = Get-ChildItem -Path $Path
        }
        $private:OR_Path_TMP = New-TemporaryFile
    }
    PROCESS
    {
        If ($null -ceq $private:l)
        {
            Return
        }
        Return Import-Csv -LiteralPath (Copy-Item -Path $Path -Destination $private:OR_Path_TMP -PassThru) -Encoding $Encoding -ErrorAction Stop | Convert-ORuser
    }
    END
    {
        If ($null -ceq $private:l)
        {
            Return
        }
        $private:OR_Path_TMP | Remove-Item
    }
}

Function Out-ORuser
{
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [OR_User[]]$InputObject,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $FilePath,
        [parameter(Mandatory = $false)]
        [String]
        $Encoding = "UTF8"
    )
    BEGIN
    {
        '"sourcedId","status","dateLastModified","enabledUser","orgSourcedIds","role","username","userIds","givenName","familyName","middleName","identifier","email","sms","phone","agentSourceIds","grades","password"' | Out-File -Encoding $Encoding -FilePath $FilePath
    }
    PROCESS
    {
        $InputObject | ForEach-Object {
            $_.ToString()
        } | Out-File -Append -Encoding $Encoding -FilePath $FilePath
    }
}

Function Read-ORUsers
{
    [OutputType('OR_user')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [String]$FolderPath = ".",
        [Parameter(Mandatory = $false)]
        [OR_Org]$Org = $null,
        [Parameter(Mandatory = $false)]
        [Bool]$LoadXML = $false
    )
    BEGIN
    {
        If ($LoadXML -eq $true)
        {
            If ($null -ceq $Org)
            {
                $FilePath = Join-Path -Path $FolderPath -ChildPath "users.xml"
            }
            Else
            {
                $FilePath = Join-Path -Path $FolderPath -ChildPath "users_$($Org.sourcedId).xml"
            }
        }
        Else
        {
            IF ($null -ceq $Org)
            {
                $FilePath = Join-Path -Path $FolderPath -ChildPath "users.csv"
            }
            Else
            {
                $FilePath = Join-Path -Path $FolderPath -ChildPath "users_$($Org.sourcedId).csv"
            }
        }
    }
    PROCESS
    {
        If (-not (Test-Path -Path $FilePath -PathType Leaf))
        {
            Return
        }
        If ($LoadXML -eq $true)
        {
            Import-Clixml -Path $FilePath -ErrorAction Stop
        }
        Else
        {
            Import-ORuser -Path $FilePath
        }
    }
    END
    {
    }
}

#---------------------------------------------------------------------------------------------------------------------------------
#Demographics
#---------------------------------------------------------------------------------------------------------------------------------

#TODO

#---------------------------------------------------------------------------------------------------------------------------------
#Find
#---------------------------------------------------------------------------------------------------------------------------------

Function Find-ORClasses
{
    [OutputType('OR_class')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$FolderPath = ".",
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [OR_academicSession[]]$academicSessions = @(),
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Int32]$ProgressId = -1
    )
    BEGIN
    {
        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Classes" -Status "Starting" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORClasses: Starting"
        }

        $academicSessions_F = $null
        If ($academicSessions.Count -gt 0)
        {
            $academicSessions_F = $academicSessions.sourcedId
        }

        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Classes" -Status "Loading" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORClasses: Loading"
        }

        $classes_I = @()
        If ($null -ceq $academicSessions_F)
        {
            $classes_I += Read-ORclasses -FolderPath $FolderPath
        }
        Else
        {
            $classes_I += Read-ORclasses -FolderPath $FolderPath | Where-Object -Property termSourcedIds -in -Value $academicSessions_F
        }

        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Classes" -Status "Loaded" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORClasses: Loaded"
        }
    }
    PROCESS
    {
        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Processing OneRoster Classes" -Status "Process" -Id $ProgressId
        }

        Return $classes_I
    }
    END
    {
        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Classes" -Status "Done" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORClasses: Done"
        }
    }
}

Function Find-ORClassesByCourse
{
    [OutputType('OR_class')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$FolderPath = ".",
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [OR_course[]]$course_E = $null,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [OR_academicSession[]]$academicSessions = @(),
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Int32]$ProgressId = -1
    )
    BEGIN
    {
        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Classes By Course" -Status "Starting" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORClassesByCourse: Starting"
        }

        $academicSessions_F = $null
        If ($academicSessions.Count -gt 0)
        {
            $academicSessions_F = $academicSessions.sourcedId
        }

        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Classes By Course" -Status "Loading" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORClassesByCourse: Loading"
        }

        $classes_I = @()
        If ($null -ceq $academicSessions_F)
        {
            $classes_I += Read-ORclasses -FolderPath $FolderPath
        }
        Else
        {
            $classes_I += Read-ORclasses -FolderPath $FolderPath | Where-Object -Property termSourcedIds -In -Value $academicSessions_F
        }

        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Classes By Course" -Status "Loaded" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORClassesByCourse: Loaded"
        }
    }
    PROCESS
    {
        If ($ProgressId -ge 0)
        {
            If ($null -ceq $course_E)
            {
                $title = "Any"
            }
            Else
            {
                $title = $course_E.title
            }

            Write-Progress -Activity "Processing OneRoster Classes By Course: $($title)" -Status "Process" -Id $ProgressId
        }

        If ($null -ceq $course_E)
        {
            Return $classes_I
        }
        Else
        {
            $course_F = $course_E.sourcedId
            Return $classes_I | Where-Object -Property courseSourcedId -In -Value $course_F
        }
    }
    END
    {
        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Classes By Course" -Status "Done" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORClassesByCourse: Done"
        }
    }
}

Function Find-ORClassesByOrg
{
    [OutputType('OR_class')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$FolderPath = ".",
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [OR_course[]]$org_E = $null,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [OR_academicSession[]]$academicSessions = @(),
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Int32]$ProgressId = -1
    )
    BEGIN
    {
        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Classes By Org" -Status "Starting" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORClassesByOrg: Starting"
        }

        $academicSessions_F = $null
        If ($academicSessions.Count -gt 0)
        {
            $academicSessions_F = $academicSessions.sourcedId
        }

        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Classes By Org" -Status "Loading" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORClassesByOrg: Loading"
        }

        $classes_I = @()
        If ($null -ceq $academicSessions_F)
        {
            $classes_I += Read-ORclasses -FolderPath $FolderPath
        }
        Else
        {
            $classes_I += Read-ORclasses -FolderPath $FolderPath | Where-Object -Property termSourcedIds -In -Value $academicSessions_F
        }

        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Classes By Org" -Status "Loaded" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORClassesByOrg: Loaded"
        }
    }
    PROCESS
    {
        If ($ProgressId -ge 0)
        {
            If ($null -ceq $org_E)
            {
                $title = "Any"
            }
            Else
            {
                $title = $org_E.title
            }

            Write-Progress -Activity "Processing OneRoster Classes By Org: $($title)" -Status "Process" -Id $ProgressId
        }

        If ($null -ceq $org_E)
        {
            Return $classes_I
        }
        Else
        {
            $org_F += $org_E.sourcedId
            Return $classes_I | Where-Object -Property schoolSourcedId -In -Value $org_F
        }
    }
    END
    {
        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Classes" -Status "Done" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORClasses: Done"
        }
    }
}

Function Find-ORCourses
{
    [OutputType('OR_course')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$FolderPath = ".",
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [OR_org[]]$org_E = $null,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [OR_academicSession[]]$academicSessions = @(),
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Int32]$ProgressId = -1
    )
    BEGIN
    {
        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Courses" -Status "Starting" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORCourses: Starting"
        }

        $academicSessions_F = $null
        If ($academicSessions.Count -gt 0)
        {
            $academicSessions_F = $academicSessions.schoolYear
        }

        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Courses" -Status "Loading" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORCourses: Loading"
        }

        $Courses_I = @()
        If ($null -ceq $academicSessions_F)
        {
            $Courses_I += Read-ORCourses -FolderPath $FolderPath
        }
        Else
        {
            $Courses_I += Read-ORCourses -FolderPath $FolderPath | Where-Object -Property schoolYearSourcedId -In -Value $academicSessions_F
        }

        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Courses" -Status "Loaded" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORCourses: Loaded"
        }
    }
    PROCESS
    {
        If ($ProgressId -ge 0)
        {
            If ($null -ceq $org_E)
            {
                Write-Progress -Activity "Processing OneRoster Course" -Status "Process" -Id $ProgressId
            }
            Else
            {
                Write-Progress -Activity "Processing OneRoster Course By Org: $($org_e.title)" -Status "Process" -Id $ProgressId
            }
        }

        If ($null -ceq $org_E)
        {
            Return $Courses_I
        }
        else
        {
            $org_F = $org_E.sourcedId
            Return [OneRoster_FastSearch.Search]::FindAll($Courses_I,"orgSourcedId",$org_F) #$Courses_I | Where-Object -Property orgSourcedId -CEQ -Value $org_F
        }
    }
    END
    {
        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Course" -Status "Done" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-ORCourses: Done"
        }
    }
}

Function Find-OROrgs
{
    [OutputType('OR_org')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$FolderPath = ".",
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [OR_org[]]$org_E = $null,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [OR_org[]]$orgs = @(),
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Int32]$ProgressId = -1
    )
    BEGIN
    {
        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Orgs" -Status "Starting" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-OROrgs: Starting"
        }

        $orgs_F = $null
        If ($orgs.Count -gt 0)
        {
            $orgs_F = $orgs.sourcedId
        }

        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Orgs" -Status "Loading" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-OROrgs: Loading"
        }

        $Orgs_I = @()
        If ($null -ceq $org_F)
        {
            $Orgs_I += Read-OROrgs -FolderPath $FolderPath
        }
        Else
        {
            $Orgs_I += Read-OROrgs -FolderPath $FolderPath | Where-Object -Property parentSourcedId -In -Value $orgs_F
        }

        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Orgs" -Status "Loaded" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-OROrgs: Loaded"
        }
    }
    PROCESS
    {
        If ($ProgressId -ge 0)
        {
            If ($null -ceq $org_E)
            {
                $name = "Any"
            }
            Else
            {
                $name = $org_E.name
            }
            Write-Progress -Activity "Processing OneRoster Orgs By Org: $($name)" -Status "Process" -Id $ProgressId
        }

        If ($null -ceq $org_E)
        {
            Return $Orgs_I
        }
        else
        {
            $org_F = $org_E.sourcedId
            Return $Orgs_I | Where-Object -Property parentSourcedId -In -Value $orgs_F
        }
    }
    END
    {
        If ($ProgressId -ge 0)
        {
            Write-Progress -Activity "Finding OneRoster Orgs" -Status "Done" -Id $ProgressId
        }
        Else
        {
            Write-Verbose "Find-OROrgs: Done"
        }
    }
}

#---------------------------------------------------------------------------------------------------------------------------------
#Split
#---------------------------------------------------------------------------------------------------------------------------------

Function Split-ORClasses
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$SourceFolderPath = ".",
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$DestFolderPath = ".",
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [OR_org[]]$org_E = $null,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Bool]$XMLInput = $false,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Bool]$XMLOutput = $false
    )
    BEGIN
    {
        If ($XMLInput -eq $true)
        {
            $InputFP = Join-Path -Path $SourceFolderPath -ChildPath "classes.xml"
            $raw = Import-Clixml -Path $InputFP -ErrorAction Stop
        }
        Else
        {
            $InputFP = Join-Path -Path $SourceFolderPath -ChildPath "classes.csv"
            $raw = Import-Csv -Path $InputFP -Encoding UTF8 -ErrorAction Stop
        }
    }
    PROCESS
    {
        $out = @()
        $sourcedId = $org_E.sourcedId
        $out += [OneRoster_FastSearch.Search]::FindAll($raw,"schoolSourcedId",$sourcedId) #$raw | Where-Object -Property schoolSourcedId -CEQ -Value $sourcedId
        If ($XMLOutput -eq $true)
        {
            $OutputFP = Join-Path -Path $DestFolderPath -ChildPath "classes_$($sourcedId).xml"
            If ($out.Count -gt 0)
            {
                $out | Convert-ORclass | Export-Clixml -Path $OutputFP -Depth 1 -Encoding UTF8 -ErrorAction Stop
            }
            ElseIf ((Test-Path -Path $OutputFP -PathType Leaf))
            {
                Remove-Item -Path $OutputFP -Force -Confirm:$false
            }
        }
        Else
        {
            $OutputFP = Join-Path -Path $DestFolderPath -ChildPath "classes_$($sourcedId).csv"
            If ($out.Count -gt 0)
            {
                $out | Export-Csv -Path $OutputFP -Encoding UTF8 -ErrorAction Stop
            }
            ElseIf ((Test-Path -Path $OutputFP -PathType Leaf))
            {
                Remove-Item -Path $OutputFP -Force -Confirm:$false
            }
        }
    }
}

Function Split-ORCourses
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$SourceFolderPath = ".",
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$DestFolderPath = ".",
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [OR_org[]]$org_E = $null,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Bool]$XMLInput = $false,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Bool]$XMLOutput = $false
    )
    BEGIN
    {
        If ($XMLInput -eq $true)
        {
            $InputFP = Join-Path -Path $SourceFolderPath -ChildPath "courses.xml"
            $raw = Import-Clixml -Path $InputFP -ErrorAction Stop
        }
        Else
        {
            $InputFP = Join-Path -Path $SourceFolderPath -ChildPath "courses.csv"
            $raw = Import-Csv -Path $InputFP -Encoding UTF8 -ErrorAction Stop
        }
    }
    PROCESS
    {
        $out = @()
        $sourcedId = $org_E.sourcedId
        $out += [OneRoster_FastSearch.Search]::FindAll($raw,"orgSourcedId",$sourcedId) #$raw | Where-Object -Property orgSourcedId -CEQ -Value $sourcedId
        If ($XMLOutput -eq $true)
        {
            $OutputFP = Join-Path -Path $DestFolderPath -ChildPath "courses_$($sourcedId).xml"
            If ($out.Count -gt 0)
            {
                $out | Convert-ORcourse | Export-Clixml -Path $OutputFP -Depth 1 -Encoding UTF8 -ErrorAction Stop
            }
            ElseIf ((Test-Path -Path $OutputFP -PathType Leaf))
            {
                Remove-Item -Path $OutputFP -Force -Confirm:$false
            }
        }
        Else
        {
            $OutputFP = Join-Path -Path $DestFolderPath -ChildPath "courses_$($sourcedId).csv"
            If ($out.Count -gt 0)
            {
                $out | Export-Csv -Path $OutputFP -Encoding UTF8 -ErrorAction Stop
            }
            ElseIf ((Test-Path -Path $OutputFP -PathType Leaf))
            {
                Remove-Item -Path $OutputFP -Force -Confirm:$false
            }
        }
    }
}

Function Split-OREnrollments
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$SourceFolderPath = ".",
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$DestFolderPath = ".",
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [OR_org[]]$org_E = $null,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Bool]$XMLInput = $false,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Bool]$XMLOutput = $false
    )
    BEGIN
    {
        If ($XMLInput -eq $true)
        {
            $InputFP = Join-Path -Path $SourceFolderPath -ChildPath "enrollments.xml"
            $raw = Import-Clixml -Path $InputFP -ErrorAction Stop
        }
        Else
        {
            $InputFP = Join-Path -Path $SourceFolderPath -ChildPath "enrollments.csv"
            $raw = Import-Csv -Path $InputFP -Encoding UTF8 -ErrorAction Stop
        }
    }
    PROCESS
    {
        $out = @()
        If ($null -ceq $org_E)
        {
            $out += $raw
        }
        ElseIf ($null -cne $raw -and $raw.Count -gt 0)
        {
            $sourcedId = $org_E.sourcedId
            $out += [OneRoster_FastSearch.Search]::FindAll($raw,"schoolSourcedId",$sourcedId) #$raw | Where-Object -Property schoolSourcedId -CEQ -Value $sourcedId
        }
        If ($XMLOutput -eq $true)
        {
            If ($null -ceq $org_E)
            {
                $OutputFP = Join-Path -Path $DestFolderPath -ChildPath "enrollments.xml"
            }
            Else
            {
                $OutputFP = Join-Path -Path $DestFolderPath -ChildPath "enrollments_$($sourcedId).xml"
            }
            If ($out.Count -gt 0)
            {
                If ($XMLInput -eq $true)
                {
                    $out | Export-Clixml -Path $OutputFP -Depth 2 -Encoding UTF8 -ErrorAction Stop
                }
                else
                {
                    $out | Convert-ORenrollment | Export-Clixml -Path $OutputFP -Depth 2 -Encoding UTF8 -ErrorAction Stop
                }
            }
            ElseIf ((Test-Path -Path $OutputFP -PathType Leaf))
            {
                Remove-Item -Path $OutputFP -Force -Confirm:$false
            }
        }
        Elseif ($XMLInput -eq $false)
        {
            $OutputFP = Join-Path -Path $DestFolderPath -ChildPath "enrollments_$($sourcedId).csv"
            If ($out.Count -gt 0)
            {
                $out | Export-Csv -Path $OutputFP -Encoding UTF8 -ErrorAction Stop
            }
            ElseIf ((Test-Path -Path $OutputFP -PathType Leaf))
            {
                Remove-Item -Path $OutputFP -Force -Confirm:$false
            }
        }
    }
}

Function Split-ORUsers
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$SourceFolderPath = ".",
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [String]$DestFolderPath = ".",
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [OR_org[]]$org_E = $null,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Bool]$XMLInput = $false,
        [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [Bool]$XMLOutput = $false
    )
    BEGIN
    {
        If ($XMLInput -eq $true)
        {
            $InputFP = Join-Path -Path $SourceFolderPath -ChildPath "users.xml"
            $raw = Import-Clixml -Path $InputFP -ErrorAction Stop
        }
        Else
        {
            $InputFP = Join-Path -Path $SourceFolderPath -ChildPath "users.csv"
            $raw = Import-Csv -Path $InputFP -Encoding UTF8 -ErrorAction Stop
        }
    }
    PROCESS
    {
        $out = @()
        If ($null -ceq $org_E)
        {
            $out += $raw
        }
        Else
        {
            $sourcedId = $org_E.sourcedId
            If ($XMLInput -eq $true)
            {
                $out += $raw | Where-Object -FilterScript {$sourcedId -cin $_.orgSourcedIds} #-Property orgSourcedIds -CIn -Value $sourcedId
            }
            Else
            {
                $out += $raw | Where-Object -FilterScript {$sourcedId -cin ($_.orgSourcedIds -split ",")} #-Property orgSourcedIds -Contains -Value $sourcedId
            }
        }
        If ($XMLOutput -eq $true)
        {
            If ($null -ceq $org_E)
            {
                $OutputFP = Join-Path -Path $DestFolderPath -ChildPath "users.xml"
            }
            Else
            {
                $OutputFP = Join-Path -Path $DestFolderPath -ChildPath "users_$($sourcedId).xml"
            }
            If ($out.Count -gt 0)
            {
                If ($XMLInput -eq $true)
                {
                    $out | Export-Clixml -Path $OutputFP -Depth 2 -Encoding UTF8 -ErrorAction Stop
                }
                else
                {
                    $out | Convert-ORenrollment | Export-Clixml -Path $OutputFP -Depth 2 -Encoding UTF8 -ErrorAction Stop
                }
            }
            ElseIf ((Test-Path -Path $OutputFP -PathType Leaf))
            {
                Remove-Item -Path $OutputFP -Force -Confirm:$false
            }
        }
        Elseif ($XMLInput -eq $false)
        {
            $OutputFP = Join-Path -Path $DestFolderPath -ChildPath "users_$($sourcedId).csv"
            If ($out.Count -gt 0)
            {
                $out | Export-Csv -Path $OutputFP -Encoding UTF8 -ErrorAction Stop
            }
            ElseIf ((Test-Path -Path $OutputFP -PathType Leaf))
            {
                Remove-Item -Path $OutputFP -Force -Confirm:$false
            }
        }
    }
}


#---------------------------------------------------------------------------------------------------------------------------------
#Filter Limit
#---------------------------------------------------------------------------------------------------------------------------------

Function Limit-ORUserBysourcedId #USED
{
    #[OutputType('OR_user')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        #[OR_user[]]
        $user_E,
        [Parameter(Mandatory = $true)]
        [String[]]
        $sourcedId
    )
    PROCESS
    {
        #Write-Warning "Limit-ORUserBysourcedId"
        $user_E | Where-Object -Property sourcedId -In -Value $sourcedId
    }
}

Function Limit-ORUserBystatus #UNUSED
{
    #[OutputType('OR_user')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        #[OR_user[]]
        $user_E,
        [Parameter(Mandatory = $true)]
        [OR_StatusType[]]
        $status
    )
    PROCESS
    {
        Write-Warning "Limit-ORUserBystatus"
        $user_E | Where-Object -Property status -In -Value $status
    }
}

Function Limit-ORUserByRole #USED
{
    #[OutputType('OR_user')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        #[OR_user[]]
        $user_E,
        [Parameter(Mandatory = $true)]
        [OR_RoleType[]]
        $role
    )
    PROCESS
    {
        $user_E | Where-Object -Property role -In -Value $role
    }
}

Function Limit-ORUserByNotRole #USED
{
    #[OutputType('OR_user')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        #[OR_user[]]
        $user_E,
        [Parameter(Mandatory = $true)]
        [OR_RoleType[]]
        $role
    )
    PROCESS
    {
        Write-Warning "Limit-ORUserByNotRole"
        $user_E | Where-Object -Property role -NotIn -Value $role
    }
}


Function Limit-OREnrollmentBystatus #UNUSED
{
    #[OutputType('OR_enrollment')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        #[OR_enrollment[]]
        $enrollment_E,
        [Parameter(Mandatory = $false)]
        [OR_StatusType[]]
        $status = @([OR_StatusType]::active)
    )
    BEGIN
    {
        $istatus = [Int32]$($status)
    }
    PROCESS
    {
        Write-Warning "Limit-OREnrollmentBystatus"
        $enrollment_E | Where-Object -Property status -In -Value $istatus
    }
}

Function Limit-OREnrollmentByclassSourcedId #USED
{
    #[OutputType('OR_enrollment')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        #[OR_enrollment[]]
        $enrollment_E,
        [Parameter(Mandatory = $false)]
        [String[]]
        $classSourcedId
    )
    PROCESS
    {
        Write-Warning "Limit-OREnrollmentByclassSourcedId"
        $enrollment_E | Where-Object -Property classSourcedId -In -Value $classSourcedId
    }
}

Function Limit-OREnrollmentByschoolSourcedId #USED
{
    #[OutputType('OR_enrollment')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        #[OR_enrollment[]]
        $enrollment_E,
        [Parameter(Mandatory = $false)]
        [String[]]
        $schoolSourcedId
    )
    PROCESS
    {
        Write-Warning "PLEASE USE GROUPING for Limit-OREnrollmentByschoolSourcedId"
        $enrollment_E | Where-Object -Property schoolSourcedId -In -Value $schoolSourcedId
    }
}

Function Limit-OREnrollmentNotByuserSourcedId #USED
{
    #[OutputType('OR_enrollment')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        #[OR_enrollment[]]
        $enrollment_E,
        [Parameter(Mandatory = $false)]
        [string[]]
        $userSourcedId
    )
    PROCESS
    {
        Write-Warning "Limit-OREnrollmentNotByuserSourcedId"
        $enrollment_E | Where-Object -Property userSourcedId -NotIn -Value $userSourcedId
    }
}

Function Limit-OREnrollmentByrole #USED
{
    #[OutputType('OR_enrollment')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        #[OR_enrollment[]]
        $user_E,
        [Parameter(Mandatory = $true)]
        [OR_RoleType[]]
        $role
    )
    PROCESS
    {
        $user_E | Where-Object -Property role -In -Value $role
    }
}

Function Limit-OREnrollmentIsPrimary #USED
{
    #[OutputType('OR_enrollment')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        #[OR_enrollment[]]
        $enrollment_E,
        [Parameter(Mandatory = $false)]
        [bool]
        $primary = $true
    )
    PROCESS
    {
        [OneRoster_FastSearch.Search]::FindAll($enrollment_E,"primary",$primary) #$enrollment_E | Where-Object -Property primary -EQ -Value $primary
    }
}

Function Limit-OREnrollmentByDate #USED
{
    #[OutputType('OR_enrollment')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        #[OR_enrollment[]]
        $enrollment_E,
        [DateTime]
        $Date = 0,
        [TimeSpan]
        $BeginLayway = 0,
        [TimeSpan]
        $EndLayway = 0
    )
    BEGIN
    {
        If ($Date -eq 0)
        {
            $Date = Get-Date
        }
        $beginDate = $Date.Add($BeginLayway)
        $endDate = $Date.Add($EndLayway)
    }
    PROCESS
    {
        $enrollment_E | Where-Object -Property beginDate -LT $beginDate | Where-Object -Property endDate -GE $endDate
    }
}

Function Limit-OREnrollmentOnlyPrimaryTeacher #USED
{
    #[OutputType('OR_enrollment')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        #[OR_enrollment[]]
        $enrollment_E
    )
    PROCESS
    {
        $enrollment_E | Limit-OREnrollmentIsPrimary | Limit-OREnrollmentByrole -role teacher
    }
}

Function Limit-ORUserByschoolSourcedId #UNUSED
{
    #[OutputType('OR_user')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        #[OR_user[]]
        $user_E,
        [Parameter(Mandatory = $true)]
        [String[]]
        $schoolSourcedId
    )
    PROCESS
    {
        #Write-Warning "Limit-ORUserByschoolSourcedId"
        $user_E | Where-Object -FilterScript -Property sourcedId -CContains -Value $schoolSourcedId
    }
}

Function Limit-ORUserByorgSourcedIds #USED
{
    #[OutputType('OR_user')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        #[OR_user[]]
        $user_E,
        [Parameter(Mandatory = $true)]
        [String[]]
        $orgSourcedIds
    )
    PROCESS
    {
        Write-Warning "Limit-ORUserByorgSourcedIds"
        $user_E | Where-Object -Property orgSourcedIds -CContains -Value $orgSourcedIds
    }
}