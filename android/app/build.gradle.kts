plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pipemantra"
    compileSdk = 35 // ✅ Updated to match plugin requirements
    ndkVersion = "27.0.12077973" // ✅ Explicit NDK version

    defaultConfig {
        applicationId = "com.example.pipemantra"
        minSdk = 28
        targetSdk = 35 // ✅ Explicitly match compileSdk (safe and clean)
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }


    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    // ✅ Desugaring support for Java 8+
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
