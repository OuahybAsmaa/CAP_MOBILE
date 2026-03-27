package com.example.cap_mobile1

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.KeyEvent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.zebra.rfid.api3.ENUM_TRANSPORT
import com.zebra.rfid.api3.MEMORY_BANK
import com.zebra.rfid.api3.RFIDReader
import com.zebra.rfid.api3.ReaderDevice
import com.zebra.rfid.api3.Readers
import com.zebra.rfid.api3.RfidEventsListener
import com.zebra.rfid.api3.RfidReadEvents
import com.zebra.rfid.api3.RfidStatusEvents
import com.zebra.rfid.api3.STATUS_EVENT_TYPE
import com.zebra.rfid.api3.TagData
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(),
    Readers.RFIDReaderEventHandler,
    RfidEventsListener {

    companion object {
        const val METHOD_CHANNEL = "com.example.cap_mobile1/rfid"
        const val EVENT_CHANNEL  = "com.example.cap_mobile1/rfid_events"
    }

    private var readersBluetooth: Readers? = null
    private var availableRFIDReaderList: MutableList<ReaderDevice> = mutableListOf()
    private var rfidReader: RFIDReader? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile private var singleReadResult: MethodChannel.Result? = null
    @Volatile private var singleReadDone = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT)
            != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.BLUETOOTH_CONNECT,
                    Manifest.permission.BLUETOOTH_SCAN
                ),
                1001
            )
        }
    }

    // ✅ Intercepter bouton TC52
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == 103 && event?.repeatCount == 0) {
            android.util.Log.d("RFID_DEBUG", "🔑 Bouton TC52 pressé!")

            Thread {
                try {
                    // ✅ Étape 1 : Préparer capture
                    singleReadDone = false

                    // ✅ Étape 2 : Notifier Flutter → Flutter appelle readSingleTag()
                    // readSingleTag() va setter singleReadResult
                    mainHandler.post {
                        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                            MethodChannel(messenger, METHOD_CHANNEL).invokeMethod("onScanButton", null)
                        }
                    }

                    // ✅ Étape 3 : Attendre que readSingleTag() soit prêt (max 1 sec)
                    var waited = 0
                    while (singleReadResult == null && waited < 10) {
                        Thread.sleep(100)
                        waited++
                    }

                    // ✅ Étape 4 : Démarrer inventory
                    if (singleReadResult != null && !singleReadDone && rfidReader != null) {
                        rfidReader!!.Actions.Inventory.perform()
                        android.util.Log.d("RFID_DEBUG", "▶️ Inventory démarré via bouton TC52")
                    } else {
                        android.util.Log.e("RFID_DEBUG", "❌ readSingleTag pas prêt après attente")
                    }

                } catch (_: Throwable) {}
            }.start()

            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == 103) return true
        return super.onKeyUp(keyCode, event)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAvailableReaders" -> getAvailableReaders(result)
                "connect"            -> connect(call.argument("readerName")!!, result)
                "disconnect"         -> disconnect(result)
                "readSingleTag"      -> readSingleTag(result)
                "writeTag"           -> writeTag(
                    call.argument("tagId")!!,
                    call.argument("data")!!,
                    result
                )
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun getAvailableReaders(result: MethodChannel.Result) {
        Thread {
            try {
                android.util.Log.d("RFID_DEBUG", "=== getAvailableReaders ===")
                availableRFIDReaderList.clear()

                try { Readers.deattach(this@MainActivity) } catch (_: Throwable) {}
                try { readersBluetooth?.Dispose() } catch (_: Throwable) {}
                readersBluetooth = null
                Thread.sleep(500)

                readersBluetooth = Readers(applicationContext, ENUM_TRANSPORT.BLUETOOTH)
                val found = readersBluetooth!!.GetAvailableRFIDReaderList()
                android.util.Log.d("RFID_DEBUG", "BLUETOOTH: ${found?.size ?: 0} lecteur(s)")
                found?.forEach {
                    android.util.Log.d("RFID_DEBUG", "  → name=[${it.name}] address=[${it.address}]")
                    availableRFIDReaderList.add(it)
                }

                android.util.Log.d("RFID_DEBUG", "=== TOTAL: ${availableRFIDReaderList.size} ===")

                val list = availableRFIDReaderList.map { device ->
                    mapOf(
                        "name"    to (device.name    ?: "Inconnu"),
                        "address" to (device.address ?: "N/A")
                    )
                }
                mainHandler.post { result.success(list) }

            } catch (e: Throwable) {
                android.util.Log.e("RFID_DEBUG", "Erreur: ${e.message}", e)
                mainHandler.post { result.error("READERS_ERROR", e.message ?: "Erreur", null) }
            }
        }.start()
    }

    private fun connect(readerName: String, result: MethodChannel.Result) {
        Thread {
            try {
                android.util.Log.d("RFID_DEBUG", ">>> connect() appelé pour: $readerName")

                try {
                    rfidReader?.Events?.removeEventsListener(this@MainActivity)
                    rfidReader?.disconnect()
                    rfidReader = null
                    Thread.sleep(300)
                } catch (_: Throwable) {}

                val device = availableRFIDReaderList.find { it.name == readerName }
                    ?: run {
                        mainHandler.post { result.error("NOT_FOUND", "Introuvable: $readerName", null) }
                        return@Thread
                    }

                android.util.Log.d("RFID_DEBUG", "Tentative connect()...")
                rfidReader = device.rfidReader
                rfidReader!!.connect()
                android.util.Log.d("RFID_DEBUG", "✅ connect() terminé")

                rfidReader!!.Events.addEventsListener(this@MainActivity)
                rfidReader!!.Events.setTagReadEvent(true)
                rfidReader!!.Events.setReaderDisconnectEvent(true)

                // ✅ Configurer RFD40P pour accepter trigger logiciel depuis TC52
                try {
                    val startTrigger = rfidReader!!.Config.getStartTrigger()
                    val stopTrigger  = rfidReader!!.Config.getStopTrigger()

                    android.util.Log.d("RFID_DEBUG", "StartTrigger actuel: ${startTrigger?.triggerType}")
                    android.util.Log.d("RFID_DEBUG", "StopTrigger actuel: ${stopTrigger?.triggerType}")

                    // Forcer trigger IMMEDIATE = inventory démarre dès Inventory.perform()
                    startTrigger?.triggerType = com.zebra.rfid.api3.START_TRIGGER_TYPE.START_TRIGGER_TYPE_IMMEDIATE
                    stopTrigger?.triggerType  = com.zebra.rfid.api3.STOP_TRIGGER_TYPE.STOP_TRIGGER_TYPE_IMMEDIATE

                    rfidReader!!.Config.setStartTrigger(startTrigger)
                    rfidReader!!.Config.setStopTrigger(stopTrigger)

                    android.util.Log.d("RFID_DEBUG", "✅ Trigger IMMEDIATE configuré sur RFD40P")
                } catch (e: Throwable) {
                    android.util.Log.e("RFID_DEBUG", "Trigger config erreur: ${e.message}")
                }

                mainHandler.post { result.success("Connecté à $readerName") }
            } catch (e: Throwable) {
                android.util.Log.e("RFID_DEBUG", "connect erreur: ${e.message}", e)
                mainHandler.post { result.error("CONNECT_ERROR", e.message ?: "Erreur", null) }
            }
        }.start()
    }

    private fun disconnect(result: MethodChannel.Result) {
        Thread {
            try {
                android.util.Log.d("RFID_DEBUG", ">>> disconnect() appelé")
                rfidReader?.Events?.removeEventsListener(this@MainActivity)
                rfidReader?.disconnect()
                rfidReader = null
                android.util.Log.d("RFID_DEBUG", "✅ disconnect() terminé")
                mainHandler.post { result.success("Déconnecté") }
            } catch (e: Throwable) {
                android.util.Log.e("RFID_DEBUG", "disconnect erreur: ${e.message}", e)
                mainHandler.post { result.error("DISCONNECT_ERROR", e.message ?: "Erreur", null) }
            }
        }.start()
    }

    private fun readSingleTag(result: MethodChannel.Result) {
        Thread {
            try {
                android.util.Log.d("RFID_DEBUG", ">>> readSingleTag() - attente bouton TC52")

                if (rfidReader == null) {
                    mainHandler.post { result.error("NOT_CONNECTED", "Non connecté", null) }
                    return@Thread
                }

                if (singleReadResult != null) {
                    mainHandler.post { result.error("BUSY", "Scan déjà en cours", null) }
                    return@Thread
                }

                singleReadResult = result
                singleReadDone   = false

                // ✅ PAS de Inventory.perform() ici
                // Le bouton TC52 va déclencher onKeyDown → Inventory.perform()
                android.util.Log.d("RFID_DEBUG", "⏳ Prêt — appuyez sur bouton TC52...")

                // ✅ Attendre max 30 secondes
                var waited = 0
                while (!singleReadDone && waited < 300) {
                    Thread.sleep(100)
                    waited++
                }

                try {
                    rfidReader!!.Actions.Inventory.stop()
                    Thread.sleep(500)
                } catch (_: Throwable) {}

                android.util.Log.d("RFID_DEBUG", "⏹️ Inventory stoppé")

                if (!singleReadDone) {
                    singleReadResult = null
                    mainHandler.post {
                        result.error("TIMEOUT", "Timeout — appuyez sur le bouton TC52", null)
                    }
                }

            } catch (e: Throwable) {
                android.util.Log.e("RFID_DEBUG", "readSingleTag erreur: ${e.message}", e)
                singleReadResult = null
                mainHandler.post { result.error("READ_ERROR", e.message ?: "Erreur", null) }
            }
        }.start()
    }

    private fun writeTag(tagId: String, data: String, result: MethodChannel.Result) {
        Thread {
            try {
                android.util.Log.d("RFID_DEBUG", ">>> writeTag() tagId=$tagId data=$data")

                if (rfidReader == null) {
                    mainHandler.post { result.error("NOT_CONNECTED", "Non connecté", null) }
                    return@Thread
                }

                try {
                    rfidReader!!.Actions.Inventory.stop()
                    Thread.sleep(1000)
                } catch (_: Throwable) {}

                val dataBytes = mutableListOf<Byte>()
                var i = 0
                while (i < data.length - 1) {
                    val byteStr = data.substring(i, i + 2)
                    dataBytes.add(byteStr.toInt(16).toByte())
                    i += 2
                }
                val bytesArray = dataBytes.toByteArray()
                val wordCount = bytesArray.size / 2
                android.util.Log.d("RFID_DEBUG", "bytes=${bytesArray.size} words=$wordCount")

                val writeParams = rfidReader!!.Actions.TagAccess.WriteAccessParams()
                writeParams.accessPassword = 0
                writeParams.memoryBank     = MEMORY_BANK.MEMORY_BANK_EPC
                writeParams.offset         = 2
                writeParams.writeData      = bytesArray

                try {
                    val field = writeParams.javaClass.getDeclaredField("m_nWriteDataLength")
                    field.isAccessible = true
                    field.set(writeParams, wordCount)
                    android.util.Log.d("RFID_DEBUG", "m_nWriteDataLength = $wordCount ✅")
                } catch (e: Throwable) {
                    android.util.Log.e("RFID_DEBUG", "Réflexion erreur: ${e.message}")
                }

                android.util.Log.d("RFID_DEBUG", "Écriture en cours sur tagId=$tagId...")
                rfidReader!!.Actions.TagAccess.writeWait(tagId, writeParams, null, null)

                android.util.Log.d("RFID_DEBUG", "✅ Tag écrit: $tagId → $data")
                mainHandler.post { result.success("Tag écrit avec succès") }

            } catch (e: com.zebra.rfid.api3.InvalidUsageException) {
                android.util.Log.e("RFID_DEBUG", "InvalidUsageException: ${e.info}")
                mainHandler.post { result.error("WRITE_ERROR", "Erreur: ${e.info}", null) }
            } catch (e: com.zebra.rfid.api3.OperationFailureException) {
                android.util.Log.e("RFID_DEBUG", "OperationFailureException: ${e.results}")
                mainHandler.post { result.error("WRITE_ERROR", "Écriture échouée — gardez la puce proche du lecteur", null) }
            } catch (e: Throwable) {
                android.util.Log.e("RFID_DEBUG", "writeTag erreur: ${e.message}", e)
                mainHandler.post { result.error("WRITE_ERROR", e.message ?: "Erreur", null) }
            }
        }.start()
    }

    override fun eventReadNotify(e: RfidReadEvents?) {
        val tags: Array<TagData>? = rfidReader?.Actions?.getReadTags(100)
        tags?.forEach { tag ->
            val tagId = tag.tagID ?: return@forEach
            android.util.Log.d("RFID_DEBUG", "🏷️ Tag lu: $tagId")

            if (singleReadResult != null && !singleReadDone) {
                singleReadDone   = true
                val pendingResult = singleReadResult!!
                singleReadResult  = null
                try { rfidReader!!.Actions.Inventory.stop() } catch (_: Throwable) {}
                mainHandler.post { pendingResult.success(tagId) }
                return
            }

            mainHandler.post {
                eventSink?.success(mapOf(
                    "event" to "tag",
                    "tagId" to tagId,
                    "rssi"  to tag.peakRSSI.toString()
                ))
            }
        }
    }

    override fun eventStatusNotify(e: RfidStatusEvents?) {
        android.util.Log.d("RFID_DEBUG", "📡 Status: ${e?.StatusEventData?.statusEventType}")
        if (e?.StatusEventData?.statusEventType == STATUS_EVENT_TYPE.DISCONNECTION_EVENT) {
            mainHandler.post {
                eventSink?.success(mapOf("event" to "disconnected"))
            }
        }
    }

    override fun RFIDReaderAppeared(readerDevice: ReaderDevice?) {
        android.util.Log.d("RFID_DEBUG", "🎉 Lecteur apparu: ${readerDevice?.name}")
    }

    override fun RFIDReaderDisappeared(readerDevice: ReaderDevice?) {
        android.util.Log.d("RFID_DEBUG", "Lecteur disparu: ${readerDevice?.name}")
    }

    override fun onDestroy() {
        try { rfidReader?.Events?.removeEventsListener(this) } catch (_: Throwable) {}
        try { rfidReader?.disconnect() }            catch (_: Throwable) {}
        try { Readers.deattach(this@MainActivity) } catch (_: Throwable) {}
        try { readersBluetooth?.Dispose() }         catch (_: Throwable) {}
        super.onDestroy()
    }
}