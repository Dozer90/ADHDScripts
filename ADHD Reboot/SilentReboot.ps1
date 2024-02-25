# Script version: v4.0
# Date: 12:54 PM 25/02/2024
$ErrorActionPreference = "Stop"
Write-Host "APP STARTED"

# Load necessary assembly for GUI dialog
Add-Type -AssemblyName System.Windows.Forms

# Initialize a variable at the script scope to keep track of the form
$script:currentForm = $null

# Define a warning dialogue funtion
function ShowDialogue($message)
{
    # Close previous form if it is still open
    if ($null -ne $script:currentForm) {
        $script:currentForm.Close()
    }

    # Create dialog to show our message
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'WARNING'
    $form.Width = 350
    $form.Height = 100
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle

    # Create label for the dialog
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $message
    $label.Width = 300
    $label.Height = 150
    $label.Location = New-Object System.Drawing.Point(10, 10)

    # Add label to form
    $form.Controls.Add($label)

    # Update the script-scoped variable to keep track of the current form
    $script:currentForm = $form
        
    # Show the dialog
    $form.Show()
}

function TriggerAction($delayInMinutes)
{
    if ($checkbox.Checked)
    {
        TriggerLock($delayInMinutes)
    }
    else 
    {
        TriggerReboot($delayInMinutes)
    }
}

# Define a reboot function
function TriggerReboot($delayInMinutes)
{
    $delayInSeconds = $delayInMinutes * 60
    
    ShowDialogue -message "Shutting down in $delayInMinutes minutes"
    
    # Create Timer for Reboot
    $global:timer = New-Object System.Windows.Forms.Timer
    $global:timer.Interval = $delayInSeconds * 1000
    $global:timer.Add_Tick({        
        Write-Host "REBOOT INVOKED"
        Restart-Computer -Force
    })
    $global:timer.Start()
}

# Define a lock PC function
function TriggerLock($delayInMinutes)
{
    $delayInSeconds = $delayInMinutes * 60
    
    ShowDialogue -message "Locking PC in $delayInMinutes minutes"
    
    # Create Timer for Lock
    $global:timer = New-Object System.Windows.Forms.Timer
    $global:timer.Interval = $delayInSeconds * 1000
    $global:timer.Add_Tick({        
        Write-Host "PC LOCK INVOKED"        
        rundll32.exe user32.dll,LockWorkStation
        $global:timer.Stop()
        
        $dateTimeNow = Get-Date -Format "dd-MMM-yyyy HH:mm"
        ShowDialogue -message "System locked at $dateTimeNow "
    })
    $global:timer.Start()
}

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Focus Breaker Helper'
$form.Width = 350
$form.Height = 300

# Add a label for the title
$label = New-Object System.Windows.Forms.Label
$label.Text = 'Pick a time, and a method for kicking you off this PC.'
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10, 10)
$form.Controls.Add($label)

# Add a textbox for user input
$textbox = New-Object System.Windows.Forms.TextBox
$textbox.Location = New-Object System.Drawing.Point(10, 40)
$textbox.Width = 150

$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.SetToolTip($textbox, "Minutes as a whole number")

$form.Controls.Add($textbox)

# Add button to accept user input TriggerReboot -delayInMinutes
$buttonAccept = New-Object System.Windows.Forms.Button
$buttonAccept.Location = New-Object System.Drawing.Point(170, 40)
$buttonAccept.Text = 'Accept'
$buttonAccept.Width = 150
$buttonAccept.Add_Click({
    $minutes = [int]$textbox.Text
    TriggerAction -delayInMinutes $minutes
})

$form.Controls.Add($buttonAccept)

# ROW 2
# Add button to reboot after 10 minutes
$button10Min = New-Object System.Windows.Forms.Button
$button10Min.Location = New-Object System.Drawing.Point(10, 70)
$button10Min.Text = '10 Minutes'
$button10Min.Width = 150
$button10Min.Add_Click({
    TriggerAction -delayInMinutes 10
})
$form.Controls.Add($button10Min)

# Add button to reboot after 15 minutes
$button15Min= New-Object System.Windows.Forms.Button
$button15Min.Location = New-Object System.Drawing.Point(170, 70)
$button15Min.Text = '15 Minutes'
$button15Min.Width = 150
$button15Min.Add_Click({
    TriggerAction -delayInMinutes 15
})
$form.Controls.Add($button15Min)

# ROW 3
# Add button to reboot after 20 minutes
$button20Min= New-Object System.Windows.Forms.Button
$button20Min.Location = New-Object System.Drawing.Point(10, 100)
$button20Min.Text = '20 Minutes'
$button20Min.Width = 150
$button20Min.Add_Click({
    TriggerAction -delayInMinutes 20
})
$form.Controls.Add($button20Min)

# Add button to reboot after 30 minutes
$button30Min= New-Object System.Windows.Forms.Button
$button30Min.Location = New-Object System.Drawing.Point(170, 100)
$button30Min.Text = '30 Minutes'
$button30Min.Width = 150
$button30Min.Add_Click({
    TriggerAction -delayInMinutes 30
})
$form.Controls.Add($button30Min)

# ROW 4
# Add button to reboot after 45 minutes
$button45Min= New-Object System.Windows.Forms.Button
$button45Min.Location = New-Object System.Drawing.Point(10, 130)
$button45Min.Text = '45 Minutes'
$button45Min.Width = 150
$button45Min.Add_Click({
    TriggerAction -delayInMinutes 45
})
$form.Controls.Add($button45Min)

# Add button to reboot after 60 minutes
$button60Min= New-Object System.Windows.Forms.Button
$button60Min.Location = New-Object System.Drawing.Point(170, 130)
$button60Min.Text = '1 Hour'
$button60Min.Width = 150
$button60Min.Add_Click({
    TriggerAction -delayInMinutes 60
})
$form.Controls.Add($button60Min)

# ROW 5
# Add button to reboot after a Work Day (7.6h)
$buttonWorkDay= New-Object System.Windows.Forms.Button
$buttonWorkDay.Location = New-Object System.Drawing.Point(10, 160)
$buttonWorkDay.Text = 'Workday'
$buttonWorkDay.Width = 150
$buttonWorkDay.Add_Click({
    TriggerAction -delayInMinutes 506
})
$form.Controls.Add($buttonWorkDay)
$workdayToolTip = New-Object System.Windows.Forms.ToolTip
$workdayToolTip.SetToolTip($buttonWorkDay, "7.6H work and 50m break.")



# ROW 6
# Add Cancel Reboot button
$buttonCancel = New-Object System.Windows.Forms.Button
$buttonCancel.Location = New-Object System.Drawing.Point(10, 190)
$buttonCancel.Text = 'Cancel Reboot'
$buttonCancel.Width = 310
$buttonCancel.Add_Click({
    $global:timer.Stop()
    [System.Windows.Forms.MessageBox]::Show("Reboot Cancelled", "Notification", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
$form.Controls.Add($buttonCancel)

# ROW 7
# Add checkbox for lockout only
$checkbox = New-Object System.Windows.Forms.CheckBox
$checkbox.Location = New-Object System.Drawing.Point(10,220)
$checkbox.Width = 150
$checkbox.Text = "Lock Only"
$checkbox.Checked = $false # Set default state

$lockToolTip = New-Object System.Windows.Forms.ToolTip
$lockToolTip.SetToolTip($checkbox, "Selecting this to be Disabled will Reboot.")

$form.Controls.Add($checkbox)

# Show the form

Write-Host "APP SETUP"
$form.ShowDialog()