/// Represents an encoded JWT, including its encoded header, payload,
/// and signature.
class EncodedJwt {
  final String? header;
  final String? payload;
  final String? signature;

  EncodedJwt({required this.header, required this.payload, this.signature});

  factory EncodedJwt.fromJson(Map<String, dynamic> json) {
    return EncodedJwt(
      header: json['header'],
      payload: json['payload'],
      signature: json['signature'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'header': header,
      'payload': payload,
      'signature': signature,
    };
  }
}
