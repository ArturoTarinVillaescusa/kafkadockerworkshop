# Pasos para preparar el laboratorio en un PC con Windows 7, instalando el software necesario

 En este apartado cubrimos únicamente la instalación de Docker Quickstart Tools en Windows 7. Para Windows 8 en adelante
 se recomienda usar la instalación de Docker For Windows en lugar de Docker QuickStart Tools.

 - Instalar Git en nuestro pc siguiendo la [guía de instalación](https://git-scm.com/), y configurar la herramienta con las
 credenciales proporcionadas por el equipo de arquitectura.

 - [instalar VirtualBox](http://www.virtualbox.org/) en un portátil con Windows:

    1) [Descargar el instalador](http://download.virtualbox.org/virtualbox/5.2.0/VirtualBox-5.2.0-118431-Win.exe),
    arrancarlo y seguir los pasos que indica

    2) Descargar el [extension pack](http://download.virtualbox.org/virtualbox/5.2.0/Oracle_VM_VirtualBox_Extension_Pack-5.2.0-118431.vbox-extpack)
    y abrirlo con VirtualBox

    3) Si tenemos Windows 8 o Windows 10, hemos de desactivar Hiper-V:

    ![alt text](imagenes/desactivar-hiper-v.png "Desactivar Hiper-V")

 - instalar Docker para Windows:

    1) [Instalar Docker Toolbox](https://download.docker.com/win/stable/DockerToolbox.exe)

    ![alt text](imagenes/instalar-docker-toolbox.png "Instalar docker toolbox")

 - Una vez instalada la infraestructura necesaria, procedemos a crear una máquina virtual de VirtualBox siguiendo estos pasos:

    1) Lanzamos Docker Quickstart:

    ![alt text](imagenes/docker-quickstart.png "Lanzar Docker Quickstart")

    2) Desde la ventana de Docker Quickstart, recreamos la máquina default:

    ![alt text](imagenes/recrear-docker-default.png "Borrar docker default")

    A continuación creamos una máquina para nuestro laboratorio de Kafka:

        $ docker-machine create --driver virtualbox --virtualbox-memory 8000 DCAYDCB
        Running pre-create checks...
        Creating machine...
        (DCAYDCB) Copying C:\Users\atarinvi\.docker\machine\cache\boot2docker.iso to C:\Users\atarinvi\.docker\machine\machines\DCAYDCB\boot2docker.iso...
        (DCAYDCB) Creating VirtualBox VM...
        (DCAYDCB) Creating SSH key...
        (DCAYDCB) Starting the VM...
        (DCAYDCB) Check network to re-create if needed...
        (DCAYDCB) Waiting for an IP...
        Waiting for machine to be running, this may take a few minutes...
        Detecting operating system of created instance...
        Waiting for SSH to be available...
        Detecting the provisioner...
        Provisioning with boot2docker...
        Copying certs to the local machine directory...
        Copying certs to the remote machine...
        Setting Docker configuration on the remote daemon...
        Checking connection to Docker...
        Docker is up and running!
        To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: C:\Program Files\Docker\Docker\Resources\bin\docker-machine.exe env DCAYDCB

    Esta solución presenta las siguientes ventajas:

    * Consume menos recursos
    * Los contenedores pueden verse entre ellos sin necesidad de configurar las redes desde VirtualBox

    Podemos verificar el estado de las máquinas con este comando:


        $ docker-machine.exe ls
        NAME      ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
        DCAYDCB   -        virtualbox   Running   tcp://192.168.99.101:2376           v17.10.0-ce
        default   *        virtualbox   Running   tcp://192.168.99.100:2376           v17.10.0-ce

    Para nuestro trabajo podemos apagar la máquina "default"

        $ docker-machine.exe stop default
        Stopping "default"...
        Machine "default" was stopped.

        $ docker-machine.exe ls
        NAME      ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER        ERRORS
        DCAYDCB   -        virtualbox   Running   tcp://192.168.99.101:2376           v17.10.0-ce
        default   -        virtualbox   Stopped                                       Unknown


  ***Arranque de entornos Windows donde está instalado Docker QuickStart***

  Alternativamente podemos usar Docker Quickstart para crearla, aquí mostramos los pasos para tener el entorno instalado.

  1) Abrir una ventana de Docker Quickstart, apagamos la máquina "default"
     y arrancamos la máquina virtual que estamos usando para el laboratorio, DCAYDCB:

 ![alt text](imagenes/preparar-laboratorio.png "Preparar laboratorio")


  2) Cargamos el entorno para interactuar con el laboratorio:

            $ eval $(docker-machine.exe env DCAYDCB)

  4) Cambiar a la carpeta "docker/windows" del repositorio Git "Workshop" y arrancar. En Windows tarda 10 minutos:

 ![alt text](imagenes/preparar-laboratorio.png "Preparar laboratorio")

            $ cd ~/scripts
            $ ./LABORATORIOWINDOWS.sh iniciar


  - ***Parada de entornos Windows***

  1) Cambiar a la carpeta "scripts" y parar:

            $ cd ~/scripts
            $ ./LABORATORIOWINDOWS.sh parar