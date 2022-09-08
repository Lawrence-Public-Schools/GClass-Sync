$Allow_Course_Cache = $true

$PSGSHelp_Source = @"

using System;
using System.Management.Automation;
using System.Collections.Generic;

namespace PSGSHelp_FastSearch
{

    public static class Search
    {
        public static List<Object> FindAll(PSObject[] collection, string column, string data)
        {
            List<Object> results = new List<Object>();
            foreach(PSObject item in collection)
            {
                if (item.Properties[column].Value.ToString() == data) { results.Add(item); }
            }

            return results;
        }

        public static object FindOne(PSObject[] collection, string column, string data)
        {
            foreach(PSObject item in collection)
            {
                if (item.Properties[column].Value.ToString() == data) { return item; }
            }

            return null;
        }

        public static object FindOneC(PSObject[] collection, string column, string data)
        {
            foreach(PSObject item in collection)
            {
                if (item.Properties[column].Value.ToString().ToLower() == data.ToLower()) { return item; }
            }

            return null;
        }
    }
}
"@

Add-Type -ReferencedAssemblies $Assem -TypeDefinition $PSGSHelp_Source -Language CSharp

Function Invoke-HTTP429-TMRS
{

    [OutputType('Void')]
    [CmdletBinding()]
    Param
    (
        [parameter(Mandatory = $false)]
        [Int]
        $RetryMS = 300000
    )
    PROCESS
    {
        #Write-Warning -Message "Google Classroom Service is limited, holding off"
        Write-Warning -Message ("Waiting for {0} seconds" -f ($RetryMS/1000))
        Start-Sleep -Milliseconds $RetryMS
    }
}

Function Clear-_GSClassroomUserProfile
{
    [OutputType('Void')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\"
    )
    PROCESS
    {
        $Cache_File = Join-Path -Path $Path -ChildPath "Cache_GSClassroomUserProfile_$($Domain).xml"
        If ((Test-Path -Path $Cache_File -PathType Leaf))
        {
            Remove-Item -Path $Cache_File -Force
        }
    }
}

Function Import-_GSClassroomUserProfile
{
    [OutputType('Google.Apis.Classroom.v1.Data.UserProfile[]')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\"
    )
    PROCESS
    {
        $Cache_File = Join-Path -Path $Path -ChildPath "Cache_GSClassroomUserProfile_$($Domain).xml"
        $r = @()
        If ((Test-Path -Path $Cache_File -PathType Leaf))
        {
            try
            {
                $r = Import-Clixml -Path $Cache_File -ErrorAction Stop
            }
            catch
            {
                Write-Warning -Message ("Failed to load: {0}" -f $Cache_File)
            }
        }
        If ($r.Count -le 1)
        {
            $r = @() + ($r)
        }
        Return $r
    }
}

Function Export-_GSClassroomUserProfile
{
    [OutputType('Void')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [Object]
        [AllowNull()]
        $InputObject,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\"
    )
    If ($null -ceq $InputObject)
    {
        Return
    }
    $Old = @()
    $New = @()
    $Cache_File = Join-Path -Path $Path -ChildPath "Cache_GSClassroomUserProfile_$($Domain).xml"
    $Old += Import-_GSClassroomUserProfile -Domain $Domain -Path $Path
    $New += ($InputObject) | Where-Object -Property EmailAddress -Like -Value "*@$($Domain)"
    $New +=  $Old | Where-Object -Property Id -NotIn $New.Id
    If ($New.Count -gt 0)
    {
        $New | Export-Clixml -Path $Cache_File -Depth 2
    }
    Else
    {
        @() | Export-Clixml -Path $Cache_File -Depth 2
    }
}

Function Clear-_GSClassroomUserProfile_Bad
{
    [OutputType('Void')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\"
    )
    PROCESS
    {
        $Cache_File = Join-Path -Path $Path -ChildPath "Cache_GSClassroomUserProfile_Bad_$($Domain).xml"
        If ((Test-Path -Path $Cache_File -PathType Leaf))
        {
            Remove-Item -Path $Cache_File -Force
        }
    }
}

Function Import-_GSClassroomUserProfile_Bad
{
    [OutputType('String')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\"
    )
    PROCESS
    {
        $Cache_File = Join-Path -Path $Path -ChildPath "Cache_GSClassroomUserProfile_Bad_$($Domain).xml"
        $r = @()
        If ((Test-Path -Path $Cache_File -PathType Leaf))
        {
            try
            {
                $r = Import-Clixml -Path $Cache_File
            }
            catch
            {
                Write-Warning -Message ("Failed to load: {0}" -f $Cache_File)
            }
        }
        If ($r.Count -le 1)
        {
            $r = @() + ($r)
        }
        Return $r
    }
}

Function Export-_GSClassroomUserProfile_BadL
{
    [OutputType('Void')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [PSObject[]]$InputObject,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\"
    )
    $Cache_File = Join-Path -Path $Path -ChildPath "Cache_GSClassroomUserProfile_Bad_$($Domain).xml"
    $InputObject =  ($InputObject) | Sort-Object -Unique
    If ($InputObject.Count -gt 0)
    {
        $InputObject | Export-Clixml -Path $Cache_File -Depth 1
    }
    Else
    {
        @() | Export-Clixml -Path $Cache_File -Depth 1
    }
}

Function Get-_GSClassroomUserProfile
{
    [OutputType('Google.Apis.Classroom.v1.Data.UserProfile')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$UserId,
        [parameter(Mandatory = $false)]
        [Bool]
        $BypassCache = $false,
        [parameter(Mandatory = $false)]
        [Bool]
        $SkipCache = $false,
        [parameter(Mandatory = $false)]
        [Bool]
        $CacheOnly = $false,
        [parameter(Mandatory = $false)]
        [String]
        $Cache_Path = ".\",
        [parameter(Mandatory = $false)]
        [Object[]]
        [AllowNull()]
        $Cache_ClassroomUserProfile = @(),
        [parameter(Mandatory = $false)]
        [Bool]
        $StoreBad = $false
    )
    BEGIN
    {
        $Cache_AdminEMail = $(Show-PSGSuiteConfig).AdminEmail
        $Cache_Domain = $(Show-PSGSuiteConfig).Domain
        $Cache_Writeback = $true
        $Cache_Changed = $false
        $Cache_Failed = @()
        $Cache_Failed_Changed = $false

        If ($Cache_GSClassroomUserProfile.Count -gt 0)
        {
            $Cache_Writeback = $false
        }

        If ($BypassCache -eq $false)
        {
            $Cache_ClassroomUserProfile += Import-_GSClassroomUserProfile -Domain $Cache_Domain -Path $Cache_Path
        }
        If ($StoreBad -eq $true)
        {
            $Cache_Failed += Import-_GSClassroomUserProfile_Bad -Domain $Cache_Domain -Path $Cache_Path
        }
    }
    PROCESS
    {
        $r = @()
        If ($UserId -in $Cache_Failed)
        {
        }
        ElseIf ($null -ceq $Cache_ClassroomUserProfile -or $Cache_ClassroomUserProfile.Count -eq 0)
        {
        }
        ElseIf ($SkipCache -eq $false)
        {
            If ($UserId -eq "me")
            {
                $r += [PSGSHelp_FastSearch.Search]::FindOneC($Cache_ClassroomUserProfile,"EmailAddress",$Cache_AdminEMail) #$Cache_ClassroomUserProfile | Where-Object -Property EmailAddress -EQ -Value $Cache_AdminEMail
            }
            ElseIf (($UserId -as [decimal]))
            {
                $r += [PSGSHelp_FastSearch.Search]::FindOne($Cache_ClassroomUserProfile,"Id",$UserId) #$Cache_ClassroomUserProfile | Where-Object -Property Id -CEQ -Value $UserId
            }
            Elseif ($UserId -like "*@*.*")
            {
                $r += [PSGSHelp_FastSearch.Search]::FindOneC($Cache_ClassroomUserProfile,"EmailAddress",$UserId) | Where-Object -Property Id -NE -Value $null #$Cache_ClassroomUserProfile | Where-Object -Property EmailAddress -EQ -Value $UserId
            }
            Else
            {
                $UserId = "$($UserId)@$($Cache_Domain)"
                $r += [PSGSHelp_FastSearch.Search]::FindOneC($Cache_ClassroomUserProfile,"EmailAddress",$UserId) #$Cache_ClassroomUserProfile | Where-Object -Property EmailAddress -EQ -Value $UserId
            }

            If ($r.Count -gt 1)
            {
                Write-Warning -Message ("Found more this one profile for {0}: {1}" -f $UserId, ($r | ConvertTo-Json -Depth 2))
                #Return $r[-1]
            }
            ElseIF ($r.Count -eq 1)
            {
                Return $r[0]
            }
            ElseIf ($CacheOnly -eq $true)
            {
                $Cache_Failed_Changed = $true
                $Cache_Failed += $UserId
                Return
            }
        }
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        Try
        {
            $r += Get-GSClassroomUserProfile -UserId $UserId -ErrorAction Stop

            If ($r.Count -gt 0)
            {
                $Cache_ClassroomUserProfile = (($Cache_ClassroomUserProfile) | Where-Object -Property Id -NotIn $r.Id)
                $Cache_ClassroomUserProfile += $r
                $Cache_Changed = $true
            }
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            If ($null -ceq $Exc.Exception.InnerException)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -in ([System.Net.HttpStatusCode]::NotFound,[System.Net.HttpStatusCode]::Unauthorized))
                {
                    If ($UserId -like "*@$($Cache_Domain)")
                    {
                        $Cache_Failed_Changed = $true
                        $Cache_Failed += $UserId
                    }
                    Else
                    {
                        Write-Warning -Message ("Could not lookup: {0}" -f $UserId)
                    }
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Forbidden)
                {
                    Write-Warning -Message ("Could not lookup User: {0}" -f $UserId)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning -Message "Google Classroom Service was unavailable"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
                    Return Get-_GSClassroomUserProfile -UserId $UserId -BypassCache $BypassCache -SkipCache $SkipCache -CacheOnly $CacheOnly -Cache_Path $Cache_Path -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile -StoreBad $StoreBad -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning -Message "Google Classroom Service was disconnected"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
                    Return Get-_GSClassroomUserProfile -UserId $UserId -BypassCache $BypassCache -SkipCache $SkipCache -CacheOnly $CacheOnly -Cache_Path $Cache_Path -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile -StoreBad $StoreBad -Verbose
                }
                If ($HttpStatusCode -eq 429)
                {
                    Invoke-HTTP429-TMRS
                    Return Get-_GSClassroomUserProfile -UserId $UserId -BypassCache $BypassCache -SkipCache $SkipCache -CacheOnly $CacheOnly -Cache_Path $Cache_Path -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile -StoreBad $StoreBad -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
            }
        }
        If ($UserId -in $Cache_Failed)
        {
            $Cache_Failed =  $Cache_Failed | Where-Object -FilterScript {$_ -ne $UserId}
        }
        If ($r.Count -gt 0)
        {
            Return $r
        }
        Write-Warning -Message ("Could not look up Classroom User Profile: {0}" -f $UserId)
    }
    END
    {
        If ($BypassCache -eq $false -and $Cache_Writeback -eq $true -and $Cache_Changed -eq $true -and $Cache_ClassroomUserProfile.Count -gt 0)
        {
            Export-_GSClassroomUserProfile -InputObject $Cache_ClassroomUserProfile -Domain $Cache_Domain
        }
        If ($Cache_Failed_Changed -eq $true -and $Cache_Failed.Count -gt 0)
        {
            Export-_GSClassroomUserProfile_Bad -InputObject $Cache_Failed -Domain $Cache_Domain
        }
    }
}

Function Clear-_GSCourseAlias
{
    [OutputType('Void')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\"
    )
    PROCESS
    {
        $Cache_File = Join-Path -Path $Path -ChildPath "Cache_GSCourseAlias_$($Domain).xml"
        If ((Test-Path -Path $Cache_File -PathType Leaf))
        {
            Remove-Item -Path $Cache_File -Force
        }
    }
}

Function Import-_GSCourseAlias
{
    [OutputType('System.Object[]')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\"
    )
    PROCESS
    {
        If ($Allow_Course_Cache -eq $false)
        {
            Return @()
        }
        $Cache_File = Join-Path -Path $Path -ChildPath "Cache_GSCourseAlias_$($Domain).xml"
        If ((Test-Path -Path $Cache_File -PathType Leaf))
        {
            try
            {
                Import-Clixml -Path $Cache_File
            }
            catch
            {
                Write-Warning -Message ("Failed to load: {0}" -f $Cache_File)
            }
        }
        Else
        {
            Return @()
        }
    }
}

Function Export-_GSCourseAlias
{
    [OutputType('Void')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [PSObject[]]$InputObject,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\"
    )
    $Cache_File = Join-Path -Path $Path -ChildPath "Cache_GSCourseAlias_$($Domain).xml"
    $InputObject | Export-Clixml -Path $Cache_File -Depth 1
}

Function Clear-_GSCourse
{
    [OutputType('Void')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\"
    )
    PROCESS
    {
        $Cache_File = Join-Path -Path $Path -ChildPath "Cache_GSCourseAlias_$($Domain).xml"
        If ((Test-Path -Path $Cache_File -PathType Leaf))
        {
            Remove-Item -Path $Cache_File -Force
        }
    }
}

Function Import-_GSCourse
{
    [OutputType('System.Object[]')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\"
    )
    PROCESS
    {
        IF ($Allow_Course_Cache -eq $false)
        {
            Return @()
        }
        $Cache_File = Join-Path -Path $Path -ChildPath "Cache_GSCourse_$($Domain).xml"
        $r = @()
        If ((Test-Path -Path $Cache_File -PathType Leaf))
        {
            try
            {
                $r = Import-Clixml -Path $Cache_File
            }
            catch
            {
                Write-Warning -Message ("Failed to load: {0}" -f $Cache_File)
            }
        }
        Return $r
    }
}

Function Export-_GSCourse
{
    [OutputType('Void')]
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [PSObject[]]$InputObject,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Domain,
        [parameter(Mandatory = $false)]
        [String]
        $Path = ".\"
    )
    If ($null -ceq $InputObject)
    {
        Return
    }
    $Old = @()
    $New = @()
    $Cache_File = Join-Path -Path $Path -ChildPath "Cache_GSCourse_$($Domain).xml"
    $Old += Import-_GSCourse -Domain $Domain -Path $Path
    $New += ($InputObject)
    $New +=  $Old | Where-Object -Property Id -NotIn $New.Id
    If ($New.Count -gt 0)
    {
        $New | Export-Clixml -Path $Cache_File -Depth 2
    }
    Else
    {
        @() | Export-Clixml -Path $Cache_File -Depth 2
    }
}

Function Get-_GSCourse
{
    [OutputType('Google.Apis.Classroom.v1.Data.Course')]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Id,
        [parameter(Mandatory = $false)]
        [Bool]
        $BypassCache = $false,
        [parameter(Mandatory = $false)]
        [Bool]
        $SkipCache = $false,
        [parameter(Mandatory = $false)]
        [Bool]
        $CacheOnly = $false,
        [parameter(Mandatory = $false)]
        [Object[]]
        [AllowNull()]
        $Cache_GSCourse = @(),
        [parameter(Mandatory = $false)]
        #[System.Collections.Hashtable]
        $Cache_GSCourseAlias = @()
    )
    BEGIN
    {
        $Cache_Domain = $(Show-PSGSuiteConfig).Domain
        $Cache_Writeback = $true
        $Cache_Writeback_Alias = $true
        $Cache_Changed = $false

        If ($Cache_GSCourse.Count -gt 0)
        {
            $Cache_Writeback = $false
        }
        ElseIf ($BypassCache -eq $false -and $Allow_Course_Cache -eq $true)
        {
            $Cache_GSCourse += Import-_GSCourse -Domain $Cache_Domain
        }

        If ($Cache_GSCourseAlias.Count -gt 0)
        {
            $Cache_Writeback_Alias = $false
        }
        ElseIf ($BypassCache -eq $false -and $Allow_Course_Cache -eq $true)
        {
            $Cache_GSCourseAlias += Import-_GSCourseAlias -Domain $Cache_Domain
        }
    }
    PROCESS
    {
        $r = @()
        $AId = $null
        $RId = $null
        If ($SkipCache -eq $false -and $Allow_Course_Cache -eq $true)
        {
            If ($Id -like "d:*" -or $Id -like "p:*")
            {
                $AId = $Id
                $RId = $null
                If ($Cache_GSCourseAlias.Count -ge 0)
                {
                    $RId = $Cache_GSCourseAlias | Where-Object -Property CourseAlias -EQ -Value $AId | Select-Object -ExpandProperty CourseId
                }
                If ($null -ne $RId)
                {
                    $Id = $RId
                }
            }

            If (($Id -as [decimal]))
            {
                $r += [PSGSHelp_FastSearch.Search]::FindOne($Cache_GSCourse,"Id",$Id) #$Cache_GSCourse | Where-Object -Property Id -ceq -Value $Id
            }

            If ($r.Count -gt 0)
            {
                Return $r | Select-Object -Last 1
            }

            If ($CacheOnly -eq $true)
            {
                Return $null
            }
        }
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        Try
        {
            $r += Get-GSCourse -Id $Id -ErrorAction Stop
            $Cache_Changed = $true
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            If ($null -ceq $Exc.Exception.InnerException)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::NotFound)
                {
                    #Write-Warning -Message ("Could not find Course: {0}", $Id)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unauthorized)
                {
                    Write-Warning -Message ("Can not access Course: {0}" -f $Id)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }

                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning -Message "Google Classroom Service was unavailable"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Get-_GSCourse -Id $Id -BypassCache $BypassCache -SkipCache $SkipCache -CacheOnly $CacheOnly -Cache_GSCourse $Cache_GSCourse -Cache_GSCourseAlias $Cache_GSCourseAlias -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::InternalServerError)
                {
                    Write-Warning -Message "Google Classroom got an internal server error"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Get-_GSCourse -Id $Id -BypassCache $BypassCache -SkipCache $SkipCache -CacheOnly $CacheOnly -Cache_GSCourse $Cache_GSCourse -Cache_GSCourseAlias $Cache_GSCourseAlias -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning -Message "Google Classroom Service was disconnected"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Get-_GSCourse -Id $Id -BypassCache $BypassCache -SkipCache $SkipCache -CacheOnly $CacheOnly -Cache_GSCourse $Cache_GSCourse -Cache_GSCourseAlias $Cache_GSCourseAlias -Verbose
                }
                If ($HttpStatusCode -eq 429)
                {
                    Invoke-HTTP429-TMRS
                    Return Get-_GSCourse -Id $Id -BypassCache $BypassCache -SkipCache $SkipCache -CacheOnly $CacheOnly -Cache_GSCourse $Cache_GSCourse -Cache_GSCourseAlias $Cache_GSCourseAlias -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
            }
        }
        If ($r.Count -eq 1 -and $null -eq $RId)
        {
            If ($Id -like "d:*" -or $Id -like "p:*" -and $Allow_Course_Cache -eq $true)
            {
                $Cache_GSCourseAlias_Old = $Cache_GSCourseAlias
                $Cache_GSCourseAlias_New = @()
                $Cache_GSCourseAlias_New += $Cache_GSCourseAlias_Old | Where-Object -Property CourseAlias -NotIn -Value $AId | Where-Object -Property CourseId -NotIn -Value $r.Id
                $NAlias = [PSCustomObject]@{
                    CourseAlias    = $Id
                    CourseId       = $r.Id
                                           }
                $Cache_GSCourseAlias = @()
                $Cache_GSCourseAlias += $NAlias
                $Cache_GSCourseAlias += $Cache_GSCourseAlias_New
            }
        }
        If ($Allow_Course_Cache -eq $true)
        {
            $Cache_GSCourse = $Cache_GSCourse | Where-Object -Property Id -NotIn -Value $r.Id
            $Cache_GSCourse += $r
        }
        Return $r
    }
    END
    {
        If ($BypassCache -eq $false -and $Cache_Changed -eq $true -and $Allow_Course_Cache -eq $true)
        {
            If ($Cache_Writeback -eq $true)
            {
                Export-_GSCourse -InputObject $Cache_GSCourse -Domain $Cache_Domain
            }
            If ($Cache_Writeback_Alias -eq $true)
            {
                Export-_GSCourseAlias -InputObject $Cache_GSCourseAlias -Domain $Cache_Domain
            }
        }
    }
}

Function Update-_GSCourseState
{
    [OutputType('Google.Apis.Classroom.v1.Data.Course')]
    Param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Id,
        [Parameter(Mandatory=$true)]
        [ValidateSet('PROVISIONED','ACTIVE','ARCHIVED','DECLINED')]
        [String]
        $CourseState,
        [parameter(Mandatory = $false)]
        [Bool]
        $BypassCache = $false,
        [parameter(Mandatory = $false)]
        [Bool]
        $SkipCache = $false,
        [parameter(Mandatory = $false)]
        [Object[]]
        [AllowNull()]
        $Cache_GSCourse = @(),
        [parameter(Mandatory = $false)]
        #[System.Collections.Hashtable]
        $Cache_GSCourseAlias = @()
    )
    BEGIN
    {
        $Cache_Domain = $(Show-PSGSuiteConfig).Domain
        $Cache_Writeback = $true
        $Cache_Writeback_Alias = $true
        $Cache_Changed = $false

        If ($Cache_GSCourse.Count -gt 0)
        {
            $Cache_Writeback = $false
        }
        ElseIf ($BypassCache -eq $false -and $Allow_Course_Cache -eq $true)
        {
            $Cache_GSCourse += Import-_GSCourse -Domain $Cache_Domain
        }

        If ($Cache_GSCourseAlias.Count -gt 0)
        {
            $Cache_Writeback_Alias = $false
        }
        ElseIf ($BypassCache -eq $false -and $Allow_Course_Cache -eq $true)
        {
            $Cache_GSCourseAlias += Import-_GSCourseAlias -Domain $Cache_Domain
        }
    }
    PROCESS
    {
        $r = @()
        $AId = $null
        $RId = $null
        If ($SkipCache -eq $false -and $Allow_Course_Cache -eq $true)
        {
            If ($Id -like "d:*" -or $Id -like "p:*")
            {
                $AId = $Id
                $RId = $null
                If ($Cache_GSCourseAlias.Count -ge 0)
                {
                    $RId = $Cache_GSCourseAlias | Where-Object -Property CourseAlias -EQ -Value $AId | Select-Object -ExpandProperty CourseId
                }
                If ($null -ne $RId)
                {
                    $Id = $RId
                }
            }
        }
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        Try
        {
            $r += Update-GSCourse -Id $Id -CourseState $CourseState -ErrorAction Stop
            $Cache_Changed = $true
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            If ($null -ceq $Exc.Exception.InnerException)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::NotFound)
                {
                    #Write-Warning -Message ("Could not find Course: {0}", $Id)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return $null
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unauthorized)
                {
                    Write-Warning -Message ("Can not access Course: {0}" -f $Id)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return Get-_GSCourse -Id $Id -BypassCache $false -SkipCache $SkipCache -CacheOnly $true -Cache_GSCourse $Cache_GSCourse -Cache_GSCourseAlias $Cache_GSCourseAlias -Verbose
                }

                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning -Message "Google Classroom Service was unavailable"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Update-_GSCourseState -Id $Id -CourseState $CourseState -BypassCache $BypassCache -SkipCache $SkipCache -Cache_GSCourse $Cache_GSCourse -Cache_GSCourseAlias $Cache_GSCourseAlias -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::InternalServerError)
                {
                    Write-Warning -Message "Google Classroom got an internal server error"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Update-_GSCourseState -Id $Id -CourseState $CourseState -BypassCache $BypassCache -SkipCache $SkipCache -Cache_GSCourse $Cache_GSCourse -Cache_GSCourseAlias $Cache_GSCourseAlias -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning -Message "Google Classroom Service was disconnected"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Update-_GSCourseState -Id $Id -CourseState $CourseState -BypassCache $BypassCache -SkipCache $SkipCache -Cache_GSCourse $Cache_GSCourse -Cache_GSCourseAlias $Cache_GSCourseAlias -Verbose
                }
                If ($HttpStatusCode -eq 429)
                {
                    Invoke-HTTP429-TMRS
                    Return Update-_GSCourseState -Id $Id -CourseState $CourseState -BypassCache $BypassCache -SkipCache $SkipCache -Cache_GSCourse $Cache_GSCourse -Cache_GSCourseAlias $Cache_GSCourseAlias -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
            }
        }
        If ($r.Count -eq 0)
        {
            Return $null
        }
        If ($r.Count -eq 1 -and $null -eq $RId)
        {
            If ($Id -like "d:*" -or $Id -like "p:*" -and $Allow_Course_Cache -eq $true)
            {
                $Cache_GSCourseAlias_Old = $Cache_GSCourseAlias
                $Cache_GSCourseAlias_New = @()
                $Cache_GSCourseAlias_New += $Cache_GSCourseAlias_Old | Where-Object -Property CourseAlias -NotIn -Value $AId | Where-Object -Property CourseId -NotIn -Value $r.Id
                $NAlias = [PSCustomObject]@{
                    CourseAlias    = $Id
                    CourseId       = $r.Id
                                           }
                $Cache_GSCourseAlias = @()
                $Cache_GSCourseAlias += $NAlias
                $Cache_GSCourseAlias += $Cache_GSCourseAlias_New
            }
        }
        If ($Allow_Course_Cache -eq $true)
        {
            $Cache_GSCourse = $Cache_GSCourse | Where-Object -Property Id -NotIn -Value $r.Id
            $Cache_GSCourse += $r
        }
        Return $r
    }
    END
    {
        If ($BypassCache -eq $false -and $Cache_Changed -eq $true -and $Allow_Course_Cache -eq $true)
        {
            If ($Cache_Writeback -eq $true)
            {
                Export-_GSCourse -InputObject $Cache_GSCourse -Domain $Cache_Domain
            }
            If ($Cache_Writeback_Alias -eq $true)
            {
                Export-_GSCourseAlias -InputObject $Cache_GSCourseAlias -Domain $Cache_Domain
            }
        }
    }
}

Function Get-_GSCourseParticipant
{
    [OutputType('Google.Apis.Classroom.v1.Data.Student')]
    Param
    (
        [parameter(Mandatory = $true,Position = 0,ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [alias('Id')]
        [String]
        $CourseId,
        [parameter(Mandatory = $false)]
        [ValidateSet('Teacher','Student')]
        [String[]]
        $Role = @('Teacher','Student')
    )
    PROCESS
    {
        $r = @()
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        try
        {
            $r += Get-GSCourseParticipant -CourseId $CourseId -Role $Role -ErrorAction Stop
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            If ($null -ceq $Exc.Exception.InnerException)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::NotFound)
                {
                    #Write-Warning -Message ("Could not find any {1} in Course: {0}" -f $CourseId, $Role)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unauthorized)
                {
                    Write-Warning -Message ("Can not access any {1} in Course: {0}" -f $CourseId, $Role)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning -Message "Google Classroom Service was unavailable"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
                    Return Get-_GSCourseParticipant -CourseId $CourseId -Role $Role -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning -Message "Google Classroom Service was disconnected"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Get-_GSCourseParticipant -CourseId $CourseId -Role $Role -Verbose
                }
                If ($HttpStatusCode -eq 429)
                {
                    Invoke-HTTP429-TMRS
                    Return Get-_GSCourseParticipant -CourseId $CourseId -Role $Role -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
             }
        }
        If ($r.Count -ge 1)
        {
            Return $r
        }
    }
}

Function New-_GSCourseInvitation
{
    [OutputType('Google.Apis.Classroom.v1.Data.Invitation')]
    [cmdletbinding()]
    Param
    (
        [parameter(Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
        [String]
        $CourseId,
        [parameter(Mandatory = $true,ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
        [Alias('PrimaryEmail','Email','Mail')]
        [String[]]
        $UserId,
        [parameter(Mandatory = $false)]
        [ValidateSet('STUDENT','TEACHER','OWNER')]
        [String]
        $Role = 'STUDENT',
        [parameter(Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
        [String]
        $User
    )
    BEGIN
    {
        $Limited429 = $false
    }
    PROCESS
    {
        $r = @()
        If ($true -eq $Limited429)
        {
            Write-Verbose -Message "We hit a HTTP 429 limit, returning blanks"
            Return
        }
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        try
        {
            $r += New-GSCourseInvitation -CourseId $CourseId -UserId $UserId -Role $Role -User $User -ErrorAction Stop
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            If ($null -ceq $Exc.Exception.InnerException)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Conflict)
                {
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::BadRequest)
                {
                    #Write-Warning -Message "Google Classroom $($CourseId) had changed state"
                    Write-Warning -Message ("Failed to add {0} As {1} As {2}" -f $UserId, $Role, $User)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning -Message "Google Classroom Service was unavailable"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
                    Return New-_GSCourseInvitation -CourseId $CourseId -UserId $UserId -Role $Role -User $User -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Forbidden)
                {
                    #Write-Warning -Message ("Google Classroom {0} had changed state" -f $CourseId)
                    Write-Warning -Message ("Denied to add {0} As {1} As {2}" -f $UserId, $Role, $User)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning -Message "Google Classroom Service was disconnected"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return New-_GSCourseInvitation -CourseId $CourseId -UserId $UserId -Role $Role -User $User -Verbose
                }
                If ($HttpStatusCode -eq 429)
                {
                    #Invoke-HTTP429-TMRS
                    $Limited429 = $true
                    Start-Sleep -Seconds 1
                    Return #New-_GSCourseInvitation -CourseId $CourseId -UserId $UserId -Role $Role -User $User -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
            }
        }
        If ($r.Count -ge 1)
        {
            Return $r
        }
    }
}

Function Get-_GSCourseInvitationByCourse
{
    [OutputType('Google.Apis.Classroom.v1.Data.Invitation')]
    Param
    (
        [parameter(Mandatory = $true)]
        [String]
        $CourseId,
        [parameter(Mandatory = $false)]
        [ValidateSet('STUDENT','TEACHER','OWNER')]
        [String[]]
        $Role = @('STUDENT')
    )
    PROCESS
    {
        $r = @()
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        try
        {
            $r += Get-GSCourseInvitation -CourseId $CourseId -ErrorAction Stop
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            If ($null -ceq $Exc.Exception.InnerException)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::NotFound)
                {
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Forbidden)
                {
                    Write-Warning -Message ("Denied to to get {0} Invitations" -f $CourseId)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq 429)
                {
                    Invoke-HTTP429-TMRS
                    Return Get-_GSCourseInvitationByCourse -CourseId $CourseId -Role $Role -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
            }
        }
        If ($r.Count -eq 0)
        {
            Return
        }
        $f = @()
        $f += $r | Where-Object -Property Role -In -Value $Role
        If ($f.Count -eq 0)
        {
            Return
        }
        Return $f
    }
}

Function Get-_GSCourseInvitationByUser
{
    [OutputType('Google.Apis.Classroom.v1.Data.Invitation')]
    Param
    (
        [parameter(Mandatory = $true)]
        [String]
        $UserId,
        [parameter(Mandatory = $false)]
        [ValidateSet('STUDENT','TEACHER','OWNER')]
        [String[]]
        $Role = @('STUDENT')
    )
    PROCESS
    {
        $r = @()
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        try
        {
            $r += Get-GSCourseInvitation -UserId $UserId -User $UserId -ErrorAction Stop
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            If ($null -ceq $Exc.Exception.InnerException)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::NotFound)
                {
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Forbidden)
                {
                    Write-Warning -Message ("Denied to to get {0} Invitations" -f $CourseId)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq 429)
                {
                    Invoke-HTTP429-TMRS
                    Return Get-_GSCourseInvitationByUser -UserId $UserId -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
            }
        }
        If ($r.Count -eq 0)
        {
            Return
        }
        $f = @()
        $f += $r | Where-Object -Property Role -In -Value $Role
        If ($f.Count -eq 0)
        {
            Return
        }
        Return $f
    }
}

Function Confirm-_GSCourseInvitation
{
    [OutputType('Google.Apis.Classroom.v1.Data.Invitation')]
    [cmdletbinding()]
    Param
    (
        [parameter(Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
        [String]
        $Id,
        [parameter(Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
        [String]
        $User
    )
    PROCESS
    {
        $i = @()
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        Try
        {
            $i += Confirm-GSCourseInvitation -Id $Id -User $User -ErrorAction Stop
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            If ($null -ceq $Exc.Exception.InnerException)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::NotFound)
                {
                    Write-Warning -Message ("Not Found on processing Google Classroom Invitation for user {0}: {1}" -f $User, (ConvertTo-Json $I -Depth 1))
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Forbidden)
                {
                    Write-Warning -Message ("Forbidden on processing Google Classroom Invitation for user {0}: {1})" -f $User, (ConvertTo-Json $I -Depth 1))
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::InternalServerError)
                {
                    Write-Warning -Message ("Internal Error on processing Google Classroom Invitation for user {0}: {1})" -f $User, (ConvertTo-Json $I -Depth 1))
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning -Message "Google Classroom Service was unavailable"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
                    Return Confirm-_GSCourseInvitation -Id $Id -User $User -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning -Message "Google Classroom Service was disconnected"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Confirm-_GSCourseInvitation -Id $Id -User $User -Verbose
                }
                If ($HttpStatusCode -eq 429)
                {
                    Invoke-HTTP429-TMRS
                    Return Confirm-_GSCourseInvitation -Id $Id -User $User -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
             }
        }
        If ($i.Count -ge 1)
        {
            Return $i
        }
    }
}

Function New-_GSCourse
{
    [OutputType('Google.Apis.Classroom.v1.Data.Course')]
    [cmdletbinding()]
    Param
    (
        [parameter(Mandatory = $true,Position = 0)]
        [ValidateLength(1,750)]
        [String]
        $Name,
        [parameter(Mandatory = $true)]
        [Alias('Teacher')]
        [String]
        $OwnerId,
        [parameter(Mandatory = $false)]
        [Alias('Backup')]
        [String]
        $FallBackId = $null,
        [parameter(Mandatory = $true)]
        [Alias('Alias')]
        [String]
        $Id,
        [parameter(Mandatory = $true)]
        [String]
        $Section,
        [parameter(Mandatory = $true)]
        [String]
        $Room,
        [parameter(Mandatory = $false)]
        [Alias('Status')]
        [ValidateSet('PROVISIONED','ACTIVE','ARCHIVED','DECLINED')]
        [String]
        $CourseState = 'PROVISIONED'
    )
    PROCESS
    {
        $r = @()
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        Try
        {
            $r += New-GSCourse -Name $Name -OwnerId $OwnerId -Id $Id -Section $Section -Room $Room -CourseState $CourseState -ErrorAction Stop
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            If ($null -ceq $Exc.Exception.InnerException)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Forbidden)
                {
                    Write-Warning -Message ("Google User {0} can not make a Google Classroom" -f $OwnerId)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    If ($null -ne $FallBackId)
                    {
                        Return New-_GSCourse -Name $Name -OwnerId $FallBackId -Id $Id -Section $Section -Room $Room -CourseState $CourseState -Verbose
                    }
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::BadRequest)
                {
                    Write-Warning -Message ("Google User {0} can not make a Google Classroom" -f $OwnerId)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    If ($null -ne $FallBackId)
                    {
                        Return New-_GSCourse -Name $Name -OwnerId $FallBackId -Id $Id -Section $Section -Room $Room -CourseState $CourseState -Verbose
                    }
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning -Message "Google Classroom Service was unavailable"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
                    Return New-_GSCourse -Name $Name -OwnerId $OwnerId -FallBackId $FallBackId -Id $Id -Section $Section -Room $Room -CourseState $CourseState -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::InternalServerError)
                {
                    Write-Warning -Message "Google Classroom Service had an internal server error, retry?"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
                    Return New-_GSCourse -Name $Name -OwnerId $OwnerId -FallBackId $FallBackId -Id $Id -Section $Section -Room $Room -CourseState $CourseState -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning -Message "Google Classroom Service was disconnected"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return New-_GSCourse -Name $Name -OwnerId $OwnerId -FallBackId $FallBackId -Id $Id -Section $Section -Room $Room -CourseState $CourseState -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Conflict)
                {
                    Write-Warning -Message ("Course {0} could not be created, it already exists" -f $Id)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Get-_GSCourse -Id $Id -BypassCache:$true -Verbose
                }
                If ($HttpStatusCode -eq 429)
                {
                    Invoke-HTTP429-TMRS
                    Return New-_GSCourse -Name $Name -OwnerId $OwnerId -FallBackId $FallBackId -Id $Id -Section $Section -Room $Room -CourseState $CourseState -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
             }
        }
        If ($r.Count -ge 1)
        {
            Return $r
        }
    }
}

function Remove-_GSCourseInvitation
{
    [OutputType('Google.Apis.Classroom.v1.Data.Invitation')]
    [cmdletbinding()]
    Param
    (
        [parameter(Mandatory = $true,ValueFromPipeline = $true,ValueFromPipelineByPropertyName = $true)]
        [String[]]
        $Id,
        [parameter(Mandatory = $true,ValueFromPipelineByPropertyName = $true)]
        [String]
        $User
    )
    PROCESS
    {
        $r = @()
        If ($null -ceq $Id)
        {
            Write-Error "No invites to remove"
            Return
        }
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        Try
        {
            $r += Remove-GSCourseInvitation -Id $Id -User $User -Confirm:$false -ErrorAction Stop
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            If ($null -ceq $Exc.Exception.InnerException)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::NotFound)
                {
                    Write-Warning -Message ("Cound not find Invitation as {0}" -f $User)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Forbidden)
                {
                    Write-Warning -Message ("No right to remove Invitation as {0}" -f $User)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning -Message "Google Classroom Service was unavailable"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
                    Return Remove-_GSCourseInvitation -Id $Id -User $User -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning -Message "Google Classroom Service was disconnected"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Remove-_GSCourseInvitation -Id $Id -User $User -Verbose
                }
                If ($HttpStatusCode -eq 429)
                {
                    Invoke-HTTP429-TMRS
                    Return Remove-_GSCourseInvitation -Id $Id -User $User -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
            }
        }
        If ($r.Count -ge 1)
        {
            Return $r
        }
    }
}

Function Remove-_GSCourseStudent
{
    Param
    (
        [parameter(Mandatory = $true,Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $CourseId,
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('PrimaryEmail','Email','Mail', 'Id')]
        [String]
        $Student,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $User
    )
    PROCESS
    {
        $r = @()
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        Try
        {
            $r += Remove-GSCourseParticipant -CourseId $CourseId -Student $Student -User $User -Confirm:$false -ErrorAction Stop
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            #Write-Host $Exc.Exception
            If ($null -ceq $Exc.Exception.InnerException)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::NotFound)
                {
                    Write-Warning -Message ("Could not remove this Student: {0} from Course: {1} With User: {2}" -f $Student, $CourseId, $User)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Forbidden)
                {
                    Write-Warning -Message ("Could not remove this Student: {0} from Course: {1} With User: {2}" -f $Student, $CourseId, $User)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning -Message "Google Classroom Service was unavailable"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
                    Return Remove-_GSCourseStudent -CourseId $CourseId -Student $Student -User $User -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::InternalServerError)
                {
                    Write-Warning -Message "Google Classroom Service was unavailable"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
                    Return Remove-_GSCourseStudent -CourseId $CourseId -Student $Student -User $User -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning -Message "Google Classroom Service was disconnected"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Remove-_GSCourseStudent -CourseId $CourseId -Student $Student -User $User -Verbose
                }
                If ($HttpStatusCode -eq 429)
                {
                    Invoke-HTTP429-TMRS
                    Return Remove-_GSCourseStudent -CourseId $CourseId -Student $Student -User $User -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
             }
        }
        If ($r.Count -ge 1)
        {
            Return $r
        }
    }
}

Function Remove-_GSCourseTeacher
{
    Param
    (
        [parameter(Mandatory = $true,Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $CourseId,
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('PrimaryEmail','Email','Mail', 'Id')]
        [String]
        $Teacher,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $User
    )
    PROCESS
    {
        $r = @()
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        Try
        {
            $r += Remove-GSCourseParticipant -CourseId $CourseId -Teacher $Teacher -User $User -Confirm:$false -ErrorAction Stop
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            #Write-Host $Exc.Exception
            If ($null -ceq $Exc.Exception.InnerException)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::NotFound)
                {
                    Write-Warning -Message ("Could not remove this Teacher: {0} from Course: {1} With User: {2}" -f $Teacher, $CourseId, $User)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Forbidden)
                {
                    Write-Warning -Message ("Could not remove this Teacher: {0} from Course: {1} With User: {2}" -f $Teacher, $CourseId, $User)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning -Message "Google Classroom Service was unavailable"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
                    Return Remove-_GSCourseTeacher -CourseId $CourseId -Teacher $Teacher -User $User -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::InternalServerError)
                {
                    Write-Warning -Message "Google Classroom Service was unavailable"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
                    Return Remove-_GSCourseTeacher -CourseId $CourseId -Teacher $Teacher -User $User -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning -Message "Google Classroom Service was disconnected"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Remove-_GSCourseTeacher -CourseId $CourseId -Teacher $Teacher -User $User -Verbose
                }
                If ($HttpStatusCode -eq 429)
                {
                    Invoke-HTTP429-TMRS
                    Return Remove-_GSCourseTeacher -CourseId $CourseId -Teacher $Teacher -User $User -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
             }
        }
        If ($r.Count -ge 1)
        {
            Return $r
        }
    }
}

Function Add-_GSCourseTeacher
{
    Param
    (
        [parameter(Mandatory = $true,Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $CourseId,
        [parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('PrimaryEmail','Email','Mail', 'Id')]
        [String]
        $Teacher
    )
    PROCESS
    {
        $r = @()
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        Try
        {
            $r += Add-GSCourseParticipant -CourseId $CourseId -Teacher $Teacher -ErrorAction Stop
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            #Write-Host $Exc.Exception
            If ($null -ceq $Exc.Exception.InnerException)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::BadRequest)
                {
                    Write-Warning -Message ("Could not add this Teacher: {0} for Course: {1}" -f $Teacher, $CourseId)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::NotFound)
                {
                    Write-Warning -Message ("Could not add this Teacher: {0} from Course: {1}" -f $Teacher, $CourseId)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Forbidden)
                {
                    Write-Warning -Message ("Could not add this Teacher: {0} from Course: {1}" -f $Teacher, $CourseId)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning -Message "Google Classroom Service was unavailable"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
                    Return Add-_GSCourseTeacher -CourseId $CourseId -Teacher $Teacher -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::InternalServerError)
                {
                    Write-Warning -Message "Google Classroom Service was unavailable"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
                    Return Add-_GSCourseTeacher -CourseId $CourseId -Teacher $Teacher -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning -Message "Google Classroom Service was disconnected"
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Add-_GSCourseTeacher -CourseId $CourseId -Teacher $Teacher -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Conflict)
                {
                    Write-Warning -Message ("This Teacher: {1} is already in Course: {1}" -f $Teacher, $CourseId)
                    Write-Verbose -Message $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq 429)
                {
                    Invoke-HTTP429-TMRS
                    Return Add-_GSCourseTeacher -CourseId $CourseId -Teacher $Teacher -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
             }
        }
        If ($r.Count -ge 1)
        {
            Return $r
        }
    }
}
