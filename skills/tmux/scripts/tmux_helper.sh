#!/usr/bin/env bash
# tmux_helper.sh — tmux interaction helpers for Claude Code
#
# Uses a marker-based protocol for `run`: unique BEGIN/END markers are printed
# around the command so we can reliably extract output and exit codes without
# guessing prompts or polling pane_current_command.
#
# Commands:
#   run <target> <command>
#       Send a command wrapped in BEGIN/END markers. Blocks until the END marker
#       appears. Returns the command's actual exit code. Prints only the command's
#       output (between the markers).
#       Requires a POSIX-like shell (bash, zsh, sh, dash) in the target pane.
#
#   send <target> <prompt_regex> <command>
#       Send a command to an interactive program and block until the prompt
#       reappears on the last non-empty line. Prints new output since the command.
#       Heuristic — works for line-oriented, echoing REPLs with stable prompts.
#
#   wait-for <target> <grep_pattern>
#       Block until a NEW line matching the pattern appears in the pane (ignores
#       content already present when called). Prints the matching line.
#       Best for: servers ("Server ready"), logs ("ERROR"), build milestones.
#
#   wait <target> <prompt_regex>
#       Block until the prompt appears (no command sent).
#       Prints the last few lines of context.
#
#   read <target> [lines]
#       Capture the last N lines of the pane (default 30). No waiting.
#
#   interrupt <target>
#       Send Ctrl-C to the pane.
#
# Environment:
#   TMUX_WAIT_TIMEOUT=15    Max seconds to wait (default 15)
#   TMUX_WAIT_POLL=0.05     Poll interval in seconds (default 0.05)
#
# Exit codes (process exit — reserved for helper status only):
#   0 = success (for `run`, the command's exit code is on the last stdout line)
#   124 = timeout (check pane with `read` to see what's blocking)
#   125 = target lost (pane/window/session was killed)
#   126 = extraction error (BEGIN marker scrolled out of scrollback)
#
# For `run`, the command's actual exit code is printed as the LAST line of
# stdout in the format: __EXIT:<code>
# This avoids collision with helper exit codes (a command exiting 124 won't
# be confused with a timeout). Parse it like:
#   output=$(bash "$HELPER" run target 'cmd')
#   cmd_exit=$(echo "$output" | tail -1 | sed 's/__EXIT://')
#   cmd_output=$(echo "$output" | sed '$d')

set -uo pipefail

TIMEOUT="${TMUX_WAIT_TIMEOUT:-15}"
POLL="${TMUX_WAIT_POLL:-0.05}"

# Capture pane content with joined wrapped lines (-J), preserving blank lines.
# Strips only trailing blank lines at the end of the capture.
_capture() {
    local out
    if ! out=$(tmux capture-pane -t "$1" -p -J -S - 2>&1); then
        return 125
    fi
    echo "$out" | sed -e :a -e '/^[[:space:]]*$/{ $d; N; ba; }'
}

# Check if the target pane still exists
_target_exists() {
    tmux display-message -t "$1" -p '#{pane_id}' >/dev/null 2>&1
}

# Generate a unique marker ID
_marker_id() {
    echo "__TMUX_${$}_${RANDOM}_$(date +%s%N)__"
}

# ── run: marker-based protocol ──────────────────────────────────────────────
#
# Wraps the command in BEGIN/END markers. Polls for END, then extracts output
# from the SAME capture that saw END (no re-capture race). Returns the actual
# exit code embedded in the END marker.

cmd_run() {
    local target="$1" command="$2"
    local marker
    marker=$(_marker_id)

    # Send the command wrapped in BEGIN/END markers with exit code
    tmux send-keys -t "$target" \
        "printf '\\n%s\\n' '$marker BEGIN'; { $command; }; __rc=\$?; printf '%s %s\\n' '$marker END' \"\$__rc\"" Enter

    # Poll for the END marker — preserve the capture that matched
    local matched_capture=""
    local rc=0
    timeout "$TIMEOUT" bash -c '
        target="$1"; marker="$2"; poll="$3"; outfile="$4"
        while true; do
            if ! tmux display-message -t "$target" -p "#{pane_id}" >/dev/null 2>&1; then
                exit 125
            fi
            content=$(tmux capture-pane -t "$target" -p -J -S - 2>/dev/null)
            if echo "$content" | grep -q "^${marker} END "; then
                # Write this exact capture to the outfile — no re-capture race
                printf "%s" "$content" > "$outfile"
                break
            fi
            sleep "$poll"
        done
    ' _ "$target" "$marker" "$POLL" "/tmp/.tmux_cap_$$" || rc=$?

    if [[ $rc -eq 125 ]]; then
        echo "error: target '$target' was killed" >&2
        rm -f "/tmp/.tmux_cap_$$"
        return 125
    fi
    if [[ $rc -eq 124 ]]; then
        echo "error: timed out waiting for command to finish" >&2
        rm -f "/tmp/.tmux_cap_$$"
        return 124
    fi

    # Parse from the preserved capture (not a fresh one)
    local full_capture
    full_capture=$(cat "/tmp/.tmux_cap_$$" 2>/dev/null)
    rm -f "/tmp/.tmux_cap_$$"

    if [[ -z "$full_capture" ]]; then
        echo "error: capture was empty after poll succeeded" >&2
        return 125
    fi

    # Check that BEGIN is still in scrollback
    if ! echo "$full_capture" | grep -q "^${marker} BEGIN"; then
        echo "error: BEGIN marker scrolled out of scrollback — output may be truncated" >&2
        # Still extract what we can from END line
        local end_line
        end_line=$(echo "$full_capture" | grep -m1 "^${marker} END " || true)
        local cmd_exit="${end_line##* }"
        cmd_exit="${cmd_exit:-0}"
        return 126
    fi

    # Extract exit code from the END marker line
    local end_line cmd_exit
    end_line=$(echo "$full_capture" | grep -m1 "^${marker} END " || true)
    if [[ -z "$end_line" ]]; then
        echo "error: END marker not found in preserved capture" >&2
        return 125
    fi
    cmd_exit="${end_line##* }"
    cmd_exit="${cmd_exit:-0}"

    # Extract lines between BEGIN and END markers (exclusive)
    echo "$full_capture" | sed -n "/^${marker} BEGIN/,/^${marker} END/{ /^${marker}/d; p; }"

    # Print the command's exit code as a structured last line.
    # The helper always returns 0 for "command completed" — the caller parses
    # __EXIT:<code> from stdout to get the command's actual status.
    echo "__EXIT:${cmd_exit}"
    return 0
}

# ── send: prompt-based (for REPLs) ──────────────────────────────────────────
#
# Heuristic approach: snapshot → send → wait for change → wait for prompt regex
# on the last non-empty line → print incremental diff.
# Works for line-oriented, echoing REPLs with stable prompts (gdb, python, psql).
# NOT reliable for TUI programs, screen-clearing apps, or concurrent pane access.

cmd_send() {
    local target="$1" regex="$2" command="$3"

    local before_capture before_hash before_lines
    before_capture=$(_capture "$target") || return 125
    before_hash=$(echo "$before_capture" | md5sum | cut -d' ' -f1)
    before_lines=$(echo "$before_capture" | wc -l)

    tmux send-keys -t "$target" "$command" Enter

    # Wait for content to change (avoid matching stale prompt)
    local rc=0
    timeout "$TIMEOUT" bash -c '
        target="$1"; before="$2"; poll="$3"
        while true; do
            if ! tmux display-message -t "$target" -p "#{pane_id}" >/dev/null 2>&1; then
                exit 125
            fi
            after=$(tmux capture-pane -t "$target" -p -J -S - 2>/dev/null | md5sum | cut -d" " -f1)
            [[ "$after" != "$before" ]] && break
            sleep "$poll"
        done
    ' _ "$target" "$before_hash" "$POLL" || rc=$?

    [[ $rc -eq 125 ]] && return 125
    [[ $rc -ne 0 ]] && return $rc

    # Wait for prompt to reappear on the last non-empty line
    rc=0
    timeout "$TIMEOUT" bash -c '
        target="$1"; regex="$2"; poll="$3"
        while true; do
            if ! tmux display-message -t "$target" -p "#{pane_id}" >/dev/null 2>&1; then
                exit 125
            fi
            last=$(tmux capture-pane -t "$target" -p -J -S - 2>/dev/null \
                   | sed -e :a -e "/^[[:space:]]*$/{ \$d; N; ba; }" | tail -1)
            if echo "$last" | grep -qP "$regex"; then
                break
            fi
            sleep "$poll"
        done
    ' _ "$target" "$regex" "$POLL" || rc=$?

    [[ $rc -eq 125 ]] && return 125

    # Print only new lines (incremental diff)
    local after_capture
    after_capture=$(_capture "$target") || return 125
    echo "$after_capture" | tail -n +"$((before_lines + 1))"

    return $rc
}

# ── wait-for: wait for a new line matching a pattern ─────────────────────────

cmd_wait_for() {
    local target="$1" pattern="$2"

    # Snapshot current content so we only match NEW lines
    local before_capture
    before_capture=$(_capture "$target") || return 125
    local before_count
    before_count=$(echo "$before_capture" | wc -l)

    local rc=0
    timeout "$TIMEOUT" bash -c '
        target="$1"; pattern="$2"; poll="$3"; skip="$4"
        while true; do
            if ! tmux display-message -t "$target" -p "#{pane_id}" >/dev/null 2>&1; then
                exit 125
            fi
            # Only search lines that appeared after the snapshot
            match=$(tmux capture-pane -t "$target" -p -J -S - 2>/dev/null \
                    | tail -n +"$((skip + 1))" | grep -m1 -- "$pattern" || true)
            if [[ -n "$match" ]]; then
                echo "$match"
                break
            fi
            sleep "$poll"
        done
    ' _ "$target" "$pattern" "$POLL" "$before_count" || rc=$?

    return $rc
}

# ── wait: wait for a prompt (no command sent) ────────────────────────────────

cmd_wait() {
    local target="$1" regex="$2"

    local rc=0
    timeout "$TIMEOUT" bash -c '
        target="$1"; regex="$2"; poll="$3"
        while true; do
            if ! tmux display-message -t "$target" -p "#{pane_id}" >/dev/null 2>&1; then
                exit 125
            fi
            last=$(tmux capture-pane -t "$target" -p -J -S - 2>/dev/null \
                   | sed -e :a -e "/^[[:space:]]*$/{ \$d; N; ba; }" | tail -1)
            if echo "$last" | grep -qP "$regex"; then
                break
            fi
            sleep "$poll"
        done
    ' _ "$target" "$regex" "$POLL" || rc=$?

    if [[ $rc -eq 0 ]]; then
        local ctx
        ctx=$(_capture "$target") || return 125
        echo "$ctx" | tail -5
    fi
    return $rc
}

# ── read: immediate capture ──────────────────────────────────────────────────

cmd_read() {
    local target="$1"
    local lines="${2:-30}"
    if ! tmux capture-pane -t "$target" -p -J -S "-${lines}" 2>/dev/null; then
        echo "error: target '$target' not found" >&2
        return 125
    fi
}

# ── interrupt: send Ctrl-C ───────────────────────────────────────────────────

cmd_interrupt() {
    if ! tmux send-keys -t "$1" C-c 2>/dev/null; then
        echo "error: target '$1' not found" >&2
        return 125
    fi
}

# ── dispatch ─────────────────────────────────────────────────────────────────

case "${1:-}" in
    run)       shift; cmd_run "$@" ;;
    send)      shift; cmd_send "$@" ;;
    wait-for)  shift; cmd_wait_for "$@" ;;
    wait)      shift; cmd_wait "$@" ;;
    read)      shift; cmd_read "$@" ;;
    interrupt) shift; cmd_interrupt "$@" ;;
    *)
        echo "Usage: $0 {run|send|wait-for|wait|read|interrupt} <args...>" >&2
        exit 1
        ;;
esac
