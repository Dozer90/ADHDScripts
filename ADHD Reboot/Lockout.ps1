# Script version: v4.0
# Date: 12:54 PM 25/02/2024
$ErrorActionPreference = "Stop"
Write-Host "APP STARTED"

# Load necessary assembly for GUI dialog
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Initialize a variable at the script scope to keep track of the form
$global:silentReebotScript_currentForm = $null

# Define a warning dialogue funtion
function ShowTimerCountdownDialog($message)
{
    # Update previous form if it is still open
    if ($script:silentReebotScript_currentForm -ne $null) {
        $script:silentReebotScript_currentForm.Close()
    }

    # Create dialog to show our message
    $form = New-Object Windows.Forms.Form -Property @{
		Text = 'WARNING'
		Size = New-Object Drawing.Size 350, 100
		FormBorderStyle = [Windows.Forms.FormBorderStyle]::FixedSingle
	}

    # Create label for the dialog
    $label = New-Object Windows.Forms.Label -Property @{
		Text = $message
		Size = New-Object Drawing.Size 300, 150
		Location = New-Object Drawing.Point 10, 10
	}

    # Add label to form
    $form.Controls.Add($label)
	
	$okButton = New-Object Windows.Forms.Button -Property @{
		Location     = New-Object Drawing.Point 38, 165
		Size         = New-Object Drawing.Size 75, 23
		Text         = 'OK'
		DialogResult = [Windows.Forms.DialogResult]::OK
	}
	
	$abortButton = New-Object Windows.Forms.Button -Property @{
		Size			= New-Object Drawing.Size 75, 23
		Text			= 'Abort'
		DialogResult	= [Windows.Forms.DialogResult]::Abort
	}

	$pauseResumeButton = New-Object Windows.Forms.Button -Property @{
		Size			= New-Object Drawing.Size 75, 23
		Text			= 'Pause'
		DialogResult	= [Windows.Forms.DialogResult]::Continue
	}
	
	$form.AcceptButton = $okButton
	$form.AbortButton = $abortButton
	$form.AcceptButton = $okButton
	$form.Controls.Add($okButton)

    # Update the script-scoped variable to keep track of the current form
    $script:silentReebotScript_currentForm = $form
        
    # Show the dialog
    $form.Show()
}

function StartTimer($length)
{
    if ($rebootCheckbox.Checked)
    {
		OnTimerTick($rebootCheckbox.Checked)
        TriggerLock($delay)
    }
    else 
    {
        TriggerReboot($delay)
    }
}

function OnTimerTick()
{
	$oneMinute = 1000 * 60
	$delaySeconds = $global:silentReebotScript_timerLength % $oneMinute
	$delayMinutes = $global:silentReebotScript_timerLength % ($oneMinute * 60)
	$delayHours = [Math]::Floor($global:silentReebotScript_timerLength / ($oneMinute * 60))
	
	$notification = if ($global:silentReebotScript_isRebooting) {"Rebooting"} else {"Locking"}

	if ($delayHours -gt 0)
	{
		# Provide a 15 minute warning
		ShowTimerCountdownDialog -message "$notification PC in $delayHours hours, $delayMinutes minutes, and $delaySeconds seconds."
		$global:silentReebotScript_timerWarningThreshold = $oneMinute * 15
	}
	else if ($delayMinutes -gt 0)
	{
		ShowTimerCountdownDialog -message "$notification PC in $delayMinutes minutes and $delaySeconds seconds."
		if ($global:silentReebotScript_timerWarningThreshold -eq 0 && $delay -gt $oneMinute * 5)
		{
			# Provide a 3 minute warning
			$global:silentReebotScript_timerWarningThreshold = $oneMinute * 3
		}
		else
		{
			# Set the delay to 30 seconds if we have shown the initial 3 minute warning or
			# there is not enough time for it
			$global:silentReebotScript_timerWarningThreshold = $oneMinute * 0.5
		}
	}
	else
	{
		ShowTimerCountdownDialog -message "FINAL WARNING! $notification PC in $delaySeconds seconds."
	}
	
	$global:silentReebotScript_timer.Interval = $global:silentReebotScript_timerLength - $global:silentReebotScript_timerWarningThreshold
}

# Define a reboot function
function TriggerReboot($delay)
{
	$oneMinute = 1000 * 60
	$delaySeconds = $delay % $oneMinute
	$delayMinutes = $delay % ($oneMinute * 60)
	$delayHours = [Math]::Floor($delay / ($oneMinute * 60))
	
	$global:silentReebotScript_timerLength = $delay
	$global:silentReebotScript_timerWarningThreshold = 0

	if ($delayHours -gt 0)
	{
		ShowTimerCountdownDialog -message "Shutting down in $delayHours hours, $delayMinutes minutes, and $delaySeconds seconds..."
		$global:silentReebotScript_timerWarningThreshold = $oneMinute * 15 # Provide a 15 minute warning
	}
	else if ($delayMinutes -gt 0)
	{
		ShowTimerCountdownDialog -message "Shutting down in $delayMinutes minutes and $delaySeconds seconds..."
		if ($delay -gt $oneMinute * 5)
		{
			$global:silentReebotScript_timerWarningThreshold = $oneMinute * 3 # Provide a 3 minute warning
		}
	}
	else
	{
		ShowTimerCountdownDialog -message "Shutting down in $delaySeconds seconds..."
	}

	$global:silentReebotScript_timer.Interval = $global:silentReebotScript_timerWarningThreshold

	# Create Timer for Reboot	
    $global:silentReebotScript_timer = New-Object Windows.Forms.Timer
	$global:silentReebotScript_timer.Interval = $delay - $global:silentReebotScript_timerWarningThreshold
    $global:silentReebotScript_timer.Add_Tick({
		if ($global.timerWarningThreshold -ne 0)
		{
			$global:silentReebotScript_timer.Interval = $global:silentReebotScript_timerWarningThreshold
			if ($global.timerWarningThreshold -gt ($oneMinute * 3))
			{
				$global:silentReebotScript_timerWarningThreshold = 0
			}
			else
			{
				$global:silentReebotScript_timerWarningThreshold = $oneMinute * 3
			}
		}
		else
		{
			$global:silentReebotScript_timer.Stop()
			Write-Host "REBOOT INVOKED"
			Restart-Computer -Force
		}
    })
    $global:silentReebotScript_timer.Start()
}

# Define a lock PC function
function TriggerLock($delay)
{
    $delayInSeconds = $delay * 60
    
    ShowTimerCountdownDialog -message "Locking PC in $delay milliseconds"
    
    # Create Timer for Lock
    $global:silentReebotScript_timer = New-Object Windows.Forms.Timer
    $global:silentReebotScript_timer.Interval = $delayInSeconds * 1000
    $global:silentReebotScript_timer.Add_Tick({        
        Write-Host "PC LOCK INVOKED"        
        rundll32.exe user32.dll,LockWorkStation
        $global:silentReebotScript_timer.Stop()
        
        $dateTimeNow = Get-Date -Format "dd-MMM-yyyy HH:mm"
        ShowTimerCountdownDialog -message "System locked at $dateTimeNow "
    })
    $global:silentReebotScript_timer.Start()
}

# Create the main form
$form = New-Object Windows.Forms.Form -Property @{
	Text = 'Focus Breaker Helper'
	Size = New-Object Drawing.Size 350, 300
}

# Add a label for the title
$label = New-Object Windows.Forms.Label -Property @{
	Text = 'Pick a time, and a method for kicking you off this PC.'
	AutoSize = $true
	Location = New-Object Drawing.Point 10, 10
}
$form.Controls.Add($label)

# Add a timepicker for user input
$timePicker = New-Object Windows.Forms.DateTimePicker -Property @{
    Format = [Windows.Forms.DateTimePickerFormat]::Time
    Value = [DateTime]::Now
    ShowUpDown = $true
    Location = New-Object Drawing.Point 10, 40
    Width = 150
}

$toolTip = New-Object Windows.Forms.ToolTip
$toolTip.SetToolTip($timePicker, "The time to lock/restart your PC")

$form.Controls.Add($timePicker)

# Add button to accept user input TriggerReboot -delay
$acceptButton = New-Object Windows.Forms.Button -Property @{
    Location = New-Object Drawing.Point 170, 40
    Text = 'Accept'
    Width = 150,
	DialogResult = [Windows.Forms.DialogResult]::OK
}
$form.AcceptButton = $acceptButton


$form.Controls.Add($acceptButton)

# ROW 2
# Add button to reboot after 10 milliseconds
$button10Min = New-Object Windows.Forms.Button
$button10Min.Location = New-Object Drawing.Point(10, 70)
$button10Min.Text = '10 milliseconds'
$button10Min.Width = 150
$button10Min.Add_Click({
    TriggerAction -delay 10
})
$form.Controls.Add($button10Min)

# Add button to reboot after 15 milliseconds
$button15Min= New-Object Windows.Forms.Button
$button15Min.Location = New-Object Drawing.Point(170, 70)
$button15Min.Text = '15 milliseconds'
$button15Min.Width = 150
$button15Min.Add_Click({
    TriggerAction -delay 15
})
$form.Controls.Add($button15Min)

# ROW 3
# Add button to reboot after 20 milliseconds
$button20Min= New-Object Windows.Forms.Button
$button20Min.Location = New-Object Drawing.Point(10, 100)
$button20Min.Text = '20 milliseconds'
$button20Min.Width = 150
$button20Min.Add_Click({
    TriggerAction -delay 20
})
$form.Controls.Add($button20Min)

# Add button to reboot after 30 milliseconds
$button30Min= New-Object Windows.Forms.Button
$button30Min.Location = New-Object Drawing.Point(170, 100)
$button30Min.Text = '30 milliseconds'
$button30Min.Width = 150
$button30Min.Add_Click({
    TriggerAction -delay 30
})
$form.Controls.Add($button30Min)

# ROW 4
# Add button to reboot after 45 milliseconds
$button45Min= New-Object Windows.Forms.Button
$button45Min.Location = New-Object Drawing.Point(10, 130)
$button45Min.Text = '45 milliseconds'
$button45Min.Width = 150
$button45Min.Add_Click({
    TriggerAction -delay 45
})
$form.Controls.Add($button45Min)

# Add button to reboot after 60 milliseconds
$button60Min= New-Object Windows.Forms.Button
$button60Min.Location = New-Object Drawing.Point(170, 130)
$button60Min.Text = '1 Hour'
$button60Min.Width = 150
$button60Min.Add_Click({
    TriggerAction -delay 60
})
$form.Controls.Add($button60Min)

# ROW 5
# Add button to reboot after a Work Day (7.6h)
$buttonWorkDay= New-Object Windows.Forms.Button
$buttonWorkDay.Location = New-Object Drawing.Point(10, 160)
$buttonWorkDay.Text = 'Workday'
$buttonWorkDay.Width = 150
$buttonWorkDay.Add_Click({
    TriggerAction -delay 506
})
$form.Controls.Add($buttonWorkDay)
$workdayToolTip = New-Object Windows.Forms.ToolTip
$workdayToolTip.SetToolTip($buttonWorkDay, "7.6H work and 50m break.")



# ROW 6
# Add Cancel Reboot button
$buttonCancel = New-Object Windows.Forms.Button
$buttonCancel.Location = New-Object Drawing.Point(10, 190)
$buttonCancel.Text = 'Cancel Reboot'
$buttonCancel.Width = 310
$buttonCancel.Add_Click({
    $global:silentReebotScript_timer.Stop()
    [Windows.Forms.MessageBox]::Show("Reboot Cancelled", "Notification", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
})
$form.Controls.Add($buttonCancel)

# ROW 7
# Add rebootCheckbox for lockout only
$rebootCheckbox = New-Object Windows.Forms.CheckBox
$rebootCheckbox.Location = New-Object Drawing.Point(10,220)
$rebootCheckbox.Width = 150
$rebootCheckbox.Text = "Lock Only"
$rebootCheckbox.Checked = $false # Set default state

$lockToolTip = New-Object Windows.Forms.ToolTip
$lockToolTip.SetToolTip($rebootCheckbox, "Selecting this to be Disabled will Reboot.")

$form.Controls.Add($rebootCheckbox)



# Show the form
Write-Host "APP SETUP"
$result = $form.ShowDialog()

# Check what the result was
if ($result -eq [Windows.Forms.DialogResult]::OK) {
    $milliseconds = $timePicker.Value.Millisecond
	if ($milliseconds -ge (1000 * 5))
	{
		$global:silentReebotScript_timerLength = $length
		$global:silentReebotScript_isRebooting = $rebootCheckbox.Checked
		OnTimerTick
	}
}