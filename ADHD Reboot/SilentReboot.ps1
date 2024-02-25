# Script version: v3.0
# Date: 10:12 AM 6/11/2023
$ErrorActionPreference = "Stop"
Write-Host "APP STARTED"

# Load necessary assembly for GUI dialog
Add-Type -AssemblyName System.Windows.Forms

# Define a warning dialogue funtion
function ShowDialogue($message)
{
    # Create dialog to show pending shutdown
    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'WARNING'
    $form.Width = 200
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
        
    # Show the dialog
    $form.Show()
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

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Silent Reboot Helper'
$form.Width = 350
$form.Height = 240

# Add a label for the title
$label = New-Object System.Windows.Forms.Label
$label.Text = 'Clicking one of the options below, will cause a reboot.'
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
    TriggerReboot -delayInMinutes $minutes
})

$form.Controls.Add($buttonAccept)

# ROW 2
# Add button to reboot after 10 minutes
$button10Min = New-Object System.Windows.Forms.Button
$button10Min.Location = New-Object System.Drawing.Point(10, 70)
$button10Min.Text = '10 Minutes'
$button10Min.Width = 150
$button10Min.Add_Click({
    TriggerReboot -delayInMinutes 10
})
$form.Controls.Add($button10Min)

# Add button to reboot after 15 minutes
$button15Min= New-Object System.Windows.Forms.Button
$button15Min.Location = New-Object System.Drawing.Point(170, 70)
$button15Min.Text = '15 Minutes'
$button15Min.Width = 150
$button15Min.Add_Click({
    TriggerReboot -delayInMinutes 15
})
$form.Controls.Add($button15Min)

# ROW 3
# Add button to reboot after 20 minutes
$button20Min= New-Object System.Windows.Forms.Button
$button20Min.Location = New-Object System.Drawing.Point(10, 100)
$button20Min.Text = '20 Minutes'
$button20Min.Width = 150
$button20Min.Add_Click({
    TriggerReboot -delayInMinutes 20
})
$form.Controls.Add($button20Min)

# Add button to reboot after 30 minutes
$button30Min= New-Object System.Windows.Forms.Button
$button30Min.Location = New-Object System.Drawing.Point(170, 100)
$button30Min.Text = '30 Minutes'
$button30Min.Width = 150
$button30Min.Add_Click({
    TriggerReboot -delayInMinutes 30
})
$form.Controls.Add($button30Min)

# ROW 4
# Add button to reboot after 45 minutes
$button45Min= New-Object System.Windows.Forms.Button
$button45Min.Location = New-Object System.Drawing.Point(10, 130)
$button45Min.Text = '45 Minutes'
$button45Min.Width = 150
$button45Min.Add_Click({
    TriggerReboot -delayInMinutes 45
})
$form.Controls.Add($button45Min)

# Add button to reboot after 60 minutes
$button60Min= New-Object System.Windows.Forms.Button
$button60Min.Location = New-Object System.Drawing.Point(170, 130)
$button60Min.Text = '1 Hour'
$button60Min.Width = 150
$button60Min.Add_Click({
    TriggerReboot -delayInMinutes 60
})
$form.Controls.Add($button60Min)

# Add Cancel Reboot button
$buttonCancel = New-Object System.Windows.Forms.Button
$buttonCancel.Location = New-Object System.Drawing.Point(10, 160)
$buttonCancel.Text = 'Cancel Reboot'
$buttonCancel.Width = 310
$buttonCancel.Add_Click({
    $global:timer.Stop()
    [System.Windows.Forms.MessageBox]::Show("Reboot Cancelled", "Notification", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
$form.Controls.Add($buttonCancel)

# Show the form

Write-Host "APP SETUP"
$form.ShowDialog()