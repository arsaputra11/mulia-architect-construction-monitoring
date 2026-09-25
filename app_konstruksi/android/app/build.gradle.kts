plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.app_konstruksi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Dikembalikan ke pengaturan standar (Abaikan jika nanti ada warning kuning 'deprecated', itu aman dan aplikasi tetap bisa jalan)
    kotlinOptions {
        jvmTarget = "17"
    }

    sourceSets {
        getByName("main") {
            res.srcDirs("src/main/res", "src/main/res/")
        }
    }

    defaultConfig {
        applicationId = "com.example.app_konstruksi"
        
        // FORMAT YANG BENAR UNTUK KOTLIN DSL
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
