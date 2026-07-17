import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() async {
  final dir = await getApplicationSupportDirectory();
  print('Support Dir: ${dir.path}');
  final exe = File('${dir.path}/yt-dlp.exe');
  if (exe.existsSync()) {
    print('yt-dlp.exe exists, size: ${exe.lengthSync()} bytes');
  } else {
    print('yt-dlp.exe DOES NOT EXIST');
  }
}
