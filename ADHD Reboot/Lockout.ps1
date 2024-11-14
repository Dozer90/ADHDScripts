# Script version: v4.0
# Date: 12:54 PM 25/02/2024
$ErrorActionPreference = "Stop"
Write-Host "APP STARTED"
Set-PSDebug -Trace 2

# Load necessary assembly for GUI dialog
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


#==================================================
#==================================================
#
#                  ENUMERATIONS
#
#==================================================
#==================================================

Add-Type -TypeDefinition @"
public enum TimerAction {
    Undefined,
    Message,
    Lock,
    SignOut,
    Reboot,
    Shutdown
}
"@


#==================================================
#==================================================
#
#                   VARIABLES
#
#==================================================
#==================================================

$monoFont = New-Object System.Drawing.Font("Courier New", 9, [System.Drawing.FontStyle]::Regular)
$iconRootPath = Join-Path -Path $PSScriptRoot -ChildPath "icons\"
$audioRootPath = Join-Path -Path $PSScriptRoot -ChildPath "audio\"

$timeCooldown = 120     # Used to prevent alert popups from displaying too early
$timeRemaining = 0
$timerAction = [TimerAction]::Undefined


#==================================================
#==================================================
#
#                   FUNCTIONS
#
#==================================================
#==================================================

## Get the enum value from a combo box value
##    param [string] value: The value of the combo box
function Get-EnumFromComboBox {
    params ([string]$value)

    switch ($value) {
        "Display a message"     { return [TimerAction]::Message }
        "Lock PC"               { return [TimerAction]::Lock }
        "Sign user out"         { return [TimerAction]::SignOut }
        "Reboot PC"             { return [TimerAction]::Reboot }
        "Shutdown PC"           { return [TimerAction]::Shutdown }
    }
    return [TimerAction]::Undefined
}


## Get the string version of the enum value
##    param [TimerAction] action: The action to get a description of (default: current action)
##    param [switch] nsp: Flag to remove spaces from the resulting string
function Get-TimerActionAsString {
    param (
        [TimerAction]$action = $timerAction,
        [switch]$nsp
    )

    switch ($action) {
        [TimerAction]::Message    { return "Message" }
        [TimerAction]::Lock       { return "Lock" }
        [TimerAction]::SignOut    { return if ($nsp) {"SignOut"} else {"Sign Out"} }
        [TimerAction]::Reboot     { return "Reboot" }
        [TimerAction]::Shutdown   { return "Shutdown" }
    }
    return "Unknown"
}


## Get the 'active' verb for the given action
##    param action: The action to get a description of (default: current action)
function Get-TimerActionDesc {
    param ([TimerAction]$action = $timerAction)

    switch ($action) {
        [TimerAction]::Message    { return "Message displaying" }
        [TimerAction]::Lock       { return "Locking PC" }
        [TimerAction]::SignOut    { return "Signing user out" }
        [TimerAction]::Reboot     { return "Rebooting PC" }
        [TimerAction]::Shutdown   { return "Shutting down PC" }
    }
    return "Unknown"
}


## Create a tooltip and attach it to the given Object
##    param on: The object to attach the tooltip to
##    param text: The tooltip message
function Create-ToolTip {
    param (
        [System.Windows.Forms.Control]$on,
        [string]$text
    )

    $tooltip = New-Object System.Windows.Forms.ToolTip -Property @{
        OwnerDraw           = $true
    }
    $tooltip.Add_Draw({ param ($sender, $e)
        $e.Graphics.DrawString($toolTip.GetToolTip($e.AssociatedControl), $monoFont, [System.Drawing.Brushes]::Black, $e.Bounds)
    })
    $tooltip.SetToolTip($on, $text)
}


## Get the form icon
function Get-FormIcon {
    return ($iconRootPath + "FormIcon.ico")
}


## Get the icon for the nav bar based on the selected action and timer enabled state
##    param action: The action the icon should represent (default: current action)
##    param active: Should we get the active state icon (default: current state)
function Get-Icon {
    params (
        [TimerAction]$action = $timerAction,
        [bool]$active = $timer.Enabled
    )

    $icon = Get-TimerActionAsString -action $action -nsp
    $icon = $icon + "_" + (if ($active) {"active"} else {"inactive"})
    return $iconRootPath + $icon + ".ico"
}


## Get the icon for the nav bar based on the selected action and timer enabled state
##    param action: The action the icon should represent (default: current action)
##    param active: Should we get the active state icon (default: current state)
function Set-TimerAction {
    param ([TimerAction]$action)

    $timerAction = $action
    $notificationTrayIcon.Icon = Get-Icon -action $action
}


## Toggle the active state of the timer and update the tray icon
function Update-TimerPausedState {
    if ($timer.Enabled) {
        $timer.Stop()
    } else {
        $timer.Start()
    }

    $notificationTrayIcon.Icon = Get-Icon -action $timerAction
}


## Check to see if we can start the timer
function Check-CanStartTimer {
    $timeSeconds = $timePicker.Value.Millisecond / 1000
    #if ($timeSeconds -ge (3 * 60)) {
        Write-Host $actionComboBox.SelectedItem
        $action = Get-EnumFromComboBox -value $actionComboBox.SelectedItem
        if ($action -ne [TimerAction]::Undefined)
        {
            Write-Host "Can start timer"
            $timeRemaining = $time - $timeCooldown
            Set-TimerAction -action $action
            return $true
        }
    #}
    return $false
}


## Starts the timer to the next break
function Start-Timer {
    Write-Host "Starting timer..."
    $timer.Start()
    [System.Windows.Forms.Application]::Run()

    # Display a timer start notification
    $actionName = Get-TimerActionAsString -action $timerAction
    $notificationTrayIcon.ShowBalloonTip(
        7000,
        "Break Countdown Started",
        "Hover over the Focus Break icon in the notification bar to see remaining time and right-click for options.",
        [System.Windows.Forms.ToolTipIcon]::Notice
    )
    $notificationTrayIcon.Visible = $true
    
}


## Update the text to display when hovering over the notification tray icon
function Update-NotificationTrayHoverText {
    $totalTime = $timeRemaining + $timeCooldown
    $seconds = $totalTime % 60
    $minutes = [Math]::Floor($totalTime / 60)
    $hours = [Math]::Floor($minutes / 60)
    $minutes = $minutes % 60

    $actionName = Get-TimerActionAsString -action $timerAction

    if ($hours -lt 0) {
        $notifyIcon.Text = "$actionName in: $($hours)h $($minutes)m $($seconds)s"
    } elseif ($minutes -lt 0) {
        $notifyIcon.Text = "$actionName in: $($minutes)m $($seconds)s"
    } elseif ($seconds -lt 0) {
        $notifyIcon.Text = "$actionName in: $($seconds)s"
    } else {
        $notifyIcon.Text = "$actionName..."
    }
}

function Update-NotificationTrayIcon {
    
}


## Logic to perform whenever the timer elapses
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
        [System.Windows.Forms.Application]::Exit()

        switch ($timerAction) {
            [TimerAction]::Lock     { return Step-LockPC }
            [TimerAction]::SignOut  { return Step-SignOut }
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
            [System.Windows.Forms.ToolTipIcon]::Warning
        )
        return
    }

    # Display a 5 minute warning
    if ($global:timeRemaining -eq (60 * 5)) {
        $notificationTrayIcon.ShowBalloonTip(
            7000,
            "$action Notice",
            "$actionDesc in 5 minutes. You should be wrapping up by now...",
            [System.Windows.Forms.ToolTipIcon]::Information
        )
        return
    }

    # Display a 15 minute warning
    if ($global:timeRemaining -eq (60 * 15)) {
        $notificationTrayIcon.ShowBalloonTip(
            7000,
            "$action Notice",
            "$actionDesc in 15 minutes. Recommend saving any important work now.",
            [System.Windows.Forms.ToolTipIcon]::Information
        )
        return
    }
}


## Logic for TimerAction::Message action
function Step-TimerCompleteMessage
{
    Write-Host "TIMER COMPLETED MESSAGE DISPLAYED"

    # Create a transparent overlay (full-screen)
    $overlayForm = New-Object System.Windows.Forms.Form
    $overlayForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $overlayForm.TopMost = $true
    $overlayForm.ShowInTaskbar = $false
    $overlayForm.BackColor = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)  # Fully transparent background
    $overlayForm.Bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $overlayForm.Location = New-Object System.Drawing.Point(0, 0)
    $overlayForm.Opacity = 0.6  # Adjust opacity to make it semi-transparent

    $nudgeWindow = New-Object System.Windows.Forms.Form -Property @{
        Size            = New-Object Drawing.Size(300, 110)
        Padding         = New-Object System.Windows.Forms.Padding(10, 10, 10, 10)
        StartPosition   = "CenterScreen"
        FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
        MaximizeBox     = $false
        MinimizeBox     = $false
        ControlBox      = $false
        TopMost         = $true
    }

    $labelPanel = New-Object System.Windows.Forms.Panel -Property @{
        Dock            = "Fill"
    }
    $nudgeWindow.Controls.Add($labelPanel)

    $takeABreakLabel = New-Object System.Windows.Forms.Label -Property @{
        Text            = "Break time!"
        Dock            = "Fill"
        TextAlign       = "MiddleCenter"
    }
    $takeABreakLabel.Font = New-Object System.Drawing.Font($takeABreakLabel.Font.FontFamily, 20)
    $labelPanel.Controls.Add($takeABreakLabel)

    $nudgeTimer = New-Object System.Windows.Forms.Timer

    $okButton = New-Object System.Windows.Forms.Button -Property @{
        Text                = "OK"
        DialogResult        = [System.Windows.Forms.DialogResult]::OK
        Dock                = "Bottom"
    }
    $okButton.add_Click({
        [System.Windows.Forms.Application]::Exit()
        $nudgeTimer.Stop()
    })
    $nudgeWindow.Controls.Add($okButton)
    $nudgeWindow.AcceptButton = $okButton

    $random = New-Object System.Random
    $centerX = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width / 2 - $nudgeWindow.Width / 2
    $centerY = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height / 2 - $nudgeWindow.Height / 2

    $script:timesNudged = 0
    $maxNudgeCount = 5
    $nudgeDurationInSeconds = 0.8
    $script:nudgeTimeEllapsed = 0
    $secondsBetweenNudge = 30

    $shakesPerSecond = 40
    $shakeIntensityRadius = 6

    $nudgeSound.Load()
    $nudgeTimerInterval = 1000 / $shakesPerSecond

    $nudgeTimer.Add_Tick({
        Write-Host "Tick"

        if ($script:nudgeTimeEllapsed -eq 0) {
            Write-Host "Starting nudge..."
            $okButton.Enabled = $false
            $nudgeSound.Play()
            $nudgeTimer.Interval = $nudgeTimerInterval
        }

        $script:nudgeTimeEllapsed += $nudgeTimerInterval
        Write-Host "Nudge time ellapsed: $script:nudgeTimeEllapsed"

        if ($script:nudgeTimeEllapsed -le ($nudgeDurationInSeconds * 1000)) {
            Write-Host "- Shake -"
            # Move the form to the new location
            $posX = $centerX + $random.Next(-$shakeIntensityRadius, $shakeIntensityRadius + 1)
            $posY = $centerY + $random.Next(-$shakeIntensityRadius, $shakeIntensityRadius + 1)
            $nudgeWindow.Location = New-Object Drawing.Point($posX, $posY)
        } else {
            Write-Host "Nudge ended"
            $script:timesNudged++
            $script:nudgeTimeEllapsed = 0
            $okButton.Enabled = $true
            $nudgeWindow.Location = New-Object Drawing.Point($centerX, $centerY)
            $nudgeTimer.Interval = ($secondsBetweenNudge - $nudgeDurationInSeconds) * 1000

            # Check if we have reached the max nudge count
            if ($script:timesNudged -ge $maxNudgeCount) {
                $nudgeTimer.Stop()
                Write-Host "Timer stopped"
            }
        }
    })

    $overlayForm.Show()
    $nudgeWindow.Show()
    $nudgeTimer.Interval = $nudgeTimerInterval
    $nudgeTimer.Start()
    
    Write-Host "START"
    [System.Windows.Forms.Application]::Run()

    #$nudgeTimer.Stop()
    #$nudgeTimer.Dispose()
    #[System.Windows.Forms.Application]::Exit()
}


## Logic for TimerAction::Lock action
function Step-LockPC
{
    Write-Host "PC LOCK INVOKED"
    rundll32.exe user32.dll,LockWorkStation
}


## Logic for TimerAction::SignOut action
function Step-SignOut
{
    Write-Host "SIGNING USER OUT"
    ./Shutdown.exe /l
}


## Logic for TimerAction::Reboot action
function Step-RebootPC
{
    Write-Host "REBOOT INVOKED"
    Restart-Computer -Force
}


## Logic for TimerAction::Shutdown action
function Step-ShutdownPC
{
    Write-Host "REBOOT INVOKED"
    Stop-Computer -Force
}


#==================================================
#==================================================
#
#               WINFORM ELEMENTS
#
#==================================================
#==================================================

# Time picker form
$chooseTimeForm = New-Object System.Windows.Forms.Form -Property @{
    Text                = 'Focus Breaker'
    Size                = New-Object Drawing.Size(420, 162)
    StartPosition       = "CenterScreen"
    FormBorderStyle     = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    MaximizeBox         = $false
    MinimizeBox         = $false
}
$chooseTimeForm.Icon = Get-FormIcon

# Add a label for the title
$timeLabel = New-Object System.Windows.Forms.Label -Property @{
    Text                = "Break time:"
    Location            = New-Object Drawing.Point(12, 18)
    AutoSize            = $true
}
$chooseTimeForm.Controls.Add($timeLabel)

# Add a timepicker for user input
$timePicker = New-Object System.Windows.Forms.DateTimePicker -Property @{
    Format              = [System.Windows.Forms.DateTimePickerFormat]::Time
    Location            = New-Object Drawing.Point(230, 12)
    Size                = New-Object Drawing.Size(160, 25)
    Value               = [DateTime]::Now
    ShowUpDown          = $true
}
$chooseTimeForm.Controls.Add($timePicker)
Create-ToolTip -on $timePicker -text "The time you want to take your break."

# Enforcement label for combo box
$enforcementLabel = New-Object System.Windows.Forms.Label -Property @{
    Text                = "Enforcement type:"
    Location            = New-Object Drawing.Point(12, 42)
    AutoSize            = $true
}
$chooseTimeForm.Controls.Add($enforcementLabel)

$actionComboBox = New-Object System.Windows.Forms.ComboBox -Property @{
    Location            = New-Object Drawing.Point(229, 42)
    Size                = New-Object Drawing.Size(160, 25)
    DropDownStyle       = "DropDownList"
}
$actionComboBox.Items.AddRange(@(
    "Display a message",
    "Lock PC",
    "Sign user out",
    "Reboot PC",
    "Shutdown PC"
))
$actionComboBox.SelectedIndex = 0  # Set default to "Display a message"
$chooseTimeForm.Controls.Add($actionComboBox)

# Tooltip for combo box
$actionComboBoxToolTipMessage = "What should happen when we reach the chosen time.`n" +
                                "  Display a message        Displays a message prompt alerting you to`n" +
                                "                           take your break.`n" +
                                "  Lock PC                  Locks the computer.`n" +
                                "  Sign user out            Signs you out from Windows. Can only be used`n" +
                                "                           for your final break.`n" +
                                "  Reboot PC                Forces the PC to restart. Can only be used`n" +
                                "                           for your final break.`n" +
                                "  Shutdown PC              Forces the PC to shutdown. Can only be used`n" +
                                "                           for your final break."
Create-ToolTip -on $actionComboBox -text $actionComboBoxToolTipMessage

# Add button to accept user input TriggerReboot -delay
$confirmButton = New-Object System.Windows.Forms.Button -Property @{
    Location            = New-Object Drawing.Point(138, 86)
    Text                = 'Confirm'
    Size                = New-Object Drawing.Size(120, 25)
    Anchor              = "Bottom"
    DialogResult        = [System.Windows.Forms.DialogResult]::OK
}
$confirmButton.add_Click({ Check-CanStartTimer })
$chooseTimeForm.Controls.Add($confirmButton)
$chooseTimeForm.AcceptButton = $confirmButton


#==================================================
# Timer
$timer = New-Object System.Windows.Forms.Timer -Property @{
    Interval        = 1000
}
$timer.Add_Tick({ Update-TimerTick })


#==================================================
# Notification tray icon
$notificationTrayIcon = New-Object System.Windows.Forms.NotifyIcon -Property @{
    Visible             = $false
}


#==================================================
# Timer
$nudgeSound = New-Object System.Media.SoundPlayer ($audioRootPath + "nudge.wav")


#==================================================
# Notification tray context menu
$ctxMenu = New-Object System.Windows.Forms.ContextMenu

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





Step-TimerCompleteMessage

## Show the form
#Write-Host "APP SETUP"
#$result = $chooseTimeForm.ShowDialog()
#
## Check what the result was
#if ($result -eq [Windows.Forms.DialogResult]::OK) {
#    $timeSeconds = $timePicker.Value.Millisecond / 1000
#    if ($timeSeconds -ge (3 * 60)) {
#        $action = Get-EnumFromComboBox -value $actionComboBox.SelectedItem
#        if ($action -ne [TimerAction]::Undefined)
#        {
#            Start-Timer -time $timeSeconds -action $action
#        }
#    }
#}