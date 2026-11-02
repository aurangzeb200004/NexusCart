# NexusCart: Multi-Vendor Headless E-Commerce & Omnichannel Storefront

A production-grade, multi-tenant headless e-commerce platform built for **Muhammad Aurangzeb's** portfolio.

---

## ✨ Core Modules & Engineering Specs

### 1. High-Speed Headless Storefront
- **Sub-2ms Simulated MeiliSearch Engine**: Instant reactive keyword, SKU, and specs filtering with dynamic execution latency benchmarking.
- **Multi-Tenant Storefront Switcher**: Seamless switching between *Global Marketplace (All Tenants)* and individual boutique merchants (*Aether Audio Lab*, *Kuro Minimalist Gear*, *Veloce Espresso Roasters*, *Nomad Tech Carry*).
- **Multi-Currency Conversion Engine**: Real-time price rendering across `USD $`, `EUR €`, `GBP £`, and `PKR ₨` across storefront cards, quick specs modals, cart splits, and tax receipts.
- **Dynamic Category & Facet Filtering**: Filter by Audio, Desk Setup, Coffee Gear, Carry & Travel, and Accessories with real-time SKU counts.
- **Quick Specs Modal**: Detailed engineering specifications, stock indicators, and direct add-to-cart.

### 2. Unified Multi-Vendor Cart & Stripe Connect Split-Payouts
- **Omnichannel Unified Cart**: Shop across multiple independent merchants in a single checkout session.
- **Automated Stripe Connect Split Routing**:
  - Automatically calculates the **2.5% platform commission**.
  - Distributes **97.5% net payouts** directly to each merchant's connected Stripe account (`acct_aether_99x`, `acct_kuro_42k`, `acct_veloce_88v`, `acct_nomad_17n`).
- **Flexible Payment Methods**: Simulated Stripe Credit/Debit Cards, Apple Pay, and SEPA/ACH Direct Bank Wire.
- **Stock Guard**: Real-time inventory deduction and out-of-stock prevention.

### 3. Self-Service Vendor Portal (Merchant CMS)
- **Tenant Management**: Switch between verified merchants.
- **Live SKU Inventory & Inline Price Editor**: Edit pricing and stock inline with instant MeiliSearch catalog updates.
- **SKU Deactivation**: Remove or retire SKUs from the live storefront.
- **Publish New Merchant SKU**: Modal with SKU code generator, photographic image presets, category selection, and technical specification tags.
- **Vendor Telemetry**: Track connected Stripe account status, lifetime gross sales, net payouts received, and merchant ratings.

### 4. Order Lifecycle & Real-Time Shipment Tracker
- **5-Stage Logistics Progression**:
  1. `Order Placed & Split Paid` (Stripe Transfer Group executed)
  2. `Vendor Packed & Verified` (Merchant barcode inspection)
  3. `In Transit (DHL Express)` (Air freight dispatch)
  4. `Out for Local Delivery` (Courier on final route)
  5. `Delivered & Settled` (Delivery signed; escrow released)
- **DHL Express Airway Telemetry**: Unique simulated tracking numbers with interactive milestone advance controls.
- **Stripe Connect Reversal / Refund**: Complete reversal simulation restoring SKU inventory.
- **Automated Tax Invoice Modal**: Itemized tax receipt with line items, vendor split ledger, printable view (`Ctrl+P` / `window.print()`), and JSON export.

### 5. Headless Architecture & Row-Level Security (RLS)
- **Supabase PostgreSQL Schema**: Strict RLS policies enforcing tenant isolation for product catalog mutations and vendor payout ledgers (`supabase/schema.sql`).
- **Stripe Connect API Webhooks**: Production-grade transfer group routing and webhook event handlers.
- **MeiliSearch Sync Worker**: Searchable and filterable attributes indexing pipeline.
- **Interactive Split Calculator**: Live tester for arbitrary cart gross amounts and payout distributions.

---

## 🚀 How to Run the Project

### Option A: Standard Node.js Server (Recommended)
Runs the zero-dependency built-in server:
```bash
npm start
# or
npm run dev
# or
node server.js
```
Then open your browser to **[http://localhost:3000](http://localhost:3000)**.

### Option B: Python Local Server
```bash
python -m http.server 3000
```
Open **[http://localhost:3000](http://localhost:3000)** in your browser.

### Option C: Zero-Build Browser Direct Launch
Simply double-click or open **`index.html`** in any modern web browser! Everything is pre-configured with React 18, Babel Standalone, and Tailwind CSS.

---

## 📂 Project Structure

```text
nexuscart-platform/
├── index.html              # Standalone, zero-build React 18 application with Tailwind CSS
├── server.js               # Zero-dependency Node.js HTTP server (port 3000)
├── package.json            # Scripts & project manifest
├── README.md               # Architecture documentation & quick-start guide
├── src/
│   └── store/
│       └── useCartStore.js # Zustand persistent multi-tenant cart state engine
└── supabase/
    └── schema.sql          # PostgreSQL schema with Row-Level Security (RLS) & seed data
```

---

## 👨‍💻 Author & Credits
Built for **Muhammad Aurangzeb's** portfolio showcasing production-grade Headless Multi-Tenant E-Commerce Architecture.
