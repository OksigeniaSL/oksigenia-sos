# ─────────────────────────────────────────────────────────────────────────
# Oksigenia SOS — R8 / minify keep rules
#
# Shrinking is enabled (per F-Droid maintainer request) so R8 strips Flutter's
# unused deferred-components classes (FlutterPlayStoreSplitApplication etc.) and
# with them the dangling com.google.android.play.core.* references the scanner
# flags. The app uses the default FlutterApplication, so those classes are dead.
#
# Everything the SAFETY chain depends on is kept explicitly so shrinking can
# never break it at runtime. Flutter already keeps its own embedding + any
# FlutterPlugin implementation, so we only add what reflection/Gson/JNI reach.
# ─────────────────────────────────────────────────────────────────────────

# SMS — the SOS itself is dispatched through another_telephony. Critical.
-keep class com.shounakmulay.telephony.** { *; }

# Local notifications — serializes scheduled-notification models via Gson
# (reflection), which R8 cannot see. Keep the plugin + its models + Gson.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod

# Background service (also manifest-declared; kept here as belt-and-suspenders).
-keep class id.flutter.flutter_background_service.** { *; }

# JNI native bindings (transitive `jni` via another_telephony).
-keepclasseswithmembernames class * { native <methods>; }
-keepclassmembers enum * { *; }

# Google Play Core is intentionally NOT on the classpath (no deferred
# components). Let R8 strip the unused Flutter PlayStore classes; silence the
# missing-class warnings so the build doesn't fail on them.
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.**
