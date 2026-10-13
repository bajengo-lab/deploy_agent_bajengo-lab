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

# Feature 1: Deploy a new attendance tracker
deploy_project() {

# Ask for the project name
read -r -p "Enter a project name: " input

# Validate the project name
if [[ ! "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Use only letters, numbers, underscores, and hyphens."
    return 1
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
        return 1
    fi
fi

# Create the required project directories
if ! mkdir -p "$project_dir/Helpers" "$project_dir/reports"; then
    echo "Error: Could not create project directories."
    return 1
fi

echo "Project directories created successfully."

# Verify that all required template files exist
template_dir="templates"

for file in attendance_checker.py assets.csv config.json; do
    if [[ ! -f "$template_dir/$file" ]]; then
        echo "Error: Missing template file: $template_dir/$file"
        return 1
    fi
done

echo "All required template files are available."

# Deploy the application and its configuration
if ! cp "$template_dir/attendance_checker.py" "$project_dir/"; then
    echo "Error: Could not copy the application."
    return 1
fi


# Copy config.json into the Helpers directory
if ! cp "$template_dir/config.json" "$project_dir/Helpers/"; then
    echo "Error: Could not copy config.json."
    return 1
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
            return 1
        fi
        echo "Template roster copied successfully."
         total_sessions=5
        ;;
    B|b)
        echo "You selected a fresh roster."
        read -r -p "How many students do you want to add? " student_count

        if [[ ! "$student_count" =~ ^[1-9][0-9]*$ ]]; then
            echo "Error: Enter a positive whole number."
            return 1
        fi

        roster_file="$project_dir/Helpers/assets.csv"

        echo "Email,Names,Attendance Count,Absence Count" > "$roster_file"

        for ((i = 1; i <= student_count; i++)); do
            read -r -p "Enter student $i's name: " student_name
            read -r -p "Enter student $i's email: " student_email

            if [[ -z "$student_name" || -z "$student_email" ]]; then
                echo "Error: Name and email cannot be empty."
                return 1
            fi

            echo "$student_email,$student_name,0,0" >> "$roster_file"
        done

        echo "Fresh student roster created successfully."
        total_sessions=1
        ;;
    *)
        echo "Error: Invalid choice. Enter A or B."
        return 1
        ;;
esac

# Update total_sessions in config.json
config_file="$project_dir/Helpers/config.json"

if ! sed -i -E \
    's/("total_sessions"[[:space:]]*:[[:space:]]*)[0-9]+/\1'"$total_sessions"'/' \
    "$config_file"; then
    echo "Error: Could not update total_sessions."
    return 1
fi

echo "Total sessions set to $total_sessions."


# Set permissions for the deployed files
app_file="$project_dir/attendance_checker.py"

if ! chmod +x "$app_file"; then
    echo "Error: Could not make attendance_checker.py executable."
    return 1
fi

if ! chmod 600 "$config_file"; then
    echo "Error: Could not restrict config.json permissions."
    return 1
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
        return 1
    fi

    # Validate percentage ranges
    if (( warning < 0 || warning > 100 || failure < 0 || failure > 100 )); then
        echo "Error: Thresholds must be between 0 and 100."
        return 1
    fi

    # Update the warning threshold
    if ! sed -i -E \
        's/("warning"[[:space:]]*:[[:space:]]*)[0-9]+/\1'"$warning"'/' \
        "$config_file"; then
        echo "Error: Could not update warning threshold."
        return 1
    fi

    # Update the failure threshold
    if ! sed -i -E \
        's/("failure"[[:space:]]*:[[:space:]]*)[0-9]+/\1'"$failure"'/' \
        "$config_file"; then
        echo "Error: Could not update failure threshold."
        return 1
    fi

    echo "Thresholds updated successfully."
else
    echo "Keeping the existing thresholds."
fi


# Verify deployment by running the attendance application
echo "Deployment setup complete."
echo "Starting the attendance application..."

if ! (
    cd "$project_dir" &&
    python3 attendance_checker.py
); then
    echo "Error: The attendance application failed to run."
    return 1
fi

echo "Attendance application finished."

}
run_project() {
    local input
    local project_dir

    echo
    echo "===== Run Existing Project ====="

    read -r -p "Enter the project name (e.g. v1): " input

    if [[ ! "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid project name."
        return 1
    fi

    project_dir="attendance_tracker_${input}"

    if [[ ! -d "$project_dir" ]]; then
        echo "Error: Project '$project_dir' does not exist."
        return 1
    fi

    if [[ ! -f "$project_dir/attendance_checker.py" ]]; then
        echo "Error: attendance_checker.py was not found."
        return 1
    fi

    echo "Starting attendance tracker..."

    if (
        cd "$project_dir" &&
        python3 attendance_checker.py
    ); then
        echo "Attendance application finished."
    else
        echo "Error: The attendance application failed."
        return 1
    fi
}

archive_logs() {
    local input
    local project_dir
    local timestamp
    local archive_root
    local attendance_log
    local absent_log
    local attendance_archive
    local absent_archive

    echo
    echo "===== Archive Logs ====="

    read -r -p "Enter the project name (e.g. v1): " input

    if [[ ! "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid project name."
        return 1
    fi

    project_dir="attendance_tracker_${input}"

    if [[ ! -d "$project_dir" ]]; then
        echo "Error: Project '$project_dir' does not exist."
        return 1
    fi

    attendance_log="$project_dir/reports/attendance.log"
    absent_log="$project_dir/reports/absent.log"

    if [[ ! -f "$attendance_log" && ! -f "$absent_log" ]]; then
        echo "Error: No attendance or absence logs were found."
        return 1
    fi

    archive_root="archives"
    timestamp=$(date +"%Y%m%d_%H%M%S") || {
        echo "Error: Could not generate timestamp."
        return 1
    }

    if ! mkdir -p "$archive_root/attendance" "$archive_root/absent"; then
        echo "Error: Could not create archive directories."
        return 1
    fi

    if [[ -f "$attendance_log" ]]; then
        attendance_archive="$archive_root/attendance/attendance_${timestamp}.log"

        if cp -- "$attendance_log" "$attendance_archive"; then
            echo "Attendance log archived: $attendance_archive"
        else
            echo "Error: Could not archive attendance.log."
            return 1
        fi
    else
        echo "Warning: attendance.log was not found; skipping it."
    fi

    if [[ -f "$absent_log" ]]; then
        absent_archive="$archive_root/absent/absent_${timestamp}.log"

        if cp -- "$absent_log" "$absent_archive"; then
            echo "Absence log archived: $absent_archive"
        else
            echo "Error: Could not archive absent.log."
            return 1
        fi
    else
        echo "Warning: absent.log was not found; skipping it."
    fi
}

while true; do
    echo
    echo "===== Attendance Tracker Manager ====="
    echo "1. Deploy a new project"
    echo "2. Run an existing project"
    echo "3. Archive logs (coming next)"
    echo "4. Exit"

    read -r -p "Choose an option: " choice

    case "$choice" in
        1) deploy_project ;;
        2) run_project ;;
        3) archive_logs ;;
        4) echo "Goodbye!"; break ;;
        *) echo "Invalid choice. Enter 1, 2, 3, or 4." ;;
    esac
done


