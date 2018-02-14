
function Get-PerformanceCounter {
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    process {
        foreach ($Computer in $ComputerName) {
            Write-Verbose -Message "Gathering performance counters for [$ComputerName]"

            # Gather disk, memory, processor, and network stats
            $counters = @(
                '\\{0}\LogicalDisk(c:)\% Free Space'       -f $Computer
                '\\{0}\Memory\% Committed Bytes In Use'    -f $Computer
                '\\{0}\Processor(_Total)\% Processor Time' -f $Computer
            )
            $disk = Get-Counter -Counter $counters[0]
            $mem  = Get-Counter -Counter $counters[1]
            $proc = Get-Counter -Counter $counters[2]
            $netCounters = Get-NetAdapter -Physical | ForEach-Object {
                $label = $_.InterfaceDescription.Replace('#', '_')
                "\Network Adapter($label)\Bytes Total/sec"
            }
            $net  = Get-Counter -Counter $netCounters
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
        }
    }
}
