import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:test/test.dart';
import 'package:web5/src/dids/did_dht/dns/packet.dart';
import 'package:web5/src/dids/did_dht/dns/txt_data.dart';

void main() {
  group('DNS Packet', () {
    test('should encode/decode dns packet', () {
      final vector = hex.decode(
        '000084000000000500000000035f6b30045f6469643435636168636668337a683862716435636e337936696e6f656131623364366b683835726a6b736e65396535646379726331657279000010000100001c2000373669643d303b743d303b6b3d327a484746356d5f4468635062425a42366f6f4978494f522d56772d794a565953506f324e67434d6b6767035f6b31045f6469643435636168636668337a683862716435636e337936696e6f656131623364366b683835726a6b736e65396535646379726331657279000010000100001c2000393869643d7369673b743d303b6b3d4672724268717641577845346c73746a2d4957674e385f352d4f344c314b755a6a644e6a6e3562585f6477035f6b32045f6469643435636168636668337a683862716435636e337936696e6f656131623364366b683835726a6b736e65396535646379726331657279000010000100001c2000656469643d656e633b743d313b6b3d4248746636516c6d634350584d5861364c565369455f4c652d59725a4e746c354b5770517a386536566157453563416c426d6e7a7a7577524e7546744c6879464e64793976317256457145677246456969774b4d783549035f7330045f6469643435636168636668337a683862716435636e337936696e6f656131623364366b683835726a6b736e65396535646379726331657279000010000100001c20004e4d69643d64776e3b743d446563656e7472616c697a65645765624e6f64653b73653d68747470733a2f2f6578616d706c652e636f6d2f64776e3b656e633d23656e633b7369673d237369672c2330045f6469643435636168636668337a683862716435636e337936696e6f656131623364366b683835726a6b736e65396535646379726331657279000010000100001c20004140763d303b766d3d6b302c6b312c6b323b617574683d6b302c6b313b61736d3d6b302c6b313b61676d3d6b323b64656c3d6b303b696e763d6b303b7376633d7330',
      );
      final dnsPacket = PacketCodec.decode(Uint8List.fromList(vector));

      expect(dnsPacket.value.header.numQuestions, 0);
      expect(dnsPacket.value.header.numAnswers, 5);
      expect(dnsPacket.value.header.numAuthorities, 0);
      expect(dnsPacket.value.header.numAdditionals, 0);

      for (final record in dnsPacket.value.answers) {
        if (record.name.value.startsWith('_s')) {
          final txtData = record.data as TxtData;
          expect(
            txtData.value.contains(
              'id=dwn;t=DecentralizedWebNode;se=https://example.com/dwn;enc=#enc;sig=#sig,#0',
            ),
            isTrue,
          );
        }
      }
    });
  });
}
