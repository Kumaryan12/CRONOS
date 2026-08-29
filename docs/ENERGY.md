# Energy Strategy

Chronos treats wake-ups as a product metric.

- Application, screen, wake, and session changes arrive through macOS
  notifications.
- No process scanning, screenshots, GPU work, or continuous network connection.
- No AI runs in the collector.
- Idle detection reads the system idle counter every 30 seconds by default; the
  dispatch timer has tolerance and writes only when idle state changes.
- Events and completed sessions are committed transactionally. Deeper analytics
  run lazily and cached summaries are updated incrementally.
- Trackers suspend unnecessary work while the display or user session is inactive.

Developer diagnostics expose event and write rates, aggregation count, database
size, CPU, and memory so these claims can be measured with Instruments and
Activity Monitor. Release profiling should confirm near-zero CPU between events
and no background GPU use.
