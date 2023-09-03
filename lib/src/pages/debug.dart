import 'dart:async';

import 'package:flutter/widgets.dart';

import '../model/dream.dart';

/// Whether to always show debug info in the photos app.
const forceShowDebugInfo = false;

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
