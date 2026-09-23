/// Maps a crop name to a bundled photograph.
///
/// Listings created by users only carry a free-text crop name, so instead of
/// forcing them to upload a photo we match on keywords and fall back to a
/// generic sack image. Anything explicitly set on the listing's [imageAsset]
/// always wins over the keyword match.
class CropImages {
  CropImages._();

  static const String _dir = 'assets/crops';

  static const String paddy = '$_dir/paddy.jpg';
  static const String chilli = '$_dir/chilli.jpg';
  static const String sugarcane = '$_dir/sugarcane.jpg';
  static const String coffee = '$_dir/coffee.jpg';
  static const String ragi = '$_dir/ragi.jpg';
  static const String turmeric = '$_dir/turmeric.jpg';

  /// Keyword -> asset. Ordered most specific first so "red chilli" does not
  /// get caught by a broader rule later on.
  static const List<(List<String>, String)> _rules = [
    (['chilli', 'chili', 'chile', 'byadagi', 'pepper'], chilli),
    (['turmeric', 'haldi', 'curcumin'], turmeric),
    (['coffee', 'arabica', 'robusta', 'parchment'], coffee),
    (['ragi', 'millet', 'jowar', 'bajra'], ragi),
    (['sugarcane', 'cane', 'sugar'], sugarcane),
    (
      ['paddy', 'rice', 'sona', 'masuri', 'wheat', 'grain', 'maize', 'corn'],
      paddy,
    ),
  ];

  /// Best-effort photo for [cropName]; never returns null so cards always
  /// render an image rather than an empty grey box.
  static String forCrop(String cropName) {
    final q = cropName.toLowerCase();
    for (final (keywords, asset) in _rules) {
      for (final k in keywords) {
        if (q.contains(k)) return asset;
      }
    }
    return paddy;
  }

  /// Resolves the image for a listing, preferring an explicit asset.
  static String resolve({String? imageAsset, required String cropName}) {
    if (imageAsset != null && imageAsset.trim().isNotEmpty) return imageAsset;
    return forCrop(cropName);
  }
}
