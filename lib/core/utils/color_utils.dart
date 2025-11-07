import 'package:flutter/material.dart';

extension ColorUtils on Color {
  /// Creates a new color with the specified opacity while avoiding precision loss.
  /// @param value - opacity value between 0.0 and 1.0
  Color withPreciseOpacity(double value) {
    return withAlpha((value * 255).round());
  }

  /// Creates a new color with specified RGBA values, preserving existing values if not provided.
  /// @param red - red component (0-255)
  /// @param green - green component (0-255)
  /// @param blue - blue component (0-255)
  /// @param alpha - alpha component (0.0-1.0)
  Color withValues({int? red, int? green, int? blue, double? alpha}) {
    return Color.fromARGB(
      alpha != null ? (alpha * 255).round() : this.alpha,
      red ?? this.red,
      green ?? this.green,
      blue ?? this.blue,
    );
  }

  /// Blends two colors with the specified opacity for the foreground color.
  /// @param foreground - the color to blend on top
  /// @param opacity - opacity value between 0.0 and 1.0
  static Color blend(Color background, Color foreground, double opacity) {
    return Color.alphaBlend(
      foreground.withAlpha((opacity * 255).round()),
      background,
    );
  }
}
