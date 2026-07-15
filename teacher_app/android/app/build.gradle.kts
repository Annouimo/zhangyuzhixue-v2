import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── 签名配置 ──
// 密钥文件：android/zhangyuzhixue-release.keystore
// 密码见 android/key.properties（已 .gitignore，勿提交）
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

// 从 key.properties 中读取签名信息
val storeFileProp = keystoreProperties.getProperty("storeFile") ?: ""
val storePasswordProp = keystoreProperties.getProperty("storePassword") ?: ""
val keyAliasProp = keystoreProperties.getProperty("keyAlias") ?: ""
val keyPasswordProp = keystoreProperties.getProperty("keyPassword") ?: ""

android {
    namespace = "com.zhangyuzhixue.teacher"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // 发布后不可更改
        applicationId = "com.zhangyuzhixue.teacher"
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            keyAlias = keyAliasProp
            keyPassword = keyPasswordProp
            storeFile = if (storeFileProp.isNotEmpty()) rootProject.file(storeFileProp) else null
            storePassword = storePasswordProp
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
