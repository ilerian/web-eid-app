#!/usr/bin/env bash
set -uo pipefail

PKCS11_LIB="/Library/akis/libakisp11.dylib"
PKCS11_TOOL="/usr/local/bin/pkcs11-tool"
OPENSSL="/usr/local/opt/openssl@3/bin/openssl"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

PIN=""

pk() { arch -x86_64 "$PKCS11_TOOL" --module "$PKCS11_LIB" "$@"; }

ensure_pin() {
  if [[ -z "$PIN" ]]; then
    read -rs -p "AKIS user PIN: " PIN
    echo
  fi
}

show_token() {
  pk -T 2>&1 | grep -E "token label|token flags|pin min/max|serial num" | sed 's/^/  /'
}

list_objects() {
  read -r -p "Login for private objects too? (y/N): " yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    ensure_pin
    pk --list-objects --login --pin "$PIN"
  else
    pk --list-objects
  fi
}

add_pfx() {
  local pfx pw label key cert id size
  read -r -p "PFX file path: " pfx
  pfx="${pfx/#\~/$HOME}"
  [[ -f "$pfx" ]] || { echo "Not found: $pfx"; return 1; }
  read -rs -p "PFX password: " pw; echo
  read -r -p "Card label: " label
  [[ -n "$label" ]] || { echo "Label required."; return 1; }

  key="$TMP_DIR/key.der"
  cert="$TMP_DIR/cert.der"
  : > "$key"; : > "$cert"

  "$OPENSSL" pkcs12 -in "$pfx" -passin "pass:$pw" -nocerts -nodes -legacy 2>/dev/null \
    | "$OPENSSL" pkcs8 -topk8 -nocrypt -outform DER -out "$key" 2>/dev/null
  "$OPENSSL" pkcs12 -in "$pfx" -passin "pass:$pw" -clcerts -nokeys -legacy 2>/dev/null \
    | "$OPENSSL" x509 -outform DER -out "$cert" 2>/dev/null

  if [[ ! -s "$key" || ! -s "$cert" ]]; then
    echo "Extract failed — wrong password or unsupported PFX."
    return 1
  fi

  echo "--- Certificate ---"
  "$OPENSSL" x509 -in "$cert" -inform DER -noout -subject -issuer -dates
  size=$("$OPENSSL" pkey -in "$key" -inform DER -text -noout 2>&1 | head -1)
  echo "--- Key ---"
  echo "  $size"

  if ! echo "$size" | grep -qi "Private-Key: ([0-9]\+ bit, [0-9]\+ primes)"; then
    echo "  WARNING: key is not RSA. AKIS V1.2 supports RSA only (≤2048)."
  fi

  id=$("$OPENSSL" x509 -in "$cert" -inform DER -noout -pubkey \
        | "$OPENSSL" pkey -pubin -outform DER \
        | "$OPENSSL" dgst -sha1 -binary | xxd -p -c 256)
  echo "--- Import ---"
  echo "  ID:    $id"
  echo "  Label: $label"
  read -r -p "Proceed? (y/N): " yn
  [[ "$yn" =~ ^[Yy]$ ]] || { echo "Cancelled."; return 0; }

  ensure_pin
  pk --login --pin "$PIN" --write-object "$key"  --type privkey --id "$id" --label "$label" || return 1
  pk --login --pin "$PIN" --write-object "$cert" --type cert    --id "$id" --label "$label" || return 1
  echo "Done."
}

delete_object() {
  echo "--- Current objects ---"
  pk --list-objects | grep -E "label:|ID:|type =" | sed 's/^/  /'
  echo
  echo "Match by:"
  echo "  l) label"
  echo "  i) ID (hex)"
  read -r -p "> " mode
  local arg flag
  case "$mode" in
    l|L) read -r -p "Label: " arg; flag="--label" ;;
    i|I) read -r -p "ID (hex): " arg; flag="--id" ;;
    *) echo "Cancelled."; return 0 ;;
  esac
  [[ -n "$arg" ]] || { echo "Empty."; return 1; }

  read -r -p "Also delete privkey + pubkey under the same ${flag#--}? (Y/n): " yn
  local types=("cert")
  [[ ! "$yn" =~ ^[Nn]$ ]] && types=(cert privkey pubkey)

  read -r -p "Confirm delete ${flag#--}=$arg (${types[*]})? (y/N): " yn
  [[ "$yn" =~ ^[Yy]$ ]] || { echo "Cancelled."; return 0; }

  ensure_pin
  for t in "${types[@]}"; do
    local out
    out=$(pk --login --pin "$PIN" --delete-object --type "$t" "$flag" "$arg" 2>&1)
    if echo "$out" | grep -q "error:"; then
      echo "  $t: $(echo "$out" | grep error: | head -1)"
    else
      echo "  $t: deleted"
    fi
  done
}

generate_keypair() {
  local id label bits
  read -r -p "Key size (default 2048): " bits
  bits="${bits:-2048}"
  read -r -p "Label: " label
  [[ -n "$label" ]] || { echo "Label required."; return 1; }
  id=$(openssl rand -hex 20)
  echo "  ID: $id"
  read -r -p "Proceed with on-card RSA-$bits keygen? (y/N): " yn
  [[ "$yn" =~ ^[Yy]$ ]] || return 0
  ensure_pin
  pk --login --pin "$PIN" --keypairgen --key-type "rsa:$bits" --id "$id" --label "$label"
}

menu() {
  echo "AKIS card management"
  echo "  lib: $PKCS11_LIB"
  show_token
  while true; do
    echo
    echo "  1) List objects"
    echo "  2) Add cert + private key from PFX"
    echo "  3) Delete object"
    echo "  4) Generate on-card RSA keypair (no cert)"
    echo "  5) Forget cached PIN"
    echo "  q) Quit"
    read -r -p "> " choice
    case "$choice" in
      1) list_objects ;;
      2) add_pfx ;;
      3) delete_object ;;
      4) generate_keypair ;;
      5) PIN=""; echo "PIN forgotten." ;;
      q|Q|"") exit 0 ;;
      *) echo "Unknown." ;;
    esac
  done
}

menu
