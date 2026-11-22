# GPT-NeoX container build results

The runner tests the standard, Transformer Engine, and B200 Docker images and the native Apptainer recipe. Each runs with pip and uv and with GPT-NeoX fused kernels enabled and disabled, for a total of 12 Docker builds and 4 Apptainer builds.

Each Docker build uses `--pull --no-cache` to check its base image tags and rerun the Dockerfile steps. Docker can reuse base image layers already present on the host. Each Apptainer build uses `--disable-cache` to bypass its image cache.

This repository preserves both sets of recipes and their build inputs from GPT-NeoX commit `9603b14`, before the switch to uv-only images. To rerun the comparison, run the following from this repository. Set `NEOX_CHECKOUT` only to use a different checkout containing both sets of recipes. [Archived container guide](containers/README.md) · [GPT-NeoX source revision](https://github.com/aflah02/gpt-neox/tree/9603b14405adaaf7c89e63e1deb64a5ecda2daba)

```bash
./build-all.sh --tmux
```

Add `--b200-only` to run the four B200 Docker builds with the same logs and timing summary.

Each recorded run directory contains its combined and per-case logs, timing summary, and a `build-inputs.tar.gz` archive of the exact `context/` and `pip-kernel-src/` directories used for that run. The [original PR draft](pull-request.md) records the comparison before review.

## Measured Docker build times

All 12 Docker configurations built successfully across two runs on `sws-2h100-02`. The November 20 run used `f8c01c4` for the standard and Transformer Engine images. The November 21 B200 rerun used `88c7227` after the UID fix. Both revisions predate the dependency updates on the rebased branch. The host lacked `apptainer`, so the native Apptainer cases have no build timings. [November 20 summary](run-20261120T211324Z-UafkfP/summary.tsv) · [B200 rerun summary](run-20261121T082946Z-7K25n5/summary.tsv)

![Docker build times and speedups for pip versus uv and fused kernels enabled versus disabled](docker-build-speedups.png)
