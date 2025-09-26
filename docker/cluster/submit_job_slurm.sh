#!/usr/bin/env bash

# in the case you need to load specific modules on the cluster, add them here
module load eth_proxy

# Debug: Show what arguments this script received
echo "[submit_job_slurm.sh] Received arguments: $@"
echo "[submit_job_slurm.sh] Number of arguments: $#"

# Parse arguments
dir="$1"
profile="$2"
# Skip args 3 and 4 (empty mount args and "--")
shift 4
# Remaining args are the script arguments
script_args="$@"

echo "[submit_job_slurm.sh] Directory: $dir"
echo "[submit_job_slurm.sh] Profile: $profile"
echo "[submit_job_slurm.sh] Script args: $script_args"

# create job script with compute demands
### MODIFY HERE FOR YOUR JOB ###
cat <<EOT > job.sh
#!/bin/bash

#SBATCH -n 1
#SBATCH --cpus-per-task=4
#SBATCH --gpus=rtx_3090:1
#SBATCH --time=03:00:00
#SBATCH --mem-per-cpu=4048
#SBATCH --mail-type=END
#SBATCH --mail-user=name@mail
#SBATCH --job-name="isaaclab-ext-$(date +"%Y-%m-%dT%H:%M")"

# Variables embedded from submit script
dir="$dir"
profile="$profile"
script_args="$script_args"

echo "[SLURM JOB] Directory: \$dir"
echo "[SLURM JOB] Profile: \$profile"
echo "[SLURM JOB] Script arguments: \$script_args"

# Mount configuration is now handled by .mount.config file
bash "\$dir/docker/cluster/run_singularity.sh" "\$dir" "\$profile" "\$dir/docker/cluster/.env.cluster" "\$dir/docker/.env.ext_template" -- \$script_args
EOT

# Submit the job
sbatch < job.sh
rm job.sh