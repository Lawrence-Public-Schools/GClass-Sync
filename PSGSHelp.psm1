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
            $r = Import-Clixml -Path $Cache_File
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
    If ($InputObject -eq $null)
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
            $r = Import-Clixml -Path $Cache_File
        }
        If ($r.Count -le 1)
        {
            $r = @() + ($r)
        }
        Return $r
    }
}

Function Export-_GSClassroomUserProfile_Bad
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
        ElseIf ($Cache_ClassroomUserProfile -eq $null -or $Cache_ClassroomUserProfile.Count -eq 0)
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
                Write-Warning "Found more this one profile for $($UserId): $($r | ConvertTo-Json -Depth 2)"
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
            If ($Exc.Exception.InnerException -eq $null)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -in ([System.Net.HttpStatusCode]::NotFound,[System.Net.HttpStatusCode]::Unauthorized, [System.Net.HttpStatusCode]::Forbidden))
                {
                    If ($UserId -like "*@$($Cache_Domain)")
                    {
                        $Cache_Failed_Changed = $true
                        $Cache_Failed += $UserId
                    }
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning "Google Classroom Service was unavailable"
                    Start-Sleep -Seconds 5
                    Return Get-_GSClassroomUserProfile -UserId $UserId -BypassCache $BypassCache -SkipCache $SkipCache -CacheOnly $CacheOnly -Cache_Path $Cache_Path -Cache_ClassroomUserProfile $Cache_ClassroomUserProfile -StoreBad $StoreBad -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning "Google Classroom Service was disconnected"
                    Write-Warning $Exc.Exception.InnerException
                    Start-Sleep -Seconds 5
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
        Write-Warning "Could not look up Classroom User Profile: $($UserId)"
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
            Import-Clixml -Path $Cache_File
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
    [OutputType('Object[]')]
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
            $r += Import-Clixml -Path $Cache_File
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
    If ($InputObject -eq $null)
    {
        Return
    }
    $Old = @()
    $New = @()
    $OutputObject = @()
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
        $Cache_AdminEMail = $(Show-PSGSuiteConfig).AdminEmail
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
            If ($Exc.Exception.InnerException -eq $null)
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
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning "Google Classroom Service was unavailable"
                    Start-Sleep -Seconds 1
                    Return Get-_GSCourse -Id $Id -BypassCache $BypassCache -SkipCache $SkipCache -CacheOnly $CacheOnly -Cache_GSCourse $Cache_GSCourse -Cache_GSCourseAlias $Cache_GSCourseAlias -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::InternalServerError)
                {
                    Write-Warning "Google Classroom got an internal server error"
                    Start-Sleep -Seconds 1
                    Return Get-_GSCourse -Id $Id -BypassCache $BypassCache -SkipCache $SkipCache -CacheOnly $CacheOnly -Cache_GSCourse $Cache_GSCourse -Cache_GSCourseAlias $Cache_GSCourseAlias -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning "Google Classroom Service was disconnected"
                    Write-Warning $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
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
            If ($Exc.Exception.InnerException -eq $null)
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
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning "Google Classroom Service was unavailable"
                    Start-Sleep -Seconds 5
                    Return Get-_GSCourseParticipant -CourseId $CourseId -Role $Role -Verbose
                }
                If ($HttpStatusCode -eq 429)
                {
                    Write-Warning "Google Classroom Service is limited, holding off"
                    $RetryMS = 30000
                    Write-Verbose ("Waiting for {0} seconds" -f $RetryMS/100)
                    Start-Sleep -Milliseconds $RetryMS
                    Return Get-_GSCourseParticipant -CourseId $CourseId -Role $Role -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning "Google Classroom Service was disconnected"
                    Write-Warning $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Get-_GSCourseParticipant -CourseId $CourseId -Role $Role -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
             }
        }
        Return $r
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
    PROCESS
    {
        $r = @()
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        try
        {
            $r += New-GSCourseInvitation -CourseId $CourseId -UserId $UserId -Role $Role -User $User -ErrorAction Stop
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            If ($Exc.Exception.InnerException -eq $null)
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
                ElseIf ($HttpStatusCode -eq 429) #Too Many Requests
                {
                    #Return "429"
                    $RetryS = 300
                    Write-Verbose -Message "Waiting for $($RetryS) seconds"
                    Start-Sleep -Seconds $RetryS
                    Return New-_GSCourseInvitation -CourseId $CourseId -UserId $UserId -Role $Role -User $User -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::BadRequest)
                {
                    #Write-Warning "Google Classroom $($CourseId) had changed state"
                    Write-Warning "Failed to to add $($UserId) As $($Role) As $($User)"
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning "Google Classroom Service was unavailable"
                    Start-Sleep -Seconds 5
                    Return New-_GSCourseInvitation -CourseId $CourseId -UserId $UserId -Role $Role -User $User -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Forbidden)
                {
                    #Write-Warning "Google Classroom $($CourseId) had changed state"
                    Write-Warning "Denied to to add $($UserId) As $($Role) As $($User)"
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning "Google Classroom Service was disconnected"
                    Write-Warning $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return New-_GSCourseInvitation -CourseId $CourseId -UserId $UserId -Role $Role -User $User -Verbose
                }
                Write-Warning $HttpStatusCode
                
                Throw $Exc.Exception.InnerException
            }
        }
        If ($r.Count -gt 0)
        {
            Return $r
        }
    }
}

Function Get-_GSCourseInvitation
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
        $i = @()
        $i += Get-GSCourseInvitation -CourseId $CourseId
        If ($i.Count -eq 0)
        {
            Return
        }
        $r = @()
        $r += $i | Where-Object -Property Role -In -Value $Role
        If ($r.Count -eq 0)
        {
            Return
        }
        Return $r
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
        #$i = $null
        Try
        {
            #$id = Get-GSCourseInvitation -Id $Id -User $User -ErrorAction Stop | Select-Object -ExpandProperty Id
        }
        Catch
        {
            $Exc = $_
            Write-Host $Exc.Exception
        }

        If ($i -eq $null)
        {
            #Return
        }

        Try
        {
            $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
            Confirm-GSCourseInvitation -Id $Id -User $User -ErrorAction Stop | Out-Null
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            If ($Exc.Exception.InnerException -eq $null)
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
                    Write-Warning "Not Found on processing Google Classroom Invitation for user $($User): $(ConvertTo-Json $I -Depth 1)"
                    Return $i
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Forbidden)
                {
                    Write-Warning "Forbidden on processing Google Classroom Invitation for user $($User): $(ConvertTo-Json $I -Depth 1)"
                    Return $i
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::InternalServerError)
                {
                    Write-Warning "Internal Error on processing Google Classroom Invitation for user $($User): $(ConvertTo-Json $I -Depth 1)"
                    Return $i
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning "Google Classroom Service was unavailable"
                    Start-Sleep -Seconds 5
                    Return Confirm-_GSCourseInvitation -Id $Id -User $User -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning "Google Classroom Service was disconnected"
                    Write-Warning $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Confirm-_GSCourseInvitation -Id $Id -User $User -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
             }
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
        Try
        {
            $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
            $r += New-GSCourse -Name $Name -OwnerId $OwnerId -Id $Id -Section $Section -Room $Room -CourseState $CourseState -ErrorAction Stop
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            If ($Exc.Exception.InnerException -eq $null)
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
                    Write-Warning "Google User $($OwnerId) can not make a Google Classroom"
                    Write-Warning $Exc.Exception.InnerException
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning "Google Classroom Service was unavailable"
                    Start-Sleep -Seconds 5
                    Return New-_GSCourse -Name $Name -OwnerId $OwnerId -Id $Id -Section $Section -Room $Room -CourseState $CourseState -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::InternalServerError)
                {
                    Write-Warning "Google Classroom Service had an internal server error, retry?"
                    Start-Sleep -Seconds 5
                    Return New-_GSCourse -Name $Name -OwnerId $OwnerId -Id $Id -Section $Section -Room $Room -CourseState $CourseState -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning "Google Classroom Service was disconnected"
                    Write-Warning $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return New-_GSCourse -Name $Name -OwnerId $OwnerId -Id $Id -Section $Section -Room $Room -CourseState $CourseState -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Conflict)
                {
                    Write-Warning "Course $($Id) could not be created, it already exists"
                    Write-Warning $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Get-_GSCourse -Id $Id -BypassCache:$true -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
             }
        }
        If ($r.Count -gt 0)
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
    If ($Id -eq $null)
    {
        Write-Error "No invites to remove"
        Return
    }
    Try
    {
        $HttpStatusCode = [System.Net.HttpStatusCode]::Unused
        $r = Remove-GSCourseInvitation -Id $Id -User $User -Confirm:$false -ErrorAction Stop
    }
    Catch [System.Management.Automation.MethodInvocationException]
    {
        $Exc = $_
        If ($Exc.Exception.InnerException -eq $null)
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
                Write-Warning "Cound not find Invitation as $($User)"
                Return $Id
            }
            If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Forbidden)
            {
                Write-Warning "No right to remove Invitation as $($User)"
                Return $Id
            }
            If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
            {
                Write-Warning "Google Classroom Service was unavailable"
                Start-Sleep -Seconds 5
                Return Remove-_GSCourseInvitation -Id $Id -User $User -Verbose
            }
            If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
            {
                Write-Warning "Google Classroom Service was disconnected"
                Write-Warning $Exc.Exception.InnerException
                Start-Sleep -Seconds 1
                Return Remove-_GSCourseInvitation -Id $Id -User $User -Verbose
            }
            Write-Warning $HttpStatusCode

            Throw $Exc.Exception.InnerException
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
        Try
        {
            $r += Remove-GSCourseParticipant -CourseId $CourseId -Student $Student -User $User -Confirm:$false -ErrorAction Stop
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            #Write-Host $Exc.Exception
            If ($Exc.Exception.InnerException -eq $null)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -in ([System.Net.HttpStatusCode]::NotFound))
                {
                    Write-Verbose "Could not remove this Student: $($Student) from Course: $($CourseId) With User: $($User) Error: $($HttpStatusCode)"
                    Return
                }
                If ($HttpStatusCode -in ([System.Net.HttpStatusCode]::Forbidden))
                {
                    Write-Warning "Could not remove this Student: $($Student) from Course: $($CourseId) With User: $($User) Error: $($HttpStatusCode)"
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning "Google Classroom Service was unavailable"
                    Start-Sleep -Seconds 5
                    Return Remove-_GSCourseStudent -CourseId $CourseId -Student $Student -User $User -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::InternalServerError)
                {
                    Write-Warning "Google Classroom Service was unavailable"
                    Start-Sleep -Seconds 5
                    Return Remove-_GSCourseStudent -CourseId $CourseId -Student $Student -User $User -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning "Google Classroom Service was disconnected"
                    Write-Warning $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Remove-_GSCourseStudent -CourseId $CourseId -Student $Student -User $User -Verbose
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
             }
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
        Try
        {
            $r += Add-GSCourseParticipant -CourseId $CourseId -Teacher $Teacher -ErrorAction Stop
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            $Exc = $_
            #Write-Host $Exc.Exception
            If ($Exc.Exception.InnerException -eq $null)
            {
                Throw $Exc.Exception
            }
            Else
            {
                If ($null -ne $Exc.Exception.InnerException.HttpStatusCode)
                {
                    $HttpStatusCode = $Exc.Exception.InnerException.HttpStatusCode
                }

                If ($HttpStatusCode -in ([System.Net.HttpStatusCode]::NotFound))
                {
                    Write-Verbose "Could not add this Teacher: $($Teacher) from Course: $($CourseId) Error: $($HttpStatusCode)"
                    Return
                }
                If ($HttpStatusCode -in ([System.Net.HttpStatusCode]::Forbidden))
                {
                    Write-Warning "Could not add this Teacher: $($Teacher) from Course: $($CourseId) Error: $($HttpStatusCode)"
                    Return
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::ServiceUnavailable)
                {
                    Write-Warning "Google Classroom Service was unavailable"
                    Start-Sleep -Seconds 5
                    Return Add-_GSCourseTeacher -CourseId $CourseId -Teacher $Teacher -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::InternalServerError)
                {
                    Write-Warning "Google Classroom Service was unavailable"
                    Start-Sleep -Seconds 5
                    Return Add-_GSCourseTeacher -CourseId $CourseId -Teacher $Teacher -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Unused)
                {
                    Write-Warning "Google Classroom Service was disconnected"
                    Write-Warning $Exc.Exception.InnerException
                    Start-Sleep -Seconds 1
                    Return Add-_GSCourseTeacher -CourseId $CourseId -Teacher $Teacher -Verbose
                }
                If ($HttpStatusCode -eq [System.Net.HttpStatusCode]::Conflict)
                {
                    Write-Verbose "This Teacher: $($Teacher) is already in Course: $($CourseId)"
                    Return
                }
                Write-Warning $HttpStatusCode

                Throw $Exc.Exception.InnerException
             }
        }
    }
}
