# Android release signing

LumaHub release builds must be signed with a private upload key. Debug signing is intentionally not used for release artifacts.

## 1. Create an upload keystore

Run locally and keep the generated file private:

```bash
keytool -genkeypair -v \
  -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

Do not commit the keystore or passwords. The repository ignores `*.jks`, `*.keystore`, and `android/key.properties`.

## 2. Configure a local release build

Copy the keystore to `android/app/upload-keystore.jks` and create `android/key.properties`:

```properties
storePassword=CHANGE_ME
keyPassword=CHANGE_ME
keyAlias=upload
storeFile=upload-keystore.jks
```

Then build:

```bash
flutter build apk --release
```

## 3. Configure GitHub Actions

Add these repository secrets:

- `ANDROID_KEYSTORE_BASE64` — base64-encoded `upload-keystore.jks`.
- `ANDROID_KEY_ALIAS` — for example `upload`.
- `ANDROID_KEY_PASSWORD`.
- `ANDROID_STORE_PASSWORD`.

Generate the base64 value without line wrapping:

```bash
base64 -w 0 upload-keystore.jks
```

On PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))
```

Back up the keystore and passwords securely. Losing the signing key can prevent future updates to an installed application.
