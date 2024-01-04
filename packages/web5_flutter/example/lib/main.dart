import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:web5_flutter/web5_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final keyManager = SecureStorageKeyManager();
  String _thumbnail = 'Loading...';
  String _publicKey = 'Loading...';
  String _signed = 'Loading...';

  @override
  void initState() {
    super.initState();
    generateFields();
  }

  Future<void> generateFields() async {
    final thumbprint = await keyManager.generatePrivateKey(DsaName.ed25519);
    setState(() {
      _thumbnail = thumbprint;
    });
    final publicKeyJwk = await keyManager.getPublicKey(_thumbnail);
    setState(() {
      _publicKey = publicKeyJwk.toJson().toString();
    });
    final signed =
        await keyManager.sign(_thumbnail, utf8.encode('Hello World!'));
    setState(() {
      _signed = signed.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Web5 Flutter')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thumbnail:',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(_thumbnail),
              const SizedBox(height: 16),
              Text(
                'Public Key:',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(_publicKey),
              const SizedBox(height: 16),
              Text(
                'Signed payload:',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(_signed),
            ],
          ),
        ),
      ),
    );
  }
}
