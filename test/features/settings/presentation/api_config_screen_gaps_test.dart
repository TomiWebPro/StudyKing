import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/providers/secure_api_key_provider.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/secure_api_key_service.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/settings/presentation/api_config_screen.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../../test/helpers/navigator_observer_helper.dart';

class FakeSettingsRepository implements SettingsRepository {
  SettingsBox _settings = SettingsBox();

  @override
  Future<Result<SettingsBox>> getSettings() async => Result.success(_settings);

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async {
    _settings = SettingsBox(
      apiKey: update.apiKey ?? _settings.apiKey,
      apiBaseUrl: update.apiBaseUrl ?? _settings.apiBaseUrl,
      selectedModel: update.selectedModel ?? _settings.selectedModel,
      themeMode: update.themeMode?.index ?? _settings.themeMode,
      fontSize: update.fontSize ?? _settings.fontSize,
      totalSessionCount: _settings.totalSessionCount,
      totalStudyTimeMs: _settings.totalStudyTimeMs,
      totalQuestions: _settings.totalQuestions,
      studyRemindersEnabled: update.studyRemindersEnabled ?? _settings.studyRemindersEnabled,
      requestTimeoutSeconds: update.requestTimeoutSeconds ?? _settings.requestTimeoutSeconds,
      sessionDurationMinutes: update.sessionDurationMinutes ?? _settings.sessionDurationMinutes,
      highContrastEnabled: update.highContrastEnabled ?? _settings.highContrastEnabled,
      largeTouchTargets: update.largeTouchTargets ?? _settings.largeTouchTargets,
      reduceMotion: update.reduceMotion ?? _settings.reduceMotion,
      lastConnectionTestMs: update.lastConnectionTestMs ?? _settings.lastConnectionTestMs,
      backupLlmProviderName: update.backupLlmProviderName ?? _settings.backupLlmProviderName,
      backupApiKey: update.backupApiKey ?? _settings.backupApiKey,
      backupBaseUrl: update.backupBaseUrl ?? _settings.backupBaseUrl,
      backupModel: update.backupModel ?? _settings.backupModel,
    );
    return Result.success(null);
  }

  @override
  Future<Result<void>> init() async => Result.success(null);
  @override
  Future<Result<void>> updateStats({int? sessionCount, int? studyTimeMs, int? questions}) async => Result.success(null);
  @override
  Future<Result<void>> saveApiKey({required String service, required String key}) async => Result.success(null);
  @override
  Future<Result<String?>> getApiKey({required String service}) async => Result.success(null);
  @override
  Future<Result<void>> saveProfileData(UserProfile profile) async => Result.success(null);
  @override
  Future<Result<UserProfile?>> getProfileData() async => Result.success(null);
  @override
  Future<Result<void>> clearProfile() async => Result.success(null);
  @override
  Future<Result<void>> clearSettings() async => Result.success(null);
  @override
  Future<Result<void>> saveProvider(LlmProvider provider) async => Result.success(null);
  @override
  Future<Result<LlmProvider>> getProvider() async => Result.success(LlmProvider.openRouter);
}

final fakeApiRepo = FakeSettingsRepository();

class FakeSecureApiKeyService extends SecureApiKeyService {
  FakeSecureApiKeyService() : super();
  @override
  Future<void> saveApiKey(String key) async {}
  @override
  Future<String> getApiKey() async => '';
  @override
  Future<void> saveBackupApiKey(String key) async {}
  @override
  Future<String> getBackupApiKey() async => '';
  @override
  Future<void> clearAll() async {}
}

class _TestSettingsNotifier extends SettingsController {
  _TestSettingsNotifier() : super(fakeApiRepo);

  @override
  Future<void> updateSettings(SettingsUpdate update, {LlmProvider? llmProvider}) async {
    await fakeApiRepo.updateSettings(update);
    state = fakeApiRepo._settings;
  }
}

Widget buildApiConfigScreen({
  String initialApiKey = '',
  String initialBaseUrl = 'https://openrouter.ai/api/v1',
  LlmProvider initialProvider = LlmProvider.openRouter,
  TestNavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => _TestSettingsNotifier()),
      apiKeyProvider.overrideWith((ref) => initialApiKey),
      apiBaseUrlProvider.overrideWith((ref) => initialBaseUrl),
      llmProviderProvider.overrideWith((ref) => initialProvider),
      backupLlmProviderProvider.overrideWith((ref) => LlmProvider.openRouter),
      backupApiKeyProvider.overrideWith((ref) => ''),
      backupBaseUrlProvider.overrideWith((ref) => ''),
      backupModelProvider.overrideWith((ref) => ''),
      secureApiKeyServiceProvider.overrideWith((ref) => FakeSecureApiKeyService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      home: const ApiConfigScreen(),
    ),
  );
}

class _FakeHttpSuccess extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient();
  }
}

class _FakeHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 30);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}

  @override
  void addProxyCredentials(String realm, int port, String scheme, HttpClientCredentials credentials) {}

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _FakeHttpClientRequest();
  }

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}

  @override
  set authenticateProxy(
      Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}

  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod && invocation.memberName == #deleteUrl) {
      return Future.error(UnimplementedError());
    }
    if (invocation.isMethod && invocation.memberName == #getUrl) {
      return Future.error(UnimplementedError());
    }
    if (invocation.isMethod && invocation.memberName == #patchUrl) {
      return Future.error(UnimplementedError());
    }
    if (invocation.isMethod && invocation.memberName == #putUrl) {
      return Future.error(UnimplementedError());
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeHttpClientRequest implements HttpClientRequest {
  @override
  String method = 'POST';

  @override
  Uri uri = Uri.parse('https://example.com');

  @override
  bool bufferOutput = false;

  bool persistCookies = false;

  @override
  bool followRedirects = true;

  @override
  int contentLength = 0;

  Encoding _encoding = utf8;

  @override
  Encoding get encoding => _encoding;
  @override
  set encoding(Encoding value) => _encoding = value;

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse();
  }

  @override
  Future<HttpClientResponse> get done => close();

  @override
  HttpHeaders headers = _FakeHttpHeaders();

  set registerClose(void Function()? f) {}

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  int get responseTimeout => 0;
  set responseTimeout(int value) {}

  @override
  Future<dynamic> addStream(Stream<List<int>> stream) async {}

  Future<HttpClientResponse> get response => close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse implements HttpClientResponse {
  @override
  int statusCode = 200;

  @override
  String reasonPhrase = 'OK';

  @override
  int contentLength = 2;

  @override
  bool persistentConnection = true;

  Future<int> close() async => 0;

  @override
  HttpHeaders headers = _FakeHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return const Stream.empty().cast<List<int>>().listen((_) {});
  }

  @override
  Stream<List<int>> asBroadcastStream({void Function(StreamSubscription<List<int>>)? onCancel, void Function(StreamSubscription<List<int>>)? onListen}) =>
      const Stream.empty();

  @override
  Future<bool> any(bool Function(List<int> element) test) async => false;

  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(List<int> element) convert) =>
      const Stream.empty();

  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(List<int> element) convert) =>
      const Stream.empty();

  @override
  Stream<S> cast<S>() => const Stream.empty();

  @override
  Future<bool> contains(Object? needle) async => false;

  @override
  Future<E> drain<E>([E? futureValue]) async => futureValue as FutureOr<E>;

  @override
  Future<List<int>> elementAt(int index) async => [];

  @override
  Future<bool> every(bool Function(List<int> element) test) async => false;

  @override
  Future<List<int>> firstWhere(bool Function(List<int> element) test,
      {List<int> Function()? orElse}) async =>
      [];

  @override
  Future<List<int>> lastWhere(bool Function(List<int> element) test,
      {List<int> Function()? orElse}) async =>
      [];

  @override
  Future<List<int>> get first => Future.value([]);

  @override
  Future<List<int>> get last => Future.value([]);

  @override
  Future<List<int>> get single => Future.value([]);

  @override
  Future<List<int>> reduce(List<int> Function(List<int>, List<int>) combine) async =>
      [];

  @override
  Future<S> fold<S>(S initialValue, S Function(S, List<int>) combine) async =>
      initialValue;

  @override
  Future<String> join([String separator = '']) async => '';

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) =>
      const Stream.empty();

  @override
  Future<bool> get isEmpty => Future.value(false);

  @override
  Future pipe(StreamConsumer<List<int>> streamConsumer) async {}

  @override
  Future forEach(void Function(List<int> element) action) async {}

  @override
  Stream<List<int>> skip(int count) => const Stream.empty();

  @override
  Stream<List<int>> skipWhile(bool Function(List<int> element) test) =>
      const Stream.empty();

  @override
  Stream<List<int>> take(int count) => const Stream.empty();

  @override
  Stream<List<int>> takeWhile(bool Function(List<int> element) test) =>
      const Stream.empty();

  @override
  Stream<List<int>> where(bool Function(List<int> element) test) =>
      const Stream.empty();

  @override
  Stream<List<int>> distinct([bool Function(List<int>, List<int>)? equals]) =>
      const Stream.empty();

  @override
  Future<List<List<int>>> toList() async => [];

  @override
  Future<Set<List<int>>> toSet() async => {};

  @override
  Stream<List<int>> handleError(Function onError,
      {bool Function(Object error)? test}) =>
      const Stream.empty();

  @override
  Stream<S> map<S>(S Function(List<int> element) convert) =>
      const Stream.empty();

  @override
  Stream<List<int>> timeout(Duration timeLimit,
      {void Function(EventSink<List<int>>)? onTimeout}) =>
      const Stream.empty();

  @override
  Future<HttpClientResponse> redirect(
      [String? method, Uri? url, bool? followRedirects]) async =>
      this;

  @override
  List<RedirectInfo> get redirects => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = true}) {}

  @override
  List<String>? operator [](String name) => null;

  @override
  void forEach(void Function(String name, List<String> values) action) {}

  @override
  void noFolding(String name) {}

  @override
  void remove(String name, Object value) {}

  @override
  void removeAll(String name) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = true}) {}

  @override
  String? value(String name) => null;

  @override
  int get contentLength => 0;
  @override
  set contentLength(int value) {}

  @override
  bool get chunkedTransferEncoding => false;
  @override
  set chunkedTransferEncoding(bool value) {}

  @override
  String? get host => null;
  @override
  set host(String? value) {}
  @override
  int? get port => null;
  @override
  set port(int? value) {}

  @override
  DateTime? get ifModifiedSince => null;
  @override
  set ifModifiedSince(DateTime? value) {}

  @override
  bool get persistentConnection => false;
  @override
  set persistentConnection(bool value) {}

  @override
  DateTime? get date => null;
  @override
  set date(DateTime? value) {}

  @override
  DateTime? get expires => null;
  @override
  set expires(DateTime? value) {}

  @override
  ContentType? get contentType => null;
  @override
  set contentType(ContentType? value) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNon200HttpOverride extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeNon200HttpClient();
  }
}

class _FakeNon200HttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 30);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(String realm, int port, String scheme, HttpClientCredentials credentials) {}
  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    return _FakeNon200HttpClientRequest();
  }

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {}
  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) {}
  @override
  set findProxy(String Function(Uri url)? f) {}

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isMethod && invocation.memberName == #deleteUrl) {
      return Future.error(UnimplementedError());
    }
    if (invocation.isMethod && invocation.memberName == #getUrl) {
      return Future.error(UnimplementedError());
    }
    if (invocation.isMethod && invocation.memberName == #patchUrl) {
      return Future.error(UnimplementedError());
    }
    if (invocation.isMethod && invocation.memberName == #putUrl) {
      return Future.error(UnimplementedError());
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeNon200HttpClientRequest implements HttpClientRequest {
  @override
  String method = 'POST';
  @override
  Uri uri = Uri.parse('https://example.com');
  @override
  bool bufferOutput = false;
  bool persistCookies = false;
  @override
  bool followRedirects = true;
  @override
  int contentLength = 0;

  Encoding _encoding = utf8;
  @override
  Encoding get encoding => _encoding;
  @override
  set encoding(Encoding value) => _encoding = value;

  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<HttpClientResponse> close() async => _FakeNon200HttpClientResponse();
  @override
  Future<HttpClientResponse> get done => close();
  @override
  HttpHeaders headers = _FakeHttpHeaders();
  set registerClose(void Function()? f) {}
  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
  int get responseTimeout => 0;
  set responseTimeout(int value) {}
  @override
  Future<dynamic> addStream(Stream<List<int>> stream) async {}
  Future<HttpClientResponse> get response => close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNon200HttpClientResponse implements HttpClientResponse {
  @override
  int statusCode = 401;

  @override
  String reasonPhrase = 'Unauthorized';

  @override
  int contentLength = 0;

  @override
  bool persistentConnection = true;

  Future<int> close() async => 0;

  @override
  HttpHeaders headers = _FakeHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return const Stream.empty().cast<List<int>>().listen((_) {});
  }

  @override
  Stream<List<int>> asBroadcastStream({void Function(StreamSubscription<List<int>>)? onCancel, void Function(StreamSubscription<List<int>>)? onListen}) => const Stream.empty();
  @override
  Future<bool> any(bool Function(List<int> element) test) async => false;
  @override
  Stream<E> asyncExpand<E>(Stream<E>? Function(List<int> element) convert) => const Stream.empty();
  @override
  Stream<E> asyncMap<E>(FutureOr<E> Function(List<int> element) convert) => const Stream.empty();
  @override
  Stream<S> cast<S>() => const Stream.empty();
  @override
  Future<bool> contains(Object? needle) async => false;
  @override
  Future<E> drain<E>([E? futureValue]) async => futureValue as FutureOr<E>;
  @override
  Future<List<int>> elementAt(int index) async => [];
  @override
  Future<bool> every(bool Function(List<int> element) test) async => false;
  @override
  Future<List<int>> firstWhere(bool Function(List<int> element) test, {List<int> Function()? orElse}) async => [];
  @override
  Future<List<int>> lastWhere(bool Function(List<int> element) test, {List<int> Function()? orElse}) async => [];
  @override
  Future<List<int>> get first => Future.value([]);
  @override
  Future<List<int>> get last => Future.value([]);
  @override
  Future<List<int>> get single => Future.value([]);
  @override
  Future<List<int>> reduce(List<int> Function(List<int>, List<int>) combine) async => [];
  @override
  Future<S> fold<S>(S initialValue, S Function(S, List<int>) combine) async => initialValue;
  @override
  Future<String> join([String separator = '']) async => '';
  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) => const Stream.empty();
  @override
  Future<bool> get isEmpty => Future.value(false);
  @override
  Future pipe(StreamConsumer<List<int>> streamConsumer) async {}
  @override
  Future forEach(void Function(List<int> element) action) async {}
  @override
  Stream<List<int>> skip(int count) => const Stream.empty();
  @override
  Stream<List<int>> skipWhile(bool Function(List<int> element) test) => const Stream.empty();
  @override
  Stream<List<int>> take(int count) => const Stream.empty();
  @override
  Stream<List<int>> takeWhile(bool Function(List<int> element) test) => const Stream.empty();
  @override
  Stream<List<int>> where(bool Function(List<int> element) test) => const Stream.empty();
  @override
  Stream<List<int>> distinct([bool Function(List<int>, List<int>)? equals]) => const Stream.empty();
  @override
  Future<List<List<int>>> toList() async => [];
  @override
  Future<Set<List<int>>> toSet() async => {};
  @override
  Stream<List<int>> handleError(Function onError, {bool Function(Object error)? test}) => const Stream.empty();
  @override
  Stream<S> map<S>(S Function(List<int> element) convert) => const Stream.empty();
  @override
  Stream<List<int>> timeout(Duration timeLimit, {void Function(EventSink<List<int>>)? onTimeout}) => const Stream.empty();
  @override
  Future<HttpClientResponse> redirect([String? method, Uri? url, bool? followRedirects]) async => this;
  @override
  List<RedirectInfo> get redirects => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    fakeApiRepo._settings = SettingsBox();
  });

  group('ApiConfigScreen - Connection Test Success', () {
    testWidgets('test connection with HTTP 200 shows success snackbar', (tester) async {
      HttpOverrides.global = _FakeHttpSuccess();
      addTearDown(() => HttpOverrides.global = null);

      await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test-key'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.textContaining('Connection successful'), findsOneWidget);
    });
  });

  group('ApiConfigScreen - Connection Test Non-200', () {
    testWidgets('test connection with HTTP 401 shows error snackbar', (tester) async {
      HttpOverrides.global = _FakeNon200HttpOverride();
      addTearDown(() => HttpOverrides.global = null);

      await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test-key'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.textContaining('Connection failed'), findsOneWidget);
    });
  });
}
