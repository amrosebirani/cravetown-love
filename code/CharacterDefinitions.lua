--
-- CharacterDefinitions - defines all 23 character types and their properties
--

CharacterDefinitions = {
    -- Human Characters (Age: 22-40)
    {
        type = "farmer",
        role = "Farmer",
        cravingProvided = "Crops",
        workplaceType = "farm",
        color = {0.4, 0.7, 0.3},
        ageRange = {22, 40}
    },
    {
        type = "baker",
        role = "Baker",
        cravingProvided = "Bread",
        workplaceType = "bakery",
        color = {0.8, 0.6, 0.3},
        ageRange = {22, 40}
    },
    {
        type = "cook",
        role = "Cook",
        cravingProvided = "Meals",
        workplaceType = "kitchen",
        color = {0.9, 0.5, 0.2},
        ageRange = {22, 40}
    },
    {
        type = "worker",
        role = "Worker",
        cravingProvided = "Service",
        workplaceType = "worksite",
        color = {0.5, 0.5, 0.5},
        ageRange = {22, 40}
    },
    {
        type = "police",
        role = "Police",
        cravingProvided = "Security",
        workplaceType = "station",
        color = {0.2, 0.3, 0.8},
        ageRange = {22, 40}
    },
    {
        type = "teacher",
        role = "Teacher",
        cravingProvided = "Education",
        workplaceType = "school",
        color = {0.7, 0.3, 0.7},
        ageRange = {22, 40}
    },
    {
        type = "preacher",
        role = "Preacher",
        cravingProvided = "Direction",
        workplaceType = "temple",
        color = {0.9, 0.9, 0.7},
        ageRange = {22, 40}
    },
    {
        type = "transporter",
        role = "Transporter",
        cravingProvided = "Transport",
        workplaceType = "depot",
        color = {0.3, 0.6, 0.7},
        ageRange = {22, 40}
    },
    {
        type = "doctor",
        role = "Doctor",
        cravingProvided = "Health",
        workplaceType = "hospital",
        color = {1.0, 0.3, 0.3},
        ageRange = {22, 40}
    },
    {
        type = "plumber",
        role = "Plumber",
        cravingProvided = "Sanitation",
        workplaceType = "workshop",
        color = {0.4, 0.5, 0.6},
        ageRange = {22, 40}
    },
    {
        type = "electrician",
        role = "Electrician",
        cravingProvided = "Electricity",
        workplaceType = "powerhouse",
        color = {1.0, 1.0, 0.3},
        ageRange = {22, 40}
    },
    {
        type = "carpenter",
        role = "Carpenter",
        cravingProvided = "Furniture",
        workplaceType = "carpentry",
        color = {0.6, 0.4, 0.2},
        ageRange = {22, 40}
    },
    {
        type = "painter",
        role = "Painter",
        cravingProvided = "Aesthetics",
        workplaceType = "studio",
        color = {0.9, 0.4, 0.6},
        ageRange = {22, 40}
    },
    {
        type = "tailor",
        role = "Tailor",
        cravingProvided = "Clothes",
        workplaceType = "tailorshop",
        color = {0.7, 0.5, 0.8},
        ageRange = {22, 40}
    },
    {
        type = "goldsmith",
        role = "Goldsmith",
        cravingProvided = "Jewellery",
        workplaceType = "smithy",
        color = {1.0, 0.8, 0.2},
        ageRange = {22, 40}
    },
    {
        type = "homemaker",
        role = "Homemaker",
        cravingProvided = "Companionship",
        workplaceType = "house",
        color = {0.9, 0.7, 0.7},
        ageRange = {22, 40}
    },
    {
        type = "lender",
        role = "Lender",
        cravingProvided = "Loan",
        workplaceType = "bank",
        color = {0.3, 0.5, 0.3},
        ageRange = {22, 40}
    },
    {
        type = "miner",
        role = "Miner",
        cravingProvided = "Iron",
        workplaceType = "mine",
        color = {0.3, 0.3, 0.3},
        ageRange = {22, 40}
    },
    {
        type = "blacksmith",
        role = "Blacksmith",
        cravingProvided = "Tools",
        workplaceType = "forge",
        color = {0.4, 0.4, 0.4},
        ageRange = {22, 40}
    },
    {
        type = "brickmaker",
        role = "Brick-maker",
        cravingProvided = "Bricks",
        workplaceType = "brickyard",
        color = {0.7, 0.3, 0.2},
        ageRange = {22, 40}
    },
    
    -- Special: Kids (Age: 5-7)
    {
        type = "kids",
        role = "Kids",
        cravingProvided = "Survival",
        workplaceType = "none",
        color = {1.0, 0.8, 0.6},
        ageRange = {5, 7}
    },
    
    -- Animals (Age: 2-4)
    {
        type = "cow",
        role = "Cow",
        cravingProvided = "Milk",
        workplaceType = "farm",
        color = {0.6, 0.5, 0.4},
        ageRange = {2, 4}
    },
    {
        type = "chicken",
        role = "Chicken",
        cravingProvided = "Eggs",
        workplaceType = "farm",
        color = {0.9, 0.9, 0.8},
        ageRange = {2, 4}
    }
}

CharacterNames = {
    "James", "John", "Robert", "Michael", "William", "David", "Richard", "Joseph",
    "Thomas", "Charles", "Daniel", "Matthew", "Mark", "Donald", "Paul", "George",
    "Kenneth", "Steven", "Edward", "Brian", "Ronald", "Anthony", "Kevin", "Jason",
    "Mary", "Patricia", "Jennifer", "Linda", "Barbara", "Elizabeth", "Susan", "Jessica",
    "Sarah", "Karen", "Nancy", "Lisa", "Betty", "Margaret", "Sandra", "Ashley",
    "Dorothy", "Kimberly", "Emily", "Donna", "Michelle", "Carol", "Amanda", "Melissa",
    "Alice", "Henry", "Arthur", "Walter", "Jack", "Albert", "Roy", "Ralph",
    "Eugene", "Russell", "Louis", "Philip", "Benjamin", "Samuel", "Frank", "Raymond"
}

function GetRandomCharacterName()
    return CharacterNames[math.random(1, #CharacterNames)]
end

function GetCharacterDefinition(charType)
    for _, def in ipairs(CharacterDefinitions) do
        if def.type == charType then
            return def
        end
    end
    return nil
end

function GetRandomAge(ageRange)
    return math.random(ageRange[1], ageRange[2])
end