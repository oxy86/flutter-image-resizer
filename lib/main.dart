import 'dart:ffi';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS) {
    await FilePicker.skipEntitlementsChecks();
  }

  final settings = await AppSettingsStore.load();
  runApp(
    ImageResizerApp(
      settings: settings,
      initialImagePath: firstImagePathArgument(args),
    ),
  );
}

class ImageResizerApp extends StatelessWidget {
  const ImageResizerApp({
    super.key,
    this.settings = const AppSettings(),
    this.initialImagePath,
  });

  final AppSettings settings;
  final String? initialImagePath;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Resizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2f6f65),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: ImageResizerHome(
        settings: settings,
        initialImagePath: initialImagePath,
      ),
    );
  }
}

const openFileChannel = MethodChannel('image_resizer/open_file');

@immutable
class AppSettings {
  const AppSettings({
    this.defaultFormat = ExportFormat.webp,
    this.defaultResizePreset = ResizePreset.scale1200,
    this.defaultCustomWidth = 1200,
    this.defaultCustomHeight,
    this.defaultExportDirectory,
    this.maxBaseFilenameLength = 32,
    this.webpQuality = 80,
    this.jpegQuality = 80,
  });

  final ExportFormat defaultFormat;
  final ResizePreset defaultResizePreset;
  final int defaultCustomWidth;
  final int? defaultCustomHeight;
  final String? defaultExportDirectory;
  final int maxBaseFilenameLength;
  final int webpQuality;
  final int jpegQuality;

  AppSettings copyWith({
    ExportFormat? defaultFormat,
    ResizePreset? defaultResizePreset,
    int? defaultCustomWidth,
    ValueGetter<int?>? defaultCustomHeight,
    ValueGetter<String?>? defaultExportDirectory,
    int? maxBaseFilenameLength,
    int? webpQuality,
    int? jpegQuality,
  }) {
    return AppSettings(
      defaultFormat: defaultFormat ?? this.defaultFormat,
      defaultResizePreset: defaultResizePreset ?? this.defaultResizePreset,
      defaultCustomWidth: defaultCustomWidth ?? this.defaultCustomWidth,
      defaultCustomHeight: defaultCustomHeight != null
          ? defaultCustomHeight()
          : this.defaultCustomHeight,
      defaultExportDirectory: defaultExportDirectory != null
          ? defaultExportDirectory()
          : this.defaultExportDirectory,
      maxBaseFilenameLength:
          maxBaseFilenameLength ?? this.maxBaseFilenameLength,
      webpQuality: webpQuality ?? this.webpQuality,
      jpegQuality: jpegQuality ?? this.jpegQuality,
    );
  }
}

class AppSettingsStore {
  const AppSettingsStore._();

  static const _defaultFormatKey = 'settings.default_format';
  static const _defaultResizePresetKey = 'settings.default_resize_preset';
  static const _defaultCustomWidthKey = 'settings.default_custom_width';
  static const _defaultCustomHeightKey = 'settings.default_custom_height';
  static const _defaultExportDirectoryKey = 'settings.default_export_directory';
  static const _maxBaseFilenameLengthKey = 'settings.max_base_filename_length';
  static const _webpQualityKey = 'settings.webp_quality';
  static const _jpegQualityKey = 'settings.jpeg_quality';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = AppSettings();

    return AppSettings(
      defaultFormat: _enumByName(
        ExportFormat.values,
        prefs.getString(_defaultFormatKey),
        defaults.defaultFormat,
      ),
      defaultResizePreset: _enumByName(
        ResizePreset.values,
        prefs.getString(_defaultResizePresetKey),
        defaults.defaultResizePreset,
      ),
      defaultCustomWidth:
          prefs.getInt(_defaultCustomWidthKey) ?? defaults.defaultCustomWidth,
      defaultCustomHeight: prefs.getInt(_defaultCustomHeightKey),
      defaultExportDirectory: prefs.getString(_defaultExportDirectoryKey),
      maxBaseFilenameLength:
          prefs.getInt(_maxBaseFilenameLengthKey) ??
          defaults.maxBaseFilenameLength,
      webpQuality: prefs.getInt(_webpQualityKey) ?? defaults.webpQuality,
      jpegQuality: prefs.getInt(_jpegQualityKey) ?? defaults.jpegQuality,
    );
  }

  static Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultFormatKey, settings.defaultFormat.name);
    await prefs.setString(
      _defaultResizePresetKey,
      settings.defaultResizePreset.name,
    );
    await prefs.setInt(_defaultCustomWidthKey, settings.defaultCustomWidth);
    await _setNullableInt(
      prefs,
      _defaultCustomHeightKey,
      settings.defaultCustomHeight,
    );
    await _setNullableString(
      prefs,
      _defaultExportDirectoryKey,
      settings.defaultExportDirectory,
    );
    await prefs.setInt(
      _maxBaseFilenameLengthKey,
      settings.maxBaseFilenameLength,
    );
    await prefs.setInt(_webpQualityKey, settings.webpQuality);
    await prefs.setInt(_jpegQualityKey, settings.jpegQuality);
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }

  static Future<void> _setNullableInt(
    SharedPreferences prefs,
    String key,
    int? value,
  ) {
    return value == null ? prefs.remove(key) : prefs.setInt(key, value);
  }

  static Future<void> _setNullableString(
    SharedPreferences prefs,
    String key,
    String? value,
  ) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return prefs.remove(key);
    }
    return prefs.setString(key, trimmed);
  }
}

String defaultExportDirectoryPath() {
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null && home.isNotEmpty) {
    return p.join(home, 'Downloads');
  }
  return Directory.current.path;
}

enum ExportFormat {
  webp('WEBP', 'webp'),
  jpeg('JPEG', 'jpg'),
  png('PNG', 'png');

  const ExportFormat(this.label, this.extension);

  final String label;
  final String extension;
}

enum ResizePreset {
  scale1200('1200x scale', 1200),
  scale1600('1600x scale', 1600),
  scale800('800x scale', 800),
  original('Original size', null),
  custom('Custom', null);

  const ResizePreset(this.label, this.scaleWidth);

  final String label;
  final int? scaleWidth;
}

class LoadedImage {
  const LoadedImage({
    required this.path,
    required this.bytes,
    required this.width,
    required this.height,
  });

  final String path;
  final Uint8List bytes;
  final int width;
  final int height;

  String get filename => p.basename(path);
}

class ExportRequest {
  const ExportRequest({
    required this.sourcePath,
    required this.sourceBytes,
    required this.format,
    required this.resizePreset,
    required this.customWidth,
    required this.customHeight,
    required this.settings,
  });

  final String sourcePath;
  final Uint8List sourceBytes;
  final ExportFormat format;
  final ResizePreset resizePreset;
  final int? customWidth;
  final int? customHeight;
  final AppSettings settings;
}

class ImageExporter {
  const ImageExporter();

  Future<File> export(ExportRequest request) async {
    final sourceImage = img.decodeImage(request.sourceBytes);
    if (sourceImage == null) {
      throw const FormatException('This image format could not be decoded.');
    }

    final resizedImage = _resize(sourceImage, request);
    final exportDir = await _exportDirectory(request.settings);
    await exportDir.create(recursive: true);

    final outputFile = await _availableOutputFile(
      exportDir: exportDir,
      sourcePath: request.sourcePath,
      extension: request.format.extension,
      maxBaseLength: request.settings.maxBaseFilenameLength,
    );

    switch (request.format) {
      case ExportFormat.png:
        await outputFile.writeAsBytes(img.encodePng(resizedImage), flush: true);
      case ExportFormat.jpeg:
        await outputFile.writeAsBytes(
          img.encodeJpg(resizedImage, quality: request.settings.jpegQuality),
          flush: true,
        );
      case ExportFormat.webp:
        await _writeWebp(
          image: resizedImage,
          outputFile: outputFile,
          quality: request.settings.webpQuality,
        );
    }

    return outputFile;
  }

  img.Image _resize(img.Image sourceImage, ExportRequest request) {
    final (width, height) = _targetSize(
      sourceWidth: sourceImage.width,
      sourceHeight: sourceImage.height,
      preset: request.resizePreset,
      customWidth: request.customWidth,
      customHeight: request.customHeight,
    );

    if (width == sourceImage.width && height == sourceImage.height) {
      return sourceImage;
    }

    return img.copyResize(
      sourceImage,
      width: width,
      height: height,
      interpolation: img.Interpolation.average,
    );
  }

  (int width, int height) _targetSize({
    required int sourceWidth,
    required int sourceHeight,
    required ResizePreset preset,
    required int? customWidth,
    required int? customHeight,
  }) {
    if (preset == ResizePreset.original) {
      return (sourceWidth, sourceHeight);
    }

    if (preset == ResizePreset.custom) {
      final width = customWidth;
      final height = customHeight;

      if (width == null && height == null) {
        throw const FormatException('Enter a custom width or height.');
      }

      if (width != null && width <= 0 || height != null && height <= 0) {
        throw const FormatException('Custom size must be greater than zero.');
      }

      return _scaledSize(
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
        targetWidth: width,
        targetHeight: height,
      );
    }

    return _scaledSize(
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      targetWidth: preset.scaleWidth,
      targetHeight: null,
    );
  }

  (int width, int height) _scaledSize({
    required int sourceWidth,
    required int sourceHeight,
    required int? targetWidth,
    required int? targetHeight,
  }) {
    if (targetWidth != null && targetHeight != null) {
      return (targetWidth, targetHeight);
    }

    if (targetWidth != null) {
      final ratio = targetWidth / sourceWidth;
      return (targetWidth, (sourceHeight * ratio).round().clamp(1, 100000));
    }

    if (targetHeight != null) {
      final ratio = targetHeight / sourceHeight;
      return ((sourceWidth * ratio).round().clamp(1, 100000), targetHeight);
    }

    return (sourceWidth, sourceHeight);
  }

  Future<Directory> _exportDirectory(AppSettings settings) async {
    final configuredPath = settings.defaultExportDirectory;
    if (configuredPath != null && configuredPath.trim().isNotEmpty) {
      return Directory(configuredPath);
    }

    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      return downloads;
    }

    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      return Directory(p.join(home, 'Downloads'));
    }

    return Directory.current;
  }

  Future<File> _availableOutputFile({
    required Directory exportDir,
    required String sourcePath,
    required String extension,
    required int maxBaseLength,
  }) async {
    final sanitized = sanitizeBaseFilename(
      p.basenameWithoutExtension(sourcePath),
      maxLength: maxBaseLength,
    );

    var candidate = File(p.join(exportDir.path, '$sanitized.$extension'));
    var index = 2;

    while (await candidate.exists()) {
      final suffix = '_$index';
      final truncated = truncateBaseFilename(
        sanitized,
        (maxBaseLength - suffix.length).clamp(1, maxBaseLength),
      );
      candidate = File(p.join(exportDir.path, '$truncated$suffix.$extension'));
      index += 1;
    }

    return candidate;
  }

  Future<void> _writeWebp({
    required img.Image image,
    required File outputFile,
    required int quality,
  }) async {
    final tempDir = await Directory.systemTemp.createTemp('image_resizer_');
    final inputPng = File(p.join(tempDir.path, 'input.png'));

    try {
      await inputPng.writeAsBytes(img.encodePng(image), flush: true);
      final cwebp = await _materializeCwebp(tempDir);
      final result = await Process.run(cwebp.path, [
        '-quiet',
        '-q',
        quality.clamp(0, 100).toString(),
        inputPng.path,
        '-o',
        outputFile.path,
      ]);

      if (result.exitCode != 0) {
        throw ProcessException(
          cwebp.path,
          const [],
          result.stderr.toString().trim(),
          result.exitCode,
        );
      }
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  Future<File> _materializeCwebp(Directory tempDir) async {
    final assetPath = _cwebpAssetPath();
    final executableName = Platform.isWindows ? 'cwebp.exe' : 'cwebp';
    final executable = File(p.join(tempDir.path, executableName));
    final bytes = await rootBundle.load(assetPath);
    await executable.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

    if (!Platform.isWindows) {
      final chmod = await Process.run('chmod', ['755', executable.path]);
      if (chmod.exitCode != 0) {
        throw ProcessException(
          'chmod',
          ['755', executable.path],
          chmod.stderr.toString().trim(),
          chmod.exitCode,
        );
      }
    }

    return executable;
  }

  String _cwebpAssetPath() {
    return switch (Abi.current()) {
      Abi.macosArm64 => 'assets/cwebp/macos-arm64/cwebp',
      Abi.macosX64 => 'assets/cwebp/macos-x64/cwebp',
      Abi.linuxArm64 => 'assets/cwebp/linux-arm64/cwebp',
      Abi.linuxX64 => 'assets/cwebp/linux-x64/cwebp',
      Abi.windowsX64 => 'assets/cwebp/windows-x64/cwebp.exe',
      _ => throw UnsupportedError(
        'WebP export is not available for this platform.',
      ),
    };
  }
}

String? firstImagePathArgument(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('-')) {
      continue;
    }

    final uri = Uri.tryParse(arg);
    final path = uri != null && uri.scheme == 'file' ? uri.toFilePath() : arg;

    if (File(path).existsSync()) {
      return path;
    }
  }

  return null;
}

String sanitizeBaseFilename(String input, {required int maxLength}) {
  final normalized = input
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  return truncateBaseFilename(
    normalized.isEmpty ? 'image' : normalized,
    maxLength,
  );
}

String truncateBaseFilename(String input, int maxLength) {
  if (input.length <= maxLength) {
    return input;
  }
  return input.substring(0, maxLength).replaceAll(RegExp(r'_+$'), '');
}

class ImageResizerHome extends StatefulWidget {
  const ImageResizerHome({
    super.key,
    required this.settings,
    this.initialImagePath,
    this.exporter = const ImageExporter(),
  });

  final AppSettings settings;
  final String? initialImagePath;
  final ImageExporter exporter;

  @override
  State<ImageResizerHome> createState() => _ImageResizerHomeState();
}

class _ImageResizerHomeState extends State<ImageResizerHome> {
  LoadedImage? _loadedImage;
  late AppSettings _settings;
  late ExportFormat _format;
  late ResizePreset _resizePreset;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  bool _isExporting = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _format = _settings.defaultFormat;
    _resizePreset = _settings.defaultResizePreset;
    _widthController = TextEditingController(
      text: _settings.defaultCustomWidth.toString(),
    );
    _heightController = TextEditingController(
      text: _settings.defaultCustomHeight?.toString() ?? '',
    );
    openFileChannel.setMethodCallHandler(_handleOpenFileMethodCall);
    final initialPath = widget.initialImagePath;
    if (initialPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadImagePath(initialPath);
      });
    }
  }

  @override
  void dispose() {
    openFileChannel.setMethodCallHandler(null);
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<dynamic> _handleOpenFileMethodCall(MethodCall call) async {
    if (call.method != 'openFile') {
      throw MissingPluginException('Unknown method ${call.method}');
    }

    final path = call.arguments;
    if (path is String && path.isNotEmpty) {
      await _loadImagePath(path);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    await _loadImagePath(
      result.files.single.path!,
      bytes: result.files.single.bytes,
    );
  }

  Future<void> _loadImagePath(String path, {Uint8List? bytes}) async {
    final imageBytes = bytes ?? await File(path).readAsBytes();
    final decoded = img.decodeImage(imageBytes);

    if (!mounted) {
      return;
    }

    if (decoded == null) {
      setState(() {
        _status = 'Could not load that image.';
      });
      return;
    }

    setState(() {
      _loadedImage = LoadedImage(
        path: path,
        bytes: imageBytes,
        width: decoded.width,
        height: decoded.height,
      );
      _status = null;
    });
  }

  Future<void> _apply() async {
    final image = _loadedImage;
    if (image == null || _isExporting) {
      return;
    }

    setState(() {
      _isExporting = true;
      _status = 'Exporting...';
    });

    try {
      final output = await widget.exporter.export(
        ExportRequest(
          sourcePath: image.path,
          sourceBytes: image.bytes,
          format: _format,
          resizePreset: _resizePreset,
          customWidth: int.tryParse(_widthController.text.trim()),
          customHeight: int.tryParse(_heightController.text.trim()),
          settings: _settings,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Saved to ${output.path}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _status = 'Export failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _openSettings() async {
    final updated = await showDialog<AppSettings>(
      context: context,
      builder: (context) => SettingsDialog(settings: _settings),
    );

    if (updated == null) {
      return;
    }

    await AppSettingsStore.save(updated);

    if (!mounted) {
      return;
    }

    setState(() {
      _settings = updated;
      _format = updated.defaultFormat;
      _resizePreset = updated.defaultResizePreset;
      _widthController.text = updated.defaultCustomWidth.toString();
      _heightController.text = updated.defaultCustomHeight?.toString() ?? '';
      _status = 'Settings saved';
    });
  }

  Future<void> _openAbout() async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AboutAppDialog(version: packageInfo.version),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadedImage = _loadedImage;

    return CallbackShortcuts(
      bindings: {
        primaryShortcut(LogicalKeyboardKey.keyO): _pickImage,
        primaryShortcut(LogicalKeyboardKey.keyS): _apply,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Image Resizer'),
            actions: [
              IconButton(
                onPressed: _openAbout,
                tooltip: 'About',
                icon: const Icon(Icons.info_outline),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton.filledTonal(
                  onPressed: _openSettings,
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings_outlined),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              _Toolbar(
                format: _format,
                resizePreset: _resizePreset,
                widthController: _widthController,
                heightController: _heightController,
                canApply: loadedImage != null && !_isExporting,
                isExporting: _isExporting,
                onFormatChanged: (value) => setState(() => _format = value),
                onResizeChanged: (value) =>
                    setState(() => _resizePreset = value),
                onPickImage: _pickImage,
                onApply: _apply,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xfff7f8f5),
                    ),
                    child: Center(
                      child: loadedImage == null
                          ? _EmptyState(onPickImage: _pickImage)
                          : _ImagePreview(image: loadedImage),
                    ),
                  ),
                ),
              ),
              _StatusBar(image: loadedImage, status: _status),
            ],
          ),
        ),
      ),
    );
  }
}

SingleActivator primaryShortcut(LogicalKeyboardKey key) {
  return SingleActivator(
    key,
    control: !Platform.isMacOS,
    meta: Platform.isMacOS,
  );
}

class AboutAppDialog extends StatelessWidget {
  const AboutAppDialog({super.key, required this.version});

  static const repositoryUrl =
      'https://github.com/oxy86/flutter-image-resizer/';

  final String version;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('About'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AboutRow(label: 'App', value: 'Image Resizer'),
          _AboutRow(label: 'Version', value: version),
          _AboutRow(label: 'Author', value: 'Dimitris Kalamaras'),
          _AboutRow(label: 'License', value: 'MIT'),
          _AboutRow(label: 'GitHub', value: repositoryUrl),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late ExportFormat _format;
  late ResizePreset _resizePreset;
  late final TextEditingController _exportDirectoryController;
  late final TextEditingController _customWidthController;
  late final TextEditingController _customHeightController;
  late final TextEditingController _filenameLengthController;
  late final TextEditingController _webpQualityController;
  late final TextEditingController _jpegQualityController;

  @override
  void initState() {
    super.initState();
    final settings = widget.settings;
    _format = settings.defaultFormat;
    _resizePreset = settings.defaultResizePreset;
    _exportDirectoryController = TextEditingController(
      text: settings.defaultExportDirectory ?? defaultExportDirectoryPath(),
    );
    _customWidthController = TextEditingController(
      text: settings.defaultCustomWidth.toString(),
    );
    _customHeightController = TextEditingController(
      text: settings.defaultCustomHeight?.toString() ?? '',
    );
    _filenameLengthController = TextEditingController(
      text: settings.maxBaseFilenameLength.toString(),
    );
    _webpQualityController = TextEditingController(
      text: settings.webpQuality.toString(),
    );
    _jpegQualityController = TextEditingController(
      text: settings.jpegQuality.toString(),
    );
  }

  @override
  void dispose() {
    _exportDirectoryController.dispose();
    _customWidthController.dispose();
    _customHeightController.dispose();
    _filenameLengthController.dispose();
    _webpQualityController.dispose();
    _jpegQualityController.dispose();
    super.dispose();
  }

  Future<void> _chooseExportDirectory() async {
    final path = await FilePicker.getDirectoryPath(
      initialDirectory: _exportDirectoryController.text.trim().isEmpty
          ? null
          : _exportDirectoryController.text.trim(),
    );
    if (path != null && mounted) {
      setState(() {
        _exportDirectoryController.text = path;
      });
    }
  }

  void _save() {
    final settings = AppSettings(
      defaultFormat: _format,
      defaultResizePreset: _resizePreset,
      defaultCustomWidth: _positiveInt(_customWidthController.text, 1200),
      defaultCustomHeight: _nullablePositiveInt(_customHeightController.text),
      defaultExportDirectory: _exportDirectoryController.text.trim().isEmpty
          ? null
          : _exportDirectoryController.text.trim(),
      maxBaseFilenameLength: _positiveInt(
        _filenameLengthController.text,
        32,
      ).clamp(8, 128),
      webpQuality: _positiveInt(_webpQualityController.text, 80).clamp(1, 100),
      jpegQuality: _positiveInt(_jpegQualityController.text, 80).clamp(1, 100),
    );

    Navigator.of(context).pop(settings);
  }

  int _positiveInt(String value, int fallback) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return fallback;
    }
    return parsed;
  }

  int? _nullablePositiveInt(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DialogMenuField<ExportFormat>(
                      label: 'Default format',
                      value: _format,
                      items: ExportFormat.values,
                      itemLabel: (item) => item.label,
                      onChanged: (value) => setState(() => _format = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogMenuField<ResizePreset>(
                      label: 'Default resize',
                      value: _resizePreset,
                      items: ResizePreset.values,
                      itemLabel: (item) => item.label,
                      onChanged: (value) =>
                          setState(() => _resizePreset = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DialogNumberField(
                      controller: _customWidthController,
                      label: 'Custom width',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogNumberField(
                      controller: _customHeightController,
                      label: 'Custom height',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Leave width or height empty to preserve the original aspect ratio.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _exportDirectoryController,
                decoration: InputDecoration(
                  labelText: 'Export directory',
                  helperText: 'Defaults to Downloads',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: _chooseExportDirectory,
                    tooltip: 'Choose folder',
                    icon: const Icon(Icons.folder_open),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DialogNumberField(
                      controller: _filenameLengthController,
                      label: 'Max filename length',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogNumberField(
                      controller: _webpQualityController,
                      label: 'WEBP quality',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DialogNumberField(
                      controller: _jpegQualityController,
                      label: 'JPEG quality',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _DialogMenuField<T> extends StatelessWidget {
  const _DialogMenuField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(value: item, child: Text(itemLabel(item))),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _DialogNumberField extends StatelessWidget {
  const _DialogNumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.format,
    required this.resizePreset,
    required this.widthController,
    required this.heightController,
    required this.canApply,
    required this.isExporting,
    required this.onFormatChanged,
    required this.onResizeChanged,
    required this.onPickImage,
    required this.onApply,
  });

  final ExportFormat format;
  final ResizePreset resizePreset;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final bool canApply;
  final bool isExporting;
  final ValueChanged<ExportFormat> onFormatChanged;
  final ValueChanged<ResizePreset> onResizeChanged;
  final VoidCallback onPickImage;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final showCustomSize = resizePreset == ResizePreset.custom;

    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: onPickImage,
              icon: const Icon(Icons.folder_open),
              label: const Text('Load Image'),
            ),
            _MenuField<ResizePreset>(
              label: 'Resize',
              value: resizePreset,
              items: ResizePreset.values,
              itemLabel: (item) => item.label,
              onChanged: onResizeChanged,
            ),
            if (showCustomSize) ...[
              _NumberField(controller: widthController, label: 'Width'),
              _NumberField(controller: heightController, label: 'Height'),
            ],
            _MenuField<ExportFormat>(
              label: 'Format',
              value: format,
              items: ExportFormat.values,
              itemLabel: (item) => item.label,
              onChanged: onFormatChanged,
            ),
            FilledButton.icon(
              onPressed: canApply ? onApply : null,
              icon: isExporting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuField<T> extends StatelessWidget {
  const _MenuField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: DropdownButtonFormField<T>(
        isExpanded: true,
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          for (final item in items)
            DropdownMenuItem(value: item, child: Text(itemLabel(item))),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPickImage});

  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.image_outlined,
          size: 52,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(height: 14),
        Text(
          'Load an image to preview it here',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onPickImage,
          icon: const Icon(Icons.folder_open),
          label: const Text('Choose Image'),
        ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image});

  final LoadedImage image;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.2,
      maxScale: 8,
      child: Image.memory(
        image.bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.image, required this.status});

  final LoadedImage? image;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final details = image == null
        ? 'No image loaded'
        : '${image!.filename}  |  ${image!.width} x ${image!.height}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Text(
        status == null ? details : '$details  |  $status',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
