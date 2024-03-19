import gymnasium as gym

from .agent import AnymalDFlatPPORunnerTemplateCfg
from .environment import AnymalDFlatEnvTemplateCfg, AnymalDFlatEnvTemplateCfg_PLAY

##
# Register Gym environments.
##

gym.register(
    id="Isaac-Anymal-D-Flat-Template-v0",
    entry_point="omni.isaac.orbit.envs:RLTaskEnv",
    disable_env_checker=True,
    kwargs={
        "env_cfg_entry_point": AnymalDFlatEnvTemplateCfg,
        "rsl_rl_cfg_entry_point": AnymalDFlatPPORunnerTemplateCfg,
    },
)

gym.register(
    id="Isaac-Anymal-D-Flat-Template-Play-v0",
    entry_point="omni.isaac.orbit.envs:RLTaskEnv",
    disable_env_checker=True,
    kwargs={
        "env_cfg_entry_point": AnymalDFlatEnvTemplateCfg_PLAY,
        "rsl_rl_cfg_entry_point": AnymalDFlatPPORunnerTemplateCfg,
    },
)
