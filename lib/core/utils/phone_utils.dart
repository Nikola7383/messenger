import 'package:sim_data/sim_data.dart';
import 'package:permission_handler/permission_handler.dart';

class PhoneUtils {
  /// Proverava da li je broj telefona validan
  static bool isValidPhoneNumber(String phone) {
    // Regex za srpske brojeve telefona
    final regex = RegExp(r'^\+381[0-9]{8,9}$');
    return regex.hasMatch(phone);
  }

  /// Proverava da li se broj podudara sa SIM karticom
  static Future<bool> matchesSimCard(String phone) async {
    try {
      // Proveri dozvole
      final status = await Permission.phone.request();
      if (!status.isGranted) {
        return false;
      }

      // Učitaj podatke o SIM kartici
      final simData = await SimDataPlugin.getSimData();
      
      if (simData.cards.isEmpty) {
        return false;
      }

      // Normalizuj brojeve za poređenje
      final normalizedInput = _normalizePhoneNumber(phone);
      
      // Proveri da li se broj podudara sa bilo kojom SIM karticom
      for (final card in simData.cards) {
        final simPhone = card.phoneNumber;
        if (simPhone == null || simPhone.isEmpty) {
          continue;
        }

        final normalizedSim = _normalizePhoneNumber(simPhone);
        if (normalizedInput == normalizedSim) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Normalizuje broj telefona za poređenje
  static String _normalizePhoneNumber(String phone) {
    // Ukloni sve osim brojeva
    final numbers = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Ako počinje sa 0, dodaj +381
    if (numbers.startsWith('0')) {
      return '+381${numbers.substring(1)}';
    }
    
    // Ako počinje sa 381, dodaj +
    if (numbers.startsWith('381')) {
      return '+$numbers';
    }
    
    // Ako je već u +381 formatu, vrati kao je
    if (numbers.startsWith('+381')) {
      return numbers;
    }
    
    // Ako je samo broj bez prefiksa, dodaj +381
    return '+381$numbers';
  }

  /// Formatira broj telefona za prikaz
  static String formatPhoneNumber(String phone) {
    final normalized = _normalizePhoneNumber(phone);
    
    // Format: +381 6X XXX-XXX
    final regex = RegExp(r'^\+381(\d{2})(\d{3})(\d{3,4})$');
    final match = regex.firstMatch(normalized);
    
    if (match != null) {
      return '+381 ${match.group(1)} ${match.group(2)}-${match.group(3)}';
    }
    
    return phone;
  }

  /// Proverava da li uređaj ima SIM karticu
  static Future<bool> hasSimCard() async {
    try {
      final simData = await SimDataPlugin.getSimData();
      return simData.cards.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Vraća broj aktivne SIM kartice
  static Future<String?> getActiveSimNumber() async {
    try {
      final simData = await SimDataPlugin.getSimData();
      if (simData.cards.isEmpty) {
        return null;
      }

      // Uzmi prvu aktivnu SIM karticu
      final activeCard = simData.cards.firstWhere(
        (card) => card.isDataRoaming || !card.isNetworkRoaming,
        orElse: () => simData.cards.first,
      );

      return activeCard.phoneNumber;
    } catch (e) {
      return null;
    }
  }

  /// Proverava da li je broj u romingu
  static Future<bool> isRoaming() async {
    try {
      final simData = await SimDataPlugin.getSimData();
      if (simData.cards.isEmpty) {
        return false;
      }

      // Proveri da li je bilo koja kartica u romingu
      return simData.cards.any((card) => 
        card.isDataRoaming || card.isNetworkRoaming
      );
    } catch (e) {
      return false;
    }
  }
} 