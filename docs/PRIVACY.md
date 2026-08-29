# Privacy

Chronos stores activity locally in SQLite. It records application identity,
transition timestamps, idle boundaries, and screen/session state. Window-title
collection is off by default.

Chronos never records keystrokes, passwords, clipboard data, screenshots, screen
video, form contents, or message bodies. Basic application tracking uses public
workspace notifications and does not require Accessibility permission.

Privacy Mode stops all event retention immediately. Entering an excluded application
closes the prior session and writes no bundle ID or application name for the excluded
activity. Common password managers are excluded by default. User rules can exclude
additional applications or override their category retroactively.

The Privacy page exports events, sessions, and application rules as readable JSON.
It can delete today, an inclusive date range, or all local activity. Deletion pauses
tracking so new records are not created unexpectedly during the operation.
