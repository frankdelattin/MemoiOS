package com.example.onnx

import SimpleTokenizer
import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import ai.onnxruntime.OrtSession.SessionOptions
import ai.onnxruntime.providers.NNAPIFlags
import android.content.res.AssetManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMethodCodec
import org.pytorch.MemoryFormat
import org.pytorch.Tensor
import org.pytorch.torchvision.TensorImageUtils
import java.util.Collections
import java.util.EnumSet

/** OnnxPlugin */
class OnnxPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    private lateinit var assetManager: AssetManager

    private var ortEnv: OrtEnvironment? = null
    private var ortSessionVisual: OrtSession? = null
    private var ortSessionTextual: OrtSession? = null
    private var textualTokenizer: SimpleTokenizer? = null

    private val normMeanRGB = floatArrayOf(0.48145466f, 0.4578275f, 0.40821073f)
    private val normStdRGB = floatArrayOf(0.26862954f, 0.26130258f, 0.27577711f)

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val taskQueue =
            flutterPluginBinding.binaryMessenger.makeBackgroundTaskQueue()
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "onnx",
            StandardMethodCodec.INSTANCE,taskQueue)
        channel.setMethodCallHandler(this)
        assetManager = flutterPluginBinding.applicationContext.assets
    }


    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "encodeText") {
            val text = call.argument<String>("text")
            val modelPath = call.argument<String>("modelPath")
            val tokenizerPath = call.argument<String>("tokenizerPath")
            var output = encodeText(modelPath!!, tokenizerPath!!, text!!)
            result.success(output?.first())
        } else if (call.method == "encodeImage") {
            val modelPath = call.argument<String>("modelPath")
            val bytes = call.argument<ByteArray>("bytes")
            val bitmap = BitmapFactory.decodeByteArray(bytes!!, 0, bytes.size)
            val encodedFeatures = encodeImage(modelPath!!, bitmap!!)
            result.success(encodedFeatures!![0])
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        println("DETACHING...")
        channel.setMethodCallHandler(null)
        println("MethodCallHandlerDetached...")
    }




    fun encodeImage(modelPath: String, bitmap: Bitmap): Array<FloatArray>? {

        if (ortEnv == null) {
            ortEnv = OrtEnvironment.getEnvironment()
        }

        if (ortSessionVisual == null) {
            ortSessionVisual = ortEnv?.createSession(modelPath)
        }

        val start = System.currentTimeMillis()
        val floatBuffer = Tensor.allocateFloatBuffer(3 * 224 * 224)
        TensorImageUtils.bitmapToFloatBuffer(
            bitmap,
            0, 0,
            224, 224,
            normMeanRGB,
            normStdRGB,
            floatBuffer,
            0,
            MemoryFormat.CONTIGUOUS,
        )
        Log.d(
            "bitmapToBuffer",
            "${System.currentTimeMillis() - start} ms"
        )

        val inputName = ortSessionVisual?.inputNames?.iterator()?.next()
        val shape: LongArray = longArrayOf(1, 3, 224, 224)
        val env = OrtEnvironment.getEnvironment()
        env.use {
            val tensor = OnnxTensor.createTensor(env, floatBuffer, shape)
            tensor.use {
                val output: OrtSession.Result? =
                    ortSessionVisual?.run(Collections.singletonMap(inputName, tensor))
                output.use {
                    return (output?.get(0)?.value) as Array<FloatArray>
                }
            }
        }
    }

    fun encodeText(modelPath: String, tokenizerPath: String, text: String): Array<FloatArray>? {
        if (ortEnv == null) {
            ortEnv = OrtEnvironment.getEnvironment()
        }

        if (ortSessionTextual == null) {
            ortSessionTextual = ortEnv?.createSession(modelPath)
        }

        if (textualTokenizer == null) {
            val tokenizerVocabs = assetManager.open("flutter_assets/$tokenizerPath")
            textualTokenizer = SimpleTokenizer(tokenizerVocabs)
        }

        // Tokenize the text
        val tokens = textualTokenizer!!.tokenize(text)
        val inputName = ortSessionTextual?.inputNames?.iterator()?.next()
        val shape: LongArray = longArrayOf(1, 77)
        val intBuffer = Tensor.allocateIntBuffer(77)
        val intArray = IntArray(tokens.size) { tokens[it] }
        intBuffer.put(49406)
        intBuffer.put(intArray)
        intBuffer.put(49407)
        intBuffer.position(0)


        val env = OrtEnvironment.getEnvironment()
        env.use {
            val tensor = OnnxTensor.createTensor(env, intBuffer, shape)
            tensor.use {
                val output: OrtSession.Result? =
                    ortSessionTextual?.run(Collections.singletonMap(inputName, tensor))
                output.use {
                    return (output?.get(0)?.value) as Array<FloatArray>
                }
            }
        }
    }

    private fun toRGB(bitmap: Bitmap): Bitmap {
        val width = bitmap.width
        val height = bitmap.height
        val pixels = IntArray(width * height)
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height)

        for (i in pixels.indices) {
            val color = pixels[i]
            val red: Int = Color.red(color)
            val green: Int = Color.green(color)
            val blue: Int = Color.blue(color)
            val rgb = red shl 16 or (green shl 8) or blue
            pixels[i] = rgb
        }
        return bitmap
    }
}
