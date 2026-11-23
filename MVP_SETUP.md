# GlowSignal Cloud MVP 0.4

## Public URLs
- Marketing site: https://mabdelstar466-dotcom.github.io/profitos-egypt/
- Workspace: https://mabdelstar466-dotcom.github.io/profitos-egypt/workspace.html
- Demo: https://mabdelstar466-dotcom.github.io/profitos-egypt/glowsignal-demo.html

## Implemented in code
- CSV analytics for campaigns, leads, and orders.
- Campaign-level CPL, cost per qualified lead, cost per delivered order, ROAS, CTR, and estimated contribution after recorded costs.
- Data-quality warnings for unmatched campaign names and duplicate IDs.
- Email/password signup, sign-in, magic-link sign-in, and password reset UI through Supabase Auth.
- Private workspace creation and cloud data replacement through Supabase Postgres RPC.
- RLS policies and authenticated table grants in supabase/schema.sql.
- Local browser backup and CSV performance export.
- Public privacy and terms pages dedicated to GlowSignal.

## One-time Supabase setup still needs confirmation
A successful GitHub Pages deployment does not prove that the SQL has been run in the Supabase database.

1. Open the existing Supabase project.
2. In SQL Editor, run the full contents of supabase/schema.sql.
3. In Authentication → URL Configuration set:
   - Site URL: https://mabdelstar466-dotcom.github.io/profitos-egypt/
   - Redirect URL: https://mabdelstar466-dotcom.github.io/profitos-egypt/**
4. Confirm Email provider is enabled. Configure SMTP if messages are delayed or rate-limited.
5. Open Workspace → press «اختبار الاتصال» → create account → confirm email → sign in.
6. Import sample or anonymized CSV files and confirm the status changes to «متصل ومتزامن».

## CSV formats
Campaigns required: campaign_name, spend; optional: date, impressions, clicks, messages.

Leads/orders required: lead_id, campaign_name; optional: created_at, lead_status, objection, agent, first_response_minutes, order_id, order_status, order_value, product_cost, shipping_cost, return_cost, payment_fees.

Use pseudonymous IDs only. Do not upload names, phone numbers, addresses, message text, payment details, or sensitive personal data.

## Metric definition
Estimated contribution = delivered revenue - delivered product cost - recorded shipping for shipped orders - recorded return costs - recorded payment fees - ad spend. This is not accounting net profit and excludes unrecorded overhead, payroll, taxes, discounts, and other costs. Campaign matching is by campaign name, not multi-touch attribution.

## Not yet implemented
- Paid subscriptions and payment processing.
- Direct Meta Ads / TikTok Ads OAuth or automatic imports.
- WhatsApp Business Platform integration.
- Shipping-provider integrations.
- Team invitations, admin roles, and a production support console.
- Production-grade backups, monitoring, and independent security review.

Do not market the current MVP as having these features until implemented and verified.
