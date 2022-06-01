# Script that checks replication status in a Hyper-V Replica environment
# Intended to run as a scheduled task on the host serving as primary for the majority of VMs
# If replication problems are detected, and alert is posted via email using SendGrid (could be a Slack channel, email-to-ticket, etc)



# The function that does the emailing
Function Send-Alert() {
    [CmdletBinding()]
    Param(
        #[stirng]$To,
        #[string]$From,
        [String]$Subject,
        [string]$Body
    ) # End param

    # Do the things
    Try
        {
            $Error.Clear()

            # Define the credential object
            $username = "YoUr-SeNdGrId-UsEr"
            $password = ConvertTo-SecureString 'yOuR-SeNdGrId-aPi-KeY-GoEs-HeRe' -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential($username, $password)

            # Define the message
            $alertRecipient = 'alert-to-address@yourdomain.com'
            $alertFrom = 'rdhq-hvreplica-alerts@your-domain.com'
            $subjectLine = $subject
            $MsgBody = $body

            # Send the message
            Send-MailMessage -To $alertRecipient -From $alertFrom -Subject $subjectLine -Body $MsgBody -SmtpServer "smtp.sendgrid.net" -Port 587 -Credential $credential -UseSSL

            # State the obvious
            Write-Host Alert was posted to Slack.
            return
        }

    Catch
        {
            Write-Host Something bad happened trying to post the alert.
            Write-Host $Error
            return
        }


} # End function Send-Alert



# Get all of the replicated VMs and their replication information
$replicatedServers = Get-VMReplication



# Loop through the replicated VMs and check on their replication health
# Post an alert to Slack if health != "Normal"
ForEach ($server in $replicatedServers) 
    {
        if (($server.ReplicationHealth -ne "Normal") -and (($server.ReplicationState -ne "Replicating") -or ($server.ReplicationState -ne "Resynchronizing")))
            {
                # Build the alert parameters
                $msgSub = Write-Host Hyper-V Replication for $server.VMName is $server.ReplicationHealth 6>&1
                $msgBody = Write-Host $server.VMName is in a $server.ReplicationState state, and has not replicated since $server.LastReplicationTime 6>&1

                # Send the alert to Slack
                Send-Alert -Subject $msgSub -Body $msgBody

                # Post to console and move on
                Write-Host Sent alert for $server.VMName being in a $server.RepliationHealth state.

            }
            
        else
            {
                # Nothing to do
                Write-Host Hyper-V Replication is healthy for $server.VMname
            }

    } # End Foreach
