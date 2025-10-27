--
-- Building - represents a building in the town
--

Building = {}
Building.__index = Building

function Building:Create(params)
    local this = {
        mType = params.type or "house",
        mX = params.x or 0,
        mY = params.y or 0,
        mWidth = params.width or 70,  -- Changed for hot reload test
        mHeight = params.height or 70, -- Changed for hot reload test
        mColor = params.color or {0.2, 0.4, 0.8}, -- Blue color for house
        mTextColor = {1, 1, 1}, -- White color for text
        mLabel = params.label or "H",
        mPlaced = params.placed or false -- Whether the building is placed on map
    }

    setmetatable(this, self)
    return this
end

function Building:SetPosition(x, y)
    self.mX = x
    self.mY = y
end

function Building:GetPosition()
    return self.mX, self.mY
end

function Building:GetBounds()
    return self.mX, self.mY, self.mWidth, self.mHeight
end

function Building:SetPlaced(placed)
    self.mPlaced = placed
end

function Building:IsPlaced()
    return self.mPlaced
end

function Building:CheckCollision(other)
    local x1, y1, w1, h1 = self:GetBounds()
    local x2, y2, w2, h2 = other:GetBounds()

    -- AABB collision detection
    return x1 < x2 + w2 and
           x1 + w1 > x2 and
           y1 < y2 + h2 and
           y1 + h1 > y2
end

function Building:Render(canPlace)
    -- If canPlace is false, show red tinge
    if canPlace == false then
        love.graphics.setColor(0.8, 0.2, 0.2, 0.7) -- Red with transparency
    else
        love.graphics.setColor(self.mColor[1], self.mColor[2], self.mColor[3])
    end

    -- Draw the building box
    love.graphics.rectangle("fill", self.mX, self.mY, self.mWidth, self.mHeight)

    -- Draw border
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.mX, self.mY, self.mWidth, self.mHeight)

    -- Draw label in center
    love.graphics.setColor(self.mTextColor[1], self.mTextColor[2], self.mTextColor[3])
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(self.mLabel)
    local textHeight = font:getHeight()
    love.graphics.print(
        self.mLabel,
        self.mX + self.mWidth / 2 - textWidth / 2,
        self.mY + self.mHeight / 2 - textHeight / 2
    )

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end
