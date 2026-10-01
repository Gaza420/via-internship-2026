#!/usr/bin/env bash
# ------------------------------------------------------------------
# @title        Task2_permissions_sudo.sh
# @author       Yusif Ahmed
# @index        7364723
# @school       Kwame Nkrumah University of Science and Technology (KNUST)
# @description  Reports a file's permissions (symbolic + numeric), changes
#               them with chmod (numeric and symbolic), tries chown only if
#               run as root, and reports the permissions again (before/after).
# @date         2026-10-01
# ------------------------------------------------------------------

# Exit codes: 0 ok | 1 bad/missing argument | 2 file not found | 3 chmod failed

usage() {
    echo "Usage: $0 <file-path>"
    echo "  <file-path>  path of the file whose permissions will be reported/changed"
    exit "${1:-1}"
}

# Show owner/group/others in symbolic and numeric form.
# stat -c '%A' -> rwxr-xr-x   stat -c '%a' -> 755
report_perms() {
    local label="$1"
    local sym num owner group
    sym=$(stat -c '%A' "$FILE" 2>/dev/null)
    num=$(stat -c '%a' "$FILE" 2>/dev/null)
    owner=$(stat -c '%U' "$FILE" 2>/dev/null)
    group=$(stat -c '%G' "$FILE" 2>/dev/null)
    if [[ -z "$sym" || -z "$num" ]]; then
        echo "Error: could not read permissions of '$FILE'." >&2
        exit 2
    fi
    echo "===== $label ====="
    echo "File     : $FILE"
    echo "Symbolic : $sym   Numeric: $num"
    # ${sym:1:3} = characters 2-4 (owner), ${sym:4:3} = group, ${sym:7:3} = others
    echo "Owner    : $owner  (${sym:1:3})"
    echo "Group    : $group  (${sym:4:3})"
    echo "Others   : ${sym:7:3}"
}

# ---- Argument handling -------------------------------------------
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage 0
fi
if [[ $# -ne 1 || -z "$1" ]]; then
    echo "Error: exactly one non-empty argument is required." >&2
    usage 1
fi

FILE="$1"

# Validate input before touching anything.
if [[ ! -e "$FILE" ]]; then
    echo "Error: '$FILE' does not exist." >&2
    exit 2
fi

# ---- 1. Report current permissions (BEFORE) -----------------------
report_perms "BEFORE changes"

# ---- 2a. chmod with NUMERIC mode: 644 = rw-r--r-- ------------------
echo
if chmod 644 "$FILE" 2>/dev/null; then
    echo "[OK] chmod 644 applied (numeric): owner rw-, group r--, others r--"
else
    echo "Error: chmod 644 failed on '$FILE'." >&2
    exit 3
fi

# ---- 2b. chmod with SYMBOLIC mode: u+x = give owner execute --------
if chmod u+x "$FILE" 2>/dev/null; then
    echo "[OK] chmod u+x applied (symbolic): owner now has execute"
else
    echo "Error: chmod u+x failed on '$FILE'." >&2
    exit 3
fi

# ---- 3. chown only works as root, so check first (id -u == 0) -----
echo
if [[ "$(id -u)" -eq 0 ]]; then
    # Under sudo, give the file to the real user who called sudo.
    NEW_OWNER="${SUDO_USER:-root}"
    if chown "$NEW_OWNER" "$FILE" 2>/dev/null; then
        echo "[OK] chown succeeded: owner is now '$NEW_OWNER'."
    else
        echo "[FAIL] chown to '$NEW_OWNER' failed (continuing)." >&2
    fi
else
    # Not root: skip gracefully (do NOT crash).
    echo "[SKIPPED] chown step skipped: root privileges are needed (run with sudo)."
fi

# ---- 4. Report permissions again (AFTER) --------------------------
echo
report_perms "AFTER changes"

exit 0
