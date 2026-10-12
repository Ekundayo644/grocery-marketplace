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
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    // Force a compatible Cronet version for AGP 9+
    configurations.all {
        resolutionStrategy {
            force("org.chromium.net:cronet-embedded:143.7445.0")
            force("org.chromium.net:cronet-api:143.7445.0")
            force("org.chromium.net:cronet-shared:143.7445.0")
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
