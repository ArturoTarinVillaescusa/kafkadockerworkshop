#!/bin/bash

instanciarjmeter () {
    export INSTANTE=`date '+%Y-%m-%d_%H.%M.%S'`

    nohup jmeter  \
             -JSERVIDOR=$HOST -JPUERTO=$PUERTO -JBROKER=$BROKER -JHILOS=$NUMHILOS -JINSTANTE=$INSTANTE \
             -JMETRONOMO=$METRONOMO -JDURACION=$DURACION -JPERIODOSUBIDA=$PERIODOSUBIDA -JBUCLE=$BUCLE -t $JMX &
}

iniciaVariables () {

    if [ "$1" == "LINEA_BASE_PRODUCTOR_ONLINE" ] || [ "$1" == "LINEA_BASE_PRODUCTOR_BULK_ONLINE" ] ||
       [ "$1" == "LINEA_BASE_PRODUCTOR_BULK_CONNECT" ] || [ "$1" == "LINEA_BASE_CONSUMIDOR_ONLINE" ] ||
       [ "$1" == "PRODUCTOR_PICOS" ] || [ "$1" == "PRODUCTOR_INCREMENTAL" ]
    then
      source "config/$1.properties"
      export DURACION JMX NUMHILOS HOST PUERTO TIPOCARGA PERIODOSUBIDA BUCLE PERIODOVARIACION
    else
      ayuda
    fi

    echo DURACION vale $DURACION
    echo METRONOMO vale $METRONOMO
    echo JMX vale $JMX
    echo NUMHILOS vale $NUMHILOS
    echo HOST vale $HOST
    echo PUERTO vale $PUERTO
    echo TIPOCARGA vale $TIPOCARGA
    echo PERIODOSUBIDA vale $PERIODOSUBIDA
    echo BUCLE vale $BUCLE
    echo PERIODODEVARIACION vale $PERIODODEVARIACION

}


ayuda () {
    echo """

Lanzador de tests de JMeter
---------------------------

Forma de uso:

testJmeter.sh <TEST_A_LANZAR>

El parámetro <TEST_A_LANZAR> puede tomar uno de los siguientes valores:

LINEA_BASE_PRODUCTOR_BULK_ONLINE

Este test lanzará 1 thread envia de una vez 100 mensajes por segundo, durante 30 minutos.

LINEA_BASE_PRODUCTOR_ONLINE

Este test lanzará 100 thread concurrentes, cada uno de ellos envía 1 mensaje por segundo. La duración del test
será de 30 minutos. Con esta configuración, este test va a enviar 6.000 mensajes por minuto.

LINEA_BASE_PRODUCTOR_BULK_CONNECT

Este test lanzará 1 thread por segundo que llamará a un procedure de DB2 que escribirá 100 registros en la
base de datos de pruebas

LINEA_BASE_CONSUMIDOR_ONLINE

Este test lanzará 1 thread por segundo para leer los mensajes que hayan sido escritos en el tópico. El test
durará 30 minutos.

PRODUCTOR_PICOS

Este test inyectará cada 5 minutos 500 threads concurrentes, cada thread escribirá un mensaje. La duración del
test será de 30 minutos

PRODUCTOR_INCREMENTAL

Este test comienza con con 10 threads y cada minuto lanza 10 nuevos threads que se suman a los anteriores
    """

    exit 1
 }

main() {
    cd "${0%/*}"

    iniciaVariables "$@"

    export -f instanciarjmeter
    nohup bash -c instanciarjmeter &
}

main "$@"

