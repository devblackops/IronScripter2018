$objOperatingSystem = Get-WmiObject -Query "SELECT * FROM Win32_OperatingSystem"
Write-Host "OS Name: " $objOperatingSystem.Name
Write-Host "Version: " $objOperatingSystem.Version
Write-Host "Service Pack: " $objOperatingSystem.ServicePackMajorVersion "."
$objOperatingSystem.ServicePackMinorVersion
Write-Host "OS Manufacturer: " $objOperatingSystem.Manufacturer
Write-Host "Windows Directory: " $objOperatingSystem.WindowsDirectory
Write-Host "Locale: " $objOperatingSystem.Locale
Write-Host "Available Physical Memory: " $objOperatingSystem.FreePhysicalMemory
Write-Host "Total Virtual Memory: " $objOperatingSystem.TotalVirtualMemorySize
Write-Host "Available Virtual Memory: " $objOperatingSystem.FreeVirtualMemory
$disks = Get-WmiObject -Query "SELECT * FROM Win32_LogicalDisk"
foreach ($objDisk in $disks) {
 Write-Host "Drive: " $objDisk.DeviceID
 Write-Host "DriveType: " $objDisk.Description
 Write-Host "Size:" $objDisk.Size
 Write-Host "FreeSpace: " $objDisk.FreeSpace
 Write-Host "Compressed:" $objDisk.Compressed
}