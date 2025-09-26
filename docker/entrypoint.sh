#!/bin/bash

figlet Isaac Lab Extension

echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

exec gosu ${DOCKER_USER_NAME} bash --rcfile ${DOCKER_USER_HOME}/../bash.bashrc