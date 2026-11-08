// Copyright 2026 R. Heller
// SPDX-License-Identifier: Apache-2.0

import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseProperties = Properties()
val releasePropertiesFile = rootProject.file("keystore.properties")
if (releasePropertiesFile.exists()) releasePropertiesFile.inputStream().use { releaseProperties.load(it) }

android {
    namespace = "com.raban.etabli.etabli_atelier"
    // file_picker 10.x requires compileSdk >= 36; Flutter 3.44 still defaults
    // to 35, so pin it explicitly here.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.raban.etabli.atelier"
        // flutter_inappwebview + modern WebView for WebR/Pyodide require a recent WebView.
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releasePropertiesFile.exists()) create("production") {
            storeFile = rootProject.file(releaseProperties.getProperty("storeFile"))
            storePassword = releaseProperties.getProperty("storePassword")
            keyAlias = releaseProperties.getProperty("keyAlias")
            keyPassword = releaseProperties.getProperty("keyPassword")
        }
    }
    buildTypes {
        release {
            // Private signing is optional for local unsigned review builds.
            signingConfig = signingConfigs.findByName("production")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
