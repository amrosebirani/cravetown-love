--
-- CharacterFactory - creates characters with randomized properties
--

CharacterFactory = {}

-- Generate a random age based on character type
function CharacterFactory.GenerateAge(characterType)
    local def = GetCharacterDefinition(characterType)
    if def and def.ageRange then
        local minAge = def.ageRange[1]
        local maxAge = def.ageRange[2]
        return math.random(minAge, maxAge)
    end
    -- Default age range for adults
    return math.random(22, 34)
end

-- Generate random status
function CharacterFactory.GenerateStatus()
    local statuses = {"Bachelor", "Single", "Married", "Widower", "Divorced"}
    return statuses[math.random(#statuses)]
end

-- Generate random diet
function CharacterFactory.GenerateDiet()
    local diets = {"Omnivore", "Vegetarian", "Pescetarian", "Vegan"}
    return diets[math.random(#diets)]
end

-- Generate random class
function CharacterFactory.GenerateClass()
    local classes = {
        {name = "Lower", percent = "15%"},
        {name = "Middle", percent = "25%"},
        {name = "Upper", percent = "35%"},
        {name = "Elite", percent = "10%"}
    }
    local choice = classes[math.random(#classes)]
    return choice.name .. " (" .. choice.percent .. ")"
end

-- Generate random biography based on role
function CharacterFactory.GenerateBiography(role, gender)
    local templates = {
        "A hardworking {role} dedicated to their craft.",
        "An experienced {role} who takes pride in their work.",
        "A skilled {role} known throughout the town.",
        "A reliable {role} who never misses a day of work.",
        "A talented {role} with years of experience.",
    }

    local template = templates[math.random(#templates)]
    return template:gsub("{role}", role:lower())
end

-- Generate random personality traits
function CharacterFactory.GenerateTraits()
    local allTraits = {
        "Hardworking", "Lazy", "Ambitious", "Content", "Friendly", "Grumpy",
        "Curious", "Cautious", "Brave", "Timid", "Generous", "Greedy",
        "Honest", "Deceitful", "Patient", "Impatient", "Creative", "Practical",
        "Optimistic", "Pessimistic", "Loyal", "Independent"
    }

    local traits = {}
    local numTraits = math.random(3, 5)

    for i = 1, numTraits do
        local trait = allTraits[math.random(#allTraits)]
        -- Avoid duplicates
        if not table.contains(traits, trait) then
            table.insert(traits, trait)
        end
    end

    return traits
end

-- Generate random cravings (between 20 and 80)
function CharacterFactory.GenerateCravings()
    return {
        biological = math.random(20, 80),
        touch = math.random(20, 80),
        psychological = math.random(20, 80),
        safety = math.random(20, 80),
        socialStatus = math.random(20, 80),
        exoticGoods = math.random(20, 80),
        shinyObjects = math.random(20, 80)
    }
end

-- Create a fully randomized character based on type
function CharacterFactory.CreateCharacter(characterType, x, y)
    local def = GetCharacterDefinition(characterType)

    if not def then
        print("Error: Unknown character type: " .. tostring(characterType))
        return nil
    end

    -- Determine gender and name
    local gender = nil
    local name = nil

    -- Animals and kids have special naming
    if characterType == "cow" or characterType == "chicken" then
        name = NameGenerator.GenerateAnimalName()
        gender = "animal"
    elseif characterType == "kids" then
        gender = NameGenerator.GenerateGender()
        name = NameGenerator.GenerateName(gender)
    else
        gender = NameGenerator.GenerateGender()
        name = NameGenerator.GenerateName(gender)
    end

    local age = CharacterFactory.GenerateAge(characterType)
    local status = CharacterFactory.GenerateStatus()
    local diet = CharacterFactory.GenerateDiet()
    local class = CharacterFactory.GenerateClass()
    local biography = CharacterFactory.GenerateBiography(def.role, gender)
    local traits = CharacterFactory.GenerateTraits()
    local cravings = CharacterFactory.GenerateCravings()

    return Character:Create({
        name = name,
        age = age,
        gender = gender,
        type = characterType,
        role = def.role,
        class = class,
        status = status,
        diet = diet,
        biography = biography,
        cravingProvided = def.cravingProvided,
        cravingType = def.cravingType,
        cravings = cravings,
        traits = traits,
        productionItems = def.productionItems,
        color = def.color,
        x = x or 0,
        y = y or 0
    })
end

-- Helper function to check if table contains value
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end
