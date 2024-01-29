# TODO: licences?

"""
Python module serving as an extension template.
"""

import os
import toml

# Conveniences to other module directories via relative paths
print(os.path.dirname(__file__))
EXT_TEMPLATE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../"))
"""Path to the extension source directory."""

EXT_TEMPLATE_METADATA = toml.load(os.path.join(EXT_TEMPLATE_DIR, "config", "extension.toml"))
"""Extension metadata dictionary parsed from the extension.toml file."""

# Configure the module-level variables
__version__ = EXT_TEMPLATE_METADATA["package"]["version"]
