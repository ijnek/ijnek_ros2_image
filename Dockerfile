FROM osrf/ros:rolling-desktop-full

# Disable interactive frontend
# NOTE: for this to take effect when using "sudo" apt install, we need the -E flag to preserve the environment variable inside the sudo command
ARG DEBIAN_FRONTEND=noninteractive

# Add vscode user with same UID and GID as your host system
# (copied from https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user#_creating-a-nonroot-user)
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME
# Switch from root to user
USER $USERNAME

# Change directory to user home
WORKDIR /home/$USERNAME

# Install Webots
# We install keyboard-configuration first, with DEBIAN_FRONTEND disabled because installing keyboard-configuration can lock up the docker build
RUN sudo -E apt install -y wget software-properties-common
RUN wget -qO- https://cyberbotics.com/Cyberbotics.asc | sudo apt-key add -
RUN sudo apt-add-repository 'deb https://cyberbotics.com/debian/ binary-amd64/'
RUN sudo apt update
RUN sudo -E apt install webots -y

# Clone WebotsLolaController
RUN git clone https://github.com/Bembelbots/WebotsLoLaController.git

# Install SimSpark (https://gitlab.com/robocup-sim/SimSpark/-/wikis/Installation-on-Linux#build-from-source)
RUN sudo -E apt install -y g++ git make cmake libfreetype6-dev libode-dev libsdl1.2-dev ruby ruby-dev libdevil-dev libboost-dev libboost-thread-dev libboost-regex-dev libboost-system-dev qtbase5-dev qtchooser qt5-qmake
RUN git clone https://gitlab.com/robocup-sim/SimSpark.git
RUN cd SimSpark/spark && mkdir build && cd build && cmake .. && make && sudo make install && sudo ldconfig
RUN cd SimSpark/rcssserver3d && mkdir build && cd build && cmake .. && make && sudo make install && sudo ldconfig
RUN echo -e '/usr/local/lib/simspark\n/usr/local/lib/rcssserver3d' | sudo tee /etc/ld.so.conf.d/spark.conf && sudo ldconfig

# Install SPL GameController
RUN sudo -E apt install -y ant openjdk-11-jdk
RUN git clone https://github.com/RoboCup-SPL/GameController.git
RUN cd GameController && ant

# Source Install Gazebo Garden (https://gazebosim.org/docs/garden/install_ubuntu_src)
RUN sudo apt install -y python3-pip wget lsb-release gnupg curl && \
    sudo sh -c 'echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros2-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | sudo apt-key add - && \
    sudo apt-get update && \
    sudo apt-get install -y python3-vcstool python3-colcon-common-extensions && \
    mkdir -p ~/gazebo_garden_ws/src && \
    cd ~/gazebo_garden_ws/src && \
    wget https://raw.githubusercontent.com/gazebo-tooling/gazebodistro/master/collection-garden.yaml && \
    vcs import < collection-garden.yaml && \
    sudo wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null && \
    sudo apt-get update && \
    sudo apt -y install $(sort -u $(find . -iname 'packages-'`lsb_release -cs`'.apt' -o -iname 'packages.apt' | grep -v '/\.git/') | sed '/gz\|sdf/d' | tr '\n' ' ') && \
    cd ~/gazebo_garden_ws/ && \
    colcon build --merge-install && \
    echo "source ~/gazebo_garden_ws/install/setup.bash" >> ~/.bashrc

# Rosdep update
RUN rosdep update

# Source the ROS setup file
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc

# Create workspace and change directory into it
RUN mkdir ws
WORKDIR /home/$USERNAME/ws

# Copy the cloned repositories into container
COPY --chown=$USERNAME:$USERNAME src src/.

# Install dependencies ("|| true" is required to prevent a failure return code that happens if rosdep couldn't find some binary dependencies)
RUN rosdep install -y --from-paths src --ignore-src --rosdistro rolling -r || true

# Copy the colcon defaults file
COPY --chown=$USERNAME:$USERNAME colcon/defaults.yaml /home/$USERNAME/.colcon/defaults.yaml

# Set some ROS 2 logging env variables in ~/.bashrc
RUN echo 'export RCUTILS_CONSOLE_OUTPUT_FORMAT="[{severity}] {file_name}:{line_number} - {message}"' >> ~/.bashrc
RUN echo 'export RCUTILS_COLORIZED_OUTPUT=1' >> ~/.bashrc
