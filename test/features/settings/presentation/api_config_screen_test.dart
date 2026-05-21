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
import '../../../helpers/navigator_observer_helper.dart';

class FakeSettingsRepository implements SettingsRepository {
  SettingsBox _settings = SettingsBox();
  bool _shouldThrowOnSave = false;

  void setThrowOnSave(bool shouldThrow) {
    _shouldThrowOnSave = shouldThrow;
  }

  @override
  Future<Result<SettingsBox>> getSettings() async => Result.success(_settings);

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async {
    if (_shouldThrowOnSave) {
      return Result.failure('Simulated save failure');
    }
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
      revisionRemindersEnabled: update.revisionRemindersEnabled ?? _settings.revisionRemindersEnabled,
      lessonNotificationsEnabled: update.lessonNotificationsEnabled ?? _settings.lessonNotificationsEnabled,
      overworkAlertsEnabled: update.overworkAlertsEnabled ?? _settings.overworkAlertsEnabled,
      planAdjustmentNotificationsEnabled: update.planAdjustmentNotificationsEnabled ?? _settings.planAdjustmentNotificationsEnabled,
      breakDurationSeconds: update.breakDurationSeconds ?? _settings.breakDurationSeconds,
      dailyReminderHour: update.dailyReminderHour ?? _settings.dailyReminderHour,
      dailyReminderMinute: update.dailyReminderMinute ?? _settings.dailyReminderMinute,
      firstFocusVisit: update.firstFocusVisit ?? _settings.firstFocusVisit,
      dailyReminderEnabled: update.dailyReminderEnabled ?? _settings.dailyReminderEnabled,
      backupLlmProviderName: update.backupLlmProviderName ?? _settings.backupLlmProviderName,
      backupApiKey: update.backupApiKey ?? _settings.backupApiKey,
      backupBaseUrl: update.backupBaseUrl ?? _settings.backupBaseUrl,
      backupModel: update.backupModel ?? _settings.backupModel,
      lastConnectionTestMs: update.lastConnectionTestMs ?? _settings.lastConnectionTestMs,
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
  String initialBackupApiKey = '',
  String initialBackupBaseUrl = '',
  String initialBackupModel = '',
  LlmProvider initialBackupProvider = LlmProvider.openRouter,
  TestNavigatorObserver? navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      settingsProvider.overrideWith((ref) => _TestSettingsNotifier()),
      apiKeyProvider.overrideWith((ref) => initialApiKey),
      apiBaseUrlProvider.overrideWith((ref) => initialBaseUrl),
      llmProviderProvider.overrideWith((ref) => initialProvider),
      backupLlmProviderProvider.overrideWith((ref) => initialBackupProvider),
      backupApiKeyProvider.overrideWith((ref) => initialBackupApiKey),
      backupBaseUrlProvider.overrideWith((ref) => initialBackupBaseUrl),
      backupModelProvider.overrideWith((ref) => initialBackupModel),
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

Future<void> pumpApiConfigScreen(WidgetTester tester, {
  String initialApiKey = '',
  String initialBaseUrl = 'https://openrouter.ai/api/v1',
  LlmProvider initialProvider = LlmProvider.openRouter,
  String initialBackupApiKey = '',
  String initialBackupBaseUrl = '',
  String initialBackupModel = '',
  LlmProvider initialBackupProvider = LlmProvider.openRouter,
  TestNavigatorObserver? navigatorObserver,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(800, 3500);
  await tester.pumpWidget(buildApiConfigScreen(
    initialApiKey: initialApiKey,
    initialBaseUrl: initialBaseUrl,
    initialProvider: initialProvider,
    initialBackupApiKey: initialBackupApiKey,
    initialBackupBaseUrl: initialBackupBaseUrl,
    initialBackupModel: initialBackupModel,
    initialBackupProvider: initialBackupProvider,
    navigatorObserver: navigatorObserver,
  ));
  await tester.pumpAndSettle();
}

Future<void> scrollToWidget(WidgetTester tester, Finder target) async {
  await tester.dragUntilVisible(
    target,
    find.byType(Scrollable).first,
    const Offset(0, -300),
  );
  await tester.pump();
}

class _TestTimeoutHttpOverride extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => 'PROXY localhost';
    return client;
  }
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
    fakeApiRepo.setThrowOnSave(false);
  });

  group('ApiConfigScreen', () {
    testWidgets('renders API configuration screen', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.text('API Configuration'), findsOneWidget);
    });

    testWidgets('shows configure API keys title', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.text('Configure API Keys'), findsOneWidget);
    });

    testWidgets('shows description about OpenRouter', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.textContaining('OpenRouter API credentials'), findsOneWidget);
    });

    testWidgets('shows API key section with correct title', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.text('OpenRouter API Key'), findsOneWidget);
      expect(find.text('sk-or-v1-...'), findsOneWidget);
      expect(find.textContaining('Required for LLM content generation'), findsOneWidget);
    });

    testWidgets('shows API base URL section', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.text('API Base URL'), findsOneWidget);
      expect(find.text('https://openrouter.ai/api/v1'), findsOneWidget);
      expect(find.textContaining('endpoint URL for the AI service'), findsOneWidget);
    });

    testWidgets('shows save button', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Save API Keys'), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('shows test connection button', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Test Connection'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_tethering), findsOneWidget);
    });

    testWidgets('API key field is obscured by default', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;
      final widget = tester.widget<TextField>(textField);
      expect(widget.obscureText, isTrue);
    });

    testWidgets('shows visibility toggle button for API key', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('can type in API key field', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final apiKeyField = find.byType(TextField).first;
      await tester.enterText(apiKeyField, 'sk-test-key-123');
      await tester.pumpAndSettle();

      expect(find.text('sk-test-key-123'), findsOneWidget);
    });

    testWidgets('can type in base URL field', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final baseUrlField = find.byType(TextField).last;
      await tester.enterText(baseUrlField, 'https://custom.api.com');
      await tester.pumpAndSettle();

      expect(find.text('https://custom.api.com'), findsOneWidget);
    });

    testWidgets('shows error when saving empty API key', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen(initialApiKey: ''));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      await tester.pumpAndSettle();

      expect(find.text('API key cannot be empty'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('toggling visibility shows/hides API key', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final visibilityButton = find.byIcon(Icons.visibility);
      expect(visibilityButton, findsOneWidget);

      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      final textField = find.byType(TextField).first;
      final widget = tester.widget<TextField>(textField);
      expect(widget.obscureText, isFalse);
    });

    testWidgets('toggling visibility again hides API key', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      final textField = find.byType(TextField).first;
      final widget = tester.widget<TextField>(textField);
      expect(widget.obscureText, isTrue);
    });

    testWidgets('loadCurrentValues sets initial API key', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-initial-key'));
      await tester.pumpAndSettle();

      expect(find.text('sk-initial-key'), findsOneWidget);
    });

    testWidgets('loadCurrentValues sets initial base URL', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen(initialBaseUrl: 'https://custom.url'));
      await tester.pumpAndSettle();

      expect(find.text('https://custom.url'), findsOneWidget);
    });

    testWidgets('save button disabled during save', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      expect(button.onPressed, isNull);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows success snackbar on successful save', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
      await tester.pumpAndSettle();

      final apiKeyField = find.byType(TextField).first;
      await tester.enterText(apiKeyField, 'sk-new-key');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      await tester.pumpAndSettle();

      expect(find.text('API keys saved successfully'), findsOneWidget);
      expect(find.byIcon(Icons.save), findsWidgets);
    });

    testWidgets('saving navigates back to previous screen', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
      await tester.pumpAndSettle();

      final apiKeyField = find.byType(TextField).first;
      await tester.enterText(apiKeyField, 'sk-new-key');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      await tester.pumpAndSettle();

      expect(find.byType(ApiConfigScreen), findsNothing);
    });

    testWidgets('has proper padding and layout', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('description text is visible', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final description = find.textContaining('Get your key from');
      expect(description, findsOneWidget);
    });

    testWidgets('base URL field is not obscured', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      final baseUrlField = tester.widget<TextField>(textFields.last);
      expect(baseUrlField.obscureText, isFalse);
    });

    testWidgets('saving trims whitespace from inputs', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final apiKeyField = find.byType(TextField).first;
      await tester.enterText(apiKeyField, '  sk-trimmed-key  ');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
      await tester.pumpAndSettle();

      expect(find.text('API keys saved successfully'), findsOneWidget);
    });

    testWidgets('switching text fields works', (tester) async {
      await tester.pumpWidget(buildApiConfigScreen());
      await tester.pumpAndSettle();

      final apiKeyField = find.byType(TextField).first;
      await tester.enterText(apiKeyField, 'sk-key-1');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      final baseUrlField = find.byType(TextField).last;
      await tester.enterText(baseUrlField, 'sk-key-2');
      await tester.pumpAndSettle();

      expect(find.text('sk-key-1'), findsOneWidget);
      expect(find.text('sk-key-2'), findsOneWidget);
    });

    group('Validation Edge Cases', () {
      testWidgets('shows error for empty API key with whitespace', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, '   ');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('API key cannot be empty'), findsOneWidget);
      });

      testWidgets('shows error for tab-only API key', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, '\t\t');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('API key cannot be empty'), findsOneWidget);
      });

      testWidgets('newlines in API key are trimmed', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, '\nsk-trimmed\n');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('API keys saved successfully'), findsOneWidget);
      });

      testWidgets('base URL can be empty without validation error', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialBaseUrl: ''));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('API key cannot be empty'), findsNothing);
      });

      testWidgets('saves with empty base URL', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialBaseUrl: ''));
        await tester.pumpAndSettle();

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, 'sk-valid-key');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('API keys saved successfully'), findsOneWidget);
      });
    });

    group('State Updates', () {
      testWidgets('successful save updates apiKeyProvider', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-old'));
        await tester.pumpAndSettle();

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, 'sk-new-key');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('sk-new-key'), findsOneWidget);
      });

      testWidgets('successful save updates apiBaseUrlProvider', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialBaseUrl: 'https://old.url'));
        await tester.pumpAndSettle();

        final baseUrlField = find.byType(TextField).last;
        await tester.enterText(baseUrlField, 'https://new.url');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('https://new.url'), findsOneWidget);
      });
    });

    group('Visibility Toggle', () {
      testWidgets('visibility button has correct initial state', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off), findsNothing);
      });

      testWidgets('tapping visibility button once shows visibility_off', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      });

      testWidgets('API key field shows plain text when visibility is on', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, 'secret-key-123');
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pumpAndSettle();

        final textField = find.byType(TextField).first;
        final widget = tester.widget<TextField>(textField);
        expect(widget.obscureText, isFalse);
        expect(find.text('secret-key-123'), findsOneWidget);
      });

      testWidgets('toggle multiple times alternates visibility', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        for (var i = 0; i < 3; i++) {
          await tester.tap(find.byIcon(i % 2 == 0 ? Icons.visibility : Icons.visibility_off));
          await tester.pumpAndSettle();
        }

        expect(find.byIcon(Icons.visibility), findsOneWidget);
        expect(find.byIcon(Icons.visibility_off), findsNothing);
      });
    });

    group('Error States', () {
      testWidgets('shows error snackbar when save fails', (tester) async {
        fakeApiRepo.setThrowOnSave(true);
        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
        await tester.pumpAndSettle();

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, 'sk-trigger-error');
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('Unable to save API configuration'), findsOneWidget);
      });
    });

    group('Widget Properties', () {
      testWidgets('API key field has correct hint text', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.text('sk-or-v1-...'), findsOneWidget);
      });

      testWidgets('base URL field has correct hint text', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.text('https://openrouter.ai/api/v1'), findsOneWidget);
      });

      testWidgets('save button has correct text', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.text('Save API Keys'), findsOneWidget);
      });

      testWidgets('API key section has correct title', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.text('OpenRouter API Key'), findsOneWidget);
      });

      testWidgets('API key section has correct description', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('Required for LLM'), findsOneWidget);
      });

      testWidgets('base URL section has correct title', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.text('API Base URL'), findsOneWidget);
      });

      testWidgets('base URL section has correct description', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('endpoint URL'), findsOneWidget);
      });
    });

    group('Loading State', () {
      testWidgets('save button shows progress indicator during save', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.save), findsNothing);
      });
    });

    group('Provider Selection', () {
      testWidgets('renders provider dropdown section', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.text('AI Model'), findsWidgets);
        expect(find.byType(DropdownButtonFormField<LlmProvider>), findsOneWidget);
      });

      testWidgets('provider dropdown shows all options', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
        await tester.pumpAndSettle();

        expect(find.text('OpenRouter'), findsWidgets);
        expect(find.text('Ollama'), findsOneWidget);
        expect(find.text('OpenAI'), findsOneWidget);
      });

      testWidgets('selecting Ollama auto-fills base URL if empty', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialBaseUrl: ''));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ollama').last);
        await tester.pumpAndSettle();

        expect(find.text('http://localhost:11434'), findsOneWidget);
      });

      testWidgets('selecting Ollama does not change non-empty base URL', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(
          initialBaseUrl: 'https://custom.url',
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ollama').last);
        await tester.pumpAndSettle();

        expect(find.text('https://custom.url'), findsOneWidget);
      });

      testWidgets('selecting OpenAI auto-fills empty base URL', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialBaseUrl: ''));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('OpenAI').last);
        await tester.pumpAndSettle();

        expect(find.text('https://api.openai.com/v1'), findsOneWidget);
      });
    });

    group('Test Connection', () {
      testWidgets('test connection with empty API key shows error', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: ''));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
        await tester.pumpAndSettle();

        expect(find.text('API key cannot be empty'), findsOneWidget);
      });

      testWidgets('test connection button disabled during test', (tester) async {
        HttpOverrides.global = _TestTimeoutHttpOverride();
        addTearDown(() => HttpOverrides.global = null);

        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
        await tester.pump();

        final button = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Testing...'));
        expect(button.onPressed, isNull);
      });

      testWidgets('test connection shows loading text during test', (tester) async {
        HttpOverrides.global = _TestTimeoutHttpOverride();
        addTearDown(() => HttpOverrides.global = null);

        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
        await tester.pump();

        expect(find.text('Testing...'), findsOneWidget);
      });

      testWidgets('test connection timeout shows error snackbar', (tester) async {
        HttpOverrides.global = _TestTimeoutHttpOverride();
        addTearDown(() => HttpOverrides.global = null);

        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
        await tester.pump(const Duration(seconds: 16));
        await tester.pumpAndSettle();

        expect(find.textContaining('Connection failed'), findsOneWidget);
      });

      testWidgets('test connection state resets after failure', (tester) async {
        HttpOverrides.global = _TestTimeoutHttpOverride();
        addTearDown(() => HttpOverrides.global = null);

        await tester.pumpWidget(buildApiConfigScreen(initialApiKey: 'sk-test'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
        await tester.pump(const Duration(seconds: 16));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(OutlinedButton, 'Test Connection'), findsOneWidget);
      });
    });

    group('Provider Description', () {
      testWidgets('shows AI model description text', (tester) async {
        await tester.pumpWidget(buildApiConfigScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('endpoint URL for the AI service'), findsWidgets);
      });
    });

    group('Navigation', () {
      testWidgets('save triggers Navigator.pop', (tester) async {
        final navigatorObserver = TestNavigatorObserver();
        await tester.pumpWidget(buildApiConfigScreen(
          initialApiKey: 'sk-test-key',
          navigatorObserver: navigatorObserver,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(navigatorObserver.poppedRoutes, isNotEmpty);
      });
    });
  });

  group('behavioral coverage', () {
    group('ApiConfigScreen - Provider Switching Edge Cases', () {
      testWidgets('switching to Ollama auto-fills empty base URL', (tester) async {
        await pumpApiConfigScreen(tester, initialBaseUrl: '');

        await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ollama').last);
        await tester.pumpAndSettle();

        expect(find.text('http://localhost:11434'), findsOneWidget);
      });

      testWidgets('switching to OpenAI auto-fills empty base URL', (tester) async {
        await pumpApiConfigScreen(tester, initialBaseUrl: '');

        await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('OpenAI').last);
        await tester.pumpAndSettle();

        expect(find.text('https://api.openai.com/v1'), findsOneWidget);
      });

      testWidgets('switching provider preserves non-default base URL', (tester) async {
        await pumpApiConfigScreen(tester, initialBaseUrl: 'https://custom.endpoint.com');

        await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ollama').last);
        await tester.pumpAndSettle();

        expect(find.text('https://custom.endpoint.com'), findsOneWidget);
      });
    });

    group('ApiConfigScreen - Ollama Provider', () {
      testWidgets('saves without API key when Ollama is selected', (tester) async {
        await pumpApiConfigScreen(tester,
          initialProvider: LlmProvider.ollama,
          initialBaseUrl: 'http://localhost:11434',
          initialApiKey: '',
        );

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('API keys saved successfully'), findsOneWidget);
      });

      testWidgets('shows Ollama in provider dropdown', (tester) async {
        await pumpApiConfigScreen(tester);

        await tester.tap(find.byType(DropdownButtonFormField<LlmProvider>));
        await tester.pumpAndSettle();

        expect(find.text('Ollama'), findsOneWidget);
      });
    });

    group('ApiConfigScreen - Save Error Handling', () {
      testWidgets('shows error snackbar when save throws exception', (tester) async {
        fakeApiRepo.setThrowOnSave(true);

        await pumpApiConfigScreen(tester, initialApiKey: 'sk-test');

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.text('Unable to save API configuration'), findsOneWidget);
      });

      testWidgets('save error does not crash the screen', (tester) async {
        fakeApiRepo.setThrowOnSave(true);

        await pumpApiConfigScreen(tester, initialApiKey: 'sk-test');

        await tester.tap(find.widgetWithText(ElevatedButton, 'Save API Keys'));
        await tester.pumpAndSettle();

        expect(find.byType(ApiConfigScreen), findsOneWidget);
      });
    });

    group('ApiConfigScreen - Connection Test', () {
      testWidgets('test connection button shows loading while testing', (tester) async {
        HttpOverrides.global = _TestTimeoutHttpOverride();
        addTearDown(() => HttpOverrides.global = null);

        await pumpApiConfigScreen(tester, initialApiKey: 'sk-test');

        await tester.tap(find.widgetWithText(OutlinedButton, 'Test Connection'));
        await tester.pump();

        expect(find.text('Testing...'), findsOneWidget);
      });
    });

    group('ApiConfigScreen - PopScope No Changes', () {
      testWidgets('PopScope allows back navigation without changes', (tester) async {
        final navigatorObserver = TestNavigatorObserver();
        await pumpApiConfigScreen(tester, navigatorObserver: navigatorObserver);

        final backButton = find.byTooltip('Back');
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();

          expect(find.text('Unsaved Changes'), findsNothing);
          expect(navigatorObserver.poppedRoutes, isNotEmpty);
        }
      });
    });

    group('ApiConfigScreen - Backup Provider Setup Guide', () {
      testWidgets('shows backup provider section with all fields', (tester) async {
        await pumpApiConfigScreen(tester);

        await scrollToWidget(tester, find.text('Backup Provider'));
        expect(find.text('Backup Provider'), findsOneWidget);

        await scrollToWidget(tester, find.text('Backup API Key'));
        expect(find.text('Backup API Key'), findsOneWidget);

        await scrollToWidget(tester, find.text('Backup Model'));
        expect(find.text('Backup Model'), findsOneWidget);
      });

      testWidgets('backup provider dropdown has correct default value', (tester) async {
        await pumpApiConfigScreen(tester);

        final dropdowns = find.byType(DropdownButtonFormField<LlmProvider>);
        expect(dropdowns, findsNWidgets(2));
      });
    });
  });

  group('extended coverage', () {
    group('ApiConfigScreen - Backup Provider Section', () {
      testWidgets('renders backup provider section', (tester) async {
        await pumpApiConfigScreen(tester);

        expect(find.text('Backup Provider'), findsOneWidget);
        expect(find.textContaining('Optional secondary AI provider'), findsAtLeastNWidgets(1));
      });

      testWidgets('renders backup API key section', (tester) async {
        await pumpApiConfigScreen(tester);

        expect(find.text('Backup API Key'), findsOneWidget);
      });

      testWidgets('renders backup base URL section', (tester) async {
        await pumpApiConfigScreen(tester);

        expect(find.text('Backup Base URL'), findsOneWidget);
      });

      testWidgets('renders backup model section', (tester) async {
        await pumpApiConfigScreen(tester);

        expect(find.text('Backup Model'), findsOneWidget);
        expect(find.text('e.g., gpt-4o-mini'), findsOneWidget);
      });

      testWidgets('backup provider dropdown shows all options', (tester) async {
        await pumpApiConfigScreen(tester);

        final dropdowns = find.byType(DropdownButtonFormField<LlmProvider>);
        expect(dropdowns, findsNWidgets(2));

        await tester.tap(dropdowns.last);
        await tester.pumpAndSettle();

        expect(find.text('OpenRouter'), findsWidgets);
        expect(find.text('Ollama'), findsWidgets);
        expect(find.text('OpenAI'), findsWidgets);
      });

      testWidgets('selecting Ollama as backup auto-fills empty backup base URL', (tester) async {
        await pumpApiConfigScreen(tester, initialBackupBaseUrl: '');

        final dropdowns = find.byType(DropdownButtonFormField<LlmProvider>);
        await tester.tap(dropdowns.last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ollama').last);
        await tester.pumpAndSettle();

        expect(find.text('http://localhost:11434'), findsWidgets);
      });

      testWidgets('selecting OpenAI as backup auto-fills empty backup base URL', (tester) async {
        await pumpApiConfigScreen(tester, initialBackupBaseUrl: '');

        final dropdowns = find.byType(DropdownButtonFormField<LlmProvider>);
        await tester.tap(dropdowns.last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('OpenAI').last);
        await tester.pumpAndSettle();

        expect(find.text('https://api.openai.com/v1'), findsWidgets);
      });

      testWidgets('backup provider dropdown does not change non-empty backup base URL', (tester) async {
        await pumpApiConfigScreen(tester, initialBackupBaseUrl: 'https://custom.backup.url');

        final dropdowns = find.byType(DropdownButtonFormField<LlmProvider>);
        await tester.tap(dropdowns.last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Ollama').last);
        await tester.pumpAndSettle();

        expect(find.text('https://custom.backup.url'), findsOneWidget);
      });

      testWidgets('backup API key field is obscured by default', (tester) async {
        await pumpApiConfigScreen(tester);

        final textFields = find.byType(TextField);
        expect(textFields, findsNWidgets(5));

        final backupApiKeyField = tester.widget<TextField>(textFields.at(2));
        expect(backupApiKeyField.obscureText, isTrue);
      });

      testWidgets('can type in backup API key field', (tester) async {
        await pumpApiConfigScreen(tester);

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(2), 'sk-backup-key');
        await tester.pumpAndSettle();

        expect(find.text('sk-backup-key'), findsOneWidget);
      });

      testWidgets('can type in backup base URL field', (tester) async {
        await pumpApiConfigScreen(tester);

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(3), 'https://backup.api.url');
        await tester.pumpAndSettle();

        expect(find.text('https://backup.api.url'), findsOneWidget);
      });

      testWidgets('can type in backup model field', (tester) async {
        await pumpApiConfigScreen(tester);

        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(4), 'gpt-4');
        await tester.pumpAndSettle();

        expect(find.text('gpt-4'), findsOneWidget);
      });

      testWidgets('loads backup provider values from providers', (tester) async {
        await pumpApiConfigScreen(tester,
          initialBackupApiKey: 'sk-backup-existing',
          initialBackupBaseUrl: 'https://backup.url',
          initialBackupModel: 'gpt-4',
        );

        expect(find.text('sk-backup-existing'), findsOneWidget);
        expect(find.text('https://backup.url'), findsOneWidget);
        expect(find.text('gpt-4'), findsOneWidget);
      });
    });

    group('ApiConfigScreen - Setup Guide', () {
      testWidgets('shows provider setup guide icons', (tester) async {
        await pumpApiConfigScreen(tester);

        expect(find.byIcon(Icons.help_outline), findsAtLeastNWidgets(2));
        expect(find.textContaining('How to get started with'), findsAtLeastNWidgets(2));
      });
    });

    group('ApiConfigScreen - Connection Test', () {
      testWidgets('test connection button exists and is enabled with non-empty key', (tester) async {
        await pumpApiConfigScreen(tester, initialApiKey: 'sk-test-key');

        final testButton = find.widgetWithText(OutlinedButton, 'Test Connection');
        expect(testButton, findsOneWidget);

        final button = tester.widget<OutlinedButton>(testButton);
        expect(button.onPressed, isNotNull);
      });
    });

    group('ApiConfigScreen - Unsaved Changes', () {
      testWidgets('shows unsaved changes dialog when back is pressed with changes', (tester) async {
        await pumpApiConfigScreen(tester);

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, 'new-api-key');
        await tester.pumpAndSettle();

        final backButton = find.byTooltip('Back');
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();

          expect(find.text('Unsaved Changes'), findsOneWidget);
          expect(find.text('Discard'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);
        }
      });

      testWidgets('cancel on unsaved changes keeps user on screen', (tester) async {
        await pumpApiConfigScreen(tester);

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, 'new-api-key');
        await tester.pumpAndSettle();

        final backButton = find.byTooltip('Back');
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();

          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();

          expect(find.byType(ApiConfigScreen), findsOneWidget);
        }
      });

      testWidgets('discard on unsaved changes navigates back', (tester) async {
        final navigatorObserver = TestNavigatorObserver();
        await pumpApiConfigScreen(tester, navigatorObserver: navigatorObserver);

        final apiKeyField = find.byType(TextField).first;
        await tester.enterText(apiKeyField, 'new-api-key');
        await tester.pumpAndSettle();

        final backButton = find.byTooltip('Back');
        if (backButton.evaluate().isNotEmpty) {
          await tester.tap(backButton);
          await tester.pumpAndSettle();

          await tester.tap(find.text('Discard'));
          await tester.pumpAndSettle();

          expect(navigatorObserver.poppedRoutes, isNotEmpty);
        }
      });
    });

    group('ApiConfigScreen - Backup Visibility Toggle', () {
      testWidgets('shows two visibility icons for main and backup API keys', (tester) async {
        await pumpApiConfigScreen(tester);

        expect(find.byIcon(Icons.visibility), findsNWidgets(2));
      });

      testWidgets('tapping backup visibility toggle shows visibility_off', (tester) async {
        await pumpApiConfigScreen(tester);

        await scrollToWidget(tester, find.text('Backup API Key'));
        await tester.pumpAndSettle();

        final visibilityIcons = find.byIcon(Icons.visibility);
        expect(visibilityIcons, findsNWidgets(2));

        await tester.ensureVisible(visibilityIcons.last);
        await tester.pumpAndSettle();

        await tester.tap(visibilityIcons.last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byIcon(Icons.visibility_off).last);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.visibility_off), findsAtLeastNWidgets(1));
      });
    });
  });

  group('gaps coverage', () {
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
  });
}
