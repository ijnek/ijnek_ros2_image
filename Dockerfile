FROM osrf/ros:rolling-desktop

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

# Install SimSpark (https://gitlab.com/robocup-sim/SimSpark/-/wikis/Installation-on-Linux#build-from-source)
RUN sudo apt install -y g++ git make cmake libfreetype6-dev libode-dev libsdl1.2-dev ruby ruby-dev libdevil-dev libboost-dev libboost-thread-dev libboost-regex-dev libboost-system-dev qtbase5-dev qtchooser qt5-qmake
RUN git clone https://gitlab.com/robocup-sim/SimSpark.git
RUN cd SimSpark/spark && mkdir build && cd build && cmake .. && make && sudo make install && sudo ldconfig
RUN cd SimSpark/rcssserver3d && mkdir build && cd build && cmake .. && make && sudo make install && sudo ldconfig
RUN echo -e '/usr/local/lib/simspark\n/usr/local/lib/rcssserver3d' | sudo tee /etc/ld.so.conf.d/spark.conf && sudo ldconfig
