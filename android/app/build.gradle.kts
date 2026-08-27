import java.util.Properties
import java.io.FileInputStream

// Release signing credentials, kept out of the repository.
//
// Loaded from android/key.properties, which is gitignored along with the
// keystore itself: committing either would hand anyone who cloned the repo
// the ability to publish updates under this app's identity.
//
// Read defensively rather than assumed present, because a fresh clone has
// neither file. Absent, the release build falls back to debug signing below
// and says so, instead of failing with a stack trace that does not explain
// what is missing.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.blob"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.blob"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Only declared when the credentials are actually on disk. Declaring it
        // unconditionally would make every checkout without the keystore fail
        // at configuration time, including ones only building debug.
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                // Resolved against this module (android/app/), not the root
                // project: key.properties writes "../release-key.jks", which
                // only lands on android/release-key.jks from here.
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Debug-signed. Such a build runs locally but Play Console
                // rejects it at upload, so the warning below exists to stop a
                // debug-signed bundle being mistaken for a publishable one.
                logger.warn(
                    "WARNING: android/key.properties not found - signing the " +
                    "release build with the debug key. This bundle CANNOT be " +
                    "uploaded to Play Console."
                )
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

