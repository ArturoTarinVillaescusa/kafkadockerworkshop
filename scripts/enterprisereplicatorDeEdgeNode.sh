#!/bin/bash

iniciarenterprisereplicator () {
    echo Creamos el tópico \"topicoreplicador\" en el Datacenter A ...

    kafka-topics.sh --create \
        --topic topicoreplicador --replication-factor 3 --partitions 3 \
        --zookeeper dc1_zookeeper-1_1:2181,dc1_zookeeper-2_1:2181,dc1_zookeeper-3_1:2181


    kafka-topics.sh --describe \
        --topic topicoreplicador \
        --zookeeper dc1_zookeeper-1_1:2181,dc1_zookeeper-2_1:2181,dc1_zookeeper-3_1:2181

    echo
    echo Tópicos que tenemos en Datacenter A antes de crear el Connector Replicator ...

    kafka-topics.sh --list \
    --zookeeper dc1_zookeeper-1_1:2181,dc1_zookeeper-2_1:2181,dc1_zookeeper-3_1:2181

    echo
    echo Tópicos que tenemos en Datacenter B antes de crear el Connector Replicator ...

    kafka-topics.sh --list \
    --zookeeper dc2_zookeeper-1_1:2181,dc2_zookeeper-2_1:2181,dc2_zookeeper-3_1:2181

    echo
    echo Consultamos los nombres de los conectores que existen antes de crear ninguno. Debe retornarnos una lista vacía ...

    curl -X GET \
        http://dc2_replicator_1:28082/connectors

    echo
    echo
    echo Creamos el conector \"conector-replicador\" llamando a Kafka Connect REST API. Obligamos a que se clonen las particiones \
     es decir, las particiones del tópico \"topicoreplicador\" se replicarán en contenido y orden desde el Datacenter A al Datacenter B ...

    curl -X POST \
             -H "Content-Type: application/json" \
             --data '{
                "name": "conector-replicador",
                "config": {
                  "connector.class":"io.confluent.connect.replicator.ReplicatorSourceConnector",
                  "key.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
                  "value.converter": "io.confluent.connect.replicator.util.ByteArrayConverter",
                  "src.zookeeper.connect": "dc1_zookeeper-1_1:2181",
                  "src.kafka.bootstrap.servers": "dc1_kafka-1_1:9092,dc1_kafka-2_1:9092,dc1_kafka-3_1:9092",
                  "dest.zookeeper.connect": "dc2_zookeeper-1_1:2181",
                  "topic.whitelist": "topicoreplicador",
                  "topic.preserve.partitions": true}}'  \
             http://dc2_replicator_1:28082/connectors | json_pp

    echo
    echo Comprobamos que Connector Replicator ha creado el tópico \"topicoreplicador\" en Datacenter B ...
    echo
    kafka-topics.sh --list \
    --zookeeper dc2_zookeeper-1_1:2181,dc2_zookeeper-2_1:2181,dc2_zookeeper-3_1:2181 \
    | grep topicoreplicador

    kafka-topics.sh --describe \
        --topic topicoreplicador \
        --zookeeper dc2_zookeeper-1_1:2181,dc2_zookeeper-2_1:2181,dc2_zookeeper-3_1:2181

    echo
    echo Consultamos el estado del conector  \"conector-replicador\" ...
    echo

    curl -X GET \
        http://dc2_replicator_1:28082/connectors/conector-replicador/status | json_pp

    echo
    echo Enterprise Replicator ha sido iniciado.
}

ayuda () {
    echo
    echo "Forma de uso:"
    echo
    echo "$ ./enterprisereplicator.sh iniciarenterprisereplicator"
    echo "$ ./enterprisereplicator.sh producirSinClave <nummensajes>"
    echo "$ ./enterprisereplicator.sh producirConClave <nummensajes>"
    echo "$ ./enterprisereplicator.sh consumirDCA"
    echo "$ ./enterprisereplicator.sh consumirDCB"
    echo
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

    echo "Iniciando Enterprise Replicator ..."
    iniciarenterprisereplicator
    echo
    echo Produciendo $nummensajes mensajes sin clave ...
    echo
    bash -c "seq '$nummensajes' | kafka-console-producer.sh \
      --request-required-acks 1 \
      --broker-list dc1_kafka-1_1:9092,dc1_kafka-2_1:9092,dc1_kafka-3_1:9092 \
      --topic topicoreplicador && echo $nummensajes' mensajes producidos.'"
    echo
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

# AÑADIR RETRIES, INFLIGHT
    nummensajes=$(($1))
    echo "Iniciando Enterprise Replicator ..."
    iniciarenterprisereplicator
    echo
    echo Produciendo $nummensajes mensajes con clave ...
    echo
    echo
    bash -c 'rm /tmp/mensajes.txt;for i in $(seq '$nummensajes'); do echo $(($i)):$i >> /tmp/mensajes.txt; done'

    bash -c 'cat /tmp/mensajes.txt | \
       kafka-console-producer.sh \
       --request-required-acks all \
       --property "parse.key=true" --property "key.separator=:" \
       --broker-list dc1_kafka-1_1:9092,dc1_kafka-2_1:9092,dc1_kafka-3_1:9092 \
       --topic topicoreplicador'
    echo
}

consumirDCA () {
    echo "Consumiendo los mensajes en el tópico \"topicoreplicador\" del Datacenter A ..."
    echo
    kafka-console-consumer.sh \
       --topic topicoreplicador  \
            --property "print.timestamp=true" \
            --property "print.key=true" \
            --property "print.offset=true" \
       --bootstrap-server dc1_kafka-1_1:9092,dc1_kafka-2_1:9092,dc1_kafka-3_1:9092 \
       --partition 0
       --from-beginning
}

consumirDCB () {
    echo "Consumiendo los mensajes replicados por Enterprise Replicator al tópico \"topicoreplicador\" del Datacenter B ..."
    echo
    kafka-console-consumer.sh \
      --topic topicoreplicador  \
                --property "print.timestamp=true" \
                --property "print.key=true" \
                --property "print.offset=true" \
      --bootstrap-server dc1_kafka-1_1:9092,dc1_kafka-2_1:9092,dc1_kafka-3_1:9092 \
      --partition 0
      --from-beginning
}

case $1 in
  "iniciarenterprisereplicator") iniciarenterprisereplicator; ;;
  "producirSinClave") producirSinClave $2; ;;
  "producirConClave") producirConClave $2; ;;
  "consumirDCA") consumirDCA; ;;
  "consumirDCB") consumirDCB; ;;
  *) ayuda; ;;
esac

