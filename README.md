# GPT-NeoX container build results

The runner tests the standard, Transformer Engine, and B200 Docker images and the native Apptainer recipe. Each runs with pip and uv and with GPT-NeoX fused kernels enabled and disabled, for a total of 12 Docker builds and 4 Apptainer builds.

Point the runner at a local GPT-NeoX checkout on the `docker-build-consolidation` branch. Each invocation writes per-case logs, a combined `build.log`, and timings in `summary.tsv` to a new `run-*` directory beside the script.

```bash
NEOX_CHECKOUT=/path/to/gpt-neox ./build-all.sh --tmux
```
