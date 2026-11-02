import { create } from 'zustand';
import { persist } from 'zustand/middleware';

/**
 * NexusCart Multi-Vendor Cart State Engine
 * Handles persistent multi-tenant line items and automated Stripe Connect split calculations.
 */
export const useCartStore = create(
  persist(
    (set, get) => ({
      items: [],
      currency: 'USD',

      setCurrency: (currency) => set({ currency }),

      addItem: (product, qty = 1) => {
        if (!product || (product.stock !== undefined && product.stock <= 0)) {
          return false;
        }

        const items = get().items;
        const existingIndex = items.findIndex((i) => i.productId === product.id);

        if (existingIndex > -1) {
          const updatedQty = items[existingIndex].qty + qty;
          const maxStock = product.stock ?? 999;
          const safeQty = Math.min(updatedQty, maxStock);

          set({
            items: items.map((i, idx) =>
              idx === existingIndex ? { ...i, qty: safeQty } : i
            ),
          });
        } else {
          set({
            items: [...items, { productId: product.id, qty, product }],
          });
        }
        return true;
      },

      updateQty: (productId, delta) => {
        const items = get().items;
        const updated = items
          .map((item) => {
            if (item.productId !== productId) return item;
            const newQty = item.qty + delta;
            const maxStock = item.product?.stock ?? 999;
            if (newQty <= 0) return null;
            return { ...item, qty: Math.min(newQty, maxStock) };
          })
          .filter(Boolean);

        set({ items: updated });
      },

      removeItem: (productId) => {
        set({ items: get().items.filter((i) => i.productId !== productId) });
      },

      clearCart: () => set({ items: [] }),

      // Stripe Connect Split Payout Computations
      getCartCalculations: (platformFeePct = 0.025) => {
        const items = get().items;
        const subtotal = items.reduce(
          (sum, i) => sum + (i.product?.priceUsd || 0) * i.qty,
          0
        );
        const platformFee = subtotal * platformFeePct;

        // Group splits by vendor
        const splits = {};
        items.forEach((item) => {
          const v = item.product?.vendor || {
            id: item.product?.vendorId || 'unknown_vendor',
            name: item.product?.vendorName || 'Independent Merchant',
            stripeAccountId: item.product?.stripeAccountId || 'acct_default',
          };

          if (!splits[v.id]) {
            splits[v.id] = {
              vendorId: v.id,
              vendorName: v.name,
              stripeAccountId: v.stripeAccountId,
              grossAmount: 0,
              netPayout: 0,
            };
          }

          const lineTotal = (item.product?.priceUsd || 0) * item.qty;
          splits[v.id].grossAmount += lineTotal;
          splits[v.id].netPayout += lineTotal * (1 - platformFeePct);
        });

        return {
          totalCount: items.reduce((sum, i) => sum + i.qty, 0),
          subtotal,
          platformFee,
          vendorSplits: Object.values(splits),
        };
      },
    }),
    {
      name: 'nexuscart-storage',
      version: 2,
    }
  )
);
