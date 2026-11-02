-- ============================================================================
-- NexusCart Multi-Tenant Headless E-Commerce Schema
-- Database: Supabase PostgreSQL with Strict Row-Level Security (RLS)
-- Portfolio Implementation for: Muhammad Aurangzeb
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------------------
-- 1. VENDORS (Tenants)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  stripe_account_id TEXT NOT NULL UNIQUE,
  tagline TEXT,
  location TEXT,
  rating NUMERIC(3,2) DEFAULT 5.00,
  verified BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 2. PRODUCTS (SKU Catalog)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID NOT NULL REFERENCES public.vendors(id) ON DELETE CASCADE,
  sku TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  price_usd NUMERIC(10,2) NOT NULL CHECK (price_usd > 0),
  stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  image_url TEXT,
  specs JSONB DEFAULT '[]'::jsonb,
  rating NUMERIC(3,2) DEFAULT 5.00,
  reviews_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for MeiliSearch sync and fast retrieval
CREATE INDEX IF NOT EXISTS idx_products_vendor ON public.products(vendor_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_sku ON public.products(sku);

-- ----------------------------------------------------------------------------
-- 3. ORDERS (Unified Multi-Vendor Checkouts)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number TEXT UNIQUE NOT NULL, -- e.g. NX-90412
  customer_email TEXT NOT NULL,
  currency TEXT NOT NULL DEFAULT 'USD',
  total_amount NUMERIC(10,2) NOT NULL,
  platform_fee_amount NUMERIC(10,2) NOT NULL, -- 2.5% platform commission
  status TEXT NOT NULL DEFAULT 'paid_and_split', -- paid_and_split, refunded, in_transit, delivered
  logistics_step INTEGER NOT NULL DEFAULT 0 CHECK (logistics_step BETWEEN 0 AND 4),
  carrier_tracking_number TEXT, -- DHL Express tracking
  payment_method TEXT DEFAULT 'stripe_connect_split',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 4. ORDER ITEMS (Line items tagged by vendor tenant)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  vendor_id UUID NOT NULL REFERENCES public.vendors(id) ON DELETE RESTRICT,
  title TEXT NOT NULL,
  sku TEXT NOT NULL,
  unit_price NUMERIC(10,2) NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  line_total NUMERIC(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_vendor ON public.order_items(vendor_id);

-- ----------------------------------------------------------------------------
-- 5. VENDOR PAYOUT SPLITS (Stripe Connect Transfer Ledger)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.vendor_payout_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  vendor_id UUID NOT NULL REFERENCES public.vendors(id) ON DELETE RESTRICT,
  stripe_account_id TEXT NOT NULL,
  gross_amount NUMERIC(10,2) NOT NULL,
  platform_fee_amount NUMERIC(10,2) NOT NULL, -- 2.5% cut
  net_payout_amount NUMERIC(10,2) NOT NULL,    -- 97.5% routed to merchant
  stripe_transfer_id TEXT,                     -- tr_xxxxxxxxxx
  settlement_status TEXT NOT NULL DEFAULT 'completed', -- completed, reversed
  settled_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vendor_splits_vendor ON public.vendor_payout_splits(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_splits_order ON public.vendor_payout_splits(order_id);

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE public.vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_payout_splits ENABLE ROW LEVEL SECURITY;

-- Vendors: Public can view active vendors; only platform admins can mutate
CREATE POLICY "Public read vendors"
ON public.vendors FOR SELECT
USING (true);

-- Products: Anyone can read products on the storefront
CREATE POLICY "Public read products"
ON public.products FOR SELECT
USING (true);

-- Products: Strict tenant isolation for vendor write operations
-- Requires JWT with claim `tenant_id` matching vendor_id
CREATE POLICY "Vendor tenant catalog management"
ON public.products FOR ALL
USING (vendor_id::text = auth.jwt() ->> 'tenant_id')
WITH CHECK (vendor_id::text = auth.jwt() ->> 'tenant_id');

-- Orders: Customers can view orders tied to their email or JWT user
CREATE POLICY "Customer read own orders"
ON public.orders FOR SELECT
USING (
  customer_email = auth.jwt() ->> 'email'
  OR auth.jwt() ->> 'role' = 'service_role'
);

-- Order Items: Vendors can only view order items belonging to their vendor_id
CREATE POLICY "Vendor view own order line items"
ON public.order_items FOR SELECT
USING (
  vendor_id::text = auth.jwt() ->> 'tenant_id'
  OR auth.jwt() ->> 'role' = 'service_role'
);

-- Vendor Payouts: Merchants can only inspect their own Stripe settlement ledger
CREATE POLICY "Vendor view own payout splits"
ON public.vendor_payout_splits FOR SELECT
USING (
  vendor_id::text = auth.jwt() ->> 'tenant_id'
  OR auth.jwt() ->> 'role' = 'service_role'
);

-- ============================================================================
-- INITIAL SEED DATA
-- ============================================================================

INSERT INTO public.vendors (id, name, slug, stripe_account_id, tagline, location, rating)
VALUES
  ('a1111111-1111-1111-1111-111111111111', 'Aether Audio Lab', 'aether-audio', 'acct_aether_99x', 'Precision planar magnetic acoustics & studio DACs.', 'Berlin, DE', 4.95),
  ('b2222222-2222-2222-2222-222222222222', 'Kuro Minimalist Gear', 'kuro-gear', 'acct_kuro_42k', 'CNC-machined titanium everyday carry & desk architecture.', 'Tokyo, JP', 4.91),
  ('c3333333-3333-3333-3333-333333333333', 'Veloce Espresso Roasters', 'veloce-coffee', 'acct_veloce_88v', 'Micro-lot specialty coffee & precision telemetry brewers.', 'Milan, IT', 4.98),
  ('d4444444-4444-4444-4444-444444444444', 'Nomad Tech Carry', 'nomad-carry', 'acct_nomad_17n', 'Weatherproof ballistic nylon packs & GaN charging hubs.', 'San Francisco, US', 4.89)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.products (vendor_id, sku, title, category, price_usd, stock, image_url, specs, rating, reviews_count)
VALUES
  ('a1111111-1111-1111-1111-111111111111', 'AET-PM1-BLK', 'Aether Reference Planar Headphones', 'Audio', 499.00, 14, 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=800&auto=format&fit=crop', '["106mm Planar Magnetic Driver", "CNC Anodized Aluminum Frame", "Detachable Balanced XLR Cable"]'::jsonb, 4.9, 128),
  ('a1111111-1111-1111-1111-111111111111', 'AET-DAC-PRO', 'Aether Zero-Jitter Desktop DAC/Amp', 'Audio', 340.00, 9, 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?q=80&w=800&auto=format&fit=crop', '["Dual ESS Sabre 32-Bit DAC", "32bit/768kHz PCM & DSD512", "OLED Telemetry Display"]'::jsonb, 4.8, 84),
  ('b2222222-2222-2222-2222-222222222222', 'KUR-KBD-75', 'Kuro Monolith 75% Mechanical Keyboard', 'Desk Setup', 285.00, 22, 'https://images.unsplash.com/photo-1595225476474-87563907a212?q=80&w=800&auto=format&fit=crop', '["Gasket Mount CNC 6063 Aluminum", "Hot-Swappable Hall Effect Switches", "QMK / VIA Wireless 2.4GHz"]'::jsonb, 5.0, 215),
  ('b2222222-2222-2222-2222-222222222222', 'KUR-PEN-TI', 'Kuro Grade-5 Titanium Bolt Pen', 'Accessories', 95.00, 41, 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?q=80&w=800&auto=format&fit=crop', '["Zero-Tolerance Machined Titanium", "Schmidt P900 Refill Compatible", "28g Balanced Weight"]'::jsonb, 4.9, 67),
  ('c3333333-3333-3333-3333-333333333333', 'VEL-ESP-V1', 'Veloce Barista PID Pressure Brewer', 'Coffee Gear', 620.00, 7, 'https://images.unsplash.com/photo-1517668808822-9ebb02f2a0e6?q=80&w=800&auto=format&fit=crop', '["Digital PID Temperature Control", "9-Bar Rotary Vane Pump", "Real-Time Flow Profiling"]'::jsonb, 4.95, 92),
  ('c3333333-3333-3333-3333-333333333333', 'VEL-GRN-64', 'Veloce 64mm Flat-Burr Single Dose Grinder', 'Coffee Gear', 390.00, 15, 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?q=80&w=800&auto=format&fit=crop', '["DLC Coated 64mm Flat Burrs", "0.1g Zero-Retention Blowout", "Brushless Variable RPM Motor"]'::jsonb, 4.88, 53),
  ('d4444444-4444-4444-4444-444444444444', 'NOM-BPK-28', 'Nomad 28L Cordura Ballistic Tech Pack', 'Carry & Travel', 245.00, 19, 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?q=80&w=800&auto=format&fit=crop', '["1680D Ballistic Nylon Shell", "YKK AquaGuard Waterproof Zips", "Suspended 16\" MacBook Vault"]'::jsonb, 4.92, 178),
  ('d4444444-4444-4444-4444-444444444444', 'NOM-GAN-140', 'Nomad 140W 4-Port GaN Pro Travel Hub', 'Accessories', 110.00, 34, 'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?q=80&w=800&auto=format&fit=crop', '["PD 3.1 140W Fast Charging", "Dynamic Thermal Load Balancing", "EU/UK/US Modular Plugs"]'::jsonb, 4.85, 109)
ON CONFLICT (sku) DO NOTHING;
