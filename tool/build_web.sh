#!/usr/bin/env bash
# Build Lullaby's PWA with the sync kernel's WASM beside it (ADR-0007).
#
# hearth_sync's web bridge loads web/pkg/hearth_sync_bridge.{js,_bg.wasm}. They
# are built here from the sibling ../hearthSync checkout, single-threaded with
# non-shared memory, so the PWA needs no COOP/COEP headers (GitHub Pages cannot
# send them); see ../hearthSync/flutter/hearth_sync/example/tool/build_web.sh,
# whose recipe this is. web/pkg/ is a build output and is git-ignored.
#
# Extra arguments go to `flutter build web` (e.g. --base-href /Lullaby/).
set -euo pipefail
cd "$(dirname "$0")/.."
hs="$(cd ../hearthSync && pwd)"
export WASM_PACK_CACHE="$hs/.tools/wasm-pack-cache"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$hs/flutter/hearth_sync/rust/target}"
"$hs/.tools/bin/wasm-pack" build -t no-modules -d "$PWD/web/pkg" --no-typescript \
  --out-name hearth_sync_bridge --release "$hs/flutter/hearth_sync/rust"
rm -f web/pkg/.gitignore web/pkg/package.json
flutter build web --release --no-web-resources-cdn "$@"
