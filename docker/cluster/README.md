# Cluster Operations Guide

This guide focuses on cluster-specific operations for deploying IsaacLab extension training jobs. For general Docker setup and local development, see the main [Docker README](../README.md).

## Prerequisites

1. **SSH access** to your cluster
2. **Docker and Apptainer** installed locally
3. **Environment file**: Copy and configure the cluster environment:
   ```bash
   cp docker/cluster/.env.cluster.template docker/cluster/.env.cluster
   ```

#### Cluster Configuration Examples

Edit `docker/cluster/.env.cluster` with your cluster-specific settings:

**Generic University Cluster:**
```bash
CLUSTER_USER=your_username                    # ← CHANGE THIS
CLUSTER_LOGIN=$CLUSTER_USER@cluster.university.edu  # ← CHANGE THIS
CLUSTER_ISAACLAB_DIR=/cluster/home/$CLUSTER_USER/$EXTENSION_NAME
CLUSTER_SIF_PATH=/cluster/scratch/$CLUSTER_USER
CLUSTER_JOB_SCHEDULER=SLURM                  # or PBS
```

**ETH Euler Example:**
```bash
CLUSTER_USER=your_nethz_id
CLUSTER_LOGIN=$CLUSTER_USER@euler.ethz.ch
CLUSTER_ISAACLAB_DIR=/cluster/home/$CLUSTER_USER/$EXTENSION_NAME
CLUSTER_SIF_PATH=/cluster/work/rsl/$CLUSTER_USER
CLUSTER_JOB_SCHEDULER=SLURM
```

#### Validate Cluster Setup
```bash
# Test SSH connection
ssh $CLUSTER_USER@your_cluster_address "echo 'Connection successful'"

# Verify directories exist
ssh $CLUSTER_USER@your_cluster_address "mkdir -p /path/to/cluster/directories"
```

## Quick Start

```bash
# 1. Build container locally (if not already done)
cd docker
./container.sh -p ext build

# 2. Push container to cluster
cd cluster
./cluster_interface.sh push ext_template

# 3. Submit training job
./cluster_interface.sh job ext_template --task YourTask --num_envs 64000

# 4. Sync logs back to local machine
./sync_experiments.sh --remove ~/experiments/logs
```

## Detailed Operations

### Pushing Container to Cluster

The push operation converts your Docker image to Singularity format and uploads it:

```bash
./cluster_interface.sh push <profile>

# Example
./cluster_interface.sh push ext_template
```

**Note**: The image must be named `isaac-lab-<profile>` (e.g., `isaac-lab-ext_template`).

### Submitting Jobs

Submit jobs with custom arguments:

```bash
./cluster_interface.sh job <profile> [arguments]

# Examples
./cluster_interface.sh job ext_template --task YourTask --num_envs 64000
./cluster_interface.sh job ext_template --task YourOtherTask --headless

# Check for large files after sync (adds validation step)
./cluster_interface.sh -c job ext_template --task YourTask
```

**Note**: Each job submission creates a timestamped directory on the cluster (e.g., `${CLUSTER_ISAACLAB_DIR}_20231215_143022`) to ensure multiple jobs don't interfere with each other. The script arguments are properly preserved and passed through to your training script.

### External Codebase Mounting

The cluster system supports the unified mount configuration:

```bash
# Configure mounts locally before pushing
cd docker
./container.sh mount-setup

# Mounts are automatically synced with the container
cd cluster
./cluster_interface.sh push ext_template
```

#### Mount Modes

1. **Sync Mode** (default): Syncs codebase from local to cluster
2. **Mount-Only Mode**: Uses existing codebase on cluster without syncing

```bash
# Configure mount-only mode
cd docker
./container.sh mount-enable isaaclab
./container.sh mount-set-sync isaaclab off
./container.sh mount-set-cluster isaaclab /cluster/home/$USER/isaaclab
```

### Synchronizing Logs

Sync experiment logs from cluster to local machine:

```bash
# Basic sync
./sync_experiments.sh

# Sync to specific folder
./sync_experiments.sh ~/my-experiments

# Sync and remove remote logs
./sync_experiments.sh --remove ~/experiments/logs
```

## Job Management

### Check Job Status

```bash
# SLURM - List your jobs
ssh $CLUSTER_LOGIN "squeue -u \$USER"

# SLURM - Detailed job information  
ssh $CLUSTER_LOGIN "scontrol show job <job_id>"

# PBS - List your jobs
ssh $CLUSTER_LOGIN "qstat -u \$USER"

# PBS - Detailed job information
ssh $CLUSTER_LOGIN "qstat -f <job_id>"
```

**Example Output:**
```bash
$ ssh your_user@cluster.edu "squeue -u \$USER"
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
          12345678  gpuhe.4h isaaclab your_user  R       2:15      1 gpu-node-001
```

### Cancel Jobs

```bash
# SLURM
ssh $CLUSTER_LOGIN "scancel <job_id>"

# PBS
ssh $CLUSTER_LOGIN "qdel <job_id>"
```

### View Job Output

Job outputs are written to the job scheduler's output location. The exact location depends on your cluster configuration:
```bash
# For SLURM (usually in the submission directory)
ssh $CLUSTER_LOGIN "ls -la slurm-*.out"

# For PBS (check your cluster's default output location)
ssh $CLUSTER_LOGIN "ls -la *.o*"

# View recent job output
ssh $CLUSTER_LOGIN "tail -f <job_output_file>"
```

## Environment Variables

Key variables in `.env.cluster`:

| Variable | Description | Example |
|----------|-------------|---------|
| `CLUSTER_USER` | Your cluster username | `jsmith` |
| `CLUSTER_LOGIN` | SSH login string | `jsmith@euler.ethz.ch` |
| `CLUSTER_ISAACLAB_DIR` | Experiment directory | `/cluster/scratch/$USER/isaaclab` |
| `CLUSTER_SIF_PATH` | Singularity images | `/cluster/home/$USER/.singularity` |
| `CLUSTER_JOB_SCHEDULER` | Job system | `SLURM` or `PBS` |
| `CLUSTER_PYTHON_EXECUTABLE` | Script to run | `scripts/rsl_rl/train.py` |
| `CLUSTER_ISAAC_SIM_CACHE_DIR` | Isaac Sim cache | `/cluster/scratch/$USER/isaac-sim-cache` |
| `REMOVE_CODE_COPY_AFTER_JOB` | Cleanup after job | `true` or `false` |

## Customizing Job Submission

### Resource Requirements

Edit `submit_job_slurm.sh` or `submit_job_pbs.sh` to modify:

For SLURM:
```bash
#SBATCH -n 1                     # Number of tasks
#SBATCH --cpus-per-task=4        # CPUs per task
#SBATCH --gpus=rtx_3090:1        # GPU type and count
#SBATCH --time=03:00:00          # Maximum runtime
#SBATCH --mem-per-cpu=4048       # Memory per CPU (MB)
```

For PBS:
```bash
#PBS -l select=1:ncpus=8:mpiprocs=1:ngpus=1
#PBS -l walltime=01:00:00
```

### Module Loading

Add any required cluster modules in the submission scripts:
```bash
module load eth_proxy    # Example for ETH clusters
module load cuda/11.8    # Load specific CUDA version
```

## Troubleshooting

### Container Push Fails

```bash
# Check Docker image exists
docker images | grep isaac-lab-ext_template

# Verify SSH connection
ssh $CLUSTER_LOGIN "echo 'Connection successful'"

# Check available space
ssh $CLUSTER_LOGIN "df -h $CLUSTER_SIF_PATH"
```

### Job Submission Issues

```bash
# Verify Singularity image on cluster
ssh $CLUSTER_LOGIN "ls -la $CLUSTER_SIF_PATH/*.tar"

# Check job script was created
ssh $CLUSTER_LOGIN "ls -la $CLUSTER_ISAACLAB_DIR_*/*.sh"

# View error logs from job scheduler
# For SLURM
ssh $CLUSTER_LOGIN "cat slurm-*.out"
# For PBS
ssh $CLUSTER_LOGIN "cat *.e*"
```

### Mount Path Issues

If you see errors about `$CLUSTER_USER` not being expanded:
1. Ensure `CLUSTER_USER` is set in your `.env.cluster` file
2. Check that the environment file is being sourced correctly
3. Verify mount paths don't contain literal `$CLUSTER_USER` after expansion

### Performance Tips

1. **Use appropriate `--num_envs`**: Balance between GPU memory and parallelism
2. **Enable headless mode**: Add `--headless` for better performance
3. **Monitor GPU usage**: Check with `nvidia-smi` during training
4. **Use local scratch**: Configure `CLUSTER_ISAAC_SIM_CACHE_DIR` to use fast local storage

## Advanced Usage

### Custom Job Scripts

For complex workflows, create custom submission scripts:

```bash
# Copy and modify submission scripts
cp submit_job_slurm.sh submit_job_custom.sh
# Edit resource requirements, add pre/post processing, etc.
```

### Multi-GPU Training

Configure multi-GPU jobs in the submission scripts:
- SLURM: Modify `#SBATCH --gres=gpu:X`
- PBS: Modify `#PBS -l select=1:ncpus=X:ngpus=Y`

### Batch Job Submission

Submit multiple experiments:

```bash
for task in Task1 Task2 Task3; do
    ./cluster_interface.sh job ext_template --task $task --num_envs 32000
done
```

### Environment-Specific Settings

Override cluster settings for specific runs:

```bash
# Temporary override
CLUSTER_PYTHON_EXECUTABLE=scripts/custom_script.py \
    ./cluster_interface.sh job ext_template

# Different cluster configuration
ENV_CLUSTER_PATH=.env.cluster.gpu2 \
    ./cluster_interface.sh push ext_template
```

## Complete Workflow Example

Here's a complete example of training a quadruped robot on a cluster:

```bash
# 1. Setup (one-time)
cp docker/cluster/.env.cluster.template docker/cluster/.env.cluster
# Edit .env.cluster with your cluster credentials

# 2. Test locally first
./docker/run_dev.sh python scripts/rsl_rl/train.py --task Isaac-Velocity-Flat-Anymal-D-v0 --num_envs 64 --headless

# 3. Build and push to cluster  
cd docker
./container.sh -p ext build
cd cluster
./cluster_interface.sh push ext_template

# 4. Submit training job
./cluster_interface.sh job ext_template --task Isaac-Velocity-Flat-Anymal-D-v0 --num_envs 4096 --headless

# 5. Monitor job
ssh your_user@cluster.edu "squeue -u \$USER"

# 6. Check logs during training
ssh your_user@cluster.edu "tail -f /path/to/job/output.log"

# 7. Sync results back when complete
./sync_experiments.sh ~/experiments/logs

# 8. Clean up (optional)
./sync_experiments.sh --remove ~/experiments/logs
```

**Expected Timeline:**
- Local test: ~2-5 minutes  
- Container push: ~10-15 minutes
- Job submission: ~5 seconds
- Training time: varies (30 minutes to several hours)
- Results sync: ~1-2 minutes

## Best Practices

1. **Test Locally First**: Verify your code works in the Docker container before cluster submission
2. **Start Small**: Test with fewer environments before scaling up
3. **Monitor Resources**: Check cluster quotas and job limits  
4. **Use Checkpointing**: Save models periodically for long-running jobs
5. **Clean Up**: Remove old experiments to save cluster storage
6. **Resource Planning**: Check queue wait times during peak hours
7. **Validate Setup**: Use the validation commands before first cluster use