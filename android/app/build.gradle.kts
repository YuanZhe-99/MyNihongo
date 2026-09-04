import java.util.Properties

plugins {
    id("com.android.application")
    // Built-in Kotlin: the app no longer applies the Kotlin Gradle Plugin
    // itself (Flutter/AGP provide Kotlin support). The KGP version stays
    // declared in settings.gradle.kts because several Flutter plugins still
    // apply KGP and resolve it from there.
    // The Flutter Gradle Plugin must be applied after the Android plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.yuanzhe.my_nihongo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.yuanzhe.my_nihongo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // 26, not flutter.minSdkVersion (24): the ML Kit GenAI libraries below
        // require API 26. Nothing else in the app does. See
        // doc/en-us/android-aicore.md.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"]!!)
                storePassword = keystoreProperties["storePassword"] as String?
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Additive to the rules the libraries and AGP contribute. The file
            // exists only for ML Kit GenAI, which R8 otherwise shrinks into a
            // runtime NullPointerException that looks like an unsupported
            // device. See the comment in proguard-rules.pro.
            proguardFiles("proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // On-device generative AI through Android AICore. Both are beta APIs with
    // no deprecation policy, so the versions are exact rather than dynamic.
    // genai-prompt is coroutine-based; genai-proofreading returns Guava
    // ListenableFutures. See doc/en-us/android-aicore.md.
    //
    // genai-prompt must be at least 1.0.0-beta4: an earlier client throws
    // FEATURE_NOT_FOUND from checkStatus() on a Gemini Nano v4 device, which
    // is every non-Pixel device the Prompt API supports — the Galaxy
    // Z Fold8 included. beta2 is why a Fold 8 reported the feature missing.
    implementation("com.google.mlkit:genai-prompt:1.0.0-beta4")
    implementation("com.google.mlkit:genai-proofreading:1.0.0-beta1")
    // The Prompt API suspends and returns a Flow; the coroutine runtime is not
    // pulled in by the Flutter Android embedding, so it is declared here.
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
}

// Built-in Kotlin migration: align the Kotlin jvmTarget with the Java 17
// compileOptions above. Without this, Kotlin defaults to the running JDK's
// target and the build fails with an Inconsistent JVM Target error.
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
