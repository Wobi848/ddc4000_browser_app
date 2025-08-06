# Google Play Store Keystore Setup

## 🔍 **Find keytool Command**

Since your Android Studio is in `C:\Program Files\Android\Android Studio1`, the keytool will be in:

```
C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe
```

Or check these common locations:
- `C:\Program Files\Android\Android Studio1\jre\bin\keytool.exe`
- `C:\Program Files\Java\jdk-*\bin\keytool.exe`

## 🔑 **Generate Upload Keystore**

Run this command in the project root directory (`C:\Coding\ddc4000_browser_app`):

```bash
"C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe" -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Alternative method if above path doesn't work:**
```bash
# Try finding keytool first
where keytool
# Or
dir "C:\Program Files\Android\Android Studio1" /s /b | findstr keytool.exe
```

When prompted, provide:
- **Password for keystore:** (Choose a secure password)
- **Password for key:** (Use same password or different)
- **First and Last Name:** Your name or organization
- **Organization:** Your company name
- **City:** Your city
- **State:** Your state/province  
- **Country Code:** Your 2-letter country code (e.g., US, DE, etc.)

## 📝 **Update key.properties**

After generating the keystore, update the `android/key.properties` file with your actual passwords:

```properties
storePassword=YOUR_ACTUAL_KEYSTORE_PASSWORD
keyPassword=YOUR_ACTUAL_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

## 🚀 **Build Release APK**

### **Option 1: Manual Build (Secure)**
1. Edit `android/key.properties` with real passwords:
```properties
storePassword=DDC4000Store
keyPassword=DDC4000Store
keyAlias=upload
storeFile=C:/Coding/ddc4000_browser_app/upload-keystore.jks
```

2. Build the APK:
```bash
flutter clean
flutter pub get
flutter build apk --release
```

3. **IMMEDIATELY** change passwords back to placeholders:
```properties
storePassword=CHANGE_THIS_PASSWORD
keyPassword=CHANGE_THIS_PASSWORD
keyAlias=upload
storeFile=C:/Coding/ddc4000_browser_app/upload-keystore.jks
```

### **Option 2: Local Build Script (Recommended)**
Create `build_release_local.bat` in project root (NOT committed to git):

```batch
@echo off
echo Building DDC4000 Browser Release APK...
echo.

REM Set real passwords temporarily
echo storePassword=DDC4000Store > android\key.properties
echo keyPassword=DDC4000Store >> android\key.properties  
echo keyAlias=upload >> android\key.properties
echo storeFile=C:/Coding/ddc4000_browser_app/upload-keystore.jks >> android\key.properties

REM Clean and build
flutter clean
flutter pub get
flutter build apk --release

REM Restore placeholder passwords for security
echo storePassword=CHANGE_THIS_PASSWORD > android\key.properties
echo keyPassword=CHANGE_THIS_PASSWORD >> android\key.properties
echo keyAlias=upload >> android\key.properties
echo storeFile=C:/Coding/ddc4000_browser_app/upload-keystore.jks >> android\key.properties

echo.
echo ✅ Release APK built successfully!
echo 📁 Location: build\app\outputs\flutter-apk\app-release.apk
echo 🔒 Passwords secured automatically
pause
```

**Usage:** Double-click `build_release_local.bat` to build

The signed APK will be in: `build/app/outputs/flutter-apk/app-release.apk`

## 📱 **Flutter License**

For the Flutter license question - Flutter itself doesn't require license acceptance for building. However, you may need to:

1. **Accept Android licenses** (if not done already):
```bash
flutter doctor --android-licenses
```

2. **Ensure Flutter is properly set up**:
```bash
flutter doctor
```

## ✅ **Verification**

Verify your keystore was created correctly:
```bash
keytool -list -v -keystore upload-keystore.jks -alias upload
```

## 🔒 **Security Notes**

- **Never commit** the actual keystore file or real passwords to version control
- **Backup** your keystore file securely - losing it means you can't update your app
- **Use strong passwords** for both keystore and key
- **Keep key.properties** out of public repositories

## 🎯 **Ready for Google Play Store**

Once you have the signed APK:
1. Create Google Play Console account
2. Upload the `app-release.apk` 
3. Complete store listing with screenshots and description
4. Submit for review

---

**Your DDC4000 Browser app is ready for professional distribution!**