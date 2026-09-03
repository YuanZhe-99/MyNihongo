import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class LicensePage extends StatelessWidget {
  /// Purpose: Create a license page instance.
  /// Inputs: None.
  /// Returns: A new `LicensePage` instance.
  /// Side effects: None.
  /// Notes: None.
  const LicensePage({super.key});

  /// Purpose: Build the GPLv3 notice page.
  /// Inputs: `context`.
  /// Returns: The widget tree for the current state.
  /// Side effects: Creates UI widgets from the current state.
  /// Notes: Keep this method cheap because Flutter may call it often.
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsLicense)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              _licenseText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.licenseContentTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(
              l10n.licenseContentBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            const SelectableText(_contentSources),
          ],
        ),
      ),
    );
  }

  /// The attribution the content licenses require, verbatim and unlocalized.
  ///
  /// EDRDG's licence asks for the project to be named and linked wherever its
  /// data is used, so these lines are not translated and not paraphrased.
  static const _contentSources =
      '''JMdict / EDICT — © James William Breen and The Electronic Dictionary
Research and Development Group, Monash University.
Used under CC BY-SA 4.0. https://www.edrdg.org/edrdg/licence.html
Packaged as jmdict-simplified: https://github.com/scriptin/jmdict-simplified

JLPT vocabulary lists — from stephenmk/yomitan-jlpt-vocab, CC BY-SA 4.0;
the underlying lists are Jonathan Waller's, CC BY.
https://github.com/stephenmk/yomitan-jlpt-vocab

Grammar explanations, example sentences, kana notes and Chinese glosses are
written for this app and are GPL-3.0 with it.

The Traditional Chinese text is generated from the Simplified Chinese text
with the conversion dictionaries of OpenCC (https://github.com/BYVoid/OpenCC),
Copyright (c) Carbo Kuo and contributors, licensed under the Apache License,
Version 2.0. http://www.apache.org/licenses/LICENSE-2.0''';

  static const _licenseText = '''MyNihongo - Copyright (C) 2026 yuanzhe

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.

---

GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007

Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.

The full license text is available at:
https://www.gnu.org/licenses/gpl-3.0.html

Key points:
- You may use, copy, modify, and distribute this software.
- Any distributed or modified version must also be released under
  GPLv3 with source code available.
- You may NOT incorporate this software into proprietary programs.
- There is NO WARRANTY for this software.''';
}
