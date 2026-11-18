import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class SecureStorageHelper {
  static const storage = FlutterSecureStorage();

  final key = encrypt.Key.fromUtf8('1234567890123456');
  final iv = encrypt.IV.fromLength(16);

  String encryptData(String data) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.encrypt(data, iv: iv).base64;
  }

  String decryptData(String encryptedData) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.decrypt64(encryptedData, iv: iv);
  }

  Future<void> storeData(String key, String value) async {
    String encryptedValue = encryptData(value);
    await storage.write(key: key, value: encryptedValue);
  }

  Future<String?> retrieveData(String key) async {
    String? encryptedValue = await storage.read(key: key);
    if (encryptedValue != null) {
      return decryptData(encryptedValue);
    }
    return null;
  }

  Future<void> deleteData(String key) async {
    await storage.delete(key: key);
  }
}
