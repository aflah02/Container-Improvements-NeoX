# GPT-NeoX container build results

The runner tests the standard, Transformer Engine, and B200 Docker images and the native Apptainer recipe. Each runs with pip and uv and with GPT-NeoX fused kernels enabled and disabled, for a total of 12 Docker builds and 4 Apptainer builds.

Each Docker build uses `--pull --no-cache` to check its base image tags and rerun the Dockerfile steps. Docker can reuse base image layers already present on the host. Each Apptainer build uses `--disable-cache` to bypass its image cache.

Point the runner at a local GPT-NeoX checkout on the `docker-build-consolidation` branch. Each invocation writes per-case logs, a combined `build.log`, and timings in `summary.tsv` to a new `run-*` directory beside the script.

```bash
NEOX_CHECKOUT=/path/to/gpt-neox ./build-all.sh --tmux
```

Add `--b200-only` to run the four B200 Docker builds with the same logs and timing summary.

## Measured Docker build times

All 12 Docker configurations built successfully across two runs on `sws-2h100-02`. The November 20 run used `f8c01c4` for the standard and Transformer Engine images. The November 21 B200 rerun used `88c7227` after the UID fix. Both revisions predate the dependency updates on the rebased branch. The host lacked `apptainer`, so the native Apptainer cases have no build timings. [November 20 summary](run-20261120T211324Z-UafkfP/summary.tsv) · [B200 rerun summary](run-20261121T082946Z-7K25n5/summary.tsv)

![Docker build times and speedups for pip versus uv and fused kernels enabled versus disabled](docker-build-speedups.png)
