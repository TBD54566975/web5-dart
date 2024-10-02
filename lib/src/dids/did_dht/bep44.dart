import 'dart:typed_data';
import 'package:web5/src/crypto.dart';
import 'package:web5/src/dids/did_dht/bencoder.dart';

typedef Signer = Future<Uint8List> Function(Uint8List payload);

/// Represents a BEP44 message, which is used for storing and retrieving data
/// in the Mainline DHT network.
///
/// A BEP44 message is used primarily in the context of the DID DHT method
/// for publishing and resolving DID documents in the DHT network. This type
/// encapsulates the data structure required for such operations in accordance
/// with BEP44.
///
/// See [BEP44 Specification](https://www.bittorrent.org/beps/bep_0044.html)
class Bep44Message {
  static Future<Uint8List> create(
    Uint8List message,
    int seq,
    Signer sign,
  ) async {
    final toSign = BytesBuilder(copy: false);
    toSign.add(Bencoder.encode('seq'));
    toSign.add(Bencoder.encode(seq));
    toSign.add(Bencoder.encode('v'));
    toSign.add(Bencoder.encode(message));

    final sig = await sign(toSign.toBytes());

    // The sequence number needs to be converted to a big-endian byte array.
    final bigSeq = BigInt.from(seq);
    final seqBytes = _bigIntToBytes(bigSeq);
    final encoded = BytesBuilder(copy: false);

    encoded.add(sig);
    encoded.add(seqBytes);
    encoded.add(message);

    return encoded.toBytes();
  }

  static DecodedBep44Message decode(Uint8List bytes) {
    if (bytes.length < 72) {
      throw FormatException(
        'Response must be at least 72 bytes but got: ${bytes.length}',
      );
    }

    if (bytes.length > 1072) {
      throw FormatException(
        'Response is larger than 1072 bytes, got: ${bytes.length}',
      );
    }

    final sig = bytes.sublist(0, 64);
    final seqBytes = bytes.sublist(64, 72);
    final bigSeq = _bytesToBigInt(seqBytes);
    final seq = bigSeq.toInt();
    final v = bytes.sublist(72);

    return DecodedBep44Message(seq: seq, sig: sig, v: v);
  }

  static DecodedBep44Message verify(Uint8List input, Uint8List publicKey) {
    final message = decode(input);
    message.verify(publicKey);

    return message;
  }

  static Uint8List _bigIntToBytes(BigInt bigInt) {
    final byteArray = bigInt.toRadixString(16).padLeft(16, '0');
    return Uint8List.fromList(
      List<int>.generate(8, (i) {
        final byteString = byteArray.substring(i * 2, i * 2 + 2);
        return int.parse(byteString, radix: 16);
      }),
    );
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    var hexString = '';
    for (final byte in bytes) {
      hexString += byte.toRadixString(16).padLeft(2, '0');
    }
    return BigInt.parse(hexString, radix: 16);
  }
}

class DecodedBep44Message {
  /// The sequence number of the message, used to ensure the latest version of
  /// the data is retrieved and updated. It's a monotonically increasing number.
  int seq;

  /// The signature of the message, ensuring the authenticity and integrity
  /// of the data. It's computed over the bencoded sequence number and value.
  Uint8List sig;

  /// The actual data being stored or retrieved from the DHT network, typically
  /// encoded in a format suitable for DNS packet representation of a DID Document.
  Uint8List v;

  DecodedBep44Message({
    required this.seq,
    required this.sig,
    required this.v,
  });

  void verify(Uint8List publicKey) async {
    final toSign = BytesBuilder(copy: false);
    toSign.add(Bencoder.encode('seq'));
    toSign.add(Bencoder.encode(seq));
    toSign.add(Bencoder.encode('v'));
    toSign.add(Bencoder.encode(v));

    final jwk = Crypto.bytesToPublicKey(AlgorithmId.ed25519, publicKey);

    await Ed25519.verify(jwk, toSign.toBytes(), sig);
  }
}
