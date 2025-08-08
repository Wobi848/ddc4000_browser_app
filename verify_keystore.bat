@echo off
echo ========================================
echo   Keystore Password Verification
echo ========================================
echo.

echo Enter your keystore password to verify:
powershell -Command "$pwd = Read-Host 'Keystore Password' -AsSecureString; [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd))" > temp_pwd.txt
set /p TEST_PASSWORD=<temp_pwd.txt
del temp_pwd.txt

echo.
echo Testing keystore password...
echo.

echo Testing store password first...
"C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe" -list -keystore upload-keystore.jks -storepass "%TEST_PASSWORD%"

echo.
echo Testing with specific alias 'upload'...
"C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe" -list -keystore upload-keystore.jks -storepass "%TEST_PASSWORD%" -alias upload

echo.
echo Testing both store and key password...
"C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe" -list -keystore upload-keystore.jks -storepass "%TEST_PASSWORD%" -keypass "%TEST_PASSWORD%" -alias upload

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ SUCCESS: Password is correct!
    echo You can now use this password in the build script.
) else (
    echo.
    echo ❌ FAILED: Password is incorrect.
    echo Please try again with the correct password.
)

REM Clear password variable
set TEST_PASSWORD=

echo.
pause