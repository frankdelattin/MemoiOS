import java.io.InputStream
import java.util.zip.GZIPInputStream

// Cache mekanizması için yardımcı sınıf
class LRUCache<K, V>(private val maxSize: Int) : LinkedHashMap<K, V>(maxSize, 0.75f, true) {
    override fun removeEldestEntry(eldest: Map.Entry<K, V>): Boolean {
        return size > maxSize
    }
}

private val bytesToUnicodeCache = LRUCache<Unit, Map<Int, String>>(128)

fun bytesToUnicode(): Map<Int, String> {
    return bytesToUnicodeCache.getOrPut(Unit) {
        val bs = (('!'.code..'~'.code).toList() +
                ('¡'.code..'¬'.code).toList() +
                ('®'.code..'ÿ'.code).toList()).toMutableList()
        val cs = bs.toMutableList()
        var n = 0

        for (b in 0 until 256) {
            if (b !in bs) {
                bs.add(b)
                cs.add(256 + n)
                n += 1
            }
        }

        bs.zip(cs.map { it.toChar().toString() }).toMap()
    }
}

fun getPairs(word: List<String>): Set<Pair<String, String>> {
    val pairs = mutableSetOf<Pair<String, String>>()
    var prevChar = word[0]
    for (char in word.drop(1)) {
        pairs.add(Pair(prevChar, char))
        prevChar = char
    }
    return pairs
}

fun basicClean(text: String): String {
    // Not: ftfy ve html işlemleri için uygun Kotlin kütüphaneleri kullanılmalı
    return text.trim()
}

fun whitespaceClean(text: String): String {
    return text.replace(Regex("\\s+"), " ").trim()
}

class SimpleTokenizer(private val bpeStream: InputStream) {
    private val byteEncoder = bytesToUnicode()
    private val byteDecoder = byteEncoder.entries.associate { (k, v) -> v to k }
    private val merges: List<Pair<String, String>>
    private val encoder: Map<String, Int>
    private val decoder: Map<Int, String>
    private val bpeRanks: Map<Pair<String, String>, Int>
    private val cache = mutableMapOf(
        "<|startoftext|>" to "<|startoftext|>",
        "<|endoftext|>" to "<|endoftext|>"
    )
    private val pat = Regex(
        """<\|startoftext\|>|<\|endoftext\|>|'s|'t|'re|'ve|'m|'ll|'d|[\p{L}]+|[\p{N}]|[^\s\p{L}\p{N}]+""",
        RegexOption.IGNORE_CASE
    )

    init {
        val mergesText = bpeStream.use { fis ->
            GZIPInputStream(fis).bufferedReader().use { it.readText() }
        }

        val mergesList = mergesText.split('\n')
            .subList(1, 49152 - 256 - 2 + 1)
            .map { it.split(" ").let { parts -> Pair(parts[0], parts[1]) } }

        merges = mergesList

        val vocab = bytesToUnicode().values.toList()
        val vocabWithSuffix = vocab + vocab.map { "$it</w>" }
        val vocabWithMerges = vocabWithSuffix.toMutableList()

        mergesList.forEach { (first, second) ->
            vocabWithMerges.add(first + second)
        }

        vocabWithMerges.addAll(listOf("<|startoftext|>", "<|endoftext|>"))

        encoder = vocabWithMerges.withIndex().associate { (index, value) -> value to index }
        decoder = encoder.entries.associate { (k, v) -> v to k }
        bpeRanks = mergesList.withIndex().associate { (index, value) -> value to index }
    }

    fun bpe(token: String): String {
        if (token in cache) {
            return cache[token]!!
        }

        var word =
            token.dropLast(1).map { it.toString() } + listOf(token.last().toString() + "</w>")
        var pairs = getPairs(word)

        if (pairs.isEmpty()) {
            return token + "</w>"
        }

        while (true) {
            val bigram = pairs.minByOrNull { bpeRanks[it] ?: Float.POSITIVE_INFINITY.toInt() }
                ?: break

            if (bigram !in bpeRanks) break

            val (first, second) = bigram
            val newWord = mutableListOf<String>()
            var i = 0

            while (i < word.size) {
                val j = word.subList(i, word.size).indexOf(first)
                if (j == -1) {
                    newWord.addAll(word.slice(i until word.size))
                    break
                } else {
                    val actualIndex = i + j
                    newWord.addAll(word.slice(i until actualIndex))
                    i = actualIndex

                    if (word[i] == first && i < word.size - 1 && word[i + 1] == second) {
                        newWord.add(first + second)
                        i += 2
                    } else {
                        newWord.add(word[i])
                        i += 1
                    }
                }
            }

            word = newWord
            if (word.size == 1) break
            else pairs = getPairs(word)
        }

        val result = word.joinToString(" ")
        cache[token] = result
        return result
    }

    fun tokenize(text: String): List<Int> {
        val bpeTokens = mutableListOf<Int>()
        val cleanedText = whitespaceClean(basicClean(text)).lowercase()

        pat.findAll(cleanedText).forEach { match ->
            val token = match.value.encodeToByteArray()
                .joinToString("") { byteEncoder[it.toInt() and 0xFF] ?: "" }
            bpeTokens.addAll(bpe(token).split(" ").mapNotNull { encoder[it] })
        }

        return bpeTokens
    }
}