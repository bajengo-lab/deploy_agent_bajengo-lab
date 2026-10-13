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


# Copy config.json into the Helpers directory
if ! cp "$template_dir/config.json" "$project_dir/Helpers/"; then
    echo "Error: Could not copy config.json."
    exit 1
fi

# Ask the user how to create the student roster
echo "Choose how to create the student roster:"
echo "A. Copy students from the template roster"
echo "B. Generate a fresh roster"
read -r -p "Enter A or B: " roster_choice

case "$roster_choice" in
    A|a)
        if ! cp "$template_dir/assets.csv" "$project_dir/Helpers/"; then
            echo "Error: Could not copy the template roster."
            exit 1
        fi
        echo "Template roster copied successfully."
         total_sessions=5
        ;;
    B|b)
        echo "You selected a fresh roster."
        read -r -p "How many students do you want to add? " student_count

        if [[ ! "$student_count" =~ ^[1-9][0-9]*$ ]]; then
            echo "Error: Enter a positive whole number."
            exit 1
        fi

        roster_file="$project_dir/Helpers/assets.csv"

        echo "Email,Names,Attendance Count,Absence Count" > "$roster_file"

        for ((i = 1; i <= student_count; i++)); do
            read -r -p "Enter student $i's name: " student_name
            read -r -p "Enter student $i's email: " student_email

            if [[ -z "$student_name" || -z "$student_email" ]]; then
                echo "Error: Name and email cannot be empty."
                exit 1
            fi

            echo "$student_email,$student_name,0,0" >> "$roster_file"
        done

        echo "Fresh student roster created successfully."
        total_sessions=1
        ;;
    *)
        echo "Error: Invalid choice. Enter A or B."
        exit 1
        ;;
esac

# Update total_sessions in config.json
config_file="$project_dir/Helpers/config.json"

if ! sed -i -E \
    's/("total_sessions"[[:space:]]*:[[:space:]]*)[0-9]+/\1'"$total_sessions"'/' \
    "$config_file"; then
    echo "Error: Could not update total_sessions."
    exit 1
fi

echo "Total sessions set to $total_sessions."


# Set permissions for the deployed files
app_file="$project_dir/attendance_checker.py"

if ! chmod +x "$app_file"; then
    echo "Error: Could not make attendance_checker.py executable."
    exit 1
fi

if ! chmod 600 "$config_file"; then
    echo "Error: Could not restrict config.json permissions."
    exit 1
fi

echo "File permissions updated successfully."
ls -l "$app_file" "$config_file"



# Offer to update attendance alert thresholds
read -r -p "Update attendance alert thresholds? (y/n): " update_thresholds

if [[ "$update_thresholds" == "y" || "$update_thresholds" == "Y" ]]; then

    read -r -p "Enter warning threshold (default 75): " warning
    read -r -p "Enter failure threshold (default 50): " failure

    # Validate that both inputs are whole numbers
    if [[ ! "$warning" =~ ^[0-9]+$ || ! "$failure" =~ ^[0-9]+$ ]]; then
        echo "Error: Thresholds must be numeric."
        exit 1
    fi

    # Validate percentage ranges
    if (( warning < 0 || warning > 100 || failure < 0 || failure > 100 )); then
        echo "Error: Thresholds must be between 0 and 100."
        exit 1
    fi

    # Update the warning threshold
    if ! sed -i -E \
        's/("warning"[[:space:]]*:[[:space:]]*)[0-9]+/\1'"$warning"'/' \
        "$config_file"; then
        echo "Error: Could not update warning threshold."
        exit 1
    fi

    # Update the failure threshold
    if ! sed -i -E \
        's/("failure"[[:space:]]*:[[:space:]]*)[0-9]+/\1'"$failure"'/' \
        "$config_file"; then
        echo "Error: Could not update failure threshold."
        exit 1
    fi

    echo "Thresholds updated successfully."
else
    echo "Keeping the existing thresholds."
fi
