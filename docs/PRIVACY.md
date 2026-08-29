# Privacy

Chronos stores activity locally in SQLite. It records application identity,
transition timestamps, idle boundaries, and screen/session state. Window-title
collection is off by default.

Chronos never records keystrokes, passwords, clipboard data, screenshots, screen
video, form contents, or message bodies. Basic application tracking uses public
workspace notifications and does not require Accessibility permission.

Privacy Mode stops detailed activity collection immediately. Excluded bundle IDs
are represented as excluded time without retaining the application name. Data can
be exported or deleted by date range, including deletion of all local data.
