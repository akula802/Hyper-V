# Script to set VMs to auto-start with the host
# Assumes domain controllers have 'DC' in the hostname
# First non-DC guest gets a 30-second delay, this increments 15 seconds on each subsequent guest


$VMs = Get-VM
$DelayTimer = 30

ForEach ($VM in $VMs)
    {

        If (($VM.State -eq "Running") -or ($VM.AutomaticStartAction -eq "Start"))
            {
            If ($VM.Name -match "DC")
                {
                    Set-VM -Name $VM.Name -AutomaticStartAction Start -AutomaticStartDelay 0 -AutomaticStopAction ShutDown
                }

            <# ElseIf ($VM.Name -match "OpenDNS")
                {
                    Set-VM -Name $VM.Name -AutomaticStartAction Start -AutomaticStartDelay 0 -AutomaticStopAction Save
                } #>

            Else
                {
                    Set-VM -Name $VM.Name  -AutomaticStartAction Start -AutomaticStartDelay $DelayTimer -AutomaticStopAction ShutDown
                    $Global:DelayTimer += 15
                }

            } # End 'VM state check' IF block

        Else
            {
                Write-Host The $VM.Name VM is currently off or set to not auto-start, assuming it has been retired.

            } # End 'VM state check' ELSE block

    } # End ForEach loop

