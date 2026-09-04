import '../../../l10n/app_localizations.dart';
import '../models/token.dart';

/// Purpose: Name an inflected form in the learner's language.
/// Inputs: `l10n`, and the `form` the de-inflector recovered.
/// Returns: `String`.
/// Side effects: None.
/// Notes: The token chips printed these as their Dart enum names —
/// `polite + negative` — in every language, which is English to an English
/// reader and nothing at all to a Chinese one. The prompt handed to the
/// on-device model deliberately still uses the enum names: that text is read by
/// a model, not a person, and the English names are what it was trained on.
String formLabel(AppLocalizations l10n, InflectionForm form) => switch (form) {
  InflectionForm.dictionary => l10n.formDictionary,
  InflectionForm.masuStem => l10n.formMasuStem,
  InflectionForm.naiStem => l10n.formNaiStem,
  InflectionForm.teStem => l10n.formTeStem,
  InflectionForm.eStem => l10n.formEStem,
  InflectionForm.polite => l10n.formPolite,
  InflectionForm.negative => l10n.formNegative,
  InflectionForm.past => l10n.formPast,
  InflectionForm.te => l10n.formTe,
  InflectionForm.tai => l10n.formTai,
  InflectionForm.potential => l10n.formPotential,
  InflectionForm.passive => l10n.formPassive,
  InflectionForm.causative => l10n.formCausative,
  InflectionForm.imperative => l10n.formImperative,
  InflectionForm.volitional => l10n.formVolitional,
  InflectionForm.conditionalBa => l10n.formConditionalBa,
  InflectionForm.conditionalTara => l10n.formConditionalTara,
  InflectionForm.tari => l10n.formTari,
  InflectionForm.nagara => l10n.formNagara,
  InflectionForm.adverbial => l10n.formAdverbial,
  InflectionForm.attributive => l10n.formAttributive,
  InflectionForm.progressive => l10n.formProgressive,
  InflectionForm.request => l10n.formRequest,
};

/// Purpose: Name a whole chain of recovered forms.
/// Inputs: `l10n`, the `forms` innermost first.
/// Returns: `String` — the names joined, or empty when there are none.
/// Side effects: None.
/// Notes: The chain reads in the order it was applied, so 食べさせられません
/// reads causative, passive, polite, negative rather than as one opaque label.
String formChainLabel(AppLocalizations l10n, List<InflectionForm> forms) =>
    forms.map((form) => formLabel(l10n, form)).join(' + ');
