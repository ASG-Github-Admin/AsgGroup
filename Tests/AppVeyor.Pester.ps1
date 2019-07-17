# Pester test invocation
# Pester tests invoked, XML results serialised and pulled intp 'appveyor.yml'

#If Finalize is specified, we collect XML output, upload tests, and indicate build errors
param(
    
    # XML output collected, tests uploaded, indicate build errors
    [switch] $Finalise,

    # Test with current PowerShell version, results uploaded
    [switch] $Test,

    # Project root directory
    [string] $ProjectRoot = $env:APPVEYOR_BUILD_FOLDER
)

#Initialize some variables, move to the project root
$TimeStamp = Get-Date -UFormat "%Y%m%d-%H%M%S"
$PSMajVer = $PSVersionTable.PSVersion.Major
$TestFile = "TestResults_PS$PSMajVer`_$TimeStamp.xml"

$URL = "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)"
Set-Location -Path $ProjectRoot

$Verbose = @{ }
if ($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master") { $Verbose.Add("Verbose", $true) }
   
if ($Test) {

    Write-Host -Object "`n`tStatus: Testing with PowerShell $PSMajVer`n"

    Import-Module -Name Pester -Force

    $TestFilePath = "$ProjectRoot\$TestFile"
    Invoke-Pester @Verbose -Path "$ProjectRoot\Tests" -OutputFormat NUnitXml -OutputFile $TestFilePath -PassThru |
    Export-Clixml -Path "$ProjectRoot\PesterResults_PS$PSMajVer`_$TimeStamp.xml"
    
    if ($env:APPVEYOR_JOB_ID) { ([System.Net.WebClient]::new()).UploadFile($URL, $TestFilePath) }
}

#If finalize is specified, display errors and fail build if we ran into any
if ($Finalise) {

    #Show status...
    $AllFiles = Get-ChildItem -Path $ProjectRoot\PesterResults*.xml |
    Select-Object -ExpandProperty FullName
    Write-Host -Object "`n`tStatus: Finalizing results`n"
    Write-Host -Object "Collating files:`n$($AllFiles | Out-String)"

    #What failed?
    $Results = @(Get-ChildItem -Path "$ProjectRoot\PesterResults_PS*.xml" | Import-Clixml)
    
    $FailedCount = $Results | Select-Object -ExpandProperty FailedCount |
    Measure-Object -Sum | Select-Object -ExpandProperty Sum

    if ($FailedCount -gt 0) {

        $FailedItems = $Results | Select-Object -ExpandProperty TestResult |
        Where-Object -FilterScript { $PSItem.Passed -notlike $true }

        Write-Host -Object "Failed tests summary:`n"
        $FailedItems | ForEach-Object -Process {

            [pscustomobject]@{
                
                Describe = $PSItem.Describe
                Context  = $PSItem.Context
                Name     = "It $($PSItem.Name)"
                Result   = $PSItem.Result
            }
        } | Sort-Object -Property Describe, Context, Name, Result | Format-List

        throw "$FailedCount test(s) failed."
    }
}