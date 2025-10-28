--
-- InventoryDrawer - right-side drawer showing town inventory
--

require("code/CommodityTypes")

InventoryDrawer = {}
InventoryDrawer.__index = InventoryDrawer

function InventoryDrawer:Create()
    local this = {
        mIsInventoryDrawer = true,  -- Flag to identify this state
        mWidth = 350,
        mPadding = 15,
        mScrollOffset = 0,
        mMaxScroll = 0,
        mItemHeight = 30,
        mFilter = "all",  -- "all", "nonzero", or category name
        mCategories = {
            {id = "all", name = "All"},
            {id = "nonzero", name = "In Stock"},
            {id = "grain", name = "Grains"},
            {id = "fruit", name = "Fruits"},
            {id = "vegetable", name = "Vegetables"},
            {id = "animal_product", name = "Animal Products"},
            {id = "processed_food", name = "Processed Food"},
            {id = "textile", name = "Textiles"},
            {id = "clothing", name = "Clothing"},
            {id = "tools", name = "Tools"},
            {id = "furniture", name = "Furniture"},
            {id = "raw_mineral", name = "Minerals"},
            {id = "refined_metal", name = "Metals"},
            {id = "construction", name = "Construction"},
            {id = "fuel", name = "Fuel"},
            {id = "luxury", name = "Luxury"},
            {id = "misc", name = "Misc"}
        }
    }

    setmetatable(this, self)
    return this
end

function InventoryDrawer:Enter()
end

function InventoryDrawer:Exit()
end

function InventoryDrawer:GetFilteredCommodities()
    local inventory = gTown:GetInventory()
    local allCommodities = CommodityTypes.getAllCommodities()
    local filtered = {}

    for _, commodity in ipairs(allCommodities) do
        local quantity = inventory:Get(commodity.id)
        local include = false

        if self.mFilter == "all" then
            include = true
        elseif self.mFilter == "nonzero" then
            include = quantity > 0
        else
            include = commodity.category == self.mFilter
        end

        if include then
            table.insert(filtered, {
                commodity = commodity,
                quantity = quantity
            })
        end
    end

    return filtered
end

function InventoryDrawer:Update(dt)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local drawerX = screenW - self.mWidth
    local topBarHeight = 50
    local mx, my = love.mouse.getPosition()

    -- Handle close button
    if gMouseReleased and gMouseReleased.button == 1 then
        local closeX = screenW - 35
        local closeY = topBarHeight + 10
        if mx >= closeX and mx <= closeX + 25 and
           my >= closeY and my <= closeY + 25 then
            gStateStack:Pop()
            return false
        end

        -- Handle category filter buttons
        local filterY = topBarHeight + 50
        for i, category in ipairs(self.mCategories) do
            local btnX = drawerX + 10
            local btnY = filterY + (i - 1) * 28
            local btnW = self.mWidth - 20
            local btnH = 25

            if mx >= btnX and mx <= btnX + btnW and
               my >= btnY and my <= btnY + btnH then
                self.mFilter = category.id
                self.mScrollOffset = 0
                return false
            end
        end
    end

    -- Handle mouse wheel scrolling
    if mx >= drawerX then
        -- Mouse is over drawer - handle scroll
        -- Note: Love2D mouse wheel is handled via love.wheelmoved callback
    end

    return true -- Continue processing input for states below
end

function InventoryDrawer:Render()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    local drawerX = screenW - self.mWidth
    local topBarHeight = 50

    -- Draw semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, drawerX, screenH)

    -- Draw drawer background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.98)
    love.graphics.rectangle("fill", drawerX, topBarHeight, self.mWidth, screenH - topBarHeight)

    -- Draw close button
    local closeX = screenW - 35
    local closeY = topBarHeight + 10
    love.graphics.setColor(0.8, 0.2, 0.2)
    love.graphics.rectangle("fill", closeX, closeY, 25, 25, 3, 3)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("X", closeX + 7, closeY + 4)

    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Town Inventory", drawerX + self.mPadding, topBarHeight + 15)

    -- Draw category filters (left side)
    local filterY = topBarHeight + 50
    local filterWidth = 150
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", drawerX, filterY, filterWidth, screenH - filterY)

    for i, category in ipairs(self.mCategories) do
        local btnX = drawerX + 5
        local btnY = filterY + (i - 1) * 28 + 5
        local btnW = filterWidth - 10
        local btnH = 25

        local isSelected = self.mFilter == category.id
        local mx, my = love.mouse.getPosition()
        local isHovering = mx >= btnX and mx <= btnX + btnW and
                          my >= btnY and my <= btnY + btnH

        if isSelected then
            love.graphics.setColor(0.3, 0.5, 0.7)
        elseif isHovering then
            love.graphics.setColor(0.35, 0.35, 0.35)
        else
            love.graphics.setColor(0.25, 0.25, 0.25)
        end

        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 3, 3)

        love.graphics.setColor(1, 1, 1)
        love.graphics.print(category.name, btnX + 8, btnY + 5)
    end

    -- Draw inventory list (right side)
    local listX = drawerX + filterWidth + 10
    local listY = filterY + 5
    local listWidth = self.mWidth - filterWidth - 20
    local listHeight = screenH - listY - 10

    -- Scissor to clip list
    love.graphics.setScissor(listX, listY, listWidth, listHeight)

    local items = self:GetFilteredCommodities()
    local y = listY - self.mScrollOffset

    for i, item in ipairs(items) do
        if y + self.mItemHeight >= listY and y <= listY + listHeight then
            -- Draw item background
            if i % 2 == 0 then
                love.graphics.setColor(0.22, 0.22, 0.22)
            else
                love.graphics.setColor(0.25, 0.25, 0.25)
            end
            love.graphics.rectangle("fill", listX, y, listWidth, self.mItemHeight - 2)

            -- Draw icon
            love.graphics.setColor(0.8, 0.8, 0.3)
            love.graphics.rectangle("fill", listX + 5, y + 5, 20, 20)
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(item.commodity.icon, listX + 8, y + 7)

            -- Draw name
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(item.commodity.name, listX + 30, y + 5)

            -- Draw quantity
            local quantityText = tostring(item.quantity)
            local quantityColor = item.quantity > 0 and {0.4, 1, 0.4} or {0.6, 0.6, 0.6}
            love.graphics.setColor(quantityColor[1], quantityColor[2], quantityColor[3])
            local textWidth = love.graphics.getFont():getWidth(quantityText)
            love.graphics.print(quantityText, listX + listWidth - textWidth - 5, y + 5)
        end

        y = y + self.mItemHeight
    end

    -- Calculate max scroll
    self.mMaxScroll = math.max(0, #items * self.mItemHeight - listHeight)

    love.graphics.setScissor()

    -- Draw scrollbar if needed
    if self.mMaxScroll > 0 then
        local scrollbarHeight = listHeight * (listHeight / (#items * self.mItemHeight))
        local scrollbarY = listY + (self.mScrollOffset / self.mMaxScroll) * (listHeight - scrollbarHeight)

        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", listX + listWidth - 8, scrollbarY, 6, scrollbarHeight, 3, 3)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function InventoryDrawer:HandleInput()
end

function InventoryDrawer:OnMouseWheel(dx, dy)
    -- Handle scroll
    local screenW = love.graphics.getWidth()
    local drawerX = screenW - self.mWidth
    local mx, my = love.mouse.getPosition()

    if mx >= drawerX then
        self.mScrollOffset = self.mScrollOffset - dy * 30
        self.mScrollOffset = math.max(0, math.min(self.mScrollOffset, self.mMaxScroll))
    end
end

return InventoryDrawer
