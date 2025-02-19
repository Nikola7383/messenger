# Maksimalna zaštita za Secret build

# Sakrij sve informacije o debug-u
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
    public static *** println(...);
    public static *** wtf(...);
}

# Maksimalna obfuskacija
-repackageclasses 'x'
-allowaccessmodification
-overloadaggressively
-flattenpackagehierarchy
-dontusemixedcaseclassnames

# Enkripcija stringova
-keepclasseswithmembers class * {
    native <methods>;
}
-keepclasseswithmembers class * {
    public static final <fields>;
}

# Anti-tamper zaštita
-keep class com.glasnik.secret.security.** { *; }
-keepclassmembers class com.glasnik.secret.security.** {
    private <fields>;
    private <methods>;
}

# Root detekcija
-keep class com.glasnik.secret.security.root.** { *; }
-keepclassmembers class com.glasnik.secret.security.root.** {
    private <fields>;
    private <methods>;
}

# Zaštita native koda
-keepclasseswithmembernames class * {
    native <methods>;
}

# Maksimalna optimizacija
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*,!code/allocation/variable
-optimizationpasses 10
-mergeinterfacesaggressively
-dontpreverify

# Sakrij sve metode i polja
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Dodatna zaštita za Flutter/Dart kod
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }

# Zaštita kriptografskih funkcija
-keep class javax.crypto.** { *; }
-keep class javax.crypto.spec.** { *; }
-keep class java.security.** { *; }

# Sakrij implementaciju mrežne komunikacije
-keep class com.glasnik.secret.network.domain.** { *; }
-keepclassmembers class com.glasnik.secret.network.data.** {
    private <fields>;
    private <methods>;
}

# Zaštita od reverse engineering-a
-keepclassmembers class * extends android.app.Activity {
    public void *(android.view.View);
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Dodatna zaštita za WebView
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}

# Sakrij informacije o buildovima
-keepattributes BuildConfig
-keep class com.glasnik.secret.BuildConfig { *; } 