# Dodatna obfuskacija za network build
-keepclassmembers class * extends androidx.lifecycle.ViewModel {
    <init>(...);
}

# Sakrij sve debug informacije
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Obfuskacija imena klasa
-repackageclasses 'glasnik'
-allowaccessmodification

# Sakrij sve metode koje se koriste za debug
-assumenosideeffects class * {
    void debug(...);
    void debugLog(...);
    void trace(...);
}

# Dodatna obfuskacija za security klase
-keep class glasnik.features.security.** { *; }
-keepclassmembers class glasnik.features.security.** {
    private <fields>;
}

# Sakrij implementaciju mrežnih komponenti
-keep class glasnik.features.network.domain.** { *; }
-keepclassmembers class glasnik.features.network.data.** {
    private <fields>;
    private <methods>;
} 