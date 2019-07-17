# Pester test invocation
# Pester tests invoked, XML results serialised and pulled intp 'appveyor.yml'

# Parameters #

param(
    
    # XML output collected, tests uploaded, indicate build errors
    [switch] $Finalise,

    # Test with current PowerShell version, results uploaded
    [switch] $Test,

    # Project root directory
    [string] $ProjectRoot = $env:APPVEYOR_BUILD_FOLDER
)

# Variables #

# Current date time stamp in UNIX format
$TimeStamp = Get-Date -UFormat "%Y%m%d-%H%M%S"

# PowerShell major version number
$PSMajVer = $PSVersionTable.PSVersion.Major

# XML test file name
$TestFileName = "TestResults_PS$PSMajVer`_$TimeStamp.xml"

# Appveyor job identifier uniform resource locator
$URL = "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)"

# Begin #

# Location changed to project root
Set-Location -Path $ProjectRoot

# Verbose setting
$Verbose = @{ }

# Process #

# Verbose enabled when branch is not like 'master'
if ($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master") { $Verbose.Add("Verbose", $true) }

if ($Test) {

    Write-Host -Object "`n`tStatus: Testing with PowerShell $PSMajVer`n"

    Import-Module -Name Pester -Force

    $TestFilePath = "$ProjectRoot\$TestFileName"
    Invoke-Pester @Verbose -Path "$ProjectRoot\Tests" -OutputFormat NUnitXml -OutputFile $TestFilePath -PassThru |
    Export-Clixml -Path "$ProjectRoot\PesterResults_PS$PSMajVer`_$TimeStamp.xml"
    
    if ($env:APPVEYOR_JOB_ID) { ([System.Net.WebClient]::new()).UploadFile($URL, $TestFilePath) }
}

if ($Finalise) {

    # Pester test result summary
    $AllFiles = Get-ChildItem -Path $ProjectRoot\PesterResults*.xml |
    Select-Object -ExpandProperty FullName
    Write-Host -Object "`n`tStatus: Finalising results`n"
    Write-Host -Object "Collating files:`n$($AllFiles | Out-String)"

    # Result collection
    $Results = @(Get-ChildItem -Path "$ProjectRoot\PesterResults_PS*.xml" | Import-Clixml)
    
    # Failed test check
    $FailedCount = $Results | Select-Object -ExpandProperty FailedCount |
    Measure-Object -Sum | Select-Object -ExpandProperty Sum

    if ($FailedCount -gt 0) {

        # Failed item collection
        $FailedItems = $Results | Select-Object -ExpandProperty TestResult |
        Where-Object -FilterScript { $PSItem.Passed -notlike $true }

        # Failed tests summary list
        Write-Host -Object "Failed tests summary:`n"
        $FailedItems | ForEach-Object -Process {

            [pscustomobject]@{
                
                Describe = $PSItem.Describe
                Context  = $PSItem.Context
                Name     = "It $($PSItem.Name)"
                Result   = $PSItem.Result
            }
        } | Sort-Object -Property Describe, Context, Name, Result | Format-List

        # Build fail with test failure count
        throw "$FailedCount test(s) failed."
    }
}