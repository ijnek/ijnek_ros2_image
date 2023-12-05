# ijnek_ros2_image

This repository stores a Dockerfile (and an action to publish it), to clone all ros2 repos I maintain, as well as some software I often use including:

* SimSpark (RCSSServer3d)
* Webots (+ Webots Lola Controller)
* SPL GameController

**WARNING: THIS IS NOT FOR PUBLIC USAGE, DO NOT USE**

# Usage

```bash
git clone git@github.com:ijnek/ijnek_ros2_image.git
cd ijnek_ros2_image
```

Then, hit `F1` to open the Command Palette, and select `Dev Containers: Rebuild Without Cache and Reopen in Container` to open the workspace in a container.

```bash
vcs import ws/src < src.repos
```

Next time you open the dev container, you can just hit `F1` and select `Dev Containers: Reopen in Container`.

The `ws` directory is mounted into the dev container, so even if you rebuild the container, you will not lose your workspace.
