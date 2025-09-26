#!/bin/bash
# sync_logs.sh: Synchronize logs from remote cluster experiments.
# Usage: ./sync_logs.sh [--remove] [local_log_folder]
#   --remove         Remove remote experiment directories after sync.
#   local_log_folder Destination folder for logs (default: ./logs)

set -e

usage() {
    echo "Usage: $0 [--remove] [local_log_folder]"
    echo "  --remove         Remove remote experiment directories after sync."
    echo "  local_log_folder Destination folder for logs (default: ./logs)"
    exit 1
}

# Process optional flags
REMOVE_REMOTE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --remove)
            REMOVE_REMOTE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            break
            ;;
    esac
done

# Local destination folder (default to ./logs if not provided)
LOCAL_DEST=${1:-./logs}
mkdir -p "$LOCAL_DEST"

# Load .env.cluster (assumed to be in the same directory as this script)
SCRIPT_DIR=$(dirname "$0")
if [ -f "$SCRIPT_DIR/.env.cluster" ]; then
    source "$SCRIPT_DIR/.env.cluster"
else
    echo "Error: .env.cluster not found in $SCRIPT_DIR"
    exit 1
fi

# Check required environment variables are set
if [ -z "$CLUSTER_ISAACLAB_DIR" ] || [ -z "$EXTENSION_NAME" ] || [ -z "$CLUSTER_LOGIN" ]; then
    echo "Error: Missing required environment variables in .env.cluster."
    exit 1
fi

# Determine the remote base directory.
# We assume that your timestamped experiment folders (e.g. ext_template_20250214_1500)
# are created in the parent directory of CLUSTER_ISAACLAB_DIR.
REMOTE_BASE=$(dirname "$CLUSTER_ISAACLAB_DIR")

# Define search patterns for experiment directories
echo "Searching for remote experiment directories in ${REMOTE_BASE} matching ${EXTENSION_NAME} or ${EXTENSION_NAME}_* ..."

# List matching directories on the remote cluster with logs folders in one go
# We search for both exact name (e.g., ext_template) and name with a suffix (e.g., ext_template_20240101_1200)
echo "Scanning for experiment directories with logs folders..."
REMOTE_DIRS_WITH_LOGS=$(ssh "$CLUSTER_LOGIN" "
    for dir in ${REMOTE_BASE}/${EXTENSION_NAME} ${REMOTE_BASE}/${EXTENSION_NAME}_*; do
        if [ -d \"\$dir\" ] && [ -d \"\$dir/logs\" ]; then
            echo \"\$dir\"
        fi
    done
" 2>/dev/null || true)

# Also get directories without logs for reporting
REMOTE_DIRS_NO_LOGS=$(ssh "$CLUSTER_LOGIN" "
    for dir in ${REMOTE_BASE}/${EXTENSION_NAME} ${REMOTE_BASE}/${EXTENSION_NAME}_*; do
        if [ -d \"\$dir\" ] && [ ! -d \"\$dir/logs\" ]; then
            echo \"\$dir\"
        fi
    done
" 2>/dev/null || true)

if [ -z "$REMOTE_DIRS_WITH_LOGS" ] && [ -z "$REMOTE_DIRS_NO_LOGS" ]; then
    echo "No remote experiment directories found matching patterns ${EXTENSION_NAME} or ${EXTENSION_NAME}_* in ${REMOTE_BASE}"
    exit 0
fi

# Report directories without logs upfront
if [ -n "$REMOTE_DIRS_NO_LOGS" ]; then
    echo "Found experiment directories without logs folders:"
    for dir in $REMOTE_DIRS_NO_LOGS; do
        echo "  - $(basename "$dir") (no logs folder)"
    done
fi

if [ -z "$REMOTE_DIRS_WITH_LOGS" ]; then
    echo "No experiment directories with logs folders found."
    exit 0
fi

echo "Found $(echo "$REMOTE_DIRS_WITH_LOGS" | wc -l) experiment directories with logs folders."

# Loop over each directory with logs
for remote_dir in $REMOTE_DIRS_WITH_LOGS; do
    BASENAME=$(basename "$remote_dir")
    REMOTE_LOG_DIR="${remote_dir}/logs/"
    LOCAL_SUBDIR="${LOCAL_DEST}/${BASENAME}"

    echo ""
    echo "=== Processing experiment: ${BASENAME} ==="
    
    # Calculate transfer size
    echo -n "Calculating transfer size... "
    transfer_info=$(ssh "$CLUSTER_LOGIN" "du -sh ${REMOTE_LOG_DIR} 2>/dev/null" | awk '{print $1}' || echo "unknown")
    echo "done (${transfer_info})"
    
    # Ensure local sub-directory exists
    mkdir -p "$LOCAL_SUBDIR"

    # Synchronize the log folder with minimal output
    echo "Syncing logs to ${LOCAL_SUBDIR}/"
    rsync -avz --info=progress2 --no-inc-recursive "$CLUSTER_LOGIN:${REMOTE_LOG_DIR}" "$LOCAL_SUBDIR/" | \
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*[0-9,]+[[:space:]]+[0-9]+%[[:space:]]+[0-9.]+[A-Za-z]+/s[[:space:]]+[0-9:]+[[:space:]]*$ ]]; then
            # Progress line - show with carriage return for real-time update
            echo -ne "\r  Progress: $line"
        elif [[ "$line" =~ sent.*received.*bytes ]]; then
            # Final summary
            echo -e "\n  Transfer complete: $line"
        fi
    done
    RSYNC_STATUS=${PIPESTATUS[0]}

    if [ $RSYNC_STATUS -eq 0 ]; then
        echo "✓ Successfully synced logs for ${BASENAME}"
        if [ "$REMOVE_REMOTE" = true ]; then
            echo "  Removing remote directory: $remote_dir"
            ssh "$CLUSTER_LOGIN" "rm -rf ${remote_dir}"
            echo "  ✓ Remote directory removed"
        fi
    else
        echo "✗ Error during rsync for ${BASENAME}. Exit code: $RSYNC_STATUS"
        echo "  Logs for ${BASENAME} may be incomplete or missing."
    fi
done

echo "All experiments have been processed."