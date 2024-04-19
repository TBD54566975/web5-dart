import 'dart:typed_data';

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
  /// The public key bytes of the Identity Key, which serves as the identifier
  /// in the DHT network for the corresponding BEP44 message.
  Uint8List k;

  /// The sequence number of the message, used to ensure the latest version of
  /// the data is retrieved and updated. It's a monotonically increasing number.
  int seq;

  /// The signature of the message, ensuring the authenticity and integrity
  /// of the data. It's computed over the bencoded sequence number and value.
  Uint8List sig;

  /// The actual data being stored or retrieved from the DHT network, typically
  /// encoded in a format suitable for DNS packet representation of a DID Document.
  Uint8List v;

  Bep44Message({
    required this.k,
    required this.seq,
    required this.sig,
    required this.v,
  });
}
