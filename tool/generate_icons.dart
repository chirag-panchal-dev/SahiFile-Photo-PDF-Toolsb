// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  const sourcePath =
      '/Users/nishubhardwaj/.gemini/antigravity-ide/brain/62757ac9-dc7d-43ee-9610-97fcec48d442/sahifile_app_logo_1791875693529.jpg';

  final sourceFile = File(sourcePath);
  if (!sourceFile.existsSync()) {
    print('Source image not found at $sourcePath');
    exit(1);
  }

  final bytes = sourceFile.readAsBytesSync();
  final image = img.decodeImage(bytes);
  if (image == null) {
    print('Failed to decode image');
    exit(1);
  }

  // Ensure assets/icon directory exists
  final assetsIconDir = Directory('assets/icon');
  if (!assetsIconDir.existsSync()) {
    assetsIconDir.createSync(recursive: true);
  }

  // Save master icon
  final master512 = img.copyResize(
    image,
    width: 512,
    height: 512,
    interpolation: img.Interpolation.cubic,
  );
  File('assets/icon/app_icon.png').writeAsBytesSync(img.encodePng(master512));
  print('Saved assets/icon/app_icon.png (512x512)');

  // Android mipmap densities for ic_launcher
  final densities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (final entry in densities.entries) {
    final folder = entry.key;
    final size = entry.value;
    final resized = img.copyResize(
      image,
      width: size,
      height: size,
      interpolation: img.Interpolation.cubic,
    );
    final targetPath = 'android/app/src/main/res/$folder/ic_launcher.png';
    File(targetPath).writeAsBytesSync(img.encodePng(resized));
    print('Saved $targetPath (${size}x$size)');
  }

  // Splash screen logo for drawable folders (160x160 and 240x240)
  final splashLogo = img.copyResize(
    image,
    width: 200,
    height: 200,
    interpolation: img.Interpolation.cubic,
  );
  final drawableDir = Directory('android/app/src/main/res/drawable');
  if (!drawableDir.existsSync()) {
    drawableDir.createSync(recursive: true);
  }
  File(
    'android/app/src/main/res/drawable/splash_logo.png',
  ).writeAsBytesSync(img.encodePng(splashLogo));
  print('Saved android/app/src/main/res/drawable/splash_logo.png (200x200)');

  print('All icons generated successfully!');
}
