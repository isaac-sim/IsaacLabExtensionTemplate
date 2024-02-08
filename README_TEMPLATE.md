# Package Name

[![IsaacSim](https://img.shields.io/badge/IsaacSim-2023.1.0--hotfix.1-silver.svg)](https://docs.omniverse.nvidia.com/isaacsim/latest/overview.html)
[![Orbit](https://img.shields.io/badge/Orbit-0.2.0-silver)](https://isaac-orbit.github.io/orbit/)
[![Python](https://img.shields.io/badge/python-3.10-blue.svg)](https://docs.python.org/3/whatsnew/3.10.html)
[![Linux platform](https://img.shields.io/badge/platform-linux--64-orange.svg)](https://releases.ubuntu.com/20.04/)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://pre-commit.com/)

## Overview

This is a template: replace, remove, and add where required. Describe here what this package does and what it's meant for in a few sentences.

**Keywords:** example, package, template

Or, add some keywords to the Bitbucket or GitHub repository.

### License

The source code is released under a [BSD 3-Clause license](ros_package_template/LICENSE).

**Author: First_Name Second_Name<br />
Affiliation: [Company](https://www.company.com/)<br />
Maintainer: First_Name Second_Name, example@mail.com**

### Publications

If you use this work in an academic context, please cite the following publication(s):

* M. Mittal, C. Yu, Q. Yu, J. Liu, N. Rudin, D. Hoeller, J. Yuan, R. Singh, Y. Guo, H. Mazhar, A. Mandlekar, B. Babich, G. State, M. Hutter, and A. Garg: **ORBIT: A Unified Simulation Framework for Interactive Robot Learning Environments**. IEEE Robotics and Automation Letters, 2013. ([PDF](https://arxiv.org/pdf/2301.04195.pdf))

        @misc{mittal2023orbit,
            title={ORBIT: A Unified Simulation Framework for Interactive Robot Learning Environments}, 
            author={Mayank Mittal and Calvin Yu and Qinxi Yu and Jingzhou Liu and Nikita Rudin and David Hoeller and Jia Lin Yuan and Pooria Poorsarvi Tehrani and Ritvik Singh and Yunrong Guo and Hammad Mazhar and Ajay Mandlekar and Buck Babich and Gavriel State and Marco Hutter and Animesh Garg},
            year={2023},
            eprint={2301.04195},
            archivePrefix={arXiv},
            primaryClass={cs.RO}
        }


## Installation

### Installation from Packages

To install all packages from this repository as Debian packages use

```bash
sudo apt-get install x11-apps
```

### Building from Source

#### Dependencies

This template depends on Isaac Sim and Orbit. For detailed instructions on how to install these dependencies, please refer to the [installation guide](https://isaac-orbit.github.io/orbit/source/setup/installation.html).

- [Isaac Sim](https://docs.omniverse.nvidia.com/isaacsim/latest/index.html)
- [Orbit](https://isaac-orbit.github.io/orbit/)

#### Building

To build from source, clone the latest version from this repository and ...

```bash
cd extensions
git clone https://github.com/isaac-orbit/orbit.ext_template.git
cd orbit.ext_template
```

### Running in Docker

Docker is a great way to run an application with all dependencies and libraries bundles together. 
Make sure to [install Docker](https://docs.docker.com/get-docker/) first. 

First, spin up a simple container:

```bash
docker run -it --rm --name my_container
```

From within the container, run some setup commands...

### Unit Tests

Run the unit tests with

```bash
python unittest.py
```

## Usage

Describe the quickest way to run this software, for example:

Run the main script

```bash
python scripts/main.py
```

## Bugs & Feature Requests

Please report bugs and request features using the [Issue Tracker](https://github.com/isaac-orbit/orbit.ext_template/issues).