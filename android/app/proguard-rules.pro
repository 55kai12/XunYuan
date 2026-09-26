# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Gson / Jackson (json_serializable)
-keepattributes *Annotation*
-keepattributes Signature
-dontwarn sun.misc.**

# local_auth
-keep class androidx.biometric.** { *; }

# pdf / printing
-dontwarn org.apache.**
-dontwarn com.lowagie.**

# Play Core (Flutter deferred components 引用但未使用)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
