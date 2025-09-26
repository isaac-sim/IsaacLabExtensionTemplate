#!/usr/bin/env python3
"""
Unified mount configuration system for Docker and Singularity containers.

This script manages optional mounting of external codebases (IsaacLab and RSL-RL)
for both Docker and Singularity environments, providing a consistent interface
and proper validation.
"""

import argparse
import json
import os
import sys
import yaml
from pathlib import Path
from typing import Dict, List, Optional, Tuple


class MountConfig:
    """Manages mount configurations for Docker and Singularity containers."""
    
    def __init__(self, config_file: str = ".mount.config"):
        self.config_file = Path(config_file)
        self.config = self._load_config()
        self.docker_compose_template = Path("docker-compose.override.yaml.template")
        self.docker_compose_override = Path("docker-compose.override.yaml")
        
    def _load_config(self) -> Dict:
        """Load mount configuration from file or create default."""
        if self.config_file.exists():
            with open(self.config_file, 'r') as f:
                return json.load(f)
        else:
            # Default configuration
            return {
                "mounts": {
                    "isaaclab": {
                        "enabled": False,
                        "local_path": "",
                        "cluster_path": "",  # Optional: different path on cluster
                        "container_path": "/workspace/isaaclab",
                        "mount_type": "source",  # "source" or "full"
                        "sync_to_cluster": True,  # Whether to sync from local to cluster
                        "description": "External IsaacLab installation"
                    },
                    "rsl_rl": {
                        "enabled": False,
                        "local_path": "",
                        "cluster_path": "",  # Optional: different path on cluster
                        "container_path": "/workspace/isaaclab/_isaac_sim/kit/python/lib/python3.10/site-packages/rsl_rl",
                        "mount_type": "full",
                        "sync_to_cluster": True,  # Whether to sync from local to cluster
                        "description": "External RSL-RL installation"
                    }
                }
            }
    
    def save_config(self):
        """Save current configuration to file."""
        with open(self.config_file, 'w') as f:
            json.dump(self.config, f, indent=2)
    
    def validate_mount(self, mount_name: str) -> Tuple[bool, str]:
        """Validate a mount configuration."""
        if mount_name not in self.config["mounts"]:
            return False, f"Unknown mount: {mount_name}"
        
        mount = self.config["mounts"][mount_name]
        
        if not mount["enabled"]:
            return True, "Mount disabled"
        
        local_path = Path(os.path.expanduser(mount["local_path"]))
        
        if not local_path.exists():
            return False, f"Local path does not exist: {local_path}"
        
        if not local_path.is_dir():
            return False, f"Local path is not a directory: {local_path}"
        
        # Specific validations
        if mount_name == "isaaclab" and mount["mount_type"] == "source":
            source_path = local_path / "source"
            if not source_path.exists():
                return False, f"IsaacLab source directory not found: {source_path}"
        
        if mount_name == "rsl_rl":
            # Check if it's a Python package
            init_file = local_path / "__init__.py"
            rsl_rl_subdir = local_path / "rsl_rl" / "__init__.py"
            
            if not init_file.exists() and not rsl_rl_subdir.exists():
                return False, f"RSL-RL does not appear to be a valid Python package: {local_path}"
        
        return True, "Valid"
    
    def get_docker_mounts(self, profile: str) -> List[Dict]:
        """Generate Docker mount configurations for docker-compose."""
        mounts = []
        
        for mount_name, mount_config in self.config["mounts"].items():
            if not mount_config["enabled"]:
                continue
            
            valid, msg = self.validate_mount(mount_name)
            if not valid:
                print(f"Warning: Skipping {mount_name}: {msg}", file=sys.stderr)
                continue
            
            local_path = Path(os.path.expanduser(mount_config["local_path"]))
            
            # Handle special cases
            if mount_name == "isaaclab" and mount_config["mount_type"] == "source":
                # Mount only source directory for IsaacLab
                mount_spec = {
                    "type": "bind",
                    "source": str(local_path / "source"),
                    "target": f"{mount_config['container_path']}/source",
                    "read_only": False
                }
            elif mount_name == "rsl_rl":
                # Check if we need to use subdirectory
                if (local_path / "rsl_rl" / "__init__.py").exists():
                    mount_spec = {
                        "type": "bind",
                        "source": str(local_path / "rsl_rl"),
                        "target": mount_config["container_path"],
                        "read_only": False
                    }
                else:
                    mount_spec = {
                        "type": "bind",
                        "source": str(local_path),
                        "target": mount_config["container_path"],
                        "read_only": False
                    }
            else:
                # Default mount
                mount_spec = {
                    "type": "bind",
                    "source": str(local_path),
                    "target": mount_config["container_path"],
                    "read_only": False
                }
            
            mounts.append(mount_spec)
        
        return mounts
    
    def get_singularity_binds(self) -> str:
        """Generate Singularity bind mount string."""
        binds = []
        
        for mount_name, mount_config in self.config["mounts"].items():
            if not mount_config["enabled"]:
                continue
            
            valid, msg = self.validate_mount(mount_name)
            if not valid:
                print(f"Warning: Skipping {mount_name}: {msg}", file=sys.stderr)
                continue
            
            local_path = Path(os.path.expanduser(mount_config["local_path"]))
            
            # Handle special cases
            if mount_name == "isaaclab" and mount_config["mount_type"] == "source":
                # Mount only source directory for IsaacLab
                bind = f"{local_path}/source:{mount_config['container_path']}/source:rw"
            elif mount_name == "rsl_rl":
                # Check if we need to use subdirectory
                if (local_path / "rsl_rl" / "__init__.py").exists():
                    bind = f"{local_path}/rsl_rl:{mount_config['container_path']}:rw"
                else:
                    bind = f"{local_path}:{mount_config['container_path']}:rw"
            else:
                # Default mount
                bind = f"{local_path}:{mount_config['container_path']}:rw"
            
            binds.append(bind)
        
        return " ".join([f"-B {bind}" for bind in binds])
    
    def generate_docker_compose_override(self, profiles: List[str] = None):
        """Generate docker-compose.override.yaml file."""
        if profiles is None:
            profiles = ["ext", "ext-dev", "ext-dev-rootless"]
        
        # Load template if exists, otherwise create base structure
        if self.docker_compose_template.exists():
            with open(self.docker_compose_template, 'r') as f:
                override_config = yaml.safe_load(f) or {}
        else:
            override_config = {"services": {}}
        
        # Add mounts to each profile
        for profile in profiles:
            service_name = f"isaac-lab-{profile.replace('_', '-')}"
            
            if service_name not in override_config["services"]:
                override_config["services"][service_name] = {}
            
            service = override_config["services"][service_name]
            
            # Get mounts for this profile
            mounts = self.get_docker_mounts(profile)
            
            if mounts:
                # Merge with existing volumes if any
                if "volumes" not in service:
                    service["volumes"] = []
                
                # Add our mounts
                for mount in mounts:
                    # Check if mount already exists
                    existing = False
                    for i, vol in enumerate(service["volumes"]):
                        if isinstance(vol, dict) and vol.get("target") == mount["target"]:
                            service["volumes"][i] = mount
                            existing = True
                            break
                    
                    if not existing:
                        service["volumes"].append(mount)
        
        # Write override file
        with open(self.docker_compose_override, 'w') as f:
            yaml.dump(override_config, f, default_flow_style=False, sort_keys=False)
        
        print(f"Generated {self.docker_compose_override}")
    
    def interactive_setup(self):
        """Interactive setup for mount configuration."""
        print("Mount Configuration Setup")
        print("=" * 50)
        
        for mount_name, mount_config in self.config["mounts"].items():
            print(f"\n{mount_config['description']} ({mount_name})")
            print(f"Container path: {mount_config['container_path']}")
            
            enable = input(f"Enable {mount_name} mount? [y/N]: ").lower() == 'y'
            mount_config["enabled"] = enable
            
            if enable:
                # Local path configuration
                current_path = mount_config["local_path"]
                default_prompt = f" [{current_path}]" if current_path else ""
                local_path = input(f"Local path{default_prompt}: ").strip()
                
                if local_path:
                    mount_config["local_path"] = local_path
                elif not current_path:
                    print("Error: Local path is required when mount is enabled")
                    mount_config["enabled"] = False
                    continue
                
                # Cluster configuration
                print("\nCluster Configuration:")
                sync_choice = input("Sync from local to cluster? [Y/n]: ").lower()
                mount_config["sync_to_cluster"] = sync_choice != 'n'
                
                if not mount_config["sync_to_cluster"]:
                    # Mount-only mode - need cluster path
                    cluster_path = mount_config.get("cluster_path", "")
                    default_cluster = f" [{cluster_path}]" if cluster_path else ""
                    cluster_input = input(f"Cluster path (for mount-only){default_cluster}: ").strip()
                    
                    if cluster_input:
                        mount_config["cluster_path"] = cluster_input
                    elif not cluster_path:
                        print("Error: Cluster path is required for mount-only mode")
                        mount_config["enabled"] = False
                        continue
                else:
                    # Clear cluster_path if syncing
                    mount_config["cluster_path"] = ""
                
                # Validate
                valid, msg = self.validate_mount(mount_name)
                if not valid:
                    print(f"Error: {msg}")
                    mount_config["enabled"] = False
                else:
                    if mount_config["sync_to_cluster"]:
                        print(f"✓ {mount_name} will be synced from local to cluster")
                    else:
                        print(f"✓ {mount_name} will be mounted from cluster path (no sync)")
        
        self.save_config()
        print(f"\nConfiguration saved to {self.config_file}")


def main():
    parser = argparse.ArgumentParser(description="Manage container mount configurations")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    # Setup command
    setup_parser = subparsers.add_parser("setup", help="Interactive setup of mount configuration")
    
    # Generate command
    gen_parser = subparsers.add_parser("generate", help="Generate docker-compose.override.yaml")
    gen_parser.add_argument("--profiles", nargs="+", help="Profiles to generate for")
    
    # Validate command
    val_parser = subparsers.add_parser("validate", help="Validate current configuration")
    
    # Show command
    show_parser = subparsers.add_parser("show", help="Show current configuration")
    show_parser.add_argument("--format", choices=["json", "yaml", "docker", "singularity"], 
                            default="json", help="Output format")
    
    # Enable/disable commands
    for action in ["enable", "disable"]:
        action_parser = subparsers.add_parser(action, help=f"{action.capitalize()} a mount")
        action_parser.add_argument("mount", choices=["isaaclab", "rsl_rl"], help="Mount to modify")
    
    # Set path command
    set_parser = subparsers.add_parser("set", help="Set mount path")
    set_parser.add_argument("mount", choices=["isaaclab", "rsl_rl"], help="Mount to modify")
    set_parser.add_argument("path", help="Local path to mount")
    
    # Set cluster path command
    set_cluster_parser = subparsers.add_parser("set-cluster", help="Set cluster path for mount-only mode")
    set_cluster_parser.add_argument("mount", choices=["isaaclab", "rsl_rl"], help="Mount to modify")
    set_cluster_parser.add_argument("path", help="Cluster path to mount")
    
    # Sync mode commands
    sync_parser = subparsers.add_parser("set-sync", help="Set sync mode for a mount")
    sync_parser.add_argument("mount", choices=["isaaclab", "rsl_rl"], help="Mount to modify")
    sync_parser.add_argument("mode", choices=["on", "off"], help="Enable or disable sync to cluster")
    
    args = parser.parse_args()
    
    # Initialize config
    config = MountConfig()
    
    if args.command == "setup":
        config.interactive_setup()
        config.generate_docker_compose_override()
    
    elif args.command == "generate":
        config.generate_docker_compose_override(args.profiles)
    
    elif args.command == "validate":
        all_valid = True
        for mount_name in config.config["mounts"]:
            mount = config.config["mounts"][mount_name]
            if mount["enabled"]:
                valid, msg = config.validate_mount(mount_name)
                status = "✓" if valid else "✗"
                print(f"{status} {mount_name}: {msg}")
                if not valid:
                    all_valid = False
        
        sys.exit(0 if all_valid else 1)
    
    elif args.command == "show":
        if args.format == "json":
            print(json.dumps(config.config, indent=2))
        elif args.format == "yaml":
            print(yaml.dump(config.config, default_flow_style=False))
        elif args.format == "docker":
            for profile in ["ext", "ext-dev", "ext-ros2"]:
                mounts = config.get_docker_mounts(profile)
                if mounts:
                    print(f"\n{profile}:")
                    for mount in mounts:
                        print(f"  {mount['source']} -> {mount['target']}")
        elif args.format == "singularity":
            binds = config.get_singularity_binds()
            if binds:
                print("Singularity binds:")
                print(binds)
    
    elif args.command == "enable":
        config.config["mounts"][args.mount]["enabled"] = True
        config.save_config()
        print(f"Enabled {args.mount} mount")
        config.generate_docker_compose_override()
    
    elif args.command == "disable":
        config.config["mounts"][args.mount]["enabled"] = False
        config.save_config()
        print(f"Disabled {args.mount} mount")
        config.generate_docker_compose_override()
    
    elif args.command == "set":
        config.config["mounts"][args.mount]["local_path"] = args.path
        config.save_config()
        valid, msg = config.validate_mount(args.mount)
        if valid:
            print(f"Set {args.mount} path to: {args.path}")
            config.generate_docker_compose_override()
        else:
            print(f"Error: {msg}")
            sys.exit(1)
    
    elif args.command == "set-cluster":
        config.config["mounts"][args.mount]["cluster_path"] = args.path
        config.config["mounts"][args.mount]["sync_to_cluster"] = False
        config.save_config()
        print(f"Set {args.mount} cluster path to: {args.path}")
        print(f"Sync disabled for {args.mount} (mount-only mode)")
        config.generate_docker_compose_override()
    
    elif args.command == "set-sync":
        sync_enabled = args.mode == "on"
        config.config["mounts"][args.mount]["sync_to_cluster"] = sync_enabled
        if sync_enabled:
            # Clear cluster path when enabling sync
            config.config["mounts"][args.mount]["cluster_path"] = ""
        config.save_config()
        print(f"Sync {'enabled' if sync_enabled else 'disabled'} for {args.mount}")
        if not sync_enabled and not config.config["mounts"][args.mount]["cluster_path"]:
            print(f"Warning: No cluster path set. Use 'set-cluster' to specify cluster path.")
        config.generate_docker_compose_override()
    
    else:
        parser.print_help()


if __name__ == "__main__":
    main()