/// flutter_to_image — render any Flutter widget to a PNG image headlessly.
///
/// Exports the public rendering API: [renderWidgetToPng],
/// [renderScreenToPng], [renderWidgetToImageResult],
/// [renderScreenToImageResult], [ImageResult], and the golden-matrix
/// helpers [renderGoldenMatrix], [renderGoldenMatrixFull],
/// [renderGoldenTextScaleSweep], [renderScreenGoldenMatrix],
/// [renderScreenGoldenMatrixFull], and [renderScreenGoldenTextScaleSweep].
///
/// Also exports the visual-diff API: [compareImages], [ImageComparisonResult],
/// and the disk-persistence helper [savePng] for attaching "expected vs actual
/// PNG + diff" artifacts to issues (`docs/vision_next_term.md` §1.1).
library;

export 'src/diff.dart';
export 'src/file_io.dart';
export 'src/renderer.dart';
export 'src/golden_matrix.dart';
