#!/usr/bin/env bash
# ------------------------------------------------------------------
# @title        Task3_pipes_redirection.sh
# @author       Yusif Ahmed
# @index        7364723
# @school       Kwame Nkrumah University of Science and Technology (KNUST)
# @description  Generates a 50+ line fake log with a heredoc, then uses pipes
#               (grep, sort, uniq -c, wc -l, awk, head) to summarise it.
#               Summary goes to results.txt, errors go to errors.log.
# @date         2026-10-01
# ------------------------------------------------------------------

usage() {
    echo "Usage: $0"
    echo "  Takes no arguments. Creates sample.log, results.txt and errors.log"
    echo "  in the current directory."
    exit "${1:-1}"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    usage 0
fi
if [[ $# -ne 0 ]]; then
    echo "Error: this script takes no arguments." >&2
    usage 1
fi

LOG="sample.log"
RESULTS="results.txt"
ERRLOG="errors.log"

# Start with a clean errors.log so each run is fresh.
: > "$ERRLOG"

# ---- Generate sample data with a heredoc (60 lines) ---------------
# Format: DATE TIME LEVEL IP MESSAGE
# <<'LOGDATA' (quoted) stops the shell from expanding $ or % in the text.
if ! cat > "$LOG" <<'LOGDATA'
2026-09-11 10:03:21 INFO 192.168.1.10 User login successful
2026-09-11 10:03:45 ERROR 192.168.1.23 Connection timeout
2026-09-11 10:04:02 WARN 192.168.1.10 Disk usage above 80%
2026-09-11 10:04:30 INFO 192.168.1.15 File uploaded successfully
2026-09-11 10:05:11 INFO 192.168.1.10 Session started
2026-09-11 10:05:48 ERROR 192.168.1.23 Database connection failed
2026-09-11 10:06:13 INFO 192.168.1.42 User login successful
2026-09-11 10:06:59 WARN 192.168.1.15 High memory usage detected
2026-09-11 10:07:20 INFO 192.168.1.10 Report generated
2026-09-11 10:08:05 ERROR 192.168.1.77 Authentication failed
2026-09-11 10:08:41 INFO 192.168.1.23 User logout
2026-09-11 10:09:17 INFO 192.168.1.42 File downloaded
2026-09-11 10:09:52 WARN 192.168.1.10 CPU usage above 90%
2026-09-11 10:10:30 INFO 192.168.1.15 User login successful
2026-09-11 10:11:08 ERROR 192.168.1.23 Connection timeout
2026-09-11 10:11:45 INFO 192.168.1.10 Backup completed
2026-09-11 10:12:19 WARN 192.168.1.42 Slow response from server
2026-09-11 10:12:54 INFO 192.168.1.77 User login successful
2026-09-11 10:13:33 ERROR 192.168.1.10 Failed to write to disk
2026-09-11 10:14:02 INFO 192.168.1.15 Settings updated
2026-09-11 10:14:40 INFO 192.168.1.23 User login successful
2026-09-11 10:15:16 WARN 192.168.1.10 Disk usage above 85%
2026-09-11 10:15:51 INFO 192.168.1.42 Session started
2026-09-11 10:16:27 ERROR 192.168.1.77 Authentication failed
2026-09-11 10:17:03 INFO 192.168.1.10 File uploaded successfully
2026-09-11 10:17:38 INFO 192.168.1.15 User logout
2026-09-11 10:18:14 WARN 192.168.1.23 Certificate expires soon
2026-09-11 10:18:49 INFO 192.168.1.42 Report generated
2026-09-11 10:19:25 ERROR 192.168.1.10 Service unavailable
2026-09-11 10:20:01 INFO 192.168.1.77 User login successful
2026-09-11 10:20:36 INFO 192.168.1.10 Cache cleared
2026-09-11 10:21:12 WARN 192.168.1.15 Too many open connections
2026-09-11 10:21:47 ERROR 192.168.1.23 Connection timeout
2026-09-11 10:22:23 INFO 192.168.1.42 File downloaded
2026-09-11 10:22:58 INFO 192.168.1.10 User login successful
2026-09-11 10:23:34 WARN 192.168.1.77 Multiple failed login attempts
2026-09-11 10:24:09 INFO 192.168.1.15 Backup completed
2026-09-11 10:24:45 ERROR 192.168.1.10 Failed to write to disk
2026-09-11 10:25:20 INFO 192.168.1.23 Session started
2026-09-11 10:25:56 INFO 192.168.1.42 Settings updated
2026-09-11 10:26:31 WARN 192.168.1.10 Disk usage above 90%
2026-09-11 10:27:07 INFO 192.168.1.15 User login successful
2026-09-11 10:27:42 ERROR 192.168.1.77 Authentication failed
2026-09-11 10:28:18 INFO 192.168.1.10 Report generated
2026-09-11 10:28:53 INFO 192.168.1.23 User logout
2026-09-11 10:29:29 WARN 192.168.1.42 Slow response from server
2026-09-11 10:30:04 INFO 192.168.1.10 File uploaded successfully
2026-09-11 10:30:40 ERROR 192.168.1.23 Database connection failed
2026-09-11 10:31:15 INFO 192.168.1.15 Cache cleared
2026-09-11 10:31:51 INFO 192.168.1.77 User logout
2026-09-11 10:32:26 WARN 192.168.1.10 CPU usage above 95%
2026-09-11 10:33:02 INFO 192.168.1.42 User login successful
2026-09-11 10:33:37 ERROR 192.168.1.10 Service unavailable
2026-09-11 10:34:13 INFO 192.168.1.15 Session started
2026-09-11 10:34:48 INFO 192.168.1.10 Backup completed
2026-09-11 10:35:24 WARN 192.168.1.23 High memory usage detected
2026-09-11 10:35:59 INFO 192.168.1.42 File downloaded
2026-09-11 10:36:35 ERROR 192.168.1.77 Authentication failed
2026-09-11 10:37:10 INFO 192.168.1.10 User logout
LOGDATA
then
    echo "Error: could not create '$LOG'." >&2
    exit 1
fi

# Validate: file must exist and be readable before we analyse it.
if [[ ! -r "$LOG" ]]; then
    echo "Error: '$LOG' is missing or not readable." >&2
    exit 1
fi

# ---- Analysis: every command's stderr is sent to errors.log (2>>) --
# 1. Total lines: 'wc -l < file' prints only the number (no filename).
TOTAL=$(wc -l < "$LOG" 2>>"$ERRLOG")

# 2. Lines per level: field 3 -> sort (uniq needs sorted input) -> count.
LEVELS=$(awk '{print $3}' "$LOG" 2>>"$ERRLOG" | sort 2>>"$ERRLOG" | uniq -c 2>>"$ERRLOG")

# 3. Top 3 IPs: field 4 -> sort -> count -> sort numbers high-to-low -> top 3.
TOPIPS=$(awk '{print $4}' "$LOG" 2>>"$ERRLOG" | sort 2>>"$ERRLOG" | uniq -c 2>>"$ERRLOG" | sort -rn 2>>"$ERRLOG" | head -3 2>>"$ERRLOG")

# 4. ERROR lines only (spaces around ERROR avoid matching it inside messages).
ERRLINES=$(grep " ERROR " "$LOG" 2>>"$ERRLOG")

# ---- Write the report: '>' creates/overwrites, '>>' appends -------
echo "===== LOG SUMMARY REPORT =====" > "$RESULTS"
echo "Source file: $LOG"                  >> "$RESULTS"
echo ""                                   >> "$RESULTS"
echo "1. Total log lines: $TOTAL"         >> "$RESULTS"
echo ""                                   >> "$RESULTS"
echo "2. Lines per log level (count level):" >> "$RESULTS"
echo "$LEVELS"                            >> "$RESULTS"
echo ""                                   >> "$RESULTS"
echo "3. Top 3 IP addresses (count ip):"  >> "$RESULTS"
echo "$TOPIPS"                            >> "$RESULTS"
echo ""                                   >> "$RESULTS"
echo "4. All ERROR lines:"                >> "$RESULTS"
echo "$ERRLINES"                          >> "$RESULTS"

# Show the report on screen too.
cat "$RESULTS"

# Tell the user whether anything went wrong ([ -s ] = file is not empty).
if [[ -s "$ERRLOG" ]]; then
    echo
    echo "[WARN] Some commands reported errors. See '$ERRLOG'."
else
    echo
    echo "[OK] No errors. Report saved to '$RESULTS' ('$ERRLOG' is empty)."
fi

exit 0
