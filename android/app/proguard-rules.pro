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

# The second R8 failure in the same feature, found on a Pixel 10 on 2026-09-04
# with `v0.4.1` in a release build: tapping Download threw
#
#   java.lang.NoSuchMethodError: No static method cancel$default(
#       Lkotlinx/coroutines/Job;Ljava/util/concurrent/CancellationException;
#       ILjava/lang/Object;)V in class Lkotlinx/coroutines/Job;
#
# from inside `mlkit_genai_prompt`. Kotlin compiles a default-argument call into
# a synthetic static `…$default` bridge; ML Kit's dexed code calls the one on
# `Job`, this app never does, so R8 removed it and the library's own call site
# had nothing to land on. The debug build is not minified and is fine — the same
# shape as the note above.
#
# Kept whole rather than method by method: the bridges are generated, not part
# of anyone's published API, so there is no list to enumerate and the next one
# would be found the same expensive way. See doc/en-us/android-aicore.md.
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**
