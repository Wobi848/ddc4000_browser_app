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

Once keystore is configured:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

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