# lib/app/locale_resolution.dart

How a device's preferred language list is matched to one of the app's three UI languages. Wired as
`MaterialApp.localeListResolutionCallback` in [app.md](app.md), so it decides only when the learner
has not picked a language in Settings. See [../../architecture.md](../../architecture.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `traditionalChineseCountry` | constant | B | The country code the Traditional Chinese locale is filed under. |
| `traditionalChineseRegions` | constant | B | Regions that write Chinese in Traditional characters. |
| [`normalizeChinese`](#normalizechinese) | function | A | Reduce any Chinese locale to one of the app's two. |
| [`resolveAppLocale`](#resolveapplocale) | function | A | Choose the UI language for a device's list. |

## Documentation

### `Locale normalizeChinese(Locale locale)` <a id="normalizechinese"></a>

- **Kind:** function
- **Source:** `lib/app/locale_resolution.dart`
- **Purpose:** Decide whether a Chinese locale means Traditional or Simplified.
- **Inputs:** `locale`.
- **Returns:** `zh_TW`, `zh`, or the input unchanged for any other language.
- **Side effects:** None.
- **Algorithm:** `Hant` → Traditional and `Hans` → Simplified when a script subtag is present;
  otherwise the country decides, with `TW`, `HK` and `MO` reading as Traditional.
- **Usage:** `resolveAppLocale`, once per entry in the device's list.
- **Notes:** The script wins over the region because it is what the user actually asked for, so
  `zh-Hans-HK` is Simplified even though Hong Kong is a Traditional region. This is the only place
  in the app that reads a script subtag; everything downstream sees `zh` or `zh_TW`.

### `Locale resolveAppLocale(List<Locale>? preferred, Iterable<Locale> supported)` <a id="resolveapplocale"></a>

- **Kind:** function
- **Source:** `lib/app/locale_resolution.dart`
- **Purpose:** Pick the UI language for a device that has not been told which to use.
- **Inputs:** `preferred` — the device's list, best first; `supported` — `AppLocalizations.supportedLocales`.
- **Returns:** The locale to display.
- **Side effects:** None.
- **Algorithm:** Normalize every Chinese entry, then hand the list to Flutter's own
  `basicLocaleListResolution`.
- **Usage:** `MaterialApp.router`'s `localeListResolutionCallback` in `app.dart`.
- **Notes:** Flutter's algorithm is kept rather than replaced — only its input is corrected. It
  matches on language and country, so a phone asking for `zh-Hant-HK` would be given Simplified
  Chinese: the country `HK` is not `TW`, and the script it did send is ignored. Correcting the
  input rather than the algorithm keeps every non-Chinese case exactly as Flutter defines it,
  including the fall-through to the template language when nothing matches.
