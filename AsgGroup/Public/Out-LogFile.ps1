function Out-LogFile {

    <#
    .SYNOPSIS
    Sends output to a file in a log format.

    .DESCRIPTION
    The function sends the specified string as output to the specified file path in a log format using levels.

    .EXAMPLE
    PS C:\PS> Out-LogFile -Path "C:\log.log" -Level Error -Entry "Descriptive error message here."

    Description
    -----------
    This adds the entry string object to the 'log.log' file, with the error flag.

    .PARAMETER Entry
    Specifies the entry to add to the specified log file.

    .PARAMETER Path
    Specifies a file system path.

    .PARAMETER Level
    Specifies the level of the entry into the log file, from predefined set - Error, Warning, and Information.

    .INPUTS
    System.String

    You can pipe a string object (in quotation marks) for the entry parameter to this function.

    .OUTPUTS
    System.String

    It also outputs a string object as the log entry with the log level to the specified file path.
    #>
    
    [CmdLetBinding()]
    param (
        
        # Log file path
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias("File", "FilePath")]
        [string] $Path,

        # Log file entry type
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Error", "Warning", "Information")]
        [string] $Level,

        # Log file entry
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $Entry,

        # Object passed through to pipeline
        [switch] $Passthru
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
    
            # String output to file
            $EntryDateTime = Get-Date -UFormat "%Y-%m-%d %H:%M:%S"
            Write-Debug -Message "Adding $Level '$Entry' with time stamp of '$EntryDateTime' to '$Path'"
            Write-Verbose -Message "Adding entry string to file"
            Out-File -InputObject "[$EntryDateTime] $Level`: $Entry" -FilePath $Path -Append
        
            if ($Passthru) {
             
                # String output to pipeline
                Write-Debug -Message "Writing '$Entry' to pipeline as 'Passthru' parameter is set to true"
                Write-Verbose -Message "Writing entry string to pipeline"
                Write-Output -InputObject $Entry
            }
        }
        catch { Write-Error -ErrorRecord $PSItem -ErrorAction $CallerEA }
    }
}