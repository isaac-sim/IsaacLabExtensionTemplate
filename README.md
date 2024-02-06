# Extension Template for Orbit

## Overview

This repository acts as a template to build extensions for orbit.

**Keywords:** extension, template, orbit

### License

The source code is released under a [BSD 3-Clause license](ros_package_template/LICENSE).

**Author: Nico Burger<br />
Affiliation: [The AI Institute](https://theaiinstitute.com/)<br />
Maintainer: Nico Burger, nburger@theaiinstitute.com**

## Setup Extension

### Dependencies

- [Isaac Sim](https://docs.omniverse.nvidia.com/isaacsim/latest/installation/install_workstation.html)
- [Orbit](https://isaac-orbit.github.io/orbit/source/setup/installation.html) (version 0.2.0)

### Build

- Set build variables by tracking your orbit path and coming up with an extension name (e.g. `my_extension`).

```bash
export ORBIT_PATH=<path_to_orbit_repository>
export EXT_NAME=<your_extension_name>
```

- Clone the latest version of this extension template outside of the orbit repository, e.g. `home/code/orbit.ext_template`.

```bash
git clone https://github.com/isaac-orbit/orbit.ext_template.git
```

- Configure this template to your specific extension. Search for and replace **`TODO`**'s according to your extension's needs within the following files:

    - `config/extension.toml`
    - `orbit/ext_template/__init__.py`
    - `pyproject.toml`
    - `README_TEMPLATE.md`

- Copy the `README_TEMPLATE.md` file to the documentation folder.

```bash
cp README_TEMPLATE.md docs/README.md
```

- Rename your source folders and base repository.

```bash
mv orbit/ext_template orbit/${EXT_NAME}
cd ..
mv orbit.ext_template orbit.${EXT_NAME}
```

### VSCode Setup Instructions

To configure your Python environment in Visual Studio Code, you can follow these simple steps:

1. **Open the Command Palette**: Use the shortcut `Ctrl+Shift+P` to bring up the Command Palette, which allows you to access various commands and tasks within the editor.

2. **Execute the Run Task Command**: Type `Tasks: Run Task` into the Command Palette input area and hit `Enter`.

3. **Launch the Python Environment Setup**: Look for `setup_python_env` in the list of tasks that appears, and select it to start the setup process for your Python environment.

By following these steps, you will successfully prepare your VSCode environment for Python development.

### Installation

The extension can either live isolated from or integrated in the orbit repository.
The installation method is a matter of preference and not relevant.
For consistency, we recommend using the isolated installation method.

#### A. Isolated **`RECOMMENDED`**

- Install the extension as a python package to the isaac sim python executable. This keeps the extension outside of the orbit repository.

```bash
${ORBIT_PATH}/_isaac_sim/python.sh -m pip install --upgrade pip
${ORBIT_PATH}/_isaac_sim/python.sh -m pip install -e .
```

#### B. Integrated

- Create a symbolic link into the `source/extensions` directory in the orbit repository.

```bash
ln -s $(pwd)/orbit.${EXT_NAME} orbit/source/extensions/orbit.${EXT_NAME}
```

- Setup the python module for orbit.

```bash
cd ${ORBIT_PATH}
./orbit.sh --install
```

### Validate

To verify that your setup is correct and you can successfully import modules from orbit as well as this extension, execute the command below. If it completes without displaying any errors, your setup is correctly configured:

```bash
${ORBIT_PATH}/_isaac_sim/python.sh -c "import omni.isaac.orbit; import orbit.<your_extension_name>"
```

For further validation, we provide a sample script to train and play an agent with [RSL_RL](https://github.com/leggedrobotics/rsl_rl) in [Example Usage](#example-usage).

### Finalize

- The `orbit/ext_template/scripts` act as a reference template for your convenience. Delete them if no longer required:

```bash
rm -rf orbit/ext_template/scripts
```

- Create a new git repository called `orbit.<your_extension_name>`.

- Update the remote repository url.

```bash
rm -rf .git
git init
git remote add origin <your_repository_url>
```

- You are all set and no longer need these instructions. Replace this file (`README.md`) with the contents of `README_TEMPLATE.md` and delete the `README_TEMPLATE.md` file.

## Example Usage

Install [RSL_RL](https://github.com/leggedrobotics/rsl_rl) outside of the orbit repository, e.g. `home/code/rsl_rl`.

```bash
git clone https://github.com/leggedrobotics/rsl_rl.git
cd rsl_rl
${ORBIT_PATH}/_isaac_sim/python.sh -m pip install -e .
```

Train a policy.

```bash
cd <path_to_your_extension>
orbit -p orbit/<your_extension_name>/scripts/train.py --task Isaac-Velocity-Flat-Anymal-D-v0 --headless
```

Play the trained policy.

```bash
orbit -p orbit/<your_extension_name>/scripts/play.py --task Isaac-Velocity-Flat-Anymal-D-v0 --num_envs 16
```

## Bugs & Feature Requests

Please report bugs and request features using the [Issue Tracker](https://github.com/isaac-orbit/orbit.ext_template/issues).
