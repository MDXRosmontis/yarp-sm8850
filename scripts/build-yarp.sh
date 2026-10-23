#!/usr/bin/env bash
set -euo pipefail

builder_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source_root="${YARP_SOURCE_DIR:-/build/yarp}"
dist_root="${YARP_DIST_DIR:-${builder_root}/dist}"
lock_file="${builder_root}/sources.json"
mkdir -p "${source_root}" "${dist_root}"

case "${1:-}" in
  sync)
    cd "${source_root}"
    manifest_revision="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["manifest"]["revision"])' "${lock_file}")"
    repo init -u https://github.com/TWRP-Test/platform_manifest_twrp_aosp.git \
      -b "${manifest_revision}" --depth=1 --no-clone-bundle --no-tags
    python3 "${builder_root}/scripts/source-lock.py" overlay "${lock_file}" "${source_root}"
    repo sync -c -j "${SYNC_JOBS:-8}" --fail-fast --no-tags --no-clone-bundle \
      --optimized-fetch --retry-fetches=3
    python3 "${builder_root}/scripts/source-lock.py" verify "${lock_file}" "${source_root}"
    repo manifest -r -o "${dist_root}/source-manifest.xml"
    cp "${lock_file}" "${dist_root}/sources.json"
    git -C bootable/recovery diff --check
    df -h "${source_root}"
    ;;
  build)
    cd "${source_root}"
    export ALLOW_MISSING_DEPENDENCIES=true
    export USE_CCACHE=0
    export MALLOC_ARENA_MAX=2
    set +u
    source build/envsetup.sh
    lunch twrp_sm8850
    mka installclean
    mka -j"${BUILD_JOBS:-4}" recoveryimage
    ;;
  package)
    product_root="${source_root}/out/target/product/sm8850"
    python3 "${builder_root}/scripts/verify-image.py" "${product_root}" > "${dist_root}/verification.json"
    cp "${product_root}/recovery.img" "${dist_root}/YARP-sm8850-fb0349d-recovery.img"
    cd "${dist_root}"
    sha256sum YARP-sm8850-fb0349d-recovery.img > SHA256SUMS.txt
    cat verification.json
    ;;
  *)
    printf 'Usage: %s {sync|build|package}\n' "$0" >&2
    exit 2
    ;;
esac
