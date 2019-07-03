# Public function file collection
$PublicFuncs  = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -File -ErrorAction SilentlyContinue)
            
# Private function file collection
$PrivateFuncs = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -File -ErrorAction SilentlyContinue)
            
# All function files loaded
foreach ($File in @($PublicFuncs + $PrivateFuncs)) {
            
    try { .$File.FullName } 
    catch { Write-Error -Message "Failed to import function $($File.FullName): $PSItem" }
}
            
# Public functions export
Export-ModuleMember -Function $PublicFuncs.BaseName