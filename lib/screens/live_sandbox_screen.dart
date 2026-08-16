import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../state/app_state.dart';
import '../constants/app_constants.dart';
import '../models/sandbox_mission.dart';
import '../models/run_history_entry.dart';
import '../models/badge_def.dart';
import '../widgets/google_fonts_shim.dart';
import '../widgets/app_toast.dart';
import '../widgets/salary_unlock_dialog.dart';
import '../services/persistence_service.dart';

class LiveSandboxScreen extends StatefulWidget {
  const LiveSandboxScreen({super.key});

  @override
  State<LiveSandboxScreen> createState() => _LiveSandboxScreenState();
}

class _LiveSandboxScreenState extends State<LiveSandboxScreen> {
  int _missionIndex = 0;

  SandboxMission get _mission => kSandboxMissions[_missionIndex];

  late final TextEditingController _codeController =
  TextEditingController(text: kSandboxMissions[0].starterCode);
  final TextEditingController _consoleInputController = TextEditingController();
  final ScrollController _consoleScrollController = ScrollController();

  String _output = "System ready. Select a script to run.\n";
  bool _isReady = false;
  bool _isRunning = false;
  bool _isTesting = false;

  late List<bool?> _testResults = List<bool?>.filled(
      _mission.tests.length, null);

  bool _hintVisible = false;
  bool _hintLoading = false;
  String _hintText = '';

  bool _isDesktop = false;
  String _pythonCommand = '';

  late final WebViewController _webViewController;
  Completer<String>? _pendingCompleter;

  // Multi-file project support
  Map<String, String> _projectFiles = {
    'main.py': kSandboxMissions[0].starterCode,
  };
  String _activeFileName = 'main.py';

  // ประวัติการรันล่าสุด — ย้ายไปเก็บที่ AppState แล้ว (ใช้ร่วมกับแท็บ ตั้งค่า)
  List<RunHistoryEntry> get _runHistory => context.watch<AppState>().runHistory;

  double get _editorFontSize => context.watch<AppState>().editorFontSize;

  // ตั้งค่า — ย้ายไปเก็บที่ AppState แล้ว (ใช้ร่วมกันทั้งแอป)
  bool get _settingsAutoSave => context.watch<AppState>().settingsAutoSave;
  set _settingsAutoSave(bool v) => context.read<AppState>().updateAutoSave(v);

  bool get _settingsShowLineNumbers => context.watch<AppState>().settingsShowLineNumbers;
  set _settingsShowLineNumbers(bool v) => context.read<AppState>().updateShowLineNumbers(v);

  String get _settingsFontSize => context.watch<AppState>().settingsFontSize;
  set _settingsFontSize(String v) => context.read<AppState>().updateFontSize(v);

  // หลักสูตรที่วางแผนไว้ — ย้ายไปเก็บที่ AppState แล้ว (ใช้ร่วมกับแท็บ ตั้งค่า)
  List<String> get _plannedCurriculum => context.watch<AppState>().plannedCurriculum;
  Set<String> get _completedCurriculum => context.watch<AppState>().completedCurriculum;

  @override
  void initState() {
    super.initState();
    _initEnvironment();
    _loadPersistedSandbox();
  }

  /// โหลดไฟล์โค้ด + ประวัติรันจาก Supabase
  Future<void> _loadPersistedSandbox() async {
    final files = await PersistenceService.loadSandboxFiles();
    if (!mounted) return;
    if (files.isNotEmpty) {
      setState(() {
        _projectFiles = Map<String, String>.from(files);
        if (!_projectFiles.containsKey('main.py')) {
          _projectFiles['main.py'] = kSandboxMissions[0].starterCode;
        }
        _activeFileName = _projectFiles.containsKey('main.py')
            ? 'main.py'
            : _projectFiles.keys.first;
        _codeController.text = _projectFiles[_activeFileName] ?? '';
      });
    }
    // โหลดประวัติรันเข้า AppState (เฉพาะที่ยังว่าง)
    final runs = await PersistenceService.loadCodeRuns(limit: 15);
    if (!mounted || runs.isEmpty) return;
    final state = context.read<AppState>();
    if (state.runHistory.isNotEmpty) return;
    for (final r in runs.reversed) {
      state.addRunHistory(RunHistoryEntry(
        missionTitle: (r['mission_id'] as String?) ?? (r['file_name'] as String?) ?? 'run',
        code: (r['code'] as String?) ?? '',
        output: (r['output'] as String?) ?? '',
        timestamp: DateTime.tryParse((r['created_at'] as String?) ?? '') ?? DateTime.now(),
      ));
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _consoleInputController.dispose();
    _consoleScrollController.dispose();
    super.dispose();
  }

  void _appendOutput(String text) {
    setState(() => _output += text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_consoleScrollController.hasClients) {
        _consoleScrollController.jumpTo(
            _consoleScrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _initEnvironment() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      _isDesktop = true;
      await _checkLocalPython();
    } else {
      _isDesktop = false;
      _initMobilePyodide();
    }
  }

  // --------------------------------------------------
  // DESKTOP (LOCAL PYTHON)
  // --------------------------------------------------
  Future<void> _checkLocalPython() async {
    final candidates = <String>['python3', 'python', 'py'];
    for (final command in candidates) {
      try {
        final args = command == 'py' ? <String>['-3', '--version'] : <String>[
          '--version'
        ];
        final result = await Process
            .run(command, args, runInShell: true)
            .timeout(const Duration(seconds: 5));

        if (result.exitCode == 0) {
          if (!mounted) return;
          setState(() {
            _pythonCommand = command;
            _isReady = true;
            _output += "\n[Desktop Mode] Python พร้อมใช้งานแล้ว ($command)";
          });
          return;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _isReady = false;
      _output =
      "ไม่พบ Python ในเครื่อง\nติดตั้ง Python 3 จาก python.org แล้วเปิดแอปใหม่";
    });
  }


  Future<void> _runDesktopCode() async {
    final code = _codeController.text;
    _appendOutput("\n\n> Executing main.py...\n");

    File? tempFile;
    try {
      // 1. แอบสร้างไฟล์ temp_sandbox.py ชั่วคราว เพื่อแก้ปัญหา Windows ตัดโค้ดหลายบรรทัดทิ้ง
      tempFile = File('temp_sandbox.py');
      await tempFile.writeAsString(code);

      // 2. สั่งรันจากไฟล์โดยตรงแทนการใช้ -c
      final args = _pythonCommand == 'py'
          ? <String>['-3', '-u', tempFile.path]
          : <String>['-u', tempFile.path];

      // ปิด runInShell เพื่อให้รันได้เสถียรที่สุด
      final process = await Process.start(_pythonCommand, args);

      // ส่งค่าจากช่อง Input
      final testInput = _consoleInputController.text;

      process.stdin.writeln(testInput);
      await process.stdin.close();

// ดึงผลลัพธ์
      final stdoutText = await process.stdout.transform(utf8.decoder).join();
      final stderrText = await process.stderr.transform(utf8.decoder).join();

      if (!mounted) return;

      final buffer = StringBuffer();

      // 1. จัดการ Output ปกติ
      if (stdoutText.isNotEmpty) {
        buffer.write(stdoutText); // ใช้ write แทน writeln เพื่อรักษาข้อความเดิม

        // เช็คว่าถ้าข้อความสุดท้ายไม่ใช่การขึ้นบรรทัดใหม่ ให้ขึ้นบรรทัดใหม่รอไว้เลย
        // เพื่อป้องกันไม่ให้ข้อความ Error ไปต่อท้ายในบรรทัดเดียวกัน
        if (!stdoutText.endsWith('\n')) {
          buffer.writeln();
        }
      }

      // 2. จัดการ Error
      if (stderrText.isNotEmpty) {
        // ดักจับ Error กรณีที่ผู้ใช้ลืมพิมพ์ตัวเลขส่งเข้าไปโดยเฉพาะ
        if (stderrText.contains("ValueError: invalid literal for int()")) {
          buffer.writeln("โปรแกรมถูกยกเลิก: กรุณาพิมพ์ตัวเลขในช่องด้านล่างก่อนรันครับ");
        } else {
          // ถ้าเป็น Error ชนิดอื่นๆ ให้ดึงมาแค่บรรทัดสุดท้ายที่บอกสาเหตุ
          final errorLines = stderrText.trim().split('\n');
          final actualError = errorLines.isNotEmpty ? errorLines.last : 'เกิดข้อผิดพลาด';
          buffer.writeln("แจ้งเตือน: $actualError");
        }
      }

      setState(() {
        _output += buffer.toString();
        _isRunning = false;
      });

      _consoleInputController.clear();

    } catch (e) {
      setState(() {
        _output += "[System Error] ไม่สามารถรัน Python ได้\n$e";
        _isRunning = false;
      });
    } finally {
      // 3. ลบไฟล์ชั่วคราวทิ้งเสมอเมื่อรันจบ เพื่อไม่ให้รกเครื่อง
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }
  // --------------------------------------------------
  // MOBILE (PYODIDE WEBVIEW)
  // --------------------------------------------------
  void _initMobilePyodide() {
    // Pyodide engine (v0.25) — ใช้ indexURL ชัดเจนเพื่อให้โหลด WASM ได้บน Windows/Desktop
    const String pyodideHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Pyodide Engine Bridge</title>
</head>
<body style="background:#080c14;color:#fff;font-family:monospace;margin:0;padding:8px;">
<div id="status">Loading Pyodide...</div>
<script>
  let pyodide = null;

  function send(msg) {
    try {
      if (window.SandboxChannel && SandboxChannel.postMessage) {
        SandboxChannel.postMessage(msg);
      }
    } catch (e) {}
  }

  const script = document.createElement('script');
  script.src = "https://cdn.jsdelivr.net/pyodide/v0.25.0/full/pyodide.js";
  script.onload = async () => {
    document.getElementById('status').innerText = 'Initializing WASM Engine...';
    try {
      pyodide = await loadPyodide({
        indexURL: "https://cdn.jsdelivr.net/pyodide/v0.25.0/full/"
      });
      document.getElementById('status').innerText = 'Pyodide Engine Ready';
      send("READY");
    } catch (err) {
      document.getElementById('status').innerText = 'Error: ' + err;
      send("ERROR: " + err.toString());
    }
  };
  script.onerror = () => {
    const msg = 'Failed to load Pyodide from CDN';
    document.getElementById('status').innerText = msg;
    send("ERROR: " + msg);
  };
  document.head.appendChild(script);

  async function runPython(code, inputValue) {
    if (!pyodide) {
      send("ERROR: Pyodide engine is not ready yet.");
      return;
    }
    try {
      let output = "";
      pyodide.setStdout({ batched: (msg) => { output += msg + "\\n"; } });
      pyodide.setStderr({ batched: (msg) => { output += "[stderr] " + msg + "\\n"; } });

      // รองรับ input หลายบรรทัด (แยกด้วย \\n)
      const inputs = String(inputValue == null ? "" : inputValue).split("\\n");
      let idx = 0;
      const inputJson = JSON.stringify(inputs);
      const prepCode =
        "import builtins\\n" +
        "_inputs = " + inputJson + "\\n" +
        "_idx = 0\\n" +
        "def mock_input(prompt=''):\\n" +
        "    global _idx\\n" +
        "    if _idx < len(_inputs):\\n" +
        "        v = _inputs[_idx]\\n" +
        "        _idx += 1\\n" +
        "        return v\\n" +
        "    return ''\\n" +
        "builtins.input = mock_input\\n" +
        code;

      await pyodide.runPythonAsync(prepCode);
      send("RESULT: " + output);
    } catch (err) {
      send("ERROR: " + (err.message || err.toString()));
    }
  }
</script>
</body>
</html>
''';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'SandboxChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == "READY") {
            setState(() {
              _isReady = true;
              _output += "\n[Mobile Mode] Pyodide พร้อมใช้งานแล้ว";
            });
          } else if (message.message.startsWith("RESULT: ")) {
            final text = message.message.replaceFirst("RESULT: ", "").trim();
            if (_pendingCompleter != null) {
              final c = _pendingCompleter!;
              _pendingCompleter = null;
              if (!c.isCompleted) c.complete(text);
            } else {
              setState(() {
                _output += text;
                if (_output.endsWith("Executing main.py...\n")) {
                  _output += "Script finished successfully.";
                }
                _isRunning = false;
              });
            }
          } else if (message.message.startsWith("ERROR: ")) {
            final text = message.message.replaceFirst("ERROR: ", "");
            if (_pendingCompleter != null) {
              final c = _pendingCompleter!;
              _pendingCompleter = null;
              if (!c.isCompleted) c.complete("[Error] $text");
            } else {
              setState(() {
                _output += "[Python Error]\n$text";
                _isRunning = false;
              });
            }
          }
        },
      )
      ..loadHtmlString(pyodideHtml);
  }

  void _runMobileCode() {
    final code = _codeController.text;
    final inputStr = _consoleInputController.text;
    _appendOutput("\n\n> Executing on Pyodide...\n");
    final argsStr = '${jsonEncode(code)}, ${jsonEncode(inputStr)}';
    _webViewController.runJavaScript('runPython($argsStr);');
  }


  // --------------------------------------------------
  // EXECUTE / RESET
  // --------------------------------------------------
  void _execute() {
    if (!_isReady || _isRunning) return;
    if (_codeController.text
        .trim()
        .isEmpty) {
      _appendOutput("\n[Error] กรุณาใส่ Python code ก่อน");
      return;
    }

    // Keep project map in sync with current editor content
    _projectFiles[_activeFileName] = _codeController.text;

    setState(() => _isRunning = true);
    context.read<AppState>().incrementRunCount();
    _announceNewBadges();

    // บันทึก History
    final snapshot = _codeController.text;
    final missionSnap = _mission.title;
    if (_isDesktop) {
      _runDesktopCode().then((_) {
        _addRunHistory(missionSnap, snapshot, _output);
      });
    } else {
      _runMobileCode();
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) _addRunHistory(missionSnap, snapshot, _output);
      });
    }
  }

  void _addRunHistory(String mission, String code, String output) {
    if (!mounted) return;
    context.read<AppState>().addRunHistory(RunHistoryEntry(
      missionTitle: mission,
      code: code,
      output: output,
      timestamp: DateTime.now(),
    ));
    // บันทึกลง Supabase
    PersistenceService.saveCodeRun(
      code: code,
      output: output,
      fileName: _activeFileName,
      success: !output.contains('[Python Error]') && !output.contains('[Error]'),
    );
    // auto-save ไฟล์ปัจจุบัน
    PersistenceService.saveSandboxFile(_activeFileName, code);
  }

  void _clearConsole() {
    setState(() {
      _output = "System ready. Select a script to run.\n";
    });
  }

  void _selectMission(int index) {
    if (index == _missionIndex || _isRunning || _isTesting) return;
    setState(() {
      // เซฟโค้ดไฟล์ที่เปิดอยู่ก่อนสลับ Mission
      _projectFiles[_activeFileName] = _codeController.text;

      _missionIndex = index;

      // อัปเดตเฉพาะ main.py เป็น starter ของ Mission ใหม่
      // ไฟล์อื่นที่สร้างไว้ (เช่น utils.py, ddd.py) ยังคงอยู่
      _projectFiles['main.py'] = _mission.starterCode;

      // สลับกลับไปที่ main.py เสมอเมื่อเปลี่ยน Mission
      _activeFileName = 'main.py';
      _codeController.text = _mission.starterCode;

      _testResults = List<bool?>.filled(_mission.tests.length, null);
      _hintVisible = false;
      _hintText = '';
      _output = "System ready. Mission switched to \"${_mission.title}\".\n";
    });
  }

  void _resetCode() {
    setState(() {
      // Reset เฉพาะ main.py แล้วสลับไปที่ไฟล์นั้น
      _projectFiles['main.py'] = _mission.starterCode;
      _activeFileName = 'main.py';
      _codeController.text = _mission.starterCode;
    });
    showAppToast(
        context, 'รีเซ็ตโค้ดกลับเป็นค่าเริ่มต้นแล้ว', type: ToastType.info);
  }

  // สลับไฟล์ (เซฟโค้ดปัจจุบันก่อน + sync ขึ้น cloud)
  void _switchFile(String fileName) {
    if (_activeFileName == fileName) return;
    final prev = _activeFileName;
    final prevContent = _codeController.text;
    setState(() {
      _projectFiles[prev] = prevContent;
      _activeFileName = fileName;
      _codeController.text = _projectFiles[fileName] ?? '';
    });
    PersistenceService.saveSandboxFile(prev, prevContent);
  }

  // ลบไฟล์ (ลบ main.py ไม่ได้)
  void _deleteFile(String fileName) {
    if (fileName == 'main.py') {
      showAppToast(context, 'ไม่สามารถลบไฟล์ main.py ได้ครับ', type: ToastType.error);
      return;
    }
    setState(() {
      _projectFiles.remove(fileName);
      if (_activeFileName == fileName) {
        _activeFileName = 'main.py';
        _codeController.text = _projectFiles['main.py'] ?? '';
      }
    });
    PersistenceService.deleteSandboxFile(fileName);
  }

  // Dialog สร้างไฟล์ใหม่
  void _showAddFileDialog() {
    final fileNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
          title: Text('สร้างไฟล์ใหม่',
              style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: fileNameController,
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'เช่น utils.py',
              hintStyle: GoogleFonts.prompt(color: const Color(0xFF64748B)),
              enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF334155))),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF3B82F6))),
            ),
            onSubmitted: (_) => _createFileFromDialog(ctx, fileNameController),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('ยกเลิก', style: GoogleFonts.prompt(color: const Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _createFileFromDialog(ctx, fileNameController),
              child: Text('สร้าง', style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _createFileFromDialog(BuildContext dialogContext, TextEditingController nameCtrl) {
    String newName = nameCtrl.text.trim();
    if (newName.isEmpty) return;
    if (!newName.endsWith('.py')) {
      newName += '.py';
    }
    if (_projectFiles.containsKey(newName)) {
      showAppToast(context, 'มีไฟล์ชื่อนี้อยู่แล้ว', type: ToastType.error);
      return;
    }
    // อัปเดต map ในหน่วยความจำก่อน
    _projectFiles[_activeFileName] = _codeController.text;
    _projectFiles[newName] = '';
    setState(() {
      _activeFileName = newName;
      _codeController.text = '';
    });
    // บันทึกทั้งชุดขึ้น Supabase ทันที (สำคัญ: ต้องมีตาราง user_sandbox_files)
    PersistenceService.saveAllSandboxFiles(Map<String, String>.from(_projectFiles));
    Navigator.pop(dialogContext);
    showAppToast(context, 'สร้างไฟล์ $newName แล้ว (บันทึกบนคลาวด์แล้ว)', type: ToastType.success);
  }

  Future<void> _copyOutput() async {
    await Clipboard.setData(ClipboardData(text: _output));
    if (!mounted) return;
    showAppToast(context, 'คัดลอก Output แล้ว', type: ToastType.info);
  }

  void _announceNewBadges() {
    final newly = context.read<AppState>().checkBadgesAndReturnNew();
    for (final b in newly) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          showAppToast(context, 'Achievement: "${b.name}" — ${b.desc}',
              type: ToastType.badge);
        }
      });
    }
  }



// --------------------------------------------------
  // RUN TESTS (real functional replacement of JS runTests)
  // --------------------------------------------------
  Future<void> _runTests() async {
    if (!_isReady || _isTesting) return;
    final mission = _mission;

    // Keep project map in sync with current editor content
    _projectFiles[_activeFileName] = _codeController.text;

    setState(() {
      _isTesting = true;
      _testResults = List<bool?>.filled(mission.tests.length, null);
    });

    _appendOutput("\n\nIT Automated Testing System — ${mission.title}\n");

    bool allPassed = true;
    final code = _codeController.text;

    for (int i = 0; i < mission.tests.length; i++) {
      dynamic test = mission.tests[i];
      File? tempFile;

      try {
        // 1. สร้างไฟล์ temp ชั่วคราวสำหรับตรวจข้อสอบ
        tempFile = File('temp_test_$i.py');
        await tempFile.writeAsString(code);

        final args = _pythonCommand == 'py'
            ? <String>['-3', '-u', tempFile.path]
            : <String>['-u', tempFile.path];

        final process = await Process.start(_pythonCommand, args);

        // ดึงค่า Input แบบดักครบทุกโครงสร้าง (Map / Class Property)
        String inputVal = '';
        if (test is Map) {
          inputVal = test['input'] ?? test['inputData'] ?? test['input_data'] ?? '';
        } else {
          try { inputVal = test.input ?? ''; } catch (_) {}
          if (inputVal.isEmpty) {
            try { inputVal = test.inputData ?? ''; } catch (_) {}
          }
        }

        // ดึงค่า Expected (เพิ่มการเช็ค expectedContains เข้าไปให้ชัวร์ 100%)
        String rawExpected = '';
        if (test is Map) {
          rawExpected = test['expectedContains'] ?? test['expected'] ?? test['output'] ?? test['expectedOutput'] ?? test['expected_output'] ?? '';
        } else {
          try { rawExpected = test.expectedContains ?? ''; } catch (_) {}
          if (rawExpected.isEmpty) {
            try { rawExpected = test.expected ?? ''; } catch (_) {}
          }
          if (rawExpected.isEmpty) {
            try { rawExpected = test.output ?? ''; } catch (_) {}
          }
          if (rawExpected.isEmpty) {
            try { rawExpected = test.expectedOutput ?? ''; } catch (_) {}
          }
        }

        final String expectedVal = rawExpected.toString().trim();

        // 2. ป้อน Input เข้าไปใน Python
        process.stdin.writeln(inputVal);
        await process.stdin.close();

        // 3. อ่านผลลัพธ์ Output
        final stdoutText = await process.stdout.transform(utf8.decoder).join();
        String actualOutput = stdoutText.trim();

        // 4. เปรียบเทียบผลลัพธ์แบบใหม่! (ยกเลิกการหั่น split(':') แล้ว)
        // ใช้ .endsWith() เช็คว่า Output ลงท้ายด้วยคำตอบที่คาดหวังหรือไม่
        bool isPassed = actualOutput == expectedVal || actualOutput.endsWith(expectedVal);

        // จัดรูป actualOutput ใหม่ให้โชว์ใน Log สวยๆ
        if (isPassed && actualOutput != expectedVal) {
          actualOutput = expectedVal; // ถ้าผ่านแล้ว ตัด Prompt ทิ้งเฉพาะตอนโชว์ Log
        } else if (!isPassed && actualOutput.contains('\n')) {
          actualOutput = actualOutput.split('\n').last.trim(); // ถ้าไม่ผ่าน ดึงแค่บรรทัดสุดท้ายมาโชว์
        }

        setState(() {
          _testResults[i] = isPassed;
        });

        if (isPassed) {
          _appendOutput("PASS Test ${i + 1}\n");
        } else {
          allPassed = false;
          _appendOutput("FAIL Test ${i + 1} → expected \"$expectedVal\", got: \"$actualOutput\"\n");
        }
      } catch (e) {
        allPassed = false;
        setState(() {
          _testResults[i] = false;
        });
        _appendOutput("ERROR Test ${i + 1}: $e\n");
      } finally {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    }

    setState(() => _isTesting = false);

    final state = context.read<AppState>();
    if (allPassed) {
      final wasThisMissionDoneBefore = state.completedMissionIds.contains(
          mission.id);
      state.completeMissionById(mission.id, mission.xpReward);
      _announceNewBadges();
      if (!mounted) return;
      if (!wasThisMissionDoneBefore) {
        showAppToast(context,
            ' ผ่านทุกเทสต์! ได้รับ +${mission.xpReward * state.multiplier} XP',
            type: ToastType.success);
        showSalaryUnlockDialog(
            context, mission.title, mission.xpReward * state.multiplier);
      } else {
        showAppToast(
            context, 'ผ่านทุกเทสต์! (ทำ Mission นี้สำเร็จไปแล้วก่อนหน้านี้)',
            type: ToastType.success);
      }
    } else {
      if (!mounted) return;
      showAppToast(context, 'เทสต์ยังไม่ผ่านทั้งหมด ลองปรับแก้โค้ดดูนะครับ SUSU',
          type: ToastType.error);
    }
  }
  // --------------------------------------------------
  // AI HINT (real functional replacement of JS getAIHint)
  // --------------------------------------------------
  Future<void> _getAIHint() async {
    setState(() {
      _hintVisible = true;
      _hintLoading = true;
      _hintText = '';
    });

    final code = _codeController.text;
    final mission = _mission;
    final promptMessage =
        'ช่วยตรวจโค้ด Python นี้เพื่อทำ Mission "${mission
        .title}":\n```python\n$code\n```\nคำโจทย์: ${mission
        .description}\nช่วยให้ AI Hint คำแนะนำแบบสั้นๆ กระชับ (ไม่เกิน 2 ประโยค) เพื่อบอกแนวทางการแก้ไขโดยตรง';

    try {
      final response = await http.post(
        Uri.parse(kMentorApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Bypass-Tunnel-Reminder': 'true'
        },
        body: jsonEncode({'message': promptMessage}),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() =>
        _hintText = data['reply'] ??
            'ลองตรวจสอบ f-string หรือการรับค่าตัวแปรผ่าน input() ดูก่อนนะครับ');
      } else {
        setState(() =>
        _hintText = 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() =>
      _hintText =
      'ลองตรวจสอบว่า input() รับค่าใส่ตัวแปรถูกต้อง และรูปแบบ print/f-string ตรงกับโจทย์ "${_mission
          .description}" หรือไม่ครับ');
    } finally {
      if (mounted) setState(() => _hintLoading = false);
    }
  }

  // --------------------------------------------------
  // บันทึกไฟล์
  // --------------------------------------------------
  void _saveFile() {
    _projectFiles[_activeFileName] = _codeController.text;
    // บันทึกทุกไฟล์ในโปรเจกต์ เพื่อไม่ให้ไฟล์อื่นหายหลัง re-login
    PersistenceService.saveAllSandboxFiles(Map<String, String>.from(_projectFiles));
    showAppToast(context, 'บันทึกทั้งหมดเรียบร้อยแล้ว', type: ToastType.success);
  }

  // --------------------------------------------------
  // คัดลอกโค้ด
  // --------------------------------------------------
  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _codeController.text));
    if (!mounted) return;
    showAppToast(context, 'คัดลอกโค้ดเรียบร้อยแล้ว', type: ToastType.info);
  }

  // --------------------------------------------------
  // ตั้งค่า Sandbox
  // --------------------------------------------------
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF1E293B)),
          ),
          title: Row(
            children: [
              const Icon(Icons.settings_outlined, color: Color(0xFF94A3B8), size: 18),
              const SizedBox(width: 8),
              Text('ตั้งค่า Sandbox', style: GoogleFonts.prompt(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Auto Save
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('บันทึกอัตโนมัติ', style: GoogleFonts.prompt(
                              color: Colors.white, fontSize: 13)),
                          Text('บันทึกโค้ดเมื่อสลับไฟล์', style: GoogleFonts.prompt(
                              color: const Color(0xFF64748B), fontSize: 10)),
                        ],
                      ),
                      Switch(
                        value: _settingsAutoSave,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (v) {
                          setDialogState(() {});
                          setState(() => _settingsAutoSave = v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Show Line Numbers
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('แสดงหมายเลขบรรทัด', style: GoogleFonts.prompt(
                              color: Colors.white, fontSize: 13)),
                          Text('แสดงตัวเลขข้างโค้ด Editor', style: GoogleFonts.prompt(
                              color: const Color(0xFF64748B), fontSize: 10)),
                        ],
                      ),
                      Switch(
                        value: _settingsShowLineNumbers,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (v) {
                          setDialogState(() {});
                          setState(() => _settingsShowLineNumbers = v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Font Size
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('ขนาดตัวอักษร', style: GoogleFonts.prompt(
                          color: Colors.white, fontSize: 13)),
                      DropdownButton<String>(
                        value: _settingsFontSize,
                        dropdownColor: const Color(0xFF0F172A),
                        style: GoogleFonts.prompt(color: Colors.white, fontSize: 12),
                        underline: const SizedBox(),
                        items: ['เล็ก', 'ปกติ', 'ใหญ่']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() {});
                            setState(() => _settingsFontSize = v);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                showAppToast(context, 'บันทึกการตั้งค่าแล้ว', type: ToastType.info);
              },
              child: Text('บันทึก', style: GoogleFonts.prompt(
                  color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // ประวัติการรันล่าสุด
  // --------------------------------------------------
  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Color(0xFF94A3B8), size: 18),
                    const SizedBox(width: 8),
                    Text('ประวัติการรันล่าสุด',
                        style: GoogleFonts.prompt(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 18),
                      onPressed: () => Navigator.pop(ctx),
                      splashRadius: 16,
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1E293B), height: 1),
              if (_runHistory.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(Icons.history_toggle_off, color: Color(0xFF475569), size: 40),
                      const SizedBox(height: 12),
                      Text('ยังไม่มีประวัติการรัน', style: GoogleFonts.prompt(
                          color: const Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _runHistory.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final entry = _runHistory[i];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          title: Row(
                            children: [
                              const Icon(Icons.terminal, color: Colors.blueAccent, size: 14),
                              const SizedBox(width: 8),
                              Expanded(child: Text(entry.missionTitle,
                                  style: GoogleFonts.prompt(
                                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          subtitle: Text(entry.timeLabel,
                              style: GoogleFonts.prompt(color: const Color(0xFF64748B), fontSize: 10)),
                          iconColor: const Color(0xFF94A3B8),
                          collapsedIconColor: const Color(0xFF475569),
                          children: [
                            // โค้ดที่รัน
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('CODE:', style: GoogleFonts.prompt(
                                  color: const Color(0xFF475569), fontSize: 9,
                                  fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1117),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                entry.code.length > 300
                                    ? '${entry.code.substring(0, 300)}...'
                                    : entry.code,
                                style: GoogleFonts.jetBrainsMono(
                                    color: const Color(0xFFCBD5E1), fontSize: 10, height: 1.4),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // ปุ่มโหลดโค้ดนี้กลับมา
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _codeController.text = entry.code;
                                      _projectFiles[_activeFileName] = entry.code;
                                    });
                                    Navigator.pop(ctx);
                                    showAppToast(context, 'โหลดโค้ดจากประวัติแล้ว',
                                        type: ToastType.info);
                                  },
                                  icon: const Icon(Icons.restore, size: 14, color: Color(0xFF3B82F6)),
                                  label: Text('โหลดโค้ดนี้',
                                      style: GoogleFonts.prompt(color: const Color(0xFF3B82F6), fontSize: 11)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _submitProject() {
    showAppToast(context, 'ส่งผลงานเข้าสู่ IT Cloud Portfolio สำเร็จ!',
        type: ToastType.success);
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery
        .of(context)
        .size
        .width >= 900;

    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: state.bgColor,
      appBar: _buildIDEAppBar(),
      body: Column(
        children: [
          Expanded(
            child: isWide
                ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLeftSidebar(),
                Container(width: 1, color: state.borderColor),
                Expanded(child: _buildCodeEditor()),
                Container(width: 1, color: state.borderColor),
                _buildRightConsole(),
              ],
            )
                : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 340, child: _buildCodeEditor()),
                  Container(height: 1, color: state.borderColor),
                  SizedBox(height: 260, child: _buildRightConsole()),
                  Container(height: 1, color: state.borderColor),
                  _buildLeftSidebar(),
                ],
              ),
            ),
          ),
          if (!_isDesktop)
            SizedBox(
              height: 1,
              width: 1,
              child: WebViewWidget(controller: _webViewController),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildIDEAppBar() {
    final state = context.watch<AppState>();
    return AppBar(
      backgroundColor: state.sidebarColor,
      foregroundColor: state.textPrimary,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: state.borderColor, height: 1.0),
      ),
      title: Row(
        children: [
          Icon(
              Icons.terminal_rounded, color: state.accentColor, size: 24),
          const SizedBox(width: 8),
          Flexible(
            child: Text('LearnPro IT Live Sandbox',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.prompt(fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: state.textPrimary)),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (_isReady ? Colors.orange : Colors.grey).withValues(
                  alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _isReady ? Colors.orange.shade700 : Colors.grey),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isReady ? Icons.bolt : Icons.hourglass_bottom,
                    color: _isReady ? Colors.orange : Colors.grey, size: 12),
                const SizedBox(width: 4),
                Text(_isReady ? 'Engine Ready' : 'Loading...',
                    style: GoogleFonts.prompt(
                        color: _isReady ? Colors.orange : Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _buildAppbarButton(
          _hintLoading ? Icons.sync : Icons.lightbulb_outline,
          'AI Hint',
          const Color(0xFF3B0764),
          Colors.white,
          onPressed: _hintLoading ? null : _getAIHint,
        ),
        const SizedBox(width: 8),
        _buildAppbarOutlineButton(
          _isTesting ? Icons.sync : Icons.science_outlined,
          _isTesting ? 'Testing...' : 'Run Tests',
          Colors.blueAccent,
          onPressed: (_isReady && !_isTesting) ? _runTests : null,
        ),
        const SizedBox(width: 8),
        _buildAppbarButton(
          _isRunning ? Icons.sync : Icons.play_arrow,
          _isRunning ? 'Running...' : 'Execute',
          _isRunning
              ? Colors.grey.shade800
              : (context.watch<AppState>().isLightTheme
              ? const Color(0xFF1D4ED8)
              : const Color(0xFF1E293B)),
          _isRunning ? Colors.grey.shade400 : Colors.white,
          onPressed: (_isReady && !_isRunning) ? _execute : null,
        ),
        const SizedBox(width: 8),
        // ปุ่ม บันทึกไฟล์
        _buildAppbarOutlineButton(
          Icons.save_outlined,
          'Save',
          const Color(0xFF34D399),
          onPressed: _saveFile,
        ),
        const SizedBox(width: 8),
        // ปุ่ม คัดลอกโค้ด
        _buildAppbarOutlineButton(
          Icons.copy_outlined,
          'Copy Code',
          const Color(0xFFFBBF24),
          onPressed: _copyCode,
        ),
        const SizedBox(width: 8),
        _buildAppbarButton(
            Icons.cloud_upload, 'Submit', Colors.blue.shade700, Colors.white,
            onPressed: _submitProject),
        const SizedBox(width: 8),
        _buildAppbarOutlineButton(
          Icons.replay,
          'Reset',
          const Color(0xFF94A3B8),
          onPressed: (_isRunning || _isTesting) ? null : _resetCode,
        ),
        const SizedBox(width: 8),
        // ปุ่ม ตั้งค่า
        IconButton(
          icon: Icon(Icons.settings_outlined, color: context.watch<AppState>().textMuted, size: 18),
          tooltip: 'ตั้งค่า Sandbox',
          splashRadius: 18,
          onPressed: _showSettingsDialog,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAppbarButton(IconData icon, String label, Color bgColor,
      Color textColor, {VoidCallback? onPressed}) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(icon, color: textColor, size: 14),
                const SizedBox(width: 6),
                Text(label, style: GoogleFonts.prompt(color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppbarOutlineButton(IconData icon, String label, Color color,
      {VoidCallback? onPressed}) {
    final active = onPressed != null;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: active ? color : Colors.grey.shade700),
            ),
            child: Row(
              children: [
                Icon(icon, color: active ? color : Colors.grey, size: 14),
                const SizedBox(width: 6),
                Text(label, style: GoogleFonts.prompt(
                    color: active ? color : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftSidebar() {
    final state = context.watch<AppState>();
    return Container(
      width: 280,
      color: state.sidebarColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('MISSIONS', style: GoogleFonts.prompt(
              color: state.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(kSandboxMissions.length, (i) {
              final m = kSandboxMissions[i];
              final active = i == _missionIndex;
              final done = state.completedMissionIds.contains(m.id);
              return InkWell(
                onTap: () => _selectMission(i),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? (state.isLightTheme ? const Color(0xFFDBEAFE) : const Color(0xFF1E3A8A))
                        : state.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: active ? Colors.blueAccent : state.borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (done)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                              Icons.check_circle, color: Color(0xFF34D399),
                              size: 11),
                        ),
                      Text('${i + 1}',
                          style: GoogleFonts.jetBrainsMono(
                              color: active
                                  ? (state.isLightTheme ? const Color(0xFF1D4ED8) : Colors.white)
                                  : state.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(
                    'MISSION ${(_missionIndex + 1).toString().padLeft(2, '0')}',
                    style: GoogleFonts.prompt(color: const Color(0xFF34D399),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              Row(
                children: [
                  const Icon(
                      Icons.monetization_on, color: Colors.amber, size: 12),
                  const SizedBox(width: 4),
                  Text('+${_mission.xpReward} XP', style: GoogleFonts.prompt(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(_mission.title, style: GoogleFonts.prompt(
              color: state.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_mission.description,
              style: GoogleFonts.prompt(
                  color: state.textSecondary, fontSize: 11, height: 1.5)),
          const SizedBox(height: 16),

          if (_hintVisible)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E1065).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6B21A8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFC084FC),
                          size: 14),
                      const SizedBox(width: 6),
                      Text('AI HINT', style: GoogleFonts.prompt(
                          color: const Color(0xFFC084FC),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_hintLoading)
                    Row(
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFFC084FC)),
                        ),
                        const SizedBox(width: 8),
                        Text('กำลังวิเคราะห์โค้ด...', style: GoogleFonts.prompt(
                            color: const Color(0xFFE9D5FF), fontSize: 10)),
                      ],
                    )
                  else
                    Text(_hintText, style: GoogleFonts.prompt(
                        color: const Color(0xFFE9D5FF),
                        fontSize: 10,
                        height: 1.5)),
                ],
              ),
            ),

          Text('TEST CASES', style: GoogleFonts.prompt(
              color: state.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: state.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: state.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_mission.tests.length, (i) {
                final result = i < _testResults.length ? _testResults[i] : null;
                final isLast = i == _mission.tests.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                  child: _buildTestCaseItem(result, _mission.tests[i].label),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // ─── ประวัติการรันล่าสุด ───────────────────────────
          const SizedBox(height: 20),
          InkWell(
            onTap: _showHistoryDialog,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: state.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: state.borderColor),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: state.textMuted, size: 14),
                      const SizedBox(width: 6),
                      Text('ประวัติการรันล่าสุด', style: GoogleFonts.prompt(
                          color: state.textSecondary, fontSize: 11,
                          fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      if (_runHistory.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${_runHistory.length}', style: GoogleFonts.prompt(
                              color: Colors.blueAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Color(0xFF475569), size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── หลักสูตรที่วางแผนไว้ ──────────────────────────
          const SizedBox(height: 16),
          Text('PLANNED CURRICULUM', style: GoogleFonts.prompt(
              color: state.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)),
          const SizedBox(height: 8),
          ..._plannedCurriculum.asMap().entries.map((entry) {
            final idx = entry.key;
            final topic = entry.value;
            final done = _completedCurriculum.contains(topic);
            return GestureDetector(
              onTap: () {
                context.read<AppState>().toggleCurriculumTopic(topic);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: done
                      ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                      : state.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: done ? const Color(0xFF065F46) : state.borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done ? const Color(0xFF34D399) : state.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${idx + 1}. $topic',
                          style: GoogleFonts.prompt(
                            color: done
                                ? const Color(0xFF34D399)
                                : state.textSecondary,
                            fontSize: 11,
                            decoration: done ? TextDecoration.lineThrough : null,
                          ).copyWith(decorationColor: const Color(0xFF34D399))),
                    ),
                  ],
                ),
              ),
            );
          }),

          // ─── PROJECT FILES ──────────────────────────────────
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROJECT FILES', style: GoogleFonts.prompt(
                  color: state.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
              InkWell(
                onTap: _showAddFileDialog,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.add, color: state.textMuted, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._projectFiles.keys.map((fileName) {
            final isActive = fileName == _activeFileName;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isActive ? state.cardAltColor : state.cardColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isActive ? Colors.blueAccent.withValues(alpha: 0.5) : state.borderColor,
                ),
              ),
              child: InkWell(
                onTap: () => _switchFile(fileName),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.code, color: Colors.blueAccent, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: GoogleFonts.prompt(
                            color: isActive ? state.textPrimary : state.textSecondary,
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (fileName != 'main.py')
                        InkWell(
                          onTap: () => _deleteFile(fileName),
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.close, color: Color(0xFFF87171), size: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTestCaseItem(bool? state, String text) {
    IconData icon;
    Color color;
    if (state == null) {
      icon = Icons.radio_button_unchecked;
      color = const Color(0xFF475569);
    } else if (state) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else {
      icon = Icons.cancel;
      color = Colors.redAccent;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.prompt(
            color: const Color(0xFF94A3B8), fontSize: 10))),
      ],
    );
  }

  Widget _buildCodeEditor() {
    final state = context.watch<AppState>();
    final editorBg = state.isLightTheme ? const Color(0xFFF8FBFF) : const Color(0xFF161B22);
    final gutterBg = state.isLightTheme ? const Color(0xFFEEF4FF) : const Color(0xFF0D1117);
    final tabBg = state.isLightTheme ? Colors.white : const Color(0xFF0A0F1A);
    final codeColor = state.isLightTheme ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1);
    return Container(
      color: editorBg,
      child: Column(
        children: [
          Container(
            height: 40,
            color: tabBg,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: editorBg,
                    border: const Border(
                        top: BorderSide(color: Colors.blueAccent, width: 2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                          Icons.code, color: Colors.blueAccent, size: 14),
                      const SizedBox(width: 8),
                      Text(_activeFileName, style: GoogleFonts.prompt(
                          color: state.textPrimary, fontSize: 11)),
                    ],
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_settingsShowLineNumbers)
                  Container(
                    width: 40,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: gutterBg,
                    child: Column(
                      children: List.generate(
                        20,
                            (index) =>
                            Text('${index + 1}',
                                style: GoogleFonts.jetBrainsMono(
                                    color: state.textMuted,
                                    fontSize: _editorFontSize,
                                    height: 1.5)),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: TextField(
                      controller: _codeController,
                      maxLines: null,
                      expands: true,
                      style: GoogleFonts.jetBrainsMono(
                          color: codeColor,
                          fontSize: _editorFontSize,
                          height: 1.5),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightConsole() {
    final state = context.watch<AppState>();
    return Container(
      width: 320,
      color: state.sidebarColor,
      child: Column(
        children: [
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: state.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.chevron_right, color: state.textMuted,
                        size: 16),
                    const SizedBox(width: 4),
                    Text('OUTPUT CONSOLE', style: GoogleFonts.prompt(
                        color: state.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                          Icons.copy_all_outlined, color: state.textMuted,
                          size: 14),
                      onPressed: _copyOutput,
                      tooltip: 'Copy Output',
                      splashRadius: 16,
                    ),
                    IconButton(
                      icon: Icon(
                          Icons.delete_outline, color: state.textMuted,
                          size: 14),
                      onPressed: _clearConsole,
                      tooltip: 'Clear Console',
                      splashRadius: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                controller: _consoleScrollController,
                child: Text(
                  _output,
                  style: GoogleFonts.jetBrainsMono(
                    color: state.textSecondary,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
// ... (โค้ด SingleChildScrollView ด้านบนปล่อยไว้เหมือนเดิม) ...

// ... (โค้ด SingleChildScrollView ด้านบนปล่อยไว้เหมือนเดิม) ...

// console input row
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: state.borderColor)),
            ),
            child: Row(
              children: [
                Icon(
                    Icons.chevron_right, color: state.textMuted, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _consoleInputController,
                    style: GoogleFonts.jetBrainsMono(
                        color: state.textPrimary, fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Type input here... (e.g. John)',
                      hintStyle: TextStyle(color: state.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) {
                      if (_isReady && !_isRunning) _execute();
                    },
                  ),
                ),
              ],
            ),
          ),
        ], // วงเล็บปิดของ Column
      ), // วงเล็บปิดของ Container
    ); // วงเล็บปิดของ return
  } // วงเล็บปิดของฟังก์ชัน _buildRightConsole
}
