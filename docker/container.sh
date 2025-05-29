#!/usr/bin/env bash
#
# Container management script with unified mount configuration support
# This script wraps docker-compose commands and manages optional mounts
#

set -e

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
MOUNT_CONFIG="$SCRIPT_DIR/.mount.config"
DOCKER_COMPOSE_OVERRIDE="$SCRIPT_DIR/docker-compose.override.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display help
show_help() {
    echo "Container Management Script for IsaacLab Extension"
    echo ""
    echo "Usage: $0 [options] <command> [args...]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -p, --profile PROFILE   Container profile (ext, ext-dev, ext-dev-rootless)"
    echo "  -e, --env ENV_FILE      Environment file to use (default: auto-detect based on profile)"
    echo "  -r, --regenerate        Regenerate docker-compose.override.yaml from mount config"
    echo ""
    echo "Mount Commands:"
    echo "  mount-setup             Interactive setup of mount configuration"
    echo "  mount-show              Show current mount configuration"
    echo "  mount-validate          Validate mount configuration"
    echo "  mount-enable NAME       Enable a mount (isaaclab or rsl_rl)"
    echo "  mount-disable NAME      Disable a mount (isaaclab or rsl_rl)"
    echo "  mount-set NAME PATH     Set local mount path"
    echo "  mount-set-cluster NAME PATH   Set cluster path for mount-only mode"
    echo "  mount-set-sync NAME on|off    Enable/disable sync to cluster"
    echo ""
    echo "Container Commands:"
    echo "  build                   Build the container"
    echo "  run [ARGS]              Run the container (passes args to container)"
    echo "  exec [CMD]              Execute command in running container"
    echo "  attach                  Attach to running container"
    echo "  stop                    Stop the container"
    echo "  logs                    Show container logs"
    echo "  ps                      Show running containers"
    echo ""
    echo "Examples:"
    echo "  $0 mount-setup                                    # Setup mounts interactively"
    echo "  $0 -p ext-dev run                                # Run development container"
    echo "  $0 -p ext-dev run python scripts/run.py          # Run dev container with script"
    echo "  $0 mount-enable isaaclab                         # Enable IsaacLab mount"
    echo "  $0 mount-set isaaclab ~/isaaclab                 # Set IsaacLab path"
}

# Function to detect environment file based on profile
detect_env_file() {
    local profile=$1
    case $profile in
        ext)
            echo "$SCRIPT_DIR/.env.ext_template"
            ;;
        ext-dev)
            echo "$SCRIPT_DIR/.env.ext_template-dev"
            ;;
        ext-dev-rootless)
            echo "$SCRIPT_DIR/.env.ext_template-dev"
            ;;
        *)
            echo "$SCRIPT_DIR/.env.ext_template"
            ;;
    esac
}

# Function to get service name from profile
get_service_name() {
    local profile=$1
    echo "isaac-lab-${profile//_/-}"
}

# Function to check if mount config exists
check_mount_config() {
    if [ ! -f "$MOUNT_CONFIG" ]; then
        echo -e "${YELLOW}Warning: Mount configuration not found at $MOUNT_CONFIG${NC}"
        echo -e "${YELLOW}Run '$0 mount-setup' to configure optional mounts.${NC}"
        # Create empty override file if it doesn't exist
        if [ ! -f "$DOCKER_COMPOSE_OVERRIDE" ]; then
            echo "version: '3.8'" > "$DOCKER_COMPOSE_OVERRIDE"
            echo "services: {}" >> "$DOCKER_COMPOSE_OVERRIDE"
        fi
        return 1
    fi
    return 0
}

# Function to regenerate docker-compose override
regenerate_override() {
    if check_mount_config; then
        echo "Regenerating docker-compose.override.yaml..."
        python3 "$SCRIPT_DIR/mount_config.py" generate
    fi
}

# Parse command line arguments
PROFILE=""
ENV_FILE=""
REGENERATE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -p|--profile)
            PROFILE="$2"
            shift 2
            ;;
        -e|--env)
            ENV_FILE="$2"
            shift 2
            ;;
        -r|--regenerate)
            REGENERATE=true
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Get command
COMMAND=${1:-help}
shift || true

# Set default profile if not specified
if [ -z "$PROFILE" ]; then
    PROFILE="ext-dev"
    echo "Using default profile: $PROFILE"
fi

# Auto-detect env file if not specified
if [ -z "$ENV_FILE" ]; then
    ENV_FILE=$(detect_env_file "$PROFILE")
fi

# Check if env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: Environment file not found: $ENV_FILE${NC}"
    echo "Please copy the template and configure it:"
    echo "  cp ${ENV_FILE}.template $ENV_FILE"
    exit 1
fi

# Get service name
SERVICE_NAME=$(get_service_name "$PROFILE")

# Regenerate override if requested
if [ "$REGENERATE" = true ]; then
    regenerate_override
fi

# Handle commands
case $COMMAND in
    # Mount management commands
    mount-setup)
        python3 "$SCRIPT_DIR/mount_config.py" setup
        ;;
    mount-show)
        python3 "$SCRIPT_DIR/mount_config.py" show "$@"
        ;;
    mount-validate)
        python3 "$SCRIPT_DIR/mount_config.py" validate
        ;;
    mount-enable)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Mount name required (isaaclab or rsl_rl)${NC}"
            exit 1
        fi
        python3 "$SCRIPT_DIR/mount_config.py" enable "$1"
        ;;
    mount-disable)
        if [ -z "$1" ]; then
            echo -e "${RED}Error: Mount name required (isaaclab or rsl_rl)${NC}"
            exit 1
        fi
        python3 "$SCRIPT_DIR/mount_config.py" disable "$1"
        ;;
    mount-set)
        if [ -z "$1" ] || [ -z "$2" ]; then
            echo -e "${RED}Error: Usage: mount-set NAME PATH${NC}"
            exit 1
        fi
        python3 "$SCRIPT_DIR/mount_config.py" set "$1" "$2"
        ;;
    mount-set-cluster)
        if [ -z "$1" ] || [ -z "$2" ]; then
            echo -e "${RED}Error: Usage: mount-set-cluster NAME PATH${NC}"
            exit 1
        fi
        python3 "$SCRIPT_DIR/mount_config.py" set-cluster "$1" "$2"
        ;;
    mount-set-sync)
        if [ -z "$1" ] || [ -z "$2" ]; then
            echo -e "${RED}Error: Usage: mount-set-sync NAME on|off${NC}"
            exit 1
        fi
        python3 "$SCRIPT_DIR/mount_config.py" set-sync "$1" "$2"
        ;;
    
    # Container commands
    build)
        echo "Building container: $SERVICE_NAME"
        check_mount_config
        docker compose --env-file "$ENV_FILE" \
            --file "$SCRIPT_DIR/docker-compose.yaml" \
            --file "$DOCKER_COMPOSE_OVERRIDE" \
            build "$SERVICE_NAME" "$@"
        ;;
    run)
        echo "Running container: $SERVICE_NAME"
        check_mount_config
        docker compose --env-file "$ENV_FILE" \
            --file "$SCRIPT_DIR/docker-compose.yaml" \
            --file "$DOCKER_COMPOSE_OVERRIDE" \
            run --rm "$SERVICE_NAME" "$@"
        ;;
    exec)
        echo "Executing in container: $SERVICE_NAME"
        docker compose --env-file "$ENV_FILE" \
            --file "$SCRIPT_DIR/docker-compose.yaml" \
            --file "$DOCKER_COMPOSE_OVERRIDE" \
            exec "$SERVICE_NAME" "$@"
        ;;
    attach)
        echo "Attaching to container: $SERVICE_NAME"
        docker compose --env-file "$ENV_FILE" \
            --file "$SCRIPT_DIR/docker-compose.yaml" \
            --file "$DOCKER_COMPOSE_OVERRIDE" \
            attach "$SERVICE_NAME"
        ;;
    stop)
        echo "Stopping container: $SERVICE_NAME"
        docker compose --env-file "$ENV_FILE" \
            --file "$SCRIPT_DIR/docker-compose.yaml" \
            --file "$DOCKER_COMPOSE_OVERRIDE" \
            stop "$SERVICE_NAME"
        ;;
    logs)
        docker compose --env-file "$ENV_FILE" \
            --file "$SCRIPT_DIR/docker-compose.yaml" \
            --file "$DOCKER_COMPOSE_OVERRIDE" \
            logs "$SERVICE_NAME" "$@"
        ;;
    ps)
        docker compose --env-file "$ENV_FILE" \
            --file "$SCRIPT_DIR/docker-compose.yaml" \
            --file "$DOCKER_COMPOSE_OVERRIDE" \
            ps
        ;;
    help)
        show_help
        ;;
    *)
        echo -e "${RED}Error: Unknown command: $COMMAND${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac