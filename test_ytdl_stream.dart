import 'dart:io';

void main() async {
  final binary = File('yt-dlp.exe');
  if (!binary.existsSync()) {
    print("yt-dlp.exe not found");
    return;
  }
  final id = '3F2uI1JjZ8k'; // just a random video to test
  try {
    final res = await Process.run(binary.path, [
      '--no-playlist',
      '--youtube-skip-dash-manifest',
      '--get-url',
      '-f', 'ba[ext=m4a]/ba', 
      'https://youtube.com/watch?v=' + id
    ]);
    print("Exit code: ${res.exitCode}");
    print("Stdout: ${res.stdout}");
    print("Stderr: ${res.stderr}");
  } catch (e) {
    print("Error: $e");
  }
}
