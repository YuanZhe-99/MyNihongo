# OpenCC dictionaries

The Simplified → Traditional (Taiwan) conversion tables used by
`tool/src/chinese_converter.dart` to generate the `zh_TW` text in
`assets/content/`. See `doc/en-us/features/content-catalog.md`.

| File | What it maps |
|---|---|
| `STPhrases.txt` | Simplified → Traditional, whole words and phrases |
| `STCharacters.txt` | Simplified → Traditional, single characters |
| `TWVariantsPhrases.txt` | Taiwan character variants in phrase context |
| `TWVariants.txt` | Taiwan character variants |

Downloaded verbatim from
<https://github.com/BYVoid/OpenCC/tree/master/data/dictionary> at commit
`2675388` (release `ver.1.4.2`, 2026-08-22). OpenCC is Copyright (c) Carbo Kuo
and contributors, licensed under the Apache License 2.0; the app's license page
carries the attribution.

The order in the table above is OpenCC's own `s2tw` conversion chain, minus the
CJK compatibility ideograph normalisation, which the source text does not need.

`s2tw`, not `s2twp`: OpenCC's Taiwan vocabulary table (`TWPhrases.txt`) is
domain vocabulary, mostly computing, and it mistranslates ordinary prose — it
rewrites 连接 to 連線 and 对象 to 物件 in a grammar note about which noun a
particle connects. What this app needs is Taiwan character variants, and it
never says 软件.

**Do not edit these files.** To refresh them, re-download from the URL above,
update the commit named here, and re-run `dart run tool/convert_zh_tw.dart`;
`test/content_zh_tw_test.dart` fails until the assets are regenerated.
