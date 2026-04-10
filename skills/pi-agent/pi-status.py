#!/usr/bin/env python3
"""Check on a running pi agent session.

Usage:
    uv run --no-project pi-status.py [SESSION]

SESSION defaults to the most recently modified .jsonl in ~/pi-sessions/.
"""

import json
import sys
from pathlib import Path

SESSIONS_DIR = Path.home() / "pi-sessions"


def find_session(name: str | None) -> Path:
    if name:
        p = Path(name)
        if p.exists():
            return p
        p = SESSIONS_DIR / name
        if p.exists():
            return p
        p = SESSIONS_DIR / f"{name}.jsonl"
        if p.exists():
            return p
        sys.exit(f"Session not found: {name}")

    # Default to most recently modified
    sessions = sorted(SESSIONS_DIR.glob("*.jsonl"), key=lambda f: f.stat().st_mtime)
    if not sessions:
        sys.exit(f"No sessions found in {SESSIONS_DIR}")
    return sessions[-1]


def parse_session(path: Path) -> list[dict]:
    entries = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line:
                entries.append(json.loads(line))
    return entries


def format_duration(seconds: float) -> str:
    m, s = divmod(int(seconds), 60)
    if m:
        return f"{m}m{s:02d}s"
    return f"{s}s"


def summarize(entries: list[dict]) -> None:
    tool_calls = []
    text_outputs = []
    timestamps = []

    for entry in entries:
        msg = entry.get("message", {})
        role = msg.get("role", "")
        ts = entry.get("timestamp", "")
        if ts:
            timestamps.append(ts)

        content = msg.get("content", "")
        if role == "assistant" and isinstance(content, list):
            for item in content:
                if item.get("type") == "toolCall":
                    cmd = item.get("arguments", {}).get("command", "")
                    tool_calls.append((ts, cmd))
                elif item.get("type") == "text":
                    text_outputs.append((ts, item.get("text", "")))

    # Header
    print(f"Session: {session_path.name}")
    print(f"Entries: {len(entries)}")
    if timestamps:
        print(f"First:   {timestamps[0]}")
        print(f"Latest:  {timestamps[-1]}")

        # Compute elapsed
        from datetime import datetime, timezone
        try:
            t0 = datetime.fromisoformat(timestamps[0].replace("Z", "+00:00"))
            t1 = datetime.fromisoformat(timestamps[-1].replace("Z", "+00:00"))
            elapsed = (t1 - t0).total_seconds()
            print(f"Elapsed: {format_duration(elapsed)}")
        except Exception:
            pass

    print(f"Tool calls: {len(tool_calls)}")
    print(f"Text outputs: {len(text_outputs)}")
    print()

    # Recent tool calls
    if tool_calls:
        recent = tool_calls[-8:]
        print("--- Recent tool calls ---")
        for ts, cmd in recent:
            short_ts = ts[-12:-1] if len(ts) > 12 else ts
            # Truncate long commands but show enough to be useful
            if len(cmd) > 140:
                cmd = cmd[:140] + "..."
            print(f"  {short_ts}  {cmd}")
        print()

    # Final text output (the review itself, if done)
    if text_outputs:
        last_ts, last_text = text_outputs[-1]
        lines = last_text.strip().splitlines()
        print(f"--- Latest text output ({len(lines)} lines) ---")
        if len(lines) <= 40:
            print(last_text.strip())
        else:
            # Show first 20 and last 15 lines
            for line in lines[:20]:
                print(line)
            print(f"  ... ({len(lines) - 35} lines omitted) ...")
            for line in lines[-15:]:
                print(line)
    else:
        print("(No text output yet — still working)")


if __name__ == "__main__":
    name = sys.argv[1] if len(sys.argv) > 1 else None
    session_path = find_session(name)
    entries = parse_session(session_path)
    summarize(entries)
