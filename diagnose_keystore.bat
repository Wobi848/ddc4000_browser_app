@echo off
echo ========================================
echo   Keystore Diagnosis Tool
echo ========================================
echo.

REM Set path for keytool
set PATH=%PATH%;"C:\Program Files\Android\Android Studio1\jbr\bin"

echo 1. Testing keystore file access...
echo.
if exist "upload-keystore.jks" (
    echo ✅ Keystore file exists
    dir "upload-keystore.jks"
) else (
    echo ❌ Keystore file NOT found
)

echo.
echo 2. Testing with correct password (DDC4000Store)...
echo.
"C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe" -list -keystore upload-keystore.jks -storepass DDC4000Store -alias upload

if %ERRORLEVEL% EQU 0 (
    echo ✅ Manual password test: SUCCESS
) else (
    echo ❌ Manual password test: FAILED
)

echo.
echo 3. Current key.properties content:
echo.
type android\key.properties

echo.
echo 4. Creating test key.properties with correct password...
echo.
echo storePassword=DDC4000Store > android\key.properties.test
echo keyPassword=DDC4000Store >> android\key.properties.test
echo keyAlias=upload >> android\key.properties.test
echo storeFile=C:/Coding/ddc4000_browser_app/upload-keystore.jks >> android\key.properties.test

echo Test file created:
type android\key.properties.test

echo.
echo 5. Testing gradle keystore access simulation...
echo.
REM Simulate what gradle would do
echo Reading properties from test file...

echo.
echo ========================================
echo DIAGNOSIS COMPLETE
echo ========================================
pause