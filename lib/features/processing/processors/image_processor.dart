import 'package:aig/features/processing/models/processing_context.dart';
import 'package:aig/features/processing/models/processing_result.dart';
import 'package:aig/features/processing/models/processing_stage.dart';

abstract class ImageProcessor {
  const ImageProcessor({
    required this.name,
    required this.description,
    this.stage,
  });

  final String name;
  final String description;
  final ProcessingStage? stage;

  Future<ProcessingResult> process(ProcessingContext context);
}
