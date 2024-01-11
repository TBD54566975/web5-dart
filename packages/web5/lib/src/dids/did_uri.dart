/// The `DidUri` class represents a Decentralized Identifier (DID) URI.
///
/// This class provides a way to parse and handle these URIs according to the
/// specifications defined by the W3C DID Core specification.
///
/// The class contains several RegExp patterns to validate different components
/// of a DID URI such as the:
///  * method,
///  * method ID
///  * parameters
///  * path
///  * query
///  * fragment.
///
/// **Usage**:
/// To parse a DID URI, use the `parse` method. It validates the input string
/// against the DID URI pattern and, if valid, returns an instance of `DidUri`.
/// If the input is invalid, it throws an exception.
///
/// Example:
/// ```dart
/// try {
///   var didUri = DidUri.parse('did:example:123456/path?query#fragment');
///   print(didUri.method); // example
/// } on Exception catch (e) {
///   print('Failed to parse DID URI: ${e.toString()}');
/// }
/// ```
///
/// **Note**
/// This class does not perform resolution of DID URIs; it only supports
/// parsing and basic validation.
class DidUri {
  static final String pctEncodedPattern = r'(?:%[0-9a-fA-F]{2})';
  static final String idCharPattern = '(?:[a-zA-Z0-9._-]|$pctEncodedPattern)';
  static final String methodPattern = '([a-z0-9]+)';
  static final String methodIdPattern =
      '((?:$idCharPattern*:)*($idCharPattern+))';
  static final String paramCharPattern = '[a-zA-Z0-9_.:%-]';
  static final String paramPattern = ';$paramCharPattern+=$paramCharPattern*';
  static final String paramsPattern = '(($paramPattern)*)';
  static final String pathPattern = r'(/[^#?]*)?';
  static final String queryPattern = r'(\?[^\#]*)?';
  static final String fragmentPattern = r'(\#.*)?';
  static final RegExp didUriPattern = RegExp(
    '^did:$methodPattern:$methodIdPattern$paramsPattern$pathPattern$queryPattern$fragmentPattern\$',
  );

  /// The complete DID URI.
  String uri;

  /// The method specified in the DID URI e.g. jwk, dht, key etc.
  String method;

  /// The identifier part of the DID URI
  String id;

  /// Optional parameters in the DID URI.
  Map<String, String>? params;

  /// Optional path component of the DID URI.
  String? path;

  /// Optional query component of the DID URI.
  String? query;

  /// Optional fragment component of the DID URI.
  String? fragment;

  DidUri({
    required this.uri,
    required this.method,
    required this.id,
    this.params,
    this.path,
    this.query,
    this.fragment,
  });

  /// parses a DID URI in accordance to the ABNF rules specified in the
  /// specification [here](https://www.w3.org/TR/did-core/#did-syntax). Returns
  /// a [DidUri] instance if parsing is successful. Throws [Exception] if
  /// parsing fails.
  static DidUri parse(String input) {
    final match = didUriPattern.firstMatch(input);

    if (match == null) {
      throw Exception('Invalid DID URI');
    }

    final [
      methodMatch,
      idMatch,
      paramsMatch,
      pathMatch,
      queryMatch,
      fragmentMatch
    ] = match.groups([1, 2, 4, 6, 7, 8]);

    final didUri = DidUri(
      uri: 'did:$methodMatch:$idMatch',
      method: methodMatch!,
      id: idMatch!,
    );

    if (paramsMatch!.isNotEmpty) {
      final params = paramsMatch.substring(1).split(';');
      final Map<String, String> parsedParams = {};
      for (final p in params) {
        final kv = p.split('=');
        parsedParams[kv[0]] = kv[1];
      }
      didUri.params = parsedParams;
    }

    if (pathMatch != null) didUri.path = pathMatch;
    if (queryMatch != null) didUri.query = queryMatch.substring(1);
    if (fragmentMatch != null) didUri.fragment = fragmentMatch.substring(1);

    return didUri;
  }
}
