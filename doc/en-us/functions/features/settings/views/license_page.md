# lib/features/settings/views/license_page.dart

The notice includes myapps_ai and myapps_ai_platform, their source and GPL v3.

The notice includes MyApps-UI, all three consumed packages, source and GPL v3 URLs.

`LicensePage` shows the GPLv3 notice for MyNihongo!!!!! as selectable text under an app bar. It is
one of the two second-level settings pages, pushed full-screen on a narrow window and hosted in the
detail pane on a wide one (see [settings_page.md](settings_page.md)). Third-party content
attributions are added here as they ship (M1.2): JMdict/EDICT, the JLPT lists, and the
OpenCC dictionaries the Traditional Chinese text is generated with.

Since 0.6.1 the page's scroll padding is wrapped in `navBarAwarePadding(context, const EdgeInsets.all(16))`, because this page is hosted in the Settings detail pane, where the Expressive floating bar can sit over its bottom edge (`SingleChildScrollView` and an explicit `padding` do not pick up the inset themselves). See [../../../../adaptive-layout.md](../../../../adaptive-layout.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `LicensePage.new` | constructor | B | Create a license page instance. |
| `LicensePage.build` | method (widget build) | B | Build the GPLv3 notice page. |

Since M1.2 the page also carries a **Content licenses** section. JMdict and the JLPT
lists are CC BY-SA, which requires the attribution to travel with the app rather than sitting only
in a repository file. The attribution block itself is a `const` string and is deliberately not
translated: EDRDG's licence asks for the project to be named and linked as it words it.

Includes llama.cpp MIT attribution and Apache-2.0 model provenance for explicitly downloaded Qwen3.5/Gemma 4 artifacts.
