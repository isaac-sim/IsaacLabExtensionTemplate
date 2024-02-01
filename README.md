# Package Name

README.md modified from https://github.com/leggedrobotics/ros_best_practices/tree/main/ros_package_template

## Overview

This is a template: replace, remove, and add where required. Describe what this package does and what it's meant for in a few sentences.

**Keywords:** example, package, template

Or, add some keywords to the Bitbucket or GitHub repository.

### License

The source code is released under a [BSD 3-Clause license](ros_package_template/LICENSE).

**Author: Nico Burger<br />
Affiliation: [The AI Institute](https://theaiinstitute.com/)<br />
Maintainer: Nico Burger, nburger@theaiinstitute.com**

The EXTENSION TEMPLATE package has been tested on Ubuntu 22.04.
This is research code, expect that it changes often and any fitness for a particular purpose is disclaimed.


![Example image](docs/bdaii.png)


## Installation

### Building from Source

#### Dependencies

- [Isaac Sim](https://docs.omniverse.nvidia.com/isaacsim/latest/installation/install_workstation.html)
- [Orbit](https://isaac-orbit.github.io/orbit/source/setup/installation.html)

#### Building

Set your orbit path as an environment variable.

```bash
export ORBIT_PATH=<path-to-orbit>
```

Clone the latest version of this extension template.

```bash
git clone https://github.com/isaac-orbit/orbit.ext_template.git
```

Install the extension as a python package to the isaac sim python executable.

```bash
${ORBIT_PATH}/_isaac_sim/python.sh -m pip install --upgrade pip
${ORBIT_PATH}/_isaac_sim/python.sh -m pip install -e .
```

### Running in Docker

TODO

### Unit Tests

TODO

## Usage

### Train and play a policy using Orbit and rsl_rl

```bash
orbit -p orbit/ext_template/scripts/train.py --task Isaac-Velocity-Flat-Anymal-D-v0 --headless
```

```bash
orbit -p orbit/ext_template/scripts/play.py --task Isaac-Velocity-Flat-Anymal-D-v0 --num_envs 16
```

## Bugs & Feature Requests

Please report bugs and request features using the [Issue Tracker](https://github.com/isaac-orbit/orbit.ext_template/issues).

## TODO

- how to connect with conda environments, rather than ISAACSIM_PYTHON_EXE