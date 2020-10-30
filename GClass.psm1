Get-Module -Name OneRoster| Remove-Module; Import-Module .\OneRoster.psm1

Import-Module PSGSuite
Get-Module -Name PSGSHelp | Remove-Module;Import-Module .\PSGSHelp.psm1


Function New-ClassAlias
{
    [OutputType('String')]
    [CmdletBinding()]
    Param
    ( 
        [Parameter(Mandatory = $true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName = $true)]
        [Alias('classSourcedId')]
        [String]$sourcedId
    )
    PROCESS
    {
        Return "d:PowerSchool-class_id-$($sourcedId)"
    }
 }

Function Get-ClassLink
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName = $true)]
        [Alias('classSourcedId')]
        [String]$sourcedId,
        [Boolean]
        $SkipCache = $true,
        $Cache_GSCourse = @(),
        $Cache_GSCourseAlias = @()

    )
    BEGIN
    {
        $b = [PSCustomObject]@{
            sourcedId      = $null
            CourseAlias    = $null
            CourseId       = $null
            CourseState    = $null
            OwnerId        = $null
            EmailAddress   = $null
            EnrollmentCode = "N/A"
                              }
    }
    PROCESS
    {
        $s = $sourcedId
        $c = $null
        $a = $s | New-ClassAlias
        $c = $a | Get-_GSCourse -SkipCache $SkipCache -Cache_GSCourse $Cache_GSCourse -Cache_GSCourseAlias $Cache_GSCourseAlias
        $o = $b.PsObject.Copy()
        $o.sourcedId = $s
        $o.CourseAlias = $a
        If ($null -eq $c)
        {
            Write-Verbose "No Google Classroom for $($a)"
        }
        Else
        {
            $o.CourseId    = $c.Id
            $o.CourseState = $c.CourseState
            $o.OwnerId     = $c.OwnerId
            If ($null -eq $c.EnrollmentCode)
            {
                $o.EnrollmentCode = "Disabled"
            }
            Else
            {
                $o.EnrollmentCode = $c.EnrollmentCode
            }
        }
        If ($o.OwnerId -ne $null)
        {
            $p = $null
            $p = $o.OwnerId | Get-_GSClassroomUserProfile -CacheOnly $true
            If ($p -eq $null)
            {
                Write-Warning "$($a): No Cached Owner"
                $p = $o.OwnerId | Get-_GSClassroomUserProfile -SkipCache $true
                If ($p -eq $null)
                {
                    Write-Warning "$($a): No Domain Owner"
                }
                Else
                {
                    Write-Warning "Outside teacher: $($p.EmailAddress)"
                }
            }
            If ($p -ne $null -and $p.EmailAddress -ne "")
            {
                $o.EmailAddress = $p.EmailAddress
            }
        }
        Return $o
    }
}

Function Export-ClassLink
{
    [OutputType('Void')]
    [CmdletBinding()]
    Param
    ( 
        [Parameter(Mandatory = $true)]
        [Object]$InputObject,
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\"
    )
    $Cache_File = Join-Path -Path $Path -ChildPath "Cache_ClassLink.xml"
    (@() + ($InputObject))| Export-Clixml -Path $Cache_File
}

Function Import-ClassLink
{
    #[OutputType('Object')]
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\"
    )
    PROCESS
    {
        $Cache_File = Join-Path -Path $Path -ChildPath "Cache_ClassLink.xml"
        If ((Test-Path -Path $Cache_File -PathType Leaf))
        {
            (Import-Clixml -Path $Cache_File)
        }
    }
}

Function Update-ClassLink
{
    [OutputType('void')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName = $true)]
        [Alias('classSourcedId')]
        [String[]]$sourcedId = @(),
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\",
        [Parameter(Mandatory = $true)]
        [String]$Domain,
        [Boolean]
        $SkipCache = $true
    )
    BEGIN
    {
        $GoodLink = @()
        $GoodLink += Import-ClassLink -Path $Path
        $NewLink = @()
        $Cache_GSCourse = @()
        $Cache_GSCourseAlias = @()
        If (-Not $SkipCache)
        {
            $Cache_GSCourse += Import-_GSCourse -Domain $Domain
            $Cache_GSCourseAlias += Import-_GSCourseAlias -Domain $Domain
        }
    }
    PROCESS
    {
        #Write-Verbose "Cached: $($GoodLink.Count)"
        $GoodLink = @() + ($GoodLink | Where-Object -Property sourcedId -NotIn $sourcedId)
        #Write-Verbose "Update: $($GoodLink.Count)"
        Write-Verbose "Updating Class Cache data for: $($sourcedId)"
        $NewLink += $sourcedId | Get-ClassLink -SkipCache $SkipCache -Cache_GSCourse $Cache_GSCourse -Cache_GSCourseAlias $Cache_GSCourseAlias
        #Write-Verbose "Refresh: $($GoodLink.Count)"
    }
    END
    {
        $NewLink  += ($GoodLink | Where-Object -Property sourcedId -NotIn $NewLink.sourcedId)
        Export-ClassLink -InputObject $NewLink -Path $Path
        #Write-Verbose "Stored Class Cache data for: $($sourcedId -join ",")"
    }
}
