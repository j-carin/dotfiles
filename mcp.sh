#!/bin/bash

# MCP (Model Context Protocol) Server Setup
# Installs zen-mcp-server for Claude Code CLI integration

set -e

echo "Setting up MCP servers for Claude Code..."

# Check if Claude CLI is available
if ! command -v claude &> /dev/null; then
    echo "⚠️  Claude CLI not found. Please install it first via setup-ai.sh"
    exit 1
fi

# Check if uvx is available
if ! command -v uvx &> /dev/null; then
    echo "⚠️  uvx not found. Please install uv first."
    exit 1
fi

# Install zen-mcp-server using uvx method
echo "Installing zen-mcp-server..."
claude mcp add zen -- sh -c "exec \$(which uvx || echo uvx) --from git+https://github.com/BeehiveInnovations/zen-mcp-server.git zen-mcp-server"

echo "✅ zen-mcp-server installed successfully!"
echo ""
echo "Available zen tools:"
echo "  - Use zen to chat about architecture"
echo "  - Use zen to debug issues"
echo "  - Use zen to perform code reviews"
echo "  - Use zen to analyze code"
echo "  - Use zen to list available models"
echo ""
echo "Note: Restart Claude CLI sessions to use zen tools"