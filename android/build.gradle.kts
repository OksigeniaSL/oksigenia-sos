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

    // 👇 FIX PARA PLUGINS ANTIGUOS (background_sms) 👇
    // IMPORTANTE: Este bloque debe estar ANTES de 'evaluationDependsOn'
    afterEvaluate {
        // Verificamos si es un proyecto Android
        if (extensions.findByName("android") != null) {
            val android = extensions.findByName("android")
            if (android != null) {
                try {
                    // Usamos reflexión para acceder a 'namespace' (propiedad moderna)
                    // sin romper la compilación si la clase no existe en el classpath del script
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    val currentNamespace = getNamespace.invoke(android)
                    
                    // Si el namespace es nulo (típico de plugins viejos como background_sms)
                    if (currentNamespace == null) {
                        val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                        // Usamos el 'group' del proyecto como namespace (ej: com.babariviere.sms)
                        val newNamespace = group.toString()
                        setNamespace.invoke(android, newNamespace)
                        println("Oksigenia Fix: Namespace '$newNamespace' inyectado para el módulo '${name}'")
                    }
                } catch (e: Exception) {
                    // Si falla la reflexión, ignoramos silenciosamente
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}