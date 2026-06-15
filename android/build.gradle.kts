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

// Flutter expects APK artifacts under <project>/build/, not android/app/build/.
val newBuildDir: Directory =
    rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    project.layout.buildDirectory.value(newBuildDir.dir(project.name))
    project.evaluationDependsOn(":app")

    afterEvaluate {
        extensions.findByType(com.android.build.api.dsl.CommonExtension::class.java)?.apply {
            compileSdk = 36
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
