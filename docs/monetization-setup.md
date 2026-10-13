# SahiFile Monetization & Configuration Guide

## 1. Monetization Philosophy
- **Core Utilities Are Always Free**: Basic photo resizing, signature preparation, image compression, and Images-to-PDF will remain completely functional without forced paywalls or mandatory subscriptions.
- **No Watermarks**: SahiFile does not apply watermarks to generated photos or PDFs.

## 2. Optional Pro Tier (Planned)
- **Product ID**: `sahifile_pro_lifetime` (Non-consumable one-time in-app product in Google Play Console).
- **Pro Benefits**:
  - Ad-free experience.
  - Unlimited custom presets.
  - Batch processing tools.
- **Pricing**: Final price must be configured directly in Google Play Console regional pricing tables (never hardcoded in client code).

## 3. Advertising Guidelines (If Enabled)
- If Google Mobile Ads (`google_mobile_ads`) is added in future releases:
  - Ad placement must strictly be confined to non-intrusive banner slots on Home or Tools gallery.
  - **Zero Ads in Workflow**: No interstitial or rewarded ads during image cropping, active processing, or output screens.
  - Always use Google official test ad unit IDs during development.
