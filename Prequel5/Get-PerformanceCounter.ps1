
function Get-PerformanceCounter {
    [cmdletbinding(DefaultParameterSetName = 'Computer')]
    param(
        [parameter(
            ParameterSetName = 'Computer',
            ValueFromPipeline = $true
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

    process {
        foreach ($Computer in $ComputerName) {
            try {
                Write-Verbose -Message "Gathering performance counters for [$ComputerName]"

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
                    $cimParams.CimSession = $CimSession
                }

                # Gather disk, memory, processor, and network stats
                $disk = Get-Counter -Counter ('\\{0}\LogicalDisk(c:)\% Free Space'       -f $Computer)
                $mem  = Get-Counter -Counter ('\\{0}\Memory\% Committed Bytes In Use'    -f $Computer)
                $proc = Get-Counter -Counter ('\\{0}\Processor(_Total)\% Processor Time' -f $Computer)
                $netCounters = Get-NetAdapter -Physical @cimParams | ForEach-Object {
                    $label = $_.InterfaceDescription.Replace('#', '_')
                    "\Network Adapter($label)\Bytes Total/sec"
                }
                $net = Get-Counter -Counter $netCounters
                $totalNetBytes = ($net.CounterSamples |
                    Sort-Object -Property CookedValue -Descending |
                    Select-Object -First 2 |
                    Measure-Object -Property CookedValue -Sum).Sum

                [pscustomobject]@{
                    ComputerName       = $Computer
                    Timestamp          = Get-Date
                    PctProcessorTime   = "{0:n2}" -f $proc.CounterSamples.CookedValue
                    PctFreeSpaceC      = "{0:n2}" -f $disk.CounterSamples.CookedValue
                    PctCommittedBytes  = "{0:n2}" -f $mem.CounterSamples.CookedValue
                    NetworkBytesPerSec = "{0:n2}" -f $totalNetBytes
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
}
