# OpenState site release review

Candidate branch: `site/human-first-finalization` based on `site/redesign-funnel` at `5acb573`.

## What changed
- Condensed buyer homepage: product promise, guarded editing example, state continuity, measured evidence, host boundaries, two purchase routes and installation.
- One small brand mark instead of the large cube; restrained typography, native system fonts, semantic mobile navigation.
- All eleven pages share header/navigation; 320px-first table layouts, no fake host-support claims.
- Machine-readable `product.json`, `llms.txt`, `llms-full.txt` with the complete 36-tool descriptions and limitations.
- Human-facing pages deliberately shorter than the machine reference, but do not contradict it.

## Preconditions for production (not certified by this branch)
1. Run `node website/scripts/verify-site.mjs` in a checkout.
2. Render every shared page on Chromium at 320, 390, 768, and 1440px; inspect with keyboard and reduced-motion settings. Connector-only review does not establish browser QA.
3. Compare product.json's 36 operations with the exact released MCP and native tool registry.
4. Complete private repo release exam, platform-specific signed-bundle install, and Stripe LIVE purchase/refund/cancellation testing.
5. Confirm pricing. The public candidate uses $10/month and $129 once for 0.x, while pricing history said the latest owner proposal was still under discussion.
6. Do not merge/release this branch until buyer-facing copy, legal terms and payment policy have owner approval.

## AI discoverability
The human site links to `product.json` and `llms-full.txt`. The files provide detailed reference material; their existence does not guarantee AI crawler ingestion or ranking.
