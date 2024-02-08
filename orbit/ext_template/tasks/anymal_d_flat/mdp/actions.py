from omni.isaac.orbit.utils import configclass
import omni.isaac.orbit_tasks.locomotion.velocity.mdp as mdp  # noqa: F401, F403


@configclass
class ActionsCfg:
    """Action specifications for the MDP."""

    joint_pos = mdp.JointPositionActionCfg(asset_name="robot", joint_names=[".*"], scale=0.5, use_default_offset=True)
