Config = {}

Config.Framework = 'auto' -- auto | qb | qbx
Config.Debug = false

Config.Npc = {
    model = 'g_m_y_mexgoon_03',
    coords = vec4(-1084.1096, -559.6824, 38.1141, 294.8736),
    scenario = 'WORLD_HUMAN_DRUG_DEALER'
}

Config.DeliveryNpc = {
    model = 's_m_m_dockwork_01',
    coords = vec4(-1125.4557, -552.0229, 32.4840, 305.1259),
    drawDistance = 15.0,
    openDistance = 2.0,
    carryBoxModel = 'hei_prop_heist_box',
    carryBoxBone = 57005
}

Config.DrawDistance = 15.0
Config.OpenDistance = 2.0
Config.InteractKey = 38 -- E

Config.HistoryLimit = 200
Config.DefaultReputation = 0

Config.InventoryImages = {
    -- Set baseUrl if you want a fixed image source for all frameworks.
    baseUrl = '',
    default = 'https://cfx-nui-ox_inventory/web/images/',
    qb = 'https://cfx-nui-qb-inventory/html/images/',
    qbx = 'https://cfx-nui-ox_inventory/web/images/'
}

Config.Payment = {
    priority = { 'bank', 'cash', 'black_money' },
    reason = 'blackmarket-purchase',
    refundReason = 'blackmarket-refund'
}

Config.BlackMoney = {
    item = 'black_money', -- Item name in ox_inventory
}

Config.Market = {
    mode = 'always_open', -- always_open | scheduled
    schedule = {
        startTime = '19:00',
        endTime = '03:00'
    },

    levels = {
        { level = 0, minReputation = 0, discountPercent = 0 },
        { level = 1, minReputation = 150, discountPercent = 0 },
        { level = 2, minReputation = 350, discountPercent = 5 },
        { level = 3, minReputation = 650, discountPercent = 5 },
        { level = 4, minReputation = 1000, discountPercent = 10 },
        { level = 5, minReputation = 1500, discountPercent = 10 },
        { level = 6, minReputation = 2100, discountPercent = 15 },
        { level = 7, minReputation = 2800, discountPercent = 15 },
        { level = 8, minReputation = 3600, discountPercent = 20 },
        { level = 9, minReputation = 4500, discountPercent = 20 },
        { level = 10, minReputation = 5500, discountPercent = 25 }
    },


    categories = {
        { id = 'explosives', name = 'Explosives', icon = 'bomb', order = 1 },
        { id = 'tools', name = 'Tools', icon = 'wrench', order = 2 },
        { id = 'electronics', name = 'Electronics', icon = 'chip', order = 3 },
        { id = 'vehicle', name = 'Vehicle', icon = 'car', order = 4 },
        { id = 'contraband', name = 'Contraband', icon = 'box', order = 5 },
        { id = 'gear', name = 'Gear', icon = 'shield', order = 6 },
    },

    products = {
        {
            id = 'thermite_charge',
            item = 'thermite',
            name = 'Thermite Charge',
            description = 'High-heat entry charge for armored access points.',
            categoryId = 'explosives',
            basePrice = 1,
            requiredLevel = 1,
            reputationGain = 32,
            rarity = 'epic',
            offer = {
                discountPercentage = 10,
                endTimestamp = '2027-01-01T00:00:00.000Z'
            }
        },
        {
            id = 'basic_lockpick',
            item = 'lockpick',
            name = 'Basic Lockpick',
            description = 'Quick bypass for low-security mechanical locks.',
            categoryId = 'tools',
            basePrice = 2,
            requiredLevel = 0,
            reputationGain = 10,
            rarity = 'common'
        },
        {
            id = 'advanced_lockpick',
            item = 'advancedlockpick',
            name = 'Advanced Lockpick',
            description = 'Precision pick with higher success on advanced locks.',
            categoryId = 'tools',
            basePrice = 3,
            requiredLevel = 2,
            reputationGain = 45,
            rarity = 'rare'
        },
        {
            id = 'electronics_kit',
            item = 'electronickit',
            name = 'Electronics Kit',
            description = 'Module pack for signal and terminal manipulation.',
            categoryId = 'electronics',
            basePrice = 4,
            requiredLevel = 1,
            reputationGain = 54,
            rarity = 'uncommon',
            offer = {
                discountPercentage = 12,
                endTimestamp = '2027-01-01T00:00:00.000Z'
            }
        },
        {
            id = 'nitrous_bottle',
            item = 'nitrous',
            name = 'Nitrous Bottle',
            description = 'Instant speed burst for tuned engines.',
            categoryId = 'vehicle',
            basePrice = 5,
            requiredLevel = 3,
            reputationGain = 62,
            rarity = 'epic'
        },
        {
            id = 'tuner_chip',
            item = 'tunerchip',
            name = 'Tuner Chip',
            description = 'ECU module for advanced tuning profiles.',
            categoryId = 'vehicle',
            basePrice = 2,
            requiredLevel = 2,
            reputationGain = 49,
            rarity = 'rare'
        },
        {
            id = 'weed_brick',
            item = 'weed_brick',
            name = 'Weed Brick',
            description = 'Compressed stock unit for distribution.',
            categoryId = 'contraband',
            basePrice = 1,
            requiredLevel = 1,
            reputationGain = 34,
            rarity = 'uncommon'
        },
        {
            id = 'meth_tray',
            item = 'meth_tray',
            name = 'Meth Tray',
            description = 'Prepared tray with high-purity chemical base.',
            categoryId = 'contraband',
            basePrice = 2,
            requiredLevel = 3,
            reputationGain = 67,
            rarity = 'rare'
        },
        {
            id = 'coke_brick',
            item = 'coke_brick',
            name = 'Coke Brick',
            description = 'Packed high-value brick for premium clients.',
            categoryId = 'contraband',
            basePrice = 3,
            requiredLevel = 4,
            reputationGain = 81,
            rarity = 'legendary',
            offer = {
                discountPercentage = 15,
                endTimestamp = '2027-01-01T00:00:00.000Z'
            }
        },
        {
            id = 'advanced_kit',
            item = 'advancedkit',
            name = 'Advanced Kit',
            description = 'Universal tactical package for premium operations.',
            categoryId = 'gear',
            basePrice = 2,
            requiredLevel = 2,
            reputationGain = 44,
            rarity = 'common'
        },
        {
            id = 'encrypted_laptop',
            item = 'laptop',
            name = 'Encrypted Laptop',
            description = 'Pre-loaded with stealth channels and encrypted tools.',
            categoryId = 'electronics',
            basePrice = 3,
            requiredLevel = 2,
            reputationGain = 69,
            rarity = 'rare'
        },
        {
            id = 'industrial_drill',
            item = 'drill',
            name = 'Industrial Drill',
            description = 'Heavy-duty drill optimized for vault entry points.',
            categoryId = 'tools',
            basePrice = 2,
            requiredLevel = 1,
            reputationGain = 40,
            rarity = 'uncommon'
        }
    }
}
