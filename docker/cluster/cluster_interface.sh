#!/usr/bin/env bash

#==
# Configurations
#==

# Exits if error occurs
set -e

# Set tab-spaces
tabs 4

# get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Load custom environment paths if provided, else use defaults
ENV_CLUSTER_PATH=${ENV_CLUSTER_PATH:-"$SCRIPT_DIR/.env.cluster"}
# Codebase to sync
CODEBASE_PATH=${CODEBASE_PATH:-"$SCRIPT_DIR/../.."}

# Debug output (comment out for production)
# echo "[DEBUG] SCRIPT_DIR: $SCRIPT_DIR"
# echo "[DEBUG] ENV_CLUSTER_PATH: $ENV_CLUSTER_PATH"
# echo "[DEBUG] CODEBASE_PATH: $CODEBASE_PATH"

# Source the environment file
if [ -f "$ENV_CLUSTER_PATH" ]; then
    source "$ENV_CLUSTER_PATH"
else
    echo "[Error] Environment file '$ENV_CLUSTER_PATH' does not exist!" >&2
    exit 1
fi

#==
# Functions
#==
# Function to display warnings in red
display_warning() {
    echo -e "\033[31mWARNING: $1\033[0m"
}

# Helper function to compare version numbers
version_gte() {
    # Returns 0 if the first version is greater than or equal to the second, otherwise 1
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n 1)" == "$2" ]
}

# Function to check docker versions
check_docker_version() {
    # check if docker is installed
    if ! command -v docker &> /dev/null; then
        echo "[Error] Docker is not installed! Please check the 'Docker Guide' for instruction." >&2;
        exit 1
    fi
    # Retrieve Docker version
    docker_version=$(docker --version | awk '{ print $3 }')
    apptainer_version=$(apptainer --version | awk '{ print $3 }')

    # Check if Docker version is exactly 24.0.7 or Apptainer version is exactly 1.2.5
    if [ "$docker_version" = "24.0.7" ] && [ "$apptainer_version" = "1.2.5" ]; then
        echo "[INFO]: Docker version ${docker_version} and Apptainer version ${apptainer_version} are tested and compatible."

    # Check if Docker version is >= 27.0.0 and Apptainer version is >= 1.3.4
    elif version_gte "$docker_version" "27.0.0" && version_gte "$apptainer_version" "1.3.4"; then
        echo "[INFO]: Docker version ${docker_version} and Apptainer version ${apptainer_version} are tested and compatible."

    # Else, display a warning for non-tested versions
    else
        display_warning "Docker version ${docker_version} and Apptainer version ${apptainer_version} are non-tested versions. There could be issues, please try to update them. More info: https://isaac-sim.github.io/IsaacLab/source/deployment/cluster.html"
    fi
}

# Checks if a docker image exists, otherwise prints warning and exists
check_image_exists() {
    image_name="$1"
    if ! docker image inspect $image_name &> /dev/null; then
        echo "[Error] The '$image_name' image does not exist!" >&2;
        echo "[Error] You might be able to build it with /IsaacLab/docker/container.py." >&2;
        exit 1
    fi
}

# Check if the singularity image exists on the remote host, otherwise print warning and exit
check_singularity_image_exists() {
    image_name="$1"
    if ! ssh "$CLUSTER_LOGIN" "[ -f $CLUSTER_SIF_PATH/$image_name.tar ]"; then
        echo "[Error] The '$image_name' image does not exist on the remote host $CLUSTER_LOGIN!" >&2;
        exit 1
    fi
}

# Function to handle mount configuration sync
sync_mount_config() {
    local mount_config_path="$CODEBASE_PATH/docker/.mount.config"
    
    if [ -f "$mount_config_path" ]; then
        echo "[INFO] Found mount configuration file"
        
        # Create a temporary Python script
        local temp_script=$(mktemp)
        cat > "$temp_script" << 'PYTHON_SCRIPT'
import json
import sys
import os

config_path = sys.argv[1]
with open(config_path, 'r') as f:
    config = json.load(f)

need_sync = False
for mount_name, mount_config in config.get('mounts', {}).items():
    if mount_config.get('enabled', False) and mount_config.get('sync_to_cluster', True):
        need_sync = True
        local_path = os.path.expanduser(mount_config['local_path'])
        print(f"[INFO] Will sync {mount_name} from {local_path}")

sys.exit(0 if need_sync else 1)
PYTHON_SCRIPT
        
        # Execute the Python script
        # Save the result before any other commands
        set +e  # Temporarily disable exit on error
        python3 "$temp_script" "$mount_config_path"
        sync_exit_code=$?
        set -e  # Re-enable exit on error
        if [ $sync_exit_code -eq 0 ]; then
            # Sync external codebases
            python3 "$CODEBASE_PATH/docker/cluster/sync_mounts.py" "$mount_config_path" "$CLUSTER_LOGIN"
        fi
        rm -f "$temp_script"
    else
        echo "[INFO] No mount configuration found. Run './container.sh mount-setup' to configure external mounts."
    fi
}

submit_job() {

    echo "[INFO] Arguments passed to job script ${@}"

    case $CLUSTER_JOB_SCHEDULER in
        "SLURM")
            job_script_file=submit_job_slurm.sh
            ;;
        "PBS")
            job_script_file=submit_job_pbs.sh
            ;;
        *)
            echo "[ERROR] Unsupported job scheduler specified: '$CLUSTER_JOB_SCHEDULER'. Supported options are: ['SLURM', 'PBS']"
            exit 1
            ;;
    esac

    # No mount args needed - mount config is handled by .mount.config file
    # Build the command with properly quoted arguments
    ssh_cmd="cd $CLUSTER_ISAACLAB_DIR && bash $CLUSTER_ISAACLAB_DIR/docker/cluster/$job_script_file \"$CLUSTER_ISAACLAB_DIR\" \"isaac-lab-$profile\" \"\" \"--\""
    
    # Add each argument properly quoted
    for arg in "$@"; do
        ssh_cmd="$ssh_cmd \"$arg\""
    done
    
    # Execute the SSH command
    ssh $CLUSTER_LOGIN "$ssh_cmd"
}

# Function to list all available profiles
list_profiles() {
    echo "[INFO] Available profiles:"
    for env_file in "$CODEBASE_PATH"/docker/.env.*; do
        if [ -f "$env_file" ]; then
            # Extract profile name from .env.<profile> file
            profile_name=$(basename "$env_file" | sed 's/^\.env\.//')
            # Skip .env.cluster file which is not a profile
            if [ "$profile_name" != "cluster" ]; then
                echo "  - $profile_name"
            fi
        fi
    done
}

#==
# Main
#==

#!/bin/bash

help() {
    echo -e "\nusage: $(basename "$0") [-h] [-c] <command> [<profile>] [<job_args>...] -- Utility for interfacing between IsaacLab extension and compute clusters."
    echo -e "\noptions:"
    echo -e "  -h              Display this help message."
    echo -e "  -c              Check for large files in the synced directory on the cluster (job command only)."
    echo -e "\ncommands:"
    echo -e "  push [<profile>]              Push the docker image to the cluster."
    echo -e "  job [<profile>] [<job_args>]  Submit a job to the cluster."
    echo -e "  list-profiles                 List all available profiles."
    echo -e "\nwhere:"
    echo -e "  <profile>  is the optional container profile specification. Defaults to 'base'."
    echo -e "  <job_args> are optional arguments specific to the job command."
    echo -e "\nExternal mount configuration:"
    echo -e "  Configure mounts locally with: ./container.sh mount-setup"
    echo -e "  Mount config is automatically synced to cluster"
    echo -e "\n" >&2
}

# Parse options
while getopts ":hc" opt; do
    case ${opt} in
        h )
            help
            exit 0
            ;;
        c )
            check_large_files_flag=true
            ;;
        \? )
            echo "Invalid option: -$OPTARG" >&2
            help
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# Check for command
if [ $# -lt 1 ]; then
    echo "Error: Command is required." >&2
    help
    exit 1
fi

command=$1
shift
profile="base"

case $command in
    push)
        if [ $# -gt 1 ]; then
            echo "Error: Too many arguments for push command." >&2
            help
            exit 1
        fi
        [ $# -eq 1 ] && profile=$1
        echo "Executing push command"
        [ -n "$profile" ] && echo "Using profile: $profile"
        if ! command -v apptainer &> /dev/null; then
            echo "[INFO] Exiting because apptainer was not installed"
            echo "[INFO] You may follow the installation procedure from here: https://apptainer.org/docs/admin/main/installation.html#install-ubuntu-packages"
            exit
        fi
        # Check if Docker image exists
        check_image_exists isaac-lab-$profile:latest
        # Check docker and apptainer version
        check_docker_version
        # source env file to get cluster login and path information
        source $ENV_CLUSTER_PATH
        # make sure exports directory exists
        mkdir -p /$SCRIPT_DIR/exports
        # clear old exports for selected profile
        rm -rf /$SCRIPT_DIR/exports/isaac-lab-$profile*
        # create singularity image
        # NOTE: we create the singularity image as non-root user to allow for more flexibility. If this causes
        # issues, remove the --fakeroot flag and open an issue on the IsaacLab repository.
        cd /$SCRIPT_DIR/exports
        APPTAINER_NOHTTPS=1 apptainer build --sandbox --fakeroot isaac-lab-$profile.sif docker-daemon://isaac-lab-$profile:latest
        # tar image (faster to send single file as opposed to directory with many files)
        tar -cvf /$SCRIPT_DIR/exports/isaac-lab-$profile.tar isaac-lab-$profile.sif
        # make sure target directory exists
        ssh $CLUSTER_LOGIN "mkdir -p $CLUSTER_SIF_PATH"
        # send image to cluster
        scp $SCRIPT_DIR/exports/isaac-lab-$profile.tar $CLUSTER_LOGIN:$CLUSTER_SIF_PATH/isaac-lab-$profile.tar
        ;;
    list-profiles)
        list_profiles
        ;;
    job)
        if [ $# -ge 1 ] && [ -f "$CODEBASE_PATH/docker/.env.$1" ]; then
            profile=$1
            shift
        fi
        job_args="$@"
        echo "[INFO] Executing job command"
        [ -n "$profile" ] && echo -e "\tUsing profile: $profile"
        [ -n "$job_args" ] && echo -e "\tJob arguments: $job_args"
        source $ENV_CLUSTER_PATH
        # Get current date and time
        current_datetime=$(date +"%Y%m%d_%H%M%S")
        # Append current date and time to CLUSTER_ISAACLAB_DIR
        CLUSTER_ISAACLAB_DIR="${CLUSTER_ISAACLAB_DIR}_${current_datetime}"
        # Check if singularity image exists on the remote host
        check_singularity_image_exists isaac-lab-$profile
        # make sure target directory exists
        ssh $CLUSTER_LOGIN "mkdir -p $CLUSTER_ISAACLAB_DIR"
        
        # Sync mount configuration if present
        sync_mount_config
        
        # Sync extension code
        echo "[INFO] Syncing extension codebase: $CODEBASE_PATH"
        echo "[INFO] Preparing to sync files to cluster..."
        
        # Show estimated transfer size before starting
        echo -n "[INFO] Calculating transfer size... "
        transfer_size=$(rsync -avhnL --exclude="*.git*" --filter=':- .dockerignore' "$CODEBASE_PATH" "$CLUSTER_LOGIN:$CLUSTER_ISAACLAB_DIR" | tail -n 1 | awk '{print $4}')
        echo "done"
        echo "[INFO] Estimated transfer size: $transfer_size"
        
        # Sync with progress bar
        echo "[INFO] Starting sync..."
        rsync -avhL --progress --exclude="*.git*" --filter=':- .dockerignore' "$CODEBASE_PATH" "$CLUSTER_LOGIN:$CLUSTER_ISAACLAB_DIR" | \
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*[0-9,]+[[:space:]]+[0-9]+%[[:space:]]+[0-9.]+[A-Za-z]+/s[[:space:]]+[0-9:]+[[:space:]]*$ ]]; then
                # This is a progress line, show it with nice formatting
                echo -ne "\r[SYNC] $line"
            elif [[ "$line" =~ sent.*received.*bytes ]]; then
                # Final summary line
                echo -e "\n[INFO] Transfer complete: $line"
            fi
        done
        echo ""
        echo "[INFO] ✓ Codebase sync completed successfully"
        # Report large files
        if [ "$check_large_files_flag" = true ]; then
            echo "[INFO] Checking for large files in synced directory on cluster..."
            ssh $CLUSTER_LOGIN "echo 'Files larger than 50MB:'; find '$CLUSTER_ISAACLAB_DIR' -type f -size +10M -print0 | xargs -0 du -h | sort -rh"
            echo "[INFO] If any of the above files are not needed, consider adding them to your .dockerignore file to speed up future syncs."
        fi
        # execute job script
        echo "[INFO] Executing job script..."
        # check whether the second argument is a profile or a job argument
        submit_job $job_args
        ;;
    *)
        echo "Error: Invalid command: $command" >&2
        help
        exit 1
        ;;
esac