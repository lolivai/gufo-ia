{ rustPlatform }:

let
  vendor = rustPlatform.importCargoLock {
    lockFile = ../../src/core/png_decode/Cargo.lock;
  };
in
''
  export CARGO_HOME="$TMPDIR/cargo-home"
  mkdir -p "$CARGO_HOME"
  cat > "$CARGO_HOME/config.toml" <<CARGO_CONFIG
  [source.crates-io]
  replace-with = "vendored-sources"
  [source.vendored-sources]
  directory = "${vendor}"
  [net]
  offline = true
  CARGO_CONFIG

  # CI exposes a persistent /tmp/gufo-sccache through extra-sandbox-paths,
  # mirroring the ccache policy for C/C++: Rust crate objects survive source
  # revisions as long as the toolchain and Cargo.lock do not change. Cargo
  # fingerprints must stay path-stable, so incremental compilation (whose
  # objects sccache cannot cache anyway) is off for these builds.
  sccache_dir=/tmp/gufo-sccache
  if command -v sccache >/dev/null 2>&1 && [[ -d "$sccache_dir" && -w "$sccache_dir" ]]; then
    export SCCACHE_DIR="$sccache_dir"
    export SCCACHE_IDLE_TIMEOUT=0
    export CARGO_INCREMENTAL=0
    export RUSTC_WRAPPER=sccache
    sccache --zero-stats
  fi
''
