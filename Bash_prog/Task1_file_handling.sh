#!/usr/bin/env bash
# ------------------------------------------------------------------
# @title        Task1_file_handling.sh
# @author       Yusif Ahmed
# @index        7364723
# @school       Kwame Nkrumah University of Science and Technology (KNUST)
# @description  Creates a directory, creates/appends/reads a file in it,
#               backs the file up to .bak, then deletes the original after
#               checking it exists and asking for confirmation.
# @date         2026-10-01
# ------------------------------------------------------------------

# Print help text. $1 = exit code to use (default 1).
usage() {
    echo "Usage: $0 <target-directory>"
    echo "  <target-directory>  directory to create and work in"
    exit "${1:-1}"
}

# Print an error to stderr and stop the script (so we don't continue
# and produce confusing downstream errors).
fail() {
    echo "Error: $1" >&2
    exit 1
}

# ---- Argument handling -------------------------------------------
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage 0
fi
if [[ $# -ne 1 || -z "$1" ]]; then
    echo "Error: exactly one non-empty argument is required." >&2
    usage 1
fi

DIR="$1"
FILE="$DIR/notes.txt"
BAK="$FILE.bak"

# Validate input: the path must not already exist as a regular file.
if [[ -e "$DIR" && ! -d "$DIR" ]]; then
    fail "'$DIR' exists but is not a directory."
fi

# ---- Step 1: create directory (report created vs already existed) -
# We check BEFORE mkdir -p, because mkdir -p succeeds either way and
# would not tell us which case happened.
if [[ -d "$DIR" ]]; then
    echo "[INFO] Directory '$DIR' already existed."
else
    if mkdir -p "$DIR" 2>/dev/null; then
        echo "[OK] Directory '$DIR' was created."
    else
        fail "could not create directory '$DIR' (permission denied?)."
    fi
fi

# ---- Step 2: create the file and write content (> overwrites) -----
if echo "Line 1: file created by Task1_file_handling.sh" > "$FILE" 2>/dev/null; then
    echo "[OK] File '$FILE' created and written."
else
    fail "could not write to '$FILE'."
fi

# ---- Step 3: append more content (>> adds to the end) -------------
if echo "Line 2: this line was appended." >> "$FILE" 2>/dev/null; then
    echo "[OK] Extra content appended."
else
    fail "could not append to '$FILE'."
fi

# ---- Step 4: read and display the file ----------------------------
echo "---------- contents of $FILE ----------"
if cat "$FILE"; then
    echo "---------- end of file ----------"
else
    fail "could not read '$FILE'."
fi

# ---- Step 5: copy to .bak -----------------------------------------
if cp "$FILE" "$BAK" 2>/dev/null; then
    echo "[OK] Backup created: '$BAK'."
else
    fail "could not create backup '$BAK'."
fi

# ---- Step 6: delete original, but ONLY after checking + confirming -
if [[ -f "$FILE" ]]; then
    # '|| ans=n' means: if input is closed (no keyboard), default to No.
    read -r -p "Delete '$FILE'? (y/n): " ans || ans="n"
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        if rm "$FILE" 2>/dev/null; then
            echo "[OK] '$FILE' deleted. Backup '$BAK' is still there."
        else
            fail "could not delete '$FILE'."
        fi
    else
        echo "[INFO] Deletion cancelled. Original file kept."
    fi
else
    fail "'$FILE' does not exist, so there is nothing to delete."
fi

exit 0
