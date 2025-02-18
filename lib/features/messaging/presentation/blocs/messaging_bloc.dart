import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:glasnik/features/messaging/domain/entities/conversation.dart';
import 'package:glasnik/features/messaging/domain/entities/message.dart';
import 'package:glasnik/features/messaging/domain/repositories/i_messaging_repository.dart';

// Events
abstract class MessagingEvent extends Equatable {
  const MessagingEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends MessagingEvent {}

class LoadMessages extends MessagingEvent {
  final String conversationId;
  const LoadMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SendMessage extends MessagingEvent {
  final Message message;
  const SendMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class CreateConversation extends MessagingEvent {
  final Conversation conversation;
  const CreateConversation(this.conversation);

  @override
  List<Object?> get props => [conversation];
}

class DeleteConversation extends MessagingEvent {
  final String conversationId;
  const DeleteConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class MessageReceived extends MessagingEvent {
  final Message message;
  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class UpdateMessageStatus extends MessagingEvent {
  final String messageId;
  final MessageStatus status;
  const UpdateMessageStatus(this.messageId, this.status);

  @override
  List<Object?> get props => [messageId, status];
}

// State
class MessagingState extends Equatable {
  final List<Conversation> conversations;
  final Map<String, List<Message>> messages;
  final bool isLoading;
  final String? error;
  final String? activeConversationId;

  const MessagingState({
    this.conversations = const [],
    this.messages = const {},
    this.isLoading = false,
    this.error,
    this.activeConversationId,
  });

  MessagingState copyWith({
    List<Conversation>? conversations,
    Map<String, List<Message>>? messages,
    bool? isLoading,
    String? error,
    String? activeConversationId,
  }) {
    return MessagingState(
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeConversationId: activeConversationId ?? this.activeConversationId,
    );
  }

  @override
  List<Object?> get props => [
    conversations,
    messages,
    isLoading,
    error,
    activeConversationId,
  ];
}

// Bloc
class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final IMessagingRepository _repository;
  StreamSubscription? _conversationsSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _incomingMessagesSubscription;

  MessagingBloc(this._repository) : super(const MessagingState()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<CreateConversation>(_onCreateConversation);
    on<DeleteConversation>(_onDeleteConversation);
    on<MessageReceived>(_onMessageReceived);
    on<UpdateMessageStatus>(_onUpdateMessageStatus);

    // Inicijalizacija stream subscriptions
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    _conversationsSubscription?.cancel();
    _conversationsSubscription = _repository.watchConversations().listen(
      (conversations) {
        add(LoadConversations());
      },
    );

    _incomingMessagesSubscription?.cancel();
    _incomingMessagesSubscription = _repository.watchIncomingMessages().listen(
      (message) {
        add(MessageReceived(message));
      },
    );
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    
    final result = await _repository.getConversations();
    
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.toString(),
      )),
      (conversations) => emit(state.copyWith(
        isLoading: false,
        conversations: conversations,
        error: null,
      )),
    );
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      activeConversationId: event.conversationId,
    ));
    
    // Otkaži prethodni subscription ako postoji
    _messagesSubscription?.cancel();
    
    // Pretplati se na nove poruke
    _messagesSubscription = _repository
      .watchMessages(event.conversationId)
      .listen((messages) {
        add(LoadMessages(event.conversationId));
      });
    
    final result = await _repository.getMessages(event.conversationId);
    
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.toString(),
      )),
      (messages) {
        final newMessages = Map<String, List<Message>>.from(state.messages);
        newMessages[event.conversationId] = messages;
        
        emit(state.copyWith(
          isLoading: false,
          messages: newMessages,
          error: null,
        ));
      },
    );
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<MessagingState> emit,
  ) async {
    final result = await _repository.sendMessage(event.message);
    
    result.fold(
      (failure) => emit(state.copyWith(error: failure.toString())),
      (message) {
        final conversationId = message.receiverId!;
        final newMessages = Map<String, List<Message>>.from(state.messages);
        
        if (newMessages.containsKey(conversationId)) {
          newMessages[conversationId] = [
            ...newMessages[conversationId]!,
            message,
          ];
          
          emit(state.copyWith(
            messages: newMessages,
            error: null,
          ));
        }
      },
    );
  }

  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    
    final result = await _repository.createConversation(event.conversation);
    
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.toString(),
      )),
      (conversation) {
        final newConversations = [...state.conversations, conversation];
        emit(state.copyWith(
          isLoading: false,
          conversations: newConversations,
          error: null,
        ));
      },
    );
  }

  Future<void> _onDeleteConversation(
    DeleteConversation event,
    Emitter<MessagingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    
    final result = await _repository.deleteConversation(event.conversationId);
    
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.toString(),
      )),
      (_) {
        final newConversations = state.conversations
          .where((c) => c.id != event.conversationId)
          .toList();
          
        final newMessages = Map<String, List<Message>>.from(state.messages)
          ..remove(event.conversationId);
          
        emit(state.copyWith(
          isLoading: false,
          conversations: newConversations,
          messages: newMessages,
          error: null,
        ));
      },
    );
  }

  Future<void> _onMessageReceived(
    MessageReceived event,
    Emitter<MessagingState> emit,
  ) async {
    final message = event.message;
    final conversationId = message.receiverId!;
    
    if (state.messages.containsKey(conversationId)) {
      final newMessages = Map<String, List<Message>>.from(state.messages);
      newMessages[conversationId] = [
        ...newMessages[conversationId]!,
        message,
      ];
      
      emit(state.copyWith(
        messages: newMessages,
        error: null,
      ));
    }
    
    // Ažuriraj status poruke
    await _repository.updateMessageStatus(
      message.id,
      MessageStatus.delivered,
    );
  }

  Future<void> _onUpdateMessageStatus(
    UpdateMessageStatus event,
    Emitter<MessagingState> emit,
  ) async {
    final result = await _repository.updateMessageStatus(
      event.messageId,
      event.status,
    );
    
    result.fold(
      (failure) => emit(state.copyWith(error: failure.toString())),
      (_) {
        // Ažuriraj status poruke u state-u
        final newMessages = Map<String, List<Message>>.from(state.messages);
        
        for (final conversationId in newMessages.keys) {
          newMessages[conversationId] = newMessages[conversationId]!.map(
            (message) => message.id == event.messageId
              ? message.copyWith(status: event.status)
              : message,
          ).toList();
        }
        
        emit(state.copyWith(
          messages: newMessages,
          error: null,
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _conversationsSubscription?.cancel();
    _messagesSubscription?.cancel();
    _incomingMessagesSubscription?.cancel();
    return super.close();
  }
} 