# Notification hook for Claude Code.
#
# Called by the Notification and Stop hooks in .claude/settings.json.
# Claude Code pipes the hook payload to us as JSON on stdin, and reads
# whatever JSON we print on stdout (see the systemMessage at the bottom).
#
#   -Kind input  -> Claude is blocked waiting on you
#   -Kind done   -> Claude finished the turn
#
# Toast/sound behaviour is tunable in notify.config.json next to this file.

param(
    [ValidateSet('input', 'done')]
    [string]$Kind = 'done'
)

# --- config ------------------------------------------------------------------
# Defaults are what you get with no config file: toast on, sound off.
$toastEnabled = $true
$soundEnabled = $false
$beeps = $null
$wav = $null

$configPath = Join-Path $PSScriptRoot 'notify.config.json'
if (Test-Path $configPath) {
    try {
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        if ($null -ne $config.toast) { $toastEnabled = [bool]$config.toast }
        if ($config.sound) {
            if ($null -ne $config.sound.enabled) { $soundEnabled = [bool]$config.sound.enabled }
            $soundProfile = $config.sound.$Kind
            if ($soundProfile) {
                $beeps = $soundProfile.beeps
                $wav = $soundProfile.wav
            }
        }
    } catch {
        # Bad JSON in the config shouldn't break the hook - fall back to defaults.
    }
}

# --- payload -----------------------------------------------------------------
# Drain stdin so the pipe never blocks, and grab the message Claude Code
# supplies on Notification events (Stop events have no message).
$detail = ''
try {
    $raw = [Console]::In.ReadToEnd()
    if ($raw) { $detail = (ConvertFrom-Json $raw).message }
} catch {
    # Malformed or empty payload - fall back to the generic wording below.
}

# --- output ------------------------------------------------------------------
function Show-Toast {
    param([string]$Title, [string]$Body)
    try {
        [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime]

        # Toasts must be sent under a registered AppUserModelID. This is the
        # built-in Windows PowerShell one, so nothing needs installing.
        $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'

        $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent(
            [Windows.UI.Notifications.ToastTemplateType]::ToastText02)
        $textNodes = $template.GetElementsByTagName('text')
        [void]$textNodes.Item(0).AppendChild($template.CreateTextNode($Title))
        [void]$textNodes.Item(1).AppendChild($template.CreateTextNode($Body))

        $toast = New-Object Windows.UI.Notifications.ToastNotification $template
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
    } catch {
        # Toasts unavailable (notifications off, WinRT missing) - stay quiet.
    }
}

function Play-Sound {
    # A wav path wins over beeps if both are configured.
    try {
        if ($wav) {
            $path = [Environment]::ExpandEnvironmentVariables($wav)
            if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $PSScriptRoot $path }
            if (Test-Path $path) {
                (New-Object System.Media.SoundPlayer $path).PlaySync()
                return
            }
        }
        foreach ($b in $beeps) { [Console]::Beep([int]$b.freq, [int]$b.ms) }
    } catch {
        # A missing codec or bad frequency shouldn't fail the hook.
    }
}

if ($Kind -eq 'input') {
    $title = 'Claude needs your input'
    $body = if ($detail) { $detail } else { 'Waiting on you in Claude Code.' }
    $line = "[!] $body"
} else {
    $title = 'Claude finished'
    $body = 'Task complete - ready for your review.'
    $line = '[OK] Task complete.'
}

if ($soundEnabled) { Play-Sound }
if ($toastEnabled) { Show-Toast -Title $title -Body $body }

# Anything we print on stdout is parsed as JSON by Claude Code.
# systemMessage renders the line in the transcript.
@{ systemMessage = $line } | ConvertTo-Json -Compress
