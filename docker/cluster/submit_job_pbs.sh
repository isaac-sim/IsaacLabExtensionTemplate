#!/usr/bin/env bash

# in the case you need to load specific modules on the cluster, add them here
module load eth_proxy

# Debug: Show what arguments this script received
echo "[submit_job_pbs.sh] Received arguments: $@"
echo "[submit_job_pbs.sh] Number of arguments: $#"

# Parse arguments
dir="$1"
profile="$2"
# Skip args 3 and 4 (empty mount args and "--")
shift 4
# Remaining args are the script arguments
script_args="$@"

echo "[submit_job_pbs.sh] Directory: $dir"
echo "[submit_job_pbs.sh] Profile: $profile"
echo "[submit_job_pbs.sh] Script args: $script_args"

# create job script with compute demands
### MODIFY HERE FOR YOUR JOB ###
cat <<EOT > job.sh
#!/bin/bash

#PBS -l select=1:mem=100gb:ncpus=8:gpus=1
#PBS -l walltime=08:00:00
#PBS -q gpu
#PBS -N isaaclab-ext
#PBS -m bea -M "user@mail"

# Variables embedded from submit script
dir="$dir"
profile="$profile"
script_args="$script_args"

echo "[PBS JOB] Directory: \$dir"
echo "[PBS JOB] Profile: \$profile"
echo "[PBS JOB] Script arguments: \$script_args"

# Mount configuration is now handled by .mount.config file
bash "\$dir/docker/cluster/run_singularity.sh" "\$dir" "\$profile" "\$dir/docker/cluster/.env.cluster" "\$dir/docker/.env.ext_template" -- \$script_args
EOT

# Submit the job
qsub < job.sh
rm job.sh