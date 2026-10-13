#!/bin/bash

# Check that required commands are installed
if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 not installed."
    exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
    echo "Error: zip not installed."
    exit 1
fi

echo "Pre-flight checks complete."


# Ask for the project name
read -r -p "Enter a project name: " input

# Validate the project name
if [[ ! "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Use only letters, numbers, underscores, and hyphens."
    exit 1
fi

project_dir="attendance_tracker_${input}"
echo "Project directory: $project_dir"

# Check whether the project directory already exists
if [[ -d "$project_dir" ]]; then
    echo "Directory $project_dir already exists."
    read -r -p "Remove it and deploy again? (y/n): " answer

    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        rm -rf -- "$project_dir"
    else
        echo "Deployment cancelled."
        exit 1
    fi
fi
