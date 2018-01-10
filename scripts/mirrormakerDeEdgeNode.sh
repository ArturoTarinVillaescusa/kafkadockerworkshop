#!/bin/bash

iniciarmirrormaker () {
    echo "Iniciando MirrorMaker ..."

    echo
    echo Creamos el tópico "topicmirrormakerdcb" en el Datacenter A ...

    kafka-topics.sh --create \
        --topic topicmirrormakerdcb --replication-factor 3 --partitions 3 \
        --zookeeper dc1_zookeeper-1_1:2181,dc1_zookeeper-2_1:2181,dc1_zookeeper-3_1:2181

    echo
    kafka-topics.sh --describe \
        --topic topicmirrormakerdcb \
        --zookeeper dc1_zookeeper-1_1:2181,dc1_zookeeper-2_1:2181,dc1_zookeeper-3_1:2181

    echo
    echo Creamos el tópico "topicmirrormakerdcb" en el Datacenter B ...

    echo
    kafka-topics.sh --create \
        --topic topicmirrormakerdcb --replication-factor 3 --partitions 3 \
        --zookeeper dc2_zookeeper-1_1:2181,dc2_zookeeper-2_1:2181,dc2_zookeeper-3_1:2181

    echo
    kafka-topics.sh --describe \
        --topic topicmirrormakerdcb \
        --zookeeper dc2_zookeeper-1_1:2181,dc2_zookeeper-2_1:2181,dc2_zookeeper-3_1:2181

    echo
    echo MirrorMaker ha sido arrancado en Datacenter B ...
    echo
    echo Puedes verificar el funcionamiento de la réplica de mensajes entre datacenter
    echo abriendo dos nuevos terminales y lanzando en uno de ellos el comando
    echo
    echo $ ./mirrormaker.sh consumirDCA
    echo
    echo y en el otro
    echo
    echo $ ./mirrormaker.sh consumirDCB
    echo
    echo PULSA Ctrl+C para terminar MirrorMaker
    echo
    \
          kafka-run-class.sh kafka.tools.MirrorMaker \
          --consumer.config /consumerdatacenterb.properties  \
          --producer.config /producerdatacenterb.properties \
          --whitelist="topicmirrormakerdcb"
}

producirSinClave () {
    if [ -z "$1" ]
      then
        echo
        echo "Falta indicar cuantos mensajes hay que producir"
        echo
        ayuda
        exit 0
    fi

    nummensajes=$(($1))

    echo "Produciendo $nummensajes mensajes sin clave en el tópico \"topicmirrormakerdcb\" del datacenter A ..."

    \
                                          bash -c "seq '$nummensajes' | kafka-console-producer.sh \
                                          --broker-list dc1_kafka-1_1:9092,dc1_kafka-2_1:9092,dc1_kafka-3_1:9092 \
                                          --topic topicmirrormakerdcb && echo '$nummensajes' mensajes producidos."
}

producirConClave () {
    if [ -z "$1" ]
      then
        echo
        echo "Falta indicar cuantos mensajes hay que producir"
        echo
        ayuda
        exit 0
    fi

    nummensajes=$(($1))

    echo "Produciendo $nummensajes mensajes con clave en el tópico \"topicmirrormakerdcb\" del datacenter A ..."

    echo
    \
       bash -c 'rm /tmp/mensajes.txt;for i in $(seq '$nummensajes'); do echo $(($i % 10)):$i >> /tmp/mensajes.txt; done'

    \
       bash -c 'cat /tmp/mensajes.txt | \
       kafka-console-producer.sh \
       --request-required-acks 1 \
       --property "parse.key=true" --property "key.separator=:" \
       --broker-list dc1_kafka-1_1:9092,dc1_kafka-2_1:9092,dc1_kafka-3_1:9092 \
       --topic topicmirrormakerdcb'
    echo
}

consumirDCA () {
    echo "Consumiendo los mensajes enviados al tópico \"topicmirrormakerdcb\" del Datacenter A ..."
    kafka-console-consumer.sh \
        --property "print.timestamp=true" \
        --property "print.key=true" \
        --property "print.offset=true" \
        --bootstrap-server dc1_kafka-1_1:9092,dc1_kafka-2_1:9092,dc1_kafka-3_1:9092 \
        --topic topicmirrormakerdcb
}

consumirDCB () {
    echo "Consumiendo los mensajes replicados por MirrorMaker al tópico \"topicmirrormakerdcb\" del Datacenter B ..."
    kafka-console-consumer.sh \
        --property "print.timestamp=true" \
        --property "print.key=true" \
        --property "print.offset=true" \
        --bootstrap-server dc2_kafka-1_1:9092,dc2_kafka-2_1:9092,dc2_kafka-3_1:9092 \
        --topic topicmirrormakerdcb
}

ayuda () {
    echo
    echo "Forma de uso:"
    echo
    echo "Arrancar MirrorMaker desde una ventana con el comando"
    echo
    echo $ sudo ./mirrormaker.sh iniciarmirrormaker
    echo
    echo A continuación, abrir otra ventana y producir mensajes en el tópico \"topicmirrormakerdcb\" del datacenter A usando el comando
    echo
    echo "$ sudo ./mirrormaker.sh producirSinClave <nummensajes>"
    echo o
    echo "$ sudo ./mirrormaker.sh producirConClave <nummensajes>"
    echo
    echo Abrir otra ventana más y consumir los mensajes replicados al tópico \"topicmirrormakerdcb\" del datacenter B usando el comando
    echo
    echo $ sudo ./mirrormaker.sh consumirDCA
    echo o
    echo $ sudo ./mirrormaker.sh consumirDCB
    echo
 }



case $1 in
  "iniciarmirrormaker") iniciarmirrormaker; ;;
  "producirSinClave") producirSinClave $2; ;;
  "producirConClave") producirConClave $2; ;;
  "consumirDCA") consumirDCA; ;;
  "consumirDCB") consumirDCB; ;;
  *) ayuda; ;;
esac