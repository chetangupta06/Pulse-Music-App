import 'package:flutter/foundation.dart';

import '../../data/demo_seed.dart';
import '../../models/playlist.dart';
import '../../models/station.dart';

class CommunityService extends ChangeNotifier {
  CommunityService()
      : _stations = <Station>[...DemoSeed.stations],
        _activityFeed = <String>[
          'Meher upvoted Punjabi Workout in the live room.',
          'Noor added Kesariya Reimagined to Carvaan Gold Hindi.',
          'Asha shared a Wrapped card to WhatsApp.',
        ];

  final List<Station> _stations;
  final List<String> _activityFeed;

  List<Station> get stations => List<Station>.unmodifiable(_stations);
  List<String> get activityFeed => List<String>.unmodifiable(_activityFeed);

  void upvoteStation(String stationId) {
    final index = _stations.indexWhere(
      (Station station) => station.id == stationId,
    );
    if (index == -1) {
      return;
    }
    final station = _stations[index];
    _stations[index] = station.copyWith(votes: station.votes + 1);
    _activityFeed.insert(0, 'You boosted ${station.title} Radio.');
    notifyListeners();
  }

  void joinPlaylist(Playlist playlist) {
    _activityFeed.insert(
      0,
      'You joined ${playlist.title} as an anonymous collaborator.',
    );
    notifyListeners();
  }
}
