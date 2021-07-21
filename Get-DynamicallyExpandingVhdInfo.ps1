# Get all dynamically-expanding VHD/X files on a host
# Use this to ensure your expansion limits do not exceed physical storage capacity
# Credit: https://365lab.net/2014/01/11/analyze-your-vhdx-usage-with-powershell/


function Get-DynamicVHDStat {
param(
[Parameter(Mandatory=$false)]
[string]
$Cluster
)

$totalRoomToExpand = 0
 
if ($Cluster) {
    $VMs = Get-ClusterGroup -Cluster $cluster | Where-Object grouptype -eq 'virtualmachine' | Get-VM
} else {
    $VMs = Get-VM
}
    foreach ($VM in $VMs){
        $VHDs = Get-VHD -Path $vm.harddrives.path -ComputerName $vm.computername -ErrorAction SilentlyContinue | Where-Object {$_.VhdType -eq "Dynamic"} # -or $_.VhdType -eq "Differencing"}
            foreach ($VHD in $VHDs) {

                $global:totalRoomToExpand += [math]::Round($VHD.Size/1GB - $VHD.FileSize/1GB, 1)

                $stats = [PSCustomObject]@{
                    Name = $VM.name
                    Type = $VHD.VhdType
                    Path = $VHD.Path
                    'VHDMaxSize(GB)' = [math]::Round($VHD.Size/1GB, 1)
                    'VHDCurrentSize(GB)' = [math]::Round($VHD.FileSize/1GB, 1)
                    'RoomToExpand(GB)' =  [math]::Round($VHD.Size/1GB - $VHD.FileSize/1GB, 1)
                 }

                 Write-Host $stats
            }
    }
}

$totalRoomToExpandTxt = "`r`nTotal expansion potential: $global:totalRoomToExpand GB"

$DesktopPath = [Environment]::GetFolderPath("Desktop")
Get-DynamicVHDStat | Out-File $DesktopPath\dynamic-vhds.txt -Encoding utf8
$totalRoomToExpandTxt | Out-File $DesktopPath\dynamic-vhds.txt -Encoding utf8 -Append
