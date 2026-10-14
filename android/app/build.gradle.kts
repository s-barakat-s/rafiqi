plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mahmoudelnahrawy.tasbeh"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mahmoudelnahrawy.tasbeh"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Research Mushaf resources are staged only into the Android debug asset set.
// Release/profile variants never receive these local, non-approved resources.
val repositoryRoot = rootProject.projectDir.parentFile
val quranResourcesRoot = repositoryRoot.resolve("quran_resources")
val qpcPackRoot = quranResourcesRoot.resolve("qpc_v4_tajweed_pack")
val qpcPackInventory = quranResourcesRoot.resolve("qpc_v4_tajweed_pack_integrity.json")
val qpcPackAuditor = repositoryRoot.resolve("tool/quran/qpc_v4/audit_qpc_v4_pack_integrity.js")
val generatedQuranResearchAssets = layout.buildDirectory.dir("generated/quranResearchAssets/debug")
val verifyQpcV4TajweedPackIntegrity by tasks.registering(Exec::class) {
    description = "Verifies the research-only QPC V4 Tajweed pack before debug asset staging."
    workingDir(repositoryRoot)
    commandLine(
        "node",
        qpcPackAuditor.absolutePath,
        "verify",
        "--pack",
        qpcPackRoot.absolutePath,
        "--inventory",
        qpcPackInventory.absolutePath,
    )
    inputs.file(qpcPackAuditor)
    inputs.file(qpcPackInventory)
    inputs.file(qpcPackRoot.resolve("manifest.json"))
    inputs.dir(qpcPackRoot.resolve("pages"))
    inputs.dir(qpcPackRoot.resolve("geometry"))
}
val prepareQuranResearchAssets by tasks.registering(Sync::class) {
    dependsOn(verifyQpcV4TajweedPackIntegrity)
    from(qpcPackRoot.resolve("manifest.json")) {
        into("flutter_assets/quran_research/qpc_v4_tajweed_pack")
    }
    from(qpcPackRoot.resolve("pages")) {
        into("flutter_assets/quran_research/qpc_v4_tajweed_pack/pages")
    }
    from(qpcPackRoot.resolve("geometry")) {
        into("flutter_assets/quran_research/qpc_v4_tajweed_pack/geometry")
        rename("(.+)\\.json\\.gz", "$1.json_gz")
    }
    from(qpcPackRoot.resolve("licenses")) {
        into("flutter_assets/quran_research/qpc_v4_tajweed_pack/licenses")
    }
    from(qpcPackRoot.resolve("README_RESEARCH_ONLY.md")) {
        into("flutter_assets/quran_research/qpc_v4_tajweed_pack")
    }
    into(generatedQuranResearchAssets)
}

android.sourceSets.getByName("debug").assets.srcDir(generatedQuranResearchAssets)
tasks.configureEach {
    if (name == "mergeDebugAssets") {
        dependsOn(prepareQuranResearchAssets)
    }
}
