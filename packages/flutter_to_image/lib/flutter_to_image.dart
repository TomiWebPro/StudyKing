/// flutter_to_image — render any Flutter widget to a PNG image headlessly.
///
/// Exports the public rendering API: [renderWidgetToPng],
/// [renderScreenToPng], [renderWidgetToImageResult],
/// [renderScreenToImageResult], [ImageResult], and the golden-matrix
/// helpers [renderGoldenMatrix], [renderGoldenMatrixFull],
/// [renderGoldenTextScaleSweep], [renderScreenGoldenMatrixFull], and
/// [renderScreenGoldenTextScaleSweep].
///
/// Also exports the visual-diff API: [compareImages], [ImageComparisonResult].
library;

export 'src/diff.dart';
export 'src/renderer.dart';
export 'src/golden_matrix.dart';
