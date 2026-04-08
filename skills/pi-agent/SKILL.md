---
name: pi-agent
description: Run prompts through GPT/Codex models via pi CLI. Use when Jeremy asks to "use gpt" or "use codex" for a task. The model gets full tool access (read, bash, edit, write) and runs non-interactively.
---

# Pi Agent

Run tasks through OpenAI models via the pi CLI with full tool access.

## Available Models

- **openai-codex/gpt-5.4** - default, best overall
- **openai-codex/gpt-5.3-codex** - alternative

Default to gpt-5.4 unless Jeremy specifies otherwise.

## Usage

Always use --session with a descriptive filename. Sessions are stored in `~/pi-sessions/`.

```bash
cd <working-directory> && pi --model openai-codex/gpt-5.4 --session ~/pi-sessions/<descriptive-name>.jsonl -p "your prompt here"
```

For long prompts, write to a temp file and pass with @:

```bash
cd <working-directory> && pi --model openai-codex/gpt-5.4 --session ~/pi-sessions/<descriptive-name>.jsonl -p @/tmp/prompt.txt
```

Name sessions descriptively so they can be found later, e.g. `fix-bmr-fallback.jsonl`, `review-food-routes.jsonl`.

## Resuming a session

Use the same --session path to continue where it left off:

```bash
cd <working-directory> && pi --model openai-codex/gpt-5.4 --session ~/pi-sessions/<descriptive-name>.jsonl -p "follow-up prompt"
```

## When to use

When Jeremy says things like:
- "use gpt to do X"
- "use codex to do X"
- "ask gpt-5.4 about X"
- "have gpt review/write/fix X"

## Notes

- Always cd to the relevant working directory first
- Always use --session with a descriptive name
- **Always run as a background task** (use Bash run_in_background). These can take a while. Continue with other work and relay the result to Jeremy via Telegram when it completes.
- Output goes to stdout - relay the result back to Jeremy via Telegram
