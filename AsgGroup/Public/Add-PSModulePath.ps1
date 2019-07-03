function Add-PSModulePath {
    
    <#
    .SYNOPSIS
    Adds a directory path to the PowerShell global environment variable.

    .DESCRIPTION
    This function adds the specified directory path to the PowerShell global environment variable on the computer.

    .EXAMPLE
    PS C:\PS> Add-PSModulePath -DirectoryPath "D:\PowerShell Modules"

    Description
    -----------
    This adds the 'D:\PowerShell Modules' directory path to the PowerShell global environment variable.

    .PARAMETER DirectoryPath
    Specifies a path to a location.
    
    .INPUTS
    System.String

    You can pipe a file system path (in quotation marks) to this function.

    .OUTPUTS
    None
    #>
    
    #Requires -Version 6.2
    
    [CmdLetBinding()]
    param (
    
        # Directory path
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                # Directory path validation
                if (Test-Path -Path $PSItem -PathType Container) { $true }
                else { throw "'$PSItem' is not a valid directory path." }
            }
        )]
        [string] $Path,
        
        # Registry key value backup
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            {
                # Directory path validation
                if (Test-Path -Path $PSItem -PathType Container) { $true }
                else { throw "'$PSItem' is not a valid directory path." }
            }
        )]
        [string] $RegistryKeyBackupDirectoryPath
    )

    begin {

        # Error handling
        Set-StrictMode -Version "Latest"
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $CallerEA = $ErrorActionPreference
        $ErrorActionPreference = "Stop"

        # Custom exception class
        class RegistryExportException : System.Exception {
            
            RegistryExportException ([string] $Message) : base($Message) { }      
            RegistryExportException () { }
        }

        # Trailing back slash trimmed on path variable
        $Path = $Path.TrimEnd("\")
    }
    
    process {

        try {

            # Current PowerShell module path
            Write-Debug -Message "Getting current data of 'PSModulePath' value in '$RegPath'"
            Write-Verbose -Message "Getting current PowerShell module path"
            $RegPath = "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment"
            $PSModulePath = (Get-ItemProperty -Path $RegPath -Name PSModulePath).PSModulePath
            
            if ($PSModulePath.Split(";").Contains($Path)) {

                # Directory path already exists
                Write-Warning -Message "'$Path' already exists in PowerShell module path."
                break
            }

            if ($RegistryKeyBackupDirectoryPath) {

                # Registry key backup when specified
                $RegBackupFileName = "Registry key backup $(Get-Date -Format "HHmmss ddMMyyyy").reg"
                $RegBackupFilePath = "$($RegistryKeyBackupDirectoryPath.TrimEnd("\"))\$RegBackupFileName"
                $KeyName = $RegPath.Replace("Registry::HKEY_LOCAL_MACHINE", "HKLM")
                Write-Debug -Message "Backing up '$RegPath' registry key to '$RegBackupFilePath' as specified"
                Write-Verbose -Message "Backing up registry key"
                $RegExport = reg.exe export $KeyName $RegBackupFilePath
            }

            if (($RegistryKeyBackupDirectoryPath) -and ($RegExport -ne "The operation completed successfully.")) {

                # Backup unsuccessful
                Write-Debug -Message "'reg.exe' reported '$RegExport' when exporting '$KeyName'"
                Write-Verbose -Message "Backup operation did not report as completed sucessfully"
                $ErrorParams = @{

                    ExceptionName    = "RegistryExportException"
                    ExceptionMessage = "Export of '$KeyName' to file '$RegBackupFilePath' was unsuccessful."
                    ExceptionObject  = $RegExport
                    ErrorId          = "RegistryExportNotSuccessful"
                }
                ThrowError -errorCategory InvalidResult @ErrorParams
            }

            # Path update
            Write-Debug -Message "Appending new '$Path' to '$PSModulePath'"
            Write-Verbose -Message "Appending new path"
            $Value = "$PSModulePath;$Path"
            Set-ItemProperty -Path $RegPath -Name PSModulePath -Value $Value

            # New path output
            Write-Debug -Message "Getting new data of 'PSModulePath' value in '$RegPath'"
            Write-Verbose -Message "Getting new PowerShell module path"
            (Get-ItemProperty -Path $RegPath -Name "PSModulePath").PSModulePath
        }
        catch { Write-Error -ErrorRecord $PSItem -ErrorAction $CallerEA }
    }
}