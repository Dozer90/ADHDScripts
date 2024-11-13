# Script version: v4.0
# Date: 12:54 PM 25/02/2024
$ErrorActionPreference = "Stop"
Write-Host "APP STARTED"
Set-PSDebug -Trace 2

# Load necessary assembly for GUI dialog
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# The actions that can be performed when the timer completes
Add-Type -TypeDefinition @"
public enum TimerAction {
    Undefined,
    Message,
    SignOut,
    Lock,
    Reboot,
    Shutdown
}
"@

function Get-EnumFromComboBox {
    params ([string]$comboValue)

    switch ($comboValue) {
        "Display a message"     { return [TimerAction]::Message }
        "Log user out"          { return [TimerAction]::SignOut }
        "Lock PC"               { return [TimerAction]::Lock }
        "Reboot PC"             { return [TimerAction]::Reboot }
        "Shutdown PC"           { return [TimerAction]::Shutdown }
    }
    return [TimerAction]::Undefined
}

function Get-TimerActionAsString {
    param (
        [TimerAction]$action,
        [switch]$nsp
    )

    switch ($action) {
        [TimerAction]::Message    { return "Message" }
        [TimerAction]::SignOut    { return if ($nsp) {"SignOut"} else {"Sign Out"} }
        [TimerAction]::Lock       { return "Lock" }
        [TimerAction]::Reboot     { return "Reboot" }
        [TimerAction]::Shutdown   { return "Shutdown" }
    }
    return "Unknown"
}

function Get-TimerActionDesc {
    param (
        [TimerAction]$action
    )

    switch ($action) {
        [TimerAction]::Message    { return "Message displaying" }
        [TimerAction]::SignOut    { return "Signing user out" }
        [TimerAction]::Lock       { return "Locking PC" }
        [TimerAction]::Reboot     { return "Rebooting PC" }
        [TimerAction]::Shutdown   { return "Shutting down PC" }
    }
    return "Unknown"
}

#==================================================
# Time picker form
$chooseTimeForm = New-Object System.Windows.Forms.Form -Property @{
    Text                = 'Focus Breaker'
    Size                = New-Object Drawing.Size(400, 120)
    StartPosition       = "CenterScreen"
    FormBorderStyle     = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    MaximizeBox         = $false
    MinimizeBox         = $false
}
$chooseTimeForm.Icon = Get-FormIcon

# Add a label for the title
$timeLabel = New-Object Forms.Label -Property @{
    Text                = "When do you want to take a break?"
    Location            = New-Object Drawing.Point(12, 18)
    AutoSize            = $true
}
$chooseTimeForm.Controls.Add($timeLabel)

# Add a timepicker for user input
$timePicker = New-Object Forms.DateTimePicker -Property @{
    Format              = [Forms.DateTimePickerFormat]::Time
    Location            = New-Object Drawing.Point(230, 12)
    Size                = New-Object Drawing.Size(160, 25)
    Value               = [DateTime]::Now
    ShowUpDown          = $true
}
$timePickerToolTip = New-Object Forms.ToolTip
$timePickerToolTip.SetToolTip($timePicker, "The time you want to take a break.")
$chooseTimeForm.Controls.Add($timePicker)


# Add a combo box to select what happens when the timer runs out
$actionComboBox = New-Object Forms.ComboBox -Property @{
    FormattingEnabled   = $true
    Location            = New-Object Drawing.Point(229, 42)
    Size                = New-Object Drawing.Size(160, 25)
    DropDownStyle       = "DropDownList"
}
$actionComboBox.Items.AddRange(@(
    "Display a message",
    "Log user out",
    "Lock PC",
    "Reboot PC",
    "Shutdown PC"
))
$actionComboBox.SelectedIndex = 0  # Set default to "Display a message"
$actionComboBoxToolTip = New-Object Forms.ToolTip
$actionComboBoxToolTip.SetToolTip($actionComboBox, "Choose what will happen at the selected time.")
$chooseTimeForm.Controls.Add($actionComboBox)

# Add button to accept user input TriggerReboot -delay
$confirmButton = New-Object Forms.Button -Property @{
    Location            = New-Object Drawing.Point(138, 86)
    Text                = 'Confirm'
    Size                = New-Object Drawing.Size(120, 25)
    Anchor              = "Bottom"
    DialogResult        = [Forms.DialogResult]::OK
}
$chooseTimeForm.Controls.Add($confirmButton)
$chooseTimeForm.confirmButton = $confirmButton


#==================================================
# Timer
$timer = New-Object Forms.Timer -Property @{
    Interval        = 1000
    Tick            = Update-TimerTick
}
$timeCooldown = 120     # Used to prevent alert popups from displaying too early
$timeRemaining = 0
$timerAction = [TimerAction]::Undefined


#==================================================
# Notification tray icon
$notificationTrayIcon = New-Object Forms.NotifyIcon -Property @{
    Visible             = $false
}


#==================================================
# Timer
$nudgeSound = New-Object System.Media.SoundPlayer $wavFilePath


#==================================================
# Notification tray context menu
$ctxMenu = New-Object Forms.ContextMenu

# On complete...
$ctxMenu_ChangeAction = New-Object System.Windows.Forms.MenuItem("On complete...")
$ctxMenu.MenuItems.Add($ctxMenu_ChangeAction)
# On complete... > Display a message
$ctxMenu_ChangeAction_Message = New-Object System.Windows.Forms.MenuItem("Display a message")
$ctxMenu_ChangeAction_Message.add_Click({ Set-TimerAction -action [TimerAction]::Message })
$ctxMenu_ChangeAction.MenuItems.Add($ctxMenu_ChangeAction_Message)
# On complete... > Log user out
$ctxMenu_ChangeAction_SignOut = New-Object System.Windows.Forms.MenuItem("Log user out")
$ctxMenu_ChangeAction_SignOut.add_Click({ Set-TimerAction -action [TimerAction]::SignOut })
$ctxMenu_ChangeAction.MenuItems.Add($ctxMenu_ChangeAction_SignOut)
# On complete... > Lock PC
$ctxMenu_ChangeAction_Lock = New-Object System.Windows.Forms.MenuItem("Lock PC")
$ctxMenu_ChangeAction_Lock.add_Click({ Set-TimerAction -action [TimerAction]::Lock })
$ctxMenu_ChangeAction.MenuItems.Add($ctxMenu_ChangeAction_Lock)
# On complete... > Reboot PC
$ctxMenu_ChangeAction_Reboot = New-Object System.Windows.Forms.MenuItem("Reboot PC")
$ctxMenu_ChangeAction_Reboot.add_Click({ Set-TimerAction -action [TimerAction]::Reboot })
$ctxMenu_ChangeAction.MenuItems.Add($ctxMenu_ChangeAction_Reboot)
# On complete... > Shutdown PC
$ctxMenu_ChangeAction_Shutdown = New-Object System.Windows.Forms.MenuItem("Shutdown PC")
$ctxMenu_ChangeAction_Shutdown.add_Click({ Set-TimerAction -action [TimerAction]::Shutdown })
$ctxMenu_ChangeAction.MenuItems.Add($ctxMenu_ChangeAction_Shutdown)

# Seperator
$ctxMenu.MenuItems.Add("-")

# Pause
$ctxMenu_Pause = New-Object System.Windows.Forms.MenuItem("Pause")
$ctxMenu_Pause.add_Click({ Update-TimerPausedState })
$ctxMenu.MenuItems.Add($ctxMenu_Pause)

# Cancel
$ctxMenu_Cancel = New-Object System.Windows.Forms.MenuItem("Cancel")
$ctxMenu_Cancel.add_Click({ Step-PromptCancelTimer })
$ctxMenu.MenuItems.Add($ctxMenu_Cancel)


# ======================================================================
# Get the form icon
function Get-FormIcon {
    $iconPath = Join-Path -Path $scriptDir -ChildPath "icons\"
    return ($iconPath + "FormIcon.ico")
}

# Get the icon for the current action and state
function Get-Icon {
    params (
        [TimerAction]$action = [TimerAction]::Undefined,
        [switch]$form
    )

    $iconPath = Join-Path -Path $scriptDir -ChildPath "icons\"

    if ($form) {
        return ($iconPath + "FormIcon.ico")
    }

    $iconPath = $iconPath + (Get-TimerActionAsString -action $timerAction -nsp)
    $iconPath = $iconPath + "_" + (if ($timer.Enabled) {"active"} else {"inactive"}) + ".ico"
    return $iconPath
}

function Set-TimerAction {
    param ([TimerAction]$action)

    $timerAction = $action
    $notificationTrayIcon.Icon = Get-Icon -action $action
}

function Update-TimerPausedState {
    if ($timer.Enabled) {
        $timer.Stop()
    } else {
        $timer.Start()
    }

    $notificationTrayIcon.Icon = Get-Icon -action $timerAction
}

function Start-Timer {
    param (
        [int]$time,
        [TimerAction]$action
    )

    $timeRemaining = $time - $timeCooldown
    $script:timerCompleteAction = $action

    $timer.Start()
    [Forms.Application]::Run()

    # Display a timer start notification
    $actionName = Get-TimerActionAsString -action $timerAction
    $notificationTrayIcon.ShowBalloonTip(
        7000,
        "Break Countdown Started",
        "Hover over the Focus Break icon in the notification bar to see remaining time and right-click for options.",
        [Forms.ToolTipIcon]::Notice
    )
}

function Update-IconTrayText {
    $totalTime = $timeRemaining + $timeCooldown
    $seconds = $totalTime % 60
    $minutes = [Math]::Floor($totalTime / 60)
    $hours = [Math]::Floor($minutes / 60)
    $minutes = $minutes % 60

    $actionName = Get-TimerActionAsString -action $timerAction

    if ($hours -lt 0) {
        $notifyIcon.Text = "$actionName PC in: $($hours)h $($minutes)m $($seconds)s"
    } elseif ($minutes -lt 0) {
        $notifyIcon.Text = "$actionName PC in: $($minutes)m $($seconds)s"
    } elseif ($seconds -lt 0) {
        $notifyIcon.Text = "$actionName PC in: $($seconds)s"
    } else {
        $notifyIcon.Text = "$actionName PC..."
    }
}

function Update-TimerTick() {
    if ($timeCooldown -lt 0)
    {
        $timeCooldown--
        Update-IconTrayText
        return
    }

    $timeRemaining--
    Update-IconTrayText

    # Trigger the timer action
    if ($global:timeRemaining -eq 0) {
        $timer.Stop()
        $timer.Dispose()
        [Forms.Application]::Exit()

        switch ($timerAction) {
            [TimerAction]::SignOut  { return Step-SignOut }
            [TimerAction]::Lock     { return Step-LockPC }
            [TimerAction]::Reboot   { return Step-RebootPC }
            [TimerAction]::Shutdown { return Step-ShutdownPC }
        }
        Step-TimerCompleteMessage
        return
    }

    $action = Get-TimerActionAsString -action $timerAction
    $actionDesc = Get-TimerActionDesc -action $timerAction

    # Display a 30 second warning
    if ($global:timeRemaining -eq 30) {
        [System.Media.SystemSounds]::Exclamation.Play()
        $notificationTrayIcon.ShowBalloonTip(
            7000,
            "$action Imminent!",
            "$actionDesc in less than 30 seconds!",
            [Forms.ToolTipIcon]::Warning
        )
        return
    }

    # Display a 5 minute warning
    if ($global:timeRemaining -eq (60 * 5)) {
        $notificationTrayIcon.ShowBalloonTip(
            7000,
            "$action Notice",
            "$actionDesc in 5 minutes. You should be wrapping up by now...",
            [Forms.ToolTipIcon]::Information
        )
        return
    }

    # Display a 15 minute warning
    if ($global:timeRemaining -eq (60 * 15)) {
        $notificationTrayIcon.ShowBalloonTip(
            7000,
            "$action Notice",
            "$actionDesc in 15 minutes. Recommend saving any important work now.",
            [Forms.ToolTipIcon]::Information
        )
        return
    }
}

# Define a lock function
function Step-TimerCompleteMessage
{
    Write-Host "TIMER COMPLETED MESSAGE DISPLAYED"

    $nudgeWindow = New-Object System.Windows.Forms.Form -Property @{
        Text            = "Break time!"
        Size            = New-Object Drawing.Size(300, 150)
        StartPosition   = "CenterScreen"
        FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
        MaximizeBox     = $false
        MinimizeBox     = $false
        ControlBox      = $false
        TopMost         = $true
    }

    $takeABreakLabel = New-Object System.Windows.Forms.Label -Property @{
        Text = "It's time to take a break!"
        AutoSize = $true
        TextAlign = "MiddleCenter"
        Dock = "Fill"
    }
    $nudgeWindow.Controls.Add($takeABreakLabel)

    $okButton = New-Object Forms.Button -Property @{
        Text = "OK"
        DialogResult = [System.Windows.Forms.DialogResult]::OK
        Anchor = "Bottom"
        Dock = "Bottom"
    }
    $nudgeWindow.Controls.Add($okButton)
    $nudgeWindow.AcceptButton = $okButton

    $nudgeTimer = New-Object Forms.Timer
    $timer.Interval = 100  # 0.1 seconds

    $random = New-Object System.Random
    $centerX = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width / 2 - $nudgeWindow.Width / 2
    $centerY = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height / 2 - $nudgeWindow.Height / 2

    $timesShaken = 0
    $timesNudged = 0

    $timer.Add_Tick({
        if ($timesShaken -eq 0) {
            $okButton.Enabled = $false
            $timesNudged++
            if ($timesNudged -le 5) {
                $nudgeSound.Play()
                $timer.Interval = 100  # 0.1 seconds
            } else {
                # Stop after the fifth nudge
                $nudgeTimer.Stop()
                return
            }
        }
        $timesShaken++

        # Generate a small random offset within a range (e.g., -20 to +20 pixels)
        $offsetX = $random.Next(-20, 21)
        $offsetY = $random.Next(-20, 21)

        if ($timesShaken -lt 10) {
            $okButton.Enabled = $true
            $offsetX = 0
            $offsetY = 0
            $timesShaken = 0
            $timer.Interval = 10000     # 10 seconds
        }

        # Move the form to the new location
        $nudgeWindow.Location = New-Object Drawing.Point($centerX + $offsetX, $centerY + $offsetY)
    })

    $nudgeTimer.Start()
    [Forms.Application]::Run()

    $nudgeWindow.ShowDialog()

    $nudgeTimer.Stop()
    $nudgeTimer.Dispose()
    [Forms.Application]::Exit()
}

# Define a sign out function
function Step-SignOut
{
    Write-Host "SIGNING USER OUT"
    ./Shutdown.exe /l
}

# Define a lock function
function Step-LockPC
{
    Write-Host "PC LOCK INVOKED"
    rundll32.exe user32.dll,LockWorkStation
}

# Define a reboot function
function Step-RebootPC
{
    Write-Host "REBOOT INVOKED"
    Restart-Computer -Force
}

# Define a shutdown function
function Step-ShutdownPC
{
    Write-Host "REBOOT INVOKED"
    Stop-Computer -Force
}



# Show the form
Write-Host "APP SETUP"
$result = $chooseTimeForm.ShowDialog()

# Check what the result was
if ($result -eq [Windows.Forms.DialogResult]::OK) {
    $timeSeconds = $timePicker.Value.Millisecond / 1000
    if ($timeSeconds -ge (3 * 60)) {
        $action = Get-EnumFromComboBox -value $actionComboBox.SelectedItem
        if ($action -ne [TimerAction]::Undefined)
        {
            Start-Timer -time $timeSeconds -action $action
        }
    }
}