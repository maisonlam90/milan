#!/usr/bin/env bash
# setup-dev.sh — Dev env for Rust 1.89 + Yarn user-space
set -euo pipefail

NODE_VERSION="${NODE_VERSION:-20}"
RUST_CHANNEL="${RUST_CHANNEL:-1.89.0}"
SQLX_CLI_VERSION="${SQLX_CLI_VERSION:-0.7.3}"
FRONTEND_DIR="${FRONTEND_DIR:-src/frontend/demo}"
YARN_VERSION="${YARN_VERSION:-1.22.22}"

log()  { printf "\n\033[1;32m[setup]\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m[warn]\033[0m %s\n" "$*"; }

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6 2>/dev/null || echo "$HOME")"

as_user() {
  local cmd="$*"
  if [[ "$USER" == "$REAL_USER" ]]; then
    bash -lc "[ -f \"$REAL_HOME/.cargo/env\" ] && source \"$REAL_HOME/.cargo/env\"; export PATH=\"$REAL_HOME/.local/bin:\$PATH\"; $cmd"
  else
    sudo -u "$REAL_USER" bash -lc "[ -f \"$REAL_HOME/.cargo/env\" ] && source \"$REAL_HOME/.cargo/env\"; export PATH=\"$REAL_HOME/.local/bin:\$PATH\"; $cmd"
  fi
}

append_once() { # append_once <file> <line>
  local f="$1" line="$2"
  [[ -f "$f" ]] || touch "$f"
  grep -Fqx "$line" "$f" || printf "%s\n" "$line" >> "$f"
}

fix_perms() {
  log "Sửa quyền thư mục có thể bị root-own"
  local paths=(
    "$PWD"
    "$FRONTEND_DIR"
    "$FRONTEND_DIR/node_modules"
    "$REAL_HOME/.local" "$REAL_HOME/.npm"
    "$REAL_HOME/.cargo" "$REAL_HOME/.rustup"
  )
  for p in "${paths[@]}"; do
    [[ -e "$p" ]] || continue
    sudo chown -R "$REAL_USER":"$REAL_USER" "$p" || true
  done
}

install_base_deps() {
  if command -v apt-get >/dev/null 2>&1; then
    log "Cài base deps (sudo apt)"
    sudo apt-get update -y
    sudo apt-get install -y --no-install-recommends \
      ca-certificates curl git build-essential pkg-config libssl-dev openssl
  elif command -v brew >/dev/null 2>&1; then
    log "Cài base deps (brew)"
    brew install curl git openssl@3 pkg-config
  fi
}

ensure_rust_for_user() {
  if sudo test -x /root/.cargo/bin/rustup; then
    log "Gỡ rustup/cargo cài dưới root"
    sudo /root/.cargo/bin/rustup self uninstall -y || true
    sudo rm -rf /root/.cargo /root/.rustup || true
  fi
  if ! as_user "command -v rustup >/dev/null 2>&1"; then
    log "Cài rustup cho user '$REAL_USER'"
    as_user "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal"
  fi
  append_once "$REAL_HOME/.bashrc" 'source "$HOME/.cargo/env"'
  append_once "$REAL_HOME/.zshrc"  'source "$HOME/.cargo/env"'
}

pin_rust_toolchain() {
  log "Pin Rust ${RUST_CHANNEL}"
  as_user "cat > '$PWD/rust-toolchain.toml' <<EOF
[toolchain]
channel = \"${RUST_CHANNEL}\"
components = [\"rustfmt\", \"clippy\"]
EOF"
  as_user "rustup toolchain install '${RUST_CHANNEL}' --profile minimal --component rustfmt --component clippy"
  as_user "rustup override set '${RUST_CHANNEL}'"
  as_user "rustc --version && cargo --version"
}

install_node_and_yarn() {
  if ! command -v node >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
      log "Cài Node.js ${NODE_VERSION}"
      curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | sudo -E bash -
      sudo apt-get install -y nodejs npm
    elif command -v brew >/dev/null 2>&1; then
      brew install "node@${NODE_VERSION}"
      brew link --overwrite --force "node@${NODE_VERSION}" || true
    fi
  fi

  log "Cài Yarn ${YARN_VERSION} cho user (không sudo)"
  as_user 'mkdir -p "$HOME/.local/bin"'
  append_once "$REAL_HOME/.bashrc" 'export PATH="$HOME/.local/bin:$PATH"'
  append_once "$REAL_HOME/.profile" 'export PATH="$HOME/.local/bin:$PATH"'
  append_once "$REAL_HOME/.zshrc"  'export PATH="$HOME/.local/bin:$PATH"'

  as_user "npm config set prefix '$HOME/.local'"
  as_user "npm install -g yarn@${YARN_VERSION}"
  as_user "yarn -v"
}

yarn_install_fe_only() {
  if [[ -d "$FRONTEND_DIR" ]]; then
    log "yarn install tại $FRONTEND_DIR"
    sudo chown -R "$REAL_USER":"$REAL_USER" "$FRONTEND_DIR" || true
    if as_user "test -f '$FRONTEND_DIR/yarn.lock'"; then
      as_user "cd '$FRONTEND_DIR' && yarn install --frozen-lockfile"
    else
      as_user "cd '$FRONTEND_DIR' && yarn install"
    fi
  else
    warn "Không thấy thư mục frontend: $FRONTEND_DIR — bỏ qua yarn install."
  fi
}

install_sqlx_cli() {
  log "Cài sqlx-cli v${SQLX_CLI_VERSION}"
  as_user "cargo install sqlx-cli --version '${SQLX_CLI_VERSION}' --no-default-features --features postgres --locked || true"
}

cargo_build_release() {
  log "Build Rust project (release)"
  fix_perms
  as_user "cd '$PWD'; cargo build --release"
}

main() {
  install_base_deps
  fix_perms
  ensure_rust_for_user
  pin_rust_toolchain
  install_node_and_yarn
  yarn_install_fe_only
  install_sqlx_cli
  cargo_build_release
  log "Hoàn tất 🎉 — Yarn trong ~/.local/bin, Cargo trong ~/.cargo. PATH đã thêm cho bash/zsh/profile."
}

main "$@"
