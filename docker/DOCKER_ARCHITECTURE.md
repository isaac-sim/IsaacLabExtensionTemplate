# Docker Container Architecture

This document describes the simplified Docker container architecture for IsaacLab extensions.

## Overview

The Docker setup has been simplified from 4 containers to 2 containers:

1. **Production Container** (`isaac-lab-ext`) - For cluster deployment and training
2. **Development Container** (`isaac-lab-ext-dev`) - Unified development container with ROS2 and dual-mode support

## Container Details

### 1. Production Container (Dockerfile.ext)

- **Purpose**: Minimal container for cluster deployment and training
- **Base Image**: `isaac-lab-base`
- **Features**:
  - Minimal package installation for reduced size
  - Includes rsl_rl for reinforcement learning
  - Optimized for training performance
  - No development tools or ROS2

**Usage**:
```bash
./container.sh -p ext build
./container.sh -p ext run
```

### 2. Development Container (Dockerfile.ext-dev)

- **Purpose**: Unified development environment with all features
- **Base Image**: `isaac-lab-ros2`
- **Features**:
  - All ROS2 packages and dependencies
  - Development tools (Claude Code, git-lfs, pytest, etc.)
  - Pinocchio robotics library
  - CUDA toolkit
  - Dual-mode support (root/rootless)

**Usage**:
```bash
# Standard mode (with user switching)
./container.sh -p ext-dev build
./container.sh -p ext-dev run

# Rootless mode (everyone runs as root)
./container.sh -p ext-dev-rootless run
```

## Dual-Mode Operation

The development container supports two modes of operation:

### Root Mode (Default)
- Traditional Docker behavior with user switching
- Uses gosu to switch to the host user inside container
- Preserves host user permissions
- Full access to host filesystem via bind mounts

### Rootless Mode
- Everyone runs as root inside the container
- Simplified permission model
- Reduced host system access
- Suitable for environments where Docker daemon doesn't have root access

### Mode Selection

The mode is controlled by the `DOCKER_ROOTLESS_MODE` environment variable:

```bash
# Force rootless mode
export DOCKER_ROOTLESS_MODE=true
./container.sh -p ext-dev run

# Or use the rootless service
./container.sh -p ext-dev-rootless run
```

## Flexible Permission System

The development container implements a sophisticated permission management system that handles various deployment scenarios and permission requirements.

### How It Works

#### 1. Dynamic User Creation (Root Mode)
When running in root mode (default), the container dynamically creates a user matching your host system:

```bash
# Automatically detects host user
USER_ID=${LOCAL_UID:-$(id -u)}  # Your host UID
GROUP_ID=${LOCAL_GID:-$(id -g)}  # Your host GID

# Creates matching user inside container
groupadd -g $GROUP_ID -o $USER_NAME
useradd -m -u $USER_ID -g $GROUP_ID -o -s /bin/bash $USER_NAME

# Switches to that user with gosu
exec gosu $USER_NAME bash
```

This ensures files created in the container have the same ownership as on your host system.

#### 2. Rootless Mode Operation
In rootless mode, everyone runs as root inside the container:
- No user switching occurs
- Simplified permission model
- Ideal for Docker installations without root access
- All operations happen as UID 0 within container

#### 3. Automatic Permission Fixing
The `FIX_PERMISSIONS` feature automatically corrects file ownership when the container exits:

```bash
# Enable permission fixing
export FIX_PERMISSIONS=true
./docker/run_dev.sh

# On container exit, automatically runs:
find "/workspace/${EXTENSION_NAME}" -user root -exec chown ${USER_ID}:${GROUP_ID} {} \;
```

#### 4. Background Permission Setup
Large directories are fixed in the background to avoid startup delays:
- `/isaac-sim/kit` permissions are corrected asynchronously
- Container is immediately usable while permissions are being fixed
- Check `~/.permissions_done` file to verify completion

### Usage Scenarios

#### Scenario 1: Personal Development Machine
```bash
# Standard mode - preserves your user permissions
./docker/run_dev.sh
# Files created as: youruser:yourgroup
```

#### Scenario 2: Student PC (No Root Docker)
```bash
# Rootless mode - everyone is root inside
./docker/run_dev.sh --rootless
# Files created as: root:root (inside container)
```

#### Scenario 3: Shared Development Server
```bash
# Custom UID/GID with permission fixing
./docker/run_dev.sh -u 2000 -g 2000 --fix-perms
# Files created as: uid=2000:gid=2000
```

#### Scenario 4: CI/CD Pipeline
```bash
# Rootless with no permission concerns
export DOCKER_ROOTLESS_MODE=true
./docker/container.sh -p ext-dev run python scripts/test.py
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_ROOTLESS_MODE` | `false` | Enable rootless mode (true/false) |
| `FIX_PERMISSIONS` | `false` | Auto-fix permissions on exit |
| `LOCAL_UID` | Current user | Override user ID |
| `LOCAL_GID` | Current group | Override group ID |
| `DOCKER_USER_NAME` | `user` | Username inside container |
| `DOCKER_USER_HOME` | `/home/$USER` | Home directory path |

### Permission Decision Tree

```
Start Container
    │
    ├─ DOCKER_ROOTLESS_MODE=true?
    │   │
    │   └─ Yes → Run as root (UID 0)
    │             No user switching
    │             Simplified permissions
    │
    └─ No → Create user with LOCAL_UID/LOCAL_GID
            │
            ├─ Switch to user with gosu
            │
            └─ FIX_PERMISSIONS=true?
                │
                └─ Yes → Install exit trap
                         Fix ownership on exit
```

## Migration Guide

### From Old Setup

If you were using an older multi-container setup:

1. **ext** → No changes needed
2. **ext-dev** → Use new unified ext-dev
3. **ext-ros2** → Use new unified ext-dev (includes ROS2)
4. **ext-dev-rootless** → Use ext-dev-rootless service

### Building Containers

```bash
# Build production container
./container.sh -p ext build

# Build development container
./container.sh -p ext-dev build
```

### Environment Files

The following environment files are still used:
- `.env.ext_template` - Production container
- `.env.ext_template-dev` - Development container

## Container Features Comparison

| Feature | Production (ext) | Development (ext-dev) |
|---------|-----------------|---------------------| 
| Base Image | isaac-lab-base | isaac-lab-ros2 |
| ROS2 | ❌ | ✅ |
| Claude Code | ❌ | ✅ |
| Development Tools | ❌ | ✅ |
| Pinocchio | ❌ | ✅ |
| CUDA Toolkit | ❌ | ✅ |
| Size | Minimal | Full |
| Dual-Mode | ❌ | ✅ |

## Best Practices

1. **Use Production Container for**:
   - Cluster training jobs
   - Performance testing
   - Deployment scenarios

2. **Use Development Container for**:
   - Local development
   - ROS2 integration work
   - Testing and debugging
   - Running with different permission models

3. **Permission Management**:
   - Enable `FIX_PERMISSIONS` when working with mounted volumes
   - Use rootless mode on systems without root Docker access
   - Check `.permissions_done` file to verify background tasks completed

## Troubleshooting

### Common Permission Issues and Solutions

#### Issue 1: "Permission denied" errors
**Symptom**: Can't write to mounted directories
```bash
# Solution 1: Use rootless mode
./docker/run_dev.sh --rootless

# Solution 2: Enable permission fixing
./docker/run_dev.sh --fix-perms

# Solution 3: Manually fix permissions
sudo chown -R $(id -u):$(id -g) /workspace/ext_template
```

#### Issue 2: Files created as root on host
**Symptom**: After running container, files are owned by root
```bash
# Prevention: Always use FIX_PERMISSIONS
export FIX_PERMISSIONS=true
./docker/run_dev.sh

# Fix existing files
sudo chown -R $(id -u):$(id -g) .
```

#### Issue 3: Container startup is slow
**Symptom**: Long wait before container is usable
```bash
# Check if permissions are still being fixed
./docker/container.sh -p ext-dev exec cat ~/.permissions_done
# If file exists, background setup is complete
```

#### Issue 4: Can't access GPU in rootless mode
**Symptom**: nvidia-smi fails in container
```bash
# Ensure NVIDIA_DRIVER_CAPABILITIES is set
export NVIDIA_DRIVER_CAPABILITIES=all
./docker/run_dev.sh --rootless
```

### Rootless Mode Issues
```bash
# Verify rootless mode is active
echo $DOCKER_ROOTLESS_MODE

# Check container user
./container.sh -p ext-dev-rootless exec whoami
# Should output: root
```

### Build Issues
```bash
# Clean build with no cache
docker compose build --no-cache isaac-lab-ext-dev

# Remove old images
docker image prune -f
```