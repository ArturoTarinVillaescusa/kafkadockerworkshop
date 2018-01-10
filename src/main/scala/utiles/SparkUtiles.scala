package utiles

import java.lang.management.ManagementFactory

import funciones._
import org.apache.spark.sql.SQLContext
import org.apache.spark.streaming.{Duration, StreamingContext}
import org.apache.spark.{SparkConf, SparkContext}

/**
  * Created by atarin on 8/02/17.
  */
object SparkUtiles {

  val isIDE = {
    ManagementFactory.getRuntimeMXBean.getInputArguments.toString.contains("IntelliJ IDEA")
  }
  def getSparkContext(appName: String) = {
    var checkpointDirectory = ""

    // get spark configuration
    val conf = new SparkConf()
      .setAppName(appName)
      .set("spark.sql.parquet.enableVectorizedReader", "false")
      // .set("spark.casandra.connection.host", "localhost")

    // Check if running from IDE
    if (isIDE) {
      System.setProperty("hadoop.home.dir", "c:\\Libraries\\WinUtils") // Si corre en Windows hace falta tener winutils
      conf.setMaster(variablesAguas.masterLocal)
      checkpointDirectory = variablesAguas.checkpointLocal
    } else {
      conf.setMaster("local[*]")
      checkpointDirectory = variablesAguas.checkpointHDFS
    }

    // setup spark context
    val sc = SparkContext.getOrCreate(conf)
    sc.setCheckpointDir(checkpointDirectory)
    sc
  }

  def getSQLContext(sc: SparkContext) = {
    val sqlContext = SQLContext.getOrCreate(sc)
    sqlContext
  }

  def getStreamingContext(streamingApp : (SparkContext, Duration) => StreamingContext, sc : SparkContext, batchDuration: Duration) = {
    val creatingFunc = () => streamingApp(sc, batchDuration)
    val ssc = sc.getCheckpointDir match {
      case Some(checkpointDir) => StreamingContext.getActiveOrCreate(checkpointDir, creatingFunc, sc.hadoopConfiguration, createOnError = true)
      case None => StreamingContext.getActiveOrCreate(creatingFunc)
    }
    sc.getCheckpointDir.foreach( cp => ssc.checkpoint(cp))
    ssc
  }

}
