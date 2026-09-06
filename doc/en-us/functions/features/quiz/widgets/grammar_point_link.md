# lib/features/quiz/widgets/grammar_point_link.dart

The two places a quiz question names the grammar point behind it: above a generated question, before
it is answered, and after any grammar question, as a chip that opens the point's own page.

Both resolve `QuizQuestion.itemId` through `contentCatalogProvider` and render nothing when it is not
a grammar point the catalog knows, which is the same silence the rest of the quiz keeps about ids it
cannot resolve.

Consumers: `quiz_runner.dart`.

The line is shown **only** on a generated question. On an authored one the point is frequently the
answer — 「这句用了哪个语法点？」 with four points as the options — so naming it above would be
giving it away. On a generated one the point is the premise: the model was asked to test 〜ね, and a
learner who is not told that is being asked to guess the question as well as the answer. The chip is
shown on every grammar question, right or wrong, because by then the answer is on screen and the
point is no longer a secret.

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `GrammarPointLine` | class | B | Name the point a generated question tests, above the question. |
| `GrammarPointLine.new` | constructor | B | Hold the catalog id. |
| `GrammarPointLine.build` | method | B | Resolve the point and write its pattern and meaning. |
| `GrammarPointChip` | class | B | Open the point a question was about, after it is answered. |
| `GrammarPointChip.new` | constructor | B | Hold the catalog id. |
| `GrammarPointChip.build` | method | B | Resolve the point and offer `showGrammarDetailSheet`. |

## Documentation

Both widgets take an id rather than a `GrammarPoint`, because the widget is where the locale is and a
point's meaning has to be resolved against it. Neither reads the catalog itself: `contentCatalogProvider`
is already loaded wherever a quiz is running, so the lookup costs nothing and a build that raced it
simply draws nothing that frame.

The chip reuses `showGrammarDetailSheet` from `lib/shared/widgets/content_sheets.dart`, which is the
same sheet the reference tab and the sentence lab open. The quiz had never linked back to the catalog
it draws from: a wrong answer gave the learner an explanation and no way to reach the page it came
from.
