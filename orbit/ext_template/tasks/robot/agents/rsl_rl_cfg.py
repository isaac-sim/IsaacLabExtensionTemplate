from omni.isaac.orbit.utils import configclass

from omni.isaac.orbit_tasks.locomotion.velocity.config.anymal_d.agents import rsl_rl_cfg


@configclass
class AnymalDFlatPPORunnerCfg(rsl_rl_cfg.AnymalDRoughPPORunnerCfg):
    def __post_init__(self):
        super().__post_init__()

        self.max_iterations = 300
        self.experiment_name = "anymal_d_flat"
        self.policy.actor_hidden_dims = [128, 128, 128]
        self.policy.critic_hidden_dims = [128, 128, 128]
