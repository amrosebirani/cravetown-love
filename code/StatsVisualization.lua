-- StatsVisualization.lua
-- Simple charts and graphs for production statistics

local StatsVisualization = {}

-- Draw a simple line chart
function StatsVisualization.drawLineChart(x, y, width, height, data, options)
    options = options or {}
    local title = options.title or ""
    local color = options.color or {0.2, 0.8, 0.4, 1.0}
    local bgColor = options.bgColor or {0.1, 0.1, 0.1, 0.8}
    local gridColor = options.gridColor or {0.3, 0.3, 0.3, 0.5}
    local showGrid = options.showGrid ~= false
    local showAxes = options.showAxes ~= false

    -- Draw background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Draw title
    if title ~= "" then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(title, x + 5, y + 5)
    end

    -- Check if we have data
    if not data or #data < 2 then
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print("No data", x + width/2 - 30, y + height/2)
        return
    end

    -- Calculate chart area (leave margins)
    local chartX = x + 40
    local chartY = y + 30
    local chartWidth = width - 50
    local chartHeight = height - 40

    -- Find min/max values
    local minVal = math.huge
    local maxVal = -math.huge
    for _, point in ipairs(data) do
        local value = point.quantity or point.utilization or point[2] or 0
        minVal = math.min(minVal, value)
        maxVal = math.max(maxVal, value)
    end

    -- Add some padding to max
    if minVal == maxVal then
        maxVal = minVal + 1
    end
    local valueRange = maxVal - minVal
    maxVal = maxVal + valueRange * 0.1

    -- Draw grid
    if showGrid then
        love.graphics.setColor(gridColor)
        for i = 0, 5 do
            local gridY = chartY + (i / 5) * chartHeight
            love.graphics.line(chartX, gridY, chartX + chartWidth, gridY)
        end
    end

    -- Draw axes
    if showAxes then
        love.graphics.setColor(0.6, 0.6, 0.6, 1)
        love.graphics.line(chartX, chartY, chartX, chartY + chartHeight)  -- Y axis
        love.graphics.line(chartX, chartY + chartHeight, chartX + chartWidth, chartY + chartHeight)  -- X axis

        -- Y axis labels
        love.graphics.setColor(0.8, 0.8, 0.8, 1)
        for i = 0, 5 do
            local value = maxVal - (i / 5) * (maxVal - minVal)
            local labelY = chartY + (i / 5) * chartHeight
            love.graphics.print(string.format("%.0f", value), chartX - 35, labelY - 7)
        end
    end

    -- Draw line
    love.graphics.setColor(color)
    love.graphics.setLineWidth(2)

    for i = 1, #data - 1 do
        local value1 = data[i].quantity or data[i].utilization or data[i][2] or 0
        local value2 = data[i+1].quantity or data[i+1].utilization or data[i+1][2] or 0

        local x1 = chartX + ((i - 1) / (#data - 1)) * chartWidth
        local y1 = chartY + chartHeight - ((value1 - minVal) / (maxVal - minVal)) * chartHeight
        local x2 = chartX + (i / (#data - 1)) * chartWidth
        local y2 = chartY + chartHeight - ((value2 - minVal) / (maxVal - minVal)) * chartHeight

        love.graphics.line(x1, y1, x2, y2)
    end

    love.graphics.setLineWidth(1)
end

-- Draw a horizontal bar chart
function StatsVisualization.drawBarChart(x, y, width, height, data, options)
    options = options or {}
    local title = options.title or ""
    local color = options.color or {0.3, 0.6, 0.9, 1.0}
    local bgColor = options.bgColor or {0.1, 0.1, 0.1, 0.8}
    local showValues = options.showValues ~= false
    local maxBars = options.maxBars or 10

    -- Draw background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Draw title
    if title ~= "" then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(title, x + 5, y + 5)
    end

    -- Check if we have data
    if not data or #data == 0 then
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print("No data", x + width/2 - 30, y + height/2)
        return
    end

    -- Limit number of bars
    local displayData = {}
    for i = 1, math.min(#data, maxBars) do
        table.insert(displayData, data[i])
    end

    -- Calculate chart area
    local chartX = x + 10
    local chartY = y + 30
    local chartWidth = width - 20
    local chartHeight = height - 40

    -- Find max value
    local maxVal = 0
    for _, item in ipairs(displayData) do
        local value = item.rate or item.value or item.quantity or 0
        maxVal = math.max(maxVal, value)
    end

    if maxVal == 0 then maxVal = 1 end

    -- Calculate bar dimensions
    local barHeight = (chartHeight / #displayData) * 0.8
    local barSpacing = (chartHeight / #displayData) * 0.2

    -- Draw bars
    for i, item in ipairs(displayData) do
        local value = item.rate or item.value or item.quantity or 0
        local label = item.id or item.label or item.name or tostring(i)

        local barY = chartY + (i - 1) * (barHeight + barSpacing)
        local barWidth = (value / maxVal) * (chartWidth - 100)

        -- Draw bar
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", chartX + 80, barY, barWidth, barHeight)

        -- Draw label
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(label, chartX, barY + barHeight/2 - 7)

        -- Draw value
        if showValues then
            love.graphics.print(string.format("%.1f", value), chartX + 80 + barWidth + 5, barY + barHeight/2 - 7)
        end
    end
end

-- Draw a stacked area chart (production vs consumption)
function StatsVisualization.drawStackedAreaChart(x, y, width, height, productionData, consumptionData, options)
    options = options or {}
    local title = options.title or ""
    local prodColor = options.prodColor or {0.2, 0.8, 0.4, 0.6}
    local consColor = options.consColor or {0.9, 0.3, 0.3, 0.6}
    local bgColor = options.bgColor or {0.1, 0.1, 0.1, 0.8}

    -- Draw background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Draw title
    if title ~= "" then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(title, x + 5, y + 5)
    end

    -- Check data
    if not productionData or #productionData < 2 then
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print("No data", x + width/2 - 30, y + height/2)
        return
    end

    -- Calculate chart area
    local chartX = x + 40
    local chartY = y + 30
    local chartWidth = width - 50
    local chartHeight = height - 60

    -- Find max value from both datasets
    local maxVal = 0
    for _, point in ipairs(productionData) do
        maxVal = math.max(maxVal, point.quantity or point[2] or 0)
    end
    if consumptionData then
        for _, point in ipairs(consumptionData) do
            maxVal = math.max(maxVal, point.quantity or point[2] or 0)
        end
    end

    if maxVal == 0 then maxVal = 1 end
    maxVal = maxVal * 1.1  -- Add 10% padding

    -- Draw axes
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.line(chartX, chartY, chartX, chartY + chartHeight)  -- Y axis
    love.graphics.line(chartX, chartY + chartHeight, chartX + chartWidth, chartY + chartHeight)  -- X axis

    -- Draw production area
    love.graphics.setColor(prodColor)
    local prodPoints = {}
    for i, point in ipairs(productionData) do
        local value = point.quantity or point[2] or 0
        local px = chartX + ((i - 1) / (#productionData - 1)) * chartWidth
        local py = chartY + chartHeight - (value / maxVal) * chartHeight
        table.insert(prodPoints, px)
        table.insert(prodPoints, py)
    end
    -- Close the polygon
    table.insert(prodPoints, chartX + chartWidth)
    table.insert(prodPoints, chartY + chartHeight)
    table.insert(prodPoints, chartX)
    table.insert(prodPoints, chartY + chartHeight)

    if #prodPoints >= 6 then
        love.graphics.polygon("fill", prodPoints)
    end

    -- Draw consumption area
    if consumptionData and #consumptionData > 1 then
        love.graphics.setColor(consColor)
        local consPoints = {}
        for i, point in ipairs(consumptionData) do
            local value = point.quantity or point[2] or 0
            local px = chartX + ((i - 1) / (#consumptionData - 1)) * chartWidth
            local py = chartY + chartHeight - (value / maxVal) * chartHeight
            table.insert(consPoints, px)
            table.insert(consPoints, py)
        end
        -- Close the polygon
        table.insert(consPoints, chartX + chartWidth)
        table.insert(consPoints, chartY + chartHeight)
        table.insert(consPoints, chartX)
        table.insert(consPoints, chartY + chartHeight)

        if #consPoints >= 6 then
            love.graphics.polygon("fill", consPoints)
        end
    end

    -- Draw legend
    love.graphics.setColor(prodColor)
    love.graphics.rectangle("fill", chartX, chartY + chartHeight + 10, 15, 15)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Production", chartX + 20, chartY + chartHeight + 10)

    love.graphics.setColor(consColor)
    love.graphics.rectangle("fill", chartX + 120, chartY + chartHeight + 10, 15, 15)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Consumption", chartX + 140, chartY + chartHeight + 10)
end

-- Draw a stat card (simple number display)
function StatsVisualization.drawStatCard(x, y, width, height, value, label, options)
    options = options or {}
    local bgColor = options.bgColor or {0.15, 0.15, 0.2, 0.9}
    local textColor = options.textColor or {1, 1, 1, 1}
    local valueColor = options.valueColor or {0.3, 0.8, 1.0, 1}
    local format = options.format or "%.1f"

    -- Draw background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Draw border
    love.graphics.setColor(0.3, 0.3, 0.4, 1)
    love.graphics.rectangle("line", x, y, width, height)

    -- Draw value (large)
    love.graphics.setColor(valueColor)
    local valueStr = string.format(format, value)
    local font = love.graphics.getFont()
    local valueWidth = font:getWidth(valueStr)
    love.graphics.print(valueStr, x + width/2 - valueWidth/2, y + height/2 - 15, 0, 1.5)

    -- Draw label (small)
    love.graphics.setColor(textColor)
    local labelWidth = font:getWidth(label)
    love.graphics.print(label, x + width/2 - labelWidth/2, y + height - 20)
end

-- Draw a simple panel with stats summary
function StatsVisualization.drawStatsSummary(x, y, width, height, stats)
    -- Background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Title
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Production Statistics", x + 10, y + 10)

    -- Worker utilization
    local utilization = stats.workerUtilization or 0
    love.graphics.print(string.format("Worker Utilization: %.1f%%", utilization), x + 10, y + 35)
    love.graphics.print(string.format("Workers: %d / %d", stats.activeWorkers or 0, stats.totalWorkers or 0),
        x + 10, y + 50)

    -- Top producers
    love.graphics.print("Top Producers:", x + 10, y + 75)
    if stats.topProducers and #stats.topProducers > 0 then
        for i, item in ipairs(stats.topProducers) do
            love.graphics.print(string.format("%d. %s: %.1f/min", i, item.id, item.rate),
                x + 20, y + 75 + i * 15)
        end
    else
        love.graphics.setColor(0.7, 0.7, 0.7, 1)
        love.graphics.print("No production yet", x + 20, y + 90)
    end
end

return StatsVisualization
