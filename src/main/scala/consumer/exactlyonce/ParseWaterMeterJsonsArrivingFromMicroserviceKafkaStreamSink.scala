package consumer.exactlyonce

import java.util.Properties
import java.util.logging.{Level, Logger}

import _root_.kafka.serializer.{DefaultDecoder, StringDecoder}
import org.apache.spark.SparkContext
import org.apache.spark.sql.functions._
import org.apache.spark.streaming.{Duration, Minutes, Seconds, StateSpec, StreamingContext}
import org.apache.spark.streaming.kafka.KafkaUtils
import kafka.common.TopicAndPartition
import kafka.message.MessageAndMetadata
import org.apache.spark.sql.SaveMode
import org.apache.spark.storage.StorageLevel

object ParseWaterMeterReadingsJsonsArrivingFromMicroserviceKafkaStreamSink {

  def main(args: Array[String]): Unit = {

    // Desactivamos logs de línea de comando
    Logger.getLogger("org").setLevel(Level.OFF)
    Logger.getLogger("akka").setLevel(Level.OFF)

    // setup spark context
    val sc = getSparkContext("ParseWaterMeterReadingsJsonsArrivingFromMicroserviceKafkaStreamSink")
    val sqlContext = getSQLContext(sc)

    var propsConexionPostgres: Properties = new Properties()
    propsConexionPostgres.setProperty("user", variablesAguas.usuarioPostgres)
    propsConexionPostgres.setProperty("password", variablesAguas.clavePostgres)
    propsConexionPostgres.setProperty("driver", "org.postgresql.Driver")

    val batchDuration = Seconds(variablesAguas.ventanaWaterMeterReadings)

    def streamingApp(sc: SparkContext, batchDuration: Duration) = {
      val ssc = new StreamingContext(sc, batchDuration)
      val topic = variablesAguas.topicoLecturasFromMsPrincipal

      val kafkaDirectParams = Map(
        "metadata.broker.list" -> variablesAguas.kafkaBroker,
        "group.id" -> variablesAguas.grupoConsumidoresGenericos,
        "auto.offset.reset" -> "largest"
      )

      val hdfsPath = variablesAguas.rutaLecturasHDFSParquet

      val hdfsData = sqlContext.read.parquet(hdfsPath)

      // Comprobamos si el offset ha sido almacenado previamente en HDFS
      // es decir, si los datos de Kafka han sido procesados en alguna sesión anterior de Spark
      val fromOffsets = hdfsData.groupBy("topic", "kafkaPartition")
        .agg(max("untilOffset").as("untilOffset"))
        .collect().map{ row =>
        (TopicAndPartition(row.getAs[String]("topic"),
                           row.getAs[Int]("kafkaPartition")),
                           row.getAs[String]("untilOffset").toLong + 1)
      }.toMap

      val kafkaDirectStream = fromOffsets.isEmpty match {
        // Datos no procesados anteriormente
        case true =>
          KafkaUtils.createDirectStream[String, String, StringDecoder, StringDecoder](
              ssc, kafkaDirectParams, Set(topic)
          )
        // Datos procesados anteriormente. Procesamos desde el último offset almacenado en HDFS
        case false =>
          KafkaUtils.createDirectStream[String, String, StringDecoder, StringDecoder, (String, String)](
            ssc, kafkaDirectParams, fromOffsets,
            { mmd : MessageAndMetadata[String, String] => (mmd.key(), mmd.message()) }
          )
      }

      val WaterMeterReadingsStream = kafkaDirectStream.transform(rddWaterMeterReadings => {
            transforma_json_de_ms_a_RDD_Lecturas(rddWaterMeterReadings)
          }
        )

      WaterMeterReadingsStream.foreachRDD { rdd =>
        println("Transformando lecturas provinientes de los json que el microservicio principal deposita en la cola 'lecturas' ...")

        if (!rdd.isEmpty()) {
          val lecturasDF = rdd
            .toDF()
            .selectExpr("timestamp_hour", "numero_serie",
                        "inputProps.topic as topic",
                        "inputProps.kafkaPartition as kafkaPartition",
                        "inputProps.fromOffset as fromOffset",
                        "inputProps.untilOffset as untilOffset")

          lecturasDF.createOrReplaceTempView("lecturas")

          val lecturasConsultadas = sqlContext.sql(
            """ select distinct * from lecturas
              |where id <> ""
              |and numero_serie <> ""
            """.stripMargin)

          lecturasConsultadas.cache()
          lecturasConsultadas.show()

          try {
            // guardamos en HDFS los datos que hemos procesado de la cola de Kafka. Incluimos la referencia
            println("Guardando en HDFS los datos procesados de la cola de Kafka...")


            lecturasConsultadas.write
              .partitionBy("topic", "kafkaPartition", "timestamp_hour", "numero_serie")
              .mode(SaveMode.Append)
              .parquet(variablesAguas.rutaLecturasHDFSParquet + variablesAguas.tablaLecturas.replace("public.", "") + "/")
          } catch {
            case ex: Exception => println("Error guardando en HDFS:\n"+ex.printStackTrace())
          }

          try {
            // guardamos en POSTGRES
            println("Guardando en Postgres los datos procesados ...")
            lecturasConsultadas.write.mode(SaveMode.Append)
              .jdbc(variablesAguas.urlPostgres, variablesAguas.tablaLecturas, propsConexionPostgres)
          } catch {
            case ex: Exception => println("Error guardando en PostGresSql:\n"+ex.printStackTrace())
          }
        } else {
          println("Esperando la llegada de lecturas de la cola de Kafka 'lecturas', donde el microservicio principal deposita los Json que ha compuesto ...")
        }

      }

      ssc
    }

    val ssc = getStreamingContext(streamingApp, sc, batchDuration)

    ssc.start()
    ssc.awaitTermination()

  }
}
