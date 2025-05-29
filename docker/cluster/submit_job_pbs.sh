#!/usr/bin/env bash

# in the case you need to load specific modules on the cluster, add them here
# e.g., `module load eth_proxy`

# create job script with compute demands
### MODIFY HERE FOR YOUR JOB ###
cat <<EOT > job.sh
#!/bin/bash

#PBS -l select=1:ncpus=8:mpiprocs=1:ngpus=1
#PBS -l walltime=01:00:00
#PBS -j oe
#PBS -q gpu
#PBS -N isaaclab-ext
#PBS -m bea -M "user@mail"

# Variables passed from submit script
dir="$1"
profile="$2"
# Skip empty mount args and "--" delimiter
shift 4
script_args="\$@"

# Mount configuration is now handled by .mount.config file
bash "\$dir/docker/cluster/run_singularity.sh" "\$dir" "\$profile" "\$dir/docker/cluster/.env.cluster" "\$dir/docker/.env.ext_template" -- \$script_args
EOT

qsub job.sh
rm job.sh