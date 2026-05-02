# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Suppress missing Play Core split-install classes (not used in this app)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# FFmpeg Kit
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class com.arthenica.smartexception.** { *; }

# video_player
-keep class com.google.android.exoplayer2.** { *; }

# image_picker / share_plus
-keep class androidx.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
