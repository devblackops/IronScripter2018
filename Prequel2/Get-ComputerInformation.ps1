function Get-ComputerInformation {
    <#
    .SYNOPSIS
    Gather operating system and logical disk information.
    .DESCRIPTION
    Gather operating system and logical disk capacity information from local or remote computers.
    .PARAMETER ComputerName
    The computer name to query.
    .PARAMETER Credential
    Optional credential used to authenticate to remote computer.
    .EXAMPLE
    C:\> Get-ComputerInformation

    Query the local computer for OS and logical disk information
    .EXAMPLE
    C:\> Get-ComputerInformation -ComputerName server01

    Query the remote computer [server01] for OS and disk information.
    .EXAMPLE
    C:\> Get-ComputerInformation -ComputerName server01 -Credential domain\user

    Query the remote computer [server01] for OS and disk information using the supplied credential.
    .LINK
    http://ironscripter.us/
    #>
    [OutputType('ComputerInformation')]
    [cmdletbinding()]
    param(
        [parameter(
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [System.Management.Automation.CredentialAttribute()]
        [pscredential]$Credential
    )

    begin {
        $PSDefaultParameterValues = @{
            'Get-CimInstance:Verbose'     = $false
            'Get-CimInstance:ErrorAction' = 'Stop'
        }
    }

    process {
        foreach ($computer in $ComputerName) {
            Write-Verbose -Message "Querying computer [$computer]"

            try {
                # Support remote machines with optional credential
                $cimParams = @{}
                if ($computer -ne $env:COMPUTERNAME) {
                    $cimParams.ComputerName = $computer
                    if ($Credential) {
                        $cimParams.CimSession = New-CimSession -ComputerName $computer -Credential $Credential
                    }
                }

                # Gather OS and disk information
                $os = Get-CimInstance -ClassName Win32_OperatingSystem @cimParams
                [pscustomobject][ordered]@{
                    PSTypeName          = 'ComputerInformation'
                    ComputerName        = $os.CSName
                    OSName              = $os.Caption
                    Version             = [System.Version]$os.Version
                    ServicePack         = $os.ServicePackMajorVersion, $os.ServicePackMinorVersion -join '.'
                    OSManufacturer      = $os.Manufacturer
                    WindowsDirectory    = $os.WindowsDirectory
                    Locale              = ([System.Globalization.CultureInfo]([int]("0x$($os.Locale)"))).Name
                    TotalPhysicalMemory = $os.TotalVisibleMemorySize
                    FreePhysicalMemory  = $os.FreePhysicalMemory
                    TotalVirtualMemory  = $os.TotalVirtualMemorySize
                    FreeVirtualMemory   = $os.FreeVirtualMemory
                    LogicalDisks        = foreach ($disk in (Get-CimInstance -ClassName Win32_LogicalDisk @cimParams -ErrorAction Continue)) {
                        [pscustomobject][ordered]@{
                            PSTypeName  = 'LogicalDiskInfo'
                            Drive       = $disk.DeviceId
                            DriveType   = $disk.Description
                            Size        = $disk.Size
                            FreeSpace   = $disk.FreeSpace
                            PercentUsed = 100 - [System.Math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 2)
                            Compressed  = $disk.Compressed
                        }
                    }
                }
            } catch {
                Write-Error -Message "Unable to connect to [$computer]"
            } finally {
                if ($cimParams.CimSession) {
                    $cimParams.CimSession | Remove-CimSession
                }
            }
        }
    }
}
