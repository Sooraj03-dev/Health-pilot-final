plugins {
    id("com.android.application")
    id("kotlin-android")
<<<<<<< HEAD
=======
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.healthpilot.health_pilot"
<<<<<<< HEAD
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
=======
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
<<<<<<< HEAD
        applicationId = "com.healthpilot.health_pilot"
        minSdk = 26
        targetSdk = 35
=======
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.healthpilot.health_pilot"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
<<<<<<< HEAD
=======
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

<<<<<<< HEAD
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
=======
flutter {
    source = "../.."
}
>>>>>>> aabf34341f6f37d9047fdd10608e9360e05a0d42
