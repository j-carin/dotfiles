#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = ["openai"]
# ///
"""
GPT-5.2 Web Search - searches the web for up-to-date information.
Usage: uv run search.py "your query here"
"""

import sys
from openai import OpenAI

SYSTEM_PROMPT = """You are a web search assistant. Your PRIMARY function is to search the web for current, up-to-date information.

CRITICAL RULES:
1. ALWAYS use the web_search tool to find information. Do NOT rely on your training data or internal knowledge.
2. Your training data is outdated. The web has current information. SEARCH FIRST.
3. Even if you think you know the answer, SEARCH ANYWAY to verify and get the latest updates.
4. Cite your sources with URLs so the user can verify.
5. If the search returns no results, say so explicitly rather than falling back to memory.

Your value is in providing CURRENT, VERIFIED information from the web - not regurgitating potentially outdated training data."""


def main():
    if len(sys.argv) < 2:
        print("Usage: uv run search.py \"your query here\"")
        sys.exit(1)

    query = " ".join(sys.argv[1:])
    client = OpenAI()

    response = client.responses.create(
        model="gpt-5.2",
        reasoning={"effort": "high"},
        tools=[{"type": "web_search"}],
        instructions=SYSTEM_PROMPT,
        input=query,
    )

    # Cost calculation (gpt-5.2 Standard tier pricing)
    INPUT_PRICE_PER_M = 1.75
    OUTPUT_PRICE_PER_M = 14.00
    WEB_SEARCH_PRICE_PER_CALL = 0.01

    usage = response.usage
    input_tokens = usage.input_tokens
    output_tokens = usage.output_tokens

    reasoning_tokens = 0
    if hasattr(usage, "output_tokens_details") and usage.output_tokens_details:
        if hasattr(usage.output_tokens_details, "reasoning_tokens"):
            reasoning_tokens = usage.output_tokens_details.reasoning_tokens or 0

    web_search_calls = sum(
        1 for item in response.output if hasattr(item, "type") and item.type == "web_search_call"
    )

    input_cost = (input_tokens / 1_000_000) * INPUT_PRICE_PER_M
    output_cost = (output_tokens / 1_000_000) * OUTPUT_PRICE_PER_M
    web_search_cost = web_search_calls * WEB_SEARCH_PRICE_PER_CALL
    total_cost = input_cost + output_cost + web_search_cost

    # Output
    print("=== COST BREAKDOWN ===")
    print("Model: gpt-5.2 (high reasoning)")
    print(f"Input tokens:     {input_tokens:,}")
    print(f"Output tokens:    {output_tokens:,}")
    if reasoning_tokens:
        print(f"  (reasoning:     {reasoning_tokens:,})")
    print(f"Web search calls: {web_search_calls}")
    print(f"Input cost:       ${input_cost:.6f}")
    print(f"Output cost:      ${output_cost:.6f}")
    print(f"Web search cost:  ${web_search_cost:.6f}")
    print(f"TOTAL COST:       ${total_cost:.6f}")
    print("=" * 50)
    print()
    print(response.output_text)
    print()
    print("--- Sources ---")
    for item in response.output:
        if hasattr(item, "content") and item.content:
            for content in item.content:
                if hasattr(content, "annotations") and content.annotations:
                    for ann in content.annotations:
                        print(f"- {ann.title}: {ann.url}")


if __name__ == "__main__":
    main()
