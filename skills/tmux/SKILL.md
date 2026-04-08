---
name: tmux
description: Run commands in tmux windows and panes so the user can see output in their terminal. Use this skill whenever the user wants to run long-running commands (builds, servers, benchmarks), drive interactive programs (gdb, python REPL, psql), or see command output in a visible terminal pane. Also use when the user says "run this in tmux", "open a window for", "I want to watch the output", or wants to monitor logs. Trigger this skill for any task where the output matters to the user visually — compilation, server startup, log tailing, debugging sessions — rather than running it silently in the background.
---

# Tmux Skill

Run commands in tmux windows/panes so the user sees the output in their terminal, while you retain the ability to read the output and react to it.

## When to use this

- Long-running commands where the user wants to watch progress (builds, deploys, benchmarks)
- Interactive programs (gdb, python, psql) that need back-and-forth input
- Servers that stay running and you need to wait for a "ready" signal
- Log tailing where you periodically check for patterns
- Any time the user says they want to "see" the output

## Prerequisites

Check that you're inside tmux before doing anything:

```bash
if [[ -z "$TMUX" ]]; then
    echo "Not in a tmux session — falling back to normal Bash"
fi
```

If `$TMUX` is not set, fall back to running commands with the normal Bash tool.

## The helper script

All tmux interaction goes through `scripts/tmux_helper.sh` in this skill directory.

```bash
HELPER=/home/jeremy/.claude/skills/tmux/scripts/tmux_helper.sh
```

**Important: use one pane per task.** Don't send multiple concurrent commands to the same pane — there is no locking, and interleaved output will corrupt results. Create a dedicated window for each independent task.

### How `run` works (marker protocol)

The `run` command wraps each command in unique BEGIN/END markers:
```
__TMUX_<pid>_<random>_<nanos>__ BEGIN
<command output>
__TMUX_<pid>_<random>_<nanos>__ END <exit_code>
```

It polls `capture-pane` for the END marker, then extracts output from the **same capture** that saw END (no re-capture race condition). The exit code is embedded in the END marker line.

The wrapper syntax is POSIX shell — it works in bash, zsh, sh, and dash. It does **not** work in fish. If the target pane is running fish, use `send` with a prompt regex instead.

The markers are visible in the user's terminal. This is by design.

### Commands

#### `run` — Run a shell command, wait for it to finish

Best for: builds, installs, scripts, shell builtins, compound commands — anything that returns to a POSIX-like shell.

```bash
output=$(bash "$HELPER" run <target> '<command>')
helper_exit=$?     # 0=completed, 124=timeout, 125=target lost, 126=scrollback loss
cmd_exit=$(echo "$output" | tail -1 | sed 's/__EXIT://')  # command's actual exit code
cmd_output=$(echo "$output" | sed '$d')                     # command's output (without the exit line)
```

The helper's process exit code is reserved for helper errors only. The command's own exit code is printed as the last line of stdout in the format `__EXIT:<code>`. This avoids ambiguity — a command that exits 124 won't be confused with a helper timeout.

Example:
```bash
tmux new-window -d -t "$SESSION" -n build
output=$(bash "$HELPER" run "$SESSION:build" 'make -j8')
if [[ $? -ne 0 ]]; then
    echo "Helper error (timeout/target lost)"
else
    cmd_exit=$(echo "$output" | tail -1 | sed 's/__EXIT://')
    echo "$output" | sed '$d'  # print the build output
    echo "Build exited: $cmd_exit"
fi
```

Increase timeout for slow commands:
```bash
TMUX_WAIT_TIMEOUT=300 bash "$HELPER" run "$SESSION:build" 'cargo build --release'
```

Works correctly with:
- Shell builtins (`cd`, `export`, `source`)
- Compound commands (`for ... done`, `if ... fi`)
- Pipes (`cmd | tee log.txt`)
- Commands that produce no output
- Commands that fail (returns actual exit code)

For multiline commands (heredocs, multi-line scripts), write to a temp file and execute it:
```bash
cat > /tmp/myscript.sh << 'EOF'
for i in 1 2 3; do
    echo "step $i"
done
EOF
bash "$HELPER" run "$SESSION:build" 'bash /tmp/myscript.sh'
```

#### `send` — Send to an interactive program, wait for its prompt

Best for: gdb, python, psql — line-oriented REPLs with stable, known prompts.

This is a **heuristic** approach: it snapshots the pane, sends the command, waits for the content to change, then waits for the prompt regex to appear on the last non-empty line. It works well for simple, echoing REPLs but is not a protocol with strong guarantees. It will not work for TUI programs, screen-clearing apps, or programs with unstable prompts.

```bash
bash "$HELPER" send <target> '<prompt_regex>' '<command>'
# Prints only the new output since the command was sent
```

The prompt regex is a Perl-compatible regex matched against the last non-empty line.

Example — driving GDB:
```bash
tmux new-window -d -t "$SESSION" -n debug
tmux send-keys -t "$SESSION:debug" 'gdb ./myprogram' Enter
bash "$HELPER" wait "$SESSION:debug" '\(gdb\)\s*$'
bash "$HELPER" send "$SESSION:debug" '\(gdb\)\s*$' 'break main'
bash "$HELPER" send "$SESSION:debug" '\(gdb\)\s*$' 'run'
bash "$HELPER" send "$SESSION:debug" '\(gdb\)\s*$' 'next'
bash "$HELPER" send "$SESSION:debug" '\(gdb\)\s*$' 'print myvar'
```

Common prompt patterns:
| Program | Regex |
|---|---|
| bash/zsh | `\$\s*$` |
| gdb | `\(gdb\)\s*$` |
| python | `>>>\s*$` |
| psql | `[=#]>\s*$` or `\w+[=#]>\s*$` for `dbname=>` style |
| mysql | `mysql>\s*$` |
| node | `>\s*$` (caution: very loose) |

When possible, launch REPLs with known/fixed prompts rather than trying to match a user's customized prompt.

#### `wait-for` — Wait for a specific string to appear

Best for: servers printing "ready", watching for a build milestone, detecting errors in logs.

Only matches **new** content — ignores anything already in the pane when called. This prevents false matches from previous runs.

```bash
bash "$HELPER" wait-for <target> '<grep_pattern>'
# Prints the matching line when found
```

Example — start a server and wait until it's ready:
```bash
tmux new-window -d -t "$SESSION" -n server
tmux send-keys -t "$SESSION:server" 'python -m uvicorn app:app' Enter
TMUX_WAIT_TIMEOUT=60 bash "$HELPER" wait-for "$SESSION:server" "Uvicorn running on"
echo "Server is up!"
```

#### `wait` — Wait for a prompt (no command sent)

Use after launching something with raw `tmux send-keys`:
```bash
tmux send-keys -t "$SESSION:win" 'python3' Enter
bash "$HELPER" wait "$SESSION:win" '>>>\s*$'
```

#### `read` — Read the current pane content (no waiting)

```bash
bash "$HELPER" read <target> [lines]    # default 30 lines
```

Use this to check on long-running processes, inspect state, or debug timeouts.

#### `interrupt` — Send Ctrl-C

```bash
bash "$HELPER" interrupt <target>
```

## Key patterns

### Creating windows without stealing focus

Always use `-d` so the user's current view isn't disrupted:
```bash
tmux new-window -d -t "$SESSION" -n mywindow
```

### Detecting the current session

```bash
SESSION=$(tmux display-message -p '#{session_name}')
```

### Splitting panes

```bash
# Vertical split (top/bottom) without focus switch
tmux split-window -d -v -t "$SESSION:mywindow"
# Horizontal split (left/right)
tmux split-window -d -h -t "$SESSION:mywindow"
```

Address split panes as `session:window.0`, `session:window.1`, etc.

### Listing state

```bash
tmux list-windows -t "$SESSION"
tmux list-panes -t "$SESSION:mywindow"
```

### Cleaning up

```bash
tmux kill-window -t "$SESSION:mywindow"
tmux kill-pane -t "$SESSION:mywindow.1"
```

## Exit codes

The helper's process exit codes are reserved for helper status only — they never collide with a command's own exit code.

| Code | Meaning |
|---|---|
| 0 | Success. For `run`, the command's actual exit code is on the last stdout line as `__EXIT:<code>` |
| 124 | Timeout — expected condition never appeared |
| 125 | Target lost — pane/window/session was killed, or internal error |
| 126 | Extraction error — BEGIN marker scrolled out of scrollback (output truncated) |

## Handling timeouts

When any command returns 124, the expected condition never appeared. Common causes:

- An unexpected interactive prompt is blocking ("Are you sure? [y/n]", password prompt)
- The command is taking longer than expected

To diagnose:
```bash
bash "$HELPER" read <target> 10
# Read what's on screen, then respond appropriately:
tmux send-keys -t <target> 'y' Enter
```

The helper cannot provide passwords or secrets. If a command needs `sudo`, the user must enter the password themselves, or use passwordless sudo.

## Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `TMUX_WAIT_TIMEOUT` | 15 | Max seconds to wait |
| `TMUX_WAIT_POLL` | 0.05 | Poll interval in seconds |

For long builds or slow servers, set `TMUX_WAIT_TIMEOUT=300` (5 minutes) or higher.

## Limitations

- **One task per pane.** Don't send concurrent commands to the same pane. Create a new window for each independent task.
- **POSIX shells only for `run`.** The marker wrapper is POSIX shell syntax. It works in bash, zsh, sh, dash. It does NOT work in fish. For fish, use `send` with a prompt regex.
- **`send` is heuristic.** It works for line-oriented, echoing REPLs with stable prompts. It is not reliable for TUI/ncurses programs (vim, htop), screen-clearing apps, or programs with frequently changing prompts.
- **Multiline commands.** Don't try to put heredocs or multi-line blocks directly in the `run` command string. Write to a temp script file and execute that instead.
- **Scrollback limits.** tmux default is 2000 lines. If `run` output is extremely long, the BEGIN marker may scroll out of the buffer. The helper detects this and returns exit code 126 with an error message. For very verbose commands, also redirect to a file (`cmd 2>&1 | tee log.txt`).
- **TUI/ncurses programs** (vim, htop, less): `read` shows the current screen state, but `send`/`wait-for` are unreliable because these programs continuously redraw. Use raw `tmux send-keys` and `read` for TUI programs.
- **Progress bars using `\r`**: Only the last rendered state of each line is visible. Transient content between polls may be missed by `wait-for`. If you need the raw stream, use `tmux pipe-pane` to log to a file.
- **Python multiline blocks**: The continuation prompt `...` differs from `>>>`. After a `for`/`if` block, send a blank Enter to close the block before sending the next command.
- **SSH sessions**: `run` works over SSH if the remote shell is POSIX-like, since the markers are printed remotely and captured locally. `send` works for remote REPLs if you know the prompt. The prompt will include the remote hostname, so adjust your regex accordingly.
