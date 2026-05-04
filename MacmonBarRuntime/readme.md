# MacmonBarRuntime

This directory contains the Rust metrics agent bundled by Macmon Bar.

It is based on upstream `macmon` commit `20665fdee05414518792be981b202b713cf3b196`
from <https://github.com/vladkens/macmon> and keeps the upstream MIT license.
Macmon Bar owns this copy because the app needs product-specific metrics that
are not part of the upstream CLI contract:

- network upload/download rates and byte counters
- top process power estimates for the dashboard
- JSON and Prometheus fields consumed by the Swift app

Do not put Macmon Bar runtime changes in `../macmon`. That submodule is only an
upstream reference and should stay updateable from `vladkens/macmon`.

When changing this runtime, keep these in sync:

- `src/metrics.rs` and `src/serve.rs`
- `MacmonBar/Sources/MacmonBar/Models/MetricSnapshot.swift`
- decoding and layout tests under `MacmonBar/Tests/MacmonBarTests`
