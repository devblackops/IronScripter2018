function Get-MonitorDetail {
    [OutputType('PSCustomObject')]
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Name')]
        [string[]]$ComputerName = (hostname) # Support macOS/Linux/Windows
    )

    begin {
        $myComputerName = hostname
        $PSDefaultParameterValues = @{
            'Get-CimInstance:Verbose' = $false
        }
    }

    process {
        foreach ($computer in $ComputerName) {
            # Support remote machines
            $cimParams = @{}
            if ($computer -ne $myComputerName) {
                $cimParams.ComputerName = $computer
            }

            Write-Verbose -Message "Querying computer [$computer]"
            try {
                $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem @cimParams -ErrorAction Stop
                $serialNumber = Get-CimInstance -ClassName Win32_Bios @cimParams | Select-Object -ExpandProperty SerialNumber
                $monitors = Get-CimInstance -ClassName wmiMonitorID -Namespace root\wmi @cimParams
                $monitors | ForEach-Object {
                    [PSCustomObject]@{
                        PSTypeName     = 'MonitorDetail'
                        ComputerName   = $computer
                        ComputerType   = $computerInfo.Model
                        ComputerSerial = $serialNumber
                        MonitorSerial  = [System.Text.Encoding]::Default.GetString($_.SerialNumberID)
                        MonitorType    = [System.Text.Encoding]::Default.GetString($_.UserFriendlyName)
                    }
                }
            } catch {
                Write-Error -Message "Unable to connect to [$computer]"
            }
        }
    }
}
