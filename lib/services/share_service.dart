import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  final ScreenshotController _screenshotController = ScreenshotController();

  // 스크린샷을 위한 컨트롤러 가져오기
  ScreenshotController get screenshotController => _screenshotController;

  // 스크린샷 캡처 후 공유
  Future<void> captureAndShare(BuildContext context, GlobalKey key) async {
    try {
      // 위젯을 이미지로 캡처
      final RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // 임시 파일로 저장
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/schedule.png');
        await file.writeAsBytes(pngBytes);

        // 파일 공유
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '에이바헤어 직원 스케줄러',
        );
      }
    } catch (e) {
      // 에러 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('스케줄 공유 중 오류가 발생했습니다: $e')),
      );
    }
  }

  // 스크린샷 라이브러리 사용하여 캡처 후 공유
  Future<void> captureWithLibraryAndShare(String title) async {
    try {
      final Uint8List? imageBytes = await _screenshotController.capture();

      if (imageBytes != null) {
        // 임시 파일로 저장
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/schedule.png');
        await file.writeAsBytes(imageBytes);

        // 파일 공유
        await Share.shareXFiles(
          [XFile(file.path)],
          text: title,
        );
      }
    } catch (e) {
      print('스케줄 공유 중 오류: $e');
    }
  }
}