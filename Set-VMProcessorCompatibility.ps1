# Script to set CPU migration compatibility in a clustered environment
# Just in case someone created new VMs and missed this
# This is a shotgun approach, could be filtered to target only VMs that need it

$VMs = Get-VM

foreach ($vm in $VMs)
    {
        Stop-VM
        Set-VMProcessor -VMName $vm.VMName -CompatibilityForMigrationEnabled $true
        Start-VM
    }

