function New-EncryptedPasswordFile {
    
    <#
    .SYNOPSIS
    Creates a file with a password as an encrypted string.

    .DESCRIPTION
    This function converts the specified secure string password to an encrypted string, and outputs it to the
    specified file system path.

    .EXAMPLE
    PS C:\PS> New-EncryptedPasswordFile -Path "C:\PowerShell Passwords\Passwd.txt"

    Description
    -----------
    This creates an encrypted password file 'Passwd.txt' in the 'C:\PowerShell Passwords' directory.

    .EXAMPLE
    PS C:\PS> New-EncryptedPasswordFile -Path "C:\PowerShell Passwords\Passwd.txt"

    Description
    -----------
    This creates an encrypted password file 'Passwd.txt' in the 'C:\PowerShell Passwords' directory.

    .PARAMETER Password
    Specifies a secure string object containing the password.

    .PARAMETER Path
    Specifies a path for the file to be created.

    .INPUTS
    securestring, System.String

    You can pipe a file system path (in quotation mark) to this function.

    .OUTPUTS
    None

    Creates a file using the specified file path.
    #>
    
    [CmdLetBinding()]
    param (

        # Output file path
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript(
            
            # Parent directory path validation
            { Split-Path -Path $PSItem -Parent | Test-Path -PathType Container },
            ErrorMessage = "The parent of the path entered '{0}' does not exist."
        )]
        [Alias("File", "FilePath")]
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

            # Secure string password prompt
            Write-Debug -Message "Reading string from host as a secure string"
            Write-Verbose -Message "Prompting for password from host"
            $Password = Read-Host -Prompt Password -AsSecureString

            # Encrypted string out to file path
            Write-Debug -Message "Converting to encrypted string  and writing to '$Path'"
            Write-Verbose -Message "Saving password as an encrypted string"
            ConvertFrom-SecureString -SecureString $Password | Out-File -FilePath $Path -Force
        }
        catch { Write-Error -ErrorRecord $PSItem -ErrorAction $CallerEA }
    }
}