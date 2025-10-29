--
-- NameGenerator - generates random American/British names
--

NameGenerator = {}

-- American/British first names
NameGenerator.maleFirstNames = {
    "James", "John", "Robert", "Michael", "William", "David", "Richard", "Joseph",
    "Thomas", "Charles", "Christopher", "Daniel", "Matthew", "Anthony", "Mark",
    "Donald", "Steven", "Paul", "Andrew", "Joshua", "Kenneth", "Kevin", "Brian",
    "George", "Edward", "Ronald", "Timothy", "Jason", "Jeffrey", "Ryan", "Jacob",
    "Gary", "Nicholas", "Eric", "Jonathan", "Stephen", "Larry", "Justin", "Scott",
    "Brandon", "Benjamin", "Samuel", "Frank", "Gregory", "Raymond", "Patrick",
    "Alexander", "Jack", "Dennis", "Jerry", "Tyler", "Aaron", "Henry", "Douglas",
    "Peter", "Walter", "Nathan", "Zachary", "Kyle", "Harold", "Carl", "Arthur",
    "Roger", "Albert", "Joe", "Louis", "Russell", "Roy", "Eugene", "Ralph"
}

NameGenerator.femaleFirstNames = {
    "Mary", "Patricia", "Jennifer", "Linda", "Barbara", "Elizabeth", "Susan",
    "Jessica", "Sarah", "Karen", "Nancy", "Lisa", "Margaret", "Betty", "Sandra",
    "Ashley", "Dorothy", "Kimberly", "Emily", "Donna", "Michelle", "Carol",
    "Amanda", "Melissa", "Deborah", "Stephanie", "Rebecca", "Laura", "Sharon",
    "Cynthia", "Kathleen", "Amy", "Shirley", "Angela", "Helen", "Anna", "Brenda",
    "Pamela", "Nicole", "Samantha", "Katherine", "Emma", "Ruth", "Christine",
    "Catherine", "Debra", "Rachel", "Carolyn", "Janet", "Virginia", "Maria",
    "Heather", "Diane", "Julie", "Joyce", "Victoria", "Kelly", "Christina",
    "Lauren", "Joan", "Evelyn", "Judith", "Megan", "Cheryl", "Andrea", "Hannah",
    "Jacqueline", "Martha", "Gloria", "Teresa", "Ann", "Sara", "Madison"
}

NameGenerator.lastNames = {
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis",
    "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson",
    "Thomas", "Taylor", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson",
    "White", "Harris", "Sanchez", "Clark", "Ramirez", "Lewis", "Robinson", "Walker",
    "Young", "Allen", "King", "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores",
    "Green", "Adams", "Nelson", "Baker", "Hall", "Rivera", "Campbell", "Mitchell",
    "Carter", "Roberts", "Turner", "Phillips", "Evans", "Parker", "Collins", "Edwards",
    "Stewart", "Morris", "Murphy", "Cook", "Rogers", "Morgan", "Peterson", "Cooper",
    "Reed", "Bailey", "Bell", "Gomez", "Kelly", "Howard", "Ward", "Cox", "Diaz",
    "Richardson", "Wood", "Watson", "Brooks", "Bennett", "Gray", "James", "Reyes",
    "Cruz", "Hughes", "Price", "Myers", "Long", "Foster", "Sanders", "Ross", "Jenkins",
    "Powell", "Sullivan", "Russell", "Henderson", "Coleman", "Patterson", "Perry"
}

-- Animal names (for cows and chickens)
NameGenerator.animalNames = {
    "Bessie", "Daisy", "Buttercup", "Clover", "Molly", "Betty", "Rosie", "Bella",
    "Penny", "Lucy", "Ginger", "Cookie", "Nugget", "Peaches", "Goldie", "Honey",
    "Cinnamon", "Butterscotch", "Patches", "Spot", "Snowball", "Shadow", "Misty"
}

-- Generate a random male name
function NameGenerator.GenerateMaleName()
    local firstName = NameGenerator.maleFirstNames[math.random(#NameGenerator.maleFirstNames)]
    local lastName = NameGenerator.lastNames[math.random(#NameGenerator.lastNames)]
    return firstName .. " " .. lastName
end

-- Generate a random female name
function NameGenerator.GenerateFemaleName()
    local firstName = NameGenerator.femaleFirstNames[math.random(#NameGenerator.femaleFirstNames)]
    local lastName = NameGenerator.lastNames[math.random(#NameGenerator.lastNames)]
    return firstName .. " " .. lastName
end

-- Generate a random name based on gender
function NameGenerator.GenerateName(gender)
    if gender == "male" then
        return NameGenerator.GenerateMaleName()
    elseif gender == "female" then
        return NameGenerator.GenerateFemaleName()
    else
        -- Random gender
        if math.random() > 0.5 then
            return NameGenerator.GenerateMaleName()
        else
            return NameGenerator.GenerateFemaleName()
        end
    end
end

-- Generate an animal name
function NameGenerator.GenerateAnimalName()
    return NameGenerator.animalNames[math.random(#NameGenerator.animalNames)]
end

-- Generate a random gender
function NameGenerator.GenerateGender()
    if math.random() > 0.5 then
        return "male"
    else
        return "female"
    end
end
