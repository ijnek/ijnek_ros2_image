FROM ubuntu:24.04

# Add ubuntu user with same UID and GID as your host system, if it doesn't already exist
# Since Ubuntu 24.04, a non-root user is created by default with the name vscode and UID=1000
ARG USERNAME=ubuntu
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN if ! id -u $USER_UID >/dev/null 2>&1; then \
        groupadd --gid $USER_GID $USERNAME && \
        useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME; \
    fi
# Add sudo support for the non-root user
RUN apt-get update && \
    apt-get install -y sudo && \
    echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# Switch from root to user
USER $USERNAME

# Install ROS 2 Kilted
RUN sudo apt update && sudo apt install -y locales && \
    sudo locale-gen en_US en_US.UTF-8 && \
    sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 && \
    export LANG=en_US.UTF-8 && \
    locale
RUN sudo apt install -y software-properties-common && \
    sudo add-apt-repository universe
RUN sudo apt update && sudo apt install curl -y && \
    curl -o /tmp/ros2-testing-apt-source.deb "https://ftp.osuosl.org/pub/ros/packages.ros.org/ros2-testing/ubuntu/pool/main/r/ros-apt-source/ros2-testing-apt-source_1.0.0~$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb" && \
    sudo apt install -y /tmp/ros2-testing-apt-source.deb
RUN sudo apt update && sudo apt install -y ros-dev-tools
RUN sudo apt upgrade
RUN sudo apt install -y ros-kilted-ros-base

# Update all packages
RUN sudo apt update

# Install Git
RUN sudo apt install -y git

# Source the ROS setup file
RUN echo "source /opt/ros/kilted/setup.bash" >> ~/.bashrc

################################
## ADD ANY CUSTOM SETUP BELOW ##
################################

# Disable interactive frontend
# NOTE: for this to take effect when using "sudo" apt install, we need the -E flag to preserve the environment variable inside the sudo command
ARG DEBIAN_FRONTEND=noninteractive

# Change directory to user home
WORKDIR /home/$USERNAME

# Upgrade all packages
RUN sudo apt update && sudo apt upgrade -y

# Install Webots
# We install keyboard-configuration first, with DEBIAN_FRONTEND disabled because installing keyboard-configuration can lock up the docker build
# RUN sudo -E apt install -y wget software-properties-common
# RUN wget -qO- https://cyberbotics.com/Cyberbotics.asc | sudo apt-key add -
# RUN sudo apt-add-repository 'deb https://cyberbotics.com/debian/ binary-amd64/'
# RUN sudo apt update
# RUN sudo -E apt install webots -y

# Clone WebotsLolaController
# RUN git clone https://github.com/Bembelbots/WebotsLoLaController.git

# Install SimSpark (https://gitlab.com/robocup-sim/SimSpark/-/wikis/Installation-on-Linux#build-from-source)
# RUN sudo -E apt install -y g++ git make cmake libfreetype6-dev libode-dev libsdl1.2-dev ruby ruby-dev libdevil-dev libboost-dev libboost-thread-dev libboost-regex-dev libboost-system-dev qtbase5-dev qtchooser qt5-qmake libqt5opengl5-dev
# RUN git clone https://gitlab.com/robocup-sim/SimSpark.git
# RUN cd SimSpark/spark && mkdir build && cd build && cmake .. && make && sudo make install && sudo ldconfig
# RUN cd SimSpark/rcssserver3d && mkdir build && cd build && cmake .. && make && sudo make install && sudo ldconfig
# RUN echo -e '/usr/local/lib/simspark\n/usr/local/lib/rcssserver3d' | sudo tee /etc/ld.so.conf.d/spark.conf && sudo ldconfig

# Install SPL GameController
# RUN sudo -E apt install -y ant openjdk-11-jdk && \
#     git clone https://github.com/RoboCup-SPL/GameController.git && \
#     cd GameController && ant

# # Install SPL GameController3
# RUN sudo -E apt install -y libwebkit2gtk-4.1-dev build-essential curl wget file libssl-dev libgtk-3-dev libayatana-appindicator3-dev librsvg2-dev && \
#     curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh -s -- -y && \
#     curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - && \
#     sudo -E apt install -y nodejs && \
#     sudo -E apt install -y libclang-dev && \
#     git clone https://github.com/RoboCup-SPL/GameController3.git && \
#     cd GameController3/frontend && \
#     npm ci && \
#     npm run build && \
#     cd .. && \
#     . $HOME/.cargo/env && \
#     cargo build

# Install Gazebo Harmonic (https://gazebosim.org/docs/harmonic/install_ubuntu)
# RUN sudo apt update && \
#     sudo apt install -y lsb-release wget gnupg && \
#     sudo wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg && \
#     echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list > /dev/null && \
#     sudo apt update && \
#     sudo apt install gz-harmonic

# Install jstest-gtk (to test xbox controller)
# RUN sudo apt install -y jstest-gtk

# Rosdep update
# RUN rosdep update

# Source the ROS setup file
RUN echo "source /opt/ros/kilted/setup.bash" >> ~/.bashrc

# Create workspace and change directory into it
# RUN mkdir ws
# WORKDIR /home/$USERNAME/ws

# Copy the cloned repositories into container
# COPY --chown=$USERNAME:$USERNAME src src/.

# Install dependencies ("|| true" is required to prevent a failure return code that happens if rosdep couldn't find some binary dependencies)
# RUN rosdep install -y --from-paths src --ignore-src --rosdistro kilted -r || true

# Copy the colcon defaults file
COPY --chown=$USERNAME:$USERNAME colcon/defaults.yaml /home/$USERNAME/.colcon/defaults.yaml

# Set some ROS 2 logging env variables in ~/.bashrc
RUN echo 'export RCUTILS_CONSOLE_OUTPUT_FORMAT="[{severity}] {file_name}:{line_number} - {message}"' >> ~/.bashrc
RUN echo 'export RCUTILS_COLORIZED_OUTPUT=1' >> ~/.bashrc

# Set alias for GameController3
# RUN echo 'alias gc3="~/GameController3/target/debug/game_controller_app"' >> ~/.bashrc

# Install dependencies required to make ROS 2 releases (https://docs.ros.org/en/iron/How-To-Guides/Releasing/First-Time-Release.html#install-dependencies)
RUN sudo apt install -y python3-bloom python3-catkin-pkg

# Install bash completion
RUN sudo apt install -y bash-completion
