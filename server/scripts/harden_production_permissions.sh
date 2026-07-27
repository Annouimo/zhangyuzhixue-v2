#!/bin/bash
# Run as root on the production host after reviewing the resolved paths below.

set -euo pipefail

DEPLOY_DIR="/opt/zhangyuzhixue-v2"
CLOUDFLARED_DIR="/root/.cloudflared"
CLOUDFLARED_CONFIG="/etc/cloudflared/config.yml"

require_file() {
    if [[ ! -f "$1" ]]; then
        echo "Required file not found: $1" >&2
        exit 1
    fi
}

require_file "$DEPLOY_DIR/server/.env"
require_file "$CLOUDFLARED_CONFIG"
require_file "/etc/systemd/system/cloudflared-zhangyuzhixue.service"

mapfile -t credential_files < <(
    find "$CLOUDFLARED_DIR" -maxdepth 1 -type f -name '*.json' -print
)
if [[ ${#credential_files[@]} -eq 0 ]]; then
    echo "No cloudflared credential JSON found in $CLOUDFLARED_DIR" >&2
    exit 1
fi

mapfile -t private_keys < <(
    find /etc/letsencrypt/live -type l -name 'privkey.pem' -print
)
if [[ ${#private_keys[@]} -eq 0 ]]; then
    echo "No Let's Encrypt private keys found" >&2
    exit 1
fi

echo "Restricting production secret files:"
printf '  %s\n' "$DEPLOY_DIR/server/.env" "$CLOUDFLARED_CONFIG"
printf '  %s\n' "${credential_files[@]}" "${private_keys[@]}"

chown ubuntu:ubuntu "$DEPLOY_DIR/server/.env"
chmod 600 "$DEPLOY_DIR/server/.env"
chown root:root "$CLOUDFLARED_CONFIG" "${credential_files[@]}"
chmod 600 "$CLOUDFLARED_CONFIG" "${credential_files[@]}"
chown root:root /etc/systemd/system/cloudflared-zhangyuzhixue.service
chmod 644 /etc/systemd/system/cloudflared-zhangyuzhixue.service

for link in "${private_keys[@]}"; do
    target="$(readlink -f "$link")"
    case "$target" in
        /etc/letsencrypt/archive/*/privkey*.pem) ;;
        *)
            echo "Unexpected private-key target: $target" >&2
            exit 1
            ;;
    esac
    chown root:root "$target"
    chmod 600 "$target"
done

echo "Result:"
stat -c '%a %U:%G %n' \
    "$DEPLOY_DIR/server/.env" \
    "$CLOUDFLARED_CONFIG" \
    "${credential_files[@]}"
for link in "${private_keys[@]}"; do
    stat -Lc '%a %U:%G %n' "$link"
done
