import 'dart:io';

void main() async {
  final binary = File(r'C:\Users\cheta\AppData\Roaming\desi_chaska\yt-dlp.exe');
  if (!binary.existsSync()) {
    print("yt-dlp.exe not found at ${binary.path}");
    return;
  }
  final id = '3F2uI1JjZ8k'; // Some video
  try {
    final res = await Process.run(binary.path, [
      '-f', 'bestaudio[ext=m4a]/bestaudio',
      '--embed-metadata',
      '--embed-thumbnail',
      '-o', 'test_download.m4a',
      'https://youtube.com/watch?v=' + id
    ]);
    print("Exit code: ${res.exitCode}");
    print("Stdout: ${res.stdout}");
    print("Stderr: ${res.stderr}");
  } catch (e) {
    print("Error: $e");
  }
}
