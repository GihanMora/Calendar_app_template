import java.util.Properties
import java.io.FileInputStream
import java.io.File

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// Read app config from JSON file (single source of truth)
// This reads config/country_x.json and extracts all config values
fun readConfigValue(jsonContent: String, key: String, default: String): String {
    val regex = Regex("\"$key\"\\s*:\\s*\"([^\"]+)\"")
    val match = regex.find(jsonContent)
    return match?.groupValues?.get(1) ?: default
}

fun readConfigFromJson(): Map<String, String> {
    val configFile = rootProject.file("../config/country_x.json")
    val defaults = mapOf(
        "appName" to "Thai Calendar",
        "packageName" to "com.gihan.thaicalendar",
        "applicationId" to "com.gihan.thaicalendar",
        "admobAppId" to "ca-app-pub-3940256099942544~3347511713"
    )
    
    if (!configFile.exists()) {
        println("⚠️  Warning: config/country_x.json not found, using defaults")
        return defaults
    }
    
    try {
        val jsonContent = configFile.readText()
        val config = mutableMapOf<String, String>()
        
        defaults.forEach { (key, default) ->
            val value = readConfigValue(jsonContent, key, default)
            config[key] = value
            println("✅ $key from config: $value")
        }
        
        return config
    } catch (e: Exception) {
        println("⚠️  Warning: Error reading config/country_x.json: $e")
        return defaults
    }
}

val appConfig = readConfigFromJson()
val appNameFromConfig = appConfig["appName"] ?: "Thai Calendar"
val packageNameFromConfig = appConfig["packageName"] ?: "com.gihan.thaicalendar"
val applicationIdFromConfig = appConfig["applicationId"] ?: "com.gihan.thaicalendar"
val admobAppIdFromConfig = appConfig["admobAppId"] ?: "ca-app-pub-3940256099942544~3347511713"

android {
    // Namespace and applicationId are read from config/country_x.json (single source of truth)
    namespace = packageNameFromConfig
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Application ID is read from config/country_x.json
        applicationId = applicationIdFromConfig
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Set app name from config JSON (single source of truth)
        // This creates a string resource that can be used in AndroidManifest.xml
        resValue("string", "app_name", appNameFromConfig)
        
        // Set AdMob App ID from config JSON (single source of truth)
        // This makes it available in AndroidManifest.xml via ${admobAppId}
        manifestPlaceholders["admobAppId"] = admobAppIdFromConfig
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { rootProject.file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // Add ProGuard rules to prevent "Missing type parameter" errors
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.core:core-ktx:1.13.1")
}

flutter {
    source = "../.."
}
