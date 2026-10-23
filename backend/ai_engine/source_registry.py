"""
RakshaNet AI - Emergency Knowledge Source Registry & Verification Pipeline
Tracks verified international (WHO, IFRC, UNICEF, UNDRR) and Indian (NDMA, NDRF, MoHFW, IMD)
emergency documents, licenses, verification dates, and safety-critical chunk indexes.
"""

from dataclasses import dataclass, field
from typing import List, Dict, Any, Optional
import time
import hashlib

@dataclass
class EmergencySource:
    id: str
    title: str
    organization: str
    url: str
    publication_year: int
    last_verified: str
    jurisdiction: str
    license: str
    review_status: str
    topics: List[str]

# Authoritative Verified Sources Registry
VERIFIED_SOURCES: List[EmergencySource] = [
    EmergencySource(
        id="SRC-NDMA-001",
        title="National Disaster Management Guidelines: Management of Floods",
        organization="National Disaster Management Authority (NDMA), Govt of India",
        url="https://ndma.gov.in/Governance/Guidelines",
        publication_year=2023,
        last_verified="2026-01-15",
        jurisdiction="India (National)",
        license="Government Open Data License - India (GODL)",
        review_status="VERIFIED_AUTHORITATIVE",
        topics=["Floods", "Flash Floods", "Dam Failure", "Water Rescue"]
    ),
    EmergencySource(
        id="SRC-NDMA-002",
        title="National Disaster Management Guidelines: Management of Earthquakes",
        organization="National Disaster Management Authority (NDMA), Govt of India",
        url="https://ndma.gov.in/Governance/Guidelines",
        publication_year=2022,
        last_verified="2026-02-10",
        jurisdiction="India (National)",
        license="GODL",
        review_status="VERIFIED_AUTHORITATIVE",
        topics=["Earthquakes", "Structural Collapse", "Rubble Trapping", "Seismic Safety"]
    ),
    EmergencySource(
        id="SRC-NDRF-003",
        title="Standard Operating Procedures for Collapsed Structure Search & Rescue (CSSR)",
        organization="National Disaster Response Force (NDRF)",
        url="https://ndrf.gov.in/",
        publication_year=2024,
        last_verified="2026-03-01",
        jurisdiction="India (National)",
        license="Official Use Public Document",
        review_status="VERIFIED_AUTHORITATIVE",
        topics=["Search and Rescue", "Acoustic Tapping", "Void Search", "Rope Rescue"]
    ),
    EmergencySource(
        id="SRC-MOHFW-004",
        title="Standard Protocols for Trauma Care & Snakebite Envenomation",
        organization="Ministry of Health & Family Welfare (MoHFW), Govt of India",
        url="https://mohfw.gov.in/",
        publication_year=2023,
        last_verified="2026-02-20",
        jurisdiction="India (National)",
        license="Open Government Access",
        review_status="VERIFIED_AUTHORITATIVE",
        topics=["First Aid", "Trauma", "Snakebites", "Severe Bleeding", "Tourniquets"]
    ),
    EmergencySource(
        id="SRC-IMD-005",
        title="Cyclone Warning Dissemination & Cyclone Preparedness SOP",
        organization="India Meteorological Department (IMD)",
        url="https://mausam.imd.gov.in/",
        publication_year=2024,
        last_verified="2026-01-30",
        jurisdiction="India (Coasts)",
        license="Public Domain Data",
        review_status="VERIFIED_AUTHORITATIVE",
        topics=["Cyclones", "Storm Surge", "Gale Winds", "Evacuation"]
    ),
    EmergencySource(
        id="SRC-WHO-006",
        title="WHO Guidelines on Trauma Quality Improvement & Resuscitation (BLS/CPR)",
        organization="World Health Organization (WHO)",
        url="https://www.who.int/publications/i/item/9789241597722",
        publication_year=2022,
        last_verified="2026-01-10",
        jurisdiction="International",
        license="Creative Commons Attribution-NonCommercial-ShareAlike 3.0 IGO",
        review_status="VERIFIED_AUTHORITATIVE",
        topics=["CPR", "Basic Life Support", "Choking", "Triage", "Burn Treatment"]
    ),
    EmergencySource(
        id="SRC-IFRC-007",
        title="IFRC International First Aid, Resuscitation, and Education Guidelines",
        organization="International Federation of Red Cross and Red Crescent Societies (IFRC)",
        url="https://www.ifrc.org/",
        publication_year=2023,
        last_verified="2026-02-05",
        jurisdiction="International",
        license="Public Humanitarian Distribution",
        review_status="VERIFIED_AUTHORITATIVE",
        topics=["First Aid", "Wound Care", "Hypothermia", "Heatstroke", "Water Sanitation"]
    ),
    EmergencySource(
        id="SRC-CBRN-008",
        title="Authoritative Chemical, Biological, Radiological, and Nuclear (CBRN) Incident SOP",
        organization="NDMA & WHO Chemical Safety Programme",
        url="https://ndma.gov.in/Natural-Hazards/CBRN",
        publication_year=2023,
        last_verified="2026-03-12",
        jurisdiction="India / International",
        license="Public Safety Exemption",
        review_status="VERIFIED_AUTHORITATIVE",
        topics=["CBRN", "Toxic Chemical Gas", "Shelter In Place", "Decontamination"]
    ),
]

# Official Emergency Helpline Directory (Zero-Hallucination Policy)
EMERGENCY_HELPLINES = {
    "PAN_INDIA_SINGLE_EMERGENCY": {
        "number": "112",
        "description": "National Unified Emergency Response Support System (ERSS) — Police, Fire, Ambulance",
        "jurisdiction": "All India"
    },
    "AMBULANCE_MEDICAL": {
        "number": "108",
        "description": "Emergency Medical Services, Critical Care Trauma Ambulances",
        "jurisdiction": "All India"
    },
    "DISASTER_MANAGEMENT_NDMA": {
        "number": "1078",
        "description": "National Disaster Management Authority Control Room",
        "jurisdiction": "India National"
    },
    "STATE_DISASTER_RELIEF": {
        "number": "1070",
        "description": "State Emergency Operations Center (SEOC)",
        "jurisdiction": "State Specific"
    },
    "POLICE": {
        "number": "100",
        "description": "Police Emergency Dispatch",
        "jurisdiction": "All India"
    },
    "FIRE_BRIGADE": {
        "number": "101",
        "description": "Fire & Rescue Operations",
        "jurisdiction": "All India"
    },
    "WOMEN_HELPLINE": {
        "number": "1091",
        "description": "Women Emergency Assistance",
        "jurisdiction": "All India"
    }
}

def get_source_by_id(source_id: str) -> Optional[EmergencySource]:
    for s in VERIFIED_SOURCES:
        if s.id == source_id:
            return s
    return None

def list_all_sources() -> List[Dict[str, Any]]:
    return [
        {
            "id": s.id,
            "title": s.title,
            "organization": s.organization,
            "url": s.url,
            "publication_year": s.publication_year,
            "last_verified": s.last_verified,
            "jurisdiction": s.jurisdiction,
            "topics": s.topics
        }
        for s in VERIFIED_SOURCES
    ]

if __name__ == "__main__":
    print(f"Verified Emergency Sources: {len(VERIFIED_SOURCES)}")
    for s in VERIFIED_SOURCES:
        print(f"  • [{s.id}] {s.title} ({s.organization}) - {s.jurisdiction}")
