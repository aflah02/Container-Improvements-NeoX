#!/usr/bin/env bash
# Run directly, or pass --tmux to start a detached gpt-neox-build session.
# From a separate results repository, set NEOX_CHECKOUT to the GPT-NeoX checkout.
set -euo pipefail

script=$(realpath -- "${BASH_SOURCE[0]}")
script_dir=$(dirname -- "$script")
repo=$(git -C "${NEOX_CHECKOUT:-$script_dir}" rev-parse --show-toplevel)
if [[ ! -f "$repo/containers/docker/Dockerfile" ]]; then
    printf 'Set NEOX_CHECKOUT to the GPT-NeoX checkout containing containers/docker/Dockerfile.\n' >&2
    exit 2
fi

detached=false
build_options=()
for option in "$@"; do
    case "$option" in
        --tmux) detached=true ;;
        --b200-only) build_options=(--b200-only) ;;
        *) printf 'Usage: %s [--tmux] [--b200-only]\n' "$0" >&2; exit 2 ;;
    esac
done

if [[ $detached == true ]]; then
    tmux new-session -d -s gpt-neox-build -c "$repo" \
        env "PATH=$PATH" "NEOX_CHECKOUT=$repo" bash "$script" "${build_options[@]}"
    printf 'Attach with tmux attach -t gpt-neox-build\nRun logs are under %s/\n' "$script_dir"
    exit 0
fi

run_dir=$(mktemp -d -- "$script_dir/run-$(date -u +%Y%m%dT%H%M%SZ)-XXXXXX")
summary="$run_dir/summary.tsv"
TIMEFORMAT='Elapsed %3R seconds'
failures=0

run_case() {
    local name=$1 started=$SECONDS log="$run_dir/$1.log"
    shift
    local status=PASS rc=0
    local -a codes
    if ! {
        printf '\n[%s] %s\n' "$(date -u +%FT%TZ)" "$name"
        printf '$'
        printf ' %q' "$@"
        printf '\n'
        time "$@"
    } 2>&1 | tee -- "$log"; then
        codes=("${PIPESTATUS[@]}")
        # A failed build has a result to record. A failed log write stops the run.
        if (( codes[1] )); then exit "${codes[1]}"; fi
        rc=${codes[0]}
        status=FAIL
        failures=$((failures + 1))
    fi
    local elapsed=$((SECONDS - started))
    printf '%s\t%s\t%d\t%d\n' "$name" "$status" "$rc" "$elapsed" >> "$summary"
    printf '[%s] %s %s (exit %d, %ds)\n' "$(date -u +%FT%TZ)" "$name" "$status" "$rc" "$elapsed" | tee -a -- "$log"
}

build_recipe() {
    local engine=$1 variant=$2 recipe=$3
    local kernels name
    local -a args
    if [[ ${build_options[0]:-} == --b200-only && $variant != b200-* ]]; then
        return 0
    fi
    for kernels in true false; do
        name="$engine-$variant-kernels-$kernels"
        args=()
        # Leave the kernel argument unset to exercise each recipe's default.
        if [[ $kernels == false ]]; then args+=(--build-arg BUILD_FUSED_KERNELS=false); fi

        if [[ $engine == docker ]]; then
            run_case "$name" docker build --pull --no-cache --progress=plain -f "$recipe" \
                -t "gpt-neox-build-test:${name#docker-}-${run_dir##*/}" "${args[@]}" .
        else
            if [[ $variant == standard-pip ]]; then
                args+=(--bind "$PWD/requirements:/requirements:ro")
                if [[ $kernels == true ]]; then
                    # setup.py writes build intermediates alongside the sources.
                    args+=(--bind "$run_dir/pip-kernel-src:/megatron/fused_kernels:rw")
                fi
            fi
            run_case "$name" apptainer build --disable-cache "${args[@]}" "$run_dir/$name.sif" "$recipe"
        fi
    done
}

main() {
    cd -- "$repo"
    printf 'Run directory: %s\nHost: %s\nCheckout: %s\n' "$run_dir" "$(hostname)" "$repo"
    git log -1 --format='Revision: %h %D %s'
    git status --short -- .dockerignore containers requirements megatron/fused_kernels

    # Snapshot the recipe inputs once. Large .sif files and previous logs stay
    # outside the Docker build context, even when the matrix is run again.
    mkdir -- "$run_dir/context"
    cp -R --parents -- .dockerignore requirements megatron/fused_kernels \
        containers/docker/Dockerfile{,.TE,.B200}{,.uv} \
        containers/apptainer/gpt-neox{,.uv}.def "$run_dir/context/"
    cd -- "$run_dir/context"
    cp -R -- megatron/fused_kernels "$run_dir/pip-kernel-src"
    printf 'Build context: %s\n' "$PWD"
    printf 'case\tstatus\texit_code\telapsed_seconds\n' > "$summary"
    build_recipe docker standard-pip containers/docker/Dockerfile
    build_recipe docker te-pip       containers/docker/Dockerfile.TE
    build_recipe docker standard-uv  containers/docker/Dockerfile.uv
    build_recipe docker te-uv        containers/docker/Dockerfile.TE.uv
    build_recipe docker b200-pip     containers/docker/Dockerfile.B200
    build_recipe docker b200-uv      containers/docker/Dockerfile.B200.uv
    build_recipe apptainer standard-pip containers/apptainer/gpt-neox.def
    build_recipe apptainer standard-uv  containers/apptainer/gpt-neox.uv.def

    printf '\n'
    cat -- "$summary"
    printf '\n%d failed. Results in %s\n' "$failures" "$run_dir"
    (( failures == 0 ))
}

main 2>&1 | tee -- "$run_dir/build.log"
