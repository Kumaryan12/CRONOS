# Analytics

All metrics are derived from completed, non-idle sessions. Category and application
durations are sums of session intersections with the requested local date range.

## Focus score

The 0–100 score is explainable and stores every component:

```text
score = 100 * (
  0.35 * productive_fraction +
  0.30 * focus_fraction +
  0.15 * focus_length_quality +
  0.10 * switch_quality +
  0.10 * interruption_quality
)
```

Fractions are clamped to 0…1. Focus length quality reaches 1 at a 60-minute
average; switch quality decreases linearly to zero at 30 switches/hour; and
interruption quality decreases to zero at 12 distracting interruptions. A score
is not shown when active time is insufficient.

Focus sessions require sustained productive activity, tolerate only short neutral
gaps, and reject runs with excessive switching or distraction. The V1 weekly view
compares observed days with the user's prior 14 active days and displays sample size.
Future correlations will always display sample size and never claim causation.
