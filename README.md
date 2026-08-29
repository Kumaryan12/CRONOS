# CHRONOS

**Personal Time Intelligence** — understand where your time actually goes.

> Screenshot placeholder: the native daily timeline and focus dashboard are under
> active development.

Chronos is a privacy-first macOS menu-bar app that converts event-driven application
activity into useful daily and weekly analytics. It distinguishes active use from
idle time and explains focus, interruption, and context-switch metrics without
screenshots, keystrokes, shame, or a required cloud account.

## Current milestone

Milestones 0–2 provide the native package architecture, a working event-driven
collector, conservative session reconstruction, versioned SQLite persistence,
crash checkpoints, a live menu-bar diagnostic view, and tests.

## Architecture and privacy

Collection is driven by `NSWorkspace` notifications for applications, screen
state, device wake, and user sessions. A tolerant low-frequency idle check is the
only polling. Events and sessions remain in a local SQLite database.

See [Architecture](docs/ARCHITECTURE.md), [Privacy](docs/PRIVACY.md),
[Analytics](docs/ANALYTICS.md), and [Energy](docs/ENERGY.md).

## Requirements

- macOS 13 or later
- Swift 6 toolchain or Xcode 16+
- SQLite 3 (included with macOS)

The collector does not need Accessibility or Screen Recording permission. A future
optional enhanced mode may request additional permission only after explaining it.

## Development

```sh
swift build
swift test
swift run ChronosApp
swift run chronos-dev self-test
```

Build an ad-hoc signed app bundle for local installation:

```sh
./scripts/build-app.sh
open dist/Chronos.app
```

Move `Chronos.app` into `/Applications` before enabling Launch at Login. The app
starts as a quiet menu-bar agent and opens no dashboard window automatically.

`chronos-dev self-test` verifies reconstruction, migration, transactional writes,
and reads without launching the UI. Fake-history generation arrives with the
analytics milestone.

## Roadmap

1. Event-driven collector and session reconstruction
2. SQLite persistence and crash recovery
3. Menu bar and launch-at-login lifecycle
4. Daily analytics, dashboard, and timeline
5. Focus, switching, weekly baselines, privacy tools, and energy profiling
6. Optional browser context and summary-only AI insights

Phone sync, cloud accounts, and autonomous coaching are intentionally outside V1.
