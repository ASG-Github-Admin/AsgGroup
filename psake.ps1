# PSake makes variables declared here available in other scriptblocks
# Init some things
Properties {

    # Find the build folder based on build system
    $ProjectRoot = $ENV:BHProjectPath
    if (-not $ProjectRoot) { $ProjectRoot = $PSScriptRoot }

    $TimeStamp = Get-Date -UFormat "%Y%m%d-%H%M%S"
    $PSVerMaj = $PSVersionTable.PSVersion.Major
    $TestFileName = "TestResults_PS$PSVerMaj`_$TimeStamp.xml"
    $Lines = '----------------------------------------------------------------------'

    $Verbose = @{ }
    if ($ENV:BHCommitMessage -match "!verbose") { 
        
        $Verbose = @{ Verbose = $True } 
    }
}

Task Default -Depends Deploy
Write-Output -InputObject "`n"

Task Init {

    Write-Output -InputObject $Lines
    Set-Location -Path $ProjectRoot
    Write-Output -InputObject "`nBuild system details:"
    Get-Item -Filter ENV:BH*
}

Task Check -Depends Init {

    Write-Output -InputObject $Lines
    Write-Output -InputObject "`nStatus: Checking files with 'PSScriptAnalyzer'"
    Invoke-ScriptAnalyzer -Path $ProjectRoot
}

Task Test -Depends Check {

    Write-Output -InputObject $Lines
    Write-Output -InputObject "`nStatus: Testing with PowerShell $PSVerMaj`n"

    # Gather test results. Store them in a variable and file
    $TestFilePath = "$ProjectRoot\$TestFileName"
    $TestRslts = Invoke-Pester -Path $ProjectRoot\Tests -PassThru -OutputFormat NUnitXml -OutputFile $TestFilePath

    # In Appveyor?  Upload our tests! #Abstract this into a function?
    if ($ENV:BHBuildSystem -eq 'AppVeyor') {
    
        (New-Object -TypeName 'System.Net.WebClient').UploadFile(

            "https://ci.appveyor.com/api/testresults/nunit/$($ENV:APPVEYOR_JOB_ID)",
            $TestFilePath
        )
    }

    Remove-Item -Path $TestFilePath -Force -ErrorAction SilentlyContinue

    # Failed tests?
    # Need to tell psake or it will proceed to the deployment. Danger!
    if ($TestRslts.FailedCount -gt 0) {
        
        Write-Error -Message "Build failed due to '$($TestRslts.FailedCount)' failed tests."
    }
    Write-Output -InputObject "`n"
}

Task Build -Depends Test {

    Write-Output -InputObject $Lines
    
    # Load the module, read the exported functions, update the psd1 FunctionsToExport
    Set-ModuleFunctions

    # Bump the module version
    try {
    
        $Ver = Get-NextPSGalleryVersion -Name $ENV:BHProjectName -ErrorAction Stop
        Update-Metadata -Path $ENV:BHPSModuleManifest -PropertyName ModuleVersion -Value $Ver -ErrorAction Stop
    }
    catch {
    
        "Failed to update version for '$ENV:BHProjectName': $_.`ncontinuing with existing version" |
        Write-Output
    }
    Write-Output -InputObject "`n"
}

Task Deploy -Depends Build {

    Write-Output -InputObject $Lines

    $Params = @{

        Path    = $ProjectRoot
        Force   = $true
        Recurse = $false # We keep psdeploy artifacts, avoid deploying those : )
    }
    Invoke-PSDeploy @Verbose @Params
}