import 'asset.dart';

class LearnTopic {
  const LearnTopic({
    required this.type,
    required this.title,
    required this.summary,
    required this.takeaway,
  });

  final AssetType type;
  final String title;
  final String summary;
  final String takeaway;
}
