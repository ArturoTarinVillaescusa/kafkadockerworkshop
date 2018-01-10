# Pasos para preparar el laboratorio en Linux Ubuntu

 Usa esta alternativa si tu entorno es un sistema operativo Ubuntu.

 - Secuencia de comandos para [instalar Docker](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/) en un portátil con Linux:

     1) Desinstalamos imágenes antiguas de Docker:

        $ sudo apt-get remove docker docker-engine docker.io

    2) Actualizamos el repositorio:

        $ sudo apt-get update

    3) Habilitamos el acceso HTTPS:

         $ sudo apt-get install \
             apt-transport-https \
             ca-certificates \
             curl \
             software-properties-common

    4) Añadimos a nuestro entorno la clave oficial GPG de Docker:

        $ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    5) Nos aseguramos de que disponemos de la huella digital 9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88 con
    el siguiente comando:

        $ sudo apt-key fingerprint 0EBFCD88

    6) Configuramos un repositorio estable:

        $ sudo add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) \
          stable"

    7) Instalamos Docker CE:

         $ sudo apt-get upgrade
         $ sudo apt-get install docker-ce

    8) Verificar que funciona:

        $ sudo docker --version

 - [instalar Docker Compose](https://docs.docker.com/compose/install/) en Linux:

    1) Descargar Docker Compose:

        sudo curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

    2) Darle permisos de ejecución:

        $ sudo chmod +x /usr/local/bin/docker-compose

    3) Verificar que funciona:

        $ sudo docker-compose --version
