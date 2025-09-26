#!/usr/bin/env bash
#
# Convenience script to run the development container with easy mode switching
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
MODE="root"
COMMAND=""

# Function to display help
show_help() {
    echo "Development Container Runner"
    echo ""
    echo "Usage: $0 [options] [command]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -r, --rootless      Run in rootless mode (everyone as root inside container)"
    echo "  -f, --fix-perms     Enable automatic permission fixing on exit"
    echo "  -u, --uid UID       Set local UID (default: current user)"
    echo "  -g, --gid GID       Set local GID (default: current group)"
    echo ""
    echo "Examples:"
    echo "  $0                                  # Run in default mode"
    echo "  $0 --rootless                       # Run in rootless mode"
    echo "  $0 python scripts/rsl_rl/train.py  # Run with command"
    echo "  $0 --rootless --fix-perms           # Rootless with permission fixing"
    echo ""
    echo "Environment Variables:"
    echo "  DOCKER_ROOTLESS_MODE    Set to 'true' for rootless mode"
    echo "  FIX_PERMISSIONS         Set to 'true' to fix permissions on exit"
    echo "  LOCAL_UID               Override user ID"
    echo "  LOCAL_GID               Override group ID"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -r|--rootless)
            MODE="rootless"
            shift
            ;;
        -f|--fix-perms)
            export FIX_PERMISSIONS="true"
            shift
            ;;
        -u|--uid)
            export LOCAL_UID="$2"
            shift 2
            ;;
        -g|--gid)
            export LOCAL_GID="$2"
            shift 2
            ;;
        *)
            # Rest are commands to pass to container
            COMMAND="$@"
            break
            ;;
    esac
done

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Check if .env file exists
ENV_FILE="$SCRIPT_DIR/.env.ext_template-dev"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: Environment file not found: $ENV_FILE${NC}"
    echo -e "${YELLOW}Please copy and configure the environment file:${NC}"
    echo -e "  ${GREEN}cp $ENV_FILE.template $ENV_FILE${NC}"
    echo ""
    echo "Then edit the file to set:"
    echo "  - EXTENSION_FOLDER: Path to your project folder"
    echo "  - HOST_HOME: Your home directory"
    echo "  - DOCKER_USER_NAME: Your username"
    echo "  - Optionally: WANDB_API_KEY and WANDB_USERNAME"
    echo ""
    exit 1
fi

# Set defaults
export LOCAL_UID=${LOCAL_UID:-$(id -u)}
export LOCAL_GID=${LOCAL_GID:-$(id -g)}

# Display configuration
echo -e "${BLUE}=== Development Container Configuration ===${NC}"
echo -e "Mode: ${GREEN}$MODE${NC}"
echo -e "UID/GID: ${GREEN}$LOCAL_UID/$LOCAL_GID${NC}"
echo -e "Fix Permissions: ${GREEN}${FIX_PERMISSIONS:-false}${NC}"
if [ -n "$COMMAND" ]; then
    echo -e "Command: ${GREEN}$COMMAND${NC}"
fi
echo -e "${BLUE}========================================${NC}"
echo ""

# Run container based on mode
if [ "$MODE" = "rootless" ]; then
    echo -e "${YELLOW}Starting in ROOTLESS mode...${NC}"
    exec "$SCRIPT_DIR/container.sh" -p ext-dev-rootless run $COMMAND
else
    echo -e "${GREEN}Starting in ROOT mode with user switching...${NC}"
    exec "$SCRIPT_DIR/container.sh" -p ext-dev run $COMMAND
fi