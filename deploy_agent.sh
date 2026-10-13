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

# Create the required project directories
if ! mkdir -p "$project_dir/Helpers" "$project_dir/reports"; then
    echo "Error: Could not create project directories."
    exit 1
fi

echo "Project directories created successfully."

# Verify that all required template files exist
template_dir="templates"

for file in attendance_checker.py assets.csv config.json; do
    if [[ ! -f "$template_dir/$file" ]]; then
        echo "Error: Missing template file: $template_dir/$file"
        exit 1
    fi
done

echo "All required template files are available."

# Deploy the application and its configuration
if ! cp "$template_dir/attendance_checker.py" "$project_dir/"; then
    echo "Error: Could not copy the application."
    exit 1
fi

if ! cp "$template_dir/assets.csv" "$project_dir/Helpers/" ||
   ! cp "$template_dir/config.json" "$project_dir/Helpers/"; then
    echo "Error: Could not copy the configuration files."
    exit 1
fi

echo "Application and configuration files copied successfully."
