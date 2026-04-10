---
name: pi-agent
description: Run tasks through OpenAI GPT/Codex models via the pi CLI. Use this skill whenever the user wants to delegate work to GPT or Codex, compare outputs between models, get a second opinion from another LLM, or explicitly mentions "gpt", "codex", "gpt-5", "openai", or "pi" in the context of running a task. Also use when the user wants to run something with a different model for variety or comparison, even if they don't name a specific model.
---

# Pi Agent

Delegate tasks to OpenAI models via the `pi` CLI. The pi agent gets full tool access (read, write, edit, bash) and runs non-interactively, making it suitable for code review, writing, refactoring, research, or any task the user wants handled by a different model.

## Models

| ID | Notes |
|---|---|
| `openai-codex/gpt-5.4` | Default. Best overall. |
| `openai-codex/gpt-5.3-codex` | Alternative, slightly faster. |

Use gpt-5.4 unless the user specifies otherwise.

## Running a task

```bash
cd <working-directory> && pi --model openai-codex/gpt-5.4 --session ~/pi-sessions/<descriptive-name>.jsonl -p "your prompt here"
```

For long prompts, **always write the prompt file as a separate step first** (using the Write tool), then run pi in a separate Bash call. Do NOT combine heredoc file creation and pi invocation in one shell command — the escaping gets mangled and causes pi to hang.

```bash
# Step 1: Write prompt with the Write tool to /tmp/<descriptive-name>.txt

# Step 2: Run pi in a separate Bash call
cd <working-directory> && pi --model openai-codex/gpt-5.4 --session ~/pi-sessions/<descriptive-name>.jsonl -p @/tmp/<descriptive-name>.txt
```

### Why --session matters

Every invocation should include `--session` with a descriptive filename (e.g., `fix-bmr-fallback.jsonl`, `review-food-routes.jsonl`). Sessions are stored in `~/pi-sessions/`. This preserves the full conversation history so you can resume later, and makes it possible to review what the agent did. Without it, context is lost between runs.

### Resuming a previous session

Pass the same `--session` path to continue where a previous run left off:

```bash
cd <working-directory> && pi --model openai-codex/gpt-5.4 --session ~/pi-sessions/<descriptive-name>.jsonl -p "follow-up prompt"
```

## Important: always run in the background

Pi tasks can take minutes to complete. Always launch them as background tasks (use Bash `run_in_background`) so you can continue other work. Relay the result back to the user when the task completes. Blocking on a pi task wastes time for both you and the user.

## Monitoring progress

After launching a pi task in the background, check on it with:

```bash
uv run --no-project /home/jeremy/.claude/skills/pi-agent/pi-status.py [SESSION_NAME]
```

With no argument it picks the most recently modified session. You can also pass a session name (e.g., `auto-tuning-code-review` or a full path).

This shows: entry count, elapsed time, recent tool calls, and the latest text output (i.e., the final answer if the agent is done).

Use this to check on background pi tasks before reporting results to the user. Always use `uv run --no-project` (never raw `python3`).

## Prompt guidelines for read-only tasks (code review, research, analysis)

When the task is read-only (code reviews, research, explaining code), **always** include these rules in the prompt you send to pi:

1. **Read-only mode.** Do NOT modify any files. Do NOT run `pip install`, `uv pip install`, build commands, or anything that compiles code.
2. **Use `--no-project` with uv.** If you use `uv run`, always pass `--no-project` to avoid triggering project builds.

## Working directory

Always `cd` to the relevant project directory before invoking pi, so the agent has the right file context. For instance, `cd /mnt/block/mordor-web` for mordor-web tasks.
