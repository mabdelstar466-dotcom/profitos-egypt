# GlowSignal Cloud MVP 0.3

## What is live in the repository
- CSV analytics workspace for beauty and haircare ecommerce.
- Email/password authentication using Supabase Auth.
- One private workspace per account.
- Cloud persistence in Supabase Postgres with Row Level Security.
- Browser-local backup.
- No paid subscriptions, payment collection, Meta OAuth, WhatsApp Business API, or TikTok integration yet.

## Public URLs
- Marketing site: https://mabdelstar466-dotcom.github.io/profitos-egypt/
- Workspace: https://mabdelstar466-dotcom.github.io/profitos-egypt/workspace.html
- Demo: https://mabdelstar466-dotcom.github.io/profitos-egypt/glowsignal-demo.html

## Required one-time Supabase setup
1. Open the Supabase project.
2. Go to SQL Editor.
3. Copy the full contents of `supabase/schema.sql` from this repository and run it. The SQL is safe to re-run and includes authenticated Data API grants plus RLS policies.
4. Go to Authentication → URL Configuration:
   - Set Site URL to `https://mabdelstar466-dotcom.github.io/profitos-egypt/`.
   - Add `https://mabdelstar466-dotcom.github.io/profitos-egypt/**` to Redirect URLs.
5. Open the Workspace URL and create an account. Confirm the email if Supabase requests it, then sign in.
6. Upload the two CSV files. Imports are synced to the signed-in workspace.

## CSV format
Campaign file required fields: `campaign_name, spend`.
Optional: `date, impressions, clicks, messages`.

Leads/orders file required fields: `lead_id, campaign_name`.
Optional: `created_at, lead_status, objection, agent, first_response_minutes, order_id, order_status, order_value, product_cost, shipping_cost, return_cost, payment_fees`.

Use unique pseudonymous IDs only. Never upload customer names, phone numbers, addresses, or message text.

## Important metric limitation
Estimated contribution = delivered order revenue - delivered product cost - recorded shipping - return costs - payment fees - ad spend. It is not statutory accounting profit and excludes overhead, payroll, taxes, discounts and unrecorded costs. Campaign matching is exact campaign-name matching, not multi-touch attribution.

## Security
The browser uses only the Supabase Publishable Key. Never place the Supabase service-role key in GitHub Pages or any client-side file. RLS controls access to workspace rows. The SQL grants Data API table access only to authenticated users; policies still restrict each user's rows.

## Remaining work before paid launch
- Test registration, email confirmation, login, logout, and cross-device persistence.
- Test RLS isolation with a second account.
- Add invitation/roles and administrative support.
- Add Meta/TikTok/WhatsApp connections only after platform authorization and reviews.
- Add subscription billing after provider and legal requirements are confirmed.
- Complete backup/restore, error monitoring, and production security review.
