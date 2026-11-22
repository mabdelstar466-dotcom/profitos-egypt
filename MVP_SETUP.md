# GlowSignal MVP 0.2

## What is live
A working, browser-only analytics MVP for beauty and haircare ecommerce brands. It imports two CSV files, computes metrics, and saves data in the user's browser.

## URLs
- Workspace: https://mabdelstar466-dotcom.github.io/profitos-egypt/workspace.html
- Marketing site: https://mabdelstar466-dotcom.github.io/profitos-egypt/
- Demo with synthetic data: https://mabdelstar466-dotcom.github.io/profitos-egypt/glowsignal-demo.html

## CSV imports
### Campaign file
Required: campaign_name, spend
Optional: date, impressions, clicks, messages

### Leads and orders file
Required: lead_id, campaign_name
Optional: created_at, lead_status, objection, agent, first_response_minutes, order_id, order_status, order_value, product_cost, shipping_cost, return_cost, payment_fees

One row per lead/order record. Use unique pseudonymous lead_id and order_id. Do not upload names, phone numbers, addresses, or message text.

## Metric definition
Estimated contribution = delivered order revenue - delivered product cost - shipping cost for shipped orders - return costs - payment fees - ad spend.
This is not net accounting profit. It excludes overhead, payroll, taxes, discounts and any missing costs.

Campaign attribution is a simple exact-name join. It is not multi-touch attribution. If campaign names differ between exports, records will not join.

## Data handling
Files are processed in the browser and stored in localStorage. No server upload, login, cross-device sync, subscription, billing, Meta/WhatsApp/TikTok integration, or automated AI inference is active in this release. Users can clear data from the app. Browser storage can be lost if browser data is cleared.

## Next production milestones
1. Validate with 3-5 beauty/haircare merchants using anonymized CSV exports.
2. Build hosted authentication and tenant-isolated Postgres persistence with strict row-level security.
3. Add secure Meta OAuth and permitted Marketing API / Insights data access after app registration and review as required.
4. Add optional WhatsApp Business Platform connection only after permissions, consent and webhook handling are approved.
5. Add TikTok data/posting integration only after TikTok developer app review and user authorization.
6. Add recurring billing only after local payment provider eligibility and merchant-of-record requirements are checked.

## Current hosting
GitHub Pages static hosting. No server-side secrets may be placed in this repository. Do not add Meta, TikTok, WhatsApp, Supabase service-role or payment secrets to client-side code.
