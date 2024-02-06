# TODO: Add license if required.

"""
Python module serving as an extension template.  # TODO: Replace with a description of your extension
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
