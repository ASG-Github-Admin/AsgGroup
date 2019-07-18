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
    System.String
    #>
    
    [CmdLetBinding()]
    param (
    
        # Directory path
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( 
            
            # Directory path validation
            { Test-Path -Path $PSItem -PathType Container },
            ErrorMessage = "'{0}' does not exist."
        )]
        [Alias("Directory", "DirectoryPath")]
        [string] $Path
    )

    begin {

        # Error handling
        Set-StrictMode -Version "Latest"
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $CallerEA = $ErrorActionPreference
        $ErrorActionPreference = "Stop"
    }
    
    process {

        try {

            if (($Path.ToCharArray() | Select-Object -Last 1) -eq "\") {

                # Trailing backslash removed from path entered
                Write-Debug -Message "Removing trailing backslash from '$Path'"
                Write-Verbose -Message "Removing trailing backslash from path entered"
                $Path = $Path.TrimEnd("\")
            }

            if ($env:PSModulePath -split ";" -contains $Path) {
                
                # Path already exists
                Write-Host -Object "'$Path' already exists."
                break
            }

            # Path update
            Write-Debug -Message "Appending '$Path' to '$env:PSModulePath'"
            Write-Verbose -Message "Updating environmental PowerShell module path variable"
            $NewPSModPath = $env:PSModulePath += ";$Path"
            [System.Environment]::SetEnvironmentVariable("PSModulePath", $NewPSModPath, "Machine")

            # New path output
            Write-Debug -Message "Outputting '`$env:PSModulePath' as a string"
            Write-Verbose -Message "Outputting new module path"
            Write-Output -InputObject $env:PSModulePath
        }
        catch { Write-Error -ErrorRecord $PSItem -ErrorAction $CallerEA }
    }
}