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
    .PARAMETER CimSession
    One or more existing CIM sessions to use.
    .EXAMPLE
    C:\> Get-ComputerInformation
    Query the local computer for OS and logical disk information
    .EXAMPLE
    C:\> Get-ComputerInformation -ComputerName server01
    Query the remote computer [server01] for OS and disk information.
    .EXAMPLE
    C:\> Get-ComputerInformation -ComputerName server01 -Credential domain\user
    Query the remote computer [server01] for OS and disk information using the supplied credential.
    .EXAMPLE
    C:\> $cim = New-CimSession -ComputerName 'ush-p-ms-util1' -Credential domain\user
    C:\> $cim | Get-ComputerInformation
    Establish a new CIM session and use it to query remote machine.
    .LINK
    http://ironscripter.us/
    #>
    [OutputType('ComputerInformation')]
    [cmdletbinding(DefaultParameterSetName = 'Computer')]
    param(
        [parameter(
            ParameterSetName = 'Computer',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [parameter(
            ParameterSetName = 'Computer'
        )]
        [System.Management.Automation.CredentialAttribute()]
        [pscredential]$Credential,

        [parameter(
            ParameterSetName = 'CimSession',
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [Microsoft.Management.Infrastructure.CimSession[]]$CimSession
    )

    begin {
        $PSDefaultParameterValues = @{
            'Get-CimInstance:Verbose'     = $false
            'Get-CimInstance:ErrorAction' = 'Stop'
        }

        function GetMachineDetail {
            [cmdletbinding()]
            param(
                [parameter(
                    Mandatory = $true,
                    ParameterSetName = 'Computer'
                )]
                [string]$Computer,

                [parameter(
                    ParameterSetName = 'Computer'
                )]
                [pscredential]$Credential,

                [parameter(
                    Mandatory = $true,
                    ParameterSetName = 'CIM'
                )]
                [Microsoft.Management.Infrastructure.CimSession]$Session
            )

            $name = if ($Computer) { $Computer } else { $Session.ComputerName }
            Write-Verbose -Message "Querying computer [$name]"

            try {
                # Support remote machines with optional credential
                $cimParams = @{}
                if ($PSCmdlet.ParameterSetName -eq 'Computer') {
                    if ($Computer -ne $env:COMPUTERNAME) {
                        if ($Credential) {
                            $cimParams.CimSession = New-CimSession -ComputerName $Computer -Credential $Credential
                        } else {
                            $cimParams.ComputerName = $Computer
                        }
                    }
                } else {
                    $cimParams.CimSession = $Session
                }

                # Gather OS and disk information
                $os = Get-CimInstance -ClassName Win32_OperatingSystem @cimParams
                $logicalDisks = foreach ($disk in (Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType = 3' @cimParams -ErrorAction Continue)) {
                    if (($null -ne $disk.Size) -and ($disk.Size -ne 0)) {
                        $pctUsed = 100 - [System.Math]::Round(($disk.FreeSpace / $disk.Size) * 100, 2)
                    } else {
                        $pctUsed = $null
                    }
                    [pscustomobject][ordered]@{
                        PSTypeName  = 'LogicalDiskInfo'
                        Drive       = $disk.DeviceId
                        DriveType   = $disk.Description
                        Size        = $disk.Size
                        FreeSpace   = $disk.FreeSpace
                        PercentUsed = $pctUsed
                        Compressed  = $disk.Compressed
                    }
                }
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
                    LogicalDisks        = $logicalDisks
                }
            } catch {
                Write-Error $_
            } finally {
                # Don't remove the existing CIM session that was passed in
                # It still may be needed upstream
                if ($PSCmdlet.ParameterSetName -eq 'Computer' -and $cimParams.CimSession) {
                    $cimParams.CimSession | Remove-CimSession
                }
            }
        }
    }

    process {
        # Support <N> computers OR <N> CIM Sessions
        switch ($PSCmdlet.ParameterSetName) {
            'Computer' {
                foreach ($computer in $ComputerName) {
                    GetMachineDetail -Computer $computer -Credential $Credential
                }
                break
            }
            'CimSession' {
                foreach ($session in $CimSession) {
                    GetMachineDetail -Session $session
                }
                break
            }
        }
    }
}