#!/bin/sh
while :
do
   for i in `docker ps | awk '{print $11}' | grep -v CONTAINER | grep datacenter`; do
    echo
    echo Paramos el nodo $i en el instante $(date)
    docker stop $i
    echo
    docker-compose up -d --remove-orphans
    ../../scripts/registrar.sh
    sleep 300
    ../../scripts/registrar.sh
  done
done

do
   for i in `docker ps | awk '{print $12}' | grep -v CONTAINER | grep datacenter`; do
    echo
    echo Paramos el nodo $i en el instante $(date)
    docker stop $i
    echo
    docker-compose up -d --remove-orphans
    ../../scripts/registrar.sh
    sleep 300
    ../../scripts/registrar.sh
  done
done

