# SHUTDOWN SCRIPT to stop all VMs, and then stop the VMMS service process(es)
# If it fails, it will write to a log file, that can be monitored via RMM
# This is a workaround to a well-known bug in Hyper-V Server 2016, Hyper-V Server 2019, and Server 2019 with the Hyper-V role
# Without this workaround, at every reboot the VMs fail to stop and/or the VMMS service fails to stop, and the host locks up, requiring a hard reset



# Prepare the environment
$Error.Clear()
$now = ([DateTime]::Now).ToString()
$failedShutdownLog = "C:\ProgramData\MyOrg\Scripts\Shutdown\FailedVMStop.txt"
$separator = @"

---------------------------------------------------------

"@


# Shut down all of the VMs
$VMs = Get-VM

foreach ($VM in $VMs)
    {
        try
            {
                $Error.Clear()
                Stop-VM -VMName $VM.Name -ErrorAction SilentlyContinue
            } # End try block

        catch
            {
                Write-Host The virtual machine $VM.Name failed to stop!
                If (-Not (Test-Path $failedShutdownLog)) {Out-File $failedShutdownLog -Encoding ascii}
                Add-Content $failedShutdownLog "The virtual machine $VM.Name failed to stop at $now. See error below. `r`n"
                Add-Content $failedShutdownLog $error
                Add-Content $failedShutdownLog $separator
            } # End catch block

    } # End foreach $VM loop


# Shut down the Virtual Machine Management Service (vmms)
$status = (Get-Service VMMS | Select-Object Status).Status
if ($status -eq "Running")
    {
        try
            {
                $Error.Clear()
                Stop-Service VMMS
                if (((Get-Service VMMS | Select-Object Status).Status) -ne "Stopped")
                    {
                        Write-Host The VMMS service failed to stop!
                        If (-Not (Test-Path $failedShutdownLog)) {Out-File $failedShutdownLog -Encoding ascii}
                        Add-Content $failedShutdownLog "The VMMS service failed to stop at $now. See error below. `r`n"
                        Add-Content $failedShutdownLog $error
                        Add-Content $failedShutdownLog $separator
                    } # End if service status -ne "Stopped" block
            } # End try block

        catch
            {
                Write-Host The VMMS service failed to stop!
                If (-Not (Test-Path $failedShutdownLog)) {Out-File $failedShutdownLog -Encoding ascii}
                Add-Content $failedShutdownLog "The VMMS service failed to stop at $now. See error below. `r`n"
                Add-Content $failedShutdownLog $error
                Add-Content $failedShutdownLog $separator
            } # End catch block

    } # End if status -ne "Running" block



# Kill and VMMS processes that may or may not still exist at this point
$Error.Clear()
$Remnants = Get-Process -Name VMMS -ErrorAction SilentlyContinue

if ((!$Remnants -eq $true) -and (!$Error -eq $false))
    {
        # No vmms process exists
        Write-Host No remnant VMMS processes were detected.
        exit
    } # End if block

elseif (!$Remnants -eq $false)
    {
        # Remnant VMMS process exists
        try
            {
                Write-Host Remnant VMMS process(es) were detected!
                $Error.Clear()
                Stop-Process -Name VMMS -Force
            }

        catch
            {
                Write-Host A remnant VMMS process was detected, and cannot be stopped!
                If (-Not (Test-Path $failedShutdownLog)) {Out-File $failedShutdownLog -Encoding ascii}
                Add-Content $failedShutdownLog "Failed to kill a remnant VMMS process at $now. See error below. `r`n"
                Add-Content $failedShutdownLog $error
                Add-Content $failedShutdownLog $separator
            }
    } # End elseif block


# All done
Write-Host Finished running the shutdown script. Exiting...
exit
