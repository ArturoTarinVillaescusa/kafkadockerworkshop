#!/bin/bash

iniciarmirrormaker () {
    echo """

    Iniciando MirrorMaker ...

    Creamos el tópico "topicmirrormakerdcb" en el Datacenter dc1 ...

    """

    docker exec -it dc1_kafka-1_1 kafka-topics --create \
        --topic topicmirrormakerdcb --replication-factor 3 --partitions 3 \
        --zookeeper dc1_zookeeper-1_1:2181,dc1_zookeeper-2_1:2181,dc1_zookeeper-3_1:2181

    echo
    docker exec -it dc1_kafka-2_1 kafka-topics --describe \
        --topic topicmirrormakerdcb \
        --zookeeper dc1_zookeeper-1_1:2181,dc1_zookeeper-2_1:2181,dc1_zookeeper-3_1:2181

    echo """

    Creamos el tópico "topicmirrormakerdcb" en el Datacenter dc2 ...

    """

    docker exec -it dc2_kafka-1_1 kafka-topics --create \
        --topic topicmirrormakerdcb --replication-factor 3 --partitions 3 \
        --zookeeper dc2_zookeeper-1_1:2181,dc2_zookeeper-2_1:2181,dc2_zookeeper-3_1:2181

    echo
    docker exec -it dc2_kafka-3_1 kafka-topics --describe \
        --topic topicmirrormakerdcb \
        --zookeeper dc2_zookeeper-1_1:2181,dc2_zookeeper-2_1:2181,dc2_zookeeper-3_1:2181

    docker cp config/consumerdatacenterb.properties dc2_kafka-1_1:/etc/kafka
    docker cp config/producerdatacenterb.properties dc2_kafka-1_1:/etc/kafka

    echo """
        MirrorMaker ha sido arrancado en Datacenter dc2 ...

        Puedes verificar el funcionamiento de la réplica de mensajes entre datacenter
        abriendo dos nuevos terminales y lanzando en uno de ellos el comando

        $ ./mirrormaker.sh consumir dc1

        y en el otro

        $ ./mirrormaker.sh consumir dc2

        PULSA Ctrl+C para terminar MirrorMaker
    """

    docker exec -it dc2_kafka-1_1 \
              bash -c 'export KAFKA_HEAP_OPTS="-Xmx1024M -Xms1024M -XX:+HeapDumpOnOutOfMemoryError";
              kafka-mirror-maker \
              --consumer.config /etc/kafka/consumerdatacenterb.properties  \
              --producer.config /etc/kafka/producerdatacenterb.properties \
              --whitelist="topicmirrormakerdcb"'
}

producir () {
    if [ -z "$2" ]
      then
        echo """

           Falta indicar cuantos mensajes hay que producir

        """
        ayuda
        exit 0
    fi

    nummensajes=$(($2))

    echo "Produciendo $nummensajes mensajes en el tópico \"topicmirrormakerdcb\" del datacenter dc1 ..."

    echo
    case $1 in
      "ConClave") docker exec -it dc1_kafka-1_1 \
                    bash -c 'rm /tmp/mensajes.txt;for i in $(seq '$nummensajes'); \
                             do echo $(($i % 10)):$i >> /tmp/mensajes.txt; done';
                  docker exec -it dc1_kafka-1_1 \
                   bash -c 'cat /tmp/mensajes.txt | \
                   kafka-console-producer \
                   --request-required-acks 1 \
                   --property "parse.key=true" --property "key.separator=:" \
                   --broker-list dc1_kafka-1_1:9092,dc1_kafka-2_1:9092,dc1_kafka-3_1:9092 \
                   --topic topicmirrormakerdcb'; ;;
      "SinClave") docker exec -it dc1_kafka-1_1 \
                       bash -c "seq '$nummensajes' | kafka-console-producer \
                       --broker-list dc1_kafka-1_1:9092,dc1_kafka-2_1:9092,dc1_kafka-3_1:9092 \
                       --topic topicmirrormakerdcb && echo '$nummensajes' mensajes producidos."; ;;
      *) ayuda; ;;
    esac

}

consumir () {
    echo "Consumiendo los mensajes enviados al tópico \"topicmirrormakerdcb\" del Datacenter $1 ..."
    bash -c "docker exec -it $1_kafka-1_1 \
                                                    kafka-console-consumer \
                                                    --property 'print.timestamp=true' \
                                                    --property 'print.key=true' \
                                                    --property 'print.offset=true' \
                                                    --bootstrap-server dc1_kafka-1_1:9092,dc1_kafka-2_1:9092,dc1_kafka-3_1:9092 \
                                                    --topic topicmirrormakerdcb"
}

ayuda () {
    echo """
   Forma de uso:

   Arrancar MirrorMaker desde una ventana con el comando

   $ ./mirrormaker.sh iniciarmirrormaker

   A continuación, abrir otra ventana y producir mensajes en el tópico "topicmirrormakerdcb" del datacenter principal usando el comando

   $ ./mirrormaker.sh producir SinClave <nummensajes>
   o
   $ ./mirrormaker.sh producir ConClave <nummensajes>

   Abrir otra ventana más y consumir los mensajes replicados al tópico "topicmirrormakerdcb" del datacenter secundario usando el comando

   $ ./mirrormaker.sh consumir dc1
   o
   $ ./mirrormaker.sh consumir dc2

    """
 }



case $1 in
  "iniciarmirrormaker") iniciarmirrormaker; ;;
  "producir")  if [ $2 == "SinClave" ] || [ $2 == "ConClave" ]  ; then
                    producir $2 $3
               else
                 echo """

                 ERROR: falta indicar con el segundo parámetro si se está produciendo con clave o sin clave

                 """
                 ayuda
               fi; ;;
  "consumir")  if [ $2 == "dc1" ] || [ $2 == "dc2" ]  ; then
                    consumir $2
               else
                 echo """

                 ERROR: falta indicar con el segundo parámetro si se está consumiendo de dc1 o de dc2

                 """
                 ayuda
               fi; ;;
  *) ayuda; ;;
esac
