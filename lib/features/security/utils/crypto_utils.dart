import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class CryptoUtils {
  static const _uuid = Uuid();
  
  /// Generiše random challenge string
  static String generateChallenge() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = _uuid.v4();
    return '$timestamp:$random';
  }

  /// Kreira hash od podataka
  static String hashData(String data) {
    final bytes = utf8.encode(data);
    return sha256.convert(bytes).toString();
  }

  /// Kreira HMAC od podataka sa ključem
  static String hmacData(String data, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(data)).toString();
  }

  /// Generiše verifikacioni token
  static String generateVerificationToken({
    required String issuer,
    required String target,
    required String type,
    required DateTime expiresAt,
    Map<String, dynamic>? metadata,
  }) {
    final data = {
      'iss': issuer,
      'sub': target,
      'typ': type,
      'exp': expiresAt.millisecondsSinceEpoch,
      'iat': DateTime.now().millisecondsSinceEpoch,
      'jti': _uuid.v4(),
      ...?metadata,
    };
    
    final jsonData = json.encode(data);
    final hash = hashData(jsonData);
    
    return base64Url.encode(utf8.encode('$jsonData.$hash'));
  }

  /// Verifikuje verifikacioni token
  static Map<String, dynamic>? verifyToken(String token) {
    try {
      final decoded = utf8.decode(base64Url.decode(token));
      final parts = decoded.split('.');
      
      if (parts.length != 2) return null;
      
      final jsonData = parts[0];
      final hash = parts[1];
      
      if (hashData(jsonData) != hash) return null;
      
      final data = json.decode(jsonData) as Map<String, dynamic>;
      
      // Proveri expiration
      final exp = DateTime.fromMillisecondsSinceEpoch(data['exp'] as int);
      if (DateTime.now().isAfter(exp)) return null;
      
      return data;
    } catch (e) {
      return null;
    }
  }

  /// Generiše zvučni signal za verifikaciju
  static List<int> generateAudioSignal(String data) {
    // Konvertuj podatke u binarni format
    final binaryData = _stringToBinary(data);
    
    // Generisi FSK (Frequency Shift Keying) signal
    final signal = _generateFskSignal(binaryData);
    
    return signal;
  }

  /// Dekodira zvučni signal
  static String? decodeAudioSignal(List<int> signal) {
    try {
      // Dekodiraj FSK signal u binarni format
      final binaryData = _decodeFskSignal(signal);
      
      // Konvertuj nazad u string
      return _binaryToString(binaryData);
    } catch (e) {
      return null;
    }
  }

  /// Konvertuje string u binarni format
  static List<bool> _stringToBinary(String data) {
    final bytes = utf8.encode(data);
    final binary = <bool>[];
    
    for (final byte in bytes) {
      for (var i = 7; i >= 0; i--) {
        binary.add(((byte >> i) & 1) == 1);
      }
    }
    
    return binary;
  }

  /// Konvertuje binarni format u string
  static String _binaryToString(List<bool> binary) {
    final bytes = <int>[];
    var currentByte = 0;
    var bitPosition = 7;
    
    for (final bit in binary) {
      if (bit) {
        currentByte |= (1 << bitPosition);
      }
      
      if (bitPosition == 0) {
        bytes.add(currentByte);
        currentByte = 0;
        bitPosition = 7;
      } else {
        bitPosition--;
      }
    }
    
    if (bitPosition != 7) {
      bytes.add(currentByte);
    }
    
    return utf8.decode(bytes);
  }

  /// Generise FSK signal
  static List<int> _generateFskSignal(List<bool> binaryData) {
    const sampleRate = 44100;
    const bitsPerSecond = 100;
    const samplesPerBit = sampleRate ~/ bitsPerSecond;
    const frequency0 = 1000; // Hz za 0
    const frequency1 = 2000; // Hz za 1
    
    final signal = <int>[];
    
    for (final bit in binaryData) {
      final frequency = bit ? frequency1 : frequency0;
      
      for (var i = 0; i < samplesPerBit; i++) {
        final t = i / sampleRate;
        final sample = (sin(2 * pi * frequency * t) * 32767).toInt();
        signal.add(sample);
      }
    }
    
    return signal;
  }

  /// Dekodira FSK signal
  static List<bool> _decodeFskSignal(List<int> signal) {
    const sampleRate = 44100;
    const bitsPerSecond = 100;
    const samplesPerBit = sampleRate ~/ bitsPerSecond;
    const frequency0 = 1000;
    const frequency1 = 2000;
    
    final binaryData = <bool>[];
    
    for (var i = 0; i < signal.length; i += samplesPerBit) {
      final samples = signal.sublist(i, i + samplesPerBit);
      
      // Izračunaj energiju na obe frekvencije
      final energy0 = _calculateEnergy(samples, frequency0, sampleRate);
      final energy1 = _calculateEnergy(samples, frequency1, sampleRate);
      
      binaryData.add(energy1 > energy0);
    }
    
    return binaryData;
  }

  /// Računa energiju signala na određenoj frekvenciji
  static double _calculateEnergy(List<int> samples, int frequency, int sampleRate) {
    var energy = 0.0;
    
    for (var i = 0; i < samples.length; i++) {
      final t = i / sampleRate;
      final reference = sin(2 * pi * frequency * t);
      energy += samples[i] * reference;
    }
    
    return energy.abs();
  }
}

/// Matematička konstanta pi
const double pi = 3.141592653589793; 