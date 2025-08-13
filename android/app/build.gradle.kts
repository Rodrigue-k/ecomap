import com.android.build.api.dsl.ApplicationExtension
import org.gradle.api.JavaVersion
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val JAVA_VERSION = JavaVersion.VERSION_17
val TARGET_SDK = 35
val MIN_SDK = 24
val NDK_VERSION = "27.0.12077973"

val keystoreProperties = Properties().apply {
    val keystoreFile = rootProject.file("key.properties")
    if (keystoreFile.exists()) {
        load(FileInputStream(keystoreFile))
    }
}

android {
    namespace = "com.koudatek.ecomap"
    compileSdk = TARGET_SDK
    ndkVersion = NDK_VERSION

    defaultConfig {
        applicationId = "com.koudatek.ecomap"
        minSdk = MIN_SDK
        targetSdk = TARGET_SDK
        versionCode = 1
        versionName = "1.0.0"
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = getLocalProperty("GOOGLE_MAPS_API_KEY")
    }

    signingConfigs {
        create("unified") {
            keyAlias = keystoreProperties.getProperty("keyAlias", "ecomap")
            keyPassword = keystoreProperties.getProperty("keyPassword", "")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword", "")
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("unified")
            //applicationIdSuffix = ".debug"
            resValue("string", "app_name", "Ecomap Debug")
        }

        release {
            signingConfig = signingConfigs.getByName("unified")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            resValue("string", "app_name", "Ecomap")
        }
    }

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JAVA_VERSION
        targetCompatibility = JAVA_VERSION
    }

    kotlinOptions {
        jvmTarget = JAVA_VERSION.toString()
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation(platform("com.google.firebase:firebase-bom:33.0.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
}

fun getLocalProperty(name: String): String {
    val localProperties = Properties().apply {
        val localFile = rootProject.file("local.properties")
        if (localFile.exists()) {
            load(FileInputStream(localFile))
        }
    }
    return localProperties.getProperty(name, "")
}