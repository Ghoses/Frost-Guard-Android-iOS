allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            setUrl("${project(":background_fetch").projectDir}/libs")
        }
        maven {
            setUrl("https://github.com/transistorsoft/flutter_background_fetch/raw/master/dist")
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
