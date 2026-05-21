import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyking/core/services/secure_api_key_service.dart';

final secureApiKeyServiceProvider = Provider<SecureApiKeyService>((ref) {
  return SecureApiKeyService();
});
