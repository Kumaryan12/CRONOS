# Chronos Architecture

Chronos is a local-first macOS application split into three independent layers.
The collector observes state transitions, the core owns storage and analytics,
and the SwiftUI app presents derived data. Closing the dashboard does not stop
collection.

## Runtime flow

```text
NSWorkspace / CoreGraphics notifications
                  |
                  v
          ChronosCollector
                  |
                  v
       normalized ActivityEvent
                  |
                  v
     EventProcessor -> SQLite event log
                  |
                  v
       closed ActivitySession
                  |
                  v
     aggregates and analytics -> SwiftUI
```

`ApplicationTracker`, `ScreenTracker`, and `SessionTracker` are notification
driven. `IdleTracker` is the sole timer-based tracker: it samples macOS's existing
idle counter at a coarse interval with leeway and emits only boundary changes.
There is no per-second activity sampling.

## Packages

- `ChronosCore`: models, migrations, repositories, categorization, analytics,
  and rule-based insights. It has no UI dependency.
- `ChronosCollector`: native macOS event adapters and session processing.
- `ChronosApp`: menu-bar lifecycle and native SwiftUI views.
- `chronos-dev`: deterministic fake-data and diagnostics tooling.

## Correctness boundaries

Events use UTC `Date` values. Calendar-aware aggregation splits sessions at
local day boundaries. A session is written only when its ending transition is
known. On restart, open sessions are marked interrupted; Chronos does not infer
activity across a crash.

## Extension points

Future browser and device collectors must emit the same `ActivityEvent` model.
Cloud sync and AI are not dependencies of collection, persistence, or analytics.
