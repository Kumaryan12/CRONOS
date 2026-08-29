# Energy Strategy

Chronos treats wake-ups as a product metric.

- Application, screen, wake, and session changes arrive through macOS
  notifications.
- No process scanning, screenshots, GPU work, or continuous network connection.
- No AI runs in the collector.
- Idle detection reads the system idle counter every 30 seconds by default; the
  dispatch timer has tolerance and writes only when idle state changes.
- The idle timer stops while the screen or user session is inactive.
- Events and completed sessions are committed in one transaction per boundary.
- Dashboard analytics recompute only bounded current-day/current-week windows when
  a session closes; the collector performs no continuous analytics.
- The diagnostics timer exists only while its page is visible.

Developer diagnostics expose event and write rates, aggregation count, database
size, CPU, and memory so these claims can be measured with Instruments and
Activity Monitor. Release profiling should confirm near-zero CPU between events
and no background GPU use.
