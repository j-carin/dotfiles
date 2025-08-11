#!/bin/bash

# Enable sudo without password for current user
# WARNING: This reduces system security

USERNAME=$(whoami)
SUDOERS_LINE="$USERNAME ALL=(ALL) NOPASSWD: ALL"

echo "Adding NOPASSWD rule for user: $USERNAME"
echo ""
echo "This will allow sudo commands without entering a password."
echo "WARNING: This reduces system security!"
echo ""
read -p "Continue? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Create a temporary file with the new sudoers line
    echo "$SUDOERS_LINE" | sudo tee /etc/sudoers.d/nopasswd-$USERNAME > /dev/null
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully configured sudo without password for $USERNAME"
        echo ""
        echo "Testing configuration..."
        sudo -n true 2>/dev/null && echo "✓ Sudo without password is working!" || echo "✗ Configuration may need a new terminal session"
    else
        echo "✗ Failed to configure sudo"
        exit 1
    fi
else
    echo "Cancelled."
    exit 0
fi