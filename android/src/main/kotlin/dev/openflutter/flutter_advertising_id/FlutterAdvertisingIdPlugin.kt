package dev.openflutter.flutter_advertising_id

import android.content.Context
import com.google.android.gms.ads.identifier.AdvertisingIdClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.coroutines.CoroutineContext

/** FlutterAdvertisingIdPlugin */
class FlutterAdvertisingIdPlugin : FlutterPlugin, MethodCallHandler, CoroutineScope {

    private val job: Job = Job()

    private lateinit var channel: MethodChannel
    private var applicationContext: Context? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "dev.openflutter/flutter_advertising_id"
        )
        applicationContext = flutterPluginBinding.applicationContext
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getAdvertisingId" -> {
                applicationContext?.run {
                    launch {
                        val adInfo = withContext(Dispatchers.IO) {
                            runCatching {
                                AdvertisingIdClient.getAdvertisingIdInfo(this@run.applicationContext)
                            }.getOrNull()
                        }
                        withContext(Dispatchers.Main) {
                            result.success(adInfo?.id)
                        }
                    }
                } ?: run {
                    result.success(null)
                }
            }

            "limitAdTrackingEnabled" -> {
                applicationContext?.run {
                    launch {
                        val adInfo = withContext(Dispatchers.IO) {
                            runCatching {
                                AdvertisingIdClient.getAdvertisingIdInfo(this@run.applicationContext)
                            }.getOrNull()
                        }
                        withContext(Dispatchers.Main) {
                            result.success(adInfo?.isLimitAdTrackingEnabled ?: false)
                        }
                    }
                } ?: run {
                    result.success(null)
                }
            }

            "authorizationStatus" -> {
                result.success(3)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

//  case "getAdvertisingId":
//  let manager = ASIdentifierManager.shared()
//
//  if (ATTrackingManager.trackingAuthorizationStatus == ATTrackingManager.AuthorizationStatus.authorized) {
//    result(manager.advertisingIdentifier.uuidString)
//  } else if (call.arguments as? Bool ?? false){
//    ATTrackingManager.requestTrackingAuthorization { status in
//            if (status == ATTrackingManager.AuthorizationStatus.authorized) {
//              result(manager.advertisingIdentifier.uuidString)
//            } else {
//              result(nil)
//            }
//    }
//  } else {
//    result(nil)
//  }
//
//  case "limitAdTrackingEnabled":

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        applicationContext = null
        job.cancel()
    }

    override val coroutineContext: CoroutineContext = Dispatchers.Main + job

}
