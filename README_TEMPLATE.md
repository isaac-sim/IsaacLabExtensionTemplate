# Extension Template

## Overview

**`TODO`** This section shall contain the extension description.

**Keywords:** **`TODO`** extension, template, orbit

### License

The source code is released under a [BSD 3-Clause license](ros_package_template/LICENSE).

**Author: `TODO` Nico Burger<br />
Affiliation: `TODO` [The AI Institute](https://theaiinstitute.com/)<br />
Maintainer: `TODO` Nico Burger, nburger@theaiinstitute.com**


**`TODO`** Add an image if suitable.
![Example image](docs/orbit.jpg)


## Installation

### Building from Source

#### Dependencies

- [Isaac Sim](https://docs.omniverse.nvidia.com/isaacsim/latest/installation/install_workstation.html)
- [Orbit](https://isaac-orbit.github.io/orbit/source/setup/installation.html) (version 0.2.0)
- **`TODO`** Add other dependencies if required.

#### Building

Set your orbit path as an environment variable.

```bash
export ORBIT_PATH=<path_to_orbit_repository>
```

Clone the latest version of this extension template.

**`TODO`** Update your git repository url in the bash command below.

```bash
git clone https://github.com/isaac-orbit/orbit.your_extension_name.git
```

Install the extension as a python package to the isaac sim python executable.

```bash
${ORBIT_PATH}/_isaac_sim/python.sh -m pip install --upgrade pip
${ORBIT_PATH}/_isaac_sim/python.sh -m pip install -e .
```

**`TODO`** Adjust and add other build steps if required.
### Running in Docker

**`TODO`** Add steps to run in docker.

### Unit Tests

**`TODO`** Add steps to run unit tests.

## Usage

**`TODO`** Add steps on how to use the extension.

## Bugs & Feature Requests

Please report bugs and request features using the [Issue Tracker](https://github.com/isaac-orbit/orbit.ext_template/issues). **`TODO`** Update "Issue Tracker" link.
