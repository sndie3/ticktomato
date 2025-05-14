import java.util.Properties
import org.gradle.api.tasks.compile.JavaCompile

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

dependencies {
    implementation("com.google.android.play:core:1.10.3")
    implementation("com.google.android.play:core-ktx:1.8.1")
}

android {
    namespace = "com.sandie.ticktomato"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.sandie.ticktomato"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties().apply {
        if (keystorePropertiesFile.exists()) {
            load(keystorePropertiesFile.inputStream())
        }
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String? ?: throw IllegalArgumentException("keyAlias is missing in key.properties")
                keyPassword = keystoreProperties["keyPassword"] as String? ?: throw IllegalArgumentException("keyPassword is missing in key.properties")
                storeFile = file(keystoreProperties["storeFile"] as String? ?: throw IllegalArgumentException("storeFile is missing in key.properties"))
                storePassword = keystoreProperties["storePassword"] as String? ?: throw IllegalArgumentException("storePassword is missing in key.properties")
            }
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}

// Suppress obsolete Java options warnings
// Pass -Xlint:-options directly to the Java compiler
// This must be outside the android block in Kotlin DSL

tasks.withType<JavaCompile> {
    options.compilerArgs.add("-Xlint:-options")
}
