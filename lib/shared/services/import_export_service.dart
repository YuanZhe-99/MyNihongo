/// Purpose: MyNihongo's ZIP export/import API, a facade over the shared
/// `ZipTransfer` engine.
/// Inputs: Destination directories and ZIP file paths from the settings pages.
/// Returns: Written file paths, or import success flags.
/// Side effects: Reads and writes the app data directory.
/// Notes: Archive naming is `mynihongo_export_<yyyyMMdd_HHmmss>.zip`.
library;

import 'package:myapps_data/myapps_data.dart' as shared;

import '../../app/data_modules.dart';

class ImportExportService {
  /// Shared ZIP engine configured strictly.
  ///
  /// MyNihongo has no installed base to stay lenient for, so it takes the
  /// stricter knobs: unknown entries are rejected, payloads must be UTF-8 and
  /// must parse as progress data before anything is written, and writes are
  /// atomic. Path traversal is refused outright by the engine regardless.
  static final shared.ZipTransfer _zip = shared.ZipTransfer(
    storage: const NihongoStorageAdapter(),
    modules: nihongoModuleRegistry,
    archiveNamePrefix: nihongoArchiveNamePrefix,
    rejectUnknownEntries: true,
    strictUtf8: true,
    validateBeforeWrite: true,
    atomicWrites: true,
  );

  /// Purpose: Export all learning data as a ZIP file.
  /// Inputs: `destDir`.
  /// Returns: `Future<String?>` — the exported file path, or null on failure.
  /// Side effects: Writes `mynihongo_export_<stamp>.zip` in `destDir`.
  /// Notes: Bundles the registry's data files. Config, `.sync_base/`, and
  /// `backups/` are never included.
  static Future<String?> exportZIP(String destDir) => _zip.exportZip(destDir);

  /// Purpose: Import data from a previously exported ZIP file.
  /// Inputs: `filePath`.
  /// Returns: `Future<bool>` — true on success.
  /// Side effects: Overwrites allowlisted data files.
  /// Notes: Only the registry's data files are extracted, every entry must
  /// resolve inside the app dir, and an archive containing anything else is
  /// rejected without writing.
  static Future<bool> importZIP(String filePath) => _zip.importZip(filePath);
}
