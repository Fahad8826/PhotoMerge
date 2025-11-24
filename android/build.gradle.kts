buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.3.0")
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// FIX: buildDir must be a File, not a String
rootProject.buildDir = file("../build")

subprojects {
    // FIX: buildDir must be a File
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}

subprojects {
    this.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
