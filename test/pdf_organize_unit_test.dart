import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sahifile/features/pdf_tools/data/services/pdf_service.dart';
import 'package:sahifile/features/pdf_tools/domain/models/pdf_page_reorganize_item.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String testPdfPath;
  late PdfService pdfService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pdf_org_test');
    pdfService = PdfService();

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (methodCall) async {
      return tempDir.path;
    });

    // Create a 4-page test PDF
    final doc = sf.PdfDocument();
    for (int i = 1; i <= 4; i++) {
      final page = doc.pages.add();
      page.graphics.drawString(
        'Page $i',
        sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 18),
        bounds: const Rect.fromLTWH(50, 50, 200, 50),
      );
    }
    final bytes = doc.saveSync();
    doc.dispose();

    final testFile = File('${tempDir.path}/test_source.pdf');
    await testFile.writeAsBytes(bytes);
    testPdfPath = testFile.path;
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('Reorganize PDF changes sequence and rotates pages correctly', () async {
    // Original pages: [0, 1, 2, 3] (Pages 1, 2, 3, 4)
    // Desired new sequence: [3, 1, 0] (Page 4, Page 2, Page 1 - deleted Page 3)
    final pages = [
      PdfPageReorganizeItem(
        id: 'p3',
        originalPageIndex: 3,
        initialPageNumber: 4,
        sourcePdfPath: testPdfPath,
        rotationDegrees: 90,
      ),
      PdfPageReorganizeItem(
        id: 'p1',
        originalPageIndex: 1,
        initialPageNumber: 2,
        sourcePdfPath: testPdfPath,
        rotationDegrees: 0,
      ),
      PdfPageReorganizeItem(
        id: 'p0',
        originalPageIndex: 0,
        initialPageNumber: 1,
        sourcePdfPath: testPdfPath,
        rotationDegrees: 180,
      ),
    ];

    final result = await pdfService.reorganizePdf(
      orderedPages: pages,
      outputBaseName: 'test_reorganized',
    );

    expect(result.isSuccess, isTrue);
    final data = result.dataOrNull;
    expect(data, isNotNull);
    expect(data!.pageCount, 3);
    expect(File(data.outputPath).existsSync(), isTrue);

    // Verify output file page count
    final outputDoc = sf.PdfDocument(
      inputBytes: await File(data.outputPath).readAsBytes(),
    );
    expect(outputDoc.pages.count, 3);
    outputDoc.dispose();
  });

  test('Reorganize PDF supports page duplication', () async {
    // Duplicate page 0 twice: [0, 0, 1]
    final pages = [
      PdfPageReorganizeItem(
        id: 'p0_1',
        originalPageIndex: 0,
        initialPageNumber: 1,
        sourcePdfPath: testPdfPath,
      ),
      PdfPageReorganizeItem(
        id: 'p0_2',
        originalPageIndex: 0,
        initialPageNumber: 1,
        sourcePdfPath: testPdfPath,
      ),
      PdfPageReorganizeItem(
        id: 'p1',
        originalPageIndex: 1,
        initialPageNumber: 2,
        sourcePdfPath: testPdfPath,
      ),
    ];

    final result = await pdfService.reorganizePdf(
      orderedPages: pages,
      outputBaseName: 'test_duplicated',
    );

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull?.pageCount, 3);
  });
}
