# R8 rules for the release build.
#
# Only one thing needs them so far: the ML Kit GenAI client libraries behind
# Android AICore. The AARs ship consumer rules covering their generated protos,
# but not the rest, and R8 shrinking the client classes turns every AICore call
# into a NullPointerException thrown deep inside ML Kit — while the debug build,
# which is not minified, works perfectly. That difference is what makes this
# worth writing down: the failure appears only in a release build on a real
# device, and it looks like "this device does not support AI" rather than like a
# build problem.
#
# The failing frame was `com.google.mlkit.common.sdkinternal.LazyInstanceMap`,
# read out of R8's own mapping.txt — so keeping only `com.google.mlkit.genai.**`
# is not enough: the GenAI clients are built through ML Kit's shared SDK
# internals, and those have to survive too.
#
# Found on a Pixel 10 on 2026-09-03. See doc/en-us/android-aicore.md.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }
-dontwarn com.google.mlkit.**
