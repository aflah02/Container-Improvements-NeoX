# GPT-NeoX container build results

The runner tests the standard and Transformer Engine Docker images and the native Apptainer recipe with pip and uv. Each runs with GPT-NeoX fused kernels enabled and disabled, for a total of eight Docker builds and four Apptainer builds. B200 is excluded.

Point the runner at a local GPT-NeoX checkout on the `docker-build-consolidation` branch. Each invocation writes per-case logs, a combined `build.log`, and timings in `summary.tsv` to a new `run-*` directory beside the script.

```bash
NEOX_CHECKOUT=/path/to/gpt-neox ./build-all.sh --tmux
```
