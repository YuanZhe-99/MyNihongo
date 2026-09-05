# lib/features/drills/services/drill_repository.dart

Loads the drill files a JLPT paper is drawn from, and the structure file that says what a paper is
made of.

Separate from `ContentRepository` for the reason `LessonRepository` is: the catalog is what every
page needs and is worth an isolate; a drill file is one section of one level, read only when
somebody opens that section, and a level with no file yet is an ordinary state rather than a
failure.

Consumers: `jlpt_practice_card.dart` (`drillLevelProvider`), `quiz_page.dart`
(`drillLevelProvider`, `jlptStructureProvider`).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `DrillRepository` | class | B | Load the drill files a paper is drawn from. |
| `DrillRepository._` | constructor | B | Prevent construction; every member is static. |
| `assetFor` | static method | B | Name the asset one level's section lives in: `assets/content/drills/<level>-<section>.json`. |
| [`load`](#load) | static method | A | Load one level's section, treating a missing file as an empty section. |
| `loadStructure` | static method | B | Load `structure.json`; `JlptStructure.empty` if it will not load. |
| [`_exists`](#exists) | static method | A | Say whether an asset was actually bundled. |
| `drillFileProvider` | provider | B | One level's section, loaded on demand, as a family over the pair. |
| `drillLevelProvider` | provider | B | Every section of one level, loaded together. |
| `jlptStructureProvider` | provider | B | The JLPT's own composition and timings. |

## Documentation

### `static Future<DrillFile> load(JlptLevel level, DrillSection section, [AssetBundle? bundle])` <a id="load"></a>

- **Kind:** static method
- **Purpose:** Load one level's section.
- **Inputs:** `level`, `section`, and a `bundle` for tests.
- **Returns:** `Future<DrillFile>` — empty when the section has no file.
- **Side effects:** Reads an asset.
- **Algorithm:** Ask the manifest whether the asset was bundled; if not, return an empty file for
  that level and section. Otherwise load the string and hand it to `DrillFile.fromJson`, returning
  the same empty file if anything throws.
- **Usage:** `drillFileProvider`, `drillLevelProvider`.
- **Notes:** A missing file is an empty section, not an error. Levels are written one release at a
  time, so a build that ships N5 and not N4 is the normal state, and the Learn card says so rather
  than showing a failure. `assetFor` is flat — `n5-reading.json`, not `n5/reading.json` — so
  `pubspec.yaml` needs one asset line rather than one per level, and the two hard-coded directory
  lists in `tool/convert_zh_tw.dart` and `content_zh_tw_test.dart` gain one entry rather than five.

### `static Future<bool> _exists(String asset, AssetBundle bundle)` <a id="exists"></a>

- **Kind:** static method
- **Purpose:** Say whether an asset was actually bundled.
- **Inputs:** The `asset` path and the `bundle` to ask.
- **Returns:** `Future<bool>`.
- **Side effects:** Reads the asset manifest, which the bundle caches.
- **Algorithm:** Load the manifest and look the path up; return true if the manifest itself will not
  load.
- **Usage:** `load`, before every attempt.
- **Notes:** Asked of the manifest rather than attempted and caught. A missing asset is the **normal**
  state for most of the twenty level-section pairs while the levels are still being written, and
  `loadString` does not merely throw for one — it reports a Flutter error first, which a widget test
  fails on even though the throw itself is handled. A manifest that will not load at all is treated
  as "try it and see", so a platform where this is unavailable degrades to the old behaviour rather
  than reporting every level as unwritten.
