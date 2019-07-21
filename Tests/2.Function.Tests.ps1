if ($ENV:BHPSModulePath) { Import-Module -Name $ENV:BHPSModulePath -Force }
else { Import-Module -Name "$PSScriptRoot\$(Split-Path -Path $PSScriptRoot -Parent)" -Force }

$PSMajVer = $PSVersionTable.PSVersion.Major

Describe "'Add-PSModule' PowerShell $PSMajVer integration test" {

    Context "Strict mode" {

        Set-StrictMode -Version Latest

        # Preparation
        New-Item -ItemType Directory -Path TestDrive:\Test
        $OrigPSModulePath = $env:PSModulePath

        # Function call
        $Output = Add-PSModulePath -Path TestDrive:\Test

        # Tests
        It "should have  updated 'PSModulePath' environment variable" { 
    
            $Output | Should -BeTrue
            $Output.Length | Should -BeGreaterThan $OrigPSModulePath.Length
            $Output -split ";" | Should -Contain TestDrive:\Test
        }

        # Restore variable to original value
        $env:PSModulePath = $OrigPSModulePath
    }
}

Describe "'New-Credential' PowerShell $PSMajVer integration test" {

    Context "Strict mode" {

        Set-StrictMode -Version Latest

        # Preparation
        $EncStr = ConvertTo-SecureString -AsPlainText -Force -String "Test string" | ConvertFrom-SecureString
        New-Item -Path TestDrive:\PasswdFile -ItemType File -Value $EncStr | Out-Null

        # Function call
        $Output = New-Credential -Username $env:USERNAME -EncryptedPasswordFilePath TestDrive:\PasswdFile

        It "should have  created a PowerShell credential object" {

            $Output | Should -BeTrue
            $Output | Should -BeOfType [pscredential]
            $Output.Username | Should -Be $env:USERNAME
        }

        It "should have the provided username on the username property of the object" {

            $Output.Username | Should -BeExactly $env:USERNAME
        }

        It "should have a secure string on the password property of the object" {

            $Output.Password | Should -BeOfType [securestring]
        }
    }
}

if ([bool] ([Environment]::GetCommandLineArgs() -like '-noni*') -eq $false) {

    Describe "'New-EncryptedPasswordFile' PowerShell $PSMajVer integration test" {

        Context "Strict mode" {

            Set-StrictMode -Version Latest

            # Preparation
            Mock Read-Host { 

                $SecStr = [securestring]::new()
                "Test".ToCharArray() | ForEach-Object -Process { $SecStr.AppendChar($PSItem) }
                return $SecStr
            }

            # Function call
            $Output = New-EncryptedPasswordFile -Path TestDrive:\PasswdFile
    
            It "should have created an encrypted password file" {
        
                $Output | Should -BeNullOrEmpty
                Test-Path -Path TestDrive:\PasswdFile -PathType Leaf | Should -BeTrue
                (Get-Item -Path TestDrive:\PasswdFile).Length | Should -BeGreaterThan 0
            }
        }
    }
}
Describe "'Out-LogFile' PowerShell $PSMajVer integration test" {

    Context "Strict mode" {

        Set-StrictMode -Version Latest

        # Preparation
        $FilePath = "TestDrive:\Test.log"
        $InfoEntry = "Test information entry"
        $WarnEntry = "Test warning entry"
        $ErrEntry = "Test error entry"

        # Function call
        $PassThruOutput = Out-LogFile -Path $FilePath -Level Information -Entry $InfoEntry -Passthru
        Out-LogFile -Path $FilePath -Level Information -Entry $InfoEntry
        Out-LogFile -Path $FilePath -Level Warning -Entry $WarnEntry
        Out-LogFile -Path $FilePath -Level Error -Entry $ErrEntry

        It "should create a log file" { Test-Path -Path $FilePath -PathType Leaf }

        It "should write each level in 'Level' parameter set to the log file" {
            
            $FilePath | Should -FileContentMatch "Information: $InfoEntry"
            $FilePath | Should -FileContentMatch "Warning: $WarnEntry"
            $FilePath | Should -FileContentMatch "Error: $ErrEntry"
        }

        It "should write the 'Entry' parameter value to the log file" { 
            
            $FilePath | Should -FileContentMatch $InfoEntry
        }
    
        It "should create a string object containing the 'entry' value when 'Passthru' parameter is specified" {
        
            $PassThruOutput | Should -BeOfType [string]
            $PassThruOutput | Should -BeExactly $InfoEntry
        }

        It "should have a properly formatted log entry" {

            Out-LogFile -Path $FilePath -Level Error -Entry Test
            $FilePath |
            Should -FileContentMatch "^\[[0-2][0-9]:[0-5][0-9]:[0-6][0-9] [0-3]\d-[0-1]\d-\d{2}] Error: Test$"
        }
    }
}

Describe "'Test-RemotePowerShell' PowerShell $PSMajVer integration test" {

    Context "Strict mode" {

        Set-StrictMode -Version Latest

        # Preparation
        $NotARealComp = "google.com"
    
        # Function call
        $NoOutput = Test-RemotePowerShell -Name $env:COMPUTERNAME -WarningAction SilentlyContinue
        $Output = Test-RemotePowerShell -Name $NotARealComp

        It "should not create an object when testing local computer" { $NoOutput | Should -BeNullOrEmpty }

        It "should create a 'AsgGroup.TestRemotePowerShell' PowerShell custom object" {
            
            $Output | Should -BeTrue
            $Output | Should -BeOfType [pscustomobject]
            $Output.PSObject.TypeNames | Should -Contain "AsgGroup.TestRemotePowerShell"
            $Output.ComputerName | Should -BeExactly $NotARealComp
        }
    }
}
