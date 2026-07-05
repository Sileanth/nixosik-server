#!/usr/bin/env bash
set -euo pipefail

main_host="${MAIN_HOST:-main}"
kotek_host="${KOTEK_HOST:-kotek}"
navidrome_state_dir="${NAVIDROME_STATE_DIR:-/var/lib/navidrome}"
acme_env_file="${ACME_ENV_FILE:-/var/lib/bind/acme-rfc2136.env}"
acme_nameserver="${ACME_NAMESERVER:-10.200.0.1:53}"

log() {
  printf '\n==> %s\n' "$*"
}

log "Checking SSH access"
ssh "$main_host" true
ssh "$kotek_host" true

log "Stopping Navidrome on ${main_host}"
ssh "$main_host" "sudo systemctl stop navidrome.service || true"

log "Copying ACME RFC2136 environment to ${kotek_host}"
ssh "$kotek_host" "sudo install -d -m 0755 '${acme_env_file%/*}'"
ssh "$main_host" "sudo cat '${acme_env_file}'" \
  | sed "s/RFC2136_NAMESERVER='[^']*'/RFC2136_NAMESERVER='${acme_nameserver}'/" \
  | ssh "$kotek_host" "sudo tee '${acme_env_file}' >/dev/null"
ssh "$kotek_host" "sudo chown root:root '${acme_env_file}' && sudo chmod 0400 '${acme_env_file}'"

log "Preparing Navidrome state directory on ${kotek_host}"
ssh "$kotek_host" "sudo install -d -m 0755 '${navidrome_state_dir}'"

log "Measuring Navidrome state on ${main_host}"
ssh "$main_host" "sudo du -sh '${navidrome_state_dir}'"

log "Streaming Navidrome state from ${main_host} to ${kotek_host}"
ssh "$main_host" "sudo tar -C '${navidrome_state_dir}' -cpf - ." \
  | dd bs=16M status=progress \
  | ssh "$kotek_host" "sudo tar -C '${navidrome_state_dir}' -xpf -"

log "Fixing Navidrome ownership on ${kotek_host}"
ssh "$kotek_host" "sudo chown -R navidrome:navidrome '${navidrome_state_dir}'"

# log "Starting Navidrome and retrying ACME on ${kotek_host}"
# ssh "$kotek_host" "sudo systemctl start navidrome.service"
# ssh "$kotek_host" "sudo systemctl start acme-order-renew-navidrome.sileanth.pl.service || sudo systemctl status acme-order-renew-navidrome.sileanth.pl.service --no-pager"
# ssh "$kotek_host" "sudo systemctl restart nginx.service"
#
# log "Post-migration status"
# ssh "$main_host" "systemctl is-active navidrome.service || true"
# ssh "$kotek_host" "systemctl is-active navidrome.service nginx.service"
# ssh "$kotek_host" "systemctl status acme-order-renew-navidrome.sileanth.pl.service --no-pager || true"
