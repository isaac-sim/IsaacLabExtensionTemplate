"""Installation script for the 'omni.isaac.orbit_assets' python package."""

import os
import toml

from setuptools import setup

# Obtain the extension data from the extension.toml file
EXTENSION_PATH = os.path.dirname(os.path.realpath(__file__))
# Read the extension.toml file
EXTENSION_TOML_DATA = toml.load(os.path.join(EXTENSION_PATH, "config", "extension.toml"))

# Minimum dependencies required prior to installation
INSTALL_REQUIRES = [
    "orbit",
]

# Installation operation
setup(
    name="orbit-ext_template",
    author="BDAII",
    maintainer="Nico Burger",
    maintainer_email="nburger@theaiinstitute.com",
    url=EXTENSION_TOML_DATA["package"]["repository"],
    version=EXTENSION_TOML_DATA["package"]["version"],
    description=EXTENSION_TOML_DATA["package"]["description"],
    keywords=EXTENSION_TOML_DATA["package"]["keywords"],
    include_package_data=True,
    python_requires=">=3.7",
    packages=["orbit.ext_template"],
    install_requires=INSTALL_REQUIRES,
    classifiers=[
        "Natural Language :: English",
        "Programming Language :: Python :: 3.7",
        "Isaac Sim :: 2023.1.0-rc.42+2023.1.667.d641947f.tc",
    ],
    zip_safe=False,
)
