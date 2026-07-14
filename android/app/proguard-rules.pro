# Flutter's default ProGuard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep the app's own classes (change com.yourbrand.aio_workout to match your app ID)
-keep class com.i1988.aio_workout.** { *; }

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# image_picker — native image selection
-keep class io.flutter.plugins.imagepicker.** { *; }

# url_launcher — opening external links
-keep class io.flutter.plugins.urllauncher.** { *; }
