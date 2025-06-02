#!/bin/bash

# ===================================
# Unified Dynamic Entrypoint for Docker Containers
# ===================================
# This script supports both root and rootless modes
# Mode is determined by DOCKER_ROOTLESS_MODE environment variable

# Print welcome message
echo "=== Isaac Lab Extension ==="

# Always add root sudo permissions
echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Source ROS2 if available
if [ -f /opt/ros/humble/setup.bash ]; then
    echo "source /opt/ros/humble/setup.bash" >> /home/bash.bashrc
    echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc
fi

# Determine which mode to run in
if [ "${DOCKER_ROOTLESS_MODE}" = "true" ]; then
    echo "====================================="
    echo "Running in ROOTLESS mode"
    echo "All users run as root inside container"
    echo "====================================="
    
    # In rootless mode, everyone runs as root
    export HOME=/root
    export USER=root
    
    # Ensure root has bashrc
    if [ ! -f /root/.bashrc ]; then
        cp /home/bash.bashrc /root/.bashrc
    fi
    
    # Make sure critical directories are accessible
    chmod -R 777 /tmp /var/tmp 2>/dev/null || true
    
    # Fix permissions for isaac-sim kit directory
    chmod -R 777 /isaac-sim/kit 2>/dev/null || true
    
    # Execute as root
    exec bash --rcfile /root/.bashrc
    
else
    echo "====================================="
    echo "Running in ROOT mode with user switching"
    echo "====================================="
    
    # Get UID and GID from environment or use defaults
    USER_ID=${LOCAL_UID:-1000}
    GROUP_ID=${LOCAL_GID:-1000}
    USER_NAME=${DOCKER_USER_NAME:-user}
    USER_HOME=${DOCKER_USER_HOME:-/home/$USER_NAME}
    
    echo "Creating/updating user:"
    echo "  UID: $USER_ID"
    echo "  GID: $GROUP_ID"
    echo "  Username: $USER_NAME"
    echo "  Home: $USER_HOME"
    
    # Create user and group if they don't exist
    groupadd -g $GROUP_ID -o $USER_NAME 2>/dev/null || true
    useradd -m -u $USER_ID -g $GROUP_ID -o -s /bin/bash -d $USER_HOME $USER_NAME 2>/dev/null || true
    
    # Add user sudo permissions
    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    
    # Ensure user home exists with correct permissions
    if [ ! -d "$USER_HOME" ]; then
        mkdir -p "$USER_HOME"
    fi
    chown $USER_NAME:$USER_NAME "$USER_HOME"
    
    # Always copy the container's bashrc to ensure Docker prompt is available
    # This is needed because the home directory might be mounted from host
    cp /home/bash.bashrc "$USER_HOME/.bashrc_container"
    chown $USER_NAME:$USER_NAME "$USER_HOME/.bashrc_container"
    
    echo "Setting up permissions in the background..."
    
    # Run permission fixes in the background to not delay startup
    (
        # Critical directories
        chmod -R 777 /tmp /var/tmp 2>/dev/null || true
        
        # Fix isaac-sim permissions
        nohup chown -R $USER_NAME:$USER_NAME /isaac-sim/kit 2>/dev/null &
        
        # Notify when complete
        echo "Permission setup completed at $(date)" > $USER_HOME/.permissions_done
        chown $USER_NAME:$USER_NAME $USER_HOME/.permissions_done
    ) &
    
    # Handle permission fixing for mounted volumes on exit
    if [ -n "${FIX_PERMISSIONS}" ] && [ "${FIX_PERMISSIONS}" = "true" ]; then
        # Create permission fix script
        cat > /usr/local/bin/fix-permissions << EOF
#!/bin/bash
# Fix permissions for files created in the container
if [ -d "/workspace/${EXTENSION_NAME}" ]; then
    echo "Fixing permissions for mounted volume..."
    find "/workspace/${EXTENSION_NAME}" -user root -exec chown ${USER_ID}:${GROUP_ID} {} \; 2>/dev/null || true
    find "/workspace/${EXTENSION_NAME}" -user ${USER_NAME} -exec chown ${USER_ID}:${GROUP_ID} {} \; 2>/dev/null || true
fi
EOF
        chmod +x /usr/local/bin/fix-permissions
        
        # Set up trap to fix permissions on exit
        trap /usr/local/bin/fix-permissions EXIT
    fi
    
    # Ensure PATH is set for the user
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    
    # Execute as the user with the container's bashrc
    # Use --rcfile to explicitly load the container's bashrc
    exec gosu $USER_NAME /bin/bash --rcfile "$USER_HOME/.bashrc_container"
fi