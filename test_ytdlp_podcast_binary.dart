import 'dart:io';

void main() async {
  final exe = File(r'C:\Users\cheta\AppData\Roaming\com.example\desi_chaska\yt-dlp.exe');
  
  final id = "MPSPPLPuybu4MmbdAmiElP_ensAKD237jFa4NB";
  String playlistId = id;
  if (id.startsWith('MPSPPL')) {
    playlistId = id.substring(4); // Keep PL...
  } else if (id.startsWith('MPSP')) {
    playlistId = id.substring(4);
  }
  
  final url = "https://youtube.com/playlist?list=$playlistId";
  print("Running yt-dlp on $url");
  
  final res = await Process.run(exe.path, ['-J', '--flat-playlist', url]);
  if (res.exitCode == 0) {
    print("yt-dlp success! Output length: ${res.stdout.length}");
    print(res.stdout.toString().substring(0, 500));
  } else {
    print("yt-dlp failed: ${res.stderr}");
  }
}
