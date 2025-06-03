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

2. **Run the development container:**
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

Before running any extension containers, you must create the environment files from their templates:

```bash
# Create the required .env files
cp docker/.env.ext_template.template docker/.env.ext_template
cp docker/.env.ext_template-dev.template docker/.env.ext_template-dev
```

These files contain container-specific configuration and are required for the containers to start properly. You can edit them to customize settings if needed, but the defaults should work for most use cases.

## Core Concepts

### Container Types

Two primary containers are provided:

- **Production (`isaac-lab-ext`)**:
  - **Dockerfile:** `Dockerfile.ext`
  - **Purpose:** A minimal, lightweight container designed for headless training and cluster deployment
  - **Includes:** Isaac Lab, RSL-RL, and your extension
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

## Usage Guide

### The container.sh Script

The `./docker/container.sh` script is the main interface for managing containers. The `./docker/run_dev.sh` script is a convenient wrapper around it.

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
# Start an interactive shell
./docker/container.sh -p ext-dev run

# Run a specific training task
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

**Quick Workflow:**
```bash
# 1. (Optional) Configure mounts for cluster usage
./docker/container.sh mount-setup

# 2. Navigate to the cluster directory
cd docker/cluster

# 3. Push the container image to the cluster's registry
./cluster_interface.sh push ext_template

# 4. Submit a job
./cluster_interface.sh job ext_template --task YourTask --num_envs 64000
```

## Troubleshooting

### Problem: Docker/Apptainer Version Compatibility

When pushing to cluster, you may see warnings about non-tested Docker/Apptainer versions. The tested combinations are:
- Docker 24.0.7 + Apptainer 1.2.5
- Docker ≥ 27.0.0 + Apptainer ≥ 1.3.4

If you encounter issues with other versions, consider updating to a tested combination.

### Problem: Permission Denied on Mounted Files

**Cause:** Files created in the container are owned by root.

**Solution 1 (Auto-fix):** Use the `--fix-perms` flag to chown files on exit.
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

## Migration Guide

- **From 4-Container Setup:** The `ext-ros2` and `ext-dev-rootless` containers are now handled by the unified `ext-dev` container and its profile flags (`--rootless`)
- **From Old Mount System:** The old environment variables (`EXTERNAL_ISAACLAB_PATH`, etc.) are deprecated. Use the new mount management system: `./docker/container.sh mount-setup`

## Best Practices

- **Development:** Use the `isaac-lab-ext-dev` container for all local development
- **Production:** Use the `isaac-lab-ext` container for cluster jobs and performance tests to minimize overhead
- **Mounts:** Prefer the built-in libraries for stability. Only use external mounts when actively developing on them
- **Permissions:** On your personal machine, use the default user-preserving mode. Use `--fix-perms` if you encounter ownership issues