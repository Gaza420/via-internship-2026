#!/usr/bin/env bash
# ------------------------------------------------------------------
# @title        Task5_crud_app.sh
# @author       Yusif Ahmed
# @index        7364723
# @school       Kwame Nkrumah University of Science and Technology (KNUST)
# @description  Menu-driven Todo List (Create, Read, Update, Delete) in the
#               terminal. Data is stored in todo_data.txt next to the script,
#               one task per line: ID|description|status|due-date
# @date         2026-10-01
# ------------------------------------------------------------------

# Exit codes: 0 normal exit | 1 bad usage | 2 data file problem

usage() {
    echo "Usage: $0"
    echo "  Starts an interactive Todo List menu. No arguments needed."
    echo "  Data file: todo_data.txt (stored next to this script)"
    exit "${1:-1}"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage 0
fi
if [[ $# -ne 0 ]]; then
    echo "Error: this script takes no arguments." >&2
    usage 1
fi

# Data file lives next to the script, no matter where we run it from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_FILE="$SCRIPT_DIR/todo_data.txt"
BACKUP_FILE="$DATA_FILE.bak"

# ------------------------- helper functions -------------------------

# Create the data file if it does not exist yet.
init_data_file() {
    if [[ ! -f "$DATA_FILE" ]]; then
        if ! touch "$DATA_FILE" 2>/dev/null; then
            echo "Error: cannot create data file '$DATA_FILE'." >&2
            exit 2
        fi
    fi
}

# Remove spaces from both ends of a string.
trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    echo "$s"
}

# Keep asking until the user types something non-empty.
# '|' is our field separator, so it is not allowed inside text.
# Result is stored in the global variable ANSWER.
ask_required() {
    local prompt="$1" val
    while true; do
        read -r -p "$prompt" val || { echo; echo "Input closed. Bye."; exit 0; }
        val="$(trim "$val")"
        if [[ -z "$val" ]]; then
            echo "  Error: this field cannot be empty. Try again."
        elif [[ "$val" == *"|"* ]]; then
            echo "  Error: the '|' character is not allowed. Try again."
        else
            ANSWER="$val"
            return 0
        fi
    done
}

# Does a task with this ID exist? (^ID| matches the start of a line)
id_exists() {
    grep -q "^$1|" "$DATA_FILE"
}

# Next ID = highest existing ID + 1.
next_id() {
    awk -F'|' 'BEGIN{m=0} $1+0>m {m=$1+0} END{print m+1}' "$DATA_FILE"
}

# Copy the data file to .bak BEFORE any update/delete.
backup_data() {
    if cp "$DATA_FILE" "$BACKUP_FILE" 2>/dev/null; then
        echo "  [Backup saved: $BACKUP_FILE]"
        return 0
    fi
    echo "  Error: backup failed, change cancelled." >&2
    return 1
}

# Ask for a numeric ID and make sure it exists. Result in global TARGET_ID.
ask_existing_id() {
    local id
    read -r -p "Enter task ID: " id || { echo; exit 0; }
    id="$(trim "$id")"
    if [[ ! "$id" =~ ^[0-9]+$ ]]; then
        echo "  Error: ID must be a number."
        return 1
    fi
    if ! id_exists "$id"; then
        echo "  Record not found: no task with ID $id."
        return 1
    fi
    TARGET_ID="$id"
    return 0
}

# ------------------------- CRUD operations --------------------------

# CREATE
add_task() {
    local desc due id
    echo "--- Add a task ---"
    ask_required "Task description: "
    desc="$ANSWER"

    read -r -p "Due date YYYY-MM-DD (optional, Enter to skip): " due || due=""
    due="$(trim "$due")"
    if [[ -n "$due" && ! "$due" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "  Error: invalid date format. Task not added."
        return
    fi

    id="$(next_id)"
    if echo "$id|$desc|pending|$due" >> "$DATA_FILE" 2>/dev/null; then
        echo "  Task #$id added."
    else
        echo "  Error: could not write to data file." >&2
    fi
}

# READ (list)
list_tasks() {
    echo "--- All tasks ---"
    if [[ ! -s "$DATA_FILE" ]]; then
        echo "  (no tasks yet)"
        return
    fi
    awk -F'|' 'BEGIN{printf "%-4s %-35s %-8s %s\n","ID","TASK","STATUS","DUE"}
               {printf "%-4s %-35s %-8s %s\n",$1,$2,$3,$4}' "$DATA_FILE"
}

# READ (search by keyword in the description)
search_tasks() {
    local kw result
    echo "--- Search tasks ---"
    ask_required "Keyword: "
    kw="$ANSWER"
    # ENVIRON passes the keyword safely (no quote/backslash problems).
    result=$(KW="$kw" awk -F'|' 'index(tolower($2), tolower(ENVIRON["KW"])) {
                 printf "%-4s %-35s %-8s %s\n",$1,$2,$3,$4}' "$DATA_FILE")
    if [[ -z "$result" ]]; then
        echo "  No tasks match '$kw'."
    else
        echo "$result"
    fi
}

# UPDATE
update_task() {
    local desc status tmp
    echo "--- Update a task ---"
    ask_existing_id || return

    ask_required "New description: "
    desc="$ANSWER"

    while true; do
        read -r -p "New status (pending/done): " status || { echo; exit 0; }
        status="$(trim "${status,,}")"
        [[ "$status" == "pending" || "$status" == "done" ]] && break
        echo "  Error: status must be 'pending' or 'done'."
    done

    backup_data || return

    tmp=$(mktemp) || { echo "  Error: cannot create temp file." >&2; return; }
    # Rewrite every line; only the matching ID gets new values.
    TARGET_ID="$TARGET_ID" NEW_DESC="$desc" NEW_STATUS="$status" \
    awk -F'|' 'BEGIN{OFS="|"}
        $1==ENVIRON["TARGET_ID"] {$2=ENVIRON["NEW_DESC"]; $3=ENVIRON["NEW_STATUS"]}
        {print}' "$DATA_FILE" > "$tmp" \
    && mv "$tmp" "$DATA_FILE" \
    && echo "  Task #$TARGET_ID updated." \
    || { echo "  Error: update failed." >&2; rm -f "$tmp"; }
}

# DELETE
delete_task() {
    local confirm tmp
    echo "--- Delete a task ---"
    ask_existing_id || return

    read -r -p "Really delete task #$TARGET_ID? (y/n): " confirm || confirm="n"
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "  Deletion cancelled."
        return
    fi

    backup_data || return

    tmp=$(mktemp) || { echo "  Error: cannot create temp file." >&2; return; }
    # grep -v keeps every line EXCEPT the one starting with this ID.
    # (grep exits 1 when nothing is left, which is fine here.)
    grep -v "^$TARGET_ID|" "$DATA_FILE" > "$tmp"
    if mv "$tmp" "$DATA_FILE"; then
        echo "  Task #$TARGET_ID deleted."
    else
        echo "  Error: delete failed." >&2
        rm -f "$tmp"
    fi
}

# ------------------------------ main --------------------------------
init_data_file

while true; do
    echo
    echo "========= TODO LIST ========="
    echo " 1) Add task"
    echo " 2) View / List tasks"
    echo " 3) Search tasks"
    echo " 4) Update task"
    echo " 5) Delete task"
    echo " 6) Exit"
    echo "============================="
    read -r -p "Choose an option [1-6]: " choice || { echo; echo "Input closed. Bye."; exit 0; }

    case "$(trim "$choice")" in
        1) add_task ;;
        2) list_tasks ;;
        3) search_tasks ;;
        4) update_task ;;
        5) delete_task ;;
        6) echo "Goodbye!"; exit 0 ;;
        *) echo "  Invalid option. Please enter a number from 1 to 6." ;;
    esac
done
