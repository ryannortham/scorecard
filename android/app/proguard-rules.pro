# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Ignore missing Play Core classes (we don't use these features)
-dontwarn com.google.android.play.core.**
-ignorewarnings

# Keep Flutter's Play Store split compatibility classes (these are built-in)
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager** { *; }

# Firebase/Crashlytics rules (if using Firebase)
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Gson rules (if using)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep the native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
