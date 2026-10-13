# SahiFile Known Limitations & Boundaries

1. **Password-Protected / Encrypted PDFs**:
   - SahiFile cannot merge or optimize password-encrypted PDFs without prior decryption. When encountered, the app surfaces a custom error dialog asking the user to provide an unlocked copy.

2. **Theoretical JPEG Size Floor**:
   - An image with very large pixel dimensions (e.g. 4000 × 4000 px) contains a minimum entropy payload that cannot be encoded below certain strict limits (e.g. 10 KB) without extreme quantization artifacts or resolution downscaling. SahiFile honestly alerts the user rather than faking file sizes or corrupting files.

3. **PDF Compression of Already Optimized Files**:
   - When a PDF already contains maximally compressed embedded images and deflated streams, further structural optimization will not reduce byte count. In such cases, SahiFile honestly reports that the document is already optimized rather than claiming a false reduction.

4. **System File Deletion**:
   - Deleting a history entry within SahiFile removes the app-managed internal sandbox copy. Files previously shared or exported to external locations (e.g., Downloads folder) remain under system control and are not touched.
