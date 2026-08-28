import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../services/backend_api.dart';

String userMessageForError(Object error) {
  // BackendApiException carries a status code + already-safe message.
  if (error is BackendApiException) {
    return _messageForStatus(error.statusCode, error.message);
  }

  // Network-level failures.
  if (error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException) {
    return 'No internet connection. Check your connection and try again.';
  }

  // Fallback: never leak internals.
  return 'Something went wrong. Please try again.';
}

String _messageForStatus(int statusCode, String fallback) {
  switch (statusCode) {
    case 401:
      return 'Your session has ended. Please sign in again.';
    case 403:
      return "You don't have permission to do that.";
    case 404:
      return 'This item is no longer available.';
    case 409:
      return 'That action conflicts with the current state. Refresh and try again.';
    case 422:
      return 'Please check the information you entered and try again.';
    case 429:
      return 'Too many attempts. Please try again shortly.';
    case >= 500:
      return 'Something went wrong on our side. Please try again.';
    default:
      return fallback.isNotEmpty
          ? fallback
          : 'Something went wrong. Please try again.';
  }
}
