FROM osrf/ros:rolling-desktop-full

# Prevent apt install from asking questions during build process
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

# Install SimSpark (https://gitlab.com/robocup-sim/SimSpark/-/wikis/Installation-on-Linux#build-from-source)
RUN sudo apt install -y g++ git make cmake libfreetype6-dev libode-dev libsdl1.2-dev ruby ruby-dev libdevil-dev libboost-dev libboost-thread-dev libboost-regex-dev libboost-system-dev qtbase5-dev qtchooser qt5-qmake
RUN git clone https://gitlab.com/robocup-sim/SimSpark.git
RUN cd SimSpark/spark && mkdir build && cd build && cmake .. && make && sudo make install && sudo ldconfig
RUN cd SimSpark/rcssserver3d && mkdir build && cd build && cmake .. && make && sudo make install && sudo ldconfig
RUN echo -e '/usr/local/lib/simspark\n/usr/local/lib/rcssserver3d' | sudo tee /etc/ld.so.conf.d/spark.conf && sudo ldconfig

# Install Webots
RUN sudo apt install -y wget software-properties-common
RUN wget -qO- https://cyberbotics.com/Cyberbotics.asc | sudo apt-key add -
RUN sudo apt-add-repository 'deb https://cyberbotics.com/debian/ binary-amd64/'
RUN sudo apt update
RUN sudo apt install webots -y

# Clone WebotsLolaController
RUN git clone https://github.com/Bembelbots/WebotsLoLaController.git

# Install SPL GameController
RUN sudo apt install -y ant openjdk-11-jdk
RUN git clone https://github.com/RoboCup-SPL/GameController.git
RUN cd GameController && ant

# Rosdep update
RUN rosdep update

# Source the ROS setup file
RUN echo "source /opt/ros/${ROS_DISTRO}/setup.bash" >> ~/.bashrc

# Create workspace and change directory into it
RUN mkdir ws
WORKDIR /home/$USERNAME/ws

# Copy the cloned repositories into container
ARG SRC_DIR="src"
COPY $SRC_DIR src/.
COPY src.repos .

# Install dependencies ("|| true" is required to prevent a failure return code that happens if rosdep couldn't find some binary dependencies)
RUN rosdep install -y --from-paths src --ignore-src --rosdistro rolling -r || true
