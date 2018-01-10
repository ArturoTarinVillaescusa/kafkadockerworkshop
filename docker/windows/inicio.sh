#!/bin/sh
echo Cargamos las variables de entorno ...
eval $(docker-machine.exe env DCAYDCB)
echo Arrancamos la máquina virtual en VirtualBox...
docker-machine start DCAYDCB
date
docker-compose -f docker-compose.yml up -d --remove-orphans
echo Iniciando DCA ...
sleep 400
date
docker-compose -f docker-compose-1.yml up -d --remove-orphans
echo Iniciando Zookeeper en DCB ...
sleep 200
date
docker-compose -f docker-compose-2.yml up -d --remove-orphans
echo Iniciando Kafka brokers en DCB ...
sleep 400
date
docker-compose -f docker-compose-3.yml up -d --remove-orphans
echo Iniciando el resto de componentes de DCB ...
