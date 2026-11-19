# Add project specific ProGuard rules here.

# Keep Room entities
-keep class com.travelfoodie.core.data.local.entity.** { *; }

# Keep Moshi models
-keep class com.travelfoodie.core.data.remote.api.** { *; }
-keep class com.squareup.moshi.** { *; }

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }

# Keep Firebase
-keep class com.google.firebase.** { *; }

# Keep Hilt
-keep class dagger.hilt.** { *; }
-keep class javax.inject.** { *; }

# Keep ViewBinding
-keep class * implements androidx.viewbinding.ViewBinding {
    public static ** bind(android.view.View);
    public static ** inflate(android.view.LayoutInflater);
}

# Retrofit
-keepattributes Signature
-keepattributes Exceptions
-keepattributes *Annotation*

# OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**

# Kakao SDK: its models are (de)serialized reflectively with Gson, so field and enum
# constant names must survive R8. These are the rules Kakao's Android docs ask apps to add.
# Without them the minified release crashed at startup with
# NoSuchFieldException: TokenNotFound (ClientErrorCause enum).
-keep class com.kakao.sdk.**.model.* { <fields>; }
-keep class * extends com.google.gson.TypeAdapter

# Naver login SDK
-keep class com.navercorp.nid.** { *; }
-keep class com.nhn.android.** { *; }
-dontwarn com.nhn.android.**

# Reflection-based JSON libraries look enum constants up by name (Class.getField), so keep
# enum members un-renamed everywhere. Small size cost, avoids a whole class of release-only crashes.
-keepclassmembers enum * { *; }
-keepattributes EnclosingMethod
-keepattributes InnerClasses
