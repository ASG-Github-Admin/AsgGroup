# Custom exception class for registry export unsuccessful (reg.exe)
class RegistryExportException : System.Exception {
            
    RegistryExportException ([string] $Message) : base($Message) { }      
    RegistryExportException () { }
}