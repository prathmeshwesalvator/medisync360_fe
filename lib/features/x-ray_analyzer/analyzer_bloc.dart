// xray_analyzer_bloc.dart
// ─────────────────────────────────────────────────────────────────────────────
// BLoC: Events, States, and Bloc for X-Ray Analyzer
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/x-ray_analyzer/analyzer_datasource.dart';

// ══════════════════════════════════════════════════════════════════════════════
// EVENTS
// ══════════════════════════════════════════════════════════════════════════════

abstract class XRayAnalyzerEvent extends Equatable {
  const XRayAnalyzerEvent();

  @override
  List<Object?> get props => [];
}

/// User picked an image from gallery/camera
class XRayImageSelected extends XRayAnalyzerEvent {
  final File imageFile;
  const XRayImageSelected(this.imageFile);

  @override
  List<Object?> get props => [imageFile.path];
}

/// User taps "Analyze" button — triggers guard + full analysis
class XRayAnalyzeRequested extends XRayAnalyzerEvent {
  const XRayAnalyzeRequested();
}

/// User submits a chat message in the Q&A tab
class XRayChatMessageSent extends XRayAnalyzerEvent {
  final String message;
  const XRayChatMessageSent(this.message);

  @override
  List<Object?> get props => [message];
}

/// User resets — clears image and results
class XRayAnalyzerReset extends XRayAnalyzerEvent {
  const XRayAnalyzerReset();
}

// ══════════════════════════════════════════════════════════════════════════════
// STATES
// ══════════════════════════════════════════════════════════════════════════════

abstract class XRayAnalyzerState extends Equatable {
  const XRayAnalyzerState();

  @override
  List<Object?> get props => [];
}

/// Nothing uploaded yet
class XRayInitial extends XRayAnalyzerState {
  const XRayInitial();
}

/// Image is selected but not yet analyzed
class XRayImageReady extends XRayAnalyzerState {
  final File imageFile;
  const XRayImageReady(this.imageFile);

  @override
  List<Object?> get props => [imageFile.path];
}

/// Running the guard check
class XRayGuardChecking extends XRayAnalyzerState {
  final File imageFile;
  const XRayGuardChecking(this.imageFile);

  @override
  List<Object?> get props => [imageFile.path];
}

/// Guard rejected — not a chest X-ray
class XRayGuardRejected extends XRayAnalyzerState {
  final File imageFile;
  final String reason;
  const XRayGuardRejected({required this.imageFile, required this.reason});

  @override
  List<Object?> get props => [imageFile.path, reason];
}

/// Guard passed, now running full analysis
class XRayAnalyzing extends XRayAnalyzerState {
  final File imageFile;
  const XRayAnalyzing(this.imageFile);

  @override
  List<Object?> get props => [imageFile.path];
}

/// Full analysis complete
class XRayAnalysisSuccess extends XRayAnalyzerState {
  final File imageFile;
  final XRayAnalysisResult result;
  final List<ChatMessage> chatHistory;
  final bool isChatLoading;

  const XRayAnalysisSuccess({
    required this.imageFile,
    required this.result,
    this.chatHistory = const [],
    this.isChatLoading = false,
  });

  XRayAnalysisSuccess copyWith({
    File? imageFile,
    XRayAnalysisResult? result,
    List<ChatMessage>? chatHistory,
    bool? isChatLoading,
  }) =>
      XRayAnalysisSuccess(
        imageFile: imageFile ?? this.imageFile,
        result: result ?? this.result,
        chatHistory: chatHistory ?? this.chatHistory,
        isChatLoading: isChatLoading ?? this.isChatLoading,
      );

  @override
  List<Object?> get props => [
        imageFile.path,
        result,
        chatHistory,
        isChatLoading,
      ];
}

/// Any error (API, parsing, network)
class XRayAnalysisError extends XRayAnalyzerState {
  final String message;
  final File? imageFile; // keep image visible so user can retry
  const XRayAnalysisError({required this.message, this.imageFile});

  @override
  List<Object?> get props => [message, imageFile?.path];
}

// ── Chat message model ────────────────────────────────────────────────────────

class ChatMessage extends Equatable {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [role, content, timestamp];
}

// ══════════════════════════════════════════════════════════════════════════════
// BLOC
// ══════════════════════════════════════════════════════════════════════════════

class XRayAnalyzerBloc extends Bloc<XRayAnalyzerEvent, XRayAnalyzerState> {
  final XRayAnalyzerDataSource _dataSource;

  XRayAnalyzerBloc({XRayAnalyzerDataSource? dataSource})
      : _dataSource = dataSource ?? XRayAnalyzerDataSource(),
        super(const XRayInitial()) {
    on<XRayImageSelected>(_onImageSelected);
    on<XRayAnalyzeRequested>(_onAnalyzeRequested);
    on<XRayChatMessageSent>(_onChatMessageSent);
    on<XRayAnalyzerReset>(_onReset);
  }

  // ── Image Selected ─────────────────────────────────────────────────────────

  void _onImageSelected(
    XRayImageSelected event,
    Emitter<XRayAnalyzerState> emit,
  ) {
    emit(XRayImageReady(event.imageFile));
  }

  // ── Analyze Requested ─────────────────────────────────────────────────────

  Future<void> _onAnalyzeRequested(
    XRayAnalyzeRequested event,
    Emitter<XRayAnalyzerState> emit,
  ) async {
    // Must have an image loaded
    final currentState = state;
    File? imageFile;

    if (currentState is XRayImageReady) {
      imageFile = currentState.imageFile;
    } else if (currentState is XRayGuardRejected) {
      imageFile = currentState.imageFile;
    } else if (currentState is XRayAnalysisError && currentState.imageFile != null) {
      imageFile = currentState.imageFile!;
    } else {
      return;
    }

    // Step 1: Guard check
    emit(XRayGuardChecking(imageFile));

    try {
      final guard = await _dataSource.checkIsChestXRay(imageFile);

      if (!guard.isChestXRay) {
        emit(XRayGuardRejected(imageFile: imageFile, reason: guard.reason));
        return;
      }

      // Step 2: Full analysis
      emit(XRayAnalyzing(imageFile));

      final result = await _dataSource.analyzeXRay(imageFile);

      emit(XRayAnalysisSuccess(
        imageFile: imageFile,
        result: result,
        chatHistory: const [],
        isChatLoading: false,
      ));
    } on NotAChestXRayException catch (e) {
      emit(XRayGuardRejected(imageFile: imageFile, reason: e.reason));
    } on XRayApiException catch (e) {
      emit(XRayAnalysisError(
        message: 'API Error: ${e.message}',
        imageFile: imageFile,
      ));
    } catch (e) {
      emit(XRayAnalysisError(
        message: 'Unexpected error: $e',
        imageFile: imageFile,
      ));
    }
  }

  // ── Chat Message Sent ─────────────────────────────────────────────────────

  Future<void> _onChatMessageSent(
    XRayChatMessageSent event,
    Emitter<XRayAnalyzerState> emit,
  ) async {
    final currentState = state;
    if (currentState is! XRayAnalysisSuccess) return;

    // Append user message and show loading
    final userMsg = ChatMessage(role: 'user', content: event.message);
    final updatedHistory = [...currentState.chatHistory, userMsg];

    emit(currentState.copyWith(
      chatHistory: updatedHistory,
      isChatLoading: true,
    ));

    try {
      // Build history in the format the datasource expects (skip last user msg)
      final historyForApi = currentState.chatHistory
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final reply = await _dataSource.chatAboutXRay(
        imageFile: currentState.imageFile,
        chatHistory: historyForApi,
        userMessage: event.message,
      );

      final assistantMsg = ChatMessage(role: 'assistant', content: reply);
      emit(currentState.copyWith(
        chatHistory: [...updatedHistory, assistantMsg],
        isChatLoading: false,
      ));
    } on XRayApiException catch (e) {
      final errorMsg = ChatMessage(
        role: 'assistant',
        content: '⚠️ Error: ${e.message}. Please try again.',
      );
      emit(currentState.copyWith(
        chatHistory: [...updatedHistory, errorMsg],
        isChatLoading: false,
      ));
    } catch (e) {
      final errorMsg = ChatMessage(
        role: 'assistant',
        content: '⚠️ Something went wrong. Please try again.',
      );
      emit(currentState.copyWith(
        chatHistory: [...updatedHistory, errorMsg],
        isChatLoading: false,
      ));
    }
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  void _onReset(
    XRayAnalyzerReset event,
    Emitter<XRayAnalyzerState> emit,
  ) {
    emit(const XRayInitial());
  }
}