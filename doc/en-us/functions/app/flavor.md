# lib/app/flavor.dart

`AppFlavor` reads the `FLAVOR` Dart define (`store` or the default `full`) into two compile-time
constants, `isStore` and `isFull`. No feature is gated on it yet; it exists so store builds can be
told apart the way the sibling apps do, and so a future online feature has its gate ready. See
[../../architecture.md](../../architecture.md).

## Declarations

| Declaration | Kind | Tier | Purpose |
|---|---|---|---|
| `AppFlavor._` | private constructor | B | Prevent direct instantiation and expose only static members. |
