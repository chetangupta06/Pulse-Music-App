import 'package:flutter/material.dart';
import '../../core/models/app_playlist.dart';
import '../theme/app_theme.dart';
import '../../features/playlist/playlist_screen.dart';

class PlaylistCard extends StatefulWidget {
  final AppPlaylist playlist;
  final double? width;
  final double rightMargin;
  const PlaylistCard({super.key, required this.playlist, this.width = 120, this.rightMargin = 24});

  @override
  State<PlaylistCard> createState() => _PlaylistCardState();
}

class _PlaylistCardState extends State<PlaylistCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PlaylistScreen(playlist: widget.playlist)));
        },
        child: Container(
          width: widget.width,
          margin: EdgeInsets.only(right: widget.rightMargin),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()..scale(_isHovering ? 1.05 : 1.0),
            transformAlignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.playlist.effectiveThumbnailUrl.isNotEmpty ? widget.playlist.effectiveThumbnailUrl : 'https://images.unsplash.com/photo-1614680376593-902f74cf0d41?q=80&w=600&auto=format&fit=crop',
                        fit: BoxFit.cover,
                        cacheWidth: 400, cacheHeight: 400,
                      ),
                      Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, Colors.black87], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
                      if (_isHovering)
                        const Center(child: Icon(Icons.playlist_play, size: 60, color: Colors.white)),
                    ],
                  ),
                ),
              ),
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Text(
                    widget.playlist.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
