--
-- Utilities - Helper functions for character and building lookups
--

-- Character name pool (single English names)
local CharacterNames = {
    "James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael", "Linda",
    "William", "Barbara", "David", "Elizabeth", "Richard", "Susan", "Joseph", "Jessica",
    "Thomas", "Sarah", "Charles", "Karen", "Christopher", "Nancy", "Daniel", "Lisa",
    "Matthew", "Betty", "Anthony", "Margaret", "Mark", "Sandra", "Donald", "Ashley",
    "Steven", "Kimberly", "Paul", "Emily", "Andrew", "Donna", "Joshua", "Michelle",
    "Kenneth", "Dorothy", "Kevin", "Carol", "Brian", "Amanda", "George", "Melissa",
    "Edward", "Deborah", "Ronald", "Stephanie", "Timothy", "Rebecca", "Jason", "Sharon",
    "Jeffrey", "Laura", "Ryan", "Cynthia", "Jacob", "Kathleen", "Gary", "Amy",
    "Nicholas", "Shirley", "Eric", "Angela", "Jonathan", "Helen", "Stephen", "Anna",
    "Larry", "Brenda", "Justin", "Pamela", "Scott", "Nicole", "Brandon", "Emma",
    "Benjamin", "Samantha", "Samuel", "Katherine", "Raymond", "Christine", "Gregory", "Debra",
    "Frank", "Rachel", "Alexander", "Catherine", "Patrick", "Carolyn", "Raymond", "Janet",
    "Jack", "Ruth", "Dennis", "Maria", "Jerry", "Heather", "Tyler", "Diane",
    "Aaron", "Virginia", "Jose", "Julie", "Adam", "Joyce", "Henry", "Victoria",
    "Nathan", "Olivia", "Douglas", "Kelly", "Zachary", "Christina", "Peter", "Lauren",
    "Kyle", "Joan", "Walter", "Evelyn", "Ethan", "Judith", "Jeremy", "Megan",
    "Harold", "Cheryl", "Keith", "Andrea", "Christian", "Hannah", "Roger", "Martha",
    "Noah", "Jacqueline", "Gerald", "Frances", "Carl", "Gloria", "Terry", "Ann",
    "Sean", "Teresa", "Austin", "Kathryn", "Arthur", "Sara", "Lawrence", "Janice",
    "Jesse", "Jean", "Dylan", "Alice", "Bryan", "Madison", "Joe", "Doris",
    "Jordan", "Abigail", "Billy", "Julia", "Bruce", "Judy", "Albert", "Grace",
    "Willie", "Denise", "Gabriel", "Amber", "Logan", "Marilyn", "Alan", "Beverly",
    "Juan", "Danielle", "Wayne", "Theresa", "Roy", "Sophia", "Ralph", "Marie",
    "Randy", "Diana", "Eugene", "Brittany", "Vincent", "Natalie", "Russell", "Isabella",
    "Louis", "Charlotte", "Philip", "Rose", "Bobby", "Alexis", "Johnny", "Kayla"
}

-- Get a random character name
function GetRandomCharacterName()
    return CharacterNames[math.random(#CharacterNames)]
end

-- Get a random age within a range
function GetRandomAge(ageRange)
    return math.random(ageRange[1], ageRange[2])
end

-- Get character definition by type
function GetCharacterDefinition(characterType)
    for _, def in ipairs(CharacterDefinitions) do
        if def.type == characterType then
            return def
        end
    end
    return nil
end

-- Get building definition by type
function GetBuildingDefinition(buildingType)
    for _, def in ipairs(BuildingDefinitions) do
        if def.type == buildingType then
            return def
        end
    end
    return nil
end

-- Check if a character type matches a workplace type
function IsCharacterAllowedInWorkplace(characterType, workplaceType)
    local charDef = GetCharacterDefinition(characterType)
    if not charDef then return false end
    
    return charDef.workplaceType == workplaceType
end