--
-- Character - represents a townsperson, animal, or worker
-- Characters are STATIONARY and stay inside their workplace
--

Character = {}
Character.__index = Character

function Character:Create(params)
    local def = params.definition or GetCharacterDefinition(params.type)
    
    if not def then
        error("Character definition not found for type: " .. (params.type or "unknown"))
    end

    local this = {
        -- Basic Info
        mName = params.name or GetRandomCharacterName(),
        mAge = params.age or GetRandomAge(def.ageRange),
        mGender = params.gender or (math.random() > 0.5 and "male" or "female"),

        -- Role & Type (from definition)
        mType = def.type,
        mRole = def.role,
        mCravingProvided = def.cravingProvided,
        mWorkplaceType = def.workplaceType,
        
        -- Class & Status
        mClass = params.class or "Middle",
        mStatus = params.status or "Bachelor",
        mDiet = params.diet or "Omnivore",
        
        -- Children (Farmer has 1, others have 0)
        mChildren = (def.type == "farmer") and 1 or 0,

        -- Biography
        mBiography = params.biography or string.format("A %s who provides %s to the town.", 
            string.lower(def.role), 
            string.lower(def.cravingProvided)),
        
        -- Selling Info
        mSellingPrice = params.price or math.random(10, 100),
        mInventory = params.inventory or 0,
        
        -- Position & Rendering
        mX = params.x or 0,
        mY = params.y or 0,
        mRadius = params.radius or 15,
        mColor = params.color or def.color,
        
        -- Placement & Workplace
        mPlaced = false,  -- Not placed on map until assigned to workplace
        mWorkplace = nil,
        
        -- Economy
        mMoney = params.money or 0
    }

    setmetatable(this, self)
    return this
end

function Character:SetPosition(x, y)
    self.mX = x
    self.mY = y
end

function Character:GetPosition()
    return self.mX, self.mY
end

function Character:SetPlaced(placed)
    self.mPlaced = placed
end

function Character:IsPlaced()
    return self.mPlaced
end

function Character:SetWorkplace(building)
    self.mWorkplace = building
    
    -- Position character at center of workplace
    if building then
        local bx, by, bw, bh = building:GetBounds()
        self:SetPosition(bx + bw/2, by + bh/2)
        self:SetPlaced(true)
    end
end

function Character:GetWorkplace()
    return self.mWorkplace
end

function Character:Render()
    -- Only render if placed on map
    if not self.mPlaced then
        return
    end
    
    -- Draw character as circle
    love.graphics.setColor(self.mColor[1], self.mColor[2], self.mColor[3])
    love.graphics.circle("fill", self.mX, self.mY, self.mRadius)

    -- Draw border
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("line", self.mX, self.mY, self.mRadius)

    -- Draw name below character
    love.graphics.setColor(0, 0, 0)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(self.mName)
    love.graphics.print(self.mName, self.mX - textWidth / 2, self.mY + self.mRadius + 5)

    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function Character:GetInfo()
    return string.format("%s (%d, %s) - %s\nClass: %s, Status: %s\nDiet: %s, Children: %d\nSells: %s at $%d",
        self.mName, self.mAge, self.mGender, self.mRole,
        self.mClass, self.mStatus,
        self.mDiet, self.mChildren,
        self.mCravingProvided, self.mSellingPrice)
end

function Character:GetSellingInfo()
    return {
        item = self.mCravingProvided,
        price = self.mSellingPrice,
        inventory = self.mInventory
    }
end