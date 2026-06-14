plugins {
    id("com.android.application") apply false
    id("com.android.library") apply false
    id("org.jetbrains.kotlin.android") apply false
    id("com.google.gms.google-services") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.api.dsl.CommonExtension::class.java)?.apply {
            compileSdk = 34
        }
    }

    plugins.withType<com.android.build.gradle.api.AndroidBasePlugin> {
        if (project.name == "flutter_plugin_android_lifecycle") {
            val flutterExt = rootProject.extensions.findByName("flutter")
            if (flutterExt != null) {
                project.extensions.extraProperties.set("flutter", flutterExt)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}