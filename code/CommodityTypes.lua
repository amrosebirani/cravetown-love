--
-- CommodityTypes - defines all resource/commodity types in the game
--

CommodityTypes = {}

local function createCommodity(config)
    return {
        id = config.id,
        name = config.name,
        category = config.category,
        icon = config.icon or "?",
        stackSize = config.stackSize or 1000,
        baseValue = config.baseValue or 1,
        perishable = config.perishable or false,
        description = config.description or "",
        isRaw = config.isRaw or false,  -- Raw resources have no dependencies
        dependencies = config.dependencies or {}  -- Array of commodity IDs this depends on (raw materials)
    }
end

-- ==================== GRAINS (RAW) ====================
CommodityTypes.WHEAT = createCommodity({
    id = "wheat", name = "Wheat", category = "grain",
    icon = "Wt", stackSize = 5000, baseValue = 1,
    isRaw = true,
    description = "Basic grain crop - grown on farms"
})

CommodityTypes.MAIZE = createCommodity({
    id = "maize", name = "Maize", category = "grain",
    icon = "Mz", stackSize = 5000, baseValue = 1,
    isRaw = true,
    description = "Corn grain - grown on farms"
})

CommodityTypes.RICE = createCommodity({
    id = "rice", name = "Rice", category = "grain",
    icon = "Rc", stackSize = 5000, baseValue = 2,
    isRaw = true,
    description = "Staple grain - grown on farms"
})

CommodityTypes.BARLEY = createCommodity({
    id = "barley", name = "Barley", category = "grain",
    icon = "Ba", stackSize = 4000, baseValue = 1,
    isRaw = true,
    description = "Brewing grain - grown on farms"
})

CommodityTypes.OATS = createCommodity({
    id = "oats", name = "Oats", category = "grain",
    icon = "Oa", stackSize = 4000, baseValue = 1,
    isRaw = true,
    description = "Hearty grain - grown on farms"
})

CommodityTypes.RYE = createCommodity({
    id = "rye", name = "Rye", category = "grain",
    icon = "Ry", stackSize = 4000, baseValue = 1,
    isRaw = true,
    description = "Hardy grain - grown on farms"
})

-- ==================== FRUITS ====================
CommodityTypes.APPLE = createCommodity({
    id = "apple", name = "Apple", category = "fruit",
    icon = "Ap", stackSize = 1000, baseValue = 3,
    isRaw = true,
    perishable = true, description = "Crisp fruit"
})

CommodityTypes.MANGO = createCommodity({
    id = "mango", name = "Mango", category = "fruit",
    icon = "Mn", stackSize = 800, baseValue = 5,
    isRaw = true,
    perishable = true, description = "Tropical fruit"
})

CommodityTypes.ORANGE = createCommodity({
    id = "orange", name = "Orange", category = "fruit",
    icon = "Or", stackSize = 1000, baseValue = 4,
    isRaw = true,
    perishable = true, description = "Citrus fruit"
})

CommodityTypes.GRAPES = createCommodity({
    id = "grapes", name = "Grapes", category = "fruit",
    icon = "Gr", stackSize = 1200, baseValue = 6,
    isRaw = true,
    perishable = true, description = "Wine grapes"
})

CommodityTypes.BERRIES = createCommodity({
    id = "berries", name = "Berries", category = "fruit",
    icon = "Br", stackSize = 800, baseValue = 8,
    isRaw = true,
    perishable = true, description = "Mixed berries"
})

CommodityTypes.PEACH = createCommodity({
    id = "peach", name = "Peach", category = "fruit",
    icon = "Pc", stackSize = 600, baseValue = 5,
    isRaw = true,
    perishable = true, description = "Stone fruit"
})

CommodityTypes.PEAR = createCommodity({
    id = "pear", name = "Pear", category = "fruit",
    icon = "Pr", stackSize = 800, baseValue = 4,
    isRaw = true,
    perishable = true, description = "Sweet fruit"
})

-- ==================== VEGETABLES ====================
CommodityTypes.POTATO = createCommodity({
    id = "potato", name = "Potato", category = "vegetable",
    icon = "Po", stackSize = 3000, baseValue = 1,
    isRaw = true,
    description = "Root vegetable"
})

CommodityTypes.CARROT = createCommodity({
    id = "carrot", name = "Carrot", category = "vegetable",
    icon = "Ca", stackSize = 2000, baseValue = 2,
    isRaw = true,
    description = "Orange root"
})

CommodityTypes.ONION = createCommodity({
    id = "onion", name = "Onion", category = "vegetable",
    icon = "On", stackSize = 2000, baseValue = 2,
    isRaw = true,
    description = "Aromatic bulb"
})

CommodityTypes.CABBAGE = createCommodity({
    id = "cabbage", name = "Cabbage", category = "vegetable",
    icon = "Cb", stackSize = 1500, baseValue = 2,
    isRaw = true,
    perishable = true, description = "Leafy vegetable"
})

CommodityTypes.TOMATO = createCommodity({
    id = "tomato", name = "Tomato", category = "vegetable",
    icon = "To", stackSize = 1000, baseValue = 3,
    isRaw = true,
    perishable = true, description = "Red vegetable"
})

CommodityTypes.LETTUCE = createCommodity({
    id = "lettuce", name = "Lettuce", category = "vegetable",
    icon = "Le", stackSize = 800, baseValue = 2,
    isRaw = true,
    perishable = true, description = "Salad greens"
})

CommodityTypes.BEANS = createCommodity({
    id = "beans", name = "Beans", category = "vegetable",
    icon = "Bn", stackSize = 3000, baseValue = 2,
    isRaw = true,
    description = "Legumes"
})

CommodityTypes.PUMPKIN = createCommodity({
    id = "pumpkin", name = "Pumpkin", category = "vegetable",
    icon = "Pm", stackSize = 500, baseValue = 4,
    isRaw = true,
    description = "Large squash"
})

-- ==================== PLANTS & FLOWERS ====================
CommodityTypes.FLOWERS = createCommodity({
    id = "flowers", name = "Flowers", category = "plant",
    icon = "Fw", stackSize = 1000, baseValue = 6,
    isRaw = true,
    perishable = true, description = "Colorful blooms for dyes and perfume"
})

CommodityTypes.INDIGO = createCommodity({
    id = "indigo", name = "Indigo Plant", category = "plant",
    icon = "In", stackSize = 1200, baseValue = 8,
    isRaw = true,
    description = "Blue dye plant"
})

CommodityTypes.SUGAR_CANE = createCommodity({
    id = "sugar_cane", name = "Sugar Cane", category = "plant",
    icon = "SC", stackSize = 2000, baseValue = 3,
    isRaw = true,
    description = "Sweet plant for sugar production"
})

-- ==================== ANIMAL PRODUCTS ====================
CommodityTypes.WOOL = createCommodity({
    id = "wool", name = "Wool", category = "animal_product",
    icon = "Wo", stackSize = 1000, baseValue = 5,
    isRaw = true,
    description = "Sheep fiber"
})

CommodityTypes.MILK = createCommodity({
    id = "milk", name = "Milk", category = "animal_product",
    icon = "Mi", stackSize = 500, baseValue = 3,
    perishable = true, isRaw = true,
    description = "Fresh dairy"
})

CommodityTypes.EGGS = createCommodity({
    id = "eggs", name = "Eggs", category = "animal_product",
    icon = "Eg", stackSize = 600, baseValue = 4,
    perishable = true, isRaw = true,
    description = "Chicken eggs"
})

CommodityTypes.MEAT = createCommodity({
    id = "meat", name = "Meat", category = "animal_product",
    icon = "Mt", stackSize = 500, baseValue = 8,
    perishable = true, isRaw = true,
    description = "Animal protein"
})

CommodityTypes.LEATHER = createCommodity({
    id = "leather", name = "Leather", category = "animal_product",
    icon = "Le", stackSize = 400, baseValue = 15,
    isRaw = true,
    description = "Tanned hide"
})

CommodityTypes.CHEESE = createCommodity({
    id = "cheese", name = "Cheese", category = "animal_product",
    icon = "Ch", stackSize = 300, baseValue = 12,
    dependencies = {"milk"},
    description = "Aged dairy"
})

CommodityTypes.BUTTER = createCommodity({
    id = "butter", name = "Butter", category = "animal_product",
    icon = "Bu", stackSize = 400, baseValue = 10,
    dependencies = {"milk"},
    perishable = true, description = "Dairy fat"
})

-- ==================== PROCESSED FOOD ====================
CommodityTypes.BREAD = createCommodity({
    id = "bread", name = "Bread", category = "processed_food",
    icon = "Bd", stackSize = 1000, baseValue = 5,
    dependencies = {"wheat"},
    perishable = true, description = "Baked wheat"
})

CommodityTypes.FLOUR = createCommodity({
    id = "flour", name = "Flour", category = "processed_food",
    icon = "Fl", stackSize = 2000, baseValue = 2,
    dependencies = {"wheat"},
    description = "Ground grain"
})

CommodityTypes.SUGAR = createCommodity({
    id = "sugar", name = "Sugar", category = "processed_food",
    icon = "Su", stackSize = 2000, baseValue = 10,
    dependencies = {"sugar_cane"},
    description = "Refined sweetener"
})

CommodityTypes.HONEY = createCommodity({
    id = "honey", name = "Honey", category = "processed_food",
    icon = "Ho", stackSize = 500, baseValue = 15,
    isRaw = true,
    description = "Bee product"
})

CommodityTypes.WINE = createCommodity({
    id = "wine", name = "Wine", category = "processed_food",
    icon = "Wn", stackSize = 300, baseValue = 25,
    dependencies = {"grapes"},
    description = "Fermented grapes"
})

CommodityTypes.BEER = createCommodity({
    id = "beer", name = "Beer", category = "processed_food",
    icon = "Be", stackSize = 500, baseValue = 8,
    dependencies = {"barley"},
    description = "Brewed barley"
})

CommodityTypes.PASTRIES = createCommodity({
    id = "pastries", name = "Pastries", category = "processed_food",
    icon = "Pa", stackSize = 400, baseValue = 12,
    dependencies = {"wheat"},
    perishable = true, description = "Baked sweets"
})

CommodityTypes.PRESERVED_FOOD = createCommodity({
    id = "preserved_food", name = "Preserved Food", category = "processed_food",
    icon = "PF", stackSize = 800, baseValue = 10,
    description = "Canned goods"
})

-- ==================== DYES & INK ====================
CommodityTypes.RED_DYE = createCommodity({
    id = "red_dye", name = "Red Dye", category = "dye",
    icon = "RD", stackSize = 500, baseValue = 12,
    dependencies = {"berries"},
    description = "Red coloring from berries"
})

CommodityTypes.BLUE_DYE = createCommodity({
    id = "blue_dye", name = "Blue Dye", category = "dye",
    icon = "BD", stackSize = 500, baseValue = 15,
    dependencies = {"indigo"},
    description = "Blue coloring from indigo"
})

CommodityTypes.YELLOW_DYE = createCommodity({
    id = "yellow_dye", name = "Yellow Dye", category = "dye",
    icon = "YD", stackSize = 500, baseValue = 14,
    dependencies = {"flowers"},
    description = "Yellow coloring from flowers"
})

CommodityTypes.BLACK_DYE = createCommodity({
    id = "black_dye", name = "Black Dye", category = "dye",
    icon = "BkD", stackSize = 500, baseValue = 10,
    dependencies = {"charcoal"},
    description = "Black coloring from charcoal"
})

CommodityTypes.PAPER = createCommodity({
    id = "paper", name = "Paper", category = "crafting",
    icon = "Pp", stackSize = 1000, baseValue = 8,
    dependencies = {"wood"},
    description = "Writing material from pulp"
})

-- ==================== TEXTILES ====================
CommodityTypes.COTTON = createCommodity({
    id = "cotton", name = "Cotton", category = "textile_raw",
    icon = "Ct", stackSize = 2000, baseValue = 3,
    isRaw = true,
    description = "Plant fiber"
})

CommodityTypes.FLAX = createCommodity({
    id = "flax", name = "Flax", category = "textile_raw",
    icon = "Fx", stackSize = 1500, baseValue = 4,
    isRaw = true,
    description = "Linen source"
})

CommodityTypes.THREAD = createCommodity({
    id = "thread", name = "Thread", category = "textile",
    icon = "Th", stackSize = 3000, baseValue = 4,
    dependencies = {"cotton"},
    description = "Spun fiber"
})

CommodityTypes.CLOTH = createCommodity({
    id = "cloth", name = "Cloth", category = "textile",
    icon = "Cl", stackSize = 1000, baseValue = 15,
    dependencies = {"cotton", "thread"},
    description = "Woven fabric"
})

CommodityTypes.LINEN = createCommodity({
    id = "linen", name = "Linen", category = "textile",
    icon = "Li", stackSize = 500, baseValue = 20,
    dependencies = {"flax"},
    description = "Fine fabric"
})

CommodityTypes.SILK = createCommodity({
    id = "silk", name = "Silk", category = "textile",
    icon = "Si", stackSize = 200, baseValue = 100,
    isRaw = true,
    description = "Luxury fabric from silkworms"
})

-- ==================== CLOTHES ====================
CommodityTypes.SIMPLE_CLOTHES = createCommodity({
    id = "simple_clothes", name = "Simple Clothes", category = "clothing",
    icon = "SC", stackSize = 300, baseValue = 25,
    dependencies = {"cloth", "thread"},
    description = "Basic garments"
})

CommodityTypes.WORK_CLOTHES = createCommodity({
    id = "work_clothes", name = "Work Clothes", category = "clothing",
    icon = "WC", stackSize = 250, baseValue = 35,
    dependencies = {"cloth", "thread"},
    description = "Durable workwear"
})

CommodityTypes.FINE_CLOTHES = createCommodity({
    id = "fine_clothes", name = "Fine Clothes", category = "clothing",
    icon = "FC", stackSize = 150, baseValue = 80,
    dependencies = {"linen", "thread"},
    description = "Quality garments"
})

CommodityTypes.LUXURY_CLOTHES = createCommodity({
    id = "luxury_clothes", name = "Luxury Clothes", category = "clothing",
    icon = "LC", stackSize = 50, baseValue = 200,
    dependencies = {"silk", "thread"},
    description = "Silk garments"
})

CommodityTypes.WINTER_COAT = createCommodity({
    id = "winter_coat", name = "Winter Coat", category = "clothing",
    icon = "WCo", stackSize = 100, baseValue = 120,
    dependencies = {"wool", "thread"},
    description = "Warm outerwear"
})

CommodityTypes.SHOES = createCommodity({
    id = "shoes", name = "Shoes", category = "clothing",
    icon = "Sh", stackSize = 200, baseValue = 40,
    dependencies = {"leather", "thread"},
    description = "Leather footwear"
})

CommodityTypes.BOOTS = createCommodity({
    id = "boots", name = "Boots", category = "clothing",
    icon = "Bo", stackSize = 150, baseValue = 60,
    dependencies = {"leather", "thread"},
    description = "Work boots"
})

CommodityTypes.HAT = createCommodity({
    id = "hat", name = "Hat", category = "clothing",
    icon = "Ha", stackSize = 300, baseValue = 15,
    dependencies = {"cloth", "thread"},
    description = "Head covering"
})

-- ==================== TOOLS ====================
CommodityTypes.AXE = createCommodity({
    id = "axe", name = "Axe", category = "tools",
    icon = "Ax", stackSize = 200, baseValue = 40,
    dependencies = {"ore", "wood"},
    description = "Chopping tool"
})

CommodityTypes.HAMMER = createCommodity({
    id = "hammer", name = "Hammer", category = "tools",
    icon = "Hm", stackSize = 300, baseValue = 30,
    dependencies = {"ore", "wood"},
    description = "Striking tool"
})

CommodityTypes.SAW = createCommodity({
    id = "saw", name = "Saw", category = "tools",
    icon = "Sa", stackSize = 200, baseValue = 45,
    dependencies = {"ore", "wood"},
    description = "Cutting tool"
})

CommodityTypes.PICKAXE = createCommodity({
    id = "pickaxe", name = "Pickaxe", category = "tools",
    icon = "Pk", stackSize = 200, baseValue = 50,
    dependencies = {"ore", "wood"},
    description = "Mining tool"
})

CommodityTypes.SHOVEL = createCommodity({
    id = "shovel", name = "Shovel", category = "tools",
    icon = "Sv", stackSize = 250, baseValue = 35,
    dependencies = {"ore", "wood"},
    description = "Digging tool"
})

CommodityTypes.HOE = createCommodity({
    id = "hoe", name = "Hoe", category = "tools",
    icon = "Ho", stackSize = 250, baseValue = 30,
    dependencies = {"ore", "wood"},
    description = "Farming tool"
})

CommodityTypes.SCYTHE = createCommodity({
    id = "scythe", name = "Scythe", category = "tools",
    icon = "Sc", stackSize = 150, baseValue = 55,
    dependencies = {"ore", "wood"},
    description = "Harvesting tool"
})

CommodityTypes.CHISEL = createCommodity({
    id = "chisel", name = "Chisel", category = "tools",
    icon = "Ch", stackSize = 300, baseValue = 25,
    dependencies = {"ore", "wood"},
    description = "Carving tool"
})

CommodityTypes.NEEDLE = createCommodity({
    id = "needle", name = "Needle", category = "tools",
    icon = "Ne", stackSize = 500, baseValue = 5,
    dependencies = {"ore"},
    description = "Sewing tool"
})

-- ==================== FURNITURE ====================
CommodityTypes.CHAIR = createCommodity({
    id = "chair", name = "Chair", category = "furniture",
    icon = "Ch", stackSize = 50, baseValue = 40,
    dependencies = {"wood", "nails"},
    description = "Seating furniture"
})

CommodityTypes.TABLE = createCommodity({
    id = "table", name = "Table", category = "furniture",
    icon = "Tb", stackSize = 30, baseValue = 80,
    dependencies = {"wood", "nails"},
    description = "Dining furniture"
})

CommodityTypes.BED = createCommodity({
    id = "bed", name = "Bed", category = "furniture",
    icon = "Bd", stackSize = 20, baseValue = 150,
    dependencies = {"wood", "cloth", "nails"},
    description = "Sleeping furniture"
})

CommodityTypes.CABINET = createCommodity({
    id = "cabinet", name = "Cabinet", category = "furniture",
    icon = "Cb", stackSize = 30, baseValue = 100,
    dependencies = {"wood", "nails"},
    description = "Storage furniture"
})

CommodityTypes.WARDROBE = createCommodity({
    id = "wardrobe", name = "Wardrobe", category = "furniture",
    icon = "Wd", stackSize = 20, baseValue = 180,
    dependencies = {"wood", "nails"},
    description = "Clothing storage"
})

CommodityTypes.BENCH = createCommodity({
    id = "bench", name = "Bench", category = "furniture",
    icon = "Bn", stackSize = 40, baseValue = 50,
    dependencies = {"wood", "nails"},
    description = "Long seat"
})

CommodityTypes.BOOKSHELF = createCommodity({
    id = "bookshelf", name = "Bookshelf", category = "furniture",
    icon = "Bs", stackSize = 25, baseValue = 120,
    dependencies = {"wood", "nails"},
    description = "Book storage"
})

CommodityTypes.DESK = createCommodity({
    id = "desk", name = "Desk", category = "furniture",
    icon = "Ds", stackSize = 25, baseValue = 90,
    dependencies = {"wood", "nails"},
    description = "Work surface"
})

-- ==================== MINERALS & RAW MATERIALS ====================
CommodityTypes.COAL = createCommodity({
    id = "coal", name = "Coal", category = "fuel",
    icon = "Co", stackSize = 10000, baseValue = 3,
    isRaw = true,
    description = "Combustible mineral"
})

CommodityTypes.ORE = createCommodity({
    id = "ore", name = "Iron Ore", category = "raw_mineral",
    icon = "Or", stackSize = 8000, baseValue = 5,
    isRaw = true,
    description = "Raw metal ore"
})

CommodityTypes.COPPER_ORE = createCommodity({
    id = "copper_ore", name = "Copper Ore", category = "raw_mineral",
    icon = "Cu", stackSize = 6000, baseValue = 6,
    isRaw = true,
    description = "Copper bearing ore"
})

CommodityTypes.GOLD_ORE = createCommodity({
    id = "gold_ore", name = "Gold Ore", category = "raw_mineral",
    icon = "Au", stackSize = 1000, baseValue = 50,
    isRaw = true,
    description = "Precious metal ore"
})

CommodityTypes.SILVER_ORE = createCommodity({
    id = "silver_ore", name = "Silver Ore", category = "raw_mineral",
    icon = "Ag", stackSize = 2000, baseValue = 30,
    isRaw = true,
    description = "Valuable metal ore"
})

CommodityTypes.STONE = createCommodity({
    id = "stone", name = "Stone", category = "raw_mineral",
    icon = "St", stackSize = 10000, baseValue = 1,
    isRaw = true,
    description = "Building stone"
})

CommodityTypes.MARBLE = createCommodity({
    id = "marble", name = "Marble", category = "raw_mineral",
    icon = "Ma", stackSize = 3000, baseValue = 20,
    isRaw = true,
    description = "Decorative stone"
})

CommodityTypes.CLAY = createCommodity({
    id = "clay", name = "Clay", category = "raw_mineral",
    icon = "Cy", stackSize = 5000, baseValue = 2,
    isRaw = true,
    description = "Moldable earth"
})

CommodityTypes.SAND = createCommodity({
    id = "sand", name = "Sand", category = "raw_mineral",
    icon = "Sd", stackSize = 8000, baseValue = 1,
    isRaw = true,
    description = "Glass material"
})

-- ==================== REFINED MATERIALS ====================
CommodityTypes.IRON = createCommodity({
    id = "iron", name = "Iron", category = "refined_metal",
    icon = "Fe", stackSize = 5000, baseValue = 15,
    dependencies = {"ore"},
    description = "Refined metal"
})

CommodityTypes.STEEL = createCommodity({
    id = "steel", name = "Steel", category = "refined_metal",
    icon = "St", stackSize = 3000, baseValue = 35,
    dependencies = {"ore", "coal"},
    description = "Strong alloy"
})

CommodityTypes.COPPER = createCommodity({
    id = "copper", name = "Copper", category = "refined_metal",
    icon = "Cu", stackSize = 4000, baseValue = 18,
    dependencies = {"copper_ore"},
    description = "Refined copper"
})

CommodityTypes.BRONZE = createCommodity({
    id = "bronze", name = "Bronze", category = "refined_metal",
    icon = "Br", stackSize = 3000, baseValue = 25,
    dependencies = {"copper_ore"},
    description = "Copper alloy"
})

CommodityTypes.GOLD = createCommodity({
    id = "gold", name = "Gold", category = "refined_metal",
    icon = "Au", stackSize = 500, baseValue = 150,
    dependencies = {"gold_ore"},
    description = "Precious metal"
})

CommodityTypes.SILVER = createCommodity({
    id = "silver", name = "Silver", category = "refined_metal",
    icon = "Ag", stackSize = 1000, baseValue = 80,
    dependencies = {"silver_ore"},
    description = "Valuable metal"
})

-- ==================== CONSTRUCTION MATERIALS ====================
CommodityTypes.BRICKS = createCommodity({
    id = "bricks", name = "Bricks", category = "construction",
    icon = "Bk", stackSize = 5000, baseValue = 5,
    dependencies = {"clay"},
    description = "Fired clay blocks"
})

CommodityTypes.TIMBER = createCommodity({
    id = "timber", name = "Timber", category = "construction",
    icon = "Ti", stackSize = 2000, baseValue = 8,
    isRaw = true,
    description = "Cut logs"
})

CommodityTypes.PLANKS = createCommodity({
    id = "planks", name = "Planks", category = "construction",
    icon = "Pl", stackSize = 1000, baseValue = 15,
    dependencies = {"timber"},
    description = "Processed wood"
})

CommodityTypes.CEMENT = createCommodity({
    id = "cement", name = "Cement", category = "construction",
    icon = "Ce", stackSize = 4000, baseValue = 10,
    dependencies = {"stone"},
    description = "Binding material"
})

CommodityTypes.GLASS = createCommodity({
    id = "glass", name = "Glass", category = "construction",
    icon = "Gl", stackSize = 500, baseValue = 25,
    dependencies = {"sand"},
    description = "Transparent material"
})

CommodityTypes.NAILS = createCommodity({
    id = "nails", name = "Nails", category = "construction",
    icon = "Na", stackSize = 2000, baseValue = 8,
    dependencies = {"ore"},
    description = "Fasteners"
})

-- ==================== LUXURY & MISC ====================
CommodityTypes.POTTERY = createCommodity({
    id = "pottery", name = "Pottery", category = "luxury",
    icon = "Po", stackSize = 300, baseValue = 25,
    dependencies = {"clay"},
    description = "Ceramic vessels"
})

CommodityTypes.JEWELRY = createCommodity({
    id = "jewelry", name = "Jewelry", category = "luxury",
    icon = "Jw", stackSize = 100, baseValue = 200,
    dependencies = {"gold_ore", "silver_ore"},
    description = "Decorative items"
})

CommodityTypes.PERFUME = createCommodity({
    id = "perfume", name = "Perfume", category = "luxury",
    icon = "Pf", stackSize = 200, baseValue = 80,
    dependencies = {"flowers"},
    description = "Fragrant liquid"
})

CommodityTypes.PAINTING = createCommodity({
    id = "painting", name = "Painting", category = "luxury",
    icon = "Pa", stackSize = 50, baseValue = 300,
    dependencies = {"cloth", "red_dye", "blue_dye", "yellow_dye"},
    description = "Art piece"
})

CommodityTypes.SCULPTURE = createCommodity({
    id = "sculpture", name = "Sculpture", category = "luxury",
    icon = "Sc", stackSize = 30, baseValue = 400,
    dependencies = {"marble", "ore"},
    description = "Stone art carved with metal tools"
})

CommodityTypes.BOOK = createCommodity({
    id = "book", name = "Book", category = "luxury",
    icon = "Bk", stackSize = 200, baseValue = 60,
    dependencies = {"paper", "black_dye"},
    description = "Written work"
})

CommodityTypes.CANDLE = createCommodity({
    id = "candle", name = "Candle", category = "misc",
    icon = "Ca", stackSize = 1000, baseValue = 5,
    dependencies = {"honey"},
    description = "Light source made from beeswax"
})

CommodityTypes.LAMP_OIL = createCommodity({
    id = "lamp_oil", name = "Lamp Oil", category = "misc",
    icon = "LO", stackSize = 800, baseValue = 8,
    dependencies = {"oil"},
    description = "Fuel for lamps"
})

CommodityTypes.SOAP = createCommodity({
    id = "soap", name = "Soap", category = "misc",
    icon = "So", stackSize = 500, baseValue = 10,
    dependencies = {"oil"},
    description = "Cleaning agent from oil and lye"
})

CommodityTypes.MEDICINE = createCommodity({
    id = "medicine", name = "Medicine", category = "misc",
    icon = "Md", stackSize = 300, baseValue = 50,
    dependencies = {"flowers"},
    description = "Healing herbs and remedies"
})

-- ==================== FUEL ====================
CommodityTypes.WOOD = createCommodity({
    id = "wood", name = "Wood", category = "fuel",
    icon = "Wd", stackSize = 5000, baseValue = 2,
    isRaw = true,
    description = "Firewood"
})

CommodityTypes.CHARCOAL = createCommodity({
    id = "charcoal", name = "Charcoal", category = "fuel",
    icon = "Cc", stackSize = 3000, baseValue = 5,
    description = "Processed fuel"
})

CommodityTypes.OIL = createCommodity({
    id = "oil", name = "Oil", category = "fuel",
    icon = "Oi", stackSize = 2000, baseValue = 12,
    description = "Liquid fuel"
})

-- Helper functions
function CommodityTypes.getAllCommodities()
    local commodities = {}
    for key, value in pairs(CommodityTypes) do
        if type(value) == "table" and value.id then
            table.insert(commodities, value)
        end
    end
    -- Sort by category and name
    table.sort(commodities, function(a, b)
        if a.category == b.category then
            return a.name < b.name
        end
        return a.category < b.category
    end)
    return commodities
end

function CommodityTypes.getById(id)
    for key, value in pairs(CommodityTypes) do
        if type(value) == "table" and value.id == id then
            return value
        end
    end
    return nil
end

function CommodityTypes.getByCategory(category)
    local commodities = {}
    for key, value in pairs(CommodityTypes) do
        if type(value) == "table" and value.id and value.category == category then
            table.insert(commodities, value)
        end
    end
    return commodities
end

return CommodityTypes
