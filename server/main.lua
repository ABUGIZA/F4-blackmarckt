local RESOURCE = GetCurrentResourceName()

math.randomseed(os.time())

local framework = nil
local QBCore = nil

local productsById = {}
local levelsSorted = {}
local purchaseCooldowns = {}

local DB_TABLE = 'f4_blackmarket'
local DB_TYPE_PLAYER = 'player'
local DB_TYPE_HISTORY = 'history'
local DB_TYPE_DELIVERY = 'delivery'

local function debugPrint(...)
    if Config.Debug then
        print(('[%s]'):format(RESOURCE), ...)
    end
end

local function detectFramework()
    if Config.Framework == 'qb' or Config.Framework == 'qbx' then
        return Config.Framework
    end

    if GetResourceState('qbx_core') == 'started' then
        return 'qbx'
    end

    if GetResourceState('qb-core') == 'started' then
        return 'qb'
    end

    return nil
end

local function normalizeBaseUrl(url)
    if type(url) ~= 'string' or url == '' then
        return ''
    end

    if url:sub(-1) ~= '/' then
        return url .. '/'
    end

    return url
end

local function resolveInventoryImageBaseUrl()
    local config = Config.InventoryImages or {}

    local direct = normalizeBaseUrl(config.baseUrl)
    if direct ~= '' then
        return direct
    end

    local frameworkUrl = normalizeBaseUrl(config[framework])
    if frameworkUrl ~= '' then
        return frameworkUrl
    end

    local fallback = normalizeBaseUrl(config.default)
    if fallback ~= '' then
        return fallback
    end

    return ''
end

local function resolveProductImageFile(product)
    local image = product.image
    if type(image) == 'string' and image ~= '' then
        return image
    end

    local item = tostring(product.item or '')
    if item == '' then
        return ''
    end

    if item:find('.', 1, true) then
        return item
    end

    return item .. '.png'
end

local function parseClockToSeconds(value)
    if type(value) ~= 'string' then return nil end

    local hourRaw, minuteRaw = value:match('^(%d%d?):(%d%d?)$')
    local hour = tonumber(hourRaw)
    local minute = tonumber(minuteRaw)

    if not hour or not minute then return nil end
    if hour < 0 or hour > 23 then return nil end
    if minute < 0 or minute > 59 then return nil end

    return hour * 3600 + minute * 60
end

local function isMarketOpen()
    if Config.Market.mode == 'always_open' or not Config.Market.schedule then
        return true
    end

    local startSeconds = parseClockToSeconds(Config.Market.schedule.startTime)
    local endSeconds = parseClockToSeconds(Config.Market.schedule.endTime)

    if not startSeconds or not endSeconds or startSeconds == endSeconds then
        return true
    end

    local now = os.date('*t')
    local nowSeconds = now.hour * 3600 + now.min * 60 + now.sec

    if startSeconds > endSeconds then
        return nowSeconds >= startSeconds or nowSeconds < endSeconds
    end

    return nowSeconds >= startSeconds and nowSeconds < endSeconds
end

local function parseIsoTimestamp(value)
    if type(value) ~= 'string' then return nil end

    local year, month, day, hour, minute, second = value:match('^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)')
    if not year then return nil end

    return os.time({
        year = tonumber(year),
        month = tonumber(month),
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(minute),
        sec = tonumber(second)
    })
end

local function isOfferActive(product)
    if not product.offer or not product.offer.endTimestamp then
        return false
    end

    local offerEnd = parseIsoTimestamp(product.offer.endTimestamp)
    if not offerEnd then
        return false
    end

    return offerEnd > os.time()
end

local function resolveLevelByReputation(reputation)
    local safeReputation = tonumber(reputation) or 0
    local current = levelsSorted[1]

    for i = 1, #levelsSorted do
        local tier = levelsSorted[i]
        if safeReputation >= tier.minReputation then
            current = tier
        end
    end

    return current
end

local function normalizeWholePrice(value)
    local raw = math.max(0, tonumber(value) or 0)
    local normalized = math.floor(raw)

    if raw > 0 and normalized < 1 then
        normalized = 1
    end

    return normalized
end

local function calculateGlobalDiscountAmount(baseTotal, discountPercent)
    local safeTotal = normalizeWholePrice(baseTotal)
    if safeTotal <= 0 then
        return 0
    end

    local safePercent = math.max(0, tonumber(discountPercent) or 0)
    local rawDiscount = safeTotal * (safePercent / 100)

    -- Floor so fractional discounts that don't reach $1 are correctly $0.
    local discount = math.floor(rawDiscount)
    discount = math.min(discount, safeTotal - 1)

    return math.max(0, discount)
end

local function calculateOrderTotal(baseTotal, reputation)
    local tier = resolveLevelByReputation(reputation)
    local safeTotal = normalizeWholePrice(baseTotal)
    if safeTotal <= 0 then
        return 0, 0, tier
    end

    local discountAmount = calculateGlobalDiscountAmount(safeTotal, tier.discountPercent or 0)
    local finalTotal = math.max(0, safeTotal - discountAmount)

    return finalTotal, discountAmount, tier
end

local function getPlayer(source)
    if framework == 'qbx' then
        return exports.qbx_core:GetPlayer(source)
    end

    return QBCore.Functions.GetPlayer(source)
end

local function getCitizenId(player)
    if not player or not player.PlayerData then
        return nil
    end

    return player.PlayerData.citizenid
end

local function getBlackMoney(source)
    local slots = exports.ox_inventory:Search(source, 'slots', Config.BlackMoney.item)
    if not slots then return 0 end

    local total = 0
    for _, slot in ipairs(slots) do
        total = total + (tonumber(slot.metadata and slot.metadata.type) or 0)
    end
    return total
end

local function removeBlackMoney(source, amount)
    local slots = exports.ox_inventory:Search(source, 'slots', Config.BlackMoney.item)
    if not slots then return false end

    local remaining = amount
    for _, slot in ipairs(slots) do
        if remaining <= 0 then break end
        local val = tonumber(slot.metadata and slot.metadata.type) or 0
        if val <= 0 then
            -- skip
        elseif val <= remaining then
            exports.ox_inventory:RemoveItem(source, Config.BlackMoney.item, slot.count, nil, slot.slot)
            remaining = remaining - val
        else
            exports.ox_inventory:SetMetadata(source, slot.slot, { type = val - remaining })
            remaining = 0
        end
    end
    return remaining <= 0
end

local function addBlackMoney(source, amount)
    local slots = exports.ox_inventory:Search(source, 'slots', Config.BlackMoney.item)
    if slots and #slots > 0 then
        local slot = slots[1]
        local current = tonumber(slot.metadata and slot.metadata.type) or 0
        exports.ox_inventory:SetMetadata(source, slot.slot, { type = current + amount })
        return true
    end
    return exports.ox_inventory:AddItem(source, Config.BlackMoney.item, 1, { type = amount }) ~= false
end

local function getMoney(source, account)
    if account == 'black_money' then
        return getBlackMoney(source)
    end

    local player = getPlayer(source)
    if not player or not player.PlayerData or not player.PlayerData.money then
        return 0
    end

    return tonumber(player.PlayerData.money[account]) or 0
end

local function removeMoney(source, account, amount, reason)
    if account == 'black_money' then
        return removeBlackMoney(source, amount)
    end

    local player = getPlayer(source)
    if not player or not player.Functions then
        return false
    end

    return player.Functions.RemoveMoney(account, amount, reason)
end

local function addMoney(source, account, amount, reason)
    if account == 'black_money' then
        return addBlackMoney(source, amount)
    end

    local player = getPlayer(source)
    if not player or not player.Functions then
        return false
    end

    return player.Functions.AddMoney(account, amount, reason)
end

local function isInventoryReady()
    if framework == 'qbx' then
        return GetResourceState('ox_inventory') == 'started'
    end

    if framework == 'qb' then
        return GetResourceState('qb-inventory') == 'started'
    end

    return false
end

local function canCarryItem(source, itemName, amount)
    if framework ~= 'qbx' then
        return true
    end

    if GetResourceState('ox_inventory') ~= 'started' then
        return false, 'ox_inventory_missing'
    end

    if exports.ox_inventory:CanCarryItem(source, itemName, amount) then
        return true
    end

    return false, 'inventory_full'
end

local function addItem(source, itemName, amount, metadata)
    if framework == 'qbx' then
        if GetResourceState('ox_inventory') ~= 'started' then
            return false, 'ox_inventory_missing'
        end

        local added, response = exports.ox_inventory:AddItem(source, itemName, amount, metadata)
        if not added then
            if type(response) == 'string' and response ~= '' then
                return false, response
            end

            return false, 'inventory_full'
        end

        return true
    end

    if framework == 'qb' then
        if GetResourceState('qb-inventory') ~= 'started' then
            return false, 'qb_inventory_missing'
        end

        local player = getPlayer(source)
        if not player then
            return false, 'player_not_found'
        end

        local added = player.Functions.AddItem(itemName, amount, false, metadata or {})
        if not added then
            return false, 'inventory_full'
        end

        if QBCore and QBCore.Shared and QBCore.Shared.Items and QBCore.Shared.Items[itemName] then
            TriggerClientEvent('inventory:client:ItemBox', source, QBCore.Shared.Items[itemName], 'add', amount)
        end

        return true
    end

    return false, 'unsupported_framework'
end

local function takeSmartPayment(source, amount, paymentMethod)
    if paymentMethod == 'black_money' then
        if getMoney(source, 'black_money') >= amount then
            if removeMoney(source, 'black_money', amount, Config.Payment.reason) then
                return true, 'black_money'
            end
        end
        return false, nil
    end

    for i = 1, #Config.Payment.priority do
        local account = Config.Payment.priority[i]
        if getMoney(source, account) >= amount then
            if removeMoney(source, account, amount, Config.Payment.reason) then
                return true, account
            end
        end
    end

    return false, nil
end

local function getOrCreatePlayerProfile(citizenid)
    local profile = MySQL.single.await(
        ('SELECT citizenid, reputation, level FROM %s WHERE record_type = ? AND citizenid = ? ORDER BY id ASC LIMIT 1'):format(DB_TABLE),
        { DB_TYPE_PLAYER, citizenid }
    )

    if not profile then
        local fallback = MySQL.single.await(
            ('SELECT citizenid, reputation, level FROM %s WHERE record_type = ? AND citizenid = ? LIMIT 1'):format(DB_TABLE),
            { DB_TYPE_PLAYER, citizenid }
        )
        profile = fallback
    end

    if profile then
        profile.reputation = tonumber(profile.reputation) or Config.DefaultReputation
        local tier = resolveLevelByReputation(profile.reputation)
        local computedLevel = tonumber(tier.level) or 1
        profile.level = tonumber(profile.level) or computedLevel

        if profile.level ~= computedLevel then
            profile.level = computedLevel
            MySQL.update.await(
                ('UPDATE %s SET level = ? WHERE record_type = ? AND citizenid = ?'):format(DB_TABLE),
                { computedLevel, DB_TYPE_PLAYER, citizenid }
            )
        end

        return profile
    end

    local defaultTier = resolveLevelByReputation(Config.DefaultReputation)
    local defaultLevel = tonumber(defaultTier.level) or 1

    MySQL.insert.await(
        ('INSERT INTO %s (record_type, citizenid, reputation, level) VALUES (?, ?, ?, ?)'):format(DB_TABLE),
        { DB_TYPE_PLAYER, citizenid, Config.DefaultReputation, defaultLevel }
    )

    return {
        citizenid = citizenid,
        reputation = Config.DefaultReputation,
        level = defaultLevel
    }
end

local function setPlayerProgress(citizenid, reputation, level)
    MySQL.update.await(
        ('UPDATE %s SET reputation = ?, level = ? WHERE record_type = ? AND citizenid = ?'):format(DB_TABLE),
        { reputation, level, DB_TYPE_PLAYER, citizenid }
    )
end

local function queueDelivery(citizenid, product, quantity)
    local newItem = {
        itemName    = product.item,
        productId   = product.id,
        quantity    = quantity,
        purchasedAt = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }

    local existing = MySQL.single.await(
        ('SELECT id, metadata FROM %s WHERE record_type = ? AND citizenid = ? LIMIT 1'):format(DB_TABLE),
        { DB_TYPE_DELIVERY, citizenid }
    )

    if existing then
        local items = {}
        if type(existing.metadata) == 'string' and existing.metadata ~= '' then
            local ok, decoded = pcall(json.decode, existing.metadata)
            if ok and type(decoded) == 'table' then
                items = decoded
            end
        end
        items[#items + 1] = newItem
        MySQL.update.await(
            ('UPDATE %s SET metadata = ? WHERE id = ?'):format(DB_TABLE),
            { json.encode(items), existing.id }
        )
        return true
    end

    local insertedId = MySQL.insert.await(
        ('INSERT INTO %s (record_type, citizenid, metadata) VALUES (?, ?, ?)'):format(DB_TABLE),
        { DB_TYPE_DELIVERY, citizenid, json.encode({ newItem }) }
    )

    return insertedId ~= nil
end

local function getPendingDeliveryCount(citizenid)
    local row = MySQL.single.await(
        ('SELECT metadata FROM %s WHERE record_type = ? AND citizenid = ? LIMIT 1'):format(DB_TABLE),
        { DB_TYPE_DELIVERY, citizenid }
    )

    if not row or not row.metadata then return 0 end

    local ok, items = pcall(json.decode, row.metadata)
    if not ok or type(items) ~= 'table' then return 0 end

    return #items
end

local function claimDeliveriesForPlayer(source, citizenid)
    local row = MySQL.single.await(
        ('SELECT id, metadata FROM %s WHERE record_type = ? AND citizenid = ? LIMIT 1'):format(DB_TABLE),
        { DB_TYPE_DELIVERY, citizenid }
    )

    if not row or not row.metadata then
        return 0, 0
    end

    local ok, items = pcall(json.decode, row.metadata)
    if not ok or type(items) ~= 'table' or #items == 0 then
        return 0, 0
    end

    local total = #items
    local claimed = 0
    local lastFailureReason = nil
    local lastFailureItem = nil
    local remaining = {}

    for i = 1, total do
        local item = items[i]
        local itemName = tostring(item.itemName or '')
        local amount = math.max(1, math.floor(tonumber(item.quantity) or 1))

        if itemName ~= '' then
            local carryOk = true
            local carryReason = nil
            if framework == 'qbx' then
                carryOk, carryReason = canCarryItem(source, itemName, amount)
            end

            if carryOk then
                local added, addReason = addItem(source, itemName, amount, {
                    blackmarketProductId = item.productId,
                    purchasedAt = item.purchasedAt
                })
                if added then
                    claimed = claimed + 1
                else
                    lastFailureReason = addReason or 'delivery_add_failed'
                    lastFailureItem = itemName
                    remaining[#remaining + 1] = item
                end
            else
                lastFailureReason = carryReason or 'inventory_full'
                lastFailureItem = itemName
                remaining[#remaining + 1] = item
            end
        end
    end

    if #remaining == 0 then
        MySQL.query.await(
            ('DELETE FROM %s WHERE id = ?'):format(DB_TABLE),
            { row.id }
        )
    else
        MySQL.update.await(
            ('UPDATE %s SET metadata = ? WHERE id = ?'):format(DB_TABLE),
            { json.encode(remaining), row.id }
        )
    end

    return claimed, total, lastFailureReason, lastFailureItem
end

local function generatePurchaseUid(source)
    return ('BM-%d-%d-%06d'):format(os.time(), source, math.random(0, 999999))
end

local function logHistory(source, citizenid, product, quantity, unitPrice, totalPrice, status, paymentAccount, failureReason)
    local uid = generatePurchaseUid(source)

    local newEntry = {
        id             = uid,
        productId      = product.id,
        productName    = product.name,
        categoryId     = product.categoryId,
        rarity         = product.rarity,
        quantity       = quantity,
        pricePaid      = totalPrice,
        status         = status,
        paymentAccount = paymentAccount,
        failureReason  = failureReason,
        purchasedAt    = os.date('!%Y-%m-%dT%H:%M:%SZ')
    }

    local existing = MySQL.single.await(
        ('SELECT id, metadata FROM %s WHERE record_type = ? AND citizenid = ? LIMIT 1'):format(DB_TABLE),
        { DB_TYPE_HISTORY, citizenid }
    )

    if existing then
        local entries = {}
        if type(existing.metadata) == 'string' and existing.metadata ~= '' then
            local ok, decoded = pcall(json.decode, existing.metadata)
            if ok and type(decoded) == 'table' then
                entries = decoded
            end
        end
        table.insert(entries, 1, newEntry)
        while #entries > Config.HistoryLimit do
            table.remove(entries)
        end
        MySQL.update.await(
            ('UPDATE %s SET metadata = ? WHERE id = ?'):format(DB_TABLE),
            { json.encode(entries), existing.id }
        )
    else
        MySQL.insert.await(
            ('INSERT INTO %s (record_type, citizenid, metadata) VALUES (?, ?, ?)'):format(DB_TABLE),
            { DB_TYPE_HISTORY, citizenid, json.encode({ newEntry }) }
        )
    end

    return uid
end

local function getHistoryByCitizenId(citizenid)
    local row = MySQL.single.await(
        ('SELECT metadata FROM %s WHERE record_type = ? AND citizenid = ? LIMIT 1'):format(DB_TABLE),
        { DB_TYPE_HISTORY, citizenid }
    )

    if not row or not row.metadata then
        return {}
    end

    local ok, entries = pcall(json.decode, row.metadata)
    if not ok or type(entries) ~= 'table' then
        return {}
    end

    for i = 1, #entries do
        entries[i].quantity = math.max(1, tonumber(entries[i].quantity) or 1)
        entries[i].pricePaid = math.max(0, tonumber(entries[i].pricePaid) or 0)
        entries[i].status = entries[i].status == 'failed' and 'failed' or 'success'
    end

    return entries
end

local function buildSnapshot(source, citizenid)
    local profile = getOrCreatePlayerProfile(citizenid)
    local tier = resolveLevelByReputation(profile.reputation)
    local bank = getMoney(source, 'bank')
    local cash = getMoney(source, 'cash')
    local blackMoney = getMoney(source, 'black_money')
    local imageBaseUrl = resolveInventoryImageBaseUrl()
    local pendingDeliveries = getPendingDeliveryCount(citizenid)

    local productsForClient = {}
    for i = 1, #Config.Market.products do
        local p = Config.Market.products[i]
        productsForClient[i] = {
            id = p.id,
            name = p.name,
            description = p.description,
            image = resolveProductImageFile(p),
            categoryId = p.categoryId,
            basePrice = p.basePrice,
            requiredLevel = p.requiredLevel,
            reputationGain = p.reputationGain,
            rarity = p.rarity,
            offer = p.offer
        }
    end

    return {
        framework = framework,
        marketOpen = isMarketOpen(),
        imageBaseUrl = imageBaseUrl,
        products = productsForClient,
        categories = Config.Market.categories,
        levels = Config.Market.levels,
        player = {
            citizenid = citizenid,
            reputation = profile.reputation,
            level = profile.level or tier.level,
            discountPercent = tier.discountPercent,
            bank = bank,
            cash = cash,
            black_money = blackMoney,
            balance = bank + cash,
            pendingDeliveries = pendingDeliveries
        },
        history = getHistoryByCitizenId(citizenid)
    }
end

local function failPurchase(source, citizenid, product, quantity, unitPrice, totalPrice, reasonCode, message)
    logHistory(source, citizenid, product, quantity, unitPrice, totalPrice, 'failed', nil, reasonCode)

    return {
        success = false,
        code = reasonCode,
        message = message
    }
end

local function tableExists(tableName)
    local row = MySQL.single.await([[
        SELECT TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = ?
        LIMIT 1
    ]], { tableName })

    return row ~= nil
end

local function ensureDatabaseTables()
    MySQL.query.await(([[ 
        CREATE TABLE IF NOT EXISTS %s (
            id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            record_type VARCHAR(16) NOT NULL,
            citizenid VARCHAR(64) NOT NULL,
            reputation INT NULL,
            level INT NULL,
            purchase_uid VARCHAR(64) NULL,
            product_id VARCHAR(64) NULL,
            product_name VARCHAR(128) NULL,
            category_id VARCHAR(64) NULL,
            rarity VARCHAR(32) NULL,
            item_name VARCHAR(64) NULL,
            quantity INT NOT NULL DEFAULT 1,
            unit_price INT NOT NULL DEFAULT 0,
            price_paid INT NOT NULL DEFAULT 0,
            status VARCHAR(16) NULL,
            payment_account VARCHAR(16) NULL,
            failure_reason VARCHAR(64) NULL,
            metadata JSON NULL,
            purchased_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (id),
            UNIQUE KEY uq_history_purchase_uid (record_type, purchase_uid),
            KEY idx_record_type_citizenid (record_type, citizenid),
            KEY idx_record_type_purchased_at (record_type, purchased_at),
            KEY idx_record_type_created_at (record_type, created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]):format(DB_TABLE))

    if tableExists('f4_blackmarket_players') then
        MySQL.query.await(([[
            INSERT INTO %s (
                record_type,
                citizenid,
                reputation,
                level,
                created_at,
                updated_at
            )
            SELECT
                ?,
                p.citizenid,
                p.reputation,
                p.level,
                p.created_at,
                p.updated_at
            FROM f4_blackmarket_players p
            WHERE NOT EXISTS (
                SELECT 1
                FROM %s n
                WHERE n.record_type = ?
                  AND n.citizenid = p.citizenid
            )
        ]]):format(DB_TABLE, DB_TABLE), { DB_TYPE_PLAYER, DB_TYPE_PLAYER })

        MySQL.query.await('DROP TABLE IF EXISTS f4_blackmarket_players')
    end

    if tableExists('f4_blackmarket_history') then
        MySQL.query.await(([[
            INSERT INTO %s (
                record_type,
                purchase_uid,
                citizenid,
                product_id,
                product_name,
                category_id,
                rarity,
                quantity,
                unit_price,
                price_paid,
                status,
                payment_account,
                failure_reason,
                purchased_at,
                created_at,
                updated_at
            )
            SELECT
                ?,
                h.purchase_uid,
                h.citizenid,
                h.product_id,
                h.product_name,
                h.category_id,
                h.rarity,
                h.quantity,
                h.unit_price,
                h.price_paid,
                h.status,
                h.payment_account,
                h.failure_reason,
                h.purchased_at,
                h.purchased_at,
                h.purchased_at
            FROM f4_blackmarket_history h
            WHERE NOT EXISTS (
                SELECT 1
                FROM %s n
                WHERE n.record_type = ?
                  AND n.purchase_uid = h.purchase_uid
            )
        ]]):format(DB_TABLE, DB_TABLE), { DB_TYPE_HISTORY, DB_TYPE_HISTORY })

        MySQL.query.await('DROP TABLE IF EXISTS f4_blackmarket_history')
    end

    if tableExists('f4_blackmarket_deliveries') then
        MySQL.query.await(([[
            INSERT INTO %s (
                record_type,
                citizenid,
                product_id,
                item_name,
                quantity,
                metadata,
                created_at,
                updated_at
            )
            SELECT
                ?,
                d.citizenid,
                d.product_id,
                d.item_name,
                d.quantity,
                d.metadata,
                d.created_at,
                d.created_at
            FROM f4_blackmarket_deliveries d
            WHERE NOT EXISTS (
                SELECT 1
                FROM %s n
                WHERE n.record_type = ?
                  AND n.citizenid = d.citizenid
                  AND n.product_id = d.product_id
                  AND n.item_name = d.item_name
                  AND n.quantity = d.quantity
                  AND n.created_at = d.created_at
            )
        ]]):format(DB_TABLE, DB_TABLE), { DB_TYPE_DELIVERY, DB_TYPE_DELIVERY })

        MySQL.query.await('DROP TABLE IF EXISTS f4_blackmarket_deliveries')
    end

    -- Migrate old delivery rows (one row per item) → single JSON row per player
    local oldDeliveries = MySQL.query.await(
        ('SELECT id, citizenid, item_name, quantity, product_id, metadata FROM %s WHERE record_type = ? AND item_name IS NOT NULL AND item_name != ? ORDER BY citizenid, id ASC'):format(DB_TABLE),
        { DB_TYPE_DELIVERY, '' }
    ) or {}

    if #oldDeliveries > 0 then
        local byPlayer = {}
        for _, r in ipairs(oldDeliveries) do
            local cid = r.citizenid
            if not byPlayer[cid] then byPlayer[cid] = {} end
            local existingMeta = {}
            if type(r.metadata) == 'string' and r.metadata ~= '' then
                local mok, mdec = pcall(json.decode, r.metadata)
                if mok and type(mdec) == 'table' then existingMeta = mdec end
            end
            byPlayer[cid][#byPlayer[cid] + 1] = {
                id = r.id,
                item = {
                    itemName    = tostring(r.item_name or ''),
                    productId   = tostring(r.product_id or ''),
                    quantity    = math.max(1, tonumber(r.quantity) or 1),
                    purchasedAt = existingMeta.purchasedAt or os.date('!%Y-%m-%dT%H:%M:%SZ')
                }
            }
        end
        for cid, rows in pairs(byPlayer) do
            local newRow = MySQL.single.await(
                ('SELECT id, metadata FROM %s WHERE record_type = ? AND citizenid = ? AND (item_name IS NULL OR item_name = ?) LIMIT 1'):format(DB_TABLE),
                { DB_TYPE_DELIVERY, cid, '' }
            )
            local items = {}
            if newRow then
                local nok, ndec = pcall(json.decode, newRow.metadata or '')
                if nok and type(ndec) == 'table' then items = ndec end
            end
            for _, r in ipairs(rows) do
                items[#items + 1] = r.item
                MySQL.query.await(('DELETE FROM %s WHERE id = ?'):format(DB_TABLE), { r.id })
            end
            if newRow then
                MySQL.update.await(('UPDATE %s SET metadata = ? WHERE id = ?'):format(DB_TABLE), { json.encode(items), newRow.id })
            else
                MySQL.insert.await(('INSERT INTO %s (record_type, citizenid, metadata) VALUES (?, ?, ?)'):format(DB_TABLE), { DB_TYPE_DELIVERY, cid, json.encode(items) })
            end
        end
        print(('[%s] Migrated old delivery rows to JSON format.'):format(RESOURCE))
    end

    -- Migrate old history rows (one row per purchase) → single JSON row per player
    local oldHistory = MySQL.query.await(
        ('SELECT id, citizenid, purchase_uid, product_id, product_name, category_id, rarity, quantity, price_paid, status, payment_account, failure_reason, purchased_at FROM %s WHERE record_type = ? AND purchase_uid IS NOT NULL ORDER BY citizenid, purchased_at DESC'):format(DB_TABLE),
        { DB_TYPE_HISTORY }
    ) or {}

    if #oldHistory > 0 then
        local byPlayer = {}
        for _, r in ipairs(oldHistory) do
            local cid = r.citizenid
            if not byPlayer[cid] then byPlayer[cid] = {} end
            local pat = tostring(r.purchased_at or ''):gsub('^(%d+%-%d+%-%d+) (%d+:%d+:%d+).*$', '%1T%2Z')
            byPlayer[cid][#byPlayer[cid] + 1] = {
                id = r.id,
                entry = {
                    id             = tostring(r.purchase_uid or ''),
                    productId      = tostring(r.product_id or ''),
                    productName    = tostring(r.product_name or ''),
                    categoryId     = tostring(r.category_id or ''),
                    rarity         = tostring(r.rarity or ''),
                    quantity       = math.max(1, tonumber(r.quantity) or 1),
                    pricePaid      = math.max(0, tonumber(r.price_paid) or 0),
                    status         = r.status == 'failed' and 'failed' or 'success',
                    paymentAccount = r.payment_account,
                    failureReason  = r.failure_reason,
                    purchasedAt    = pat
                }
            }
        end
        for cid, rows in pairs(byPlayer) do
            local entries = {}
            for _, r in ipairs(rows) do
                entries[#entries + 1] = r.entry
                MySQL.query.await(('DELETE FROM %s WHERE id = ?'):format(DB_TABLE), { r.id })
            end
            while #entries > Config.HistoryLimit do table.remove(entries) end
            MySQL.insert.await(('INSERT INTO %s (record_type, citizenid, metadata) VALUES (?, ?, ?)'):format(DB_TABLE), { DB_TYPE_HISTORY, cid, json.encode(entries) })
        end
        print(('[%s] Migrated old history rows to JSON format.'):format(RESOURCE))
    end

    local players = MySQL.query.await(
        ('SELECT citizenid, reputation, level FROM %s WHERE record_type = ?'):format(DB_TABLE),
        { DB_TYPE_PLAYER }
    )

    if players then
        for i = 1, #players do
            local row = players[i]
            local tier = resolveLevelByReputation(tonumber(row.reputation) or Config.DefaultReputation)
            local computedLevel = tonumber(tier.level) or 1
            local storedLevel = tonumber(row.level) or 0

            if storedLevel ~= computedLevel then
                MySQL.update.await(
                    ('UPDATE %s SET level = ? WHERE record_type = ? AND citizenid = ?'):format(DB_TABLE),
                    { computedLevel, DB_TYPE_PLAYER, row.citizenid }
                )
            end
        end
    end
end

local function initializeResource()
    framework = detectFramework()

    if not framework then
        error(('[%s] No supported framework found. Start qbx_core or qb-core.'):format(RESOURCE))
    end

    if framework == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
    end

    for i = 1, #Config.Market.products do
        local product = Config.Market.products[i]
        productsById[product.id] = product
    end

    for i = 1, #Config.Market.levels do
        levelsSorted[i] = Config.Market.levels[i]
    end

    table.sort(levelsSorted, function(a, b)
        return a.level < b.level
    end)
end

initializeResource()

CreateThread(function()
    ensureDatabaseTables()

    if not isInventoryReady() then
        print(('[%s] Inventory backend is missing for framework %s.'):format(RESOURCE, framework))
    end

    print(('[%s] Loaded with framework: %s'):format(RESOURCE, framework))
end)

lib.callback.register('f4:blackmarket:server:getOpenData', function(source)
    if not source or source < 1 then return end
    local player = getPlayer(source)
    if not player then
        return {
            success = false,
            message = 'Player is not loaded yet.'
        }
    end

    local citizenid = getCitizenId(player)
    if not citizenid then
        return {
            success = false,
            message = 'Citizen identifier is missing.'
        }
    end

    return {
        success = true,
        data = buildSnapshot(source, citizenid)
    }
end)

lib.callback.register('f4:blackmarket:server:purchase', function(source, payload)
    if not source or source < 1 then return end

    -- Rate limiting: 2 second cooldown per player
    local now = os.clock()
    if purchaseCooldowns[source] and (now - purchaseCooldowns[source]) < 2 then
        return {
            success = false,
            message = 'Please wait before making another purchase.'
        }
    end
    purchaseCooldowns[source] = now

    local player = getPlayer(source)
    if not player then
        return {
            success = false,
            message = 'Player is not loaded yet.'
        }
    end

    local citizenid = getCitizenId(player)
    if not citizenid then
        return {
            success = false,
            message = 'Citizen identifier is missing.'
        }
    end

    if type(payload) ~= 'table' or type(payload.productId) ~= 'string' then
        return {
            success = false,
            message = 'Invalid purchase request.'
        }
    end

    local product = productsById[payload.productId]
    if not product then
        return {
            success = false,
            message = 'Selected product is invalid.'
        }
    end

    local quantity = math.floor(tonumber(payload.quantity) or 1)
    quantity = math.max(1, math.min(quantity, 10))

    local profile = getOrCreatePlayerProfile(citizenid)
    local baseUnitPrice = normalizeWholePrice(product.basePrice)
    local baseTotalPrice = baseUnitPrice * quantity
    local totalPrice, _, tier = calculateOrderTotal(baseTotalPrice, profile.reputation)
    local unitPrice = baseUnitPrice

    if not isMarketOpen() then
        return failPurchase(
            source,
            citizenid,
            product,
            quantity,
            unitPrice,
            totalPrice,
            'market_closed',
            'Market is currently closed.'
        )
    end

    if (tonumber(product.requiredLevel) or 0) > (tonumber(tier.level) or 0) then
        return failPurchase(
            source,
            citizenid,
            product,
            quantity,
            unitPrice,
            totalPrice,
            'level_required',
            ('Required level is %d.'):format(product.requiredLevel)
        )
    end

    local paymentMethod = type(payload.paymentMethod) == 'string' and payload.paymentMethod or nil
    local paymentOk, paymentAccount = takeSmartPayment(source, totalPrice, paymentMethod)
    if not paymentOk or not paymentAccount then
        local fundsMsg = paymentMethod == 'black_money' and 'Insufficient black money.' or 'Insufficient funds in bank and cash.'
        return failPurchase(
            source,
            citizenid,
            product,
            quantity,
            unitPrice,
            totalPrice,
            'insufficient_funds',
            fundsMsg
        )
    end

    local queued = queueDelivery(citizenid, product, quantity)
    if not queued then
        addMoney(source, paymentAccount, totalPrice, Config.Payment.refundReason)

        return failPurchase(
            source,
            citizenid,
            product,
            quantity,
            unitPrice,
            totalPrice,
            'delivery_queue_failed',
            'Could not queue your delivery package. Payment refunded.'
        )
    end

    local reputationGain = (tonumber(product.reputationGain) or 0) * quantity
    local newReputation = math.max(0, (tonumber(profile.reputation) or 0) + reputationGain)
    local newTier = resolveLevelByReputation(newReputation)
    local newLevel = tonumber(newTier.level) or 1

    setPlayerProgress(citizenid, newReputation, newLevel)

    logHistory(
        source,
        citizenid,
        product,
        quantity,
        unitPrice,
        totalPrice,
        'success',
        paymentAccount,
        nil
    )

    local snapshot = buildSnapshot(source, citizenid)

    return {
        success = true,
        paymentAccount = paymentAccount,
        message = ('Purchased %dx %s for $%d. Pick it up from the delivery operator.'):format(quantity, product.name, totalPrice),
        data = snapshot
    }
end)

lib.callback.register('f4:blackmarket:server:batchPurchase', function(source, payload)
    if not source or source < 1 then return end

    -- Rate limiting: 2 second cooldown per player
    local now = os.clock()
    if purchaseCooldowns[source] and (now - purchaseCooldowns[source]) < 2 then
        return {
            success = false,
            message = 'Please wait before making another purchase.'
        }
    end
    purchaseCooldowns[source] = now

    local player = getPlayer(source)
    if not player then
        return { success = false, message = 'Player is not loaded yet.' }
    end

    local citizenid = getCitizenId(player)
    if not citizenid then
        return { success = false, message = 'Citizen identifier is missing.' }
    end

    if type(payload) ~= 'table' or type(payload.items) ~= 'table' or #payload.items == 0 then
        return { success = false, message = 'Invalid batch purchase request.' }
    end

    if #payload.items > 20 then
        return { success = false, message = 'Too many items in a single purchase.' }
    end

    if not isMarketOpen() then
        return { success = false, message = 'Market is currently closed.' }
    end

    local profile = getOrCreatePlayerProfile(citizenid)
    local tier = resolveLevelByReputation(profile.reputation)

    -- Phase 1: Validate all items and compute grand base total
    local resolvedItems = {}
    local grandBaseTotal = 0

    for i = 1, #payload.items do
        local entry = payload.items[i]

        if type(entry) ~= 'table' or type(entry.productId) ~= 'string' then
            return { success = false, message = 'Invalid item in cart.' }
        end

        local product = productsById[entry.productId]
        if not product then
            return { success = false, message = ('Unknown product: %s'):format(entry.productId) }
        end

        local quantity = math.floor(tonumber(entry.quantity) or 1)
        quantity = math.max(1, math.min(quantity, 10))

        if (tonumber(product.requiredLevel) or 0) > (tonumber(tier.level) or 0) then
            return { success = false, message = ('Item "%s" requires a higher level.'):format(product.name) }
        end

        local baseUnitPrice = normalizeWholePrice(product.basePrice)
        local baseItemTotal = baseUnitPrice * quantity

        resolvedItems[#resolvedItems + 1] = {
            product = product,
            quantity = quantity,
            unitPrice = baseUnitPrice,
            baseItemTotal = baseItemTotal,
            paidTotal = 0
        }

        grandBaseTotal = grandBaseTotal + baseItemTotal
    end

    local grandDiscount = calculateGlobalDiscountAmount(grandBaseTotal, tier.discountPercent or 0)
    local grandTotal = math.max(0, grandBaseTotal - grandDiscount)

    -- Split the paid total across items proportionally for history + refunds.
    if grandBaseTotal > 0 then
        local remainingPaid = grandTotal
        for i = 1, #resolvedItems do
            local item = resolvedItems[i]
            local paidAmount = 0

            if i == #resolvedItems then
                paidAmount = remainingPaid
            else
                paidAmount = math.floor((item.baseItemTotal / grandBaseTotal) * grandTotal)
                paidAmount = math.max(0, math.min(paidAmount, remainingPaid))
            end

            item.paidTotal = paidAmount
            remainingPaid = remainingPaid - paidAmount
        end
    end

    -- Phase 2: Take payment for grand total at once
    local paymentMethod = type(payload.paymentMethod) == 'string' and payload.paymentMethod or nil
    local paymentOk, paymentAccount = takeSmartPayment(source, grandTotal, paymentMethod)
    if not paymentOk or not paymentAccount then
        local fundsMsg = paymentMethod == 'black_money' and 'Insufficient black money.' or 'Insufficient funds in bank and cash.'
        return { success = false, message = fundsMsg }
    end

    -- Phase 3: Queue all deliveries and log history
    local totalQuantity = 0
    local totalReputationGain = 0

    for i = 1, #resolvedItems do
        local item = resolvedItems[i]

        local queued = queueDelivery(citizenid, item.product, item.quantity)
        if not queued then
            -- Refund the remaining amount for failed deliveries
            local refundAmount = 0
            for j = i, #resolvedItems do
                refundAmount = refundAmount + resolvedItems[j].paidTotal
            end
            addMoney(source, paymentAccount, refundAmount, Config.Payment.refundReason)

            -- Log the failed items
            for j = i, #resolvedItems do
                logHistory(source, citizenid, resolvedItems[j].product, resolvedItems[j].quantity,
                    resolvedItems[j].unitPrice, resolvedItems[j].paidTotal, 'failed', nil, 'delivery_queue_failed')
            end

            -- Log the successful items up to this point
            return {
                success = false,
                message = ('Delivery failed for "%s". Remaining funds refunded.'):format(item.product.name),
                data = buildSnapshot(source, citizenid)
            }
        end

        logHistory(source, citizenid, item.product, item.quantity,
            item.unitPrice, item.paidTotal, 'success', paymentAccount, nil)

        totalQuantity = totalQuantity + item.quantity
        totalReputationGain = totalReputationGain + ((tonumber(item.product.reputationGain) or 0) * item.quantity)
    end

    -- Phase 4: Update reputation
    local newReputation = math.max(0, (tonumber(profile.reputation) or 0) + totalReputationGain)
    local newTier = resolveLevelByReputation(newReputation)
    local newLevel = tonumber(newTier.level) or 1

    setPlayerProgress(citizenid, newReputation, newLevel)

    return {
        success = true,
        message = ('Purchased %d item(s) for $%d. Pick them up from the delivery operator.'):format(totalQuantity, grandTotal),
        data = buildSnapshot(source, citizenid)
    }
end)

lib.callback.register('f4:blackmarket:server:claimDeliveries', function(source)
    if not source or source < 1 then return end
    local player = getPlayer(source)
    if not player then
        return {
            success = false,
            code = 'player_missing',
            message = 'Player is not loaded yet.'
        }
    end

    local citizenid = getCitizenId(player)
    if not citizenid then
        return {
            success = false,
            code = 'citizenid_missing',
            message = 'Citizen identifier is missing.'
        }
    end

    local claimed, total, failureReason, failureItem = claimDeliveriesForPlayer(source, citizenid)
    local remaining = math.max(0, total - claimed)
    local snapshot = buildSnapshot(source, citizenid)

    if total == 0 then
        return {
            success = false,
            code = 'no_pending',
            message = 'No delivery packages are waiting for you.',
            claimed = 0,
            total = 0,
            remaining = 0,
            data = snapshot
        }
    end

    if claimed == 0 then
        local errorCode = failureReason or 'delivery_failed'
        local message = 'Could not complete the delivery.'

        if errorCode == 'inventory_full' then
            message = 'Inventory is full. Free some space and try again.'
        elseif errorCode == 'invalid_item' or errorCode == 'item_not_found' then
            message = ('Delivery item "%s" is not registered in inventory items.'):format(failureItem or 'unknown')
        elseif errorCode == 'ox_inventory_missing' then
            message = 'ox_inventory is not started on the server.'
        elseif errorCode == 'qb_inventory_missing' then
            message = 'qb-inventory is not started on the server.'
        elseif errorCode == 'unsupported_framework' then
            message = 'Current framework does not support item delivery.'
        elseif errorCode == 'player_not_found' then
            message = 'Player was not found while delivering items.'
        end

        return {
            success = false,
            code = errorCode,
            message = message,
            claimed = 0,
            total = total,
            remaining = remaining,
            data = snapshot
        }
    end

    if remaining > 0 then
        return {
            success = true,
            code = 'partial',
            message = ('Received %d package(s). %d package(s) still pending.'):format(claimed, remaining),
            claimed = claimed,
            total = total,
            remaining = remaining,
            data = snapshot
        }
    end

    return {
        success = true,
        code = 'success',
        message = ('Received %d delivery package(s).'):format(claimed),
        claimed = claimed,
        total = total,
        remaining = 0,
        data = snapshot
    }
end)
