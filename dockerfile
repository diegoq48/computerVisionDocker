# Build arguments  


# Specify the parent image from which we build
# Using image provided from steroLab devel verison for testing purposes 
# Should be changed to runtime for final build 
FROM stereolabs/zed:3.7-devel-jetson-jp4.6

# OpenCV Version 
ARG OPENCV_VERSION=4.x

## Copys buildtime libs from host into docker image
RUN rm -rf /usr/local/cuda-10.2/targets/aarch64-linux/lib/*
COPY lib64/* /usr/local/cuda-10.2/targets/aarch64-linux/lib/

# Install dependencies
RUN apt-get update || true && apt-get upgrade -y &&\
    # Install build tools, build dependencies and python
	apt-get install --no-install-recommends -y \
	build-essential gcc g++ \
	cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev \
	libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev \
	yasm libatlas-base-dev gfortran libpq-dev \
	libxine2-dev libglew-dev libtiff5-dev zlib1g-dev libavutil-dev libpostproc-dev \ 
	libeigen3-dev python3-dev python3-pip python3-numpy libx11-dev tzdata \
	&& rm -rf /var/lib/apt/lists/*

##Pulled from zed sdk website to install opencv 
# Set Working directory
WORKDIR /opt
# Install OpenCV from Source
RUN git clone --depth 1 --branch ${OPENCV_VERSION} https://github.com/opencv/opencv.git && \
    git clone --depth 1 --branch ${OPENCV_VERSION} https://github.com/opencv/opencv_contrib.git && \
    cd opencv && \
    mkdir build && \
    cd build && \
    cmake \
	-D CMAKE_BUILD_TYPE=RELEASE \
	-D CMAKE_INSTALL_PREFIX=/usr/ \
	-D PYTHON3_PACKAGES_PATH=/usr/lib/python3/dist-packages \
	-D WITH_V4L=ON \
	-D WITH_QT=OFF \
	-D WITH_OPENGL=ON \
	-D WITH_GSTREAMER=ON \
	-D OPENCV_GENERATE_PKGCONFIG=ON \
	-D OPENCV_ENABLE_NONFREE=ON \
	-D OPENCV_EXTRA_MODULES_PATH=/opt/opencv_contrib/modules \
	-D INSTALL_PYTHON_EXAMPLES=OFF \
	-D INSTALL_C_EXAMPLES=OFF \
	-D BUILD_EXAMPLES=OFF .. && \
   make -j"$(nproc)" && \
   make install



#WORKDIR /

# CMD ["bash"]

#Installs yaml-cpp by building from source in /opt Dir

WORKDIR /opt 

RUN echo "Installing yaml-cpp"

RUN git clone https://github.com/jbeder/yaml-cpp.git && \
    cd yaml-cpp && \
    mkdir build && \
    cd build && \
    cmake -DBUILD_SHARED_LIBS=ON .. && \
    make -j4 &&\
    make install &&\
    ldconfig

## Installs Ros noetic 
# setup timezone
WORKDIR /opt 
RUN apt install -q -y --no-install-recommends tzdata
# install packages
RUN apt update 
RUN apt-get install -q -y --no-install-recommends \
    dirmngr \ 
    gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# setup sources.list
RUN echo "deb http://packages.ros.org/ros/ubuntu bionic main" > /etc/apt/sources.list.d/ros1-latest.list

# setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

ENV ROS_DISTRO melodic

#install ros packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-melodic-ros-core=1.4.1-0* \
    && rm -rf /var/lib/apt/lists/*

# setup entrypoint
RUN rm -rf /ros_entrypoint.sh
COPY ./ros_entrypoint.sh /
RUN chmod +x /ros_entrypoint.sh

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
WORKDIR /opt

RUN echo "Installing Vision Module"
RUN git clone https://github.com/stereolabs/zed-ros-wrapper.git 

