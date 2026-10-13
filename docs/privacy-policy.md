# Privacy Policy for SahiFile

**Effective Date:** October 13, 2026  
**App Name:** SahiFile: Photo & PDF Tools  
**Contact:** support@sahifile.app  

> **Notice:** SahiFile is built with a strict local-first architecture. All photo resizing, signature preparation, file compression, and PDF generation operations execute exclusively on your device hardware.

---

### 1. Information We Do Not Collect
- We do **not** collect or upload your photos, documents, signatures, or generated PDFs.
- We do **not** collect your personal identity (name, email, phone number) or require user accounts.
- We do **not** collect your device location or contacts.

### 2. Device Storage & Permission Usage
- **Photo & Document Selection:** SahiFile utilizes Android's System Photo Picker and the system Storage Access Framework. The application only accesses files explicitly chosen by you in the system picker.
- **No Broad Storage Permission:** SahiFile does not request `MANAGE_EXTERNAL_STORAGE` or broad device-wide storage access.
- **App-Private Sandbox:** Working copies created during processing reside exclusively in the app's private internal storage sandbox (`/data/user/0/.../app_flutter/sahifile_workspace`).
- **Temporary Cache:** Temporary intermediate files are stored in the app's cache directory and can be purged at any time from within **Settings > Clear Temp Cache**.

### 3. Sharing and Export
- Output files are only shared when you tap the **Share** button, invoking Android's native system Sharesheet.
- Exported files are written directly through system storage intents.

### 4. Third-Party Services
- SahiFile does not integrate third-party analytics SDKs, trackers, or behavioral profiling tools in the core application.
- If advertising or in-app billing SDKs are configured in future production builds, their data handling practices will be explicitly disclosed here.

### 5. Policy Updates & Inquiries
For questions regarding this policy or data safety, contact: `support@sahifile.app`.
