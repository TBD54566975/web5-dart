class DsaAlias {
  String? algorithm;
  String? curve;

  DsaAlias({this.algorithm, this.curve});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DsaAlias &&
        other.algorithm == algorithm &&
        other.curve == curve;
  }

  @override
  int get hashCode => algorithm.hashCode ^ curve.hashCode;
}
