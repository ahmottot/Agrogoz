# AGROGÖZ — Bitki Hastalığı Teşhis Uygulaması

Bu klasör, telefon kamerasıyla çekilen yaprak fotoğrafını **cihaz üzerinde** (internet
gerekmeden) analiz eden bir Flutter uygulamasının tam kaynak kodudur. Model olarak
MobileNetV2 tabanlı, PlantVillage veri setiyle eğitilmiş 38 sınıflık, açık kaynaklı
bir TFLite modeli kullanılıyor (`assets/plant_model.tflite`).

APK'yı **GitHub Actions** üzerinden, hiçbir şey kurmadan otomatik olarak
derletebilirsin.

## Adım Adım: APK'yı Nasıl Alırsın?

### 1. GitHub'a yükle
1. [github.com](https://github.com) üzerinde ücretsiz hesap aç (yoksa).
2. Sağ üstten **"+" → "New repository"** ile yeni bir repo oluştur (adı önemli değil,
   örn. `agrogoz-app`). Public seçmen yeterli.
3. Oluşan boş repo sayfasında **"uploading an existing file"** linkine tıkla.
4. Bu klasördeki **tüm dosya ve klasörleri** (özellikle `.github` klasörünü de
   gizli dosya olduğu için unutma) sürükleyip bırak, sonra **"Commit changes"** de.

   > Not: `.github` klasörü gizli göründüğü için bazı dosya yöneticilerinde
   > görünmeyebilir. Bilgisayardan yüklüyorsan klasörü olduğu gibi (zip'ten çıkarıp)
   > sürüklemen yeterli, GitHub gizli klasörleri de kabul eder.

### 2. Otomatik derlemeyi izle
1. Repo sayfasında üstteki **"Actions"** sekmesine git.
2. "APK Derle" adında bir workflow'un otomatik başladığını göreceksin (dosyaları
   yükleyince otomatik tetiklenir). Başlamadıysa soldan workflow'a tıklayıp
   **"Run workflow"** de.
3. Derleme yaklaşık **5-8 dakika** sürer. Yeşil tik ✅ görününce bitmiştir.

### 3. APK'yı indir
1. Tamamlanan workflow çalıştırmasına tıkla.
2. En altta **"Artifacts"** bölümünde **"agrogoz-apk"** dosyasını indir (bu bir zip).
3. Zip'i aç, içinden `app-release.apk` çıkar.
4. APK'yı telefonuna aktar (kendine e-posta/Drive ile gönderebilirsin).
5. Telefonda dosyaya dokun → "Bilinmeyen kaynaklardan yüklemeye izin ver" derse
   izin ver → **Kur**.

Artık AGROGÖZ tamamen bağımsız, internet gerektirmeden telefonunda çalışıyor.

## Notlar

- Model açık kaynaklı bir GitHub projesinden (PlantVillage veri setiyle eğitilmiş,
  MobileNetV2 mimarisi) alınmıştır; 38 farklı bitki/hastalık sınıfını tanır
  (elma, domates, patates, mısır, üzüm vb.).
- Sonuçlar bilgilendirme amaçlıdır, kesin teşhis için uzmana danışılmalıdır.
- `lib/main.dart` dosyasını değiştirip GitHub'a tekrar push edersen, her seferinde
  APK otomatik olarak yeniden derlenir.
