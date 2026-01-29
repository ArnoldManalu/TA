# Cara Install Flutter di Windows

## Langkah 1: Download Flutter SDK
1. Buka: https://docs.flutter.dev/get-started/install/windows
2. Download Flutter SDK (zip file, ~1GB)
3. Atau langsung download dari: https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip

## Langkah 2: Ekstrak Flutter
1. Buat folder di C:\ (disarankan) atau D:\
2. Ekstrak file zip ke folder tersebut
3. Pastikan struktur folder: `C:\flutter\bin\flutter.bat` ada

## Langkah 3: Tambahkan ke PATH (PENTING!)
### Cara 1: Melalui GUI (Paling Mudah)
1. Tekan `Win + R`, ketik: `sysdm.cpl`, lalu Enter
2. Klik tab **"Advanced"**
3. Klik **"Environment Variables"**
4. Di bagian **"User variables"**, pilih **"Path"**, lalu klik **"Edit"**
5. Klik **"New"**
6. Tambahkan path: `C:\flutter\bin` (atau path dimana Anda ekstrak Flutter)
7. Klik **OK** di semua jendela
8. **RESTART TERMINAL/PowerShell** (sangat penting!)

### Cara 2: Melalui PowerShell (Sebagai Administrator)
Jalankan di PowerShell **sebagai Administrator**:
```powershell
[System.Environment]::SetEnvironmentVariable('Path', [System.Environment]::GetEnvironmentVariable('Path', 'User') + ';C:\flutter\bin', 'User')
```
**Catatan:** Ganti `C:\flutter\bin` dengan path Flutter Anda jika berbeda.

## Langkah 4: Verifikasi Instalasi
Setelah restart terminal, jalankan:
```bash
flutter --version
flutter doctor
```

## Langkah 5: Setelah Flutter Terinstall
Kembali ke project folder dan jalankan:
```bash
cd "D:\PERKULIAHAN\SEMESTER 5\Tugas Akhir\cataract"
flutter pub get
flutter run
```

---
**CATATAN PENTING:**
- Setelah menambah PATH, HARUS restart terminal/PowerShell
- Jangan ekstrak Flutter ke folder dengan spasi atau karakter khusus
- Pastikan folder Flutter memiliki struktur: `flutter\bin\flutter.bat`

