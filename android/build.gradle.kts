buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.3.15")
        // Se usar Crashlytics ou Performance Monitoring, adicione aqui também
        // classpath("com.google.firebase:firebase-crashlytics-gradle:2.9.9")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.buildDir = newBuildDir.asFile

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.buildDir = newSubprojectBuildDir.asFile
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
