#!/usr/bin/env python3
"""
Sync external codebases to cluster based on mount configuration.
"""

import json
import os
import subprocess
import sys
from pathlib import Path


def sync_codebase(mount_name: str, local_path: str, cluster_path: str, cluster_login: str):
    """Sync a codebase to the cluster."""
    local_path = Path(os.path.expanduser(local_path))
    
    if not local_path.exists():
        print(f"[ERROR] Local path not found: {local_path}")
        return False
    
    print(f"[INFO] Syncing {mount_name} from {local_path}")
    
    # Common excludes
    excludes = [
        "--exclude=*.git*",
        "--exclude=_build/",
        "--exclude=logs/",
        "--exclude=*.pyc",
        "--exclude=__pycache__/",
        "--exclude=*.egg-info/",
        "--exclude=wandb/",
        "--exclude=*.ckpt",
        "--exclude=*.pth",
        "--exclude=*.pt"
    ]
    
    # Create remote directory
    ssh_cmd = ["ssh", cluster_login, f"mkdir -p {cluster_path}"]
    subprocess.run(ssh_cmd, check=True)
    
    # Calculate transfer size
    print(f"[INFO] Calculating transfer size for {mount_name}...")
    size_cmd = ["rsync", "-avhnL"] + excludes + [f"{local_path}/", f"{cluster_login}:{cluster_path}"]
    result = subprocess.run(size_cmd, capture_output=True, text=True)
    if result.returncode == 0:
        lines = result.stdout.strip().split('\n')
        if lines:
            size_line = lines[-1]
            print(f"[INFO] Estimated size: {size_line}")
    
    # Sync with progress
    print(f"[INFO] Starting {mount_name} sync...")
    sync_cmd = ["rsync", "-avhL", "--progress"] + excludes + [f"{local_path}/", f"{cluster_login}:{cluster_path}"]
    
    process = subprocess.Popen(sync_cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
    
    for line in iter(process.stdout.readline, ''):
        line = line.rstrip()
        if line:
            # Show progress lines with special formatting
            if any(x in line for x in ['%', '/s', 'xfr#']):
                print(f"\r[{mount_name.upper()} SYNC] {line}", end='', flush=True)
            elif "sent" in line and "received" in line:
                print(f"\n[INFO] {mount_name} transfer complete: {line}")
            elif not line.startswith(' '):
                # Show file names being transferred
                print(f"\n[{mount_name.upper()}] {line}", end='', flush=True)
    
    process.wait()
    
    if process.returncode == 0:
        print(f"\n[INFO] ✓ {mount_name} sync completed successfully")
        return True
    else:
        print(f"\n[ERROR] {mount_name} sync failed with code {process.returncode}")
        return False


def main():
    if len(sys.argv) != 3:
        print("Usage: sync_mounts.py <mount_config_path> <cluster_login>")
        sys.exit(1)
    
    config_path = sys.argv[1]
    cluster_login = sys.argv[2]
    
    # Load mount configuration
    with open(config_path, 'r') as f:
        config = json.load(f)
    
    # Get cluster username for path expansion
    cluster_user = cluster_login.split('@')[0]
    
    # Sync enabled mounts
    for mount_name, mount_config in config.get('mounts', {}).items():
        if not mount_config.get('enabled', False):
            continue
        
        if not mount_config.get('sync_to_cluster', True):
            # Mount-only mode
            cluster_path = mount_config.get('cluster_path', '')
            if cluster_path:
                cluster_path = cluster_path.replace('$CLUSTER_USER', cluster_user)
                print(f"[INFO] {mount_name} configured for mount-only from: {cluster_path}")
                
                # Verify it exists on cluster
                check_cmd = ["ssh", cluster_login, f"[ -d {cluster_path} ] && echo 'EXISTS' || echo 'NOT_FOUND'"]
                result = subprocess.run(check_cmd, capture_output=True, text=True)
                if result.returncode == 0 and "EXISTS" in result.stdout:
                    print(f"[INFO] ✓ {mount_name} directory verified on cluster")
                else:
                    print(f"[WARNING] {mount_name} directory not found on cluster: {cluster_path}")
            continue
        
        # Sync mode
        local_path = mount_config.get('local_path', '')
        if not local_path:
            print(f"[WARNING] No local path set for {mount_name}, skipping")
            continue
        
        # Determine cluster path
        if mount_name == 'isaaclab':
            cluster_path = f"/cluster/home/{cluster_user}/isaaclab"
        elif mount_name == 'rsl_rl':
            cluster_path = f"/cluster/home/{cluster_user}/rsl_rl"
        else:
            cluster_path = f"/cluster/home/{cluster_user}/{mount_name}"
        
        # Sync the codebase
        sync_codebase(mount_name, local_path, cluster_path, cluster_login)
        
        # Update config with actual cluster path used
        mount_config['cluster_path'] = cluster_path
    
    # Save updated config with cluster paths
    with open(config_path, 'w') as f:
        json.dump(config, f, indent=2)


if __name__ == "__main__":
    main()