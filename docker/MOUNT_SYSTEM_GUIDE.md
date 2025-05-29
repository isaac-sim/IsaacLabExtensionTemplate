# Unified Mount System Guide

## Overview

The unified mount system provides a consistent and flexible way to optionally mount external codebases (IsaacLab and RSL-RL) in both Docker and Singularity containers. This solves the challenge of making mounts optional while maintaining compatibility across container runtimes.

## Key Features

- **Unified Configuration**: Single configuration file (`.mount.config`) that works for both Docker and Singularity
- **Optional Mounting**: Easily enable/disable mounts without modifying docker-compose files
- **Validation**: Automatic validation of mount paths before container startup
- **Interactive Setup**: User-friendly setup process for configuring mounts
- **Backward Compatibility**: Legacy environment variables still work for cluster operations

## Quick Start

### 1. Initial Setup

Run the interactive setup to configure your mounts:

```bash
cd docker
./container.sh mount-setup
```

This will:
- Create a `.mount.config` file with your mount preferences
- Validate the paths you provide
- Generate `docker-compose.override.yaml` automatically

### 2. Running Containers

Use the new container management script:

```bash
# Run development container
./container.sh -p ext-dev run

# Run with a specific script
./container.sh -p ext-ros2 run python scripts/train.py

# Build container
./container.sh -p ext build
```

## Configuration File

The `.mount.config` file stores your mount preferences:

```json
{
  "mounts": {
    "isaaclab": {
      "enabled": false,
      "local_path": "/path/to/your/isaaclab",
      "container_path": "/workspace/isaaclab",
      "mount_type": "source",
      "description": "External IsaacLab installation"
    },
    "rsl_rl": {
      "enabled": false,
      "local_path": "/path/to/your/rsl_rl",
      "container_path": "/workspace/isaaclab/_isaac_sim/kit/python/lib/python3.10/site-packages/rsl_rl",
      "mount_type": "full",
      "description": "External RSL-RL installation"
    }
  }
}
```

### Mount Types

- **source**: For IsaacLab - mounts only the `source/` subdirectory to preserve the container's Python environment
- **full**: For RSL-RL - completely overrides the built-in version

## Mount Management Commands

### Setup and Configuration

```bash
# Interactive setup
./container.sh mount-setup

# Show current configuration
./container.sh mount-show
./container.sh mount-show --format yaml
./container.sh mount-show --format docker
./container.sh mount-show --format singularity

# Validate configuration
./container.sh mount-validate
```

### Enable/Disable Mounts

```bash
# Enable a mount
./container.sh mount-enable isaaclab
./container.sh mount-enable rsl_rl

# Disable a mount
./container.sh mount-disable isaaclab
./container.sh mount-disable rsl_rl
```

### Set Mount Paths

```bash
# Set mount path
./container.sh mount-set isaaclab ~/my-isaaclab
./container.sh mount-set rsl_rl ~/my-rsl-rl
```

## Docker Usage

The system automatically generates `docker-compose.override.yaml` based on your mount configuration. This file is used alongside the main `docker-compose.yaml`.

### Manual Override Regeneration

If you modify `.mount.config` directly, regenerate the override:

```bash
./container.sh -r -p ext-dev run
# or
python3 mount_config.py generate
```

## Cluster/Singularity Usage

The system supports both syncing from local to cluster and mount-only modes.

### Mount Modes

1. **Sync Mode** (default): Syncs codebase from local to cluster, then mounts
2. **Mount-Only Mode**: Mounts existing codebase on cluster without syncing

### Basic Cluster Workflow (Sync Mode)

1. Configure mounts locally:
   ```bash
   cd docker
   ./container.sh mount-setup
   # Enable mounts and set local paths
   ```

2. Push container to cluster:
   ```bash
   cd cluster
   ./cluster_interface.sh push ext_template
   ```

3. Submit job (codebases are synced and mounted automatically):
   ```bash
   ./cluster_interface.sh job ext_template --task YourTask --num_envs 64000
   ```

### Mount-Only Mode (No Sync)

Perfect for when codebases already exist on the cluster:

```bash
# Configure mount-only for IsaacLab
./container.sh mount-enable isaaclab
./container.sh mount-set-sync isaaclab off
./container.sh mount-set-cluster isaaclab /cluster/home/$USER/isaaclab

# Configure mount-only for RSL-RL
./container.sh mount-enable rsl_rl
./container.sh mount-set-sync rsl_rl off
./container.sh mount-set-cluster rsl_rl /cluster/home/$USER/rsl_rl

# Submit job (no sync, just mount)
cd cluster
./cluster_interface.sh job ext_template --task YourTask
```

### Mixed Mode Example

Sync IsaacLab but mount existing RSL-RL:

```bash
# IsaacLab: sync from local
./container.sh mount-enable isaaclab
./container.sh mount-set isaaclab ~/my-isaaclab
./container.sh mount-set-sync isaaclab on

# RSL-RL: mount existing on cluster
./container.sh mount-enable rsl_rl
./container.sh mount-set-sync rsl_rl off
./container.sh mount-set-cluster rsl_rl /cluster/scratch/$USER/rsl_rl
```

## Advanced Usage

### Using Python API

```python
from mount_config import MountConfig

# Load configuration
config = MountConfig()

# Enable a mount programmatically
config.config["mounts"]["isaaclab"]["enabled"] = True
config.config["mounts"]["isaaclab"]["local_path"] = "/path/to/isaaclab"
config.save_config()

# Generate docker-compose override
config.generate_docker_compose_override()

# Get Singularity bind string
binds = config.get_singularity_binds()
print(binds)  # -B /path/to/isaaclab/source:/workspace/isaaclab/source:rw
```

### Custom Mount Profiles

You can create different mount configurations for different scenarios:

```bash
# Save current config
cp .mount.config .mount.config.backup

# Create development config
./container.sh mount-setup
cp .mount.config .mount.config.dev

# Create production config
./container.sh mount-setup
cp .mount.config .mount.config.prod

# Switch between configs
cp .mount.config.dev .mount.config
./container.sh -r -p ext-dev run
```

## Migration from Old System

### Docker

Old docker-compose.yaml approach:
```yaml
- type: bind
  source: ${EXTERNAL_ISAACLAB_PATH:-/dev/null}/source
  target: /workspace/isaaclab/source
```

New approach:
1. Remove external mount lines from docker-compose.yaml
2. Run `./container.sh mount-setup`
3. Use `./container.sh` to manage containers

### Environment Files

Old `.env` approach:
```bash
EXTERNAL_ISAACLAB_PATH=/path/to/isaaclab
EXTERNAL_RSL_RL_PATH=/path/to/rsl_rl
```

New approach:
- These variables are no longer needed in `.env` files
- Configuration is stored in `.mount.config`
- Use `./container.sh mount-set` to update paths

## Troubleshooting

### Mount Not Working

1. Check configuration:
   ```bash
   ./container.sh mount-validate
   ```

2. Verify override file exists:
   ```bash
   ls -la docker-compose.override.yaml
   ```

3. Regenerate override:
   ```bash
   ./container.sh -r -p ext-dev run
   ```

### Path Validation Errors

- **IsaacLab**: Ensure the path contains a `source/` subdirectory
- **RSL-RL**: Ensure the path is either:
  - A Python package with `__init__.py`
  - A repository with `rsl_rl/` subdirectory

### Container Can't Find Mounted Code

1. Check mount is enabled:
   ```bash
   ./container.sh mount-show --format docker
   ```

2. Verify paths inside container:
   ```bash
   ./container.sh -p ext-dev exec ls -la /workspace/isaaclab/source
   ```

## Best Practices

1. **Always Use Interactive Setup**: The `mount-setup` command validates paths and prevents common errors

2. **Test Locally First**: Verify mounts work in Docker before pushing to cluster

3. **Keep Built-in Versions**: When possible, use the built-in IsaacLab and RSL-RL for stability

4. **Document Custom Setups**: If using external codebases, document the specific versions/branches required

5. **Version Control**: Don't commit `.mount.config` or `docker-compose.override.yaml` - they're user-specific

## Technical Details

### How It Works

1. **Configuration**: User preferences stored in `.mount.config` (JSON format)
2. **Docker**: `mount_config.py` generates `docker-compose.override.yaml` with bind mounts
3. **Singularity**: `run_singularity.sh` reads `.mount.config` and adds `-B` bind flags
4. **Validation**: Paths are validated before container startup to prevent runtime errors

### Docker Compose Override Mechanism

The system uses Docker Compose's built-in override feature to cleanly manage user-specific mounts:

#### How Override Files Work

When you run any docker-compose command, Docker Compose automatically:
1. Reads `docker-compose.yaml` (base configuration)
2. Looks for `docker-compose.override.yaml` in the same directory
3. **Merges** the configurations, with override values taking precedence

#### Example Merge Process

**Base `docker-compose.yaml`:**
```yaml
services:
  isaac-lab-ext-dev:
    image: isaac-lab-ext_template-dev
    volumes:
      - type: bind
        source: ${EXT_PATH}
        target: /workspace/${EXTENSION_NAME}
```

**Generated `docker-compose.override.yaml`:**
```yaml
services:
  isaac-lab-ext-dev:
    volumes:
      - type: bind
        source: /home/user/isaaclab/source
        target: /workspace/isaaclab/source
```

**Result:** The container gets ALL volumes from both files merged together.

#### Why Use Override?

1. **Separation of Concerns**: Base config (tracked) vs user mounts (ignored)
2. **No Manual Editing**: Users never modify docker-compose.yaml
3. **Clean Git History**: No merge conflicts from different mount preferences
4. **Easy Disable**: Just delete override file to remove all custom mounts
5. **Standard Feature**: Works with all docker-compose commands automatically

### File Structure

```
docker/
├── mount_config.py              # Core mount management script
├── container.sh                 # User-friendly wrapper script
├── .mount.config               # User's mount configuration (git-ignored)
├── .mount.config.template      # Template for new users
├── docker-compose.yaml         # Clean compose file without external mounts
├── docker-compose.override.yaml # Generated mount overrides (git-ignored)
└── cluster/
    ├── run_singularity.sh      # Updated to support unified config
    └── sync_mounts.py          # Handles selective syncing to cluster
```

### Integration Points

- **Docker Compose**: Uses override mechanism to add mounts without modifying base file
- **Singularity**: Parses config file and generates bind mount arguments
- **Cluster Sync**: `.mount.config` is automatically included when syncing to cluster
- **Selective Sync**: Only syncs codebases marked with `sync_to_cluster: true`