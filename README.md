# Extension Template for Isaac Lab

[![IsaacSim](https://img.shields.io/badge/IsaacSim-4.0.0-silver.svg)](https://docs.omniverse.nvidia.com/isaacsim/latest/overview.html)
[![Isaac Lab](https://img.shields.io/badge/IsaacLab-1.0.0-silver)](https://isaac-sim.github.io/IsaacLab)
[![Python](https://img.shields.io/badge/python-3.10-blue.svg)](https://docs.python.org/3/whatsnew/3.10.html)
[![Linux platform](https://img.shields.io/badge/platform-linux--64-orange.svg)](https://releases.ubuntu.com/20.04/)
[![Windows platform](https://img.shields.io/badge/platform-windows--64-orange.svg)](https://www.microsoft.com/en-us/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://pre-commit.com/)
[![License](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/license/mit)

## Overview

This repository serves as a template for building projects or extensions based on Isaac Lab. It allows you to develop in an isolated environment, outside of the core Isaac Lab repository.

- **Project Template**
    Ensures access to `Isaac Sim` and `Isaac Lab` functionalities, which can be used as a project template.

- **Omniverse Extension**
    Can be used as an Omniverse extension, ideal for projects that leverage the Omniverse platform's graphical user interface.

**Key Features:**

- `Isolation` Work outside the core Isaac Lab repository, ensuring that your development efforts remain self-contained.
- `Flexibility` This template is set up to allow your code to be run as an extension in Omniverse.

**Keywords:** extension, template, isaaclab


### Installation

- You must have installed Isaac Lab first, see the [installation guide](https://isaac-sim.github.io/IsaacLab/source/setup/installation/index.html).

- Throughout the repository, the name `ext_template` only serves as an example and we provide a script to rename all the references to it automatically:

```
# Rename all occurences of ext_template (in files/directories) to your_fancy_extension
python rename_template.py your_fancy_extension
```

- Using a python interpreter that has Isaac Lab installed, install the library

```
python -m pip install -e .
```

#### Set up IDE (Optional)

To setup the IDE, please follow these instructions:

- Run VSCode Tasks, by pressing `Ctrl+Shift+P`, selecting `Tasks: Run Task` and running the `setup_python_env` in the drop down menu. When running this task, you will be prompted to add the absolute path to your Isaac Lab installation.

If everything executes correctly, it should create a file .python.env in the .vscode directory. The file contains the python paths to all the extensions provided by Isaac Sim and Omniverse. This helps in indexing all the python modules for intelligent suggestions while writing code.


#### Setup as Omniverse Extension

We provide an example UI extension that will load upon enabling your extension defined in `ext_template/ui_extension_example.py`. For more information on UI extensions, enable and check out the source code of the `omni.isaac.ui_template` extension and refer to the introduction on [Isaac Sim Workflows 1.2.3. GUI](https://docs.omniverse.nvidia.com/isaacsim/latest/introductory_tutorials/tutorial_intro_workflows.html#gui).

To enable your extension, follow these steps:

1. **Add the search path of your repository** to the extension manager:
    - Navigate to the extension manager using `Window` -> `Extensions`.
    - Click on the **Hamburger Icon** (☰), then go to `Settings`.
    - In the `Extension Search Paths`, enter the path that goes up to your repository's location without actually including the repository's own directory. For example, if your repository is located at `/home/code/IsaacLabExtensionTemplate`, you should add `/home/code` as the search path.
    - If not already present, in the `Extension Search Paths`, enter the path that leads to your local Isaac Lab directory. For example: `/home/IsaacLab/source/extensions`
    - Click on the **Hamburger Icon** (☰), then click `Refresh`.

2. **Search and enable your extension**:
    - Find your extension under the `Third Party` category.
    - Toggle it to enable your extension.


## Pre-Commit

Pre-committing involves using a framework to automate the process of enforcing code quality standards before code is actually committed to a version control system, like Git. This process involves setting up hooks that run automated checks, such as code formatting, linting (checking for programming errors, bugs, stylistic errors, and suspicious constructs), and running tests. If these checks pass, the commit is allowed; if not, the commit is blocked until the issues are resolved. This ensures that all code committed to the repository adheres to the defined quality standards, leading to a cleaner, more maintainable codebase. To do so, we use the [pre-commit](https://pre-commit.com/) module. Install the module using:

```bash
pip install pre-commit
```

Run the pre-commit with:

```bash
pre-commit run --all-files
```
