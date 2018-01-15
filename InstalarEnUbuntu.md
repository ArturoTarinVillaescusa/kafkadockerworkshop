# Steps to prepare the lab in Linux Ubuntu

 Use this alternative if your environment is an Ubuntu operating system.

 - [Install Docker on your Linux laptop](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/):

    1) Uninstall old Docker images from your laptop:

        $ sudo apt-get remove docker docker-engine docker.io

    2) Update the repository:

        $ sudo apt-get update

    3) Enable HTTPS access:

         $ sudo apt-get install \
             apt-transport-https \
             ca-certificates \
             curl \
             software-properties-common

    4) Add to your environment the official GPG Docker key:

        $ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    5) Make sure you have the 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88 digital footprint
       using this command:

        $ sudo apt-key fingerprint 0EBFCD88

    6) Add a stable repository:

        $ sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) \
          stable"

    7) Install Docker CE:

         $ sudo apt-get upgrade
         $ sudo apt-get install docker-ce

    8) Check that it works:

        $ sudo docker --version

 - [Install Docker Compose](https://docs.docker.com/compose/install/):

    1) Download Docker Compose:

        sudo curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

    2) Give execute permissions to the file:

        $ sudo chmod +x /usr/local/bin/docker-compose

    3) Check that it works:

        $ sudo docker-compose --version
