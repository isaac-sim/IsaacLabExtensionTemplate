# Docker Setup for IsaacLab Extension Template

This guide provides comprehensive documentation for building, running, and deploying IsaacLab extension containers for both local development and cluster deployment.

## Table of Contents

- [Quick Start: Local Development](#quick-start-local-development)
- [Prerequisites](#prerequisites)
- [Core Concepts](#core-concepts)
  - [Container Types](#container-types)
  - [User Permissions System](#user-permissions-system)
- [Usage Guide](#usage-guide)
  - [The container.sh Script](#the-containersh-script)
  - [Building the Containers](#building-the-containers)
  - [Running Containers & Workflows](#running-containers--workflows)
  - [Managing External Mounts](#managing-external-mounts)
- [Cluster Deployment](#cluster-deployment)
- [Troubleshooting](#troubleshooting)
- [Migration Guide](#migration-guide)
- [Best Practices](#best-practices)

## Quick Start: Local Development

This is the fastest way to get a development environment running.

1. **Set up environment files:**
   ```bash
   # Run this once to create your local .env files
   cp docker/.env.ext_template.template docker/.env.ext_template
   cp docker/.env.ext_template-dev.template docker/.env.ext_template-dev
   # You can optionally edit these files with custom settings.
   ```

2. **Validate your setup:**
   ```bash
   # Test basic Docker functionality
   docker --version

   # Verify environment files are configured
   ./docker/run_dev.sh --help

   # Test mount configuration system
   ./docker/container.sh mount-show
   ```

3. **Run the development container:**
   ```bash
   # Start an interactive shell in the dev container
   ./docker/run_dev.sh

   # Or, run a specific command directly
   ./docker/run_dev.sh python scripts/rsl_rl/train.py --task YourTask
   ```

   > **Note:** For systems where you don't have root access for Docker (e.g., some university PCs), use the `--rootless` flag:
   > ```bash
   > ./docker/run_dev.sh --rootless
   > ```

## Prerequisites

- [ ] NVIDIA GPU with current drivers installed
- [ ] Docker and Docker Compose installed
- [ ] NVIDIA Container Toolkit installed ([installation guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html))
- [ ] For local development, optionally symlink IsaacLab as `_isaaclab` in the repository root

### Environment Files Setup

Before running any extension containers, you must create and configure the environment files from their templates:

#### Step 1: Copy Templates
```bash
# Create the required .env files
cp docker/.env.ext_template.template docker/.env.ext_template
cp docker/.env.ext_template-dev.template docker/.env.ext_template-dev
```

#### Step 2: Configure Environment Files

Edit `docker/.env.ext_template-dev` with your specific paths:

```bash
# =========================
# Extension Configuration
# =========================
EXTENSION_NAME=ext_template
EXTENSION_FOLDER=/path/to/your/project/folder        # ← CHANGE THIS
EXT_PATH=$EXTENSION_FOLDER
DOCKER_EXT_PATH=/workspace/$EXTENSION_NAME

# =========================
# Docker User Configuration  
# =========================
HOST_HOME=/home/your_username                        # ← CHANGE THIS
DOCKER_USER_NAME=your_username                       # ← CHANGE THIS  
DOCKER_USER_HOME=/home/your_username                 # ← CHANGE THIS
```

**Example Configuration:**
```bash
EXTENSION_FOLDER=/home/alice/projects/IsaacLabExtensionTemplate
HOST_HOME=/home/alice
DOCKER_USER_NAME=alice
DOCKER_USER_HOME=/home/alice
```

#### Step 3: Validate Configuration
```bash
# Verify environment files are correctly configured
./docker/run_dev.sh --help
# Should show help without errors about missing environment files
```

## Core Concepts

### Container Types

Two primary containers are provided:

- **Production (`isaac-lab-ext`)**:
  - **Dockerfile:** `Dockerfile.ext`
  - **Purpose:** A minimal, lightweight container designed for headless training and cluster deployment
  - **Includes:** Isaac Lab (with RSL-RL) and your extension
  - **Excludes:** ROS2, GUI tools, and other development dependencies

- **Development (`isaac-lab-ext-dev`)**:
  - **Dockerfile:** `Dockerfile.ext-dev`
  - **Purpose:** A full-featured environment for local development and debugging
  - **Includes:** Everything in the production container, plus ROS2 Humble, development tools (like pytest, ruff), and GPU-accelerated libraries

### User Permissions System

To prevent file ownership issues when mounting local directories, the development container synchronizes the container's user with your host's user ID (UID) and group ID (GID).

- **Default Mode (User-Preserving):** Files created inside the container are owned by you on the host. This is the recommended mode for personal machines.
- **Rootless Mode (`--rootless`):** Runs as root inside the container. This simplifies permissions and is ideal for environments where you cannot manage Docker users.

| Use Case | Command | Outcome |
|----------|---------|---------|
| Personal Dev Machine | `./docker/run_dev.sh` | Files created match your host user |
| Restricted PC (No Root) | `./docker/run_dev.sh --rootless` | Runs as root inside the container |
| Auto-Fix Permissions | `./docker/run_dev.sh --fix-perms` | chowns files to your user on exit |
| Shared Server | `./docker/run_dev.sh -u 2000 -g 2000` | Uses a custom UID/GID |

### Quick Start with run_dev.sh

The `run_dev.sh` script provides the easiest way to get started:

```bash
# Basic usage - start interactive shell
./docker/run_dev.sh

# Run a command
./docker/run_dev.sh python scripts/rsl_rl/train.py --task=YourTask

# Rootless mode (for restricted environments)
./docker/run_dev.sh --rootless

# With permission fixing
./docker/run_dev.sh --fix-perms

# Custom user/group
./docker/run_dev.sh --uid 1001 --gid 1001
```

## Usage Guide

### The container.sh Script

The `./docker/container.sh` script is the main interface for managing containers. The `./docker/run_dev.sh` script is a convenient wrapper that provides easy mode switching and user-friendly options.

**Basic Syntax:** `./docker/container.sh -p <profile> <command>`

| Command | Description | Example |
|---------|-------------|---------|
| `build` | Builds the container image | `./docker/container.sh -p ext-dev build` |
| `run` | Runs the container | `./docker/container.sh -p ext-dev run` |
| `attach` | Attaches to a running container | `./docker/container.sh -p ext-dev attach` |
| `exec` | Executes a command in a running container | `./docker/container.sh -p ext-dev exec nvidia-smi` |
| `logs` | Shows container logs | `./docker/container.sh -p ext-dev logs` |
| `mount-setup` | Interactively configure mounts | `./docker/container.sh mount-setup` |

### Building the Containers

First, ensure you have the base images from IsaacLab. If not, build them from the IsaacLab-Internal repository:

#### Prerequisites: Building Base IsaacLab Containers

Before building extension containers, you need to build the base IsaacLab containers from the [IsaacLab-Internal repository](https://github.com/leggedrobotics/IsaacLab-Internal).

1. **Clone and navigate to IsaacLab-Internal:**
   ```bash
   git clone https://github.com/leggedrobotics/IsaacLab-Internal
   cd IsaacLab-Internal/docker
   ```

2. **Build the base containers:**
   ```bash
   # Build the ROS2 base container
   docker compose --env-file docker/.env.ros2 --file docker/docker-compose.yaml build isaac-lab-ros2
   
   # Build and run the base container
   docker compose --env-file docker/.env.base --file docker/docker-compose.yaml run isaac-lab-base
   ```

#### Building Extension Containers

Once you have the base images, you can build the extension containers:

```bash
# Build the development container (most common)
./docker/container.sh -p ext-dev build

# Build the production container
./docker/container.sh -p ext build
```

### Running Containers & Workflows

**Development:**
```bash
# Start an interactive shell (recommended - use run_dev.sh)
./docker/run_dev.sh

# Run a specific training task (recommended - use run_dev.sh)
./docker/run_dev.sh python scripts/rsl_rl/train.py --task=YourTask

# Alternative: Using container.sh directly
./docker/container.sh -p ext-dev run
./docker/container.sh -p ext-dev run python scripts/rsl_rl/train.py --task=YourTask
```

**Production:**
```bash
# Run a headless training job in the production container
./docker/container.sh -p ext run python scripts/rsl_rl/train.py \
   --task=YourTask --num_envs 1024
```

### Managing External Mounts

You can optionally mount external checkouts of isaaclab or rsl_rl to override the versions built into the container. This is useful for development.

```bash
# Start the interactive setup wizard (recommended)
./docker/container.sh mount-setup

# Manually enable/disable a mount
./docker/container.sh mount-enable isaaclab
./docker/container.sh mount-disable isaaclab

# Manually set a mount path
./docker/container.sh mount-set isaaclab ~/dev/my-isaaclab

# Check your current mount configuration
./docker/container.sh mount-show
```

This system works by creating a `.mount.config` file and auto-generating a `docker-compose.override.yaml` which is git-ignored.

## Cluster Deployment

For detailed cluster operations, see `docker/cluster/README.md`.

**Quick Cluster Workflow:**
```bash
# 1. (Optional) Configure mounts for cluster usage
./docker/container.sh mount-setup

# 2. Set up cluster environment (first time only)
cp docker/cluster/.env.cluster.template docker/cluster/.env.cluster
# Edit .env.cluster with your cluster-specific settings

# 3. Navigate to the cluster directory
cd docker/cluster

# 4. Push the container image to the cluster's registry
./cluster_interface.sh push ext_template

# 5. Submit a job
./cluster_interface.sh job ext_template --task YourTask --num_envs 64000

# 6. Sync results back to local machine
./sync_experiments.sh --remove ~/experiments/logs
```

## System Requirements & Performance Expectations

### Docker Version Compatibility
**Tested Combinations:**
- Docker 24.0.7 + Apptainer 1.2.5
- Docker ≥ 27.0.0 + Apptainer ≥ 1.3.4

**System Requirements:**
- NVIDIA GPU with current drivers
- 20GB+ free disk space for containers
- 8GB+ RAM recommended for development
- Fast internet connection for initial builds

### Expected Performance
**Container Build Times:**
- Production container (`isaac-lab-ext`): ~5-10 minutes
- Development container (`isaac-lab-ext-dev`): ~10-15 minutes
- Subsequent builds with cache: ~2-5 minutes

**Container Sizes:**
- Production: ~26-27GB
- Development: ~50-52GB

**Cluster Operations:**
- Container push to cluster: ~5-15 minutes (depending on network)
- Code sync: ~30 seconds for typical extension
- Job submission: ~1-5 seconds

## Troubleshooting

### Problem: Docker/Apptainer Version Compatibility

When pushing to cluster, you may see warnings about non-tested Docker/Apptainer versions. The tested combinations are:
- Docker 24.0.7 + Apptainer 1.2.5
- Docker ≥ 27.0.0 + Apptainer ≥ 1.3.4

If you encounter issues with other versions, consider updating to a tested combination.

### Problem: Permission Denied on Mounted Files

**Cause:** Files created in the container are owned by root.

**Solution 1 (Recommended - Auto-fix):** Use the `--fix-perms` flag to automatically fix permissions on exit.
```bash
./docker/run_dev.sh --fix-perms
```

**Solution 2 (Rootless):** Use rootless mode if you don't need user-preserving permissions.
```bash
./docker/run_dev.sh --rootless
```

**Solution 3 (Manual Fix):** Manually change ownership on your host.
```bash
sudo chown -R $(id -u):$(id -g) .
```

### Problem: Build Fails or Old Layers Persist

**Solution:** Perform a clean rebuild.
```bash
./docker/container.sh -p ext-dev build --no-cache
```

### Problem: invalid spec: :/ssh-agent: empty section between colons warning

**Cause:** The `SSH_AUTH_SOCK` or `DISPLAY` environment variables are not set on your host. Docker Compose shows a warning but continues.

**Solution:** This is a harmless warning if you don't need SSH agent or GUI forwarding. To suppress it, you can set default values in your shell's startup file (e.g., `~/.bashrc` or `~/.zshrc`).
```bash
# Set default values for Docker environment variables
export SSH_AUTH_SOCK="${SSH_AUTH_SOCK:-/dev/null}"
export DISPLAY="${DISPLAY:-:0}"
```

### Problem: Environment File Not Found or Configured

**Cause:** Environment files not copied or paths not configured.

**Solution:**
1. Copy templates and configure paths:
   ```bash
   cp docker/.env.ext_template-dev.template docker/.env.ext_template-dev
   # Edit the file with your actual paths (see Environment Files Setup section)
   ```
2. Validate configuration:
   ```bash
   ./docker/run_dev.sh --help  # Should not show missing file errors
   ```

### Problem: Mount Configuration Missing

**Cause:** Docker compose override file not generated.

**Solution:**
```bash
# Generate mount configuration (even if not using external mounts)
cd docker
python3 mount_config.py generate
```

### Problem: Container Build Timeout or Failure

**Cause:** Network issues, insufficient disk space, or base image missing.

**Solution:**
1. Check available disk space: `df -h`
2. Ensure base images exist: `docker images | grep isaac-lab`
3. Clean Docker cache if needed: `docker system prune`
4. Try building with no cache: `./docker/container.sh -p ext-dev build --no-cache`

### Problem: GPU Not Accessible Inside Container

**Solution:**
1. Verify `nvidia-smi` works on the host
2. Verify NVIDIA Container Toolkit is installed:
   ```bash
   docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu20.04 nvidia-smi
   ```
3. Verify `nvidia-smi` works inside the container:
   ```bash
   ./docker/container.sh -p ext-dev exec nvidia-smi
   ```
4. Ensure your NVIDIA drivers are up to date

## Best Practices

- **Development:** Use `./docker/run_dev.sh` for all local development - it provides the easiest interface
- **Production:** Use the `isaac-lab-ext` container for cluster jobs and performance tests to minimize overhead
- **Mounts:** Prefer the built-in libraries for stability. Only use external mounts when actively developing on them
- **Permissions:** On your personal machine, use the default user-preserving mode. Use `--fix-perms` if you encounter ownership issues
- **Environment Setup:** Always copy and configure the environment templates before first use
- **Cluster Operations:** Set up the cluster environment file before pushing containers to cluster

### File Structure Overview

```
docker/
├── README.md                           # This documentation
├── run_dev.sh                         # Convenience script for development
├── container.sh                       # Main container management script
├── mount_config.py                    # Mount configuration management
├── Dockerfile.ext                     # Production container
├── Dockerfile.ext-dev                 # Development container
├── docker-compose.yaml                # Container definitions
├── docker-compose.override.yaml.template # Template for mount overrides
├── .env.ext_template.template         # Production environment template
├── .env.ext_template-dev.template     # Development environment template
├── entrypoint.sh                      # Container entrypoint
├── dynamic_entrypoint.sh              # Multi-mode entrypoint
└── cluster/                           # Cluster deployment scripts
    ├── README.md                      # Cluster-specific documentation
    ├── cluster_interface.sh           # Main cluster interface
    ├── .env.cluster.template          # Cluster environment template
    ├── submit_job_slurm.sh            # SLURM job submission
    ├── submit_job_pbs.sh              # PBS job submission
    ├── sync_experiments.sh            # Experiment syncing
    └── sync_mounts.py                 # Mount syncing for cluster
```