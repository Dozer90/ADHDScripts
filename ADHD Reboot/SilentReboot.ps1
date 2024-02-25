# Script version: v2.0
# Date: 9:26 AM, 16/09/2023

# Load necessary assembly for GUI dialog
Add-Type -AssemblyName System.Windows.Forms

# Set delay time in seconds (2100 seconds = 35 minutes)
$delaySeconds = 2100

# Create dialog to show pending shutdown
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Notice'
$form.Width = 200
$form.Height = 100
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle

# Create label for the dialog
$label = New-Object System.Windows.Forms.Label
$label.Text = "Shutting down in $($delaySeconds / 60) minutes"
$label.Width = 150
$label.Height = 30
$label.Location = New-Object System.Drawing.Point(25, 25)

# Add label to form
$form.Controls.Add($label)

# Create timer to close the dialog after 2 seconds
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000  # 2000 milliseconds = 2 seconds
$timer.Add_Tick({ $form.Close() })
$timer.Start()

# Show the dialog
$form.ShowDialog()

# Wait for specified delay time (default 2100 seconds)
Start-Sleep -Seconds $delaySeconds

# Restart the computer forcibly
Restart-Computer -Force
