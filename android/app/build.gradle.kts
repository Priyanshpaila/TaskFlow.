plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.task_flow_app"
  compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // required by multiple plugins

    defaultConfig {
        applicationId = "com.example.task_flow_app"
        minSdk = 24 // required by flutter_sound, install_plugin, etc.
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // Optional: AGP 8+ explicit JVM toolchain
    kotlin {
        jvmToolchain(17)
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required for Java 8+ API support (used by newer plugins like flutter_local_notifications)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
