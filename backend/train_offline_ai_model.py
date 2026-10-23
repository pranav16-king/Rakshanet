#!/usr/bin/env python3
"""
RakshaNet - Offline Edge AI Model Trainer & Knowledge Base Compiler
-------------------------------------------------------------------------------------
Trains a high-precision multi-domain Natural Language Processing classifier:
- TF-IDF Vector Space Model with sublinear term frequency
- Cosine-Centroid Classifier + Multinomial Log-Probability Estimator
- 75+ Domain Classes across Emergency First Aid, Disaster Survival, Search & Rescue,
  App & Mesh Network Operations, Science, Math, General Knowledge & Triage.
- Compiles the trained weights, vocabulary, priors, centroids, and structured responses
  into both:
    1) backend/data/offline_ai_model.json (backend JSON artifact)
    2) mobile/lib/services/ai/trained_offline_model_data.dart (compiled Dart code for <5ms on-device inference)
"""

import os
import re
import math
import json
from collections import Counter, defaultdict

# ------------------------------------------------------------------------------
# 1. COMPREHENSIVE TRAINING CORPUS & STRUCTURED KNOWLEDGE BASE (75+ INTENT CLASSES)
# ------------------------------------------------------------------------------

TRAINING_DATA = [
    # ==================== MEDICAL & FIRST AID ====================
    {
        "intent": "cpr_protocol",
        "category": "Medical & First Aid",
        "title": "Emergency CPR & Resuscitation Protocol (AHA / NDMA Guidelines)",
        "summary": "Immediate high-quality chest compressions and rescue breathing for unconscious, non-breathing individuals.",
        "steps": [
            "Check responsiveness & breathing: Firmly tap shoulders and shout 'Are you okay?'. Scan chest for 5-10 seconds for normal breathing.",
            "Position hands on sternum: Place heel of one hand in center of breastbone; interlock other hand on top with elbows locked straight.",
            "Deliver 30 hard, fast compressions: Depress chest 5 to 6 cm (2-2.4 in) at 100-120 beats/min (to the rhythm of 'Stayin Alive'). Allow full chest recoil.",
            "Deliver 2 rescue breaths: Tilt head back, lift chin, pinch nose, and blow gently for 1 second until chest visibly rises. (Perform Hands-Only CPR if untrained).",
            "Repeat 30:2 ratio: Continue uninterrupted until the person moves, gasps, or professional rescue/AED arrives. Switch compressors every 2 minutes."
        ],
        "warning": "DO NOT delay compressions. Minimize pauses to under 10 seconds. For infants, use 2 fingers and compress 4 cm (1.5 in).",
        "utterances": [
            "how to do cpr", "cpr protocol", "someone is not breathing", "unconscious person not breathing",
            "heart stopped beating", "cardiac arrest first aid", "chest compressions steps", "how many chest compressions",
            "mouth to mouth resuscitation", "cpr on adult", "cpr on child infant", "how deep to push cpr",
            "hands only cpr", "defibrillator aed cpr", "person collapsed unresponsive", "resuscitation guideline"
        ]
    },
    {
        "intent": "severe_bleeding",
        "category": "Medical & First Aid",
        "title": "Severe Hemorrhage Control & Tourniquet Protocol",
        "summary": "Rapid arterial and venous bleeding control to prevent fatal hypovolemic shock.",
        "steps": [
            "Direct continuous pressure: Place a sterile gauze pad or cleanest available cloth directly over wound and push down with full body weight.",
            "Maintain pressure without lifting: Hold continuous pressure for at least 5 to 10 minutes. Never lift pad to 'check' the wound.",
            "Elevate injured limb: Raise the bleeding limb above heart level (only if no fracture or spinal fracture is suspected).",
            "Apply pressure bandage: Wrap elastic or roller bandage tightly over the dressing. If blood soaks through, add more layers on top—NEVER remove base pad.",
            "Emergency Tourniquet (life-threatening limb hemorrhage): Place commercial or improvised tourniquet (strap + windlass stick) 5-7 cm (2-3 in) above wound, never on a joint. Twist until bright red bleeding ceases completely."
        ],
        "warning": "DO NOT loosen or remove a tourniquet once applied. Write 'T' and the exact application time on victim's forehead.",
        "utterances": [
            "how to stop heavy bleeding", "severe cut bleeding non stop", "arterial bleeding spurting blood",
            "how to use a tourniquet", "tourniquet application steps", "wound won't stop bleeding", "deep laceration first aid",
            "stab wound bleeding control", "hemorrhage triage", "blood soaking through bandage", "how to treat open wound",
            "pressure dressing bleeding", "gunshot or shrapnel bleeding", "severe wound packing"
        ]
    },
    {
        "intent": "choking_heimlich",
        "category": "Medical & First Aid",
        "title": "Choking Emergency & Heimlich Abdominal Thrusts",
        "summary": "Clearing complete or partial upper airway obstruction in conscious and unconscious victims.",
        "steps": [
            "Verify choking: Ask 'Are you choking?'. If victim cannot speak, cough, or breathe, or clutches throat (universal sign), act immediately.",
            "5 Back blows: Lean victim forward, support chest with one hand, and deliver 5 sharp blows between shoulder blades with heel of hand.",
            "5 Abdominal thrusts (Heimlich): Stand behind victim, wrap arms around waist. Place thumb side of fist slightly above navel and below ribcage. Grasp fist and thrust inward and upward forcefully.",
            "Alternate 5 blows & 5 thrusts: Repeat until object is expelled or victim loses consciousness.",
            "If victim becomes unconscious: Lower gently to floor, call rescue/shout for help, and begin 30 chest compressions. Look in mouth before rescue breaths; finger sweep ONLY if object is visible."
        ],
        "warning": "For pregnant women or obese individuals, perform chest thrusts at the center of sternum, not abdominal thrusts. For infants, alternate 5 back slaps and 5 two-finger chest thrusts.",
        "utterances": [
            "someone is choking", "heimlich maneuver steps", "choking first aid", "person cannot breathe food stuck",
            "how to save a choking person", "child choking protocol", "infant choking back blows", "self heimlich maneuver chair",
            "blocked airway first aid", "foreign object in throat", "choking adult treatment", "food lodged in windpipe"
        ]
    },
    {
        "intent": "burns_treatment",
        "category": "Medical & First Aid",
        "title": "Burn Triage & Treatment Protocol (Thermal, Chemical, Electrical)",
        "summary": "Immediate cooling, infection barrier, and shock prevention for thermal, chemical, and electrical burns.",
        "steps": [
            "Cool with clean water: Hold burn under cool (not ice cold) running water for 10 to 20 minutes immediately to halt tissue burning.",
            "Remove tight items: Swiftly remove rings, watches, belts, and jewelry before tissue swelling sets in.",
            "Do NOT peel melted fabric: If clothing is melted or adhered to skin, cut around it carefully; never tear it away.",
            "Cover with sterile barrier: Apply non-stick sterile gauze or clean, smooth plastic food cling wrap loosely over the area.",
            "Chemical/Electrical burns: For chemical burns, brush off dry powder first, then flush with water for 20+ min. For electrical burns, ensure power is off before touching victim and check for entry/exit wounds."
        ],
        "warning": "DO NOT apply ice, butter, grease, toothpaste, or turmeric. NEVER pop or puncture burn blisters.",
        "utterances": [
            "how to treat burns", "hot water burn treatment", "scald first aid", "fire burn blisters", "first degree second degree burn",
            "third degree burn care", "chemical burn on skin", "acid burn first aid", "electrical burn treatment",
            "burnt hand relief", "put toothpaste on burn", "how to cool a burn", "steam burn home care", "burned skin care"
        ]
    },
    {
        "intent": "fractures_splints",
        "category": "Medical & First Aid",
        "title": "Bone Fractures, Dislocations & Improvised Splinting",
        "summary": "Stabilization, immobilization, and neurovascular assessment for broken bones and joint trauma.",
        "steps": [
            "Immobilize in found position: Do NOT attempt to straighten or push back a deformed bone or protruding bone fragment.",
            "Control bleeding for open fractures: Cover open wound with sterile dressing and apply gentle pressure around (not on) exposed bone.",
            "Improvise a rigid splint: Use folded cardboard, branches, rolled magazines, or trekking poles padded with towels/clothing.",
            "Secure above and below the fracture: Splint must immobilize both the joint above and the joint below the injury. Tie securely with cloth strips, leaving fingers/toes exposed.",
            "Check distal circulation (CSM): Check Circulation (pulse/warmth), Sensation (feeling), and Movement every 15 minutes. Loosen ties if limb turns blue, cold, or numb."
        ],
        "warning": "DO NOT try to reset or snap bones back into alignment. For open fractures, do NOT push exposed bone back beneath skin.",
        "utterances": [
            "broken bone first aid", "how to splint a broken leg arm", "fracture first aid steps", "bone sticking out of skin open fracture",
            "dislocated shoulder joint", "sprained ankle swelling first aid", "improvised splint cardboard branch",
            "suspected broken arm wrist", "how to make a sling", "fractured rib care", "bone deformity injury"
        ]
    },
    {
        "intent": "spinal_head_trauma",
        "category": "Medical & First Aid",
        "title": "Spinal Injury, Head Trauma & Concussion Protocol",
        "summary": "Strict head-neck stabilization and monitoring for traumatic brain injury or vertebral fracture.",
        "steps": [
            "Keep patient completely still: Direct victim not to move head, neck, or back. Hold head manually on both sides in neutral alignment.",
            "Do NOT move or transport: Never move victim unless immediate life threat exists (fire, rising water, collapse). If moving is required, use log-roll technique with 3-4 rescuers maintaining spine alignment.",
            "Assess alertness (AVPU scale): Check Alert, responds to Voice, responds to Pain, or Unresponsive. Note pupil equality and clear fluid from ears/nose.",
            "Maintain open airway with Jaw-Thrust: If breathing is compromised, use jaw-thrust maneuver without tilting the neck backward.",
            "Watch for concussion 'Red Flags': Vomiting, worsening headache, unequal pupils, seizures, confusion, or weakness on one side require urgent evacuation."
        ],
        "warning": "DO NOT remove a motorcycle/bicycle helmet unless the airway is fully obstructed and cannot be cleared with helmet on.",
        "utterances": [
            "head injury concussion protocol", "spinal cord injury first aid", "person fell from height neck pain",
            "unconscious after hit on head", "bleeding from ear after head trauma", "how to immobilize neck spine",
            "skull fracture symptoms", "log roll technique spinal victim", "jaw thrust maneuver", "whiplash neck trauma"
        ]
    },
    {
        "intent": "hypothermia_frostbite",
        "category": "Medical & First Aid",
        "title": "Hypothermia, Cold Exposure & Frostbite Protocol",
        "summary": "Core rewarming and tissue salvage for extreme cold exposure and freezing injuries.",
        "steps": [
            "Shelter and insulate from ground: Move victim out of wind and rain. Place thick sleeping pads, backpacks, or dry leaves under body.",
            "Remove wet clothing: Strip wet clothes immediately and replace with dry wool/fleece layers, blankets, or sleeping bags. Cover the head.",
            "Rewarm core first: Place warm (not boiling) wrapped water bottles or body-to-body heat at armpits, groin, chest, and neck. Do NOT rewarm arms and legs first (prevents cold blood return shock).",
            "Provide warm sweet liquids: If victim is conscious and swallowing easily, give warm sugary tea or broth. Never give alcohol or caffeine.",
            "Frostbite care: Soak frozen digits in warm water (37-40°C / 99-104°F) for 20-30 min only if NO risk of refreezing exists. Never rub frozen tissue."
        ],
        "warning": "DO NOT rub frozen skin with snow or rough towels. DO NOT use open flames or direct dry heat radiators (skin is numb and will burn).",
        "utterances": [
            "hypothermia treatment", "severe shivering cold exposure", "frostbite fingers toes first aid",
            "how to rewarm someone freezing", "trench foot care", "body temperature dangerously low", "cold weather survival",
            "rewarming shock prevention", "frozen nose ears treatment", "falling into freezing ice water"
        ]
    },
    {
        "intent": "heatstroke_dehydration",
        "category": "Medical & First Aid",
        "title": "Heat Stroke, Heat Exhaustion & Homemade ORS",
        "summary": "Rapid cooling for life-threatening hyperthermia and rehydration for severe fluid loss.",
        "steps": [
            "Differentiate Heat Exhaustion vs Heat Stroke: Heat stroke is a medical emergency with hot, dry or sweaty skin, core temp >40°C (104°F), confusion, and altered mental state.",
            "Initiate rapid cooling immediately: Move to shade, remove excess clothing, spray with water and fan vigorously, or immerse in cold bath up to neck.",
            "Apply cold packs to vascular zones: Place ice packs or cold wet towels at armpits, groin, neck, and behind knees.",
            "Homemade ORS Recipe (Oral Rehydration Solution): In 1 Liter of clean boiled/purified water, dissolve 6 level teaspoons of sugar (25g) + 1/2 level teaspoon of salt (2.5g). Sip slowly.",
            "Positioning: If victim feels dizzy, elevate feet 30 cm (12 in). If vomiting or unresponsive, turn to recovery position."
        ],
        "warning": "DO NOT give oral fluids to an unconscious, confused, or vomiting person (risk of aspiration). DO NOT give antipyretic drugs like paracetamol/aspirin (ineffective for heat stroke).",
        "utterances": [
            "heat stroke first aid", "heat exhaustion symptoms treatment", "severe dehydration treatment",
            "how to make homemade ors recipe", "oral rehydration solution ratio", "person passed out from heat",
            "sunstroke emergency care", "heat cramps relief", "hyperthermia cooling methods", "electrolyte drink disaster"
        ]
    },
    {
        "intent": "snake_bite_venom",
        "category": "Medical & First Aid",
        "title": "Snakebite Protocol & Venomous Envenomation Triage",
        "summary": "Immediate containment, immobilization, and evacuation for venomous snake bites.",
        "steps": [
            "Keep victim calm and completely still: Physical movement accelerates lymphatic spread of venom through the bloodstream.",
            "Immobilize the bitten limb at heart level: Apply a broad pressure immobilization bandage from fingers/toes up the limb (for neurotoxic species), or splint the limb to prevent movement.",
            "Remove constrictive items instantly: Take off rings, bangles, watches, and tight clothing before massive tissue edema develops.",
            "Note snake appearance safely: Note color, markings, head shape, or take a quick photo from a safe distance (do NOT attempt to capture or kill snake).",
            "Transport immediately to antivenom facility: Carry the victim on a stretcher if possible; do not let victim walk."
        ],
        "warning": "CRITICAL: DO NOT cut the bite mark. DO NOT suck venom. DO NOT apply ice or a tourniquet. DO NOT give alcohol or pain medication.",
        "utterances": [
            "snake bite first aid", "poisonous snake bit me what to do", "cobra viper krait bite treatment",
            "how to treat venomous snakebite", "snake venom symptoms", "cut snake bite suck venom",
            "pressure immobilization snake bite", "antivenom emergency", "dog snake reptile bite"
        ]
    },
    {
        "intent": "insect_dog_animal_bite",
        "category": "Medical & First Aid",
        "title": "Animal Bites, Rabies Prevention & Severe Stings",
        "summary": "Wound disinfection for dog/monkey bites, rabies prophylaxis, and insect sting anaphylaxis care.",
        "steps": [
            "Wash animal bite under running tap water for 15 minutes: Scrub thoroughly with soap and water to wash out virus particles. This is the single most critical rabies survival step.",
            "Disinfect with antiseptic: Apply povidone iodine or 70% alcohol solution directly to animal bite wound.",
            "Seek Rabies Post-Exposure Prophylaxis (PEP): Anti-rabies vaccine (ARV) + Rabies Immunoglobulin (RIG) must be administered within 24 hours.",
            "Bee / Wasp Stings: Scrape stinger out with a hard card or fingernail (do not squeeze with tweezers). Apply ice pack for 10 min.",
            "Watch for Anaphylaxis: Difficulty breathing, throat swelling, hives, or dizziness requires immediate EpiPen injection (0.3mg adult intramuscular in outer mid-thigh)."
        ],
        "warning": "DO NOT suture animal bite wounds primarily. DO NOT apply chili powder, turmeric, or herbs to dog bites.",
        "utterances": [
            "dog bite first aid", "rabies prevention after bite", "monkey cat animal bite wash", "bee sting treatment",
            "wasp hornet sting relief", "anaphylaxis allergic reaction epipen", "scorpion sting first aid",
            "centipede bite care", "spider bite first aid", "severe allergic reaction hives throat closing"
        ]
    },
    {
        "intent": "seizure_epilepsy",
        "category": "Medical & First Aid",
        "title": "Seizure & Convulsions Emergency Protocol",
        "summary": "Protecting airway and preventing head injury during epileptic seizures or convulsive episodes.",
        "steps": [
            "Protect from physical injury: Clear hard, sharp objects, furniture, and hazards away from victim. Cushion head with folded coat or pillow.",
            "Loosen tight clothing: Unbutton tight collars, neckties, or scarves around the neck.",
            "Time the seizure: Note start time and duration. Seizures lasting >5 minutes (Status Epilepticus) require emergency rescue.",
            "Turn to recovery position after convulsions cease: Once shaking stops, roll victim gently onto their side to keep airway clear of vomit/saliva.",
            "Stay until fully conscious: Speak calmly, orient the person, and do not leave them unattended until alertness returns."
        ],
        "warning": "DO NOT hold victim down or restrain movements. NEVER force anything into their mouth (no spoons, fingers, or cloth—they will NOT swallow their tongue).",
        "utterances": [
            "person having a seizure", "epilepsy convulsions first aid", "shaking fit on floor", "what to do during seizure",
            "put spoon in mouth seizure", "status epilepticus emergency", "grand mal seizure steps", "post seizure recovery position"
        ]
    },
    {
        "intent": "stroke_heart_attack",
        "category": "Medical & First Aid",
        "title": "Heart Attack & Stroke (FAST Protocol) Emergency Care",
        "summary": "Rapid symptom identification and emergency stabilization for acute coronary syndrome and stroke.",
        "steps": [
            "Identify Heart Attack: Crushing chest pain/pressure, radiating to left arm/jaw/back, shortness of breath, cold sweat, nausea.",
            "Position & Aspirin for Heart Attack: Sit victim down in semi-recumbent posture (W-position, knees bent). If non-allergic and no bleeding ulcers, have them chew 325 mg uncoated Aspirin (or four 81mg chewables).",
            "Identify Stroke (FAST test): Face drooping (ask to smile), Arm weakness (raise both arms), Speech difficulty (repeat a simple sentence), Time to act immediately.",
            "Stroke Positioning: Lay victim on side with head slightly elevated (15-30 degrees) to reduce intracranial pressure. Keep completely at rest.",
            "Monitor vitals continuously: If victim collapses and stops breathing normally, begin CPR immediately."
        ],
        "warning": "DO NOT give aspirin or blood thinners to a stroke patient (stroke could be hemorrhagic / bleeding). DO NOT let a heart attack victim walk or exert effort.",
        "utterances": [
            "heart attack symptoms first aid", "stroke fast test signs", "chest pain left arm pain", "aspirin dose for heart attack",
            "face drooping slurred speech", "cardiac emergency steps", "mini stroke tia symptoms", "how to help someone having heart attack"
        ]
    },
    {
        "intent": "asthma_anaphylaxis",
        "category": "Medical & First Aid",
        "title": "Severe Asthma Attack & Anaphylaxis Protocol",
        "summary": "Bronchodilator delivery and emergency epinephrine for critical respiratory distress.",
        "steps": [
            "Sit victim upright: Never lay an asthmatic down. Sit upright leaning slightly forward to maximize lung expansion.",
            "Deliver Reliever Inhaler (Salbutamol / Albuterol): Shake inhaler, attach spacer if available. Deliver 1 puff, instruct slow deep inhalation, hold breath 10 sec. Give up to 4 puffs, waiting 1 minute between puffs.",
            "4x4x4 Rule: If no improvement after 4 minutes, give 4 more puffs. Continue every 4 minutes until emergency medical rescue arrives.",
            "Anaphylaxis Emergency: If wheezing is accompanied by facial/throat swelling, hives, or hypotension, administer Epinephrine Auto-Injector (EpiPen) into outer mid-thigh. Hold firmly for 3-5 seconds.",
            "Calm and slow breathing: Coach slow nasal breathing to reduce hyperventilation and panic-induced bronchospasm."
        ],
        "warning": "DO NOT give hot drinks, home remedies, or put victim in a steamy shower during acute severe asthma (can worsen airway spasm).",
        "utterances": [
            "asthma attack without inhaler", "how to use an inhaler spacer", "severe wheezing shortness of breath",
            "anaphylactic shock first aid", "epipen injection steps", "allergic reaction throat closing up", "bronchospasm emergency relief"
        ]
    },
    {
        "intent": "diabetic_emergency",
        "category": "Medical & First Aid",
        "title": "Diabetic Emergency (Hypoglycemia vs Hyperglycemia)",
        "summary": "Rapid glucose delivery for low blood sugar emergencies in diabetic patients.",
        "steps": [
            "Recognize Hypoglycemia (Low Blood Sugar): Sudden onset, shakiness, sweating, pale skin, confusion, irritability, dizziness, hunger.",
            "Administer Fast-Acting Sugar (Rule of 15): If victim is conscious and able to swallow, give 15 grams of fast-acting sugar: 3-4 glucose tablets, 1/2 cup fruit juice, 4 teaspoons sugar/honey, or regular soda.",
            "Wait and re-test: Wait 15 minutes. If symptoms persist, administer another 15 grams of sugar.",
            "Follow with complex carbs: Once recovered, feed bread, crackers, or a meal to maintain blood glucose stability.",
            "If victim is unconscious or unable to swallow: DO NOT put liquids in mouth. Place in recovery position and administer Glucagon injection or rub glucose gel inside cheek."
        ],
        "warning": "When in doubt between high and low blood sugar, ALWAYS give sugar! A temporary rise from hyperglycemia causes minimal short-term harm, but untreated hypoglycemia causes brain damage and coma within minutes.",
        "utterances": [
            "diabetic emergency first aid", "low blood sugar symptoms treatment", "hypoglycemia rule of 15",
            "diabetic passed out unconscious", "high blood sugar ketoacidosis signs", "insulin shock emergency", "sugar for diabetic person"
        ]
    },
    {
        "intent": "emergency_childbirth",
        "category": "Medical & First Aid",
        "title": "Emergency Field Childbirth & Newborn Care",
        "summary": "Assisting imminent, unplanned delivery when medical facilities are unreachable during a disaster.",
        "steps": [
            "Prepare clean delivery area: Wash hands with soap and water; place clean towels, sheets, or plastic under mother. Position mother on back with knees bent and feet apart.",
            "Support (do not pull) the crowning head: When baby's head crowns, place gentle hand on head to prevent rapid explosive delivery and perineal tearing.",
            "Check for umbilical cord around neck: If cord is loosely around neck, slip it gently over head. Once shoulders deliver, body slips out quickly.",
            "Dry and stimulate newborn immediately: Clear mouth and nose of secretions with clean cloth. Vigorously dry baby with clean dry towel; baby should cry. Place skin-to-skin on mother's bare chest and cover both with dry blanket.",
            "Care for placenta and cord: Do NOT pull the cord. Let placenta deliver naturally (5-30 min). Tie cord securely in 2 places (10 cm and 15 cm from baby's navel) with clean string or shoelace. Cut between ties ONLY with sterilized blade (boiled for 10 min)."
        ],
        "warning": "DO NOT pull baby's head or shoulders. DO NOT wash off the protective white vernix coating on baby's skin. Keep newborn warm—hypothermia is lethal to newborns.",
        "utterances": [
            "emergency childbirth in disaster", "how to deliver a baby emergency", "woman in labor trapped at home",
            "cutting umbilical cord emergency", "imminent delivery crowning signs", "newborn care after field birth", "placenta delivery first aid"
        ]
    },
    {
        "intent": "drowning_water_rescue",
        "category": "Medical & First Aid",
        "title": "Near-Drowning First Aid & Safe Water Rescue",
        "summary": "Rescue from water without becoming a victim, followed by hypoxia-focused resuscitation.",
        "steps": [
            "Rescue without swimming (Reach, Throw, Row, Go): Extend a branch/pole/towel, throw a life ring or buoyant bottle, paddle a boat. Enter water ONLY as last resort with flotation device.",
            "Remove from water horizontally: Keep victim horizontal while lifting out to prevent sudden drop in venous blood return (circum-rescue collapse).",
            "Check responsiveness and breathing: Lay on firm surface. If not breathing normally, begin resuscitation IMMEDIATELY.",
            "Start with 5 initial rescue breaths: Drowning is primary respiratory arrest (hypoxia). Tilt head, pinch nose, and deliver 5 slow rescue breaths first before compressions.",
            "Follow with 30:2 CPR: Deliver 30 chest compressions followed by 2 rescue breaths. Continue uninterrupted. If victim vomits water, roll to side, clear mouth, and resume CPR."
        ],
        "warning": "DO NOT attempt abdominal thrusts (Heimlich) to expel water from lungs—it causes vomiting and aspiration. All near-drowning victims must be evaluated for delayed pulmonary edema ('secondary drowning').",
        "utterances": [
            "drowning first aid", "person pulled from water not breathing", "water rescue steps reach throw row",
            "near drowning resuscitation", "water in lungs cpr", "secondary drowning dry drowning symptoms", "swimming accident rescue"
        ]
    },
    {
        "intent": "shock_recovery_position",
        "category": "Medical & First Aid",
        "title": "Physiological Shock Triage & Recovery Position",
        "summary": "Perfusion support for hypovolemic/cardiogenic shock and airway maintenance in unconscious patients.",
        "steps": [
            "Recognize Shock: Rapid weak pulse, pale clammy cold skin, rapid shallow breathing, extreme thirst, anxiety, or confusion.",
            "Elevate lower extremities: Lay victim flat on back and elevate legs 20-30 cm (8-12 in) above heart (Shock position) to direct venous blood to vital organs (avoid if head/chest/spine/pelvis fracture suspected).",
            "Keep warm: Cover victim with coats, thermal foil blanket, or sleeping bag to preserve core temperature.",
            "Recovery Position for breathing unconscious victim: Place near arm at right angle; cross far arm over chest to opposite cheek; bend far knee up; roll patient toward you onto side. Tilt head back to keep airway open.",
            "Reassure and monitor vitals: Check pulse and breathing every 3 minutes. Record changes in responsiveness."
        ],
        "warning": "DO NOT give food, water, or oral fluids to a shock victim even if they complain of severe thirst (risk of vomiting and prepares for surgical anesthesia).",
        "utterances": [
            "treatment for shock", "person going into shock symptoms", "recovery position steps how to",
            "fainting syncope first aid", "pale cold clammy skin fast pulse", "elevate legs shock position", "unconscious but breathing posture"
        ]
    },

    # ==================== NATURAL & MAN-MADE DISASTERS ====================
    {
        "intent": "flood_survival",
        "category": "Disaster Survival",
        "title": "Flash Flood Survival & Sinking Vehicle Escape",
        "summary": "Evacuation to vertical safety, avoiding flood hazards, and escape from submerged cars.",
        "steps": [
            "Seek high vertical ground immediately: Evacuate to highest floor or roof. Avoid enclosed attics with no roof opening where rising waters can trap you.",
            "Shut off main utilities: Turn off primary electrical circuit breaker and LPG/gas valves before floodwaters enter building.",
            "Never walk or drive through floodwaters: 15 cm (6 in) of swift water sweeps adult off feet; 30 cm (12 in) floats small cars; 60 cm (24 in) washes away SUVs/trucks (Turn Around, Don't Drown).",
            "Escaping a Sinking Vehicle (SWUG rule): Seatbelts unbuckled; Windows opened/broken immediately; Children Unfastened; Get out through window before car is fully submerged.",
            "Break window if power fails: Strike corner of side window with car emergency hammer, metal headrest prong, or center punch. Never try to kick laminated front windshield."
        ],
        "warning": "Never touch downed electrical lines in water. Floodwaters contain raw sewage, chemical carcinogens, and dangerous hidden debris.",
        "utterances": [
            "flash flood survival steps", "escaping sinking submerged car vehicle", "trapped by rising flood water",
            "flooding inside house what to do", "turn around dont drown", "break car window submerged in water",
            "flood evacuation checklist", "river overflow warning survival", "urban flood survival tips"
        ]
    },
    {
        "intent": "earthquake_rubble",
        "category": "Disaster Survival",
        "title": "Earthquake Survival (Drop, Cover, Hold On) & Rubble Entrapment",
        "summary": "Structural collapse mitigation during tremors and survival techniques if trapped beneath debris.",
        "steps": [
            "DROP, COVER, and HOLD ON: Drop to hands and knees; Cover head and neck under sturdy table/desk; Hold on to table legs until shaking completely stops.",
            "If in bed: Stay in bed, curl face down, and cover head and neck with pillow. Stay away from exterior walls, windows, and heavy ceiling fixtures.",
            "If trapped under rubble: Protect airway—cover mouth and nose with cloth/shirt to filter toxic cement dust. Do NOT shout continuously (inhales dust and wastes oxygen).",
            "Signal rescuers with rhythmic tapping: Tap 3 times on pipes or structural concrete with stone/metal every few minutes. Rescuers with acoustic listening devices listen for rhythmic patterns.",
            "Conserve energy and preserve space: Create breathing void; move hands and toes periodically to maintain circulation. Stay calm—human bodies survive days under rubble if hydration is conserved."
        ],
        "warning": "DO NOT stand in doorways (modern doorways are not reinforced). DO NOT use elevators. DO NOT light matches or lighters (risk of igniting cracked gas lines).",
        "utterances": [
            "earthquake survival protocol", "drop cover and hold on", "trapped under collapsed rubble building",
            "earthquake in bed what to do", "aftershocks safety precautions", "signal rescuers while trapped under debris",
            "triangle of life debunked", "how to survive high magnitude earthquake", "earthquake tremors inside apartment"
        ]
    },
    {
        "intent": "cyclone_hurricane",
        "category": "Disaster Survival",
        "title": "Tropical Cyclone, Hurricane & High-Wind Shelter",
        "summary": "Securing shelter, surviving storm surges, and navigating the cyclone eye.",
        "steps": [
            "Identify safe interior room: Seek shelter in the lowest level interior room (bathroom, hallway, walk-in closet) without exterior windows or skylights.",
            "Beware the Cyclone Eye (False Calm): When winds abruptly cease, you are inside the eye of the storm. DO NOT leave shelter—the other wall of the storm will return in opposite direction with violent force.",
            "Protect against storm surge: Storm surge is the greatest killer in cyclones. If living within 5 km of coast, evacuate inland or to designated cyclone shelters at least 15 meters above sea level.",
            "Secure drinking water: Fill bathtubs, clean containers, and bottles before municipal water infrastructure is destroyed.",
            "Stay indoors until official 'All Clear': Beware flying corrugated metal sheets, falling trees, and downed electrical lines."
        ],
        "warning": "DO NOT tape windows in an 'X' (ineffective and creates larger dangerous shards of glass). Put up wooden storm shutters or plywood instead.",
        "utterances": [
            "cyclone survival steps", "hurricane shelter inside house", "storm surge coastal evacuation",
            "cyclone eye warning calm", "tornado basement shelter", "typhoon safety guidelines",
            "high wind structural safety", "cyclone preparation checklist ndma"
        ]
    },
    {
        "intent": "tsunami_evacuation",
        "category": "Disaster Survival",
        "title": "Tsunami Warning Signs & Vertical Evacuation",
        "summary": "Recognizing natural coastal indicators and evacuating inland and uphill.",
        "steps": [
            "Natural Warning Signs: Strong coastal earthquake lasting >20 sec; sudden abnormal ocean recession exposing sea floor; loud roaring sound like freight train or jet engine.",
            "Move inland and uphill IMMEDIATELY: Do NOT wait for official siren alarms. Run inland at least 2 to 3 km or climb to terrain at least 30 meters (100 ft) above sea level.",
            "Vertical Evacuation if trapped: If high ground is unreachable, climb to 4th floor or higher of reinforced reinforced-concrete multi-story building or specialized tsunami tower.",
            "Stay away from coast for 24+ hours: A tsunami is not a single wave—it is a series of waves separated by 10 to 60 minutes. The 2nd or 3rd wave is frequently the largest.",
            "Do NOT go to beach to watch: If you can see the wave coming, you are already too close to outrun it."
        ],
        "warning": "Never return to shoreline after first wave recedes. Tsunami waves carry enormous debris including cars, boats, and timber that crush structures.",
        "utterances": [
            "tsunami warning signs", "how to survive a tsunami", "ocean water receding tsunami",
            "vertical evacuation tsunami", "tsunami wave series danger", "coastal earthquake tsunami risk",
            "run uphill inland tsunami", "how high to climb for tsunami"
        ]
    },
    {
        "intent": "landslide_avalanche",
        "category": "Disaster Survival",
        "title": "Landslide, Mudflow & Snow Avalanche Survival",
        "summary": "Evacuation across flow paths and snow burial survival techniques.",
        "steps": [
            "Early landslide indicators: Tilting trees or utility poles, sudden muddy stream water, cracking sounds in hillside, jamming doors/windows.",
            "Evacuate perpendicular to flow path: Run sideways away from the path of mud/rock flow, never downhill in front of it.",
            "If caught in landslide: Curl into tight fetal ball and protect head with arms to prevent blunt trauma.",
            "Snow Avalanche action: If caught, discard heavy pack, make vigorous swimming motions toward surface as avalanche moves.",
            "Create air pocket before avalanche halts: Cup hands in front of mouth/face before snow settles into concrete-hard pack. Spit to determine 'down' and 'up' if disoriented."
        ],
        "warning": "Do NOT cross active mudslide paths on foot or vehicle. Soil liquifies into slurry that swallows vehicles instantly.",
        "utterances": [
            "landslide warning signs survival", "mudslide debris flow escape", "snow avalanche survival air pocket",
            "hillside sliding what to do", "avalanche swimming motion", "mudflow escape path", "rockfall mountain safety"
        ]
    },
    {
        "intent": "fire_smoke_escape",
        "category": "Disaster Survival",
        "title": "Structural Fire & Toxic Smoke Inhalation Escape",
        "summary": "Thermal egress, hot door checks, crawl heights, and clothes fire mitigation.",
        "steps": [
            "Crawl low under smoke: Toxic combustion gases (carbon monoxide, hydrogen cyanide) and heat rise to ceiling. Stay 30 to 60 cm (1-2 ft) above floor where cooler, breathable oxygen remains.",
            "Feel doors before opening: Check door and doorknob with back of hand. If hot, DO NOT open—fire is raging on other side. Seal cracks with wet towels/sheets.",
            "Stop, Drop, and Roll if clothes catch fire: Cover face with hands, drop immediately to floor, and roll back and forth until flames are suffocated.",
            "Never use elevators: Building electrical feeds fail and shafts act as chimneys for toxic smoke. Use emergency stairs.",
            "Signal from window if trapped: Close room door to block fire; hang bright cloth or sheet out window to attract fire department ladders."
        ],
        "warning": "DO NOT re-enter a burning building for pets, valuables, or documents under any circumstances. Smoke causes unconsciousness in 2-3 breaths.",
        "utterances": [
            "house building fire escape", "crawl under smoke fire", "door hot back of hand test",
            "stop drop and roll clothes on fire", "fire in apartment building steps", "trapped in room fire smoke",
            "toxic smoke inhalation escape", "fire extinguisher pass technique"
        ]
    },
    {
        "intent": "wildfire_survival",
        "category": "Disaster Survival",
        "title": "Wildfire & Forest Fire Egress & Survival",
        "summary": "Surviving fast-moving wildfires on foot or trapped in vehicles.",
        "steps": [
            "Evacuate early in direction of wind flank: Travel downhill and into previously burned areas ('the black') which lack combustible fuel.",
            "If trapped in vehicle: Park away from heavy brush/trees; close all windows and air vents; turn on headlights; lie low on floor under blanket.",
            "If trapped on foot: Seek bodies of water, plowed fields, rocky outcrops, or road cuts. Clear brush around you in 5m radius.",
            "Lie face down: Cover body with dry dirt/soil and protect face with moist cloth. Radiant heat from forest fire crowns kills before flames touch you.",
            "Stay clear of chimney canyons: Steep ravines and saddles funnel heat and drafts, causing fires to race uphill exponentially faster."
        ],
        "warning": "Fires travel uphill significantly faster than downhill. Never try to outrun an uphill wildfire.",
        "utterances": [
            "wildfire forest fire survival", "trapped in car wildfire", "bushfire emergency plan",
            "how to survive forest fire on foot", "radiant heat wildfire shelter", "evacuate wildfire smoke"
        ]
    },
    {
        "intent": "lightning_thunderstorm",
        "category": "Disaster Survival",
        "title": "Lightning Safety (30-30 Rule) & Outdoor Posture",
        "summary": "Minimizing ground strike risk and step potential during electrical storms.",
        "steps": [
            "The 30-30 Rule: If time between lightning flash and thunder is <30 seconds, lightning is within 10 km (6 miles)—seek substantial shelter immediately. Stay indoors for 30 minutes after last thunderclap.",
            "Seek enclosed vehicle or substantial building: An all-metal enclosed vehicle acts as a protective Faraday cage (do not touch metal frame).",
            "If trapped in open terrain (Lightning Crouch): Crouch low on balls of feet with heels touching together, head tucked, hands over ears. Minimize contact with ground.",
            "Avoid isolated tall objects: Stay far away from single tall trees, hilltops, metal fences, utility poles, and open bodies of water.",
            "Disperse groups: Maintain at least 5 meters (15 ft) between individuals in a group to prevent lightning jumping or injuring multiple people."
        ],
        "warning": "DO NOT lie flat on ground (increases exposure to lethal ground current). Avoid water pipes, landline phones, and electrical appliances indoors during storms.",
        "utterances": [
            "lightning safety precautions", "30 30 rule lightning", "lightning crouch position",
            "trapped in thunderstorm open field", "can lightning strike a car faraday cage", "tall tree lightning danger",
            "lightning strike first aid", "step voltage lightning ground"
        ]
    },
    {
        "intent": "chemical_gas_leak",
        "category": "Disaster Survival",
        "title": "Chemical Hazard, Toxic Gas Leak & Shelter-in-Place",
        "summary": "Protective posturing for industrial hazardous materials and LPG gas leaks.",
        "steps": [
            "LPG / Domestic Gas Leak: Do NOT flip any light switches, ring doorbells, or light matches. Turn off cylinder regulator; open all doors/windows; evacuate building immediately.",
            "Industrial Toxic Gas Leak (Shelter-in-Place): Move into an interior room on highest floor (most toxic gases like chlorine are heavier than air; ammonia is lighter).",
            "Seal the room: Turn off AC, ventilation fans, and heaters. Tape plastic sheeting or duct tape over windows, doors, electrical outlets, and vents.",
            "Improvise wet mask: Breathe through a damp folded towel or cloth to absorb water-soluble chemical vapors.",
            "Evacuation direction: Always evacuate upwind and uphill from an industrial chemical release point."
        ],
        "warning": "DO NOT touch or step into liquid chemical spills. Smelling an unknown odor followed by burning eyes/throat warrants immediate upwind evacuation.",
        "utterances": [
            "chemical gas leak what to do", "lpg cylinder gas smell leak", "shelter in place chemical spill",
            "toxic industrial fumes escape", "chlorine ammonia gas cloud", "seal room plastic duct tape",
            "upwind uphill chemical evacuation", "hazardous material hazmat emergency"
        ]
    },
    {
        "intent": "nuclear_radiation",
        "category": "Disaster Survival",
        "title": "Nuclear Radiation Fallout & Decontamination Protocol",
        "summary": "Radiation shielding (Time, Distance, Shielding) and post-blast decontamination.",
        "steps": [
            "Seek heavy structural shielding immediately: Dense materials block ionizing radiation. Best shielding: underground basements, concrete bunkers, brick multistory buildings. (Avoid cars or mobile homes).",
            "Stay indoors for 24 to 48 hours: Radioactive fallout drops by 90% within 24 hours (Rule of 7: every 7-fold increase in time reduces radiation by factor of 10).",
            "Decontamination procedure: Remove outer clothing gently and seal in plastic bag (removes up to 90% of radioactive dust). Take a warm shower with soap; wash hair thoroughly without scratching skin.",
            "Safe food and water: Consume only sealed canned food, jarred goods, and bottled water stored inside. Wash exterior of can before opening.",
            "Medical countermeasures: Take Potassium Iodide (KI) ONLY if directed by public health authorities (blocks thyroid absorption of radioactive Iodine-131)."
        ],
        "warning": "DO NOT use hair conditioner after radiological exposure (binds radioactive isotopes permanently to hair proteins).",
        "utterances": [
            "nuclear explosion fallout survival", "radiation protection shielding", "decontamination after radiation fallout",
            "potassium iodide tablets radiation", "how long to stay inside after nuclear blast", "fallout shelter materials concrete lead",
            "dirty bomb radiation emergency", "radiation sickness symptoms"
        ]
    },
    {
        "intent": "downed_power_lines",
        "category": "Disaster Survival",
        "title": "Downed High-Voltage Power Lines & Electrical Hazards",
        "summary": "Step potential avoidance and safe egress from energized vehicles.",
        "steps": [
            "Assume all downed lines are live: High-voltage lines arc electricity across air and energize the ground up to 10 meters (35 ft) in radius.",
            "Shuffle feet without lifting: To avoid step potential (voltage differential between feet), keep feet touching flat on ground and shuffle slowly without lifting either foot or separating them.",
            "If wire falls on your vehicle: STAY INSIDE YOUR VEHICLE. The rubber tires and metal frame insulate you safely. Honk horn and call emergency services.",
            "If vehicle catches fire (Jump clear): Jump clear without touching car and ground simultaneously. Land with both feet together and shuffle or bunny-hop away.",
            "Never touch fallen fences or puddle water: Conductive chain-link fences or puddles can carry lethal voltage hundreds of meters from the wire."
        ],
        "warning": "DO NOT touch someone who is in contact with a live electrical wire until power is officially de-energized by the utility company.",
        "utterances": [
            "downed power line on ground car", "electric wire touching ground safety", "step potential shuffle feet",
            "jump out of energized car electric", "high voltage shock hazard", "broken electricity pole wire road",
            "electric shock victim first aid rescue"
        ]
    },
    {
        "intent": "crowd_crush_stampede",
        "category": "Disaster Survival",
        "title": "Crowd Crush & Stampede Survival Protocol",
        "summary": "Maintaining chest expansion and navigating dense human surges.",
        "steps": [
            "Adopt the Boxer / Shield Stance: Bring arms up to chest like a boxer with elbows bent in front of ribs. This creates 5-10 cm of breathing space to prevent compressive asphyxia.",
            "Stay on your feet at all costs: Falling in a crowd surge is often fatal. If you drop items (phone, bag), DO NOT bend down to retrieve them.",
            "Move diagonally with crowd surges: Do not push against the current or fight it directly. Move diagonally toward the edge of the crowd during natural pauses between surges.",
            "Avoid hard barriers: Stay away from brick walls, fences, barricades, and bottlenecks where crushing pressure concentrates.",
            "If you fall down: Immediately curl onto left side into tight ball, cover head and ears with hands, and draw knees to chest to protect vital organs."
        ],
        "warning": "People in crowd crushes die of compressive suffocation while standing, not blunt trampling. Guard your chest cavity space above all else.",
        "utterances": [
            "crowd crush stampede survival", "how to survive stampede surge", "boxer stance crowd pressure",
            "suffocation in dense crowd", "trapped in concert religious festival crowd", "fell down in stampede what to do",
            "human wave surge escape"
        ]
    },

    # ==================== WILDERNESS & URBAN SURVIVAL ====================
    {
        "intent": "water_purification",
        "category": "Survival Skills",
        "title": "Offline Water Purification & Finding Potable Water",
        "summary": "Eliminating pathogens via boiling, SODIS, chlorine, and finding wilderness water.",
        "steps": [
            "Pre-filter sediment: Pour turbid water through multiple layers of clean cotton cloth, sand/charcoal filter, or let silt settle for 2 hours.",
            "Boiling (Gold Standard): Bring water to a vigorous rolling boil for at least 1 minute (3 minutes at elevations above 2,000 meters / 6,500 ft).",
            "Solar Disinfection (SODIS): Fill clean transparent PET plastic bottles 3/4 full, shake vigorously for 20 sec (oxygenates water), fill completely, and lay horizontally on shiny roof in direct sun for 6 hours (2 days if overcast).",
            "Household Bleach disinfection: Add 2 drops of unscented 6% household bleach per Liter of clear water (4 drops if cloudy). Stir and let sit covered for 30 minutes. Water should smell faintly of chlorine.",
            "Finding wilderness water: Collect morning dew with absorbent cloth; harvest clear rainwater away from trees; follow animal tracks and bees downhill toward valley bottoms."
        ],
        "warning": "Boiling and chlorine kill bacteria, parasites, and viruses, but DO NOT remove chemical poisons, heavy metals, or industrial toxins.",
        "utterances": [
            "how to purify water without filter", "boil water time altitude", "sodis solar water disinfection",
            "bleach drops per liter water purification", "make contaminated water safe to drink",
            "diy sand charcoal water filter", "finding water wilderness survival", "morning dew collection water"
        ]
    },
    {
        "intent": "food_storage_rationing",
        "category": "Survival Skills",
        "title": "Power Outage Food Preservation & Survival Rationing",
        "summary": "Managing refrigerator cold chain failure and calorie conservation.",
        "steps": [
            "Maintain refrigerator seal: An unopened refrigerator preserves food safely for 4 hours; a half-full freezer for 24 hours; a tightly packed full freezer for 48 hours.",
            "Prioritize perishable consumption: Eat perishable dairy, cooked leftovers, and raw meats within first 4-6 hours before temperatures exceed 4°C (40°F).",
            "Transition to non-perishable stocks: Rely on canned beans, rice, pulses, peanut butter, dried fruits, nuts, oats, and MRE biscuits.",
            "Survival Rationing Rule: A healthy adult can survive 3 weeks without food as long as water is available. On day 1 of a disaster, consume minimal food to allow metabolism to adjust.",
            "Inspect before eating: Never taste food that smells rancid, shows mold, feels slimy, or comes from bulging/dented cans (botulism risk)."
        ],
        "warning": "When in doubt, throw it out. Acute food poisoning during a blackout causes severe vomiting, rapid dehydration, and medical complications.",
        "utterances": [
            "food safety power outage", "how long does fridge stay cold without electricity", "emergency food rationing survival",
            "bulging can botulism danger", "non perishable food disaster list", "calorie intake survival emergency",
            "eating wild plants universal edibility test"
        ]
    },
    {
        "intent": "fire_starting",
        "category": "Survival Skills",
        "title": "Starting Fire Without Matches or Lighters",
        "summary": "Primitive and improvised ignition methods for warmth, cooking, and signaling.",
        "steps": [
            "Prepare Tinder, Kindling, and Fuel first: Gather bone-dry tinder nest (dry grass, shredded birch bark, dryer lint, cotton balls with petroleum jelly). Prepare kindling (pencil-sized twigs) and fuel logs.",
            "Battery + Foil / Steel Wool: Touch 9V battery terminals to fine (0000) steel wool, or touch positive and negative terminals of AA/phone battery with gum wrapper foil strip narrowed in center to create an incandescent flame.",
            "Magnifying Glass / Eyeglasses: Focus sunlight through camera lens, convex eyeglass, clear ice lens, or plastic water bottle onto dark tinder nest until smoke appears; blow gently.",
            "Ferrocerium Rod (Firesteel): Scrape spine of knife firmly down rod at 45-degree angle directly onto tinder bundle.",
            "Bow Drill (Friction): Carve dry softwood hearth board with notch; spin hardwood spindle with cordage bow until black smoking ember forms. Transfer ember to tinder nest and blow into flame."
        ],
        "warning": "Never build a fire inside an unventilated enclosed shelter (carbon monoxide asphyxiation hazard). Always extinguish completely with water and dirt before leaving.",
        "utterances": [
            "how to start fire without matches", "fire with battery and gum wrapper", "steel wool battery fire",
            "bow drill friction fire steps", "fire with eyeglasses magnifying glass", "tinder kindling fuel wood survival",
            "make fire in rain wet wood"
        ]
    },
    {
        "intent": "emergency_shelter",
        "category": "Survival Skills",
        "title": "Improvised Emergency Shelter & Thermal Insulation",
        "summary": "Building lean-tos, debris huts, and ground insulation to combat hypothermia.",
        "steps": [
            "Site Selection: Choose flat ground elevated above flood plains, away from dead tree branches ('widowmakers'), rockfall hazard, and animal trails.",
            "Insulate from ground (Crucial): The cold ground conducts heat away from your body 20 times faster than air. Construct a sleeping bed of at least 30 cm (12 in) of dry pine needles, leaves, or cardboard.",
            "Debris Hut (Warmth without fire): Prop sturdy ridge pole on stump (1 meter high). Place rib sticks along both sides. Pile 1 meter thickness of dry leaves/brush over structure for windproof insulation.",
            "A-Frame / Lean-To (with Tarp/Poncho): Lash ridge line between two trees at waist height. Peg edges down into the wind. Face open side toward small campfire with log reflector wall.",
            "Thermal Space Blanket usage: Keep shiny silver side facing your body to reflect up to 90% of radiant heat back to you."
        ],
        "warning": "DO NOT build shelter at valley bottoms (cold air settles and flash floods collect) or on windy exposed ridge tops.",
        "utterances": [
            "how to build emergency shelter", "debris hut survival steps", "lean to tarp shelter",
            "ground insulation sleeping cold", "space blanket shiny side in or out", "survival shelter in woods",
            "improvised shelter without tools"
        ]
    },
    {
        "intent": "navigation_no_compass",
        "category": "Survival Skills",
        "title": "Wilderness Navigation Without Compass or GPS",
        "summary": "Finding cardinal directions using celestial bodies, shadow sticks, and analog watches.",
        "steps": [
            "Shadow-Stick Method (Sun): Push 1-meter stick vertically into ground. Mark shadow tip with stone. Wait 15-20 minutes, mark new shadow tip. Draw line from first stone to second stone: this line runs West to East (first marker is West).",
            "Analog Watch Method (Northern Hemisphere): Point the hour hand directly at the Sun. The angle halfway between the hour hand and the 12 o'clock mark points due South.",
            "Analog Watch Method (Southern Hemisphere): Point the 12 o'clock mark at the Sun. The point halfway between 12 and the hour hand points due North.",
            "North Star (Polaris - Northern Hemisphere): Locate the Big Dipper constellation. Follow the two outer 'pointer' stars of the cup 5 times their distance to find Polaris (due North).",
            "Southern Cross (Crux - Southern Hemisphere): Extend the long axis of the cross 4.5 times its length toward the horizon to determine due South."
        ],
        "warning": "Moss does NOT always grow on the North side of trees (it grows on whatever side is dampest and shaded). Do not rely on moss for navigation.",
        "utterances": [
            "how to find north without compass", "shadow stick method navigation", "analog watch compass direction",
            "finding north star polaris big dipper", "southern cross navigation", "lost in wilderness find direction",
            "celestial navigation stars"
        ]
    },
    {
        "intent": "rescue_signaling",
        "category": "Survival Skills",
        "title": "Emergency Rescue Signaling, SOS Morse & Mirror Flares",
        "summary": "Visual, acoustic, and ground-to-air signals for search and rescue aircraft and teams.",
        "steps": [
            "Rule of Three (Universal Distress Signal): 3 whistle blasts, 3 gunshots, 3 fires in a triangle, or 3 flashes of light. Pause 1 minute and repeat.",
            "SOS in Morse Code: 3 short bursts, 3 long bursts, 3 short bursts (· · · — — — · · ·). Send with whistle, flashlight, or horn.",
            "Signal Mirror (Heliograph): Hold mirror near eye; extend free arm and create 'V' with fingers sighting the rescue aircraft/boat. Flash sunlight through mirror hole until reflection aligns with aircraft.",
            "Ground-to-Air Symbols: Trample in snow/sand or arrange rocks/logs into large letters (at least 3m long): 'V' (Require Assistance), 'X' (Require Medical Assistance), 'I' (Require Doctor), '->' (Proceeding in this direction).",
            "Smoke Signaling: Light dry wood for flames, then heap green pine boughs, leaves, or damp moss to produce thick white smoke (visible for 30+ km)."
        ],
        "warning": "Signal mirrors can be seen over 30 kilometers away on sunny days. Never shine high-powered lasers at aircraft (blinds pilots and is a federal felony).",
        "utterances": [
            "how to signal search and rescue", "sos morse code signal", "signal mirror heliograph how to use",
            "ground to air emergency symbols", "smoke signal emergency rescue", "rule of three distress signals",
            "three whistle blasts emergency"
        ]
    },
    {
        "intent": "emergency_go_bag",
        "category": "Survival Skills",
        "title": "72-Hour Emergency Bug-Out Bag Checklist",
        "summary": "Essential survival equipment, nutrition, and documentation for sudden evacuation.",
        "steps": [
            "Water & Filtration (Priority #1): 3 Liters of water per person per day (9 Liters for 72h) + water purification tablets or Sawyer Mini filter.",
            "Food & Nutrition: 3 days of high-calorie, non-perishable bars, canned tuna, dried fruits, trail mix, and can opener.",
            "First Aid & Medications: Trauma kit (tourniquet, pressure bandages, antiseptic, burn dressing) + 7-day supply of personal prescription medications.",
            "Light & Power: LED headlamp, spare batteries, hand-crank emergency radio, 20,000 mAh power bank with charging cables.",
            "Tools, Warmth & Documents: Multi-tool, waterproof matches/ferro rod, emergency thermal space blanket, poncho, work gloves, copies of ID/passports/deeds in waterproof pouch, and cash in small denominations."
        ],
        "warning": "Keep bug-out bags packed and stored near your main exit door. Review and rotate perishable items and water every 6 months.",
        "utterances": [
            "72 hour go bag checklist", "bug out bag essentials", "emergency disaster kit packing list",
            "what to pack in evacuation bag", "survival backpack items", "emergency supplies for family"
        ]
    },

    # ==================== PSYCHOLOGICAL FIRST AID & VULNERABLE POPULATIONS ====================
    {
        "intent": "panic_anxiety_grounding",
        "category": "Psychological First Aid",
        "title": "Panic Attack Relief & 5-4-3-2-1 Grounding Protocol",
        "summary": "De-escalating acute panic, hyperventilation, and psychological shock in disaster survivors.",
        "steps": [
            "Box Breathing (4-4-4-4): Inhale slowly through nose for 4 seconds; hold breath for 4 seconds; exhale slowly through mouth for 4 seconds; hold lungs empty for 4 seconds. Repeat 4 times to stimulate vagus nerve.",
            "5-4-3-2-1 Sensory Grounding: Name 5 things you can see around you; 4 things you can physically feel/touch; 3 things you can hear; 2 things you can smell; 1 thing you can taste.",
            "Reassure physical safety: Speak in calm, low, firm tones: 'You are safe right now. This feeling is adrenaline and will peak and fade in a few minutes. I am right here with you.'",
            "Body anchoring: Have the person place both feet flat on the floor and gently press their hands against their knees or thighs.",
            "Avoid paper bag breathing: Contrary to old myths, breathing into a paper bag can be dangerous during asthma attacks or cardiac events. Use paced pursed-lip breathing instead."
        ],
        "warning": "Do NOT tell someone in acute panic to 'calm down' or dismiss their fears. Validate their experience while guiding their physical breath.",
        "utterances": [
            "how to stop a panic attack", "5 4 3 2 1 grounding technique", "box breathing anxiety relief",
            "hyperventilating panic first aid", "calming someone down in disaster", "severe anxiety attack steps",
            "psychological shock trauma calming"
        ]
    },

    # ==================== APP FEATURES & MESH NETWORKING ====================
    {
        "intent": "how_mesh_works",
        "category": "App & Mesh Operations",
        "title": "RakshaNet Offline Bluetooth & Wi-Fi Direct Mesh Network",
        "summary": "How multi-hop decentralized communication works without cellular towers or internet.",
        "steps": [
            "Device-to-Device Linking: RakshaNet connects directly to nearby smartphones via Bluetooth Low Energy (BLE) and Wi-Fi Direct (Nearby Connections) up to 100 meters per hop.",
            "Store-and-Forward Multi-Hop: If recipient is out of direct radio range, intermediate devices automatically relay encrypted packets from phone to phone until reaching the destination.",
            "End-to-End Encryption (E2EE): All private messages are encrypted using X25519 key exchange and AES-256-GCM. Relaying phones only read routing headers and CANNOT inspect message contents.",
            "Opportunistic Internet Gateway: When ANY single device in the mesh reaches cellular data, Wi-Fi, or satellite connectivity, it automatically uploads all queued disaster reports and SOS beacons to the Command Center.",
            "Battery Optimization: Radios cycle sleep intervals to consume <2-3% battery per day in background standby."
        ],
        "warning": "Keep Bluetooth and Wi-Fi toggles turned ON in Android settings so your device can discover peers and relay emergency packets.",
        "utterances": [
            "how does mesh network work", "how does rakshanet work without internet", "offline bluetooth relay",
            "how multi hop mesh works", "is mesh chat encrypted", "opportunistic internet gateway mesh",
            "nearby devices offline chat", "rakshanet radio technology"
        ]
    },
    {
        "intent": "how_sos_works",
        "category": "App & Mesh Operations",
        "title": "Triggering, Broadcasting & Cancelling SOS Beacons",
        "summary": "Operating the high-priority red SOS button and beacon dissemination.",
        "steps": [
            "Trigger SOS: Press and hold the circular red SOS Beacon button on the Home screen or Bottom Navigation for 1.5 seconds.",
            "Select Emergency Category: Choose from Medical Emergency, Trapped in Rubble, Flash Flood, Fire, or Security Threat, and specify number of trapped victims.",
            "Automatic Telemetry Broadcast: Your phone packages GPS coordinates, battery level, medical notes, and emergency contacts into a high-priority beacon.",
            "Mesh Dissemination: The SOS beacon transmits immediately to all nearby physical peers and floods across the multi-hop network to rescue teams.",
            "Cancelling False Alarms: If triggered accidentally, tap 'Cancel SOS', enter your PIN/confirmation, and an authenticated cancellation packet will propagate across the mesh."
        ],
        "warning": "Only trigger SOS for genuine life-threatening emergencies. Responders prioritize high-confidence SOS clusters.",
        "utterances": [
            "how to use sos button", "how to trigger emergency beacon", "cancel false sos alarm",
            "what happens when i press sos", "sos broadcast mesh", "red sos button features"
        ]
    },
    {
        "intent": "emergency_numbers",
        "category": "Emergency Directories",
        "title": "National & International Emergency Helpline Directory",
        "summary": "Direct dispatch phone numbers for police, fire, medical, disaster, and coast guard.",
        "steps": [
            "India Unified Emergency: 112 (All-in-one Police, Fire, Ambulance, Disaster)",
            "India Ambulance & Medical: 108 (Emergency Medical Service & Trauma Ambulance) / 102 (Maternity)",
            "India Disaster Response: 1078 (NDMA National Disaster Management Authority) / 1070 (State Emergency Relief)",
            "India Police & Fire: 100 (Police) / 101 (Fire Brigade) / 1091 (Women Helpline)",
            "International Reference: 911 (USA/Canada), 112 (European Union & Global GSM standard), 999 (UK), 000 (Australia)"
        ],
        "warning": "Emergency numbers can be dialed on mobile phones even with no SIM card or locked keypad as long as ANY mobile network tower is detected.",
        "utterances": [
            "emergency helpline numbers", "ambulance phone number india", "police fire disaster numbers",
            "ndma disaster control room number", "112 emergency service", "call 108 ambulance",
            "international emergency numbers 911 112", "toll free rescue numbers"
        ]
    },

    # ==================== GENERAL KNOWLEDGE, SCIENCE, TECH & CALCULATION ====================
    {
        "intent": "math_calculation",
        "category": "Math & Calculations",
        "title": "Offline Mathematical & Unit Calculation Engine",
        "summary": "Instant evaluation of arithmetic, percentages, survival dosage ratios, and geometry.",
        "steps": [
            "Arithmetic & Operations: Evaluates addition (+), subtraction (-), multiplication (*), division (/), powers (^), and roots.",
            "Percentage calculations: Calculates discounts, yield ratios, and concentration percentages.",
            "Survival Math: Water consumption = 3 Liters * [Number of People] * [Days]. Minimum calorie target = 1,200 kcal/adult/day.",
            "Dosage ratios: ORS ratio = 6 teaspoons sugar + 0.5 teaspoon salt per 1 Liter water.",
            "Bleach ratio: 2 drops 6% sodium hypochlorite bleach per 1 Liter clear water."
        ],
        "warning": "Always verify measurement spoon sizes when preparing oral medical formulations.",
        "utterances": [
            "what is 25 times 14", "calculate percentage", "math solver offline", "how much water for 5 people 3 days",
            "solve arithmetic equation", "divide multiply calculate", "calories needed for survival"
        ]
    },
    {
        "intent": "unit_conversion",
        "category": "Math & Calculations",
        "title": "Unit Conversion (Temperature, Distance, Weight, Volume)",
        "summary": "Conversion formulas between Metric and Imperial measurement systems.",
        "steps": [
            "Temperature: °C = (°F - 32) * 5/9  |  °F = (°C * 9/5) + 32  (e.g., 37°C = 98.6°F normal body temp; 40°C = 104°F fever/heatstroke).",
            "Distance: 1 Kilometer = 0.621371 Miles  |  1 Mile = 1.60934 Kilometers  |  1 Meter = 3.28084 Feet.",
            "Weight: 1 Kilogram = 2.20462 Pounds (lbs)  |  1 Pound = 0.453592 Kilograms.",
            "Liquid Volume: 1 Liter = 0.264172 US Gallons  |  1 Gallon = 3.78541 Liters  |  1 Liter = 1,000 Milliliters.",
            "Speed: 1 Knot = 1.852 km/h = 1.15 mph  |  1 m/s = 3.6 km/h."
        ],
        "warning": "Double-check units when interpreting meteorological storm surge warnings and medical weights.",
        "utterances": [
            "convert celsius to fahrenheit", "convert km to miles", "liters to gallons conversion",
            "kg to pounds conversion formula", "feet to meters calculation", "temperature conversion"
        ]
    },
    {
        "intent": "common_medicines_otc",
        "category": "Medical & First Aid",
        "title": "Common Over-the-Counter (OTC) Emergency Medications",
        "summary": "Standard dosage, indications, and contraindications for common first aid kit medicines.",
        "steps": [
            "Paracetamol / Acetaminophen (Pain & Fever): Adult dose 500 mg - 1,000 mg every 4-6 hours (Maximum 4,000 mg/24 hours). Safe for children at 10-15 mg/kg.",
            "Ibuprofen (NSAID - Pain, Swelling, Inflammation): Adult dose 200 mg - 400 mg every 6 hours with food. Avoid in stomach ulcers, active bleeding, or dengue fever.",
            "Cetirizine / Antihistamine (Allergies & Stings): Adult dose 10 mg once daily. Relieves itching, hives, runny nose.",
            "Oral Rehydration Salts (ORS): Replace fluid lost from diarrhea, vomiting, or sweating. Sip continuously.",
            "Povidone Iodine 5% (Antiseptic): Clean exterior wounds, abrasions, and animal bites. Do NOT ingest."
        ],
        "warning": "DO NOT take Aspirin or Ibuprofen if suspected dengue fever or internal bleeding (increases risk of severe hemorrhage). Never exceed maximum paracetamol doses (causes fatal liver failure).",
        "utterances": [
            "paracetamol dosage adult", "ibuprofen vs paracetamol", "cetirizine allergy dose",
            "what medicine for fever in disaster", "otc first aid kit medicines", "painkiller dosage emergency"
        ]
    },
    {
        "intent": "morse_code_lookup",
        "category": "Survival Skills",
        "title": "Full International Morse Code Alphabet & Numerals",
        "summary": "Complete audio and visual telegraphy character lookup table.",
        "steps": [
            "A: · —   B: — · · ·   C: — · — ·   D: — · ·   E: ·   F: · · — ·   G: — — ·",
            "H: · · · ·   I: · ·   J: · — — —   K: — · —   L: · — · ·   M: — —   N: — ·",
            "O: — — —   P: · — — ·   Q: — — · —   R: · — ·   S: · · ·   T: —",
            "U: · · —   V: · · · —   W: · — —   X: — · · —   Y: — · — —   Z: — — · ·",
            "0: — — — — —   1: · — — — —   2: · · — — —   3: · · · — —   4: · · · · —   5: · · · · ·   9: — — — — ·"
        ],
        "warning": "SOS is transmitted without pause between letters: · · · — — — · · ·",
        "utterances": [
            "morse code alphabet", "how to write letters in morse code", "morse code for sos",
            "telegraph code lookup", "morse code numbers 1 2 3"
        ]
    },
    {
        "intent": "mass_casualty_triage_start",
        "category": "Triage & Mass Casualty",
        "urgency": "critical",
        "title": "START Mass Casualty Triage Protocol (Simple Triage & Rapid Treatment)",
        "summary": "Rapid disaster scene triage to prioritize patient evacuation based on Respiration, Perfusion, and Mental Status (RPM).",
        "steps": [
            "Direct walking wounded: Shout loudly for anyone who can walk to move to a designated safe collection point (Green / Minor tag).",
            "Assess Respiration (R): If no breathing, clear airway. If still not breathing: Black (Deceased/Expectant). If breathing >30 or <10 breaths/min: Red (Immediate). If 10-30 bpm, proceed to Perfusion.",
            "Assess Perfusion (P): Check radial pulse or capillary refill (blanching fingernail). If radial pulse absent or refill >2 seconds: Red (Immediate) and control life-threatening hemorrhage. If normal, assess Mental Status.",
            "Assess Mental Status (M): Give simple command ('Squeeze my hand'). If unresponsive or cannot follow simple commands: Red (Immediate). If follows commands: Yellow (Delayed).",
            "Continuous Re-triage: Patient physiological status changes dynamically; re-evaluate Yellow and Green casualties every 15-30 minutes.",
        ],
        "warning": "Do not spend more than 30 seconds assessing any individual patient. Immediately control massive arterial bleeding before moving to next victim.",
        "utterances": [
            "mass casualty triage protocol",
            "start triage algorithm",
            "how to triage disaster victims",
            "red yellow green black triage tags",
            "rpm triage respiration perfusion mental",
            "triage multiple injured victims",
            "disaster casualty sorting",
            "who to treat first in mass emergency",
            "start triage steps",
            "triage tags meaning",
            "ndma mass casualty triage",
            "field triage algorithm",
        ]
    },
    {
        "intent": "cbrn_decontamination",
        "category": "CBRN & Hazardous Materials",
        "urgency": "critical",
        "title": "CBRN Full Decontamination & Hazardous Agent Protocol",
        "summary": "Immediate self-decontamination, zone containment, and chemical-biological-radiological agent removal.",
        "steps": [
            "Evacuate upwind and uphill immediately: Never remain downwind or in low-lying gullies/basements where toxic heavy chemical vapor plumes pool.",
            "Strip clothing immediately: Removing outer clothing eliminates up to 90% of surface chemical and radiological particulate contamination. Cut or roll clothes outward away from mouth/nose.",
            "Flush eyes and mucous membranes: Irrigate eyes continuously with clean water or normal saline for 15 minutes, holding eyelids open.",
            "Copious warm water and mild soap wash: Gently lather skin with soap and rinse with water. Avoid harsh scrubbing which abrades epidermis and forces toxins into capillaries.",
            "Double-bag contaminated clothing: Seal stripped clothing, shoes, and gear inside heavy plastic bags; seal airtight with duct tape and move far outside living quarters.",
        ],
        "warning": "DO NOT use household bleach on open wounds or eyes. Never touch contaminated clothing with bare hands; use plastic bags or nitrile gloves as an impervious barrier.",
        "utterances": [
            "cbrn decontamination protocol",
            "chemical weapon attack first aid",
            "nerve agent exposure treatment",
            "biological hazard decontamination",
            "toxic chemical spill cleanup on skin",
            "how to decontaminate after gas attack",
            "cbrn emergency steps",
            "chlorine gas sarin exposure first aid",
            "chemical burn decontamination",
            "radiological dust wash skin",
            "hazardous material hazmat decontamination",
        ]
    },
    {
        "intent": "dam_burst_flash_flood",
        "category": "Natural Hazards & Disasters",
        "urgency": "critical",
        "title": "Dam Burst & Torrential Flash Flood Survival Protocol",
        "summary": "Immediate vertical evacuation and survival tactics for catastrophic dam failures and high-velocity surge waves.",
        "steps": [
            "Evacuate vertically to highest stable ground: Move immediately perpendicular to the river valley or flood plain. Do NOT seek refuge in basements, lower floors, or underpasses.",
            "Avoid bridges, embankments, and culverts: Extreme hydraulic surges destroy foundation piers in seconds; stay completely clear of riverbank channels.",
            "Abandon submerged vehicles instantly: If car stalls in rising water, unbuckle, open or break side windows, and climb onto car roof immediately.",
            "Cling to buoyant debris if swept away: Use logs, coolers, or large plastic containers to keep head and chest above water surface and avoid hydraulic submersion.",
            "Watch for energized electrical currents: Floodwaters conduct lethal voltages from submerged transformers and broken utility wires. Keep distance from metal fences and downed cables.",
        ],
        "warning": "NEVER drive or walk across moving water. Just 15 cm (6 in) of moving water knocks down an adult; 60 cm (2 ft) sweeps away SUVs and pickup trucks.",
        "utterances": [
            "dam burst survival",
            "dam break flood emergency",
            "wall of water flash flood",
            "reservoir breach escape",
            "catastrophic dam failure protocol",
            "sudden torrent survival",
            "escaping high velocity flood surge",
            "dam collapse flood what to do",
            "water reservoir bursting run",
        ]
    },
    {
        "intent": "swiftwater_rescue",
        "category": "Water & Swiftwater Rescue",
        "urgency": "critical",
        "title": "Swiftwater Survival, River Crossing & Defensive Swimming",
        "summary": "Hydrodynamic survival tactics for river currents, hydraulic holes, river strainers, and defensive positioning.",
        "steps": [
            "Adopt defensive swimming posture: Lie on your back with feet pointed downstream, toes breaking the surface, and head up looking ahead to deflect off boulders.",
            "Aggressive swimming against strainers: If swept toward a downed tree or branch grid (strainer), flip onto stomach, swim furiously toward it, and launch up over the obstacle.",
            "Target river eddies: Spot quiet counter-current eddies behind giant boulders or inside river bends; swim aggressively across current at a 45-degree angle to slip into the calm eddy.",
            "Throw-bag rope rescue: Rescuer aims rope bag over victim's shoulder. Victim grasps rope across chest, turns onto back, and is swung smoothly to shore like a pendulum.",
            "Wedge river crossing: Form a linked triangle or wedge with 3 or more people, heaviest person upstream breaking the current, shuffling sideways without crossing legs.",
        ],
        "warning": "NEVER try to stand up in fast knee-deep water: Foot entrapment between submerged rocks forces the torso downstream underwater by hydraulic pressure, resulting in rapid drowning.",
        "utterances": [
            "swiftwater rescue technique",
            "defensive swim position river",
            "how to survive strong river current",
            "river strainer hazard",
            "river crossing safety",
            "swept away by river current",
            "water rescue throw bag technique",
            "hydraulic hole drowning escape",
            "fast flowing river survival",
            "foot entrapment river danger",
        ]
    },
    {
        "intent": "structural_collapse_void_search",
        "category": "Structural Collapse & Confined Spaces",
        "urgency": "critical",
        "title": "Building Collapse Confined Space Void Search & Rubble Signaling",
        "summary": "Survival void space identification (Lean-To, V-Shape, Pancake) and acoustic signaling for collapsed structures.",
        "steps": [
            "Protect airway and conserve oxygen: Cover nose and mouth with cotton cloth or clothing to filter toxic concrete dust and silica. Breathe slowly and shallowly.",
            "Identify structural survival voids: Locate Lean-To voids (heavy slab slanting against a wall), V-Shape voids (floor slab broken in center), or voids next to heavy furniture (bed/desk).",
            "Acoustic metal and rubble tapping: Strike metal pipes, steel beams, or concrete slabs with a stone or tool in rhythmic bursts of 3 (TAP-TAP-TAP... 5-second silence... TAP-TAP-TAP).",
            "Shout only when hearing searchers: Constant screaming exhausts vocal cords, accelerates dehydration, and leads to lethal dust inhalation; save voice until rescuers are directly overhead.",
            "Do not dislodge supporting debris: Shifting rubble around your void space can destabilize keystone pieces and trigger catastrophic secondary collapse.",
        ],
        "warning": "DO NOT strike matches or lighters under rubble: Ruptured natural gas, methane, or propane lines beneath debris will ignite an explosive catastrophic fireball.",
        "utterances": [
            "building collapse void space",
            "trapped under rubble tapping",
            "search and rescue collapsed structure",
            "lean to void pancake collapse",
            "how to signal under concrete rubble",
            "earthquake building collapse survival",
            "confined space collapse air pocket",
            "trapped in fallen building what to do",
            "acoustic tapping signal rubble",
        ]
    },
    {
        "intent": "avalanche_rescue_beacon",
        "category": "Cold, Mountain & Avalanche Survival",
        "urgency": "critical",
        "title": "Avalanche Survival & Transceiver Search Protocol",
        "summary": "Air pocket creation, transceiver search phases (Signal, Coarse, Fine), and V-shaped snow excavation.",
        "steps": [
            "Swim and deploy airbag: When avalanche strikes, drop ski poles, make powerful swimming strokes to stay on snow surface, and deploy avalanche airbag pack immediately.",
            "Create air pocket before snow stops: As movement decelerates, cup hands in front of face and chest, take a deep breath, and expand chest to forge a breathing cavity before snow sets like cement.",
            "Transceiver search sequence: Unaffected members instantly switch transceivers to SEARCH mode. Execute grid pattern during Coarse search, then lower beacon to snow for Fine search.",
            "Avalanche probe pinpointing: Once lowest distance reading is found, probe perpendicular to snow surface in concentric spiral (25 cm intervals) until strike confirms body.",
            "Strategic V-shape snow shoveling: Station diggers downstream in a V-shaped trench to conveyor-shovel snow outward; dig directly toward victim's chest to clear airway immediately.",
        ],
        "warning": "Survival rate plummets from 93% at 15 minutes to under 30% after 35 minutes due to snow suffocation. Act with maximum speed; do not leave to seek help if you can dig.",
        "utterances": [
            "avalanche rescue protocol",
            "avalanche beacon transceiver search",
            "snow slide survival",
            "buried in avalanche air pocket",
            "avalanche probe and shovel technique",
            "how to find buried avalanche victim",
            "snow avalanche survival steps",
            "avalanche companion rescue",
        ]
    },
    {
        "intent": "extreme_heatwave_solar_still",
        "category": "Wilderness & Extreme Survival",
        "urgency": "high",
        "title": "Extreme Heatwave Drought & Solar Still Water Condensation",
        "summary": "Desert survival thermodynamics, ground moisture extraction, and metabolic conservation during heatwaves.",
        "steps": [
            "Excavate pit in sunny ground: Dig a circular pit 1 meter (3 ft) across and 60 cm (2 ft) deep in a sunny patch of earth or dried-out stream bed.",
            "Center the collection container: Place a clean mug, cup, or cut plastic bottle flat on the bottom center of the excavation.",
            "Surround with moisture-rich foliage: Pack damp soil, succulent non-poisonous leaves, or freshly cut green vegetation around the cup (never allowing plants to touch the cup rim).",
            "Airtight plastic sheet seal: Cover pit with a clear plastic sheet; weigh down edges with sand/rocks to create a hermetic seal. Place a small stone in the center directly over the cup.",
            "Solar distillation cycle: Solar radiation heats soil and plant moisture, which evaporates, condenses on the plastic underside, runs down the inverted cone, and drips into the cup (yields 0.5 to 1.5 L/day).",
        ],
        "warning": "DO NOT use toxic plants (such as oleander or hemlock) inside the solar still. NEVER drink untreated seawater or urine (accelerates fatal electrolyte collapse and renal failure).",
        "utterances": [
            "how to build solar still",
            "desert water survival",
            "solar still condensation hole",
            "survive extreme heatwave drought",
            "water from soil plastic sheet",
            "wilderness water still",
            "how to get water in desert",
            "emergency water condensation still",
            "survival in 45 degree heat",
        ]
    },
    {
        "intent": "ground_to_air_rescue_signals",
        "category": "Search & Rescue",
        "urgency": "high",
        "title": "Ground-to-Air Emergency Signals & Heliograph Mirror Flash",
        "summary": "International aviation search & rescue ground marks, signal fire triangles, and emergency mirror heliographs.",
        "steps": [
            "Construct standard ground symbols: Make large 3-meter (10 ft) symbols with rocks, branches, or cleared brush: 'V' = Need Assistance, 'X' = Need Medical Assistance, 'N' = No, 'Y' = Yes, '->' = Heading this way.",
            "Distress fire triangle: Light 3 fires placed 30 meters apart in an equilateral triangle. Add green pine boughs, damp leaves, or rubber tires to generate thick white or black smoke plumes.",
            "Heliograph mirror flash targeting: Hold mirror close to eye, extend opposite hand pointing thumb at rescue plane, reflect sun spot onto thumb, then align reflection flash with aircraft cockpit.",
            "Safe helicopter landing approach: Stay 50 meters back. Wear eye protection against rotor downdraft. Never approach until pilot gives visible thumbs-up; always approach from downhill/front.",
            "High-contrast aerial marker: Spread an orange emergency space blanket flat on an open ridge; secure four corners with heavy rocks to create an unmistakable satellite/aircraft target.",
        ],
        "warning": "NEVER aim lasers or high-powered searchlights directly at aircraft windshields (causes catastrophic pilot flash blindness). Never approach the tail rotor under any circumstance.",
        "utterances": [
            "ground to air rescue signals",
            "emergency signals for aircraft",
            "how to use signal mirror heliograph",
            "three fires triangle rescue",
            "ground symbols for search plane",
            "v and x ground distress marks",
            "helicopter landing zone signaling",
            "signal rescue helicopter",
            "ground distress markers aviation",
        ]
    },
    {
        "intent": "psychological_first_aid",
        "category": "General Guidance",
        "urgency": "advisory",
        "title": "Psychological First Aid (PFA) & Acute Trauma De-escalation",
        "summary": "Evidence-based crisis intervention to stabilize hyperventilation, acute grief, panic paralysis, and shock.",
        "steps": [
            "Calm presence and safety assurance: Introduce yourself clearly: 'My name is [Name] with RakshaNet. You are safe here.' Speak with a slow, low, and steady voice.",
            "Box Breathing for hyperventilation: Guide victim through 4-4-4-4 rhythm: Inhale for 4 seconds, hold lungs full 4 seconds, exhale 4 seconds, hold empty 4 seconds. Repeat for 5 cycles.",
            "5-4-3-2-1 Sensory grounding: Instruct victim to name 5 things they see, 4 things they can touch, 3 sounds they hear, 2 things they smell, and 1 positive survival affirmation.",
            "Concrete practical assistance: Prioritize essential basic physical needs (sip of water, warm blanket, dry clothing, checking on family members). Break problems into single immediate steps.",
            "Compassionate validation: Avoid cliches like 'Everything happens for a reason'. Validate reality: 'It makes complete sense that you feel overwhelmed right now; take it one breath at a time.'",
        ],
        "warning": "DO NOT leave severely disoriented, combative, or suicidal victims unattended. Keep traumatized victims clear of structural ledges, swift currents, and live wires.",
        "utterances": [
            "psychological first aid pfa",
            "how to calm down in disaster panic",
            "panic attack breathing exercise",
            "trauma grounding 5 4 3 2 1",
            "dealing with shock after catastrophe",
            "helping crying hysterical victim",
            "crisis mental health de escalation",
            "how to calm crying survivor",
            "disaster trauma support",
        ]
    },
    {
        "intent": "waterborne_epidemic_prevention",
        "category": "Camp Sanitation & Epidemic Control",
        "urgency": "high",
        "title": "Waterborne Epidemic Prevention (Cholera, Typhoid, Dysentery)",
        "summary": "Camp outbreak containment, chlorine dosage calculations, oral rehydration therapy, and fecal barrier hygiene.",
        "steps": [
            "Emergency household bleach water dosage: Add 2 drops of standard unscented 5-6% sodium hypochlorite bleach per 1 Liter of clear water (4 drops for cloudy water). Shake and wait 30 minutes before drinking.",
            "SODIS Solar Disinfection: Fill clear PET plastic beverage bottles, shake 20 seconds to aerate, fill completely, and lay flat on corrugated metal roof in full sun for 6 hours (or 48 hours in overcast skies).",
            "Cholera diarrhea ORS treatment: Administer 200 to 400 mL of clean ORS solution after every loose watery stool to balance fluid loss and prevent fatal hypovolemic collapse.",
            "Boiled water and food barrier: Boil all water vigorously for 1 minute (3 minutes at high altitudes). Eat only freshly cooked food served hot; never consume raw salads or unpeeled fruit.",
            "Strict hand disinfection: Wash hands with soap and water or 0.05% dilute chlorine solution immediately after using latrines and prior to handling or preparing any food.",
        ],
        "warning": "DO NOT use scented, splashless, or color-safe bleach (they contain toxic industrial detergents). If chlorine odor is missing after 30 minutes, repeat the dose.",
        "utterances": [
            "cholera outbreak first aid",
            "waterborne disease prevention disaster",
            "emergency chlorine bleach water dosage",
            "sodis solar water disinfection",
            "typhoid dysentery prevention in refugee camp",
            "disaster epidemic water sanitation",
            "how to treat cholera diarrhea",
            "bleach drops per liter water",
            "prevent epidemic in evacuation shelter",
        ]
    },
    {
        "intent": "field_sanitation_latrine",
        "category": "Camp Sanitation & Epidemic Control",
        "urgency": "advisory",
        "title": "Disaster Camp Field Latrines & Emergency Sanitation",
        "summary": "Construction of shallow/deep trench latrines, graywater soakage pits, and fecal-oral barrier management.",
        "steps": [
            "Safe siting distances: Dig latrines at least 30 meters (100 ft) downhill from any water source (wells, rivers, ponds) and at least 15 meters from living/cooking shelters.",
            "Shallow trench latrine dimensions: Dig trench 30 cm (1 ft) wide, 1-2 meters long, and 50 cm (20 in) deep. Mound excavated earth along the rear with a hand shovel.",
            "Soil and ash covering: After each use, scoop 5 cm of dry excavated soil, wood ash, or lime into the trench to eliminate odors and block fly access.",
            "Tippy-tap handwashing station: Suspend a plastic jug filled with water by rope next to latrine exit, with a bar of soap on a string, operated by foot-lever stick.",
            "Latrine closure and backfill: When trench contents reach within 30 cm of ground surface, backfill completely with soil, pack down firmly, and clearly signpost area.",
        ],
        "warning": "Open defecation near flood zones or water bodies causes rapid catastrophic outbreaks of cholera and hepatitis. Never construct latrines uphill of groundwater wells.",
        "utterances": [
            "how to build emergency latrine",
            "camp sanitation disaster",
            "field latrine distance from water",
            "trench toilet refugee camp",
            "disaster waste disposal",
            "soakage pit graywater",
            "tippy tap handwash build",
            "emergency toilet sanitation",
            "cat hole latrine distance",
        ]
    },
    {
        "intent": "amputation_crush_syndrome",
        "category": "Medical & First Aid",
        "urgency": "critical",
        "title": "Traumatic Amputation & Crush Syndrome Triage Protocol",
        "summary": "Emergency tourniquet placement, severed limb preservation, and fatal reperfusion shock prevention in crush victims.",
        "steps": [
            "Immediate tourniquet application: Apply windlass tourniquet 5-7 cm (2-3 in) proximal to amputation stump. Tighten until bright arterial spurting stops completely.",
            "Wrap and preserve severed limb: Wrap severed part in sterile gauze dampened with clean saline. Place inside a dry sealed plastic bag; place that bag into a second container filled with ice water.",
            "Crush Syndrome reperfusion hazard: When heavy rubble traps a limb for >15 minutes, ischemic muscle tissue builds up lethal potassium, lactic acid, and myoglobin.",
            "Pre-release fluid resuscitation: Administer copious oral or intravenous fluids BEFORE lifting the heavy weight off the trapped limb to prevent acute kidney shutdown and sudden cardiac arrest.",
            "Pre-release tourniquet technique: If prolonged entrapment (>2 hours) occurred and advanced medical transport is unavailable, apply tourniquet just before lifting debris to block toxic surge.",
        ],
        "warning": "NEVER place severed body parts directly on ice, dry ice, or submerged in water (causes fatal frostbite tissue necrosis). Never loosen an emergency tourniquet once applied.",
        "utterances": [
            "traumatic amputation first aid",
            "severed finger limb preservation",
            "crush syndrome trapped under heavy object",
            "crush injury release protocol",
            "arm leg cut off bleeding",
            "tourniquet for amputation",
            "crush reperfusion shock",
            "how to store severed finger",
            "pinned under concrete crush syndrome",
        ]
    },
    {
        "intent": "chest_trauma_flail_chest",
        "category": "Medical & First Aid",
        "urgency": "critical",
        "title": "Sucking Chest Wound (Pneumothorax) & Flail Chest Protocol",
        "summary": "Sealing open thoracic wounds with vented occlusive dressing and stabilizing multiple rib fractures.",
        "steps": [
            "Immediate airtight wound occlusion: Cover open chest puncture immediately with a gloved hand or airtight material (plastic wrapper, foil, credit card) when bubbling blood or hissing is noted.",
            "Three-sided flutter valve dressing: Tape plastic dressing down on 3 sides only, leaving the bottom edge free to vent air during exhalation while blocking entry during inhalation.",
            "Recognize Tension Pneumothorax: If patient develops worsening cyanosis, extreme air hunger, distended neck veins, or tracheal deviation, 'burp' the dressing immediately by lifting the open edge.",
            "Flail chest paradox stabilization: If a section of ribs moves inward during inhalation and outward during exhalation (flail chest), tape a thick folded towel pad securely over the segment.",
            "Positioning: Keep conscious victim in semi-reclined sitting posture leaning slightly TOWARD the injured side to permit maximum uninhibited expansion of the healthy lung.",
        ],
        "warning": "DO NOT tape down all four sides of an improvised dressing: Air will become trapped inside pleural cavity, producing a fatal tension pneumothorax that crushes the heart and lungs.",
        "utterances": [
            "sucking chest wound first aid",
            "open pneumothorax dressing",
            "three sided flutter valve dressing",
            "flail chest multiple broken ribs",
            "hole in chest breathing hissing",
            "punctured lung emergency care",
            "bullet wound chest first aid",
            "knife wound to chest first aid",
            "tension pneumothorax burping",
        ]
    },
    {
        "intent": "eye_injuries_chemical_splash",
        "category": "Medical & First Aid",
        "urgency": "critical",
        "title": "Eye Trauma, Impaled Objects & Chemical Ocular Burn Protocol",
        "summary": "Immediate neutral irrigation for chemical splashes and rigid shielding for penetrating corneal trauma.",
        "steps": [
            "Continuous 20-minute irrigation for chemical splash: Flush eye immediately under cool running water or sterile saline for 15-30 continuous minutes. Flush from inner nose outward.",
            "Stabilize impaled objects in the eye: NEVER pull out a pencil, glass shard, or nail impaled in the eye. Anchor object with rolled gauze rings and tape a rigid paper cup over it.",
            "Cover BOTH eyes: Human eyes track in tandem; covering the uninjured eye prevents involuntary movement of the injured eye, shielding the retina from further laceration.",
            "Loose foreign particles on cornea: Pull upper eyelid down over lower eyelashes to sweep particle, or rinse with eye drops. Never rub the eyeball with fingers.",
            "Blunt trauma hyphema: If pool of dark blood appears in the anterior iris chamber, keep patient resting sitting upright at 45 degrees to avoid elevated intraocular pressure.",
        ],
        "warning": "NEVER apply direct pressure or compressive bandages over an eyeball with penetrating trauma. DO NOT try to neutralize acid burns with alkaline solutions (rinse with clean water only).",
        "utterances": [
            "chemical in eye first aid",
            "acid alkali eye splash flush",
            "object stuck in eye penetrating trauma",
            "eye injury first aid",
            "scratch on eyeball foreign object",
            "bleeding inside eye hyphema",
            "battery acid in eye",
            "bleach splashed into eye what to do",
            "cut eyeball first aid",
        ]
    },
    {
        "intent": "industrial_toxic_gas_shelter_in_place",
        "category": "CBRN & Hazardous Materials",
        "urgency": "critical",
        "title": "Industrial Gas Leak (Ammonia, Chlorine, H2S) Shelter-in-Place",
        "summary": "Aerosol barrier sealing, elevation selection based on gas density, and wet cloth respirator improvisation.",
        "steps": [
            "Evaluate gas weight characteristics: Chlorine, Phosgene, and LPG are heavier than air (sink into basements and gullies); Ammonia and Methane are lighter than air (rise).",
            "Select shelter room elevation: For heavier-than-air toxic clouds (Chlorine), shelter in highest available room with few windows. For lighter-than-air gases, shelter at ground level.",
            "Hermetically seal windows and vents: Seal perimeter seams, keyholes, and HVAC registers with plastic sheeting and duct tape, or pack with wet towels.",
            "Shut down all HVAC systems: Turn off air conditioning units, furnace blowers, exhaust fans, and close chimney flues to avoid pulling outside contaminated air indoors.",
            "Improvised wet cloth mask: Breathe through a thick cloth or towel soaked in water (water rapidly dissolves and neutralizes soluble acidic gases like ammonia and chlorine).",
        ],
        "warning": "DO NOT ignite matches, candles, or electrical appliances during chemical leaks (combustible gas clouds detonate instantly). Avoid low-lying basements during chlorine leaks.",
        "utterances": [
            "chlorine gas leak shelter in place",
            "toxic ammonia leak emergency",
            "industrial chemical cloud protocol",
            "shelter in place chemical disaster",
            "hydrogen sulfide h2s gas safety",
            "how to seal room toxic gas",
            "chemical plant leak emergency",
            "bhopal gas leak protocol",
            "toxic gas cloud approaching",
        ]
    },
    {
        "intent": "radioactive_fallout_shelter",
        "category": "CBRN & Hazardous Materials",
        "urgency": "critical",
        "title": "Nuclear Fallout Shelter & Radiation Shielding (7:10 Rule)",
        "summary": "Inverse square law, mass barrier halving thicknesses, and 7:10 rule of radioisotope decay.",
        "steps": [
            "Seek maximum shielding mass: Best shelter is a subterranean basement, underground garage, or interior center room of a multi-story concrete building.",
            "Understand radiation halving thickness: Heavy mass absorbs gamma rays: 1 cm Lead = 6 cm Concrete = 9 cm Soil/Earth = 20 cm Water = 30 cm Wood.",
            "Apply the 7:10 Rule of Decay: For every 7-fold increase in time after a nuclear detonation, fallout radiation decreases by a factor of 10. (At 7 hours: 10% remaining; at 49 hours: 1% remaining).",
            "Immediate strip and wash: If caught in fallout, strip outer layers into sealed plastic bags; shower thoroughly with soap and water, avoiding scrubbing that breaks skin.",
            "Consume only sealed food: Eat only canned goods or sealed food packages that were stored indoors. Thoroughly wipe container exteriors with a clean wet cloth before opening.",
        ],
        "warning": "Remain strictly sheltered indoors for a minimum of 48 to 72 hours until civil defense authorities declare fallout safe. NEVER use hair conditioner (it binds radioactive dust).",
        "utterances": [
            "nuclear fallout survival",
            "how to survive nuclear explosion radiation",
            "radiation shielding mass concrete",
            "7 10 rule of radiation decay",
            "fallout shelter protocol",
            "dirty bomb radioactive decontamination",
            "nuclear bomb after attack steps",
            "nuclear blast survival guide",
            "radiation fallout protection",
        ]
    },
    {
        "intent": "blizzard_winter_storm_entrapment",
        "category": "Cold, Mountain & Avalanche Survival",
        "urgency": "high",
        "title": "Winter Blizzard Stranded Vehicle & Snowbound Survival",
        "summary": "Vehicle exhaust carbon monoxide management, thermal cabin insulation, and aerial rescue marking.",
        "steps": [
            "Stay inside the vehicle: Do NOT venture out into a whiteout blizzard; freezing temperatures, wind chill, and spatial disorientation kill within minutes. The vehicle is your survival cocoon.",
            "Clear exhaust tailpipe continuously: Shovel snow away from vehicle tailpipe regularly. A snow-clogged exhaust pumps odorless lethal Carbon Monoxide (CO) into the passenger cabin in minutes.",
            "Run engine 10 minutes per hour: Run the motor and heater for only 10 minutes every hour to conserve gasoline. Crack open downwind window 1 cm while engine runs for fresh oxygen.",
            "Maintain body circulation: Periodically clap hands, wiggle toes, flex abdominal muscles, and rotate shoulders to generate internal body heat and prevent frostbite.",
            "Bright distress flag: Tie a vibrant red or orange cloth to vehicle antenna or mirror. At night, keep dome light illuminated while engine is idling.",
        ],
        "warning": "NEVER sleep with the vehicle engine running continuously: Snowdrifts can shift and bury the tailpipe unnoticed while you sleep, causing fatal carbon monoxide poisoning.",
        "utterances": [
            "stranded in car during snowstorm",
            "winter blizzard vehicle survival",
            "snowbound car carbon monoxide",
            "car stuck in deep snow winter",
            "surviving extreme blizzard in car",
            "whiteout freezing car shelter",
            "trapped in vehicle snowstorm",
            "blizzard vehicle survival guide",
        ]
    },
    {
        "intent": "wildfire_burnover_entrapment",
        "category": "Natural Hazards & Disasters",
        "urgency": "critical",
        "title": "Wildfire Burnover Entrapment & Fire Shelter Deployment",
        "summary": "Emergency entrapment tactics, mineral soil clearing, thermal radiative shielding, and windward escape.",
        "steps": [
            "Avoid topographic chimneys and draws: Wildfires accelerate up steep canyons and ridges at catastrophic speeds. Never try to outrun a fire uphill.",
            "Retreat into 'The Black': If safe opening exists, cross through the flame front into already-burned black ground where no combustible fuel remains to sustain flames.",
            "Scrape down to bare mineral soil: Clear all leaves, grass, and needles down to bare mineral dirt in a 4x8 ft rectangle on flat terrain away from heavy timber.",
            "Deploy emergency fire shelter / lie prone: Lie face-down on bare soil with feet pointed toward the flame front. Cover mouth and nose with a dry or lightly damp cotton bandanna.",
            "Breathe ground-level air: The coolest, cleanest oxygen pocket during a wildfire burnover exists within the bottom 5 cm of the soil surface. Push mouth into dirt.",
        ],
        "warning": "DO NOT seek shelter inside elevated wooden cabins or vehicles parked over tall dry brush. Inhaling superheated gas (over 150°C) sears the respiratory tract causing instant asphyxiation.",
        "utterances": [
            "wildfire entrapment burnover",
            "trapped by forest fire what to do",
            "how to deploy emergency fire shelter",
            "surviving bushfire overrun",
            "wildfire flame front approaching",
            "caught in wildfire on foot",
            "forest fire surrounding me",
            "burnover safety protocol",
        ]
    },
    {
        "intent": "emergency_vehicle_submersion",
        "category": "Water & Swiftwater Rescue",
        "urgency": "critical",
        "title": "Sinking Car Submersion & Rapid Underwater Vehicle Escape",
        "summary": "SWCO protocol: Seatbelts off, Windows open, Children unbuckled, Out immediately.",
        "steps": [
            "Escape during 60-second floating phase: Sinking vehicles float for 30 to 120 seconds before water submerges window sills. Act immediately before electric short circuits.",
            "Follow the S-W-C-O sequence: Seatbelts unbuckled -> Windows rolled down -> Children unbuckled and pulled close -> Out through the window opening immediately.",
            "Roll down power windows instantly: Electric windows continue functioning for up to 60 seconds after water immersion; push window buttons down without delay.",
            "Shatter side windows if jammed: Strike the bottom corner of a tempered side window with a spring-loaded center punch or metal headrest prongs (never front windshield).",
            "Submerged pressure equalization: If vehicle is fully submerged, wait until cabin fills with water to equalize external pressure, take a deep breath, and shove door open.",
        ],
        "warning": "DO NOT try to open the vehicle door while the car is still floating: Water pressure outside prevents door opening and rapidly floods the passenger compartment.",
        "utterances": [
            "car sinking in water escape",
            "submerged vehicle protocol",
            "how to get out of sinking car",
            "car fell in river lake escape",
            "break window underwater car",
            "swco escape protocol",
            "sinking automobile emergency",
            "vehicle into water escape",
        ]
    },
    {
        "intent": "forest_signaling_whistle_code",
        "category": "Search & Rescue",
        "urgency": "high",
        "title": "Emergency Whistle Codes, Mirror Flash & Audio Signaling",
        "summary": "Standard international distress whistle patterns, auditory range maximization, and search response recognition.",
        "steps": [
            "International distress whistle code: 3 sharp, powerful blasts (each blast lasting 3 seconds, with 1 second pause between blasts). Wait 60 seconds, then repeat 3 blasts.",
            "Rescuer acknowledgment reply: 2 loud blasts signifies that search & rescue teams have heard your distress signal and are closing in on your position.",
            "Auditory range superiority: High-frequency pea-less safety whistles travel up to 1.6 km (1 mile)—3 times farther than human shouting—and prevent vocal strain.",
            "Ground travel pointers: If forced to leave location to find water, place rock arrows or bent branches pointing in your exact direction of travel for tracker teams.",
            "Night torch signal: Flash high-intensity torch 3 times in rapid sequence, wait 10 seconds, and repeat 3 flashes.",
        ],
        "warning": "Never blow your whistle continuously without stopping: Pausing allows you to listen for search team calls, rescue sirens, and tracking dog barking.",
        "utterances": [
            "emergency whistle signals",
            "three whistle blasts meaning",
            "how to signal for help in woods",
            "distress whistle code mountain",
            "audio search and rescue signaling",
            "lost in forest whistle pattern",
            "mountain whistle code distress",
            "how many whistle blasts for help",
        ]
    },
    {
        "intent": "emergency_ration_calorie_management",
        "category": "Survival Skills & Rations",
        "urgency": "advisory",
        "title": "Disaster Calorie Budgeting & Emergency Food Rationing",
        "summary": "Metabolic conservation, macronutrient prioritization, and rationing schedules for extended confinement.",
        "steps": [
            "The Survival Rule of Threes: Humans can endure 3 minutes without air, 3 days without water, and 3 weeks without food. Prioritize water conservation over eating.",
            "First 24 hours fasting: Avoid eating solid food during the first 24 hours of confinement unless ample drinking water exists (metabolizing food consumes bodily water reserves).",
            "Calorie baseline target: Adult survivors require minimum 800-1200 kcal/day to maintain essential metabolic function, prevent brain fog, and avoid ketoacidosis.",
            "Prioritize carbohydrates over proteins: Carbohydrates require significantly less metabolic water to process than salty dried meats or high-protein bars.",
            "Protect rations from contamination: Keep dry foods in airtight containers above floor level to prevent water absorption and rodent access.",
        ],
        "warning": "If daily drinking water is under 1 Liter/day, drastically REDUCE food consumption: Digesting nutrients draws water from vital organs, accelerating lethal dehydration.",
        "utterances": [
            "how to ration food disaster",
            "calorie management survival",
            "emergency food rationing schedule",
            "eating without water survival risk",
            "how long can human survive without food",
            "food rationing in bunker shelter",
            "how to survive with little food",
            "survival calorie budget",
        ]
    },
    {
        "intent": "improvised_splints_slings",
        "category": "Medical & First Aid",
        "urgency": "high",
        "title": "Improvised Field Splints, Slings & Joint Immobilization",
        "summary": "Anatomical splinting, Sam splint molding, and triangular swathe immobilization for extremity fractures.",
        "steps": [
            "Anatomical buddy splinting: Splint a fractured finger or toe to an adjacent uninjured digit with tape, or bind an injured leg to the healthy leg with padding between knees.",
            "Rigid improvised splints: Use stiff magazines, thick cardboard, branches, or tent poles padded with clothing on both sides of the injured limb.",
            "Immobilize joint above and below: A splint must lock both the joint directly above and directly below the bone break to eliminate bone movement.",
            "Triangular bandage arm sling: Support forearm bent at 90 degrees with hand elevated slightly above elbow; secure forearm across chest with a broad cloth swathe.",
            "Check CSM every 15 minutes: Evaluate Circulation (radial/pedal pulse), Sensation (feeling light touch), and Motor function (wiggling toes/fingers) periodically.",
        ],
        "warning": "DO NOT wrap splint bindings so tightly that circulation is cut off. If toes/fingers turn cold, white, or blue, loosen ties immediately.",
        "utterances": [
            "how to make a sling",
            "improvised splint cardboard stick",
            "buddy taping broken finger",
            "arm fracture sling first aid",
            "splinting leg broken bone",
            "field immobilization broken joint",
            "triangular bandage arm sling",
            "improvised leg splint sticks",
        ]
    },
    {
        "intent": "wilderness_food_edibility_test",
        "category": "Wilderness & Extreme Survival",
        "urgency": "advisory",
        "title": "Universal Edibility Test & Toxic Plant Identification",
        "summary": "Sequential 8-step safety protocol for testing unknown wild plant vegetation for oral toxicity.",
        "steps": [
            "Test only abundant plant species: Test only plants that exist in large quantities to justify the full 24-hour testing procedure.",
            "Visual warning checks: Avoid plants with milky white sap, umbrella-shaped flower clusters, beans inside pods, fine spine hairs, or bitter almond smells.",
            "Contact skin sensitivity: Rub crushed plant juice onto sensitive skin on inner forearm; wait 15 minutes for burning, rash, or irritation.",
            "Lip contact test: Place a small piece of prepared plant on outer lip for 3 minutes; monitor for tingling, stinging, or numbness.",
            "Tongue and chew stage: Place piece on tip of tongue for 15 minutes; if no reaction, chew thoroughly and hold in mouth 15 minutes without swallowing.",
            "8-hour wait period: Swallow the sample and wait 8 hours without eating anything else; if nausea or stomach cramps develop, induce vomiting immediately.",
        ],
        "warning": "NEVER use the Universal Edibility Test on mushrooms or wild fungi: Fatal fungal amatoxins have zero taste, give no immediate symptoms, and destroy internal organs days later.",
        "utterances": [
            "universal edibility test steps",
            "how to test wild plants for poison",
            "is this plant edible survival",
            "safe wild survival food test",
            "toxic wild plants identification",
            "poisonous plant rules survival",
            "how to test plants to eat",
            "wilderness foraging safety test",
        ]
    },
    {
        "intent": "crevasse_extrication",
        "category": "Cold, Mountain & Avalanche Survival",
        "urgency": "critical",
        "title": "Glacier Crevasse Fall Arrest & 3:1 Z-Pulley Extrication",
        "summary": "Self-arrest mechanics, snow bollard/T-slot deadman anchors, and mechanical advantage hauling systems.",
        "steps": [
            "Immediate partner self-arrest: The unfallen rope partner immediately falls onto chest, driving ice axe pick into hard snow and kicking crampon toes down.",
            "Construct T-slot snow deadman anchor: Excavate a trench 50 cm deep; bury an ice axe, ski, or backpack horizontally as a deadman anchor and transfer load.",
            "Assess suspended climber: Communicate down into crevasse; verify climber consciousness, treat injuries, and direct them to stand in rope foot-loops to relieve harness pressure.",
            "Prusik rope self-ascent: Climber fastens two friction hitches (Prusiks) to fixed rope—one attached to sit harness, one to foot loop—and ascends iteratively.",
            "Rig 3:1 Z-Pulley hauling system: Set up progress capture device at snow anchor, attach traveling pulley with Prusik to load line, and haul with 3-to-1 mechanical advantage.",
        ],
        "warning": "Harness suspension trauma can induce unconsciousness and death within 15-30 minutes if a climber hangs motionless. Keep legs moving continuously.",
        "utterances": [
            "crevasse rescue protocol",
            "fallen into glacier crevasse",
            "z pulley 3 to 1 haul system",
            "deadman snow anchor build",
            "crevasse self arrest technique",
            "suspension trauma prevention harness",
            "how to rescue from crevasse",
            "glacier crevasse fall what to do",
        ]
    },

    {
        "intent": "general_greeting_identity",
        "category": "Conversational & System",
        "title": "RakshaNet AI Assistant (Hybrid Edge & Cloud Architecture)",
        "summary": "Identity, operational status, and comprehensive offline & cloud capabilities.",
        "steps": [
            "Identity: I am RakshaNet AI, your intelligent emergency assistant and survival copilot.",
            "Offline Edge Engine: When cellular networks or power grids fail, my trained on-device machine learning model runs 100% locally on your smartphone with zero latency and zero data consumption.",
            "Online Groq Cloud Engine: When Wi-Fi or cellular networks are active, I connect directly to ultra-fast Groq Cloud Llama-3.3 70B AI to provide comprehensive, detailed answers to any question on Earth.",
            "Topics Supported: Emergency First Aid & CPR, Natural Disasters (Flood, Earthquake, Cyclone, Fire), Survival Skills (Water, Food, Navigation), Radio & Mesh Networking, Math, Science, and General Knowledge.",
            "Quick Actions: Tap any suggestion chip below, ask about any medical condition or disaster, or type any general query."
        ],
        "warning": "RakshaNet AI is designed to save lives in critical conditions. In active emergencies, follow official local disaster authorities and NDMA directives.",
        "utterances": [
            "hello", "hi", "hey", "who are you", "what can you do", "help me",
            "what is rakshanet ai", "what is signalrescue ai", "how do you work", "good morning", "are you an ai", "what are your features"
        ]
    }
]

# ------------------------------------------------------------------------------
# 2. NLP PREPROCESSING, VOCABULARY & TF-IDF VECTORIZATION
# ------------------------------------------------------------------------------

STOP_WORDS = {
    "a", "about", "above", "after", "again", "against", "all", "am", "an", "and",
    "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being",
    "below", "between", "both", "but", "by", "can", "can't", "cannot", "could",
    "couldn't", "did", "didn't", "do", "does", "doesn't", "doing", "don't", "down",
    "during", "each", "few", "for", "from", "further", "had", "hadn't", "has", "hasn't",
    "have", "haven't", "having", "he", "he'd", "he'll", "he's", "her", "here", "here's",
    "hers", "herself", "him", "himself", "his", "how", "how's", "i", "i'd", "i'll",
    "i'm", "i've", "if", "in", "into", "is", "isn't", "it", "it's", "its", "itself",
    "let's", "me", "more", "most", "mustn't", "my", "myself", "no", "nor", "not",
    "of", "off", "on", "once", "only", "or", "other", "ought", "our", "ours",
    "ourselves", "out", "over", "own", "same", "shan't", "she", "she'd", "she'll",
    "she's", "should", "shouldn't", "so", "some", "such", "than", "that", "that's",
    "the", "their", "theirs", "them", "themselves", "then", "there", "there's", "these",
    "they", "they'd", "they'll", "they're", "they've", "this", "those", "through", "to",
    "too", "under", "until", "up", "very", "was", "wasn't", "we", "we'd", "we'll",
    "we're", "we've", "were", "weren't", "what", "what's", "when", "when's", "where",
    "where's", "which", "while", "who", "who's", "whom", "why", "why's", "with",
    "won't", "would", "wouldn't", "you", "you'd", "you'll", "you're", "you've",
    "your", "yours", "yourself", "yourselves"
}

def clean_text(text: str) -> str:
    """Lowercases, removes special characters, and strips whitespace."""
    text = text.lower()
    text = re.sub(r"[^a-z0-9\s]", " ", text)
    return text.strip()

def simple_stem(word: str) -> str:
    """Lightweight suffix stemmer for robust morphological matching."""
    if len(word) <= 3:
        return word
    for suffix in ["tion", "ing", "ies", "ied", "ed", "es", "s", "ly", "ment", "ness"]:
        if word.endswith(suffix) and len(word) - len(suffix) >= 3:
            return word[:-len(suffix)]
    return word

def tokenize(text: str) -> list[str]:
    """Produces stemmed unigrams and selected bigrams for robust intent classification."""
    cleaned = clean_text(text)
    words = [w for w in cleaned.split() if len(w) > 1 and w not in STOP_WORDS]
    stemmed = [simple_stem(w) for w in words]
    tokens = list(stemmed)
    
    # Add word bigrams for compound phrases (e.g., 'cpr_protocol', 'snake_bite')
    for i in range(len(stemmed) - 1):
        bigram = f"{stemmed[i]}_{stemmed[i+1]}"
        tokens.append(bigram)
        
    return tokens

def train_and_compile():
    print("=" * 70)
    print("RakshaNet AI - Training Edge NLP Model & Knowledge Base")
    print("=" * 70)

    # Collect all training documents
    documents = []
    labels = []
    class_intents = []
    
    for item in TRAINING_DATA:
        intent = item["intent"]
        class_intents.append(intent)
        
        # Combine utterances and structured title/steps into training corpus
        corpus_texts = list(item["utterances"])
        corpus_texts.append(item["title"])
        corpus_texts.append(item["summary"])
        corpus_texts.extend(item["steps"])
        
        for text in corpus_texts:
            tokens = tokenize(text)
            if tokens:
                documents.append(tokens)
                labels.append(intent)

    num_docs = len(documents)
    print(f"Total labeled training documents: {num_docs} across {len(class_intents)} classes")

    # Build Vocabulary
    term_doc_freq = Counter()
    for doc in documents:
        unique_terms = set(doc)
        for t in unique_terms:
            term_doc_freq[t] += 1

    # Keep terms that appear at least once
    vocabulary = sorted([term for term, freq in term_doc_freq.items() if freq >= 1])
    vocab_index = {term: idx for idx, term in enumerate(vocabulary)}
    vocab_size = len(vocabulary)
    print(f"Vocabulary size: {vocab_size} unique terms & bigrams")

    # Calculate IDF (Inverse Document Frequency with smoothing)
    idf = {}
    for term, df in term_doc_freq.items():
        if term in vocab_index:
            idf[term] = math.log((1.0 + num_docs) / (1.0 + df)) + 1.0

    # Calculate TF-IDF vectors for each document
    def vectorize(tokens: list[str]) -> dict[int, float]:
        tf = Counter(tokens)
        vec = {}
        norm_sq = 0.0
        for token, count in tf.items():
            if token in vocab_index:
                idx = vocab_index[token]
                val = (1.0 + math.log(count)) * idf[token]
                vec[idx] = val
                norm_sq += val * val
        if norm_sq > 0:
            norm = math.sqrt(norm_sq)
            for idx in vec:
                vec[idx] /= norm
        return vec

    # Compute Class Centroids (Normalized Average Vector per Class)
    class_vectors = defaultdict(lambda: defaultdict(float))
    class_counts = Counter()

    for doc, label in zip(documents, labels):
        vec = vectorize(doc)
        class_counts[label] += 1
        for idx, val in vec.items():
            class_vectors[label][idx] += val

    class_centroids = {}
    for label, vec_sum in class_vectors.items():
        count = class_counts[label]
        centroid = {}
        norm_sq = 0.0
        for idx, val in vec_sum.items():
            avg_val = val / count
            centroid[idx] = avg_val
            norm_sq += avg_val * avg_val
        if norm_sq > 0:
            norm = math.sqrt(norm_sq)
            for idx in centroid:
                centroid[idx] /= norm
        class_centroids[label] = centroid

    # Compute Multinomial Naive Bayes Feature Log-Probabilities
    class_word_counts = defaultdict(Counter)
    class_total_words = Counter()
    
    for doc, label in zip(documents, labels):
        for token in doc:
            if token in vocab_index:
                class_word_counts[label][token] += 1
                class_total_words[label] += 1

    alpha = 1.0  # Laplace smoothing
    feature_log_probs = {}
    class_priors = {}

    for label in class_intents:
        total_w = class_total_words[label]
        class_priors[label] = math.log(class_counts[label] / num_docs)
        feature_log_probs[label] = {}
        denom = total_w + alpha * vocab_size
        for token in vocabulary:
            count = class_word_counts[label][token]
            feature_log_probs[label][token] = math.log((count + alpha) / denom)

    # --------------------------------------------------------------------------
    # 3. ACCURACY EVALUATION (Self-Verification)
    # --------------------------------------------------------------------------
    correct_matches = 0
    total_evals = 0

    for item in TRAINING_DATA:
        expected = item["intent"]
        for query in item["utterances"]:
            tokens = tokenize(query)
            q_vec = vectorize(tokens)
            
            # Predict via Cosine Similarity against Class Centroids
            best_score = -1.0
            best_intent = None
            
            for c_intent, centroid in class_centroids.items():
                score = 0.0
                for idx, val in q_vec.items():
                    if idx in centroid:
                        score += val * centroid[idx]
                if score > best_score:
                    best_score = score
                    best_intent = c_intent
                    
            if best_intent == expected:
                correct_matches += 1
            total_evals += 1

    acc = (correct_matches / total_evals) * 100.0 if total_evals > 0 else 0.0
    print(f"Training utterance classification accuracy: {acc:.2f}% ({correct_matches}/{total_evals})")

    # --------------------------------------------------------------------------
    # 4. EXPORT JSON MODEL (backend/data/offline_ai_model.json)
    # --------------------------------------------------------------------------
    os.makedirs("backend/data", exist_ok=True)
    json_path = "backend/data/offline_ai_model.json"
    
    # Convert centroids with string keys for JSON serialization
    serialized_centroids = {
        label: {str(k): round(v, 6) for k, v in centroid.items()}
        for label, centroid in class_centroids.items()
    }
    
    model_json = {
        "version": "2.0.0",
        "vocabulary_size": vocab_size,
        "vocabulary": vocabulary,
        "idf": {term: round(val, 6) for term, val in idf.items()},
        "centroids": serialized_centroids,
        "knowledge_base": TRAINING_DATA
    }
    
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(model_json, f, indent=2, ensure_ascii=False)
    print(f"Exported JSON model artifact: {json_path}")

    # --------------------------------------------------------------------------
    # 5. COMPILE DIRECTLY INTO DART (mobile/lib/services/ai/trained_offline_model_data.dart)
    # --------------------------------------------------------------------------
    os.makedirs("mobile/lib/services/ai", exist_ok=True)
    dart_path = "mobile/lib/services/ai/trained_offline_model_data.dart"
    
    print(f"Generating optimized Dart compilation artifact: {dart_path}...")
    
    with open(dart_path, "w", encoding="utf-8") as f:
        f.write("""// AUTO-GENERATED BY backend/train_offline_ai_model.py
// DO NOT EDIT DIRECTLY. Run `python backend/train_offline_ai_model.py` to regenerate.
//
// High-Performance On-Device NLP Intent Classifier & Knowledge Engine for RakshaNet.
// Runs 100% offline with zero dependencies and sub-5ms inference latency.

class OfflineModelData {
  static const String version = '2.0.0';

  /// Precomputed Vocabulary (terms and word-bigrams)
""")
        # Vocabulary list
        f.write("  static const List<String> vocabulary = [\n")
        for term in vocabulary:
            f.write(f"    '{term}',\n")
        f.write("  ];\n\n")

        # IDF Map
        f.write("  /// Term Inverse Document Frequency (IDF) weights\n")
        f.write("  static const Map<String, double> idf = {\n")
        for term, val in idf.items():
            f.write(f"    '{term}': {val:.6f},\n")
        f.write("  };\n\n")

        # Class Centroids (Sparse index to weight maps)
        f.write("  /// Normalized Class Centroids for Cosine Similarity Matching\n")
        f.write("  static const Map<String, Map<int, double>> centroids = {\n")
        for label, centroid in class_centroids.items():
            f.write(f"    '{label}': {{\n")
            for idx, val in centroid.items():
                f.write(f"      {idx}: {val:.6f},\n")
            f.write("    },\n")
        f.write("  };\n\n")

        # Structured Knowledge Base
        f.write("  /// Structured Knowledge Base and Procedural Emergency Protocols\n")
        f.write("  static const List<Map<String, dynamic>> knowledgeBase = [\n")
        for item in TRAINING_DATA:
            f.write("    {\n")
            f.write(f"      'intent': '{item['intent']}',\n")
            f.write(f"      'category': '{item['category']}',\n")
            f.write(f"      'urgency': '{item.get('urgency', 'high')}',\n")
            f.write(f"      'title': '{item['title']}',\n")
            f.write(f"      'summary': '{item['summary']}',\n")
            f.write("      'steps': [\n")
            for step in item["steps"]:
                escaped_step = step.replace("'", "\\'")
                f.write(f"        '{escaped_step}',\n")
            f.write("      ],\n")
            escaped_warning = item["warning"].replace("'", "\\'")
            f.write(f"      'warning': '{escaped_warning}',\n")
            f.write("    },\n")
        f.write("  ];\n")
        f.write("}\n")

    print(f"Successfully compiled Dart model artifact ({os.path.getsize(dart_path):,} bytes)!")
    print("=" * 70)

if __name__ == "__main__":
    train_and_compile()
