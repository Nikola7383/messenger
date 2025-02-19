import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class SecurityFailure extends Failure {
  const SecurityFailure(String message) : super(message);
}

class EncryptionFailure extends SecurityFailure {
  const EncryptionFailure(String message) : super(message);
}

class DecryptionFailure extends SecurityFailure {
  const DecryptionFailure(String message) : super(message);
}

class IntegrityFailure extends SecurityFailure {
  const IntegrityFailure(String message) : super(message);
}

class StorageFailure extends SecurityFailure {
  const StorageFailure(String message) : super(message);
}

class BackupFailure extends SecurityFailure {
  const BackupFailure(String message) : super(message);
}

class KeyManagementFailure extends SecurityFailure {
  const KeyManagementFailure(String message) : super(message);
} 