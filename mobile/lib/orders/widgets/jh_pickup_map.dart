import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/icons.dart';
import '../../theme/tokens.dart';

/// The map in the Pickup step.
///
/// When [live] it is a real OpenStreetMap `FlutterMap`; when not (tests,
/// goldens) it is a fixed placeholder with no network, animation or clock —
/// so the real tile layer is never exercised in automated tests. Set
/// `state.liveMap = false` to force the placeholder, the same way `clock` is
/// pinned.
class JhPickupMap extends StatefulWidget {
  const JhPickupMap({
    super.key,
    required this.live,
    required this.center,
    this.routeEnd,
    this.draggable = false,
    this.onPinMoved,
    this.caption,
    this.height = 176,
  });

  final bool live;
  final LatLng? center;

  /// When set, the map shows both points with a connecting line (tracking).
  final LatLng? routeEnd;

  /// A centre-anchored pin the user positions by dragging the map under it.
  final bool draggable;
  final ValueChanged<LatLng>? onPinMoved;

  /// Shown under the pin in the placeholder.
  final String? caption;
  final double height;

  static const _fallback = LatLng(-6.7924, 39.2083); // Dar es Salaam

  @override
  State<JhPickupMap> createState() => _JhPickupMapState();
}

class _JhPickupMapState extends State<JhPickupMap> {
  final MapController _controller = MapController();

  /// Where the map itself last reported being centred -- via our own
  /// `.move()` call or the user's own drag. Used to tell "the coordinates
  /// changed because of a search/GPS/recent-place pick" (recentre for real)
  /// apart from "the coordinates changed because we're the ones dragging"
  /// (already there, don't fight the gesture).
  LatLng? _liveCenter;

  @override
  void didUpdateWidget(covariant JhPickupMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.live) return;
    final target = widget.center;
    if (target == null) return;
    final known = _liveCenter;
    if (known != null && _sameSpot(known, target)) return;
    _controller.move(target, _controller.camera.zoom);
  }

  static bool _sameSpot(LatLng a, LatLng b) =>
      (a.latitude - b.latitude).abs() < 1e-6 &&
      (a.longitude - b.longitude).abs() < 1e-6;

  @override
  Widget build(BuildContext context) {
    final target = widget.center ?? JhPickupMap._fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(JhRadii.control),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: widget.live ? _map(target) : _placeholder(),
      ),
    );
  }

  Widget _map(LatLng target) {
    final end = widget.routeEnd;
    final mid = end == null
        ? target
        : LatLng((target.latitude + end.latitude) / 2,
            (target.longitude + end.longitude) / 2);
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: mid,
              initialZoom: end == null ? 15 : 12.5,
              interactionOptions: InteractionOptions(
                flags: widget.draggable
                    ? InteractiveFlag.all & ~InteractiveFlag.rotate
                    : InteractiveFlag.none,
              ),
              onPositionChanged: (camera, hasGesture) {
                _liveCenter = camera.center;
                if (hasGesture && widget.draggable) {
                  widget.onPinMoved?.call(camera.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'tz.co.jihudumie.jihudumie_app',
              ),
              if (end != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [target, end],
                      strokeWidth: 3,
                      color: JhColors.primary,
                    ),
                  ],
                ),
              if (!widget.draggable)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: target,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const _Pin(),
                    ),
                    if (end != null)
                      Marker(
                        point: end,
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: const _Pin(),
                      ),
                  ],
                ),
            ],
          ),
        ),
        if (widget.draggable)
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 34),
                child: _Pin(size: 40),
              ),
            ),
          ),
      ],
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: JhColors.surfaceMuted,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Pin(size: 32),
          if (widget.caption != null && widget.caption!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.caption!,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: JhText.ui(
                  size: 12,
                  weight: FontWeight.w600,
                  color: JhColors.textMuted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({this.size = 34});
  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(JhIcons.mapPin, color: JhColors.primary, size: size);
}
