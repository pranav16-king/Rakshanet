$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Building Lightweight Native Android APK (RakshaNet)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$ROOT = "P:\RakshaNet"
$APP_DIR = "$ROOT\mobile\android_app"
$SDK = "$ROOT\.android_sdk\android-13"

$AAPT2 = "$SDK\aapt2.exe"
$ZIPALIGN = "$SDK\zipalign.exe"
$ANDROID_JAR = "$SDK\android.jar"
$D8_JAR = "$SDK\lib\d8.jar"
$APKSIGNER_JAR = "$SDK\lib\apksigner.jar"

$JDK_BIN = "C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot\bin"
$JAVAC = "$JDK_BIN\javac.exe"
$JAR = "$JDK_BIN\jar.exe"
$KEYTOOL = "$JDK_BIN\keytool.exe"

Set-Location $APP_DIR

# Clean build folders
if (Test-Path "build") { Remove-Item "build" -Recurse -Force }
if (Test-Path "gen") { Remove-Item "gen" -Recurse -Force }
if (Test-Path "bin") { Remove-Item "bin" -Recurse -Force }

New-Item -ItemType Directory -Path "build", "gen", "bin" -Force | Out-Null

# 1. Compile resources with aapt2
Write-Host "`n[1/7] Compiling resources with aapt2..." -ForegroundColor Yellow
& $AAPT2 compile --dir res -o build\compiled_res.zip

# 2. Link resources, generate R.java, and create unaligned APK
Write-Host "[2/7] Linking resources and generating R.java..." -ForegroundColor Yellow
& $AAPT2 link -I $ANDROID_JAR --manifest AndroidManifest.xml --java gen -o build\unaligned.apk build\compiled_res.zip -A assets

# 3. Compile Java sources
Write-Host "[3/7] Compiling Java sources with javac..." -ForegroundColor Yellow
$javaFiles = (Get-ChildItem -Path "src\org\rakshanet\*.java", "gen\org\rakshanet\*.java").FullName
& $JAVAC -cp $ANDROID_JAR -d bin $javaFiles

# 4. Dex bytecode with D8
Write-Host "[4/7] Converting bytecode to classes.dex with D8..." -ForegroundColor Yellow
$classFiles = (Get-ChildItem -Path "bin\org\rakshanet\*.class").FullName
java -cp $D8_JAR com.android.tools.r8.D8 --lib $ANDROID_JAR --output bin $classFiles

# 5. Pack classes.dex into unaligned APK
Write-Host "[5/7] Adding classes.dex to APK package..." -ForegroundColor Yellow
Set-Location bin
& $JAR uf ..\build\unaligned.apk classes.dex
Set-Location $APP_DIR

# 6. Zipalign APK
Write-Host "[6/7] Aligning APK with zipalign..." -ForegroundColor Yellow
& $ZIPALIGN -f -p 4 build\unaligned.apk build\aligned.apk

# 7. Generate debug keystore and sign
Write-Host "[7/7] Signing APK with apksigner..." -ForegroundColor Yellow
$keystorePath = "$APP_DIR\debug.keystore"
if (-not (Test-Path $keystorePath)) {
    & $KEYTOOL -genkey -v -keystore $keystorePath -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=RakshaNet,O=RakshaNet,C=IN"
}

$OUTPUT_APK = "$ROOT\RakshaNet.apk"
java -jar $APKSIGNER_JAR sign --ks $keystorePath --ks-pass pass:android --ks-key-alias androiddebugkey --key-pass pass:android --out $OUTPUT_APK build\aligned.apk

# Verify signature
java -jar $APKSIGNER_JAR verify --verbose $OUTPUT_APK

$apkSizeMB = [math]::Round((Get-Item $OUTPUT_APK).Length / 1MB, 2)
Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "  SUCCESS! APK Built Successfully: $OUTPUT_APK" -ForegroundColor Green
Write-Host "  File Size: $apkSizeMB MB (Lightweight & Small Sized)" -ForegroundColor Green
Write-Host "==========================================================`n" -ForegroundColor Green
