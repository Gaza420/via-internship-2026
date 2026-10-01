#!/usr/bin/env bash
# ------------------------------------------------------------------
# @title        Task4_return_codes_error_handling.sh
# @author       Yusif Ahmed
# @index        7364723
# @school       Kwame Nkrumah University of Science and Technology (KNUST)
# @description  Runs 4 checks (host reachable, free disk space, required file
#               readable, required command installed). A helper function
#               check_status reads $? and exits with a specific exit code on
#               failure. A trap cleans up the temp file on any exit.
# @date         2026-10-01
# ------------------------------------------------------------------

# Exit codes:
#   0 = all checks passed
#   1 = missing required argument
#   2 = host unreachable
#   3 = insufficient disk space
#   4 = required file not found
#   5 = required command not found

usage() {
    echo "Usage: $0 <hostname>"
    echo "  <hostname>  host to check connectivity to (e.g. google.com)"
    exit "${1:-1}"
}

# ---- Settings you can change --------------------------------------
REQUIRED_FILE="/etc/hosts"   # file that must exist and be readable
REQUIRED_CMD="curl"          # command that must be installed
MIN_FREE_MB=100              # minimum free space (MB) on /

# ---- Temp file + trap ---------------------------------------------
# Temp file holds the report of checks. The trap runs cleanup() when the
# script ends for ANY reason: success, failure (exit N), or Ctrl+C.
TMP_FILE=$(mktemp) || { echo "Error: cannot create temp file." >&2; exit 1; }

cleanup() {
    rm -f "$TMP_FILE"
}
trap cleanup EXIT
# On Ctrl+C / kill, call exit so the EXIT trap above also fires.
trap 'echo; echo "Interrupted. Cleaning up..." >&2; exit 130' INT TERM

# ---- Helper: check_status ------------------------------------------
# $1 = the result code ($?) of the check
# $2 = description of the check
# $3 = exit code to use if the check FAILED
check_status() {
    local rc="$1" desc="$2" fail_code="$3"
    if [[ "$rc" -eq 0 ]]; then
        echo "[PASS] $desc" | tee -a "$TMP_FILE"
    else
        echo "[FAIL] $desc" | tee -a "$TMP_FILE" >&2
        echo "Error: check failed, exiting with code $fail_code." >&2
        exit "$fail_code"
    fi
}

# ---- Argument handling -------------------------------------------
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage 0
fi
if [[ $# -ne 1 || -z "$1" ]]; then
    echo "Error: missing required argument <hostname>." >&2
    usage 1
fi

HOST="$1"
echo "Running checks against host: $HOST"
echo "-------------------------------------------"

# ---- Check 1: host reachable (1 packet, wait max 2 seconds) --------
ping -c 1 -W 2 "$HOST" > /dev/null 2>&1
check_status $? "Host '$HOST' is reachable" 2

# ---- Check 2: enough free disk space on / --------------------------
# df -Pm prints sizes in MB; line 2, column 4 is the 'Available' value.
FREE_MB=$(df -Pm / 2>/dev/null | awk 'NR==2 {print $4}')
if [[ "$FREE_MB" =~ ^[0-9]+$ ]] && (( FREE_MB >= MIN_FREE_MB )); then
    DISK_RC=0
else
    DISK_RC=1
fi
check_status "$DISK_RC" "Free disk space on / is ${FREE_MB:-unknown} MB (need >= ${MIN_FREE_MB} MB)" 3

# ---- Check 3: required file exists AND is readable ----------------
[[ -f "$REQUIRED_FILE" && -r "$REQUIRED_FILE" ]]
check_status $? "File '$REQUIRED_FILE' exists and is readable" 4

# ---- Check 4: required command installed ---------------------------
command -v "$REQUIRED_CMD" > /dev/null 2>&1
check_status $? "Command '$REQUIRED_CMD' is installed" 5

# ---- All good ------------------------------------------------------
echo "-------------------------------------------"
echo "Summary (read back from temp file):"
cat "$TMP_FILE"
echo "All checks passed."
exit 0
