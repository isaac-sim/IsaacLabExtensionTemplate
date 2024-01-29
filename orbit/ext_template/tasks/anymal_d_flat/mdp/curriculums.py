from omni.isaac.orbit.utils import configclass


@configclass
class CurriculumCfg:
    """Curriculum terms for the MDP."""

    terrain_levels = None
