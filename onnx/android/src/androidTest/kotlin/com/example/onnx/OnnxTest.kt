import android.graphics.BitmapFactory
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.example.onnx.OnnxPlugin
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File


const val TEST_STRING = "This is a string"
const val TEST_LONG = 12345678L

// @RunWith is required only if you use a mix of JUnit3 and JUnit4.
@RunWith(AndroidJUnit4::class)
class LogHistoryAndroidUnitTest {

    @Test
    fun testMethod1() {
        val plugin = OnnxPlugin()
        // Model dosyasının yolunu belirtin
        val modelPath = "/sdcard/Download/ai/nlp_visualize.onnx"

        // Test edilecek resmin yolunu belirtin
        val imagePath = "/sdcard/Download/ai/Lenna_(test_image)-2.png"
        val imageFile = File(imagePath)
        val inputStream = imageFile.inputStream()
        val bitmap = BitmapFactory.decodeStream(inputStream)
        inputStream.close()

        // encodeImage fonksiyonunu çağır
        val result = plugin.encodeImage(modelPath, bitmap)
        println("ag")
    }
}