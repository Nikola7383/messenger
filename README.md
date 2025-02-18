# Glasnik

Glasnik je decentralizovana mesh komunikaciona aplikacija koja omogućava sigurnu razmenu poruka bez oslanjanja na centralni server. Aplikacija koristi Bluetooth Low Energy (BLE) za P2P komunikaciju i implementira napredne sigurnosne mehanizme.

## Funkcionalnosti

### Mesh Networking
- P2P komunikacija preko BLE
- Automatsko rutiranje poruka
- Mesh network formiranje
- Optimizovana potrošnja baterije

### Verifikacioni Sistem
- QR kod verifikacija
- Zvučna verifikacija
- Verifikacioni lanci
- Hijerarhija uloga

### Messaging
- End-to-end enkripcija
- Offline messaging
- Message routing
- Message prioritization

### Sigurnost
- Forward secrecy
- Digitalni potpisi
- Secure storage
- Tamper detection

## Tehnički Zahtevi

### Sistemski Zahtevi
- Flutter ≥ 3.0.0
- Dart ≥ 3.0.0
- Android 6.0 (API level 23) ili noviji
- iOS 12.0 ili noviji
- BLE 4.0+ podrška

### Zavisnosti
- flutter_blue_plus: ^1.35.3
- flutter_bloc: ^8.1.6
- cryptography: ^2.7.0
- hive: ^2.2.3
- nearby_connections: ^4.2.0

## Instalacija

1. Klonirajte repozitorijum:
```bash
git clone https://github.com/Nikola7383/messenger.git
```

2. Instalirajte zavisnosti:
```bash
flutter pub get
```

3. Pokrenite aplikaciju:
```bash
flutter run
```

## Arhitektura

Aplikacija koristi Clean Architecture sa sledećim slojevima:

```
lib/
├── core/
│   ├── error/
│   ├── router/
│   └── theme/
├── features/
│   ├── auth/
│   ├── messaging/
│   ├── network/
│   └── security/
└── main.dart
```

### Ključne Komponente
- **Network Layer**: Implementira BLE komunikaciju i mesh networking
- **Security Layer**: Upravlja enkripcijom i verifikacijom
- **Messaging Layer**: Hendluje razmenu poruka i rutiranje
- **Auth Layer**: Upravlja ulogama i verifikacijom korisnika

## Sigurnosne Napomene

- Aplikacija je dizajnirana za offline komunikaciju
- Svi podaci se čuvaju lokalno u enkriptovanom formatu
- Poruke su end-to-end enkriptovane
- Implementiran je sistem za detekciju tampering-a

## Doprinos Projektu

1. Fork-ujte repozitorijum
2. Kreirajte feature branch (`git checkout -b feature/amazing-feature`)
3. Commit-ujte promene (`git commit -m 'Add some amazing feature'`)
4. Push-ujte na branch (`git push origin feature/amazing-feature`)
5. Otvorite Pull Request

## Licenca

Ovaj projekat je licenciran pod MIT licencom - pogledajte [LICENSE](LICENSE) fajl za detalje.

## Kontakt

Nikola Jovanović - nikola@example.com

Project Link: [https://github.com/Nikola7383/messenger](https://github.com/Nikola7383/messenger)
