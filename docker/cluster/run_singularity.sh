#!/usr/bin/env bash

echo "(run_singularity.sh): Called on compute node from current directory $1 with container profile $2 and arguments ${@:5}"
echo "[DEBUG] Working directory: $(pwd)"
echo "[DEBUG] All arguments: $*"
echo "[DEBUG] Directory path (arg1): $1"
echo "[DEBUG] Container profile (arg2): $2" 
echo "[DEBUG] Cluster env (arg3): $3"
echo "[DEBUG] Base env (arg4): $4"
echo "[DEBUG] Script arguments (arg5+): ${@:5}"
echo "[DEBUG] Current user: $(whoami)"
echo "[DEBUG] TMPDIR: $TMPDIR"

# Parse mount arguments
MOUNT_ISAACLAB_PATH=""
MOUNT_RSL_RL_PATH=""
SCRIPT_ARGS=()
ALL_ARGS=("${@:5}") # Get all arguments after the env files

# Find the "--" delimiter to separate mount args from script args
delimiter_found=false
i=0
while [ $i -lt ${#ALL_ARGS[@]} ]; do
    if [ "${ALL_ARGS[$i]}" = "--" ]; then
        delimiter_found=true
        break
    fi
    i=$((i+1))
done

if [ "$delimiter_found" = true ]; then
    # Extract mount args (before delimiter) and script args (after delimiter)
    MOUNT_ARGS_TEMP=("${ALL_ARGS[@]:0:$i}")
    SCRIPT_ARGS=("${ALL_ARGS[@]:$((i+1))}")
    echo "[DEBUG] Found delimiter at position $i"
    echo "[DEBUG] Mount args: ${MOUNT_ARGS_TEMP[*]}"
    echo "[DEBUG] Script args: ${SCRIPT_ARGS[*]}"
else
    # No delimiter, all args are script args (backward compatibility)
    echo "[DEBUG] No delimiter found, treating all as script args"
    SCRIPT_ARGS=("${ALL_ARGS[@]}")
    MOUNT_ARGS_TEMP=()
fi

# Parse mount arguments
i=0
while [ $i -lt ${#MOUNT_ARGS_TEMP[@]} ]; do
    arg_val="${MOUNT_ARGS_TEMP[$i]}"
    echo "[DEBUG] Processing mount arg $i: $arg_val"
    
    case "$arg_val" in
        --mount_isaaclab)
            echo "[DEBUG] Found --mount_isaaclab at position $i"
            i=$((i+1)) # Move to the path
            if [ $i -lt ${#MOUNT_ARGS_TEMP[@]} ]; then
                MOUNT_ISAACLAB_PATH="${MOUNT_ARGS_TEMP[$i]}"
                echo "[DEBUG] run_singularity.sh: Captured MOUNT_ISAACLAB_PATH as: $MOUNT_ISAACLAB_PATH"
            else
                echo "[ERROR] run_singularity.sh: --mount_isaaclab requires a value." >&2; exit 1;
            fi
            ;;
        --mount_rsl_rl)
            echo "[DEBUG] Found --mount_rsl_rl at position $i"
            i=$((i+1)) # Move to the path
            if [ $i -lt ${#MOUNT_ARGS_TEMP[@]} ]; then
                MOUNT_RSL_RL_PATH="${MOUNT_ARGS_TEMP[$i]}"
                echo "[DEBUG] run_singularity.sh: Captured MOUNT_RSL_RL_PATH as: $MOUNT_RSL_RL_PATH"
            else
                echo "[ERROR] run_singularity.sh: --mount_rsl_rl requires a value." >&2; exit 1;
            fi
            ;;
        *)
            echo "[WARNING] Unknown mount argument: $arg_val"
            ;;
    esac
    i=$((i+1))
done

echo "[DEBUG] run_singularity.sh: Final MOUNT_ISAACLAB_PATH: $MOUNT_ISAACLAB_PATH"
echo "[DEBUG] run_singularity.sh: Final MOUNT_RSL_RL_PATH: $MOUNT_RSL_RL_PATH"
echo "[DEBUG] run_singularity.sh: Final SCRIPT_ARGS: ${SCRIPT_ARGS[*]}"
echo "[DEBUG] run_singularity.sh: Number of script args: ${#SCRIPT_ARGS[@]}"

#==
# Helper functions
#==

setup_directories() {
    # Check and create directories
    for dir in \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/cache/kit" \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/cache/ov" \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/cache/pip" \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/cache/glcache" \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/cache/computecache" \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/logs" \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/data" \
        "${CLUSTER_ISAAC_SIM_CACHE_DIR}/documents"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "Created directory: $dir"
        fi
    done
}

#==
# Main
#==

# get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# load variables to set the Isaac Lab path on the cluster
ENV_CLUSTER_PATH=${3:-"$SCRIPT_DIR/.env.cluster"}
ENV_BASE_PATH=${4:-"$SCRIPT_DIR/../.env.ext_template"}

# load variables to set the Isaac Lab path on the cluster
echo "[DEBUG] Loading environment from: $ENV_CLUSTER_PATH"
echo "[DEBUG] Loading base environment from: $ENV_BASE_PATH"

if [ ! -f "$ENV_CLUSTER_PATH" ]; then
    echo "[ERROR] Cluster environment file not found: $ENV_CLUSTER_PATH"
    exit 1
fi

if [ ! -f "$ENV_BASE_PATH" ]; then
    echo "[ERROR] Base environment file not found: $ENV_BASE_PATH"
    exit 1
fi

source "$ENV_CLUSTER_PATH"
source "$ENV_BASE_PATH"

echo "[DEBUG] CLUSTER_USER: $CLUSTER_USER"
echo "[DEBUG] CLUSTER_SIF_PATH: $CLUSTER_SIF_PATH"
echo "[DEBUG] Container profile: $2"

# make sure that all directories exists in cache directory
setup_directories
# copy all cache files
cp -r $CLUSTER_ISAAC_SIM_CACHE_DIR $TMPDIR

# make sure logs directory exists (in the permanent isaaclab directory)
mkdir -p "$CLUSTER_ISAACLAB_DIR/logs"
touch "$CLUSTER_ISAACLAB_DIR/logs/.keep"

# copy the temporary isaaclab directory with the latest changes to the compute node
cp -r $1 $TMPDIR
# Get the directory name
dir_name=$(basename "$1")

# if defined, remove the temporary isaaclab directory pushed when the job was submitted
echo "[DEBUG] REMOVE_CODE_COPY_AFTER_JOB: $REMOVE_CODE_COPY_AFTER_JOB"
if [ "$REMOVE_CODE_COPY_AFTER_JOB" = "true" ]; then
    echo "[DEBUG] Attempting to remove temporary directory early: $1"
    # cd to a neutral directory before removing. Using a subshell with cd /
    (cd / && rm -rf "$1") || echo "[WARNING] Failed to remove $1 early."
else
    echo "[DEBUG] Keeping temporary directory as per REMOVE_CODE_COPY_AFTER_JOB=$REMOVE_CODE_COPY_AFTER_JOB: $1"
fi

# copy container to the compute node
echo "[DEBUG] Extracting container: $CLUSTER_SIF_PATH/$2.tar"
if [ ! -f "$CLUSTER_SIF_PATH/$2.tar" ]; then
    echo "[ERROR] Container file not found: $CLUSTER_SIF_PATH/$2.tar"
    exit 1
fi

tar -xf $CLUSTER_SIF_PATH/$2.tar -C $TMPDIR
echo "[DEBUG] Container extracted successfully"

# Determine binding strategy based on environment variables
SINGULARITY_BINDS=""

# Always bind cache directories
SINGULARITY_BINDS="$SINGULARITY_BINDS -B $TMPDIR/docker-isaac-sim/cache/kit:${DOCKER_ISAACSIM_ROOT_PATH}/kit/cache:rw"
SINGULARITY_BINDS="$SINGULARITY_BINDS -B $TMPDIR/docker-isaac-sim/cache/ov:${DOCKER_USER_HOME}/.cache/ov:rw"
SINGULARITY_BINDS="$SINGULARITY_BINDS -B $TMPDIR/docker-isaac-sim/cache/pip:${DOCKER_USER_HOME}/.cache/pip:rw"
SINGULARITY_BINDS="$SINGULARITY_BINDS -B $TMPDIR/docker-isaac-sim/cache/glcache:${DOCKER_USER_HOME}/.cache/nvidia/GLCache:rw"
SINGULARITY_BINDS="$SINGULARITY_BINDS -B $TMPDIR/docker-isaac-sim/cache/computecache:${DOCKER_USER_HOME}/.nv/ComputeCache:rw"
SINGULARITY_BINDS="$SINGULARITY_BINDS -B $TMPDIR/docker-isaac-sim/logs:${DOCKER_USER_HOME}/.nvidia-omniverse/logs:rw"
SINGULARITY_BINDS="$SINGULARITY_BINDS -B $TMPDIR/docker-isaac-sim/data:${DOCKER_USER_HOME}/.local/share/ov/data:rw"
SINGULARITY_BINDS="$SINGULARITY_BINDS -B $TMPDIR/docker-isaac-sim/documents:${DOCKER_USER_HOME}/Documents:rw"

# Bind logs directory
SINGULARITY_BINDS="$SINGULARITY_BINDS -B $CLUSTER_ISAACLAB_DIR/logs:$DOCKER_ISAACLAB_PATH/logs:rw"

# NEW: Check for unified mount config file
MOUNT_CONFIG_FILE="$TMPDIR/$dir_name/docker/.mount.config"
if [ -f "$MOUNT_CONFIG_FILE" ]; then
    echo "[INFO] Found unified mount configuration file"
    
    # Use Python to parse mount config and generate binds
    ADDITIONAL_BINDS=$(python3 - <<EOF
import json
import os
import sys

with open("$MOUNT_CONFIG_FILE", 'r') as f:
    config = json.load(f)

# Get cluster user from environment - passed directly from shell
cluster_user = "$CLUSTER_USER"
print(f"[DEBUG] Python: CLUSTER_USER = {cluster_user}", file=sys.stderr)

# Check if CLUSTER_USER was properly set
if not cluster_user or cluster_user == "" or cluster_user.startswith("$"):
    print("[ERROR] CLUSTER_USER environment variable is not set or not expanded!", file=sys.stderr)
    sys.exit(1)

binds = []
for mount_name, mount_config in config.get('mounts', {}).items():
    if not mount_config.get('enabled', False):
        continue
    
    # Determine which path to use
    if mount_config.get('sync_to_cluster', True):
        # Use cluster_path that was set during sync
        mount_path = mount_config.get('cluster_path', '')
        if not mount_path:
            print(f"[WARNING] No cluster path for {mount_name}, skipping", file=sys.stderr)
            continue
    else:
        # Use cluster_path for mount-only mode
        mount_path = mount_config.get('cluster_path', '')
        if not mount_path:
            print(f"[WARNING] No cluster path set for mount-only {mount_name}, skipping", file=sys.stderr)
            continue
    
    # Expand environment variables in mount_path
    original_path = mount_path
    # Expand $CLUSTER_USER and any other environment variables
    mount_path = mount_path.replace('$CLUSTER_USER', cluster_user)
    # Also handle ${CLUSTER_USER} syntax
    mount_path = mount_path.replace('${CLUSTER_USER}', cluster_user)
    print(f"[DEBUG] Python: Mount {mount_name}: {original_path} -> {mount_path}", file=sys.stderr)
    
    container_path = mount_config['container_path']
    
    # Handle special cases
    if mount_name == 'isaaclab' and mount_config.get('mount_type') == 'source':
        # Mount only source directory for IsaacLab
        binds.append(f"-B {mount_path}/source:{container_path}/source:rw")
    elif mount_name == 'rsl_rl':
        # Check if we need to use subdirectory
        if os.path.exists(f"{mount_path}/rsl_rl/__init__.py"):
            binds.append(f"-B {mount_path}/rsl_rl:{container_path}:rw")
        else:
            binds.append(f"-B {mount_path}:{container_path}:rw")
    else:
        # Default mount
        binds.append(f"-B {mount_path}:{container_path}:rw")

print(' '.join(binds))
EOF
)
    
    # Check if Python script failed
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to parse mount configuration"
        exit 1
    fi
    
    if [ -n "$ADDITIONAL_BINDS" ]; then
        # Expand any remaining environment variables in the bind paths
        ADDITIONAL_BINDS=$(echo "$ADDITIONAL_BINDS" | sed "s/\$CLUSTER_USER/$CLUSTER_USER/g")
        echo "[INFO] Adding mounts from unified config: $ADDITIONAL_BINDS"
        SINGULARITY_BINDS="$SINGULARITY_BINDS $ADDITIONAL_BINDS"
    fi
else
    echo "[INFO] No unified mount config found. Using built-in IsaacLab and RSL-RL."
    echo "[INFO] To configure external mounts, run './container.sh mount-setup' locally before pushing to cluster."
fi

# Always mount the extension
if [ -z "$DOCKER_EXT_PATH" ]; then echo "[ERROR] DOCKER_EXT_PATH is not set!"; exit 1; fi
SINGULARITY_BINDS="$SINGULARITY_BINDS -B $TMPDIR/$dir_name:$DOCKER_EXT_PATH:rw"
echo "[DEBUG] Extension $EXTENSION_NAME mounted at $DOCKER_EXT_PATH from $TMPDIR/$dir_name"

# Set ISAACLAB_PATH environment variable
CONTAINER_ENV_VARS="export ISAACLAB_PATH=/workspace/isaaclab"

# execute command in singularity container
echo "[DEBUG] Starting singularity container: $TMPDIR/$2.sif"
echo "[DEBUG] Container environment: $CONTAINER_ENV_VARS"
echo "[DEBUG] Target working directory in container: $DOCKER_EXT_PATH"
echo "[DEBUG] Python executable to be called: $CLUSTER_PYTHON_EXECUTABLE"
echo "[DEBUG] Script arguments: ${SCRIPT_ARGS[*]}"
echo "[DEBUG] WANDB_API_KEY: ${WANDB_API_KEY:0:10}..." # Show only first 10 chars for security
echo "[DEBUG] WANDB_USERNAME: $WANDB_USERNAME"

# Set up environment variables for WANDB
WANDB_ENV_VARS=""
if [ -n "${WANDB_MODE:-}" ]; then
    WANDB_ENV_VARS="$WANDB_ENV_VARS export WANDB_MODE='$WANDB_MODE' &&"
fi
if [ -n "${WANDB_API_KEY:-}" ]; then
    WANDB_ENV_VARS="$WANDB_ENV_VARS export WANDB_API_KEY='$WANDB_API_KEY' &&"
fi
if [ -n "${WANDB_USERNAME:-}" ]; then
    WANDB_ENV_VARS="$WANDB_ENV_VARS export WANDB_USERNAME='$WANDB_USERNAME' &&"
fi

# NOTE: ISAACLAB_PATH is normally set in `isaaclab.sh` but we directly call the isaac-sim python because we sync the entire
# Isaac Lab directory to the compute node and remote the symbolic link to isaac-sim

# Pass script args as environment variable to avoid expansion issues
SCRIPT_ARGS_STRING="${SCRIPT_ARGS[*]}"

# Add debug output
echo "[DEBUG] SCRIPT_ARGS array has ${#SCRIPT_ARGS[@]} elements"
for i in "${!SCRIPT_ARGS[@]}"; do
    echo "[DEBUG] SCRIPT_ARGS[$i] = '${SCRIPT_ARGS[$i]}'"
done
echo "[DEBUG] SCRIPT_ARGS_STRING = '$SCRIPT_ARGS_STRING'"

singularity exec \
    $SINGULARITY_BINDS \
    --nv --containall --writable-tmpfs \
    --env "WANDB_MODE=${WANDB_MODE:-offline}" \
    --env "ISAACLAB_PATH=/workspace/isaaclab" \
    --env "SCRIPT_ARGS_STRING=$SCRIPT_ARGS_STRING" \
    $TMPDIR/$2.sif bash -c "
        # Source both bashrc files to get Python aliases
        source /etc/bash.bashrc 2>/dev/null || true
        source /home/bash.bashrc 2>/dev/null || true
        cd $DOCKER_EXT_PATH
        export ISAACLAB_PATH=/workspace/isaaclab
        $WANDB_ENV_VARS
        
        # Debug information
        echo '[CONTAINER] Current directory:' \$(pwd)
        echo '[CONTAINER] ISAACLAB_PATH:' \$ISAACLAB_PATH
        echo '[CONTAINER] Checking if _isaac_sim exists:' \$(ls -la \$ISAACLAB_PATH/_isaac_sim 2>/dev/null | head -5 || echo '_isaac_sim directory not found')
        echo '[CONTAINER] Checking python.sh:' \$(ls -la \$ISAACLAB_PATH/_isaac_sim/python.sh 2>/dev/null || echo 'python.sh not found')
        echo '[CONTAINER] Python aliases:' \$(alias | grep python || echo 'No python aliases found')
        echo '[CONTAINER] PATH:' \$PATH
        echo '[CONTAINER] Running python from:' \$(which python 2>/dev/null || echo 'python not found in PATH')
        
        # Set up Python function instead of alias (aliases don't work in non-interactive bash)
        if ! command -v python >/dev/null 2>&1; then
            echo '[CONTAINER] Setting up Python function manually'
            function python() { \$ISAACLAB_PATH/_isaac_sim/python.sh \"\$@\"; }
            function python3() { \$ISAACLAB_PATH/_isaac_sim/python.sh \"\$@\"; }
            export -f python python3
        fi
        
        echo '[CONTAINER] Python version:' \$(python --version 2>/dev/null || echo 'python command failed')
        echo '[CONTAINER] Direct python.sh test:' \$(\$ISAACLAB_PATH/_isaac_sim/python.sh --version 2>/dev/null || echo 'direct python.sh failed')
        echo '[CONTAINER] PYTHONPATH:' \$PYTHONPATH
        echo '[CONTAINER] Listing /workspace:' \$(ls /workspace 2>/dev/null || echo '/workspace not found or empty')
        echo '[CONTAINER] Listing /workspace/isaaclab:' \$(ls /workspace/isaaclab 2>/dev/null || echo '/workspace/isaaclab not found or empty')
        echo '[CONTAINER] Listing $DOCKER_EXT_PATH:' \$(ls $DOCKER_EXT_PATH 2>/dev/null || echo '$DOCKER_EXT_PATH not found or empty')
        echo '[CONTAINER] Python sys.path:'
        python -c 'import sys; print(sys.path)' 2>/dev/null || echo 'Failed to get Python sys.path'
        echo '[CONTAINER] Direct python.sh sys.path:'
        \$ISAACLAB_PATH/_isaac_sim/python.sh -c 'import sys; print(sys.path)' 2>/dev/null || echo 'Failed to get direct python.sh sys.path'
        echo '[CONTAINER] Attempting to import isaaclab.app:'
        python -c 'from isaaclab.app import AppLauncher; print(\"AppLauncher imported successfully\")' 2>/dev/null || echo 'Failed to import isaaclab.app'
        echo '[CONTAINER] Direct python.sh isaaclab.app import:'
        \$ISAACLAB_PATH/_isaac_sim/python.sh -c 'from isaaclab.app import AppLauncher; print(\"AppLauncher imported successfully\")' 2>/dev/null || echo 'Failed to import isaaclab.app with direct python.sh'
        echo '[CONTAINER] Checking RSL-RL installation:'
        echo '[CONTAINER] RSL-RL site-packages location:' \$(ls -la \$ISAACLAB_PATH/_isaac_sim/kit/python/lib/python3.10/site-packages/ | grep rsl_rl || echo 'No rsl_rl found in site-packages')
        echo '[CONTAINER] RSL-RL directory contents:' \$(ls -la \$ISAACLAB_PATH/_isaac_sim/kit/python/lib/python3.10/site-packages/rsl_rl/ 2>/dev/null | head -10 || echo 'RSL-RL directory not accessible')
        echo '[CONTAINER] Testing RSL-RL import:'
        python -c 'import rsl_rl; print(\"RSL-RL version:\", rsl_rl.__version__ if hasattr(rsl_rl, \"__version__\") else \"no version info\")' 2>/dev/null || echo 'Failed to import rsl_rl'
        echo '[CONTAINER] Testing RSL-RL runners import:'
        python -c 'from rsl_rl.runners import OnPolicyRunner; print(\"OnPolicyRunner imported successfully\")' 2>/dev/null || echo 'Failed to import rsl_rl.runners'
        echo '[CONTAINER] Running main script: $CLUSTER_PYTHON_EXECUTABLE'
        echo '[CONTAINER] Script arguments: \$SCRIPT_ARGS_STRING'
        \$ISAACLAB_PATH/_isaac_sim/python.sh $CLUSTER_PYTHON_EXECUTABLE \$SCRIPT_ARGS_STRING
    "

# copy resulting cache files back to host
echo "[DEBUG] Copying cache files back to host"
rsync -azPv $TMPDIR/docker-isaac-sim $CLUSTER_ISAAC_SIM_CACHE_DIR/..

# if defined, remove the temporary isaaclab directory pushed when the job was submitted
echo "(run_singularity.sh): Return"