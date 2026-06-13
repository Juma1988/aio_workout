import 'package:flutter/material.dart';

/// An icon that automatically mirrors in RTL (right-to-left) contexts.
///
/// Directional icons (e.g. arrows, chevrons, play/skip buttons) have an
/// inherent direction and should be flipped horizontally when the app is
/// rendered in a right-to-left locale such as Arabic.
///
/// If [rtlIcon] is provided, it will be used instead of flipping [icon].
/// Otherwise the icon is mirrored via [Transform.flip].
class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon({
    super.key,
    required this.icon,
    this.rtlIcon,
    this.size,
    this.color,
  });

  /// The icon to display in LTR mode (also used in RTL mode unless [rtlIcon]
  /// is given, in which case it is flipped via [Transform.flip]).
  final IconData icon;

  /// Optional alternative icon to show in RTL without flipping.
  final IconData? rtlIcon;

  /// The size of the icon (passed to [Icon.size]).
  final double? size;

  /// The color of the icon (passed to [Icon.color]).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;

    if (rtlIcon != null && isRTL) {
      return Icon(rtlIcon, size: size, color: color);
    }

    // Flip the icon horizontally for directional icons in RTL.
    return isRTL
        ? Transform.flip(
            flipX: true,
            child: Icon(icon, size: size, color: color),
          )
        : Icon(icon, size: size, color: color);
  }
}
