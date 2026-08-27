import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../../data/gazetteer.dart';

/// Map support for place names.
///
/// [PlaceLink] is the piece used across the app: it turns any place name into a
/// tappable link that opens [PlaceMapScreen] pinned to that place. It is
/// deliberately tolerant — a name the [Gazetteer] does not know renders as
/// plain text instead of a dead link, so an unmappable value degrades quietly
/// rather than dropping a pin somewhere wrong.
///
/// Tiles come from OpenStreetMap over the network. That means the map needs
/// connectivity; a fully offline map needs vector tiles shipped in the bundle,
/// which is a much larger change and is still an open question with the user.
class PlaceMapScreen extends StatelessWidget {
  const PlaceMapScreen({
    super.key,
    required this.place,
    this.label,
    this.subtitle,
  });

  final Place place;

  /// What to call this pin. Defaults to the place's own name.
  final String? label;

  /// Optional context line, e.g. a job title or listing name.
  final String? subtitle;

  /// Zoom levels: a country needs a wide view, a town a close one. Picking from
  /// the place's own scale avoids opening the map fully zoomed into the middle
  /// of a state.
  double get _zoom {
    if (Gazetteer.countryNames.contains(place.name)) return 4.2;
    if (Gazetteer.stateNames.contains(place.name)) return 6.8;
    return 11;
  }

  @override
  Widget build(BuildContext context) {
    final centre = LatLng(place.lat, place.lng);
    final title = label ?? place.name;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: centre,
                initialZoom: _zoom,
                minZoom: 3,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // OSM's tile policy requires identifying the client.
                  // Must match the real applicationId in
                  // android/app/build.gradle.kts, or OSM cannot identify us.
                  userAgentPackageName: 'com.blob',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: centre,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.location_on,
                        size: 44,
                        color: AppColors.primary,
                        shadows: const [
                          Shadow(color: Colors.black38, blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
                // Required, not decorative: OpenStreetMap's tile usage policy
                // and GeoNames' CC-BY licence both oblige us to credit them
                // visibly wherever their data is shown.
                const _MapAttribution(),
              ],
            ),
          ),
          _PlaceFooter(place: place, title: title, subtitle: subtitle),
        ],
      ),
    );
  }
}

/// Credit for the map tiles and the place data.
///
/// Both licences require attribution to be shown to the user, so this sits on
/// the map itself rather than buried in an about screen.
class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Text(
              '© OpenStreetMap contributors · places from GeoNames',
              style: TextStyle(fontSize: 9.5, color: Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceFooter extends StatelessWidget {
  const _PlaceFooter({
    required this.place,
    required this.title,
    this.subtitle,
  });

  final Place place;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.place_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle ??
                        '${place.lat.toStringAsFixed(4)}, '
                            '${place.lng.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A place name that opens a map when tapped.
///
/// Drop this in anywhere a city, town, district or country is displayed. If the
/// name is not in the [Gazetteer] it renders as ordinary text, so callers do
/// not need to check first.
class PlaceLink extends StatelessWidget {
  const PlaceLink({
    super.key,
    required this.name,
    this.subtitle,
    this.style,
    this.showIcon = true,
    this.iconSize = 15,
    this.icon = Icons.place_outlined,
  });

  /// The place to resolve. May be composite ("Maddur, Mandya") or unknown.
  final String? name;

  /// Optional context shown on the map screen, e.g. the listing title.
  final String? subtitle;

  final TextStyle? style;
  final bool showIcon;
  final double iconSize;

  /// Leading glyph. Overridable so a link can keep whatever pin the
  /// surrounding layout already used before it became tappable.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = (name ?? '').trim();
    if (text.isEmpty) return const SizedBox.shrink();

    final place = Gazetteer.lookup(text);
    final baseStyle =
        style ??
        const TextStyle(fontSize: 13, color: AppColors.textSecondary);

    // Unknown place: no affordance to tap. The icon is kept, in the muted
    // text colour, so a row does not visibly reflow just because one value
    // happens to be unmappable.
    if (place == null) {
      if (!showIcon) {
        return Text(text, style: baseStyle, overflow: TextOverflow.ellipsis);
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: AppColors.textSecondary),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              style: baseStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: () => openPlaceMap(context, text, subtitle: subtitle),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(icon, size: iconSize, color: AppColors.primary),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                text,
                style: baseStyle.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary.withValues(alpha: 0.4),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the map for [name] if it can be resolved; tells the user plainly when
/// it cannot, rather than opening a map pointing at the wrong place.
void openPlaceMap(BuildContext context, String? name, {String? subtitle}) {
  final place = Gazetteer.lookup(name);
  if (place == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('No map position on record for "${name ?? ''}".'),
      ),
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlaceMapScreen(
        place: place,
        label: name!.trim(),
        subtitle: subtitle,
      ),
    ),
  );
}
