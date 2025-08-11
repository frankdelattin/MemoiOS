import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:html_unescape/html_unescape.dart';

class SimpleTokenizer {
  late Map<int, String> byteEncoder;
  late Map<String, int> byteDecoder;
  late Map<List<String>, int> bpeRanks;
  late RegExp pat;
  late Map<String, String> cache;
  late Map<String, int> encoder;
  late Map<int, String> decoder;

  SimpleTokenizer(Uint8List bpeBytes) {
    byteEncoder = bytesToUnicode();
    byteDecoder = byteEncoder.map((k, v) => MapEntry(v, k));

    List<String> merges = utf8.decode(GZipCodec().decode(bpeBytes)).split('\n');
    merges = merges.sublist(1, 49152 - 256 - 2 + 1);
    List<List<String>> mergesPairs = merges.map((m) => m.split(' ')).toList();

    List<String> vocab = List.from(byteEncoder.values);
    vocab.addAll(vocab.map((v) => '${v}</w>').toList());
    for (var merge in mergesPairs) {
      vocab.add(merge.join(''));
    }
    vocab.addAll(['<|startoftext|>', '<|endoftext|>']);

    encoder = Map.fromIterables(vocab, List.generate(vocab.length, (i) => i));
    decoder = Map.fromIterables(encoder.values, encoder.keys);
    bpeRanks = LinkedHashMap<List<String>, int>(
      equals: (list1, list2) {
        return ListEquality().equals(list1, list2);
      },
      hashCode: Object.hashAll,
    );
    var tmpBpeRanks = Map.fromIterables(
        mergesPairs, List.generate(mergesPairs.length, (i) => i));

    bpeRanks.addAll(tmpBpeRanks);
    cache = {
      '<|startoftext|>': '<|startoftext|>',
      '<|endoftext|>': '<|endoftext|>'
    };
    pat = RegExp(
        r"<\|startoftext\|>|<\|endoftext\|>|'s|'t|'re|'ve|'m|'ll|'d|[\p{L}]+|[\p{N}]|[^\s\p{L}\p{N}]+",
        unicode: true,
        caseSensitive: false);
  }

  String bpe(String token) {
    if (cache.containsKey(token)) {
      //return cache[token]!;
    }
    List<String> word = token.split('');
    word[word.length - 1] += '</w>';
    Set<List<String>> pairs = getPairs(word);
    if (pairs.isEmpty) return '$token</w>';

    while (true) {
      List<String>? bigram = minBy(pairs, (pair) {
        print(bpeRanks[pair]);
        return bpeRanks[pair] ?? double.maxFinite.toInt();
      });
      if (bigram == null || !bpeRanks.containsKey(bigram)) break;

      List<String> newWord = [];
      int i = 0;
      while (i < word.length) {
        int j = word.indexOf(bigram[0], i);
        if (j == -1) {
          newWord.addAll(word.sublist(i));
          break;
        }
        newWord.addAll(word.sublist(i, j));
        if (j < word.length - 1 &&
            word[j] == bigram[0] &&
            word[j + 1] == bigram[1]) {
          newWord.add(bigram.join(''));
          i = j + 2;
        } else {
          newWord.add(word[j]);
          i = j + 1;
        }
      }
      word = newWord;
      if (word.length == 1) break;
      pairs = getPairs(word);
    }
    String result = word.join(' ');
    cache[token] = result;
    return result;
  }

  List<int> encode(String text) {
    List<int> bpeTokens = [];
    text = whitespaceClean(basicClean(text)).toLowerCase();
    for (var token in pat.allMatches(text).map((m) => m.group(0) ?? '')) {
      String encoded = token.runes.map((r) => byteEncoder[r] ?? '').join();
      print(encoded);
      bpeTokens.addAll(
          bpe(encoded).split(' ').map((bpeToken) => encoder[bpeToken] ?? 0));
      print(bpeTokens);
    }
    return bpeTokens;
  }

  Map<int, String> bytesToUnicode() {
    List<int> bs = [];
    bs.addAll(List.generate(94, (i) => i + 33));
    bs.addAll(List.generate(12, (i) => i + 161));
    bs.addAll(List.generate(32, (i) => i + 174));

    List<int> cs = List.from(bs);
    int n = 0;
    for (int b = 0; b < 256; b++) {
      if (!bs.contains(b)) {
        bs.add(b);
        cs.add(256 + n);
        n++;
      }
    }
    return Map.fromIterables(bs, cs.map((n) => String.fromCharCode(n)));
  }

  Set<List<String>> getPairs(List<String> word) {
    Set<List<String>> pairs = {};
    for (int i = 0; i < word.length - 1; i++) {
      pairs.add([word[i], word[i + 1]]);
    }
    return pairs;
  }

  String basicClean(String text) {
    text = HtmlUnescape().convert(HtmlUnescape().convert(text));
    return text.trim();
  }

  String whitespaceClean(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
