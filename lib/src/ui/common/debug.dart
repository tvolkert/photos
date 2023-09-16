import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:photos/src/model/dream.dart';

/// Whether to always show debug info in the photos app.
const bool forceShowDebugInfo = false;

/// Whether to show errors to the user in release mode.
///
/// If this is false, errors will be displayed in debug mode only.
const bool showErrorsInReleaseMode = true;

/// Whether to monitor performance timings from the engine.
///
/// When this is enabled, the app will respond to the keyboard key `digit9`
/// by showing a bottom bar notification containing the performance metric
/// averages.
const bool isCollectingPerformanceMetrics = true;

class DebugInfo extends StatefulWidget {
  const DebugInfo({super.key});

  @override
  State<DebugInfo> createState() => _DebugInfoState();
}

class _DebugInfoState extends State<DebugInfo> {
  Map<String, dynamic>? _deviceInfo;
  late Timer _deviceInfoRefreshTimer;

  static const Duration _deviceInfoRefreshRate = Duration(seconds: 3);

  void _reloadDeviceInfo() async {
    Map<String, dynamic> info = await DreamBinding.instance.getDeviceInfo();
    if (mounted) {
      setState(() {
        _deviceInfo = info;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _deviceInfoRefreshTimer = Timer.periodic(_deviceInfoRefreshRate, (Timer timer) {
      _reloadDeviceInfo();
    });
    _reloadDeviceInfo();
  }

  @override
  void dispose() {
    _deviceInfoRefreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: PerformanceOverlay.allEnabled(
            checkerboardOffscreenLayers: true,
            checkerboardRasterCacheImages: true,
            rasterizerThreshold: 1,
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Screen size: ${mediaQueryData.size.width} x ${mediaQueryData.size.height}'),
              Text('Device pixel ratio: ${mediaQueryData.devicePixelRatio}'),
              Text('Max heap size (MB): ${_deviceInfo?['maxHeapSizeMB']}'),
              Text('Available heap size (MB): ${_deviceInfo?['availHeapSizeMB']}'),
              Text('Total system RAM (MB): ${_deviceInfo?['totalSystemRamMB']}'),
              Text('Available system RAM (MB): ${_deviceInfo?['availableSystemRamMB']}'),
              Text('GLES version (`ConfigurationInfo.getGlEsVersion()`): ${_deviceInfo?['gpuGlesVersion']}'),
              Text('GL vendor: ${_deviceInfo?['glVendor']}'),
              Text('GL renderer: ${_deviceInfo?['glRenderer']}'),
              Text('GL version (`GL10.glGetString(GL10.GL_VERSION)`): ${_deviceInfo?['glVersion']}'),
              Text('Image cache size (count): ${imageCache.currentSize}'),
              Text('Image cache size (MB): ${imageCache.currentSizeBytes / (1024 * 1024)}'),
            ],
          ),
        ),
      ],
    );
  }
}

typedef TimingsReportCallback = void Function(
  Duration averageBuildTime,
  Duration averageRasterTime,
  Duration averageTotalTime,
  Duration worstBuildTime,
  Duration worstRasterTime,
  Duration worstTotalTime,
  int missedFrames,
);

class PerformanceMonitor extends StatefulWidget {
  const PerformanceMonitor({
    super.key,
    this.sampleFrequency = 100,
    this.clearValuesNotifier,
    required this.onTimingsReport,
    required this.child,
  });

  /// The frequency with which this widget will calculate average performance
  /// metrics.
  ///
  /// This widget will call [onTimingsReport] every `sampleFrequency` frames.
  /// When it does, it will report the averages since the last time it called
  /// the callback.
  final int sampleFrequency;

  /// Optional object that, when fired, will cause this widget to clear its
  /// stored performance metrics and start collecting from scratch.
  ///
  /// This can be used to wipe clean any records of average frame times or worst
  /// frame times.
  final Listenable? clearValuesNotifier;

  /// Callback to receive the performance metrics that have been collected.
  ///
  /// This widget will call `onTimingsReport` every [sampleFrequency] frames.
  /// When it does, it will report the averages since the last time it called
  /// the callback.
  final TimingsReportCallback onTimingsReport;

  /// The child widget.
  final Widget child;

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  int? lastFrameNumber;
  late int localFrameCount;
  late int globalMissedFrames;
  late Duration localTotalBuildTime;
  late Duration localTotalRasterTime;
  late Duration localTotalTime;
  late Duration globalWorstBuildTime;
  late Duration globalWorstRasterTime;
  late Duration globalWorstTotalTime;

  void _initializeValues() {
    lastFrameNumber = null;
    localFrameCount = 0;
    globalMissedFrames = 0;
    localTotalBuildTime = Duration.zero;
    localTotalRasterTime = Duration.zero;
    localTotalTime = Duration.zero;
    globalWorstBuildTime = Duration.zero;
    globalWorstRasterTime = Duration.zero;
    globalWorstTotalTime = Duration.zero;
  }

  void _handleTimings(List<FrameTiming> timings) {
    assert(mounted);
    for (FrameTiming frame in timings) {
      lastFrameNumber ??= frame.frameNumber - 1;
      localFrameCount++;
      localTotalBuildTime += frame.buildDuration;
      localTotalRasterTime += frame.rasterDuration;
      localTotalTime += frame.totalSpan;
      if (localFrameCount % widget.sampleFrequency == 0) {
        final Duration localAverageBuildTime = localTotalBuildTime ~/ localFrameCount;
        final Duration localAverageRasterTime = localTotalRasterTime ~/ localFrameCount;
        final Duration localAverageTotalTime = localTotalTime ~/ localFrameCount;
        localFrameCount = 0;
        localTotalBuildTime = Duration.zero;
        localTotalRasterTime = Duration.zero;
        localTotalTime = Duration.zero;
        widget.onTimingsReport(
          localAverageBuildTime,
          localAverageRasterTime,
          localAverageTotalTime,
          globalWorstBuildTime,
          globalWorstRasterTime,
          globalWorstTotalTime,
          globalMissedFrames,
        );
      }
      if (frame.buildDuration > globalWorstBuildTime) {
        globalWorstBuildTime = frame.buildDuration;
      }
      if (frame.rasterDuration > globalWorstRasterTime) {
        globalWorstRasterTime = frame.rasterDuration;
      }
      if (frame.totalSpan > globalWorstTotalTime) {
        globalWorstTotalTime = frame.totalSpan;
      }
      if (frame.frameNumber != lastFrameNumber! + 1) {
        globalMissedFrames += frame.frameNumber - lastFrameNumber! - 1;
      }
      lastFrameNumber = frame.frameNumber;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeValues();
    SchedulerBinding.instance.addTimingsCallback(_handleTimings);
    widget.clearValuesNotifier?.addListener(_initializeValues);
  }

  @override
  void dispose() {
    widget.clearValuesNotifier?.removeListener(_initializeValues);
    SchedulerBinding.instance.removeTimingsCallback(_handleTimings);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
