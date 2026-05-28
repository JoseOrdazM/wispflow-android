# Configuración del Proyecto WispFlow Android

## 1. Estructura del Proyecto

Hay **dos proyectos** en el repositorio:

### A) `wispflow-android/` (Activo - WispFlow)
- **Nombre**: `wispflow_android`
- **Descripción**: Floating microphone overlay para transcripción por voz
- **Entry point**: `lib/main.dart`
- **Overlay**: `lib/overlay.dart` (entry point separado `overlayMain()`)

### B) Raíz `/` (IronWorker Dictation - Proyecto legado)
- **Nombre**: `ironworker_dictation`
- **Descripción**: Dictado por voz con Whisper.cpp (versión anterior)
- **No se usa actualmente** para el build Android

---

## 2. Configuración Gradle (Build System)

### Archivos clave:

| Archivo | Propósito |
|---------|-----------|
| `wispflow-android/android/build.gradle.kts` | Gradle raíz del proyecto Android |
| `wispflow-android/android/settings.gradle.kts` | Plugin management y configuración de módulos |
| `wispflow-android/android/app/build.gradle.kts` | Build config de la app (SDK, signing, etc.) |
| `wispflow-android/android/gradle.properties` | Propiedades globales de Gradle |
| `wispflow-android/android/gradle/wrapper/gradle-wrapper.properties` | Versión de Gradle wrapper |

### Versiones:

| Componente | Versión |
|------------|---------|
| **Gradle** | `8.3` (wrapper) |
| **Android Gradle Plugin (AGP)** | `8.1.4` |
| **Kotlin** | `1.9.22` |
| **compileSdk** | `34` |
| **targetSdk** | `34` |
| **minSdk** | `21` |
| **ndkVersion** | `25.1.8937393` |
| **Java** | `17` (sourceCompatibility, targetCompatibility, jvmTarget) |

### Plugins aplicados:
- `com.android.application` (AGP 8.1.4)
- `org.jetbrains.kotlin.android` (Kotlin 1.9.22)
- `dev.flutter.flutter-gradle-plugin` (Flutter)

---

## 3. Configuración de Signing (Firma APK)

### Release (firma con variables de entorno):
```kotlin
signingConfigs {
    create("release") {
        storeFile = System.getenv("WISPFLOW_STORE_FILE")?.let { file(it) }
        storePassword = System.getenv("WISPFLOW_STORE_PASSWORD")
        keyAlias = System.getenv("WISPFLOW_KEY_ALIAS")
        keyPassword = System.getenv("WISPFLOW_KEY_PASSWORD")
    }
}
```

**Variables de entorno requeridas para release:**
- `WISPFLOW_STORE_FILE` → Ruta al keystore (.jks)
- `WISPFLOW_STORE_PASSWORD` → Contraseña del keystore
- `WISPFLOW_KEY_ALIAS` → Alias de la clave
- `WISPFLOW_KEY_PASSWORD` → Contraseña de la clave

### Debug:
Usa el signing config por defecto de debug (`signingConfigs.getByName("debug")`).

---

## 4. Build Types

| Tipo | Minify | Shrink | Signing |
|------|--------|--------|---------|
| **release** | ✅ `isMinifyEnabled = true` | ✅ `isShrinkResources = true` | Firma release (env vars) |
| **debug** | ❌ | ❌ | Firma debug por defecto |

### ProGuard:
- Archivo: `wispflow-android/android/app/proguard-rules.pro`
- Reglas: Flutter, Kotlin coroutines, clases de la app

---

## 5. Dependencias Flutter (pubspec.yaml)

### `wispflow-android/pubspec.yaml`:
```yaml
dependencies:
  flutter_overlay_window: ^0.4.3    # Overlay flotante
  http: ^1.1.0                      # Peticiones HTTP (transcripción)
  shared_preferences: ^2.2.0        # Persistencia de settings
  permission_handler: ^11.1.0       # Permisos
  record: ^4.0.0                    # Grabación de audio
```

### `pubspec.yaml` (raíz - legado):
```yaml
dependencies:
  record: ^5.0.4
  path_provider: ^2.1.1
  clipboard: ^0.1.3
  permission_handler: ^11.1.0
```

---

## 6. Permisos Android (AndroidManifest.xml)

### Permisos solicitados:
| Permiso | Propósito |
|---------|-----------|
| `RECORD_AUDIO` | Grabación de micrófono |
| `SYSTEM_ALERT_WINDOW` | Overlay flotante sobre otras apps |
| `FOREGROUND_SERVICE` | Servicio en foreground para el overlay |
| `INTERNET` | Llamadas a API de transcripción |
| `POST_NOTIFICATIONS` | Notificaciones (Android 13+) |
| `FOREGROUND_SERVICE_DATA_SYNC` | Servicio foreground tipo dataSync |

### Activity principal:
- `com.wispflow.wispflow_android.MainActivity`
- `launchMode: singleTop`
- `taskAffinity: ""` (permite que no se agrupe con otras tasks)
- `excludeFromRecents: true` (no aparece en recents)

### Servicio overlay:
- `com.hs.gs.flutter_overlay_window.FlutterOverlayService`
- `foregroundServiceType: "dataSync"`

---

## 7. CI/CD (GitHub Actions)

### Workflow principal: `wispflow-android/.github/workflows/build-android.yml`
- **Trigger**: Push a `main` o manual (`workflow_dispatch`)
- **Flutter**: `3.24.3` stable
- **Java**: Temurin 17
- **Build**: `flutter build apk --release`
- **Output**: `build/app/outputs/flutter-apk/app-release.apk`
- **Release**: Crea GitHub Release `v1.1` automáticamente

### Workflow secundario: `.github/workflows/flutter_build_release.yml`
- Más completo: incluye análisis, tests, split-per-abi, firma con secrets
- Usa secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`

---

## 8. Estructura del Código Dart

```
lib/
├── main.dart                    # Entry point principal (App + UI)
├── overlay.dart                 # Entry point del overlay flotante
├── models/
│   └── settings.dart            # Modelo AppSettings con persistencia
├── screens/
│   └── settings_screen.dart     # Pantalla de configuración
└── services/
    ├── audio_recorder.dart      # Grabación de audio (WAV 16kHz)
    ├── overlay_service.dart     # Lógica del overlay (singleton)
    └── transcription_service.dart # Transcripción (OpenAI o custom server)
```

### Flujo de la app:
1. `main.dart` → Inicia app, carga settings, muestra UI principal
2. Usuario presiona "Start Bubble" → `OverlayService.startOverlay()`
3. `overlay.dart` → Muestra círculo flotante (estados: idle/recording/processing)
4. Tap en bubble → `OverlayService.onBubbleTap()`:
   - Idle → Inicia grabación (AudioRecorderService)
   - Recording → Detiene grabación, envía a transcripción
   - Processing → Muestra spinner
5. Transcripción completada → Copia al clipboard, envía resultado a main

---

## 9. Configuración de Análisis (analysis_options.yaml)

```yaml
include: package:flutter_lints/flutter.yaml
linter:
  rules: []
```

Sin reglas personalizadas adicionales.

---

## 10. Problemas Detectados / Recomendaciones

### ⚠️ `settings.gradle.kts` - Typo en variable
```kotlin
val flutterSkkPath = properties.getProperty("flutter.sdk")
```
**Error**: `flutterSkkPath` debería ser `flutterSdkPath`. Aunque funciona porque se usa la misma variable, es confuso.

### ⚠️ `android.newDsl=false` en gradle.properties
Esto deshabilita el nuevo DSL de Gradle. Recomendado para compatibilidad con AGP 8.1.4.

### ⚠️ `android.builtInKotlin=false`
Deshabilita el Kotlin built-in de Gradle, usando el plugin de Kotlin explícitamente.

### ⚠️ Test desactualizado
`widget_test.dart` referencia `MyApp` que no existe (la app usa `WispFlowApp`). El test fallará.

### ⚠️ Proyecto raíz (ironworker_dictation) vs wispflow-android
Hay dos proyectos en el repo. El build de CI apunta a `wispflow-android/`. Asegurarse de que el working directory en GitHub Actions sea `wispflow-android`.

---

## 11. Comandos Útiles

```bash
# Build debug APK
cd wispflow-android && flutter build apk --debug

# Build release APK (requiere env vars de signing)
cd wispflow-android && flutter build apk --release

# Build release split-per-abi
cd wispflow-android && flutter build apk --release --split-per-abi

# Análisis estático
cd wispflow-android && flutter analyze

# Tests
cd wispflow-android && flutter test

# Limpiar build
cd wispflow-android && flutter clean
```
