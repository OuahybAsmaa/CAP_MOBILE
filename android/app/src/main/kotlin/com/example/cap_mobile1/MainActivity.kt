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
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.content.Context

class MainActivity : FlutterActivity(),
    Readers.RFIDReaderEventHandler,
    RfidEventsListener {

    companion object {
        const val METHOD_CHANNEL = "com.example.cap_mobile1/rfid"
        const val EVENT_CHANNEL  = "com.example.cap_mobile1/rfid_events"
    }

    private var readersBluetooth: Readers? = null

    private var readersInternal: Readers? = null

    private var availableRFIDReaderList: MutableList<ReaderDevice> = mutableListOf()
    private var rfidReader: RFIDReader? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile private var singleReadResult: MethodChannel.Result? = null
    @Volatile private var singleReadDone = false
    @Volatile private var inventoryRunning = false

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

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == 103 && event?.repeatCount == 0) {
            android.util.Log.d("RFID_DEBUG", "Bouton TC52 presse!")

            Thread {
                try {
                    singleReadDone = false

                    mainHandler.post {
                        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                            MethodChannel(messenger, METHOD_CHANNEL).invokeMethod("onScanButton", null)
                        }
                    }

                    var waited = 0
                    while (singleReadResult == null && waited < 10) {
                        Thread.sleep(100)
                        waited++
                    }

                    if (singleReadResult != null && !singleReadDone && rfidReader != null) {
                        rfidReader!!.Actions.Inventory.perform()
                        android.util.Log.d("RFID_DEBUG", "Inventory demarre via bouton TC52")
                    } else {
                        android.util.Log.e("RFID_DEBUG", "readSingleTag pas pret apres attente")
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
                "getBatteryLevel"     -> getBatteryLevel(result)
                "startInventory"      -> startInventory(result)
                "stopInventory"       -> stopInventory(result)
                "configureMemoryBank" -> configureMemoryBank(
                    call.argument("memoryBank")!!,
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

    // MODIFIE : getAvailableReaders cherche sur BLUETOOTH (sled RFD40)
    //           ET sur INTERNAL (TC53E et appareils a RFID integre)
    private fun getAvailableReaders(result: MethodChannel.Result) {
        Thread {
            try {
                android.util.Log.d("RFID_DEBUG", "=== getAvailableReaders ===")
                availableRFIDReaderList.clear()

                try { Readers.deattach(this@MainActivity) } catch (_: Throwable) {}
                try { readersBluetooth?.Dispose() } catch (_: Throwable) {}
                try { readersInternal?.Dispose() }  catch (_: Throwable) {}
                readersBluetooth = null
                readersInternal  = null
                Thread.sleep(500)

                // 1. Recherche Bluetooth (sled RFD40, RFD8500)
                try {
                    readersBluetooth = Readers(applicationContext, ENUM_TRANSPORT.BLUETOOTH)
                    val foundBT = readersBluetooth!!.GetAvailableRFIDReaderList()
                    android.util.Log.d("RFID_DEBUG", "BLUETOOTH: ${foundBT?.size ?: 0} lecteur(s)")
                    foundBT?.forEach {
                        android.util.Log.d("RFID_DEBUG", "  [BT] name=[${it.name}] address=[${it.address}]")
                        availableRFIDReaderList.add(it)
                    }
                } catch (e: Throwable) {
                    android.util.Log.e("RFID_DEBUG", "Bluetooth scan erreur: ${e.message}")
                }

                // 2. Recherche tous les transports disponibles (TC53E RFID integre)
                // On itere sur toutes les valeurs de l'enum ENUM_TRANSPORT pour trouver
                // le bon transport selon la version du SDK installee sur l'appareil
                val transportsToTry = try {
                    ENUM_TRANSPORT::class.java.enumConstants
                        ?.filter { it != ENUM_TRANSPORT.BLUETOOTH } // Bluetooth deja fait
                        ?: emptyList()
                } catch (_: Throwable) { emptyList() }

                for (transport in transportsToTry) {
                    try {
                        val readers = Readers(applicationContext, transport)
                        val found = readers.GetAvailableRFIDReaderList()
                        android.util.Log.d("RFID_DEBUG", "$transport: ${found?.size ?: 0} lecteur(s)")
                        found?.forEach {
                            android.util.Log.d("RFID_DEBUG", "  [$transport] name=[${it.name}] address=[${it.address}]")
                            if (availableRFIDReaderList.none { existing -> existing.name == it.name }) {
                                availableRFIDReaderList.add(it)
                                if (transport != ENUM_TRANSPORT.BLUETOOTH) {
                                    readersInternal = readers
                                }
                            }
                        }
                    } catch (e: Throwable) {
                        android.util.Log.d("RFID_DEBUG", "$transport: non supporte (${e.message})")
                    }
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
                android.util.Log.d("RFID_DEBUG", ">>> connect() appele pour: $readerName")

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
                android.util.Log.d("RFID_DEBUG", "connect() termine")

                rfidReader!!.Events.addEventsListener(this@MainActivity)
                rfidReader!!.Events.setTagReadEvent(true)
                rfidReader!!.Events.setReaderDisconnectEvent(true)
                rfidReader!!.Events.setHandheldEvent(true)
                rfidReader!!.Events.setHandheldEvent(true)

                try {
                    val startTrigger = rfidReader!!.Config.getStartTrigger()
                    val stopTrigger  = rfidReader!!.Config.getStopTrigger()

                    android.util.Log.d("RFID_DEBUG", "StartTrigger actuel: ${startTrigger?.triggerType}")
                    android.util.Log.d("RFID_DEBUG", "StopTrigger actuel: ${stopTrigger?.triggerType}")

                    startTrigger?.triggerType = com.zebra.rfid.api3.START_TRIGGER_TYPE.START_TRIGGER_TYPE_IMMEDIATE
                    stopTrigger?.triggerType  = com.zebra.rfid.api3.STOP_TRIGGER_TYPE.STOP_TRIGGER_TYPE_IMMEDIATE

                    rfidReader!!.Config.setStartTrigger(startTrigger)
                    rfidReader!!.Config.setStopTrigger(stopTrigger)

                    android.util.Log.d("RFID_DEBUG", "Trigger IMMEDIATE configure")
                } catch (e: Throwable) {
                    android.util.Log.e("RFID_DEBUG", "Trigger config erreur: ${e.message}")
                }

                mainHandler.post { result.success("Connecte a $readerName") }
            } catch (e: Throwable) {
                android.util.Log.e("RFID_DEBUG", "connect erreur: ${e.message}", e)
                mainHandler.post { result.error("CONNECT_ERROR", e.message ?: "Erreur", null) }
            }
        }.start()
    }

    private fun disconnect(result: MethodChannel.Result) {
        Thread {
            try {
                inventoryRunning = false
                rfidReader?.Events?.removeEventsListener(this@MainActivity)
                rfidReader?.disconnect()
                rfidReader = null
                mainHandler.post { result.success("Deconnecte") }
            } catch (e: Throwable) {
                mainHandler.post { result.error("DISCONNECT_ERROR", e.message ?: "Erreur", null) }
            }
        }.start()
    }

    private fun readSingleTag(result: MethodChannel.Result) {
        Thread {
            try {
                android.util.Log.d("RFID_DEBUG", ">>> readSingleTag() - attente bouton TC52")

                if (rfidReader == null) {
                    mainHandler.post { result.error("NOT_CONNECTED", "Non connecte", null) }
                    return@Thread
                }

                if (singleReadResult != null) {
                    mainHandler.post { result.error("BUSY", "Scan deja en cours", null) }
                    return@Thread
                }

                singleReadResult = result
                singleReadDone   = false

                android.util.Log.d("RFID_DEBUG", "Pret appuyez sur bouton TC52...")

                var waited = 0
                while (!singleReadDone && waited < 300) {
                    Thread.sleep(100)
                    waited++
                }

                try {
                    rfidReader!!.Actions.Inventory.stop()
                    Thread.sleep(500)
                } catch (_: Throwable) {}

                android.util.Log.d("RFID_DEBUG", "Inventory stoppe")

                if (!singleReadDone) {
                    singleReadResult = null
                    mainHandler.post {
                        result.error("TIMEOUT", "Timeout appuyez sur le bouton TC52", null)
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
                    mainHandler.post { result.error("NOT_CONNECTED", "Non connecte", null) }
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

                val writeParams = rfidReader!!.Actions.TagAccess.WriteAccessParams()
                writeParams.accessPassword = 0
                writeParams.memoryBank     = MEMORY_BANK.MEMORY_BANK_EPC
                writeParams.offset         = 2
                writeParams.writeData      = bytesArray

                try {
                    val field = writeParams.javaClass.getDeclaredField("m_nWriteDataLength")
                    field.isAccessible = true
                    field.set(writeParams, wordCount)
                } catch (e: Throwable) {
                    android.util.Log.e("RFID_DEBUG", "Reflexion erreur: ${e.message}")
                }

                android.util.Log.d("RFID_DEBUG", "Ecriture en cours sur tagId=$tagId...")
                rfidReader!!.Actions.TagAccess.writeWait(tagId, writeParams, null, null)

                android.util.Log.d("RFID_DEBUG", "Tag ecrit: $tagId")

                beepSuccess()

                mainHandler.post { result.success("Tag ecrit avec succes") }

            } catch (e: com.zebra.rfid.api3.InvalidUsageException) {
                android.util.Log.e("RFID_DEBUG", "InvalidUsageException: ${e.info}")
                beepError()
                vibrateError()
                mainHandler.post { result.error("WRITE_ERROR", "Erreur: ${e.info}", null) }

            } catch (e: com.zebra.rfid.api3.OperationFailureException) {
                android.util.Log.e("RFID_DEBUG", "OperationFailureException: ${e.results}")
                beepError()
                vibrateError()
                mainHandler.post { result.error("WRITE_ERROR", "Ecriture echouee gardez la puce proche du lecteur", null) }

            } catch (e: Throwable) {
                android.util.Log.e("RFID_DEBUG", "writeTag erreur: ${e.message}", e)
                beepError()
                vibrateError()
                mainHandler.post { result.error("WRITE_ERROR", e.message ?: "Erreur", null) }
            }
        }.start()
    }

    private fun getBatteryLevel(result: MethodChannel.Result) {
        Thread {
            try {
                if (rfidReader == null) {
                    mainHandler.post { result.success(-1) }
                    return@Thread
                }
                var batteryLevel = -1
                try {
                    val batteryStats = rfidReader!!.Config.getBatteryStats()
                    val field = batteryStats?.javaClass?.getDeclaredField("percentage")
                    field?.isAccessible = true
                    val value = field?.get(batteryStats)
                    if (value is Int && value in 0..100) {
                        batteryLevel = value
                    }
                } catch (e: Throwable) {
                    android.util.Log.e("RFID_DEBUG", "getBatteryStats erreur: ${e.message}")
                }
                mainHandler.post { result.success(batteryLevel) }
            } catch (e: Throwable) {
                mainHandler.post { result.success(-1) }
            }
        }.start()
    }

    private fun startInventory(result: MethodChannel.Result) {
        Thread {
            try {
                if (rfidReader == null) {
                    mainHandler.post { result.error("NOT_CONNECTED", "Non connecte", null) }
                    return@Thread
                }
                if (inventoryRunning) {
                    mainHandler.post { result.error("ALREADY_RUNNING", "Inventaire deja en cours", null) }
                    return@Thread
                }
                inventoryRunning = true
                rfidReader!!.Actions.Inventory.perform()
                mainHandler.post { result.success("Inventaire demarre") }
            } catch (e: Throwable) {
                inventoryRunning = false
                mainHandler.post { result.error("INVENTORY_ERROR", e.message ?: "Erreur", null) }
            }
        }.start()
    }

    private fun stopInventory(result: MethodChannel.Result) {
        Thread {
            try {
                inventoryRunning = false
                rfidReader?.Actions?.Inventory?.stop()
                mainHandler.post { result.success("Inventaire arrete") }
            } catch (e: Throwable) {
                mainHandler.post { result.error("INVENTORY_ERROR", e.message ?: "Erreur", null) }
            }
        }.start()
    }

    private fun configureMemoryBank(memoryBank: String, result: MethodChannel.Result) {
        Thread {
            try {
                if (rfidReader == null) {
                    mainHandler.post { result.error("NOT_CONNECTED", "Non connecte", null) }
                    return@Thread
                }
                try {
                    val tagFieldClass = Class.forName("com.zebra.rfid.api3.TAG_FIELD")
                    val settings = rfidReader!!.Config.getTagStorageSettings()
                    val fieldName = when (memoryBank.uppercase()) {
                        "NONE"     -> "ALL_TAG_FIELDS"
                        "EPC"      -> "PC"
                        "TID"      -> "TID"
                        "USER"     -> "USER"
                        "RESERVED" -> "ALL_TAG_FIELDS"
                        "TAMPER"   -> "ALL_TAG_FIELDS"
                        else       -> "ALL_TAG_FIELDS"
                    }
                    val tagFieldValue = tagFieldClass.getField(fieldName).get(null)
                    val setMethod = settings?.javaClass?.getMethod("setTagFields", tagFieldClass)
                    setMethod?.invoke(settings, tagFieldValue)
                    rfidReader!!.Config.setTagStorageSettings(settings)
                } catch (e: Throwable) {
                    android.util.Log.e("RFID_DEBUG", "configureMemoryBank erreur: ${e.message}")
                }
                mainHandler.post { result.success("Banque configuree: $memoryBank") }
            } catch (e: Throwable) {
                mainHandler.post { result.success("Banque par defaut") }
            }
        }.start()
    }

    private fun triggerDataWedgeScan(start: Boolean) {
        try {
            val intent = android.content.Intent()
            intent.action = "com.symbol.datawedge.api.ACTION"
            intent.putExtra(
                "com.symbol.datawedge.api.SOFT_SCAN_TRIGGER",
                if (start) "START_SCANNING" else "STOP_SCANNING"
            )
            sendBroadcast(intent)
            android.util.Log.d("RFID_DEBUG",
                if (start) "DataWedge START" else "DataWedge STOP")
        } catch (e: Throwable) {
            android.util.Log.e("RFID_DEBUG", "DataWedge erreur: ${e.message}")
        }
    }

    private fun beepSuccess() {
        Thread {
            try {
                val toneGen = ToneGenerator(AudioManager.STREAM_MUSIC, ToneGenerator.MAX_VOLUME)
                toneGen.startTone(ToneGenerator.TONE_PROP_BEEP, 120)
                Thread.sleep(140)
                toneGen.stopTone()
                Thread.sleep(60)
                toneGen.startTone(ToneGenerator.TONE_PROP_BEEP2, 300)
                Thread.sleep(340)
                toneGen.stopTone()
                toneGen.release()
            } catch (_: Throwable) {}
        }.start()
    }

    private fun beepError() {
        Thread {
            try {
                val toneGen = ToneGenerator(AudioManager.STREAM_MUSIC, ToneGenerator.MAX_VOLUME)
                toneGen.startTone(ToneGenerator.TONE_CDMA_SOFT_ERROR_LITE, 300)
                Thread.sleep(350)
                toneGen.stopTone()
                Thread.sleep(80)
                toneGen.startTone(ToneGenerator.TONE_CDMA_SOFT_ERROR_LITE, 300)
                Thread.sleep(350)
                toneGen.stopTone()
                toneGen.release()
            } catch (_: Throwable) {}
        }.start()
    }

    private fun vibrateError() {
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                val vibrator = vm.defaultVibrator
                vibrator.vibrate(VibrationEffect.createOneShot(1500, 255))
            } else {
                @Suppress("DEPRECATION")
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    vibrator.vibrate(VibrationEffect.createOneShot(1500, 255))
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(1500)
                }
            }
        } catch (_: Throwable) {}
    }

    override fun eventReadNotify(e: RfidReadEvents?) {
        val tags: Array<TagData>? = rfidReader?.Actions?.getReadTags(100)
        tags?.forEach { tag ->
            val tagId = tag.tagID ?: return@forEach

            // Mode lecture unique
            if (singleReadResult != null && !singleReadDone) {
                singleReadDone    = true
                val pendingResult = singleReadResult!!
                singleReadResult  = null
                try { rfidReader!!.Actions.Inventory.stop() } catch (_: Throwable) {}
                mainHandler.post { pendingResult.success(tagId) }
                return
            }

            // Mode inventaire
            if (inventoryRunning) {
                val tidData = try {
                    val f = tag.javaClass.getDeclaredField("tid")
                    f.isAccessible = true
                    (f.get(tag) as? String) ?: ""
                } catch (_: Throwable) { "" }

                val memoryBankData = try {
                    val f = tag.javaClass.getDeclaredField("memoryBankData")
                    f.isAccessible = true
                    (f.get(tag) as? String) ?: ""
                } catch (_: Throwable) { "" }

                mainHandler.post {
                    eventSink?.success(mapOf(
                        "event"          to "tag",
                        "tagId"          to tagId,
                        "rssi"           to tag.peakRSSI.toDouble(),
                        "memoryBankData" to memoryBankData,
                        "tidData"        to tidData,
                    ))
                }
            } else {
                mainHandler.post {
                    eventSink?.success(mapOf(
                        "event" to "tag",
                        "tagId" to tagId,
                        "rssi"  to tag.peakRSSI.toString()
                    ))
                }
            }
        }
    }

    override fun eventStatusNotify(e: RfidStatusEvents?) {
        val eventType = e?.StatusEventData?.statusEventType
        android.util.Log.d("RFID_DEBUG", "Status: $eventType")

        when (eventType) {
            STATUS_EVENT_TYPE.DISCONNECTION_EVENT -> {
                mainHandler.post {
                    eventSink?.success(mapOf("event" to "disconnected"))
                }
            }

            STATUS_EVENT_TYPE.HANDHELD_TRIGGER_EVENT -> {
                val triggerData = e?.StatusEventData?.HandheldTriggerEventData

                when (triggerData?.handheldEvent) {

                    com.zebra.rfid.api3.HANDHELD_TRIGGER_EVENT_TYPE.HANDHELD_TRIGGER_PRESSED -> {
                        android.util.Log.d("RFID_DEBUG", "RFD40 Trigger PRESSED")

                        Thread {
                            try {
                                singleReadDone = false

                                mainHandler.post {
                                    flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                                        MethodChannel(messenger, METHOD_CHANNEL)
                                            .invokeMethod("onScanButton", null)
                                    }
                                }

                                var waited = 0
                                while (singleReadResult == null && waited < 10) {
                                    Thread.sleep(100)
                                    waited++
                                }

                                if (singleReadResult != null && !singleReadDone && rfidReader != null) {
                                    rfidReader!!.Actions.Inventory.perform()
                                    android.util.Log.d("RFID_DEBUG", "Inventory demarre via trigger RFD40")
                                } else {
                                    android.util.Log.d("RFID_DEBUG", "Mode DataWedge simulation bouton TC52")
                                    mainHandler.post {
                                        triggerDataWedgeScan(true)
                                    }
                                }

                            } catch (_: Throwable) {}
                        }.start()
                    }

                    com.zebra.rfid.api3.HANDHELD_TRIGGER_EVENT_TYPE.HANDHELD_TRIGGER_RELEASED -> {
                        android.util.Log.d("RFID_DEBUG", "RFD40 Trigger RELEASED")

                        if (singleReadResult == null) {
                            mainHandler.post {
                                triggerDataWedgeScan(false)
                            }
                        }
                    }

                    else -> {}
                }
            }

            else -> {}
        }
    }

    override fun RFIDReaderAppeared(readerDevice: ReaderDevice?) {
        android.util.Log.d("RFID_DEBUG", "Lecteur apparu: ${readerDevice?.name}")
    }

    override fun RFIDReaderDisappeared(readerDevice: ReaderDevice?) {
        android.util.Log.d("RFID_DEBUG", "Lecteur disparu: ${readerDevice?.name}")
    }

    // MODIFIE : onDestroy dispose aussi readersInternal
    override fun onDestroy() {
        try { rfidReader?.Events?.removeEventsListener(this) } catch (_: Throwable) {}
        try { rfidReader?.disconnect() }            catch (_: Throwable) {}
        try { Readers.deattach(this@MainActivity) } catch (_: Throwable) {}
        try { readersBluetooth?.Dispose() }         catch (_: Throwable) {}
        try { readersInternal?.Dispose() }          catch (_: Throwable) {}
        super.onDestroy()
    }
}