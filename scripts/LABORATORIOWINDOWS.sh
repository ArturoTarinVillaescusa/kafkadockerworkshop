#!/bin/bash

verificarparametros () {

    echo
    if [ -z "$INDICE_REPLICACION_DATACENTER" ]; then
            echo "Falta indicar el número de réplicas que vamos a crear del datacenter $TIPO_DATACENTER"
    fi

    if [ -z "$CP_VERSION" ]; then
            echo "Falta indicar la versión de Confluent"
    fi

    if [ -z "$ZOOKEEPER_PORT" ]; then
            echo "Falta indicar el puerto de Zookeeper"
    fi

    if [ -z "$BROKER_PORT" ]; then
            echo "Falta indicar el puerto de Kafka Broker"
    fi

    if [ -z "$CP_VERSION" ] || [ -z "$ZOOKEEPER_PORT" ] || [ -z "$BROKER_PORT" ]; then
            echo
            ayuda
            exit 0
    fi

}

iniciarcontenedores () {
    # Creamos una red común a todos los datacenter
    docker network create $RED

    # Creamos el datacenter principal
    export DATACENTER=dc1
    docker-compose -p $DATACENTER -f $DOCKER_COMPOSE_ZK_KAFKA -f $DOCKER_COMPOSE_SCHEMA_REGISTRY \
     -f $DOCKER_COMPOSE_KAFKA_CONNECT -f $DOCKER_COMPOSE_KAFKA_REST up -d --remove-orphans

    # Creamos los datacenter de réplica
    for i in $(seq 2 $INDICE_REPLICACION_DATACENTER); do
        export REST_BINDING_PORT_1=$((REST_BINDING_PORT_1 + 3))
        export REST_BINDING_PORT_2=$((REST_BINDING_PORT_1 + 1))
        export REST_BINDING_PORT_3=$((REST_BINDING_PORT_2 + 1))
        export REGISTRY_BINDING_PORT_1=$((REGISTRY_BINDING_PORT_1 + 3))
        export REGISTRY_BINDING_PORT_2=$((REGISTRY_BINDING_PORT_1 + 1))
        export REGISTRY_BINDING_PORT_3=$((REGISTRY_BINDING_PORT_2 + 1))
        export CONNECT_BINDING_PORT_1=$((CONNECT_BINDING_PORT_1 + 3))
        export CONNECT_BINDING_PORT_2=$((CONNECT_BINDING_PORT_1 + 1))
        export CONNECT_BINDING_PORT_3=$((CONNECT_BINDING_PORT_2 + 1))
        export DATACENTER=dc$i
        export BROKER_MIRROR_MAKER=dc$i\_kafka-1_1

        docker-compose -p $DATACENTER -f $DOCKER_COMPOSE_ZK_KAFKA -f $DOCKER_COMPOSE_SCHEMA_REGISTRY \
             -f $DOCKER_COMPOSE_KAFKA_CONNECT -f $DOCKER_COMPOSE_KAFKA_REST -f $DOCKER_COMPOSE_REPLICATOR \
             up -d --scale replicator-1=$NODOS_REPLICATOR --remove-orphans

        # Levamos al broker los archivos de configuración de mirror maker
        docker cp config/consumerdatacenterb.properties $BROKER_MIRROR_MAKER:/etc/kafka
        docker cp config/producerdatacenterb.properties $BROKER_MIRROR_MAKER:/etc/kafka

    done

    estadocontenedores
}

estadocontenedores () {
    for i in $(seq $INDICE_REPLICACION_DATACENTER); do
        docker-compose -p dc$i -f $DOCKER_COMPOSE_ZK_KAFKA -f $DOCKER_COMPOSE_SCHEMA_REGISTRY \
             -f $DOCKER_COMPOSE_KAFKA_CONNECT -f $DOCKER_COMPOSE_KAFKA_REST -f $DOCKER_COMPOSE_REPLICATOR ps
    done
    exit 0
}

pararcontenedores () {
    for i in `docker ps | awk '{print $1}' | grep -v CONTAINER`; do docker stop $i; done
    exit 0
}

borrarcontenedores () {
  for i in `sudo docker ps | awk '{print $1}' | grep -v CONTAINER `; do sudo docker stop $i; done
  for i in `sudo docker ps -a | awk '{print $1}' | grep -v CONTAINER `; do sudo docker rm $i; done
  echo "Contenedores borrados"
  exit 0
}

main () {
    clear

    eval $(docker-machine.exe env DCAYDCB)
    docker-machine.exe start DCAYDCB

    if [ -z $1 ]; then
      echo
      echo Forma de uso:
      echo
      echo ./LABORATORIOWINDOWS.sh iniciar
      echo
      echo ./LABORATORIOWINDOWS.sh verificar
      echo
      echo ./LABORATORIOWINDOWS.sh parar
      echo
      echo ./LABORATORIOWINDOWS.sh borrar
      echo
      exit 1
    fi

    # Leemos el archivo de configuración para exportar las variables de entorno
    export CONFIG=./config/LABORATORIO.conf
    while read LINE
    do
        [[ "$line" =~ ^#.*$ ]] && continue
        var1=$(echo $LINE | awk '{print $1}')
        var2=$(echo $LINE | awk '{print $2}')

        export $var1=$var2
    done < $CONFIG

    if [ $1 == "parar" ] ; then
      pararcontenedores
    fi

    if  [ "$1" == "borrar" ] ; then
      borrarcontenedores
    fi

    if  [ "$1" == "verificar" ] ; then
      estadocontenedores
    fi

    # Exportamos otras variables de entorno calculadas en base al valor guardado en
    # el archivo de configuración
    export ZOOKEEPER_ELECTION_PORT_1=$((ZOOKEEPER_INTERNAL_PORT_1 + 1000))
    export ZOOKEEPER_INTERNAL_PORT_2=$((ZOOKEEPER_INTERNAL_PORT_1 + 10000))
    export ZOOKEEPER_INTERNAL_PORT_3=$((ZOOKEEPER_INTERNAL_PORT_2 + 10000))
    export ZOOKEEPER_ELECTION_PORT_2=$((ZOOKEEPER_ELECTION_PORT_1 + 10000))
    export ZOOKEEPER_ELECTION_PORT_3=$((ZOOKEEPER_ELECTION_PORT_2 + 10000))
    export REST_BINDING_PORT_1=$((REST_BINDING_PORT))
    export REST_BINDING_PORT_2=$((REST_BINDING_PORT_1 + 1))
    export REST_BINDING_PORT_3=$((REST_BINDING_PORT_2 + 1))

    export REGISTRY_BINDING_PORT_1=$((REGISTRY_BINDING_PORT))
    export REGISTRY_BINDING_PORT_2=$((REGISTRY_BINDING_PORT_1 + 1))
    export REGISTRY_BINDING_PORT_3=$((REGISTRY_BINDING_PORT_2 + 1))
    export CONNECT_BINDING_PORT_1=$((CONNECT_BINDING_PORT))
    export CONNECT_BINDING_PORT_2=$((CONNECT_BINDING_PORT_1 + 1))
    export CONNECT_BINDING_PORT_3=$((CONNECT_BINDING_PORT_2 + 1))

    verificarparametros

    iniciarcontenedores

}

main $1