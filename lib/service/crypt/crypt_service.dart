import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart';
import 'package:wenznote/commons/util/encrypt.dart';
import 'package:wenznote/config/app_constants.dart';
import 'package:wenznote/service/service_manager.dart';
import 'package:ydart/lib0/byte_input_stream.dart';
import 'package:ydart/lib0/byte_output_stream.dart';
import 'package:ydart/utils/encoding_utils.dart';
import 'package:ydart/utils/update_decoder_v2.dart';
import 'package:ydart/utils/update_encoder_v2.dart';

class PasswordInfo {
  int version;
  String password;
  String sha256;

  PasswordInfo({
    required this.version,
    required this.password,
    required this.sha256,
  });

  factory PasswordInfo.fromJson(Map<String, dynamic> json) {
    return PasswordInfo(
      version: json['version'],
      password: json['password'],
      sha256: json['sha256'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'password': password,
      'sha256': sha256,
    };
  }
}

/// 加解密算法，建议使用 kms 算法
class CryptService {
  ServiceManager serviceManager;
  var passwordMap = <int, PasswordInfo>{};

  CryptService(this.serviceManager);

  Future<void> init() async {
    await readPassword();
  }

  Future<void> readPassword() async {
    var uid = serviceManager.userService.currentUser?.id;
    var password = await serviceManager.configManager
        .readConfig("document.password.$uid", "");
    if (password.isEmpty) {
      passwordMap.clear();
    } else {
      passwordMap = json.decode(password).map<int, PasswordInfo>((key, value) {
        return MapEntry(int.parse(key), PasswordInfo.fromJson(value));
      });
    }
  }

  Future<void> savePassword() async {
    var uid = serviceManager.userService.currentUser?.id;
    var password = passwordMap.map((key, value) {
      return MapEntry(key.toString(), value.toJson());
    });
    await serviceManager.configManager
        .saveConfig("document.password.$uid", json.encode(password));
  }

  Future<void> addPassword(PasswordInfo passwordInfo) async {
    passwordMap[passwordInfo.version] = passwordInfo;
    await savePassword();
  }

  PasswordInfo? getCurrentPassword() {
    if (passwordMap.isEmpty) {
      return null;
    }
    return passwordMap[
        passwordMap.keys.reduce((value, element) => max(value, element))];
  }

  bool hasPwd(int version) {
    if (version == -1 && passwordMap.isNotEmpty) {
      version =
          passwordMap.keys.reduce((value, element) => max(value, element));
    }
    var pwd = passwordMap[version]?.password;
    if (pwd == null) {
      return false;
    }
    return true;
  }

  Uint8List encode(Uint8List data, [int version = -1]) {
    if (version == -1 && passwordMap.isNotEmpty) {
      version =
          passwordMap.keys.reduce((value, element) => max(value, element));
    }
    var pwd = passwordMap[version]?.password;
    if (pwd == null) {
      return data;
    }
    var key = Key.fromBase64(pwd);
    var encrypt = Encrypter(AES(key));
    var result =
        encrypt.encryptBytes(data, iv: IV.fromUtf8("1234567890123456"));
    return result.bytes;
  }

  Uint8List decode(Uint8List data, [int version = -1]) {
    if (version == -1 && passwordMap.isNotEmpty) {
      version =
          passwordMap.keys.reduce((value, element) => max(value, element));
    }
    var pwd = passwordMap[version]?.password;
    if (pwd == null) {
      if (version != -1) {
        throw Exception("no password");
      }
      return data;
    }
    var key = Key.fromBase64(pwd);
    var encrypt = Encrypter(AES(key));
    var result = encrypt.decryptBytes(Encrypted(data),
        iv: IV.fromUtf8("1234567890123456"));
    return Uint8List.fromList(result);
  }

  // 根据字符串生成密码
  String generatePassword(String password) {
    final bytes = utf8.encode(password);
    final sha256Str = sha256.convert(bytes);
    return base64Encode(sha256Str.bytes.sublist(0, 32));
  }

  String generateRandomPassword() {
    var text = PasswordGenerator.generateRandomPassword(length: 32);
    return generatePassword(text);
  }

  bool hasPassword() {
    return passwordMap.isNotEmpty;
  }

  String getPasswordSha256(String password) {
    return generatePassword(password);
  }

  Future<bool> changeServerPassword(String password) async {
    if (password.isEmpty) {
      return false;
    }
    try {
      if (base64Decode(password).length != 32) {
        return false;
      }
    } catch (e) {
      return false;
    }
    // 调用用户服务器接口修改密码
    var passwordInfo = PasswordInfo(
      version: passwordMap.length + 1,
      password: password,
      sha256: getPasswordSha256(password),
    );
    var dio = serviceManager.userService.dio;
    var result = await dio.post(
      '${AppConstants.apiUrl}/security/update',
      data: {
        'md5': passwordInfo.sha256,
      },
      options: Options(contentType: "application/json"),
    );
    var data = result.data;
    if (data['msg'] == AppConstants.success) {
      var version = data['data']['securityVersion'];
      passwordInfo.version = version;
      await addPassword(passwordInfo);
      return true;
    }
    return false;
  }

  String? encodeString(String? input, [int version = -1]) {
    if (input == null || input.isEmpty) {
      return input;
    }
    if (!hasPwd(version)) {
      return input;
    }
    var bytes = utf8.encode(input);
    var ret = encode(bytes);
    return base64Encode(ret);
  }

  String? decodeString(String? input, [int version = -1]) {
    if (input == null || input.isEmpty) {
      return input;
    }
    if (!hasPwd(version)) {
      return input;
    }
    var bytes = base64Decode(input);
    var ret = decode(bytes, version);
    return utf8.decode(ret);
  }

  Uint8List decodeDoc(Uint8List fileBytes, [int version = -1]) {
    var encryptInputStream = EncryptByteArrayInputStream(fileBytes, (bytes) {
      return decode(bytes, version);
    });
    var encoder = UpdateEncoderV2(ByteArrayOutputStream(fileBytes.length));
    EncodingUtils.encrypt(UpdateDecoderV2(encryptInputStream), encoder);
    return encoder.toArray();
  }

  Uint8List encodeDoc(Uint8List fileBytes, [int version = -1]) {
    var encryptOutputStream = EncryptByteArrayOutputStream((bytes) {
      return encode(bytes);
    });
    var encoder = UpdateEncoderV2(encryptOutputStream);
    EncodingUtils.encrypt(
        UpdateDecoderV2(ByteArrayInputStream(fileBytes)), encoder);
    return encoder.toArray();
  }

  List<int> getPasswordVersions() {
    return passwordMap.keys.toList();
  }
}

class PasswordGenerator {
  static const _lowercaseLetters = 'abcdefghijklmnopqrstuvwxyz';
  static const _uppercaseLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _digits = '0123456789';
  static const _specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  static final _random = Random();

  static String generateRandomPassword({int length = 12}) {
    const allChars =
        _lowercaseLetters + _uppercaseLetters + _digits + _specialChars;

    return List.generate(
        length, (_) => allChars[_random.nextInt(allChars.length)]).join('');
  }
}
