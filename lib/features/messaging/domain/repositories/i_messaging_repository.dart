import 'package:dartz/dartz.dart';
import 'package:glasnik/core/error/failures.dart';
import 'package:glasnik/features/messaging/domain/entities/conversation.dart';
import 'package:glasnik/features/messaging/domain/entities/message.dart';

abstract class IMessagingRepository {
  // Konverzacije
  Future<Either<Failure, List<Conversation>>> getConversations();
  Future<Either<Failure, Conversation>> getConversation(String id);
  Future<Either<Failure, Conversation>> createConversation(Conversation conversation);
  Future<Either<Failure, Unit>> deleteConversation(String id);
  Future<Either<Failure, Unit>> updateConversation(Conversation conversation);
  
  // Poruke
  Future<Either<Failure, List<Message>>> getMessages(String conversationId);
  Future<Either<Failure, Message>> sendMessage(Message message);
  Future<Either<Failure, Unit>> deleteMessage(String messageId);
  Future<Either<Failure, Unit>> updateMessageStatus(String messageId, MessageStatus status);
  
  // E2E Enkripcija
  Future<Either<Failure, String>> generateEncryptionKey();
  Future<Either<Failure, Unit>> exchangeKeys(String userId, String publicKey);
  Future<Either<Failure, String>> encryptMessage(String message, String key);
  Future<Either<Failure, String>> decryptMessage(String encryptedMessage, String key);
  
  // Message Routing
  Future<Either<Failure, Unit>> relayMessage(Message message);
  Future<Either<Failure, List<String>>> getOptimalRoute(String targetUserId);
  Future<Either<Failure, Unit>> pruneExpiredMessages();
  
  // Storage
  Future<Either<Failure, Unit>> saveMessageLocally(Message message);
  Future<Either<Failure, Unit>> syncMessages(String conversationId);
  Future<Either<Failure, Unit>> clearLocalStorage();
  
  // Streams
  Stream<List<Conversation>> watchConversations();
  Stream<List<Message>> watchMessages(String conversationId);
  Stream<Message> watchIncomingMessages();
} 