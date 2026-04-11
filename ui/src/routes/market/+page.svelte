<script lang="ts">
  import { onMount } from "svelte";
  import { MarketHeader } from "$lib/components/layout";
  import {
    MarketSearchBar,
    MarketSidebar,
    ProductGrid,
    CartView,
  } from "$lib/components/market";
  import type { ProductGridItem } from "$lib/components/market";
  import { ProductModal } from "$lib/components/modals";
  import { NotificationStack } from "$lib/components/ui";
  import { HistoryView } from "$lib/components/history";
  import type { SelectOption } from "$lib/components/ui";
  import { isFiveM, onNuiMessage, postNui } from "$lib/fivem/nui";
  import {
    activeProductId,
    activeCategoryId,
    calculateDiscountedTotal,
    calculateFinalPrice,
    calculateGlobalDiscountAmount,
    categories,
    cart,
    cartCount,
    clearNotifications,
    clockTimestamp,
    closeProduct,
    dismissNotification,
    filteredProducts,
    getCategoryName,
    getOfferSecondsRemaining,
    isNuiVisible,
    isOfferActive,
    marketStatus,
    marketTitle,
    notifications,
    openProduct,
    pushNotification,
    searchQuery,
    selectCategory,
    serverProducts,
    setHistoryEntries,
    setNuiVisible,
    sortBy,
    startMarketClock,
    stopMarketClock,
    syncLevelsFromServer,
    syncMarketDataFromServer,
    syncUserStateFromServer,
    userState,
  } from "$lib/stores";

  interface ServerPlayerSnapshot {
    reputation: number;
    balance?: number;
    bank?: number;
    cash?: number;
  }

  interface ServerHistoryEntry {
    id: string;
    productId: string;
    productName: string;
    categoryId: string;
    rarity: "common" | "uncommon" | "rare" | "epic" | "legendary";
    quantity: number;
    pricePaid: number;
    status: "success" | "failed";
    purchasedAt: string;
  }

  interface ServerMarketSnapshot {
    imageBaseUrl?: string;
    player?: ServerPlayerSnapshot;
    history?: ServerHistoryEntry[];
    products?: Array<{
      id: string;
      name: string;
      description: string;
      image: string;
      categoryId: string;
      basePrice: number;
      requiredLevel: number;
      reputationGain: number;
      rarity: "common" | "uncommon" | "rare" | "epic" | "legendary";
      offer?: { discountPercentage: number; endTimestamp: string };
    }>;
    categories?: Array<{
      id: string;
      name: string;
      icon: string;
      order: number;
    }>;
    levels?: Array<{
      level: number;
      minReputation: number;
      discountPercent: number;
    }>;
  }

  interface PurchaseResponse {
    success: boolean;
    message?: string;
    paymentAccount?: string;
    data?: ServerMarketSnapshot;
  }

  const sortOptions: SelectOption[] = [
    { label: "Featured", value: "featured" },
    { label: "Price: Low to High", value: "price_asc" },
    { label: "Price: High to Low", value: "price_desc" },
    { label: "Required Level", value: "level_asc" },
  ];

  const isLocked = (requiredLevel: number, currentLevel: number) =>
    requiredLevel > currentLevel;

  let previousMarketOpen = $state<boolean | null>(null);
  let view = $state<"market" | "history" | "cart">("market");
  let isCheckingOut = $state(false);

  const expiredOfferNotified = new Set<string>();

  const applyServerSnapshot = (snapshot?: ServerMarketSnapshot) => {
    if (!snapshot) return;

    // Sync market data (products, categories) from server
    syncMarketDataFromServer(snapshot);

    // Sync levels
    if (snapshot.levels) {
      syncLevelsFromServer(snapshot.levels);
    }

    if (snapshot.player) {
      syncUserStateFromServer(snapshot.player);
    }

    if (Array.isArray(snapshot.history)) {
      setHistoryEntries(
        snapshot.history.map((entry) => ({
          id: entry.id,
          productId: entry.productId,
          productName: entry.productName,
          categoryId: entry.categoryId,
          rarity: entry.rarity,
          quantity: Math.max(1, Math.trunc(entry.quantity ?? 1)),
          pricePaid: Math.max(0, Math.trunc(entry.pricePaid ?? 0)),
          status: entry.status,
          purchasedAt: entry.purchasedAt,
        })),
      );
    }
  };

  const handleNuiMessage = (payload: Record<string, unknown>) => {
    const action = typeof payload.action === "string" ? payload.action : "";
    const data = (payload.payload ?? undefined) as ServerMarketSnapshot | undefined;

    if (action === "f4:blackmarket:open") {
      clearNotifications();
      applyServerSnapshot(data);
      closeProduct();
      view = "market";
      setNuiVisible(true);
      return;
    }

    if (action === "f4:blackmarket:sync") {
      applyServerSnapshot(data);
      setNuiVisible(true);
      return;
    }

    if (action === "f4:blackmarket:close") {
      closeProduct();
      view = "market";
      setNuiVisible(false);
    }
  };

  const closeNui = async () => {
    closeProduct();
    view = "market";
    setNuiVisible(false);
    await postNui("f4:blackmarket:close");
  };

  const gridItems = $derived.by((): ProductGridItem[] =>
    $filteredProducts.map((product) => ({
      offerSecondsRemaining: getOfferSecondsRemaining(product, $clockTimestamp),
      id: product.id,
      name: product.name,
      description: product.description,
      image: product.image,
      categoryName: getCategoryName(product.categoryId),
      requiredLevel: product.requiredLevel,
      offerPercentage: isOfferActive(product, $clockTimestamp)
        ? product.offer?.discountPercentage
        : undefined,
      locked: isLocked(product.requiredLevel, $userState.currentLevel),
      rarity: product.rarity,
      finalPrice: product.basePrice,
    })),
  );

  const selectedProduct = $derived.by(() =>
    $activeProductId
      ? ($serverProducts.find(
          (product) => product.id === $activeProductId,
        ) ?? null)
      : null,
  );

  const selectedFinalPrice = $derived.by(() =>
    selectedProduct
      ? calculateFinalPrice(
          selectedProduct,
          $userState.discountPercent,
          $clockTimestamp,
        )
      : 0,
  );

  const selectedOfferSecondsRemaining = $derived.by(() =>
    selectedProduct
      ? getOfferSecondsRemaining(selectedProduct, $clockTimestamp)
      : null,
  );

  const handleOpenProduct = (productId: string) => {
    if (!$marketStatus.isOpen) return;
    openProduct(productId);
  };

  const handleCloseProduct = () => {
    closeProduct();
  };

  const handleBuySelectedProduct = async (paymentMethod: 'normal' | 'black_money' = 'normal') => {
    if (!selectedProduct) return;

    const product = selectedProduct;

    if (isLocked(product.requiredLevel, $userState.currentLevel)) {
      pushNotification(
        "purchase_fail",
        `Required level for ${product.name} was not reached.`,
      );
      return;
    }

    const response = await postNui<PurchaseResponse>("f4:blackmarket:purchase", {
      productId: product.id,
      quantity: 1,
      paymentMethod,
    });

    if (!response) {
      pushNotification(
        "purchase_fail",
        "Could not contact the server. Please try again.",
      );
      return;
    }

    if (!response.success) {
      pushNotification(
        "purchase_fail",
        response.message ?? `Transaction failed while buying ${product.name}.`,
      );
      return;
    }

    applyServerSnapshot(response.data);

    pushNotification(
      "purchase_success",
      response.message ?? `Purchased ${product.name} successfully.`,
    );

    closeProduct();
  };

  const handleAddToCart = (productId: string) => {
    const product = $serverProducts.find((p) => p.id === productId);
    if (!product || !$marketStatus.isOpen) return;

    if (isLocked(product.requiredLevel, $userState.currentLevel)) {
      pushNotification(
        "purchase_fail",
        `Required level for ${product.name} was not reached.`,
      );
      return;
    }

    cart.addItem(product, product.basePrice);

    pushNotification(
      "cart_add",
      `Added ${product.name} to your delivery cart.`,
    );
  };

  const handleCheckoutCart = async (paymentMethod: 'normal' | 'black_money' = 'normal') => {
    if (isCheckingOut || $cart.length === 0) return;

    // Pre-check: one global modifier on full base total (no double discounting)
    const cartItems = [...$cart];
    const cartBaseTotal = cartItems.reduce(
      (total, item) => total + item.product.basePrice * item.quantity,
      0,
    );
    const discountAmount = calculateGlobalDiscountAmount(
      cartBaseTotal,
      $userState.discountPercent,
    );
    const grandTotal = calculateDiscountedTotal(
      cartBaseTotal,
      $userState.discountPercent,
    );

    const availableBalance = paymentMethod === 'black_money' ? $userState.blackMoney : $userState.balance;
    const balanceLabel = paymentMethod === 'black_money' ? 'black money' : 'funds';

    if (availableBalance < grandTotal) {
      pushNotification(
        "purchase_fail",
        `Insufficient ${balanceLabel}. Total is $${grandTotal.toLocaleString()} (base $${cartBaseTotal.toLocaleString()} - discount $${discountAmount.toLocaleString()}). You only have $${availableBalance.toLocaleString()}.`,
      );
      return;
    }

    isCheckingOut = true;

    try {
      const payloadItems = cartItems.map((item) => ({
        productId: item.product.id,
        quantity: Math.max(1, Math.min(10, Math.trunc(item.quantity || 1))),
      }));

      const response = await postNui<PurchaseResponse>(
        "f4:blackmarket:batchPurchase",
        { items: payloadItems, paymentMethod },
      );

      if (!response) {
        pushNotification(
          "purchase_fail",
          "Could not contact the server for checkout.",
        );
        return;
      }

      applyServerSnapshot(response.data);

      if (!response.success) {
        pushNotification(
          "purchase_fail",
          response.message ?? "Batch transaction failed.",
        );
        return;
      }

      const purchasedItems = payloadItems.reduce(
        (total, item) => total + item.quantity,
        0,
      );

      cart.clearCart();
      view = "market";

      pushNotification(
        "purchase_success",
        response.message ??
          `Purchase complete! ${purchasedItems} item(s) were added to your inventory.`,
      );
    } finally {
      isCheckingOut = false;
    }
  };

  $effect(() => {
    if (previousMarketOpen === null) {
      previousMarketOpen = $marketStatus.isOpen;
      return;
    }

    if (previousMarketOpen && !$marketStatus.isOpen) {
      closeProduct();
      pushNotification(
        "market_closed",
        "Market closed. Purchases are locked until the next opening window.",
      );
    }

    previousMarketOpen = $marketStatus.isOpen;
  });

  $effect(() => {
    for (const product of $serverProducts) {
      if (!product.offer) continue;

      const remainingSeconds = getOfferSecondsRemaining(
        product,
        $clockTimestamp,
      );
      if (remainingSeconds !== 0) continue;
      if (expiredOfferNotified.has(product.id)) continue;

      expiredOfferNotified.add(product.id);
      pushNotification("offer_expired", `Offer expired for ${product.name}.`);
    }
  });

  onMount(() => {
    startMarketClock();

    const disposeNuiMessage = onNuiMessage(handleNuiMessage);
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key !== "Escape") return;
      if ($activeProductId) return;
      if (!$isNuiVisible) return;
      closeNui();
    };

    window.addEventListener("keydown", handleKeyDown);

    if (isFiveM()) {
      postNui("f4:blackmarket:ready");
    } else {
      setNuiVisible(true);
    }

    return () => {
      window.removeEventListener("keydown", handleKeyDown);
      disposeNuiMessage();
      stopMarketClock();
    };
  });
</script>

<section class="market-screen">
  <div class="market-frame">
    <MarketSidebar
      categories={$categories}
      activeCategoryId={$activeCategoryId || "all"}
      onSelect={(catId) => {
        view = "market";
        selectCategory(catId);
      }}
      onShowHistory={() => {
        view = "history";
      }}
    />

    <div class="market-content">
      <div class="content-panel">
        {#if view === "market"}
          <MarketHeader
            title={$marketTitle}
            level={$userState.currentLevel}
            discountPercent={$userState.discountPercent}
            balance={$userState.balance}
            blackMoney={$userState.blackMoney}
            progressRatio={$userState.progress.progressRatio}
            cartItemCount={$cartCount}
            onToggleCart={() => (view = "cart")}
          />

          <MarketSearchBar
            bind:search={$searchQuery}
            bind:sortBy={$sortBy}
            {sortOptions}
          />

          <ProductGrid
            items={gridItems}
            marketOpen={$marketStatus.isOpen}
            onOpen={handleOpenProduct}
            onAddToCart={handleAddToCart}
          />
        {:else if view === "history"}
          <HistoryView onBack={() => (view = "market")} />
        {:else if view === "cart"}
          <CartView
            onBack={() => (view = "market")}
            onCheckout={handleCheckoutCart}
            isCheckingOut={isCheckingOut}
          />
        {/if}
      </div>
    </div>
  </div>
</section>

<ProductModal
  open={Boolean(selectedProduct)}
  product={selectedProduct}
  finalPrice={selectedFinalPrice}
  reputationDiscountPercent={$userState.discountPercent}
  userLevel={$userState.currentLevel}
  userBalance={$userState.balance}
  userBlackMoney={$userState.blackMoney}
  marketOpen={$marketStatus.isOpen}
  offerSecondsRemaining={selectedOfferSecondsRemaining}
  onClose={handleCloseProduct}
  onBuy={handleBuySelectedProduct}
  onAddToCart={handleAddToCart}
/>

<NotificationStack items={$notifications} onDismiss={dismissNotification} />

<style>
  .market-screen {
    height: 100%; /* Fill the fixed height of .app-modal */
    width: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    overflow: hidden; /* Prevent body scroll */
  }

  .market-frame {
    width: 100%;
    height: 100%;
    display: grid;
    grid-template-columns: 260px minmax(0, 1fr);
    border-radius: 4px;
    background: #0d0f0e;
    border: 1px solid var(--line-soft);
    overflow: hidden;
    position: relative;
  }

  .market-content {
    padding: 0.95rem;
    height: 100%;
    overflow-y: auto; /* Internal scroll only */
  }

  .content-panel {
    display: grid;
    gap: 0.8rem;
    animation: panel-in 180ms ease;
  }

  @keyframes panel-in {
    from {
      opacity: 0;
      transform: translateY(5px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  @media (max-width: 900px) {
    .market-frame {
      grid-template-columns: 1fr;
      min-height: calc(100dvh - 3.2rem);
    }
  }
</style>
