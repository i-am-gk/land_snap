plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")

    // REQUIRED FOR FIREBASE
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.landsnap_demo"
    compileSdk = 35       // Required for shared_preferences_android
    ndkVersion = "27.0.12077973"   // REQUIRED FIX

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.landsnap_demo"

        // 🔥 REQUIRED FIX — Firebase needs minSdk 23 or higher
        minSdk = 23

        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Firebase BOM
    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    // Firebase SDKs
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}

flutter {
    source = "../.."
}
