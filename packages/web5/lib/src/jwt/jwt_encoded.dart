/// Represents an encoded JWT, including its encoded header, payload,
/// and signature.
class JwtEncoded {
  final String? header;
  final String? payload;
  final String? signature;

  JwtEncoded({required this.header, required this.payload, this.signature});

  factory JwtEncoded.fromJson(Map<String, dynamic> json) {
    return JwtEncoded(
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
