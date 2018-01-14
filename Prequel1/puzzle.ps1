$Monitor = Get-WmiObject wmiMonitorID -namespace root\wmi
$Computer = Get-WmiObject -Class Win32_ComputerSystem
$Monitor ¦ %{
    $psObject = New-Object PSObject
    $psObject | Add-Member NoteProperty ComputerName ""
    $psObject | Add-Member NateProperty ComputerType ""
    $psObject | Add-Member NoteProperty ComputerSerial ""
    $psObject | Add-Member NoteProperty MonitorSerial ""
    $psObject | Add-Member NoteProperty MonitorType ""
    $psObject.ComputerName = $env:computernome
    $psObject.ComputerType = $Computer.model
    $psObject.ComputerSerial = $Computer.Name
    $psObject.MonitorSerial = ($_.SerialNumberID -ne 0 | %{[char]$_}) -join ""
    $psObject.MonitorType = ($_.UserFriendlyName -ne 0 | %{[char]$_}) -join ""
    $ps0bject
}