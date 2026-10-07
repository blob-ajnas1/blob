import 'dart:math' as math;

import '../../data/gazetteer.dart';

/// One leg of a planned route.
class RouteStop {
  final String place;
  final String label; // "Pick up · Suresh Traders"
  final double legKm; // straight-line distance from the previous stop
  final Place at;
  const RouteStop(this.place, this.label, this.legKm, this.at);
}

/// A job the driver has to do: collect at [pickup], deliver to [drop].
class RouteJob {
  final String id;
  final String pickup;
  final String drop;
  final String who;
  const RouteJob({
    required this.id,
    required this.pickup,
    required this.drop,
    required this.who,
  });
}

class PlannedRoute {
  final List<RouteStop> stops;
  final double totalKm;

  /// Jobs skipped because a place name isn't in the gazetteer. Listed, not
  /// silently dropped, so the driver knows the plan is incomplete.
  final List<RouteJob> unplaced;

  /// Where the route starts; null when the start isn't in the gazetteer.
  final Place? origin;

  const PlannedRoute(this.stops, this.totalKm, this.unplaced, [this.origin]);

  bool get isEmpty => stops.isEmpty;
}

/// Orders a driver's pickups and drops into a short route.
///
/// Greedy nearest-next from [start], with the one hard rule of goods
/// transport: a load can't be dropped before it is picked up. This is a
/// heuristic, not a proven optimum, but for the handful of stops a village
/// driver has in a day it lands close to the best order and is instant.
///
/// Distances are straight-line (haversine) between town centres — good for
/// ordering stops, not a road distance. The real road route comes from the
/// maps app the "Navigate" button opens.
class RoutePlanner {
  RoutePlanner._();

  static double haversineKm(Place a, Place b) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.lat - a.lat);
    final dLng = rad(b.lng - a.lng);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.lat)) *
            math.cos(rad(b.lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(h.toDouble()));
  }

  static PlannedRoute plan(String start, List<RouteJob> jobs) {
    final origin = Gazetteer.lookup(start);
    final unplaced = <RouteJob>[];
    final pending = <_Stop>[];

    for (final j in jobs) {
      final p = Gazetteer.lookup(j.pickup);
      final d = Gazetteer.lookup(j.drop);
      if (origin == null || p == null || d == null) {
        unplaced.add(j);
        continue;
      }
      pending.add(_Stop(j, true, p));
      pending.add(_Stop(j, false, d));
    }
    if (origin == null || pending.isEmpty) {
      return PlannedRoute(const [], 0, unplaced);
    }

    final collected = <String>{};
    final stops = <RouteStop>[];
    var here = origin;
    var total = 0.0;

    while (pending.isNotEmpty) {
      // Only pickups, or drops whose load is already on board, are legal.
      final legal = pending
          .where((s) => s.isPickup || collected.contains(s.job.id))
          .toList();
      legal.sort(
        (a, b) => haversineKm(here, a.at).compareTo(haversineKm(here, b.at)),
      );
      final next = legal.first;
      final leg = haversineKm(here, next.at);
      total += leg;
      stops.add(
        RouteStop(
          next.isPickup ? next.job.pickup : next.job.drop,
          '${next.isPickup ? 'Pick up' : 'Deliver'} · ${next.job.who}',
          leg,
          next.at,
        ),
      );
      if (next.isPickup) collected.add(next.job.id);
      here = next.at;
      pending.remove(next);
    }
    return PlannedRoute(stops, total, unplaced, origin);
  }

  /// Google Maps directions through every stop, in order. Opens the Maps app
  /// on Android when installed, the website otherwise.
  ///
  /// Stops are passed as coordinates, not names: "Maddur" alone can resolve to
  /// a different Maddur in another state, and coordinates from the gazetteer
  /// pin the exact town without guessing a state suffix.
  static Uri? directionsUri(PlannedRoute route) {
    final origin = route.origin;
    if (origin == null || route.stops.isEmpty) return null;
    String ll(Place p) => '${p.lat},${p.lng}';
    final points = route.stops.map((s) => ll(s.at)).toList();
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'origin': ll(origin),
      'destination': points.last,
      if (points.length > 1)
        'waypoints': points.sublist(0, points.length - 1).join('|'),
      'travelmode': 'driving',
    });
  }
}

class _Stop {
  final RouteJob job;
  final bool isPickup;
  final Place at;
  _Stop(this.job, this.isPickup, this.at);
}
