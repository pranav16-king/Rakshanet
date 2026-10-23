"""
Helper script to expand backend/train_offline_ai_model.py with 24 high-priority disaster management protocols.
"""

NEW_PROTOCOLS = [
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
            "Continuous Re-triage: Patient physiological status changes dynamically; re-evaluate Yellow and Green casualties every 15-30 minutes."
        ],
        "warning": "Do not spend more than 30 seconds assessing any individual patient. Immediately control massive arterial bleeding before moving to next victim.",
        "utterances": [
            "mass casualty triage protocol", "start triage algorithm", "how to triage disaster victims",
            "red yellow green black triage tags", "rpm triage respiration perfusion mental", "triage multiple injured victims",
            "disaster casualty sorting", "who to treat first in mass emergency", "start triage steps",
            "triage tags meaning", "ndma mass casualty triage", "field triage algorithm"
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
            "Double-bag contaminated clothing: Seal stripped clothing, shoes, and gear inside heavy plastic bags; seal airtight with duct tape and move far outside living quarters."
        ],
        "warning": "DO NOT use household bleach on open wounds or eyes. Never touch contaminated clothing with bare hands; use plastic bags or nitrile gloves as an impervious barrier.",
        "utterances": [
            "cbrn decontamination protocol", "chemical weapon attack first aid", "nerve agent exposure treatment",
            "biological hazard decontamination", "toxic chemical spill cleanup on skin", "how to decontaminate after gas attack",
            "cbrn emergency steps", "chlorine gas sarin exposure first aid", "chemical burn decontamination",
            "radiological dust wash skin", "hazardous material hazmat decontamination"
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
            "Watch for energized electrical currents: Floodwaters conduct lethal voltages from submerged transformers and broken utility wires. Keep distance from metal fences and downed cables."
        ],
        "warning": "NEVER drive or walk across moving water. Just 15 cm (6 in) of moving water knocks down an adult; 60 cm (2 ft) sweeps away SUVs and pickup trucks.",
        "utterances": [
            "dam burst survival", "dam break flood emergency", "wall of water flash flood",
            "reservoir breach escape", "catastrophic dam failure protocol", "sudden torrent survival",
            "escaping high velocity flood surge", "dam collapse flood what to do", "water reservoir bursting run"
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
            "Wedge river crossing: Form a linked triangle or wedge with 3 or more people, heaviest person upstream breaking the current, shuffling sideways without crossing legs."
        ],
        "warning": "NEVER try to stand up in fast knee-deep water: Foot entrapment between submerged rocks forces the torso downstream underwater by hydraulic pressure, resulting in rapid drowning.",
        "utterances": [
            "swiftwater rescue technique", "defensive swim position river", "how to survive strong river current",
            "river strainer hazard", "river crossing safety", "swept away by river current",
            "water rescue throw bag technique", "hydraulic hole drowning escape", "fast flowing river survival",
            "foot entrapment river danger"
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
            "Do not dislodge supporting debris: Shifting rubble around your void space can destabilize keystone pieces and trigger catastrophic secondary collapse."
        ],
        "warning": "DO NOT strike matches or lighters under rubble: Ruptured natural gas, methane, or propane lines beneath debris will ignite an explosive catastrophic fireball.",
        "utterances": [
            "building collapse void space", "trapped under rubble tapping", "search and rescue collapsed structure",
            "lean to void pancake collapse", "how to signal under concrete rubble", "earthquake building collapse survival",
            "confined space collapse air pocket", "trapped in fallen building what to do", "acoustic tapping signal rubble"
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
            "Strategic V-shape snow shoveling: Station diggers downstream in a V-shaped trench to conveyor-shovel snow outward; dig directly toward victim's chest to clear airway immediately."
        ],
        "warning": "Survival rate plummets from 93% at 15 minutes to under 30% after 35 minutes due to snow suffocation. Act with maximum speed; do not leave to seek help if you can dig.",
        "utterances": [
            "avalanche rescue protocol", "avalanche beacon transceiver search", "snow slide survival",
            "buried in avalanche air pocket", "avalanche probe and shovel technique", "how to find buried avalanche victim",
            "snow avalanche survival steps", "avalanche companion rescue"
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
            "Solar distillation cycle: Solar radiation heats soil and plant moisture, which evaporates, condenses on the plastic underside, runs down the inverted cone, and drips into the cup (yields 0.5 to 1.5 L/day)."
        ],
        "warning": "DO NOT use toxic plants (such as oleander or hemlock) inside the solar still. NEVER drink untreated seawater or urine (accelerates fatal electrolyte collapse and renal failure).",
        "utterances": [
            "how to build solar still", "desert water survival", "solar still condensation hole",
            "survive extreme heatwave drought", "water from soil plastic sheet", "wilderness water still",
            "how to get water in desert", "emergency water condensation still", "survival in 45 degree heat"
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
            "High-contrast aerial marker: Spread an orange emergency space blanket flat on an open ridge; secure four corners with heavy rocks to create an unmistakable satellite/aircraft target."
        ],
        "warning": "NEVER aim lasers or high-powered searchlights directly at aircraft windshields (causes catastrophic pilot flash blindness). Never approach the tail rotor under any circumstance.",
        "utterances": [
            "ground to air rescue signals", "emergency signals for aircraft", "how to use signal mirror heliograph",
            "three fires triangle rescue", "ground symbols for search plane", "v and x ground distress marks",
            "helicopter landing zone signaling", "signal rescue helicopter", "ground distress markers aviation"
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
            "Compassionate validation: Avoid cliches like 'Everything happens for a reason'. Validate reality: 'It makes complete sense that you feel overwhelmed right now; take it one breath at a time.'"
        ],
        "warning": "DO NOT leave severely disoriented, combative, or suicidal victims unattended. Keep traumatized victims clear of structural ledges, swift currents, and live wires.",
        "utterances": [
            "psychological first aid pfa", "how to calm down in disaster panic", "panic attack breathing exercise",
            "trauma grounding 5 4 3 2 1", "dealing with shock after catastrophe", "helping crying hysterical victim",
            "crisis mental health de escalation", "how to calm crying survivor", "disaster trauma support"
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
            "Strict hand disinfection: Wash hands with soap and water or 0.05% dilute chlorine solution immediately after using latrines and prior to handling or preparing any food."
        ],
        "warning": "DO NOT use scented, splashless, or color-safe bleach (they contain toxic industrial detergents). If chlorine odor is missing after 30 minutes, repeat the dose.",
        "utterances": [
            "cholera outbreak first aid", "waterborne disease prevention disaster", "emergency chlorine bleach water dosage",
            "sodis solar water disinfection", "typhoid dysentery prevention in refugee camp", "disaster epidemic water sanitation",
            "how to treat cholera diarrhea", "bleach drops per liter water", "prevent epidemic in evacuation shelter"
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
            "Latrine closure and backfill: When trench contents reach within 30 cm of ground surface, backfill completely with soil, pack down firmly, and clearly signpost area."
        ],
        "warning": "Open defecation near flood zones or water bodies causes rapid catastrophic outbreaks of cholera and hepatitis. Never construct latrines uphill of groundwater wells.",
        "utterances": [
            "how to build emergency latrine", "camp sanitation disaster", "field latrine distance from water",
            "trench toilet refugee camp", "disaster waste disposal", "soakage pit graywater",
            "tippy tap handwash build", "emergency toilet sanitation", "cat hole latrine distance"
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
            "Pre-release tourniquet technique: If prolonged entrapment (>2 hours) occurred and advanced medical transport is unavailable, apply tourniquet just before lifting debris to block toxic surge."
        ],
        "warning": "NEVER place severed body parts directly on ice, dry ice, or submerged in water (causes fatal frostbite tissue necrosis). Never loosen an emergency tourniquet once applied.",
        "utterances": [
            "traumatic amputation first aid", "severed finger limb preservation", "crush syndrome trapped under heavy object",
            "crush injury release protocol", "arm leg cut off bleeding", "tourniquet for amputation",
            "crush reperfusion shock", "how to store severed finger", "pinned under concrete crush syndrome"
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
            "Positioning: Keep conscious victim in semi-reclined sitting posture leaning slightly TOWARD the injured side to permit maximum uninhibited expansion of the healthy lung."
        ],
        "warning": "DO NOT tape down all four sides of an improvised dressing: Air will become trapped inside pleural cavity, producing a fatal tension pneumothorax that crushes the heart and lungs.",
        "utterances": [
            "sucking chest wound first aid", "open pneumothorax dressing", "three sided flutter valve dressing",
            "flail chest multiple broken ribs", "hole in chest breathing hissing", "punctured lung emergency care",
            "bullet wound chest first aid", "knife wound to chest first aid", "tension pneumothorax burping"
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
            "Blunt trauma hyphema: If pool of dark blood appears in the anterior iris chamber, keep patient resting sitting upright at 45 degrees to avoid elevated intraocular pressure."
        ],
        "warning": "NEVER apply direct pressure or compressive bandages over an eyeball with penetrating trauma. DO NOT try to neutralize acid burns with alkaline solutions (rinse with clean water only).",
        "utterances": [
            "chemical in eye first aid", "acid alkali eye splash flush", "object stuck in eye penetrating trauma",
            "eye injury first aid", "scratch on eyeball foreign object", "bleeding inside eye hyphema",
            "battery acid in eye", "bleach splashed into eye what to do", "cut eyeball first aid"
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
            "Improvised wet cloth mask: Breathe through a thick cloth or towel soaked in water (water rapidly dissolves and neutralizes soluble acidic gases like ammonia and chlorine)."
        ],
        "warning": "DO NOT ignite matches, candles, or electrical appliances during chemical leaks (combustible gas clouds detonate instantly). Avoid low-lying basements during chlorine leaks.",
        "utterances": [
            "chlorine gas leak shelter in place", "toxic ammonia leak emergency", "industrial chemical cloud protocol",
            "shelter in place chemical disaster", "hydrogen sulfide h2s gas safety", "how to seal room toxic gas",
            "chemical plant leak emergency", "bhopal gas leak protocol", "toxic gas cloud approaching"
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
            "Consume only sealed food: Eat only canned goods or sealed food packages that were stored indoors. Thoroughly wipe container exteriors with a clean wet cloth before opening."
        ],
        "warning": "Remain strictly sheltered indoors for a minimum of 48 to 72 hours until civil defense authorities declare fallout safe. NEVER use hair conditioner (it binds radioactive dust).",
        "utterances": [
            "nuclear fallout survival", "how to survive nuclear explosion radiation", "radiation shielding mass concrete",
            "7 10 rule of radiation decay", "fallout shelter protocol", "dirty bomb radioactive decontamination",
            "nuclear bomb after attack steps", "nuclear blast survival guide", "radiation fallout protection"
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
            "Bright distress flag: Tie a vibrant red or orange cloth to vehicle antenna or mirror. At night, keep dome light illuminated while engine is idling."
        ],
        "warning": "NEVER sleep with the vehicle engine running continuously: Snowdrifts can shift and bury the tailpipe unnoticed while you sleep, causing fatal carbon monoxide poisoning.",
        "utterances": [
            "stranded in car during snowstorm", "winter blizzard vehicle survival", "snowbound car carbon monoxide",
            "car stuck in deep snow winter", "surviving extreme blizzard in car", "whiteout freezing car shelter",
            "trapped in vehicle snowstorm", "blizzard vehicle survival guide"
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
            "Breathe ground-level air: The coolest, cleanest oxygen pocket during a wildfire burnover exists within the bottom 5 cm of the soil surface. Push mouth into dirt."
        ],
        "warning": "DO NOT seek shelter inside elevated wooden cabins or vehicles parked over tall dry brush. Inhaling superheated gas (over 150°C) sears the respiratory tract causing instant asphyxiation.",
        "utterances": [
            "wildfire entrapment burnover", "trapped by forest fire what to do", "how to deploy emergency fire shelter",
            "surviving bushfire overrun", "wildfire flame front approaching", "caught in wildfire on foot",
            "forest fire surrounding me", "burnover safety protocol"
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
            "Submerged pressure equalization: If vehicle is fully submerged, wait until cabin fills with water to equalize external pressure, take a deep breath, and shove door open."
        ],
        "warning": "DO NOT try to open the vehicle door while the car is still floating: Water pressure outside prevents door opening and rapidly floods the passenger compartment.",
        "utterances": [
            "car sinking in water escape", "submerged vehicle protocol", "how to get out of sinking car",
            "car fell in river lake escape", "break window underwater car", "swco escape protocol",
            "sinking automobile emergency", "vehicle into water escape"
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
            "Night torch signal: Flash high-intensity torch 3 times in rapid sequence, wait 10 seconds, and repeat 3 flashes."
        ],
        "warning": "Never blow your whistle continuously without stopping: Pausing allows you to listen for search team calls, rescue sirens, and tracking dog barking.",
        "utterances": [
            "emergency whistle signals", "three whistle blasts meaning", "how to signal for help in woods",
            "distress whistle code mountain", "audio search and rescue signaling", "lost in forest whistle pattern",
            "mountain whistle code distress", "how many whistle blasts for help"
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
            "Protect rations from contamination: Keep dry foods in airtight containers above floor level to prevent water absorption and rodent access."
        ],
        "warning": "If daily drinking water is under 1 Liter/day, drastically REDUCE food consumption: Digesting nutrients draws water from vital organs, accelerating lethal dehydration.",
        "utterances": [
            "how to ration food disaster", "calorie management survival", "emergency food rationing schedule",
            "eating without water survival risk", "how long can human survive without food", "food rationing in bunker shelter",
            "how to survive with little food", "survival calorie budget"
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
            "Check CSM every 15 minutes: Evaluate Circulation (radial/pedal pulse), Sensation (feeling light touch), and Motor function (wiggling toes/fingers) periodically."
        ],
        "warning": "DO NOT wrap splint bindings so tightly that circulation is cut off. If toes/fingers turn cold, white, or blue, loosen ties immediately.",
        "utterances": [
            "how to make a sling", "improvised splint cardboard stick", "buddy taping broken finger",
            "arm fracture sling first aid", "splinting leg broken bone", "field immobilization broken joint",
            "triangular bandage arm sling", "improvised leg splint sticks"
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
            "8-hour wait period: Swallow the sample and wait 8 hours without eating anything else; if nausea or stomach cramps develop, induce vomiting immediately."
        ],
        "warning": "NEVER use the Universal Edibility Test on mushrooms or wild fungi: Fatal fungal amatoxins have zero taste, give no immediate symptoms, and destroy internal organs days later.",
        "utterances": [
            "universal edibility test steps", "how to test wild plants for poison", "is this plant edible survival",
            "safe wild survival food test", "toxic wild plants identification", "poisonous plant rules survival",
            "how to test plants to eat", "wilderness foraging safety test"
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
            "Rig 3:1 Z-Pulley hauling system: Set up progress capture device at snow anchor, attach traveling pulley with Prusik to load line, and haul with 3-to-1 mechanical advantage."
        ],
        "warning": "Harness suspension trauma can induce unconsciousness and death within 15-30 minutes if a climber hangs motionless. Keep legs moving continuously.",
        "utterances": [
            "crevasse rescue protocol", "fallen into glacier crevasse", "z pulley 3 to 1 haul system",
            "deadman snow anchor build", "crevasse self arrest technique", "suspension trauma prevention harness",
            "how to rescue from crevasse", "glacier crevasse fall what to do"
        ]
    }
]

import re

def update_training_script():
    script_path = "backend/train_offline_ai_model.py"
    with open(script_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Check if already expanded
    if "mass_casualty_triage_start" in content:
        print("Script already contains expanded protocols.")
        return

    # Find the position right before "general_greeting_identity"
    target_pattern = r'(\s+\{\s+"intent":\s*"general_greeting_identity",)'
    match = re.search(target_pattern, content)
    if not match:
        raise ValueError("Could not find general_greeting_identity in script")

    insert_pos = match.start(1)

    # Format new protocols as python code
    import json
    new_blocks = []
    for item in NEW_PROTOCOLS:
        lines = ["    {"]
        lines.append(f'        "intent": "{item["intent"]}",')
        lines.append(f'        "category": "{item["category"]}",')
        lines.append(f'        "urgency": "{item["urgency"]}",')
        lines.append(f'        "title": "{item["title"]}",')
        lines.append(f'        "summary": "{item["summary"]}",')
        lines.append('        "steps": [')
        for s in item["steps"]:
            escaped = s.replace('"', '\\"')
            lines.append(f'            "{escaped}",')
        lines.append('        ],')
        escaped_w = item["warning"].replace('"', '\\"')
        lines.append(f'        "warning": "{escaped_w}",')
        lines.append('        "utterances": [')
        for u in item["utterances"]:
            escaped_u = u.replace('"', '\\"')
            lines.append(f'            "{escaped_u}",')
        lines.append('        ]')
        lines.append("    },")
        new_blocks.append("\n".join(lines))

    insertion_text = "\n" + "\n".join(new_blocks) + "\n"

    new_content = content[:insert_pos] + insertion_text + content[insert_pos:]

    # Also make sure the Dart generator includes 'urgency'
    # Look for: f.write(f"      'category': '{item['category']}',\n")
    dart_gen_target = "f.write(f\"      'category': '{item['category']}',\\n\")"
    dart_gen_replacement = "f.write(f\"      'category': '{item['category']}',\\n\")\n            f.write(f\"      'urgency': '{item.get('urgency', 'high')}',\\n\")"
    
    if dart_gen_target in new_content:
        new_content = new_content.replace(dart_gen_target, dart_gen_replacement, 1)

    with open(script_path, "w", encoding="utf-8") as f:
        f.write(new_content)

    print(f"Successfully added {len(NEW_PROTOCOLS)} protocols to {script_path}!")

if __name__ == "__main__":
    update_training_script()
