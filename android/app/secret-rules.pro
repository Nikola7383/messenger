# Maksimalna obfuskacija za secret build
-keepclassmembers class * extends androidx.lifecycle.ViewModel {
    <init>(...);
}

# Ukloni sve debug informacije
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
    public static *** println(...);
}

# Maksimalna obfuskacija imena klasa
-repackageclasses 'glasnik.secret'
-allowaccessmodification
-overloadaggressively

# Sakrij sve debug i trace metode
-assumenosideeffects class * {
    void debug(...);
    void debugLog(...);
    void trace(...);
    void printStackTrace(...);
}

# Maksimalna zaštita security klasa
-keep class glasnik.features.security.** { *; }
-keepclassmembers class glasnik.features.security.** {
    private <fields>;
    private <methods>;
}

# Sakrij implementaciju mrežnih komponenti
-keep class glasnik.features.network.domain.** { *; }
-keepclassmembers class glasnik.features.network.data.** {
    private <fields>;
    private <methods>;
}

# Dodatna enkripcija stringova
-keepclassmembers class * extends android.app.Activity {
    public void *(android.view.View);
}

# Sakrij sve native metode
-keepclasseswithmembernames class * {
    native <methods>;
}

# Maksimalna optimizacija
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-mergeinterfacesaggressively

# Dodatna zaštita za root detekciju
-keep class glasnik.features.security.root.** { *; }
-keepclassmembers class glasnik.features.security.root.** {
    private <fields>;
    private <methods>;
} 