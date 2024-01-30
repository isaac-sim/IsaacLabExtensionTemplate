# Package Name

### README.md modified from https://github.com/leggedrobotics/ros_best_practices/tree/main/ros_package_template

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


![Example image](docs/ai-flowers.png)


## Installation

### Building from Source

#### Dependencies

- [Omniverse](https://docs.omniverse.nvidia.com/isaacsim/latest/installation/install_workstation.html)
- [Orbit](https://isaac-orbit.github.io/orbit/source/setup/installation.html)

#### Building

Clone the latest version of the extension.

```bash
git clone https://github.com/isaac-orbit/orbit.ext_template.git
```

Install the extension as a python package using pip.

```bash
sudo apt install python3-pip
${ISAACSIM_PATH}/python.sh -m pip install -e .
```

### Running in Docker

TODO

### Unit Tests

TODO

## Usage

### Simple

Illustrate the key funcionalities of your extension, for example:

```python
from orbit.ext_template import hello_world

# print 'Hello World!'
hello_world()
```

### Use rsl_rl

Train a policy with rsl_rl.

```bash
orbit -p orbit/ext_template/scripts/train.py --task Isaac-Velocity-Flat-Anymal-D-v0 --headless
```

Play a policy that was trained on rsl_rl.

```bash
orbit -p orbit/ext_template/scripts/play.py --task Isaac-Velocity-Flat-Anymal-D-v0 --num_envs 16 --checkpoint <model.pt>
```

## Bugs & Feature Requests

Please report bugs and request features using the [Issue Tracker](https://github.com/ethz-asl/ros_best_practices/issues).


[ROS]: http://www.ros.org
[rviz]: http://wiki.ros.org/rviz
[Eigen]: http://eigen.tuxfamily.org
[std_srvs/Trigger]: http://docs.ros.org/api/std_srvs/html/srv/Trigger.html
[sensor_msgs/Temperature]: http://docs.ros.org/api/sensor_msgs/html/msg/Temperature.html