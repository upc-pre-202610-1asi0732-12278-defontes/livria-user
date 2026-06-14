pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            settingsDir.resolve("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    id("com.android.application") version "8.7.2" apply false
    id("com.android.library") version "8.7.2" apply false

    id("com.google.gms.google-services") version "4.4.4" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")