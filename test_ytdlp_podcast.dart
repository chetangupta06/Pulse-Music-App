import 'dart:io';

void main() async {
  final id = "MPSPPLPuybu4MmbdAmiElP_ensAKD237jFa4NB";
  final url = "https://music.youtube.com/podcast/$id";
  print("Running yt-dlp on $url");
  final res = await Process.run('yt-dlp.exe', ['-J', '--flat-playlist', url]);
  if (res.exitCode == 0) {
    print("yt-dlp success! Output length: ${res.stdout.length}");
    // print snippet
    print(res.stdout.toString().substring(0, 500));
  } else {
    print("yt-dlp failed: ${res.stderr}");
  }
}
