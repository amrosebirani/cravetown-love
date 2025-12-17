Multi-Level Vector Architecture

  Hierarchical Structure:

  Level 1: Top-Level Craving (9 dimensions)
      ↓
  Level 2: Sub-Categories (variable dimensions per craving)
      ↓
  Level 3: Tags (finest granularity for substitution)

  ---
  Expanded Vector Structure

  Level 1: Coarse Vector (9D)

  Used for: Overall satisfaction display, emigration decisions, class comparisons

  Level 2: Fine Vector (40-50D)

  Used for: Precise satisfaction calculation, substitution matching, consumption logic

  Level 3: Tag Set

  Used for: Exact substitution rules, commodity filtering, special conditions

  ---
  Detailed Sub-Category Breakdown:

  1. BIOLOGICAL (8 sub-dimensions)

  biological_nutrition_grain        (wheat, rice, barley)
  biological_nutrition_protein      (meat, fish, eggs)
  biological_nutrition_produce      (vegetables, fruit)
  biological_hydration              (water, beverages)
  biological_health_medicine        (medicine, healing items)
  biological_health_hygiene         (soap, clean water)
  biological_energy_rest            (sleep quality from furniture)
  biological_energy_stimulation     (coffee, tea)

  2. SAFETY (5 sub-dimensions)

  safety_security_law               (police, guards, justice)
  safety_security_defense           (walls, weapons, fortifications)
  safety_shelter_housing            (home, roof quality)
  safety_shelter_warmth             (heating, insulation)
  safety_fire_protection            (fire brigade, safety measures)

  3. TOUCH (6 sub-dimensions)

  touch_clothing_everyday           (basic clothes, work clothes)
  touch_clothing_formal             (fine clothes, formal wear)
  touch_furniture_functional        (bed, chair, table)
  touch_furniture_decorative        (luxury furniture, soft furnishings)
  touch_textiles_bedding            (sheets, blankets, pillows)
  touch_sensory_luxury              (perfumes, soft fabrics, flowers)

  4. PSYCHOLOGICAL (7 sub-dimensions)

  psychological_education_books     (books, scrolls, written knowledge)
  psychological_education_formal    (school, tutoring, lectures)
  psychological_entertainment_arts  (paintings, music, theater)
  psychological_entertainment_games (games, sports, leisure)
  psychological_purpose_work        (meaningful employment)
  psychological_purpose_religion    (church, prayer, spirituality)
  psychological_purpose_civic       (town participation, voting)

  5. SOCIAL STATUS (6 sub-dimensions)

  status_reputation_display         (visible wealth items)
  status_reputation_title           (rank, position, honors)
  status_wealth_precious            (gold, silver, gems)
  status_wealth_property            (manor size, land ownership)
  status_service_servants           (having servants, staff)
  status_fashion_luxury             (luxury clothes, accessories)

  6. SOCIAL CONNECTION (5 sub-dimensions)

  social_friendship_casual          (tavern visits, informal gatherings)
  social_friendship_intimate        (close friends, confidants)
  social_community_church           (religious community)
  social_community_civic            (town meetings, public events)
  social_family_bonds               (spouse, children, relatives)

  7. EXOTIC GOODS (4 sub-dimensions)

  exotic_food_spices                (pepper, cinnamon, rare spices)
  exotic_food_imports               (foreign fruits, wines)
  exotic_items_textiles             (silk, rare fabrics)
  exotic_items_novelty              (foreign curiosities, rare goods)

  8. SHINY OBJECTS (4 sub-dimensions)

  shiny_precious_gold               (gold items, gold coins)
  shiny_precious_silver             (silver items, silverware)
  shiny_precious_gems               (diamonds, rubies, gems)
  shiny_decorative_art              (sculptures, fine decorations)

  9. VICE (5 sub-dimensions)

  vice_alcohol_beer                 (beer, ale)
  vice_alcohol_spirits              (wine, whiskey, strong drinks)
  vice_gambling                     (dice, cards, betting)
  vice_indulgence_sweets            (cakes, pastries, desserts)
  vice_indulgence_excess            (overeating, luxury consumption)

  Total: 50 fine-grained dimensions

  ---
  Data Model with Multi-Level Vectors

  Character State:

  {
    "characterId": "char_001",
    "class": "middle",
    "vocation": "baker",
    "traits": ["frugal", "intellectual"],

    "satisfaction": {
      "coarse": [65, 70, 45, 30, 20, 55, 10, 15, 40],
      "fine": [
        68, 62, 65,   // biological_nutrition (grain, protein, produce)
        80,           // biological_hydration
        50, 60,       // biological_health (medicine, hygiene)
        40, 35,       // biological_energy (rest, stimulation)

        70, 65,       // safety_security (law, defense)
        75, 60, 55,   // safety_shelter (housing, warmth, fire)

        40, 30,       // touch_clothing (everyday, formal)
        45, 35,       // touch_furniture (functional, decorative)
        50, 25,       // touch_textiles, touch_sensory

        // ... all 50 dimensions
      ]
    },

    "cravingVector": {
      "coarse": [4.0, 3.0, 1.5, 2.0, 1.5, 3.0, 1.0, 0.7, 1.0],
      "fine": [
        4.5, 3.5, 4.0,  // biological nutrition cravings
        3.0,            // hydration
        2.0, 2.5,       // health
        2.0, 1.5,       // energy

        3.0, 2.5,       // safety security
        3.5, 2.0, 2.0,  // shelter

        // ... all 50 dimensions
      ]
    }
  }

  Commodity Fulfillment Vectors:

  {
    "commodityId": "wheat",
    "name": "Wheat",

    "fulfillmentVector": {
      "coarse": [8, 0, 0, 0, 0, 0, 0, 0, 0],

      "fine": {
        "biological_nutrition_grain": 12,
        "biological_nutrition_protein": 1,
        "biological_energy_stimulation": 0.5,
        "touch_clothing_everyday": 0,
        // ... rest are 0
      }
    },

    "tags": ["grain", "nutrition", "basic_food", "raw_material"],

    "qualityMultipliers": {
      "poor": 0.6,
      "basic": 1.0,
      "good": 1.3,
      "luxury": 1.5
    }
  }

  {
    "commodityId": "luxury_clothes",
    "name": "Luxury Clothes",

    "fulfillmentVector": {
      "coarse": [0, 0, 12, 1, 8, 2, 0, 0, 0],

      "fine": {
        "touch_clothing_formal": 20,
        "touch_clothing_everyday": 5,
        "touch_sensory_luxury": 8,
        "psychological_entertainment_arts": 2,
        "status_reputation_display": 15,
        "status_fashion_luxury": 25,
        "social_friendship_casual": 3,
        // ... rest are 0
      }
    },

    "tags": ["clothing", "luxury", "status_display", "fashion"],

    "qualityMultipliers": {
      "good": 0.8,
      "luxury": 1.0,
      "masterwork": 1.5
    }
  }

  {
    "commodityId": "book",
    "name": "Book",

    "fulfillmentVector": {
      "coarse": [0, 0, 0, 20, 1, 3, 2, 0, 0],

      "fine": {
        "psychological_education_books": 35,
        "psychological_entertainment_arts": 10,
        "psychological_purpose_work": 5,
        "status_reputation_display": 3,
        "social_friendship_intimate": 5,
        "exotic_items_novelty": 3,
        // ... rest are 0
      }
    },

    "tags": ["education", "books", "culture", "knowledge"],
    "durability": "durable",
    "reusableValue": 0.1
  }

  ---
  Substitution with Fine Vectors

  High-Precision Substitution:

  def find_best_substitute(desired_commodity, available_commodities, character):
      """
      Find best substitute using fine-grained vector similarity
      """
      desired_vec = desired_commodity.fulfillmentVector.fine

      scores = []
      for candidate in available_commodities:
          candidate_vec = candidate.fulfillmentVector.fine

          # Calculate weighted similarity based on character's current needs
          satisfaction_gap = max(0, 50 - character.satisfaction.fine)
          weights = normalize(satisfaction_gap)  # Prioritize biggest gaps

          # Weighted cosine similarity
          similarity = weighted_cosine_similarity(
              desired_vec,
              candidate_vec,
              weights
          )

          # Tag overlap bonus
          tag_overlap = len(set(desired_commodity.tags) & set(candidate.tags))
          tag_bonus = 0.03 * tag_overlap

          # Class acceptability check
          if not is_acceptable_for_class(candidate, character.class):
              similarity *= 0.5  # Penalty but not elimination

          scores.append({
              'commodity': candidate,
              'score': similarity + tag_bonus
          })

      return sorted(scores, key=lambda x: x['score'], reverse=True)

  Example Substitution Scenarios:

  Scenario 1: Grain Substitution
  Desired: wheat
  Character needs: [biological_nutrition_grain: 30/100]

  Available options:
  - rice:   similarity = 0.95 (almost identical nutrition_grain vector)
  - barley: similarity = 0.92 (slightly different profile)
  - bread:  similarity = 0.88 (processed, different vector but fulfills grain need)
  - potato: similarity = 0.65 (different sub-category: produce vs grain)

  Scenario 2: Clothing Substitution
  Desired: luxury_clothes
  Character needs: [touch_clothing_formal: 20/100, status_fashion_luxury: 15/100]

  Available options:
  - fine_clothes:    similarity = 0.85 (good formal, less status)
  - simple_clothes:  similarity = 0.40 (fulfills clothing but wrong sub-category)
  - jewelry:         similarity = 0.55 (high status, zero touch_clothing)

  Scenario 3: Entertainment Substitution
  Desired: theater_ticket
  Character needs: [psychological_entertainment_arts: 25/100]

  Available options:
  - book:           similarity = 0.70 (different entertainment, fulfills psychological)
  - tavern_visit:   similarity = 0.45 (entertainment but social_connection focus)
  - painting:       similarity = 0.75 (same arts sub-category)

  ---
  Aggregation Functions

  Fine → Coarse (Roll-up):

  def calculate_coarse_satisfaction(fine_vector):
      """
      Aggregate fine satisfaction into coarse 9D vector
      """
      coarse = [0] * 9

      # Biological (indices 0-7 of fine → index 0 of coarse)
      coarse[0] = mean(fine_vector[0:8])

      # Safety (indices 8-12 of fine → index 1 of coarse)
      coarse[1] = mean(fine_vector[8:13])

      # Touch (indices 13-18 → index 2)
      coarse[2] = mean(fine_vector[13:19])

      # And so on...

      return coarse

  Coarse → Fine (Distribute):

  def distribute_coarse_to_fine(coarse_modifier, distribution_weights):
      """
      When we have a coarse modifier (e.g., from enablement),
      distribute it to fine dimensions based on weights
      """
      fine_modifier = [0] * 50

      # Example: +2 to biological (coarse[0])
      # Distribute across 8 biological sub-dimensions
      biological_modifier = 2.0
      biological_weights = [0.2, 0.15, 0.15, 0.1, 0.15, 0.1, 0.1, 0.05]

      for i in range(8):
          fine_modifier[i] = biological_modifier * biological_weights[i]

      return fine_modifier

  ---
  Performance Considerations

  Storage:
  - Coarse vectors: 9 floats × 100 chars = ~4KB
  - Fine vectors: 50 floats × 100 chars = ~20KB
  - Totally manageable

  Computation:
  - Per-cycle decay: 100 chars × 50D vector subtraction = trivial
  - Substitution search: ~133 commodities × 50D dot product = ~6,650 operations
  - Still very fast, can optimize with spatial indexing if needed

  ---
  Recommended Approach:

  1. Define the 50 fine dimensions with clear categories
  2. Map all 133 commodities to fine fulfillment vectors
  3. Store both coarse and fine in character state
  4. Use fine for calculations, coarse for display/decisions
  5. Pre-compute commodity similarity matrix (133×133) for fast substitution
