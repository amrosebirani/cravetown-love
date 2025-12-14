--
-- BirthdaySplash - Animated birthday greeting screen
-- A special birthday gift for Mansi!
--

BirthdaySplash = {}
BirthdaySplash.__index = BirthdaySplash

function BirthdaySplash:Create(onComplete)
    local this = {
        mOnComplete = onComplete or function() end,
        mTimer = 0,
        mPhase = "fade_in",  -- fade_in, show, fade_out
        mFadeInDuration = 1.5,
        mShowDuration = 4.0,
        mFadeOutDuration = 1.0,
        mAlpha = 0,

        -- Particle system for floating hearts
        mHearts = {},
        mHeartSpawnTimer = 0,
        mHeartSpawnInterval = 0.15,

        -- Sparkle effects
        mSparkles = {},
        mSparkleSpawnTimer = 0,

        -- Text animation
        mTextScale = 0.5,
        mTextBounce = 0,

        -- Colors
        mBgColor = {0.95, 0.85, 0.9},  -- Soft pink
        mTextColor = {0.8, 0.2, 0.4},   -- Deep rose
        mHeartColors = {
            {1.0, 0.4, 0.5},
            {1.0, 0.5, 0.6},
            {0.9, 0.3, 0.5},
            {1.0, 0.6, 0.7},
            {0.95, 0.45, 0.55}
        },

        -- Fonts (created once)
        mFonts = {
            title = love.graphics.newFont(72),
            name = love.graphics.newFont(96),
            subtitle = love.graphics.newFont(32),
            instruction = love.graphics.newFont(18)
        },

        -- Click/key to skip
        mCanSkip = false,
        mSkipTimer = 0
    }

    setmetatable(this, self)
    return this
end

function BirthdaySplash:SpawnHeart()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local heart = {
        x = math.random(50, screenW - 50),
        y = screenH + 50,
        size = math.random(20, 45),
        speed = math.random(80, 150),
        wobbleSpeed = math.random(2, 4),
        wobbleAmount = math.random(20, 40),
        wobbleOffset = math.random() * math.pi * 2,
        rotation = math.random() * 0.4 - 0.2,
        color = self.mHeartColors[math.random(#self.mHeartColors)],
        alpha = 0.7 + math.random() * 0.3
    }
    table.insert(self.mHearts, heart)
end

function BirthdaySplash:SpawnSparkle()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()
    local sparkle = {
        x = math.random(0, screenW),
        y = math.random(0, screenH),
        size = math.random(2, 6),
        life = 0,
        maxLife = 0.5 + math.random() * 0.5,
        alpha = 0
    }
    table.insert(self.mSparkles, sparkle)
end

function BirthdaySplash:Update(dt)
    self.mTimer = self.mTimer + dt
    self.mSkipTimer = self.mSkipTimer + dt

    -- Allow skipping after 1.5 seconds
    if self.mSkipTimer > 1.5 then
        self.mCanSkip = true
    end

    -- Phase management
    if self.mPhase == "fade_in" then
        self.mAlpha = math.min(1, self.mTimer / self.mFadeInDuration)
        self.mTextScale = 0.5 + 0.5 * self.mAlpha
        if self.mTimer >= self.mFadeInDuration then
            self.mPhase = "show"
            self.mTimer = 0
        end
    elseif self.mPhase == "show" then
        self.mAlpha = 1
        self.mTextBounce = math.sin(self.mTimer * 2) * 5
        if self.mTimer >= self.mShowDuration then
            self.mPhase = "fade_out"
            self.mTimer = 0
        end
    elseif self.mPhase == "fade_out" then
        self.mAlpha = 1 - (self.mTimer / self.mFadeOutDuration)
        if self.mTimer >= self.mFadeOutDuration then
            self.mOnComplete()
            return true
        end
    end

    -- Spawn hearts
    self.mHeartSpawnTimer = self.mHeartSpawnTimer + dt
    if self.mHeartSpawnTimer >= self.mHeartSpawnInterval then
        self.mHeartSpawnTimer = 0
        self:SpawnHeart()
    end

    -- Update hearts
    for i = #self.mHearts, 1, -1 do
        local heart = self.mHearts[i]
        heart.y = heart.y - heart.speed * dt
        heart.x = heart.x + math.sin(self.mTimer * heart.wobbleSpeed + heart.wobbleOffset) * heart.wobbleAmount * dt

        -- Remove hearts that go off screen
        if heart.y < -60 then
            table.remove(self.mHearts, i)
        end
    end

    -- Spawn sparkles
    self.mSparkleSpawnTimer = self.mSparkleSpawnTimer + dt
    if self.mSparkleSpawnTimer >= 0.05 then
        self.mSparkleSpawnTimer = 0
        self:SpawnSparkle()
    end

    -- Update sparkles
    for i = #self.mSparkles, 1, -1 do
        local sparkle = self.mSparkles[i]
        sparkle.life = sparkle.life + dt
        local t = sparkle.life / sparkle.maxLife
        sparkle.alpha = math.sin(t * math.pi)  -- Fade in and out

        if sparkle.life >= sparkle.maxLife then
            table.remove(self.mSparkles, i)
        end
    end

    -- Check for skip (click or key)
    if self.mCanSkip and gMousePressed then
        self.mOnComplete()
        return true
    end

    return false
end

function BirthdaySplash:Render()
    local screenW, screenH = love.graphics.getWidth(), love.graphics.getHeight()

    -- Background with gradient effect
    love.graphics.clear(
        self.mBgColor[1] * self.mAlpha,
        self.mBgColor[2] * self.mAlpha,
        self.mBgColor[3] * self.mAlpha
    )

    -- Draw sparkles (behind everything)
    for _, sparkle in ipairs(self.mSparkles) do
        love.graphics.setColor(1, 1, 0.8, sparkle.alpha * self.mAlpha * 0.6)
        love.graphics.circle("fill", sparkle.x, sparkle.y, sparkle.size)
    end

    -- Draw floating hearts
    for _, heart in ipairs(self.mHearts) do
        love.graphics.push()
        love.graphics.translate(heart.x, heart.y)
        love.graphics.rotate(heart.rotation)
        love.graphics.setColor(heart.color[1], heart.color[2], heart.color[3], heart.alpha * self.mAlpha)
        self:DrawHeart(0, 0, heart.size)
        love.graphics.pop()
    end

    -- Main text - "Happy Birthday"
    love.graphics.setFont(self.mFonts.title)
    love.graphics.setColor(self.mTextColor[1], self.mTextColor[2], self.mTextColor[3], self.mAlpha)
    local titleText = "Happy Birthday"
    local titleWidth = self.mFonts.title:getWidth(titleText)

    love.graphics.push()
    love.graphics.translate(screenW / 2, screenH / 2 - 80 + self.mTextBounce)
    love.graphics.scale(self.mTextScale, self.mTextScale)
    love.graphics.print(titleText, -titleWidth / 2, -36)
    love.graphics.pop()

    -- Name - "Mansi!"
    love.graphics.setFont(self.mFonts.name)
    love.graphics.setColor(0.9, 0.3, 0.5, self.mAlpha)
    local nameText = "Mansi!"
    local nameWidth = self.mFonts.name:getWidth(nameText)

    love.graphics.push()
    love.graphics.translate(screenW / 2, screenH / 2 + 30 + self.mTextBounce * 0.5)
    love.graphics.scale(self.mTextScale, self.mTextScale)
    -- Draw shadow
    love.graphics.setColor(0.5, 0.1, 0.2, self.mAlpha * 0.3)
    love.graphics.print(nameText, -nameWidth / 2 + 4, -48 + 4)
    -- Draw main text
    love.graphics.setColor(0.9, 0.3, 0.5, self.mAlpha)
    love.graphics.print(nameText, -nameWidth / 2, -48)
    love.graphics.pop()

    -- Subtitle
    love.graphics.setFont(self.mFonts.subtitle)
    love.graphics.setColor(0.6, 0.3, 0.4, self.mAlpha * 0.8)
    local subtitleText = "With love from Amrose"
    local subtitleWidth = self.mFonts.subtitle:getWidth(subtitleText)
    love.graphics.print(subtitleText, (screenW - subtitleWidth) / 2, screenH / 2 + 100)

    -- Draw decorative hearts around the text
    local centerX, centerY = screenW / 2, screenH / 2
    love.graphics.setColor(1, 0.5, 0.6, self.mAlpha * 0.7)
    self:DrawHeart(centerX - 250, centerY - 60, 25)
    self:DrawHeart(centerX + 250, centerY - 60, 25)
    self:DrawHeart(centerX - 200, centerY + 80, 20)
    self:DrawHeart(centerX + 200, centerY + 80, 20)

    -- Skip instruction
    if self.mCanSkip then
        love.graphics.setFont(self.mFonts.instruction)
        love.graphics.setColor(0.5, 0.3, 0.4, self.mAlpha * 0.6)
        local skipText = "Click anywhere to continue"
        local skipWidth = self.mFonts.instruction:getWidth(skipText)
        love.graphics.print(skipText, (screenW - skipWidth) / 2, screenH - 50)
    end

    love.graphics.setColor(1, 1, 1)
end

function BirthdaySplash:DrawHeart(x, y, size)
    -- Draw a heart shape using bezier curves
    local s = size / 30  -- Scale factor

    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(s, s)

    -- Heart shape approximation using circles and a triangle
    -- Left circle
    love.graphics.circle("fill", -10, -5, 15)
    -- Right circle
    love.graphics.circle("fill", 10, -5, 15)
    -- Bottom triangle
    love.graphics.polygon("fill", -22, 0, 22, 0, 0, 30)

    love.graphics.pop()
end

function BirthdaySplash:keypressed(key)
    if self.mCanSkip and (key == "space" or key == "return" or key == "escape") then
        self.mOnComplete()
        return true
    end
    return false
end

return BirthdaySplash
