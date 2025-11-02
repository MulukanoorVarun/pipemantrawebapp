plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pipemantra.android"
    compileSdk = 35 // ✅ Updated to match plugin requirements
    ndkVersion = "27.0.12077973" // ✅ Explicit NDK version

    defaultConfig {
        applicationId = "com.pipemantra.android"
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

    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "pipemantra"
            storePassword = "pipemantra"
            storeFile = file("D:\\pipematra\\android\\app\\upload-keystore.jks")
        }
    }


    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
