void main() {
  String query = "Ghost stories podcast";
  final baseQuery = query.replaceAll(' podcast', '').toLowerCase().trim();
  final keywords = baseQuery.split(' ').where((w) => w.length > 2).toList();
  print("Keywords: $keywords");

  // Suppose JioSaavn returned:
  String title = "ghost stories";
  String author = "jiosaavn show";
  bool matches = keywords.any((kw) => title.contains(kw) || author.contains(kw));
  print("Matches Ghost stories: $matches");

  query = "Raj Shamani podcast";
  final bq2 = query.replaceAll(' podcast', '').toLowerCase().trim();
  final kw2 = bq2.split(' ').where((w) => w.length > 2).toList();
  String title2 = "raj shamani - figuring out";
  bool matches2 = kw2.any((kw) => title2.contains(kw) || author.contains(kw));
  print("Matches Raj Shamani: $matches2");
}
