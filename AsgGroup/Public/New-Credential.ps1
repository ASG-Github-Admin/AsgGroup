function New-Credential {

    <#
    .SYNOPSIS
    Create a PowerShell Credential object.

    .DESCRIPTION
    This function creates a PowerShell Credential object using the specified username, and encrypted password file
    path.

    .EXAMPLE
    PS C:\PS> New-Credential -Username "jbloggs@contoso.com" -EncryptedPasswordFilePath "C:\Passwd"

    Description
    -----------
    This creates a PowerShell Credential object with the username of "jbloggs@contoso.com", and the encrypted
    password file "C:\Passwd".

    .PARAMETER EncryptedPasswordFilePath
    Specifies a path to an encrypted password file.

    .PARAMETER Username
    Specifies the username to be used in the PowerShell credential object.

    .INPUTS
    System.String for both the username and encrypted password file path parameters.

    You can pipe a file system path (in quotation marks) to this function.

    .OUTPUTS
    System.Management.Automation.PSCredential
    #>

    [CmdLetBinding()]
    param (
        
        # Username
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Username,

        # Encrypted password file path
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript( 
            { Test-Path -Path $PSItem -PathType Leaf },
            ErrorMessage = "'{0}' does not exist."
        )]
        [Alias("Path", "FilePath", "PasswordFilePath")]
        [string] $EncryptedPasswordFilePath
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

            # Encrypted string read from file
            Write-Debug -Message "Getting encrypted string from '$EncryptedPasswordFilePath'"
            Write-Verbose -Message "Getting encrypted password from file"
            $EncryptedStr = Get-Content -Path $EncryptedPasswordFilePath

            # Encrypted string conversion to secure string
            Write-Debug -Message "Converting encrypted string to secure string"
            Write-Verbose -Message "Decrypting password"
            $SecStr = ConvertTo-SecureString -String $EncryptedStr

            # PowerShell credential object creation
            Write-Debug -Message "Creating PowerShell credential object with '$Username' and secure string"
            Write-Verbose -Message "Creating credential with username and password"
            [pscredential]::new($Username, $SecStr)
        }
        catch { Write-Error -ErrorRecord $PSItem -ErrorAction $CallerEA }
    }
}