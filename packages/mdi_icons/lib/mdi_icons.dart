import 'package:flutter/widgets.dart';

const String _fontFamily = 'Material Design Icons';
const String _fontPackage = 'mdi_icons';

/// The subset of [Material Design Icons](https://pictogrammers.com/library/mdi/)
/// used by BlackHole.
///
/// Replaces the unmaintained `material_design_icons_flutter` package, which no
/// longer compiles since `IconData` became a final class.
class MdiIcons {
  const MdiIcons._();

  static const IconData export =
      IconData(0xf0207, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const IconData folderMusic =
      IconData(0xf1359, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const IconData gmail =
      IconData(0xf02ab, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const IconData import =
      IconData(0xf02fa, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const IconData instagram =
      IconData(0xf02fe, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const IconData share =
      IconData(0xf0496, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const IconData spotify =
      IconData(0xf04c7, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const IconData themeLightDark =
      IconData(0xf050e, fontFamily: _fontFamily, fontPackage: _fontPackage);
  static const IconData youtube =
      IconData(0xf05c3, fontFamily: _fontFamily, fontPackage: _fontPackage);
}
