abstract final class TextScale {
  static const defaultValue = 1.0;
  static const min = 0.8;
  static const max = 1.8;
  static const steps = 10;

  static double clamp(double scale) => scale.clamp(min, max).toDouble();
}
