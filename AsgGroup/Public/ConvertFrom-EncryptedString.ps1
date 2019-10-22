function ConvertFrom-EncryptedString {

    <#
    .SYNOPSIS
    Converts an encrypted string to a string.
    .DESCRIPTION
    The ConvertFrom-EncryptedString function converts an encrypted string in the form of a string object to a
    string ( System.String ).
    .EXAMPLE
    PS C:\> $SecureString = Read-Host -AsSecureString
    ***
    PS C:\> $EncryptedString = ConvertFrom-SecureString -SecureString $SecureString
    PS C:\> ConvertFrom-EncryptedString -String $EncryptedString
    abc
    Description
    -----------
    This example shows a secure string object being created with the variable name '$SecureString' using the
    Read-Host cmdlet with 'AsSecureString' parameter, and then converted to an encrypted string using the
    'ConvertFrom-EncryptedString' cmdlet, and finally converted from the encrypted string back to a string.
    .EXAMPLE
    PS C:\> $EncryptedString | ConvertFrom-EncryptedString
    abc
    Description
    -----------
    This example shows the previous encrypted string passed as a string object through to the function.
    .EXAMPLE
    PS C:\> ConvertFrom-EncryptedString -String $EncryptedStringArray
    abc
    xyz
    123
    Description
    -----------
    This example shows the function converting an array of encrypted strings into strings.
    .PARAMETER String
    Specifies the encrypted string in the form of a string object to be converted to a string.
    .INPUTS
    System.String
    .OUTPUTS
    System.String
    #>

    #Requires -Version 6.2

    [CmdLetBinding()]
    param (
        
        # Encrypted string in the form of a string object
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string[]] $String
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

            $String.foreach{

                # Convert the encrypted string to a secure string
                Write-Debug -Message "Converting the encrypted string '$PSItem' to a secure string"
                Write-Verbose -Message "Converting the encrypted string to a secure string"
                $SecStr = ConvertTo-SecureString -String $PSItem

                # Convert the secure string to a string
                Write-Debug -Message "Converting the secure string to a string"
                Write-Verbose -Message "Converting the secure string to a string"
                $Str = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            
                    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecStr)
                )

                # Write the string out
                Write-Output -InputObject $Str
            }
        }
        catch { Write-Error -ErrorRecord $PSItem -EA $CallerEA }
    }
}