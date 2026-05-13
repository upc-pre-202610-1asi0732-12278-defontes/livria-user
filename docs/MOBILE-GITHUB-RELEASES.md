# Despliegue móvil vía GitHub Releases (User y Admin)

**Mobile (User & Admin):** Para las aplicaciones móviles, el despliegue a producción consiste en empaquetar la versión final del APK y publicarla automáticamente en la sección de **GitHub Releases** del repositorio (etiquetando la versión, ej. `v1.0.0`). Esto genera un **enlace de descarga directo y permanente** para que los usuarios bajen e instalen la aplicación en sus celulares **sin depender de la Google Play Store**.

Este documento describe el flujo para **Livria User** (`livria-user`). El mismo patrón se puede copiar al repositorio de la app **Admin** (workflow + tag en ese repo).

---

## Requisitos previos

1. Repositorio en GitHub con el código de la app Flutter.
2. En **Settings → Actions → General → Workflow permissions**, activar **Read and write** (para que el workflow pueda crear/editar Releases con `GITHUB_TOKEN`).
3. Opcional: keystore de **release** propio si dejáis de firmar con debug (hoy `android/app/build.gradle.kts` usa la firma debug en release; válido para pruebas internas).

---

## Publicar una nueva versión (automático)

1. Actualizá `version:` en `pubspec.yaml` (ej. `1.0.1+2`) si corresponde.
2. Commiteá y pusheá a la rama principal (o la que usen).
3. Creá y pusheá un **tag** semver con prefijo `v`:

   ```bash
   git tag v1.0.1
   git push origin v1.0.1
   ```

4. En GitHub: pestaña **Actions** → comprobar que el workflow **Release APK** terminó en verde.
5. En **Releases** aparecerá el release con el archivo `livria-user-v1.0.1.apk`. Ese asset es el enlace de descarga directa (clic derecho → copiar enlace / “Copy link”).

---

## Publicar manualmente (sin Actions)

1. Local: `flutter build apk --release`
2. En GitHub: **Releases → Draft a new release** → elegir o crear el tag `vX.Y.Z` → subir `app-release.apk` (o renombrarlo) → **Publish release**.

---

## App Admin

Duplicá `.github/workflows/release-apk.yml` en el repo de Admin, ajustando:

- el nombre del artefacto (ej. `livria-admin-${{ github.ref_name }}.apk`), y  
- la ruta del proyecto si el `pubspec.yaml` no está en la raíz del repo (`working-directory` en el job).

---

## Notas de seguridad y distribución

- Los usuarios deben permitir **instalar apps de fuentes desconocidas** (o desde el navegador que usen para descargar).
- Un release **público** expone el APK a quien tenga el enlace o el repo; para acceso restringido usad repo privado y control de miembros, u otro hosting con auth.
- Para **Google Play** necesitáis otro pipeline (AAB firmado con la misma clave de subida a Play).
