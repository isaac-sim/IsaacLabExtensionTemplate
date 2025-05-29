#!/usr/bin/env bash

# in the case you need to load specific modules on the cluster, add them here
module load eth_proxy

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

# Variables passed from submit script
dir="$1"
profile="$2"
# Skip empty mount args and "--" delimiter
shift 4
script_args="\$@"

# Mount configuration is now handled by .mount.config file
bash "\$dir/docker/cluster/run_singularity.sh" "\$dir" "\$profile" "\$dir/docker/cluster/.env.cluster" "\$dir/docker/.env.ext_template" -- \$script_args
EOT

sbatch < job.sh
rm job.sh