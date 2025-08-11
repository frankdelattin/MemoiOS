package com.example.onnx

import android.graphics.BitmapFactory
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.runner.RunWith
import org.mockito.junit.MockitoJUnitRunner
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowBitmapFactory
import java.io.File
import kotlin.test.Test
import kotlin.test.assertNotNull

@RunWith(AndroidJUnit4::class)
internal class OnnxPluginTest {

  @Test
  fun testEncodeImage() {
    val plugin = OnnxPlugin()
    val context = InstrumentationRegistry.getInstrumentation().targetContext

    // Model dosyasının yolunu belirtin
    val modelPath = "/Users/emre/Projects/snapp_app/assets/models/nlp_visualize.onnx"

    // Test edilecek resmin yolunu belirtin
    val imagePath = "/Users/emre/Downloads/image.jpeg"
    val imageFile = File(imagePath)
    val bitmap = BitmapFactory.decodeFile(imageFile.absolutePath)

    // encodeImage fonksiyonunu çağır
    val result = plugin.encodeImage(modelPath, bitmap)

    // Sonucun null olmadığını kontrol et
    assertNotNull(result, "Encoded image features should not be null")
  }
}
