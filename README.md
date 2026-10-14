# deploy_agent_bajengo-lab
A repo containing my final deliverable after taking a course in Introduction to Linux and IT Tools

# Attendance Tracker Deployment Automation

## Overview

The **Attendance Tracker Deployment Automation** project is a Bash-based tool designed to simplify the deployment, execution, and log archiving of a Python Student Attendance Tracker application.

The script automates project directory creation, copies application templates, configures student rosters, updates attendance thresholds, sets file permissions, and verifies deployments by launching the application. It also allows users to run existing deployments and archive attendance and absence logs.

## Features

### 1. Automated Deployment
- Checks that required commands are installed before starting.
- Creates a project directory using the naming format `attendance_tracker_<project_name>`.
- Creates the required `Helpers/` and `reports/` directories.
- Copies the application and configuration templates into the deployment directory.
- Checks that the required template files exist.
- Prompts before replacing an existing deployment.

### 2. Student Roster Management
Users can choose between two roster options:

- **Template roster:** Copies the existing sample student roster from `assets.csv` and configures five total sessions.
- **Fresh roster:** Generates a new CSV roster based on the number of students entered. Each student starts with zero attendance and zero absences, and the configuration is set to one total session.

### 3. Attendance Threshold Configuration
- Allows users to configure warning and failure thresholds.
- Uses default thresholds of 75% and 50% when the corresponding inputs are left blank.
- Validates that threshold values are numeric percentages between 0 and 100.
- Updates the relevant values in `config.json`.

### 4. File Permissions
- Makes `attendance_checker.py` executable.
- Restricts `config.json` permissions to the file owner using `chmod 600`.

### 5. Run Existing Deployments
Users can select an existing attendance tracker deployment and launch the application without creating a new deployment.

### 6. Log Archiving
The script copies available attendance and absence logs into separate archive directories:

- `archives/attendance/`
- `archives/absent/`

Archived logs use timestamped filenames, for example:

- `attendance_YYYYMMDD_HHMMSS.log`
- `absent_YYYYMMDD_HHMMSS.log`

The script reports missing logs and handles each log independently.

### 7. Signal Handling and Error Management
- Handles `SIGINT` (Ctrl+C) and `SIGTSTP` (Ctrl+Z) during deployment.
- Attempts to archive an incomplete deployment into a ZIP file.
- Removes the incomplete deployment directory if archiving succeeds.
- Reports errors when required files or directories cannot be accessed or when application execution fails.

## Project Structure

The repository should be organized as follows:

```text
deploy_agent_GithubUsername/
├── deploy_agent.sh
├── templates/
│   ├── attendance_checker.py
│   ├── assets.csv
│   └── config.json
├── README.md
└── .gitignore
```

The `templates/` directory must contain the required source files before deployment.

A deployed project follows this structure:

```text
attendance_tracker_<project_name>/
├── attendance_checker.py
├── Helpers/
│   ├── assets.csv
│   └── config.json
└── reports/
```

The `reports/` directory is used by the attendance application for its log files.

## Prerequisites

Ensure the following tools are available in your environment:

- **Bash** — to execute the deployment script.
- **Python 3** — to run the attendance application.
- **zip** — to archive interrupted deployments.
- **sed** — to update configuration values.
- Standard Linux utilities, including `cp`, `mkdir`, `chmod`, `rm`, and `date`.

## Installation and Setup

1. Clone the repository:

   ```bash
   git clone https://github.com/GithubUsername/deploy_agent_GithubUsername.git
   ```

2. Navigate to the repository directory:

   ```bash
   cd deploy_agent_GithubUsername
   ```

3. Confirm that the template files exist:

   ```bash
   ls templates/
   ```

   The directory should contain `attendance_checker.py`, `assets.csv`, and `config.json`.

4. Make the deployment script executable:

   ```bash
   chmod +x deploy_agent.sh
   ```

## Running the Script

Start the deployment manager with:

```bash
./deploy_agent.sh
```

The interactive menu provides the following options:

| Option | Action |
|---|---|
| 1 | Deploy a new attendance tracker project |
| 2 | Run an existing project |
| 3 | Archive attendance and absence logs |
| 4 | Exit the program |

Follow the prompts for the selected operation.

### Deploying a New Project

1. Select option `1`.
2. Enter a project name using letters, numbers, underscores, or hyphens.
3. Select either the template roster or a fresh roster.
4. Enter student details if generating a fresh roster.
5. Choose whether to update attendance thresholds.
6. Allow the script to launch the attendance application to verify the deployment.

### Running an Existing Project

1. Select option `2`.
2. Enter the project name used during deployment.
3. The script checks that the project directory and Python application exist before launching the application.

### Archiving Logs

1. Select option `3`.
2. Enter the relevant project name.
3. Available attendance and absence logs are copied into their respective archive directories with timestamped filenames.

## Error Handling and Limitations

- The script stops if `python3` or `zip` is unavailable.
- Invalid project names and roster inputs are rejected.
- Missing template files and failed file operations are reported.
- Existing project directories require confirmation before replacement.
- If archiving an interrupted deployment fails, the incomplete directory is retained.
- Ordinary deployment failures reset the deployment state but may leave a partial directory for troubleshooting.
- Log archiving copies logs rather than removing the original files.
- The script assumes it is run from the repository directory so that it can locate `templates/` and the deployed project directories.

## Testing

The script should be tested for the following scenarios:

- Required commands are available.
- Both roster creation options work.
- Blank threshold inputs apply the defaults.
- Invalid input is rejected.
- Existing project directories are handled safely.
- Deployed file permissions are correct.
- Existing deployments can be run.
- Available logs are archived with timestamped filenames.
- Missing logs are reported.
- Deployment interruption triggers the expected archive and cleanup behavior.

## Author

**Bill Ajengo**
Demo Video: https://youtu.be/gVLcz_CzoKA

GitHub: [https://github.com/bajengo-lab](https://github.com/bajengo-lab)

 

