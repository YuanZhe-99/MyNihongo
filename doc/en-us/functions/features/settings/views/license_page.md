# lib/features/settings/views/license_page.dart

`LicensePage` shows the GPLv3 notice for MyNihongo!!!!! as selectable text under an app bar. It is
one of the two second-level settings pages, pushed full-screen on a narrow window and hosted in the
detail pane on a wide one (see [settings_page.md](settings_page.md)). Third-party content
attributions are added here as they ship (`PLAN.md` M1.2).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `LicensePage.new` | constructor | B | Create a license page instance. |
| `LicensePage.build` | method (widget build) | B | Build the GPLv3 notice page. |

Since `PLAN.md` M1.2 the page also carries a **Content licenses** section. JMdict and the JLPT
lists are CC BY-SA, which requires the attribution to travel with the app rather than sitting only
in a repository file. The attribution block itself is a `const` string and is deliberately not
translated: EDRDG's licence asks for the project to be named and linked as it words it.
