import 'dart:io';
import 'package:image/image.dart';

void main() {
  final file = File('assets/images/league_logo_raw.jpg');
  final bytes = file.readAsBytesSync();
  final image = decodeImage(bytes);

  if (image != null) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.r > 200 && pixel.g > 200 && pixel.b > 200) {
          image.setPixelRgba(x, y, 255, 255, 255, 0);
        }
      }
    }
    File('assets/images/league_logo.png').writeAsBytesSync(encodePng(image));
    print('Background removed!');
  }
}