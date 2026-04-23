

plugins {
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: File = rootProject.projectDir.parentFile.resolve("build")
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.resolve(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
}

// Evaluation depends on app moved to declarative plugin

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
