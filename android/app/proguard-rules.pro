# Flutter Local Notifications - Preserve type information for Gson
# This prevents "Missing type parameter" errors when deserializing notification data
-keepattributes Signature
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
