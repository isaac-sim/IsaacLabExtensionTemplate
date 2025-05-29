# Docker Setup for IsaacLab Extension Template

This guide provides comprehensive documentation for building, running, and deploying IsaacLab extension containers for both local development and cluster deployment.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Container Architecture](#container-architecture)
  - [Container Types](#container-types)
  - [Permission System](#permission-system)
- [Building Containers](#building-containers)
- [Running Containers](#running-containers)
  - [Development Workflow](#development-workflow)
  - [Production Usage](#production-usage)
- [Mount Configuration System](#mount-configuration-system)
  - [Quick Setup](#quick-setup)
  - [Mount Management](#mount-management)
  - [Technical Details](#technical-details)
- [Cluster Deployment](#cluster-deployment)
- [Troubleshooting](#troubleshooting)
- [Migration Guide](#migration-guide)

## Overview

The Docker setup provides two main containers:

1. **Production Container** (`isaac-lab-ext`) - Minimal container for training and cluster deployment
2. **Development Container** (`isaac-lab-ext-dev`) - Full-featured container with ROS2, development tools, and dual-mode support

Both containers include:
- Isaac Lab and Isaac Sim integration
- RSL-RL for reinforcement learning
- Your extension package
- Optional mounting of external codebases

## Prerequisites

1. **Docker and Docker Compose** installed on your system
2. **NVIDIA GPU** with appropriate drivers
3. **Environment files** - Create by copying templates:
   ```bash
   cp docker/.env.ext_template.template docker/.env.ext_template
   cp docker/.env.ext_template-dev.template docker/.env.ext_template-dev
   ```
   Edit these files with your settings (they're git-ignored).
4. **IsaacLab base images** - Either pull from DockerHub or build locally (see [Building Containers](#building-containers))

## Quick Start

### Using container.sh (Recommended)

```bash
# Build and run development container
./docker/container.sh -p ext-dev build
./docker/container.sh -p ext-dev run

# Run with a specific command
./docker/container.sh -p ext-dev run python scripts/rsl_rl/train.py --task YourTask

# Run in rootless mode (for systems without root Docker)
./docker/container.sh -p ext-dev-rootless run
```

### Production Container

```bash
# Build and run production container
./docker/container.sh -p ext build
./docker/container.sh -p ext run
```

## Container Architecture

### Container Types

#### 1. Production Container (`Dockerfile.ext`)
- **Base Image**: `isaac-lab-base`
- **Purpose**: Cluster deployment and training
- **Features**:
  - Minimal footprint for performance
  - Includes RSL-RL
  - No development tools or ROS2
- **Use Cases**: Training jobs, performance testing, deployment

#### 2. Development Container (`Dockerfile.ext-dev`)
- **Base Image**: `isaac-lab-ros2`
- **Purpose**: Local development with all features
- **Features**:
  - ROS2 packages and integration
  - Development tools (Claude Code, pytest, ruff, etc.)
  - Pinocchio robotics library
  - CUDA toolkit
  - Git LFS support
  - Dual-mode operation (root/rootless)
- **Use Cases**: Development, debugging, ROS2 integration, testing

### Permission System

The development container supports flexible permission management through two modes:

#### Root Mode (Default)
- Traditional Docker behavior with user switching
- Preserves host user permissions
- Files created match host user ownership
- Uses `gosu` for seamless user switching

#### Rootless Mode
- Everyone runs as root inside container
- Simplified permission model
- Suitable for Docker installations without root access
- Ideal for student PCs or restricted environments

#### Quick Permission Reference

| Use Case | Command | Result |
|----------|---------|--------|
| Personal dev machine | `./docker/container.sh -p ext-dev run` | Files owned by your user |
| Student PC (no root) | `./docker/container.sh -p ext-dev-rootless run` | Run as root inside container |
| Shared server | `FIX_PERMISSIONS=true ./docker/container.sh -p ext-dev run` | Auto-fix ownership on exit |

#### Environment Variables

- `DOCKER_ROOTLESS_MODE`: Enable rootless mode (true/false)
- `FIX_PERMISSIONS`: Auto-fix file permissions on exit (true/false)
- `LOCAL_UID`: Override user ID (default: current user)
- `LOCAL_GID`: Override group ID (default: current group)

## Building Containers

### Step 1: Obtain Base Images

```bash
# Option 1: Pull from DockerHub (recommended)
docker pull jmanan/isaac-lab-base:latest
docker tag jmanan/isaac-lab-base:latest isaac-lab-base

docker pull jmanan/isaac-lab-ros2:latest
docker tag jmanan/isaac-lab-ros2:latest isaac-lab-ros2

# Option 2: Build locally (if you have IsaacLab source)
cd /path/to/isaaclab
./docker/container.py build isaac-lab-base
./docker/container.py build isaac-lab-ros2
```

### Step 2: Build Extension Containers

```bash
# Build production container
./docker/container.sh -p ext build

# Build development container
./docker/container.sh -p ext-dev build
```

## Running Containers

### Development Workflow

```bash
# Standard development mode
./docker/container.sh -p ext-dev run

# Rootless mode for restricted systems
./docker/container.sh -p ext-dev-rootless run

# Run specific command
./docker/container.sh -p ext-dev run python scripts/rsl_rl/train.py --task YourTask

# Attach to running container
./docker/container.sh -p ext-dev attach

# Execute command in running container
./docker/container.sh -p ext-dev exec nvidia-smi
```

### Production Usage

```bash
# Run production container
./docker/container.sh -p ext run

# Training example
./docker/container.sh -p ext run python scripts/rsl_rl/train.py \
    --task YourTask --num_envs 1024
```

### Claude Code AI Assistant

The development container includes Claude Code for AI-assisted development:

```bash
# Inside the container
claude
```

## Mount Configuration System

The unified mount system allows optional mounting of external IsaacLab and RSL-RL codebases in both Docker and Singularity environments.

### Quick Setup

```bash
# Interactive setup
./docker/container.sh mount-setup

# This will:
# 1. Create .mount.config with your preferences
# 2. Validate paths
# 3. Generate docker-compose.override.yaml
```

### Mount Management

```bash
# Show current configuration
./docker/container.sh mount-show

# Enable/disable mounts
./docker/container.sh mount-enable isaaclab
./docker/container.sh mount-disable rsl_rl

# Set mount paths
./docker/container.sh mount-set isaaclab ~/my-isaaclab
./docker/container.sh mount-set rsl_rl ~/my-rsl-rl

# Validate configuration
./docker/container.sh mount-validate
```

### Technical Details

#### Configuration File (.mount.config)

```json
{
  "mounts": {
    "isaaclab": {
      "enabled": false,
      "local_path": "/path/to/isaaclab",
      "container_path": "/workspace/isaaclab",
      "mount_type": "source",  // Mounts only source/ subdirectory
      "description": "External IsaacLab installation"
    },
    "rsl_rl": {
      "enabled": false,
      "local_path": "/path/to/rsl_rl",
      "container_path": "/workspace/isaaclab/_isaac_sim/.../rsl_rl",
      "mount_type": "full",  // Completely overrides built-in
      "description": "External RSL-RL installation"
    }
  }
}
```

#### How It Works

1. **Configuration**: User preferences stored in `.mount.config`
2. **Docker**: Generates `docker-compose.override.yaml` with bind mounts
3. **Singularity**: Reads config and adds `-B` bind flags
4. **Validation**: Paths validated before container startup

The system uses Docker Compose's override mechanism, automatically merging:
- Base configuration: `docker-compose.yaml`
- User mounts: `docker-compose.override.yaml` (auto-generated)

## Cluster Deployment

For detailed cluster operations, see [docker/cluster/README.md](cluster/README.md).

### Quick Cluster Workflow

```bash
# 1. Configure mounts (optional)
./docker/container.sh mount-setup

# 2. Push container to cluster
cd docker/cluster
./cluster_interface.sh push ext_template

# 3. Submit job
./cluster_interface.sh job ext_template --task YourTask --num_envs 64000

# 4. Sync logs back
./sync_experiments.sh --remove ~/experiments/logs
```

## Troubleshooting

### Permission Issues

```bash
# Enable automatic permission fixing
export FIX_PERMISSIONS=true
./docker/container.sh -p ext-dev run

# Use rootless mode
./docker/container.sh -p ext-dev-rootless run

# Manually fix permissions
sudo chown -R $(id -u):$(id -g) /workspace/ext_template
```

### Build Issues

```bash
# Clean rebuild
docker compose build --no-cache isaac-lab-ext-dev

# Remove old images
docker image prune -f

# Check logs
./docker/container.sh -p ext-dev logs
```

### Mount Issues

```bash
# Validate mounts
./docker/container.sh mount-validate

# Regenerate override file
./docker/container.sh -r -p ext-dev run

# Check mounted paths inside container
./docker/container.sh -p ext-dev exec ls -la /workspace/isaaclab/source
```

### GPU Access

```bash
# Verify host GPU
nvidia-smi

# Check container GPU access
./docker/container.sh -p ext-dev exec nvidia-smi

# For rootless mode
export NVIDIA_DRIVER_CAPABILITIES=all
./docker/container.sh -p ext-dev-rootless run
```

## Migration Guide

### From Simple Docker Setup

If using the previous simple Docker setup:
- The single Dockerfile has been replaced with two specialized containers
- Use `ext` for production/training
- Use `ext-dev` for development

### From Environment Variables

Old approach with environment variables:
```bash
EXTERNAL_ISAACLAB_PATH=/path/to/isaaclab  # No longer used
EXTERNAL_RSL_RL_PATH=/path/to/rsl_rl      # No longer used
```

New approach:
```bash
./docker/container.sh mount-setup  # Interactive configuration
# or
./docker/container.sh mount-set isaaclab /path/to/isaaclab
```

## Best Practices

1. **Container Selection**:
   - Use production container for cluster training and deployment
   - Use development container for local development and debugging

2. **Permission Management**:
   - Enable `FIX_PERMISSIONS` when working with mounted volumes
   - Use rootless mode on systems without root Docker access

3. **Mount Configuration**:
   - Prefer built-in IsaacLab/RSL-RL for stability
   - Test mounts locally before cluster deployment
   - Don't commit `.mount.config` or `docker-compose.override.yaml`

4. **Performance**:
   - Use production container for training to minimize overhead
   - Limit mounted volumes to necessary paths only