// ignore_for_file: override_on_non_overriding_member

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyking/core/errors/result.dart';
import 'package:studyking/core/providers/llm_providers.dart';
import 'package:studyking/core/services/llm/llm_chat_service.dart';
import 'package:studyking/core/services/llm_task_manager.dart';
import 'package:studyking/core/services/llm_usage_meter.dart';
import 'package:studyking/core/services/secure_api_key_service.dart';
import 'package:studyking/core/providers/app_providers.dart';
import 'package:studyking/core/providers/secure_api_key_provider.dart';
import 'package:studyking/features/settings/data/models/settings_box.dart';
import 'package:studyking/features/settings/data/models/user_profile_model.dart';
import 'package:studyking/features/settings/data/models/settings_update.dart';
import 'package:studyking/features/settings/data/repositories/settings_repository.dart';
import 'package:studyking/features/settings/presentation/settings_screen.dart';
import 'package:studyking/features/settings/providers/settings_providers.dart';
import 'package:studyking/features/settings/services/data_backup_service.dart';
import 'package:studyking/l10n/generated/app_localizations.dart';
import '../../../helpers/navigator_observer_helper.dart';

class FakeSettingsRepository implements SettingsRepository {
  SettingsBox settings = SettingsBox();
  bool _shouldThrow = false;

  void setThrowOnGetSettings(bool shouldThrow) {
    _shouldThrow = shouldThrow;
  }

  @override
  Future<Result<SettingsBox>> getSettings() async {
    if (_shouldThrow) return Result.failure('Simulated error');
    return Result.success(settings);
  }

  @override
  Future<Result<void>> updateSettings(SettingsUpdate update) async {
    settings = SettingsBox(
      apiKey: update.apiKey ?? settings.apiKey,
      apiBaseUrl: update.apiBaseUrl ?? settings.apiBaseUrl,
      selectedModel: update.selectedModel ?? settings.selectedModel,
      themeMode: update.themeMode?.index ?? settings.themeMode,
      fontSize: update.fontSize ?? settings.fontSize,
      totalSessionCount: settings.totalSessionCount,
      totalStudyTimeMs: settings.totalStudyTimeMs,
      totalQuestions: settings.totalQuestions,
      studyRemindersEnabled: update.studyRemindersEnabled ?? settings.studyRemindersEnabled,
      requestTimeoutSeconds: update.requestTimeoutSeconds ?? settings.requestTimeoutSeconds,
      sessionDurationMinutes: update.sessionDurationMinutes ?? settings.sessionDurationMinutes,
      highContrastEnabled: update.highContrastEnabled ?? settings.highContrastEnabled,
      largeTouchTargets: update.largeTouchTargets ?? settings.largeTouchTargets,
      reduceMotion: update.reduceMotion ?? settings.reduceMotion,
      boldText: update.boldText ?? settings.boldText,
      revisionRemindersEnabled: update.revisionRemindersEnabled ?? settings.revisionRemindersEnabled,
      lessonNotificationsEnabled: update.lessonNotificationsEnabled ?? settings.lessonNotificationsEnabled,
      overworkAlertsEnabled: update.overworkAlertsEnabled ?? settings.overworkAlertsEnabled,
      planAdjustmentNotificationsEnabled: update.planAdjustmentNotificationsEnabled ?? settings.planAdjustmentNotificationsEnabled,
      breakDurationSeconds: update.breakDurationSeconds ?? settings.breakDurationSeconds,
      dailyReminderHour: update.dailyReminderHour ?? settings.dailyReminderHour,
      dailyReminderMinute: update.dailyReminderMinute ?? settings.dailyReminderMinute,
      firstFocusVisit: update.firstFocusVisit ?? settings.firstFocusVisit,
      dailyReminderEnabled: update.dailyReminderEnabled ?? settings.dailyReminderEnabled,
      lastConnectionTestMs: update.lastConnectionTestMs ?? settings.lastConnectionTestMs,
      lastLlmError: update.lastLlmError ?? settings.lastLlmError,
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
  Future<Result<String?>> getApiKey({required String service}) async => Result.success(settings.apiKey);
  @override
  Future<Result<void>> saveProfileData(UserProfile profile) async => Result.success(null);
  @override
  Future<Result<UserProfile?>> getProfileData() async => Result.success(null);
  @override
  Future<Result<void>> clearSettings() async => Result.success(null);
  @override
  Future<Result<void>> clearProfile() async => Result.success(null);
  @override
  Future<Result<void>> saveProvider(LlmProvider provider) async => Result.success(null);
  @override
  Future<Result<LlmProvider>> getProvider() async => Result.success(LlmProvider.openRouter);
}

final fakeRepo = FakeSettingsRepository();

class FakeLlmTaskManager extends LlmTaskManager {
  final List<LlmTask> _overrideTasks;
  final List<LlmTask> _overrideActiveTasks;

  FakeLlmTaskManager({List<LlmTask>? tasks, List<LlmTask>? activeTasks})
      : _overrideTasks = tasks ?? [],
        _overrideActiveTasks = activeTasks ?? [];

  @override
  Future<void> init() async {}

  @override
  List<LlmTask> get tasks => _overrideTasks;

  @override
  List<LlmTask> get activeTasks => _overrideActiveTasks;
}

class FakeLlmUsageMeter extends LlmUsageMeter {
  final int _totalTokens;
  final double _totalCost;
  final Map<String, int> _perFeature;

  FakeLlmUsageMeter({
    int totalTokens = 0,
    double totalCost = 0.0,
    Map<String, int> perFeature = const {},
  })  : _totalTokens = totalTokens,
        _totalCost = totalCost,
        _perFeature = perFeature;

  @override
  Future<void> init() async {}

  @override
  List<LlmUsageRecord> getRecords({String? feature, int? limit}) => [];

  @override
  int getTotalTokens() => _totalTokens;

  @override
  double getTotalCost() => _totalCost;

  @override
  Map<String, int> getTotalTokensPerFeature() => _perFeature;
}

class FakeSecureApiKeyService extends SecureApiKeyService {
  bool clearAllCalled = false;

  FakeSecureApiKeyService() : super();

  @override
  Future<Result<void>> clearAll() async {
    clearAllCalled = true;
    return Result.success(null);
  }

  @override
  Future<Result<void>> saveApiKey(String key) async => Result.success(null);
  @override
  Future<Result<String>> getApiKey() async => Result.success('');
  @override
  Future<Result<void>> saveBackupApiKey(String key) async => Result.success(null);
  @override
  Future<Result<String>> getBackupApiKey() async => Result.success('');
}

class FakeDataBackupService extends DataBackupService {
  bool exportAllDataCalled = false;

  @override
  Map<String, List<Map<String, dynamic>>> collectAllBoxData() => {};

  @override
  Future<Result<String>> exportAllData({
    required Map<String, List<Map<String, dynamic>>> boxData,
    String? filename,
    String? outputDir,
    bool compress = true,
    String? encryptionPassword,
  }) async {
    exportAllDataCalled = true;
    return Result.success('/tmp/test_backup.skbak');
  }
}

class _TestSettingsNotifier extends SettingsController {
  _TestSettingsNotifier(SettingsBox initial, SettingsRepository repo) : super(repo) {
    state = initial;
  }
}

class _ThrowingSettingsNotifier extends SettingsController {
  _ThrowingSettingsNotifier() : super(fakeRepo);

  @override
  RemoveListener addListener(void Function(SettingsBox) listener, {bool fireImmediately = true}) {
    return () {};
  }

  @override
  SettingsBox get state => throw Exception('Test settings error');
}

Widget buildSettingsScreen({
  SettingsBox? initialSettings,
  String apiKey = '',
  String selectedModel = '',
  LlmTaskManager? taskManager,
  LlmUsageMeter? usageMeter,
  SecureApiKeyService? secureApiKeyService,
  DataBackupService? backupService,
  bool useThrowingNotifier = false,
  TestNavigatorObserver? navigatorObserver,
}) {
  if (initialSettings != null) {
    fakeRepo.settings = initialSettings;
  }
  final effectiveTaskManager = taskManager ?? FakeLlmTaskManager();
  final effectiveUsageMeter = usageMeter ?? FakeLlmUsageMeter();
  return ProviderScope(
    overrides: [
      if (useThrowingNotifier)
        settingsProvider.overrideWith((ref) => _ThrowingSettingsNotifier())
      else
        settingsProvider.overrideWith((ref) => _TestSettingsNotifier(fakeRepo.settings, fakeRepo)),
      apiKeyProvider.overrideWith((ref) => apiKey),
      selectedModelProvider.overrideWith((ref) => selectedModel),
      llmTaskManagerProvider.overrideWith((ref) => effectiveTaskManager),
      llmUsageMeterProvider.overrideWith((ref) => effectiveUsageMeter),
      if (secureApiKeyService != null)
        secureApiKeyServiceProvider.overrideWith((ref) => secureApiKeyService),
      if (backupService != null)
        dataBackupServiceProvider.overrideWith((ref) => backupService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: navigatorObserver != null ? [navigatorObserver] : [],
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(body: Text('Route: ${settings.name}')),
        settings: settings,
      ),
      home: const SettingsScreen(),
    ),
  );
}

Future<void> pumpWithSettings(WidgetTester tester, {
  SettingsBox? initialSettings,
  String apiKey = '',
  String selectedModel = '',
  LlmTaskManager? taskManager,
  LlmUsageMeter? usageMeter,
  SecureApiKeyService? secureApiKeyService,
  DataBackupService? backupService,
  bool useThrowingNotifier = false,
  TestNavigatorObserver? navigatorObserver,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(800, 3500);
  await tester.pumpWidget(buildSettingsScreen(
    initialSettings: initialSettings,
    apiKey: apiKey,
    selectedModel: selectedModel,
    taskManager: taskManager,
    usageMeter: usageMeter,
    secureApiKeyService: secureApiKeyService,
    backupService: backupService,
    useThrowingNotifier: useThrowingNotifier,
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

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = {};
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) =>
      (_values.putIfAbsent(name, () => [])..add(value.toString()));
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) =>
      _values[name] = [value.toString()];
  @override
  void remove(String name, Object value) => _values[name]?.remove(value.toString());
  @override
  void removeAll(String name) => _values.remove(name);
  @override
  void clear() => _values.clear();
  @override
  void forEach(void Function(String name, List<String> values) action) =>
      _values.forEach(action);
  @override
  String? value(String name) => _values[name]?.first;
  @override
  List<String>? operator [](String name) => _values[name];
  @override
  DateTime? date;
  @override
  DateTime? expires;
  @override
  DateTime? ifModifiedSince;
  @override
  DateTime? lastModified;
  @override
  ContentType? contentType;
  @override
  int contentLength = -1;
  @override
  bool persistentConnection = true;
  @override
  void noFolding(String name) {}
  @override
  bool chunkedTransferEncoding = false;
  @override
  String? connection;
  @override
  String? proxyAuthenticate;
  @override
  String? wwwAuthenticate;
  @override
  String? host;
  @override
  int? port;
  @override
  String? pragma;
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this._client, this.method, this.uri);
  final _FakeHttpClient _client;
  @override
  final String method;
  @override
  final Uri uri;
  @override
  final HttpHeaders headers = _FakeHttpHeaders();
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  bool persistentConnection = true;
  @override
  int contentLength = -1;
  @override
  bool bufferOutput = true;
  @override
  Encoding encoding = utf8;
  @override
  List<Cookie> cookies = [];
  @override
  HttpConnectionInfo? connectionInfo;
  @override
  Future<HttpClientResponse> get done => close();
  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();
  @override
  Future<HttpClientResponse> close() => _client._respond(this);
  @override
  Future<void> flush() async {}
  @override
  void write(Object? obj) {}
  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = '']) {}
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse(this.statusCode, this._bodyBytes, this._headers);
  @override
  final int statusCode;
  final List<int> _bodyBytes;
  final HttpHeaders _headers;
  @override
  final String reasonPhrase = 'OK';
  @override
  final bool isRedirect = false;
  @override
  final bool persistentConnection = false;
  @override
  final HttpClientResponseCompressionState compressionState =
      HttpClientResponseCompressionState.notCompressed;
  @override
  final List<Cookie> cookies = const [];
  @override
  final HttpConnectionInfo? connectionInfo = null;
  @override
  final X509Certificate? certificate = null;
  @override
  int get contentLength => _bodyBytes.length;
  @override
  HttpHeaders get headers => _headers;
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final controller = StreamController<List<int>>();
    controller.add(_bodyBytes);
    controller.close();
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<Socket> detachSocket({bool? writeHeaders = true}) =>
      throw UnimplementedError();
  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) =>
      throw UnimplementedError();
}

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.statusCode, this.body, {this.hang = false, this.throwsError = false});
  final int statusCode;
  final String body;
  final bool hang;
  final bool throwsError;

  Future<HttpClientResponse> _respond(_FakeHttpClientRequest request) {
    if (hang) return Completer<HttpClientResponse>().future;
    return Future.value(
      _FakeHttpClientResponse(statusCode, utf8.encode(body), request.headers),
    );
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    if (throwsError) {
      throw const SocketException('Connection refused (fake)');
    }
    return Future.value(_FakeHttpClientRequest(this, method, url));
  }
  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);
  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);
  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);
  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl('HEAD', url);
  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl('PATCH', url);
  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      openUrl('GET', Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      openUrl('POST', Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      openUrl('PUT', Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      openUrl('DELETE', Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      openUrl('HEAD', Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      openUrl('PATCH', Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) =>
      openUrl(method, Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  void close({bool force = false}) {}
  @override
  bool autoUncompress = true;
  @override
  String? userAgent;
  @override
  Duration idleTimeout = Duration.zero;
  @override
  int? maxConnectionsPerHost;
  @override
  bool? persistentConnection;
  @override
  String Function(Uri url)? findProxy = (Uri url) => 'DIRECT';
  @override
  void Function(String line)? keyLog;
  @override
  Future<bool> Function(Uri url, String scheme, String realm)? authenticate;
  @override
  Future<bool> Function(String host, int port, String scheme, String? realm)?
      authenticateProxy;
  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {}
  @override
  bool Function(X509Certificate cert, String host, int port)?
      badCertificateCallback;
  @override
  Future<ConnectionTask<Socket>> Function(
    Uri url,
    String? proxyHost,
    int? proxyPort,
  )? connectionFactory;
  @override
  Duration? connectionTimeout;
  @override
  SecurityContext? context;
  @override
  void Function(String host, int port, String path, String method)?
      onBadCertificate;
}

class FakeSettingsHttpOverride extends HttpOverrides {
  final int responseStatusCode;
  final String responseBody;
  final bool throwsError;

  FakeSettingsHttpOverride({
    required this.responseStatusCode,
    required this.responseBody,
    this.throwsError = false,
  });

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _FakeHttpClient(responseStatusCode, responseBody, throwsError: throwsError);
}

class TimeoutSettingsHttpOverride extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _FakeHttpClient(200, '', hang: true);
}
