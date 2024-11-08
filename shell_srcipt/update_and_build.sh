#!/bin/bash

# Check shell compatibility
if [ -n "$ZSH_VERSION" ]; then
    SHELL_TYPE="zsh"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_TYPE="bash"
else
    echo "Unsupported shell. Please use zsh or bash."
    exit 1
fi


echo "=== update_and_build: start ========================="
echo "============= update_and_build: start ==============="
source /home/shanpengma/.zshrc
source /opt/ros/humble/setup.zsh
echo "============= update-and-build: start ==============="