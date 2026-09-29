import 'dart:math' as math;
import 'dart:ui';

/// Conversão CIE L*a*b* (D65) -> sRGB, espelhando backend/app/vision/color_extraction.py.
/// Cores fora do gamut sRGB são saturadas no limite mais próximo.
Color labToColor(double l, double a, double b) {
  const epsilon = 216 / 24389;
  const kappa = 24389 / 27;
  const white = [0.95047, 1.0, 1.08883];

  final fy = (l + 16) / 116;
  final f = [fy + a / 500, fy, fy - b / 200];
  final xyz = [
    for (var i = 0; i < 3; i++)
      (math.pow(f[i], 3) > epsilon ? math.pow(f[i], 3).toDouble() : (116 * f[i] - 16) / kappa) * white[i],
  ];

  final linear = [
    3.2404542 * xyz[0] - 1.5371385 * xyz[1] - 0.4985314 * xyz[2],
    -0.9692660 * xyz[0] + 1.8760108 * xyz[1] + 0.0415560 * xyz[2],
    0.0556434 * xyz[0] - 0.2040259 * xyz[1] + 1.0572252 * xyz[2],
  ];

  int channel(double c) {
    final v = c.clamp(0.0, 1.0);
    final srgb = v <= 0.0031308 ? 12.92 * v : 1.055 * math.pow(v, 1 / 2.4) - 0.055;
    return (srgb.clamp(0.0, 1.0) * 255).round();
  }

  return Color.fromARGB(255, channel(linear[0]), channel(linear[1]), channel(linear[2]));
}

/// Cor a partir de '#RRGGBB'.
Color hexToColor(String hex) => Color(0xFF000000 | int.parse(hex.replaceFirst('#', ''), radix: 16));

/// Rótulo editorial das coordenadas, ex: 'L* 42.3, a* 36.3, b* 29.0'.
String formatLab(double l, double a, double b) =>
    'L* ${l.toStringAsFixed(1)}, a* ${a.toStringAsFixed(1)}, b* ${b.toStringAsFixed(1)}';
