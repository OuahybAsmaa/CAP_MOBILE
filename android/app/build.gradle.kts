plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.cap_mobile1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.cap_mobile1"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // Désactiver explicitement les deux
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(files("libs/API3_READER-release-2.0.5.238.aar"))
    implementation(files("libs/API3_ASCII-release-2.0.5.238.aar"))
    implementation(files("libs/API3_CMN-release-2.0.5.238.aar"))
    implementation(files("libs/API3_INTERFACE-release-2.0.5.238.aar"))
    implementation(files("libs/API3_TRANSPORT-release-2.0.5.238.aar"))
    implementation(files("libs/API3_NGE-protocolrelease-2.0.5.238.aar"))
    implementation(files("libs/API3_NGE-Transportrelease-2.0.5.238.aar"))
    implementation(files("libs/API3_NGEUSB-Transportrelease-2.0.5.238.aar"))
    implementation(files("libs/BarcodeScannerLibrary.aar"))
    implementation(files("libs/API3_ZIOTC-release-2.0.5.238.aar"))
    implementation(files("libs/API3_ZIOTCTRANSPORT-release-2.0.5.238.aar"))
}