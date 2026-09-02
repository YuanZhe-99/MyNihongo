import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/progress/models/study_record.dart';
import '../../features/progress/services/nihongo_storage.dart';

/// The user's progress file, read from disk.
///
/// Pages that show progress watch this and call `ref.refresh` after a save or
/// when `AutoSyncService` reports that sync wrote local data.
final progressDataProvider = FutureProvider<ProgressData>(
  (ref) => NihongoStorage.load(),
);
