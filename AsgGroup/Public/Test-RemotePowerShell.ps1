function Test-RemotePowerShell {
    
    <#
    .SYNOPSIS
    Displays diagnostic information for a remote PowerShell connection.

    .DESCRIPTION
    The Test-RemotePowerShell function displays diagnostic information for a remote PowerShell connection. The
    output includes the results of DNS lookup, a listing of the remote TCP/IP interface, WinRM port availability
    and service enablement, PowerShell version, and a confirmation of connection establishment.

    .EXAMPLE
    PS C:\PS> Test-RemotePowerShell -Name Server1

    Description
    -----------
    This tests the PowerShell capability to remote computer 'Server1'.

    .EXAMPLE
    PS C:\PS> Get-ADComputer -Filter * | Test-RemotePowerShell

    Description
    -----------
    This tests the PowerShell capability to all computers in Active Directory.

    .PARAMETER Name
    Specifies the Domain Name System (DNS) name or the IP address of the target computer.

    .INPUTS
    System.String or Microsoft.ActiveDirectory.Management.ADComputer

    .OUTPUTS
    AsgGroup.TestRemotePowerShell
    #>
    
    #Requires -Version 6.2
    
    [CmdLetBinding()]
    param (

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("ComputerName", "Computer", "Server")]
        [string] $Name
    )

    begin {
        
        # Error handling
        Set-StrictMode -Version "Latest"
        Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
        $CallerEA = $ErrorActionPreference
        $ErrorActionPreference = "Stop"

        # Error & warning supression parameters
        $ErrWarnAction = @{ 
            
            ErrorAction   = "SilentlyContinue"
            WarningAction = "SilentlyContinue"
        }

        # Progression status supression
        $ProgressPreference = "SilentlyContinue"

        # Local IP address(es)
        $LocEthAdptr = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
        Where-Object -FilterScript {
            
            $PSItem.OperationalStatus -eq "Up" -and $PSItem.NetworkInterfaceType -eq "Ethernet"
        }

        $LocalIPAddr = $LocEthAdptr | ForEach-Object -Process {
            
            Write-Output -InputObject $PSItem.GetIPProperties().UnicastAddresses.Address.IPAddressToString
        }
    }
    
    process {

        try {

            if ($Name -eq $env:COMPUTERNAME -or $LocalIPAddr.Contains($Name)) {

                Write-Debug -Message "'$Name' is equivalent to local computer name variable or IP address(es)"
                Write-Verbose -Message "'$Name' is the local computer"
                Write-Warning -Message "'$Name' matches the local computer name or IP address(es)"
                return
            }

            # Ping test
            Write-Debug -Message "Sending IMCP echo request (ping) to '$Name'"
            Write-Verbose -Message "Testing network connection using ping"
            $Ping = [System.Net.NetworkInformation.Ping]::new()
            $PingTest = if ($Ping.Send($Name) -eq "Success") { Write-Output -InputObject $true }
            else { Write-Output -InputObject $false }

            # Remote IP address
            $RemIPAddr = if ($PingTest) { 
                
                Write-Debug -Message "Getting remote IP address of '$Name' that responded to ping"
                Write-Verbose -Message "Getting remote computer IP address"
                Write-Output -InputObject $PingTest.Address.IPAddressToString 
            }
            else { Write-Output -InputObject $null }

            # Windows Remote Management (WinRM) network port test
            "Testing Windows Remote Management (WinRM) TCP port on '$Name' and supressing errors and warnings" |
            Write-Debug
            Write-Verbose -Message "Testing Windows Remote Management (WinRM) TCP port"
            $TCPTest = Test-Connection -TargetName $Name -TCPPort 5985

            # Web Services Management Service (WSMan) test
            "Testing Web Services Management (WSMan) on '$Name' with errors and warnings supressed" |
            Write-Debug
            Write-Verbose -Message "Testing Web Services Management (WSMan) on '$Name'"
            $WSManTest = if (Test-WSMan -ComputerName $Name @ErrWarnAction) { Write-Output -InputObject $true }
            else { Write-Output -InputObject $false }
            
            # Remote PowerShell version check  
            $PSVerChk = if ($WSManTest) {
                
                "Invoking command on '$Name' to get PowerShell version with errors and warnings supressed" |
                Write-Debug
                Write-Verbose -Message "Getting PowerShell version on '$Name'"
                $PS = Invoke-Command -ComputerName $Name -ScriptBlock { $PSVersionTable.PSVersion } @ErrWarnAction

                if ($PS) { Write-Output -InputObject "$($PS.Major).$($PS.Minor)" }
                else { Write-Output -InputObject $null }
            }
            else { Write-Output -InputObject $null }

            # Custom object creation
            $Obj = [pscustomobject]@{

                ComputerName    = $Name
                PingSucceeded   = $PingTest
                RemoteIPAddress = $RemIPAddr
                PortAvailable   = $TCPTest
                WinRMEnabled    = $WSManTest
                Version         = $PSVerChk
            }
            
            # Object type name set
            $Obj.PSObject.TypeNames.Insert(0, "AsgGroup.TestRemotePowerShell")

            # Object output
            Write-Output -InputObject $Obj
        }
        catch { Write-Error -ErrorRecord $PSItem -ErrorAction $CallerEA }
    }
}