# Extension Template for Orbit

[![IsaacSim](https://img.shields.io/badge/IsaacSim-2023.1.0--hotfix.1-silver.svg)](https://docs.omniverse.nvidia.com/isaacsim/latest/overview.html)
[![Orbit](https://img.shields.io/badge/Orbit-0.2.0-silver)](https://isaac-orbit.github.io/orbit/)
[![Python](https://img.shields.io/badge/python-3.10-blue.svg)](https://docs.python.org/3/whatsnew/3.10.html)
[![Linux platform](https://img.shields.io/badge/platform-linux--64-orange.svg)](https://releases.ubuntu.com/20.04/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://pre-commit.com/)

## Overview

This repository serves as a template for building projects or extensions based on Orbit. It allows you to develop in an isolated environment, outside of the core Orbit repository. 

**Key Features:**

- `Isolation` Work outside the core Orbit repository, ensuring that your development efforts remain self-contained.
- `Flexibility` This template is set up to allow your code to be run as an extension in Omniverse.

**Keywords:** extension, template, orbit

### License

The source code is released under a [BSD 3-Clause license](ros_package_template/LICENSE).

**Author: The ORBIT Project Developers<br />
Affiliation: [The AI Institute](https://theaiinstitute.com/)<br />
Maintainer: Nico Burger, nburger@theaiinstitute.com**

## Setup

### Project

#### Dependencies

This template depends on Isaac Sim and Orbit. For detailed instructions on how to install these dependencies, please refer to the [installation guide](https://isaac-orbit.github.io/orbit/source/setup/installation.html).

- [Isaac Sim](https://docs.omniverse.nvidia.com/isaacsim/latest/index.html)
- [Orbit](https://isaac-orbit.github.io/orbit/)

#### Configuration

Decide on a name for your project or extension. This guide will refer to this name as `<your_extension_name>`.

- Fork the latest version of this template [here](https://github.com/isaac-orbit/orbit.ext_template). Name your forked repository using the following convention: `"orbit.<your_extension_name>"`.

- Clone your forked repository to a location **outside** the orbit repository.

```bash
git clone <your_repository_url>
```

- Configure this template to your specific extension. Search for and replace **`TODO`**'s according to your extension's needs within the following files:

    - `config/extension.toml`
    - `pyproject.toml`

- Rename your source folders and base repository.

```bash
mv orbit/ext_template orbit/<your_extension_name>
```

#### Environment (Optional)

Although optional, this guide assumes you will be working within a virtual environment set up through Orbit, allowing you to use the `python` command directly. If you will not be using a virtual environment, you will need to run Python using `./<path_to_orbit>/orbit.sh -p`.

If you have not already, set up a virtual environment with Orbit by installing conda [here](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html) and use the following commands:

- Create a virtual environment

```bash
# Option 1: Default name for conda environment is 'orbit'
./<path_to_orbit>/orbit.sh --conda
# Option 2: Custom name for conda environment
./<path_to_orbit>/orbit.sh --conda my_env
```

- Activate your virtual environment

```bash
conda activate orbit  # or "conda activate my_env"
```

#### Configure Python Interpreter

In the provided configuration, we set the default Python interpreter to use the Python executable provided by Omniverse. This is specified in the `.vscode/settings.json` file:

```json
    "python.defaultInterpreterPath": "${env:ISAACSIM_PATH}/python.sh",
```

If you want to use a different Python interpreter, you need to change the Python interpreter used by selecting and activating the Python interpreter of your choice in the bottom left corner of VSCode, or opening the command palette (`Ctrl+Shift+P`) and selecting `Python: Select Interpreter`. We recommend using the Python interpreter from your conda environment.

### Run Project as Extension

Your project can be run as an extension in Omniverse, allowing you to import source code or run UI apps.

#### Import Source Code

From within this repository, install your extension as a Python package to the Isaac Sim Python executable.

```bash
python -m pip install --upgrade pip
python -m pip install -e .
```

To verify that your setup is correct and you can successfully import modules from your extension, execute the command below. If it completes without displaying any errors, your setup is correctly configured:

```bash
python -c "import orbit.<your_extension_name>"
```

#### Run from Omniverse

For the moment, refer to the introduction on [Isaac Sim Workflows 1.2.3. GUI](https://docs.omniverse.nvidia.com/isaacsim/latest/introductory_tutorials/tutorial_intro_workflows.html#gui)

TODO: @Nico, add UI template in `orbit/ext_template/scripts/...`

## Usage

Install [RSL_RL](https://github.com/leggedrobotics/rsl_rl) outside of the orbit repository, e.g. `home/code/rsl_rl`.

```bash
git clone https://github.com/leggedrobotics/rsl_rl.git
cd rsl_rl
python -m pip install -e .
```

Train a policy.

```bash
cd <path_to_your_extension>
python scripts/rsl_rl/train.py --task Isaac-Anymal-D-Flat-Template-v0 --headless
```

Play the trained policy.

```bash
python scripts/rsl_rl/play.py --task Isaac-Anymal-D-Flat-Template-Play-v0 --num_envs 16
```

## Finalize

You are all set and no longer need the template instructions

- The `orbit/ext_template/scripts` act as a reference template for your convenience. Delete them if no longer required.

- When ready, replace this `README.md` with the contents of `README_TEMPLATE.md` and customize where appropriate.

## Bugs & Feature Requests

Please report bugs and request features using the [Issue Tracker](https://github.com/isaac-orbit/orbit.ext_template/issues).
