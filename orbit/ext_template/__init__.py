"""
Python module serving as a project/extension template.
"""

import os
import toml

# Conveniences to other module directories via relative paths
EXT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../"))
"""Path to the extension source directory."""

EXT_METADATA = toml.load(os.path.join(EXT_DIR, "config", "extension.toml"))
"""Extension metadata dictionary parsed from the extension.toml file."""

# Configure the module-level variables
__version__ = EXT_METADATA["package"]["version"]


##
# Register Gym environments.
##

from omni.isaac.orbit_tasks.utils import import_packages

# The blacklist is used to prevent importing configs from sub-packages
_BLACKLIST_PKGS = ["utils"]
# Import all configs in this package
import_packages(__name__, _BLACKLIST_PKGS)


##
# Register UI extensions.
##

from .ui_example import *
