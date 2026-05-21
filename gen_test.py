import json, os, re

with open('lib/l10n/app_en.arb') as f:
    en = json.load(f)
with open('lib/l10n/app_es.arb') as f:
    es = json.load(f)

all_keys = {k for k in en if k[0].isalpha() and not k.startswith('@')}

tested_keys = set()
test_dir = 'test/l10n'
for fn in os.listdir(test_dir):
    if fn.endswith('.dart'):
        with open(os.path.join(test_dir, fn)) as f:
            content = f.read()
        for m in re.finditer(r'(?:l10n|l|loc|delegate|localizations|l10nEs|l10nEn|lEn|lEs)\.([a-zA-Z_]\w*)', content):
            tested_keys.add(m.group(1))
        for m in re.finditer(r'AppLocalizations[Ee][ns]\(\)\.([a-zA-Z_]\w*)', content):
            tested_keys.add(m.group(1))

untested = sorted(all_keys - tested_keys)

param_from_meta = set()
for k in untested:
    meta_key = f'@{k}'
    meta = en.get(meta_key, {})
    if isinstance(meta, dict) and 'placeholders' in meta:
        param_from_meta.add(k)

param_methods = sorted(param_from_meta)
simple_getters = sorted(set(untested) - param_from_meta)

def esc(s):
    s = s.replace("\\", "\\\\")
    s = s.replace("'", "\\'")
    s = s.replace("\n", "\\n")
    return s

lines = []
lines.append("import 'package:flutter_test/flutter_test.dart';")
lines.append("import 'package:studyking/l10n/generated/app_localizations_en.dart';")
lines.append("import 'package:studyking/l10n/generated/app_localizations_es.dart';")
lines.append("")
lines.append("// ignore_for_file: type=lint")
lines.append("")

# Group simple getters into larger test functions (group by domain)
domains = {
    'backup': lambda k: k.startswith(('backup', 'import', 'export', 'merge', 'overwrite', 'exclude', 'sensitive', 'selectBox', 'selectBackup', 'boxCount', 'lastBackup', 'backupShare', 'backupInterval', 'backupNow', 'backupCompleted', 'backupContains', 'backupRestore', 'selectedBox', 'invalidBackupFile', 'backupExportFailed', 'backupExported', 'restore', 'mergeRestore','overwriteRestore', 'sensitiveDataWillBe', 'keepOld', 'importConfirm', 'importFailed', 'importFromFile', 'importPreview', 'importRestart', 'importSuccess')),
    'mentor_context': lambda k: k.startswith('mentorContext'),
    'mentor_other': lambda k: k.startswith(('mentor', 'tutor')) and not k.startswith('mentorContext'),
    'exam': lambda k: k.startswith(('exam', 'startExam', 'noMistakes')),
    'questions': lambda k: k.startswith(('question', 'questions', 'questionBank', 'questionCreated', 'questionDeleted', 'questionText', 'questionSubtitle', 'questionTypeDefault', 'deleteQuestion', 'deleteQuestions', 'noQuestionsFrom', 'noQuestionsPractice', 'noQuestionsTo', 'questionsAbbreviation', 'questionsAtAGlance', 'questionsDeleted', 'questionsToday', 'questionsWithoutTopic', 'questionsCountPlural')),
    'practice': lambda k: k.startswith(('practice', 'atRiskQuestions', 'correctAnswer', 'incorrectAnswer')) and not k.startswith('practiceMode'),
    'lesson_planner': lambda k: k.startswith(('lesson', 'plan', 'schedule', 'scheduled', 'milestone', 'roadmap', 'catchUp', 'redistribute', 'regenerate')),
    'notification': lambda k: k.startswith(('notif', 'notification', 'dailyReminder')),
    'nudge_adherence': lambda k: k.startswith(('nudge', 'adherence', 'adap', 'recommend')),
    'onboarding': lambda k: k.startswith(('onboarding', 'welcome', 'whileYouWereAway', 'absence', 'getStarted', 'gettingStarted')),
    'settings_profile': lambda k: k.startswith(('settings', 'profile', 'account', 'signOut', 'language', 'locale', 'theme', 'fontSize', 'appearance', 'accessibility', 'highContrast', 'bold', 'reduce', 'largeTouch', 'currentUser', 'manageYour', 'quickAccess', 'aiPowered')),
    'subjects_sources': lambda k: k.startswith(('subject', 'source', 'mySubjects', 'addNew', 'topic', 'syllabus', 'root', 'parent', 'prerequisite', 'dependencies', 'downstream', 'manage')),
    'dashboard_analytics': lambda k: k.startswith(('dashboard', 'overall', 'mastery', 'progress', 'instrumentation', 'weekly', 'currentStreak', 'avg', 'totalSessions', 'performance', 'sessionsBy', 'weeklyActivity', 'readiness', 'totalTopics', 'mastered', 'badges', 'avgTime', 'sessionHistoryExport')),
    'timer_focus': lambda k: k.startswith(('focus', 'timer', 'break', 'dailyLimit', 'overtime', 'confirmExit', 'staleSession', 'sessionComplete', 'sessionCompleted', 'sessionDeleted', 'sessionDetails', 'sessionDuration', 'sessionHistory', 'sessionNumber', 'sessionProgress', 'sessionResults', 'sessionTracking', 'sessionType', 'startStudying', 'startYourFirst')),
    'drawing_canvas': lambda k: k.startswith(('draw', 'canvas', 'stroke', 'clearAll', 'undo', 'redo', 'saveDrawing', 'drawingSaved', 'drawingSubmitted', 'drawingWithStrokes', 'noDrawing', 'invalidDrawing', 'graphCanvas', 'graphDrawing')),
    'ai_llm': lambda k: k.startswith(('ai', 'llm', 'classify', 'summarize', 'summarizing', 'evaluate', 'transcribe', 'ocr', 'llmStatus', 'connectionHealth', 'modelCap', 'modelNot')),
    'buttons_actions': lambda k: k.startswith(('confirm', 'save', 'delete', 'edit', 'discard', 'selectAll', 'deselect', 'more', 'viewAll', 'back', 'retry', 'skip', 'submit', 'next', 'previous', 'done', 'close', 'accept', 'dismiss', 'undo', 'redo', 'toggle', 'selectMultiple', 'addOption', 'cancelSelection', 'proceed', 'continue', 'stay', 'exit', 'iUnderstand', 'dontShow')),
    'upload_content': lambda k: k.startswith(('upload', 'file', 'content', 'url', 'paste', 'gallery', 'fetch', 'reprocess', 'reprocessing', 'ocr')),
    'audio_voice': lambda k: k.startswith(('audio', 'voice', 'mic', 'microphone', 'recording', 'record')),
    'sort_filter': lambda k: k.startswith(('sort', 'filter', 'search', 'allSources', 'allStatuses', 'allSubjects', 'allTypes', 'status')),
    'source_types': lambda k: k.startswith(('pdf', 'textbook', 'video', 'lecture', 'web', 'image', 'document', 'syllabus', 'external', 'slide', 'diagram', 'essay', 'math', 'mcq', 'inputLabel', 'graphLabel', 'multipleChoice', 'multipleSelect', 'textAnswer', 'stepByStep', 'audioRecording', 'canvas', 'fileUpload', 'graphDrawing', 'graphQuestion')),
    'errors': lambda k: k.startswith(('error', 'couldNot', 'failed', 'unable', 'invalid', 'unknown', 'network', 'database', 'timeout', 'noActivity', 'noAnswer', 'noBadges', 'noCode', 'noData', 'noDescription', 'noExam', 'noExtracted', 'noFailed', 'noLessons', 'noLimit', 'noLlm', 'noMistakes', 'noOptions', 'noPlan', 'noPractice', 'noQuestions', 'noReviews', 'noRoadmaps', 'noSessions', 'noSources', 'noStudyPlan', 'noSubjects', 'noSummary', 'noThanks', 'noTopicData', 'noTopics', 'noWeakAreas', 'orphaned', 'pageNotFound', 'studentIdMismatch')),
    'api_config': lambda k: k.startswith(('api', 'model', 'requestTime', 'secondsValue', 'minutesValue')),
    'settings_tiles': lambda k: k.startswith(('userManagement', 'quickGuide', 'aiConfiguration', 'studyPreferences', 'studyReminders', 'enableNotif', 'sessionDuration', 'studyAnalytics', 'aboutSection', 'aboutStudyKing', 'versionInfo', 'studyPlanner', 'backupAndRestore', 'exportAll', 'importFrom')),
    'onboarding_tour': lambda k: k.startswith(('showOnboarding', 'onboarding')),
    'lesson_build': lambda k: k.startswith(('lessonBuild', 'lessonPlan', 'lessonSystem', 'lessonReady', 'lessonSaved', 'lessonScheduled', 'lessonTime', 'lessonPractice', 'lessonsCount', 'upcomingLessonsCount', 'generateLessonFrom')),
    'syllabus_topics': lambda k: k.startswith(('syl', 'topicClassification', 'topicCount', 'topicCreate', 'topicCreated', 'topicDelete', 'topicDeleted', 'topicDescription', 'topicTitle', 'topicUpdate', 'topicUpdated', 'topicsAuto', 'topicsNeed', 'prerequisite', 'noTopicsFor')),
    'Misc': lambda k: True,
}

def categorize(k):
    for name, pred in domains.items():
        if pred(k):
            return name
    return 'Misc'

categorized = {}
for k in simple_getters:
    cat = categorize(k)
    categorized.setdefault(cat, []).append(k)

# Filter to meaningful categories
skip_cats = {'Misc'}
# Generate EN file
lines.append("void main() {")

# Group EN simple getters
lines.append("  group('AppLocalizationsEn - Missing Simple Getters', () {")
lines.append("    late AppLocalizationsEn l10n;")
lines.append("    setUp(() { l10n = AppLocalizationsEn(); });")
lines.append("")

for cat in sorted(categorized.keys()):
    if cat in skip_cats:
        continue
    keys = categorized[cat]
    if not keys:
        continue
    test_name = cat.replace('_', ' ').title()
    lines.append(f"    test('{test_name}', () {{")
    for k in keys:
        val = en.get(k, '')
        if isinstance(val, str):
            escaped = esc(val)
            lines.append(f"      expect(l10n.{k}, '{escaped}');")
    lines.append("    });")
    lines.append("")

# Misc keys
for k in categorized.get('Misc', []):
    val = en.get(k, '')
    if isinstance(val, str):
        escaped = esc(val)
        lines.append(f"    test('{k}', () => expect(l10n.{k}, '{escaped}'));")

lines.append("  });")
lines.append("")

# EN param methods
lines.append("  group('AppLocalizationsEn - Missing Parameterized Methods', () {")
lines.append("    late AppLocalizationsEn l10n;")
lines.append("    setUp(() { l10n = AppLocalizationsEn(); });")
lines.append("")

for k in param_methods:
    meta = en.get(f'@{k}', {})
    if isinstance(meta, dict):
        ph = meta.get('placeholders', {})
    else:
        ph = {}
    args = []
    for pname, pinfo in ph.items():
        ptype = pinfo.get('type', 'String') if isinstance(pinfo, dict) else 'String'
        if ptype == 'int':
            args.append('3')
        elif ptype in ('double', 'num'):
            args.append('1.5')
        else:
            args.append(f"'test_{pname}'")
    
    if args:
        call = f"{k}({', '.join(args)})"
    else:
        call = k
    lines.append(f"    test('{k}', () => expect(l10n.{call}, isNotEmpty));")

lines.append("  });")
lines.append("")

# ES simple getters
lines.append("  group('AppLocalizationsEs - Missing Simple Getters', () {")
lines.append("    late AppLocalizationsEs l10n;")
lines.append("    setUp(() { l10n = AppLocalizationsEs(); });")
lines.append("")

for cat in sorted(categorized.keys()):
    if cat in skip_cats:
        continue
    keys = categorized[cat]
    if not keys:
        continue
    test_name = cat.replace('_', ' ').title()
    lines.append(f"    test('{test_name}', () {{")
    for k in keys:
        val = es.get(k, '')
        if isinstance(val, str):
            escaped = esc(val)
            lines.append(f"      expect(l10n.{k}, '{escaped}');")
    lines.append("    });")
    lines.append("")

for k in categorized.get('Misc', []):
    val = es.get(k, '')
    if isinstance(val, str):
        escaped = esc(val)
        lines.append(f"    test('{k}', () => expect(l10n.{k}, '{escaped}'));")

lines.append("  });")
lines.append("")

# ES param methods
lines.append("  group('AppLocalizationsEs - Missing Parameterized Methods', () {")
lines.append("    late AppLocalizationsEs l10n;")
lines.append("    setUp(() { l10n = AppLocalizationsEs(); });")
lines.append("")

for k in param_methods:
    meta = es.get(f'@{k}', {})
    if isinstance(meta, dict):
        ph = meta.get('placeholders', {})
    else:
        ph = {}
    args = []
    for pname, pinfo in ph.items():
        ptype = pinfo.get('type', 'String') if isinstance(pinfo, dict) else 'String'
        if ptype == 'int':
            args.append('3')
        elif ptype in ('double', 'num'):
            args.append('1.5')
        else:
            args.append(f"'test_{pname}'")
    
    if args:
        call = f"{k}({', '.join(args)})"
    else:
        call = k
    lines.append(f"    test('{k}', () => expect(l10n.{call}, isNotEmpty));")

lines.append("  });")
lines.append("}")

with open('test/l10n/app_localizations_missing_coverage_test.dart', 'w') as f:
    f.write('\n'.join(lines))

print(f"Written {len(lines)} lines covering {len(simple_getters)} simple getters and {len(param_methods)} param methods")
