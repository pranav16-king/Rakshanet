"""
Government Common Alerting Protocol (OASIS CAP v1.2) & CAD Exporter for RakshaNet.
Feature 25 & Architecture Tier 4 Interoperability.

Transforms decentralized mesh distress packets and Master Incidents into
standard OASIS CAP v1.2 XML feeds natively ingestible by India's NDMA (National Disaster
Management Authority), SACHET portal, SDMA state command centers, and legacy Computer-Aided
Dispatch (CAD) 112/911 console networks.
"""

import time
import xml.etree.ElementTree as ET
from xml.dom import minidom
from typing import List, Dict, Any, Optional
from datetime import datetime, timezone, timedelta

from .clustering import MasterIncident
from .black_hole import BlackHoleAnomaly


class CAPExporter:
    """
    OASIS Common Alerting Protocol (CAP v1.2) & CAD Dispatch Serializer.
    """
    CAP_NAMESPACE = "urn:oasis:names:tc:emergency:cap:1.2"
    SENDER_ID = "ops@rakshanet.in"
    IST_TZ = timezone(timedelta(hours=5, minutes=30))

    @classmethod
    def _format_iso8601(cls, timestamp_ms: int) -> str:
        dt = datetime.fromtimestamp(timestamp_ms / 1000.0, tz=cls.IST_TZ)
        return dt.isoformat()

    @classmethod
    def incident_to_cap_xml(cls, incident: MasterIncident, is_draft: bool = False) -> str:
        """
        Converts a MasterIncident into an OASIS CAP v1.2 XML document.
        """
        alert = ET.Element("alert", xmlns=cls.CAP_NAMESPACE)

        # Alert Header
        ET.SubElement(alert, "identifier").text = f"RAKSHANET-{incident.incident_id}"
        ET.SubElement(alert, "sender").text = cls.SENDER_ID
        ET.SubElement(alert, "sent").text = cls.format_iso(incident.last_reported_at)
        ET.SubElement(alert, "status").text = "Draft" if is_draft else "Actual"
        ET.SubElement(alert, "msgType").text = "Alert"
        ET.SubElement(alert, "scope").text = "Public"
        ET.SubElement(alert, "code").text = "NDMA-SACHET-CAP-1.2"

        # Information Segment
        info = ET.SubElement(alert, "info")
        ET.SubElement(info, "language").text = "en-IN"

        # Category mapping
        cat_tag = "Rescue"
        if "FIRE" in incident.category:
            cat_tag = "Fire"
        elif "MEDICAL" in incident.category:
            cat_tag = "Health"
        ET.SubElement(info, "category").text = cat_tag

        # Event Description
        hazard_title = incident.category.replace("_", " ").title()
        ET.SubElement(info, "event").text = f"Civilian Distress: {hazard_title}"

        # Urgency & Severity mapping
        urgency_val = "Immediate" if incident.urgency in ["CRITICAL", "HIGH"] else "Expected"
        severity_val = "Extreme" if incident.urgency == "CRITICAL" else ("Severe" if incident.urgency == "HIGH" else "Moderate")
        ET.SubElement(info, "urgency").text = urgency_val
        ET.SubElement(info, "severity").text = severity_val
        ET.SubElement(info, "certainty").text = "Observed"

        # Event Codes
        event_code = ET.SubElement(info, "eventCode")
        ET.SubElement(event_code, "valueName").text = "DisasterTaxonomy"
        ET.SubElement(event_code, "value").text = incident.category

        # Headline & Descriptions
        ET.SubElement(info, "headline").text = (
            f"Active Rescue Incident {incident.incident_id}: "
            f"~{incident.estimated_casualties} Casualties Reported in {hazard_title}"
        )

        desc_text = (
            f"Synthesized from {incident.total_devices} physical mesh handsets via RakshaNet DTN radio. "
            f"Estimated population impacted: {incident.estimated_casualties} people. "
            f"Identified high-vulnerability demographics: {', '.join(incident.vulnerabilities) if incident.vulnerabilities else 'NONE'}."
        )
        ET.SubElement(info, "description").text = desc_text

        instruction_text = (
            f"Deploy water rescue or high-clearance assets to designated centroid. "
            f"Incident bounding radius is {incident.radius_meters} meters. "
            f"Prioritize medical extraction for tagged vulnerable groups."
        )
        ET.SubElement(info, "instruction").text = instruction_text
        ET.SubElement(info, "contact").text = "State Emergency Operations Center (112 / SEOC)"

        # Custom Operational Parameters
        params = [
            ("EstimatedCasualties", str(incident.estimated_casualties)),
            ("ReportingMeshDevices", str(incident.total_devices)),
            ("UrgencyLevel", incident.urgency),
            ("AggregatedVulnerabilities", ", ".join(incident.vulnerabilities) if incident.vulnerabilities else "STANDARD"),
            ("MeshPacketCount", str(len(incident.raw_packet_ids)))
        ]
        for v_name, v_val in params:
            param = ET.SubElement(info, "parameter")
            ET.SubElement(param, "valueName").text = v_name
            ET.SubElement(param, "value").text = v_val

        # Geospatial Area
        area = ET.SubElement(info, "area")
        ET.SubElement(area, "areaDesc").text = f"Sector Centroid {incident.centroid_lat}, {incident.centroid_lng}"

        # CAP circle format: lat,lng,radius_km
        radius_km = round(incident.radius_meters / 1000.0, 3)
        ET.SubElement(area, "circle").text = f"{incident.centroid_lat},{incident.centroid_lng},{radius_km}"

        return cls._prettify_xml(alert)

    @classmethod
    def black_hole_to_cap_xml(cls, anomaly: BlackHoleAnomaly) -> str:
        """
        Converts a BlackHoleAnomaly into an OASIS CAP v1.2 Infrastructure Warning alert.
        """
        alert = ET.Element("alert", xmlns=cls.CAP_NAMESPACE)

        ET.SubElement(alert, "identifier").text = f"RAKSHANET-{anomaly.anomaly_id}"
        ET.SubElement(alert, "sender").text = cls.SENDER_ID
        ET.SubElement(alert, "sent").text = cls.format_iso(anomaly.detected_at)
        ET.SubElement(alert, "status").text = "Actual"
        ET.SubElement(alert, "msgType").text = "Alert"
        ET.SubElement(alert, "scope").text = "Public"
        ET.SubElement(alert, "code").text = "NDMA-COMM-BLACKOUT-1.2"

        info = ET.SubElement(alert, "info")
        ET.SubElement(info, "language").text = "en-IN"
        ET.SubElement(info, "category").text = "Infra"
        ET.SubElement(info, "event").text = "Severe Communication Network Collapse"
        ET.SubElement(info, "urgency").text = "Immediate" if anomaly.severity == "CRITICAL" else "Expected"
        ET.SubElement(info, "severity").text = "Extreme" if anomaly.severity == "CRITICAL" else "Severe"
        ET.SubElement(info, "certainty").text = "Observed"

        ET.SubElement(info, "headline").text = (
            f"Communication Black Hole Detected in {anomaly.sector_id}: "
            f"{anomaly.baseline_nodes} down to {anomaly.current_nodes} nodes ({anomaly.drop_percentage}% loss)"
        )

        desc = (
            f"Automated telemetry monitoring flagged a catastrophic telemetry decay curve in {anomaly.sector_id}. "
            f"Initial baseline: {anomaly.baseline_nodes} active devices, collapsed to {anomaly.current_nodes} devices. "
            f"Estimated population in silence: ~{anomaly.estimated_silenced_people} people. "
            f"No verified civil evacuation reported."
        )
        ET.SubElement(info, "description").text = desc
        ET.SubElement(info, "instruction").text = f"Recommended immediate tactical response: {anomaly.recommended_action}"

        # Area Bounding Polygon
        area = ET.SubElement(info, "area")
        ET.SubElement(area, "areaDesc").text = f"Grid Sector {anomaly.sector_id}"
        b = anomaly.bounds
        # Polygon: min_lat,min_lng max_lat,min_lng max_lat,max_lng min_lat,max_lng min_lat,min_lng
        poly_str = f"{b['min_lat']},{b['min_lng']} {b['max_lat']},{b['min_lng']} {b['max_lat']},{b['max_lng']} {b['min_lat']},{b['max_lng']} {b['min_lat']},{b['min_lng']}"
        ET.SubElement(area, "polygon").text = poly_str

        return cls._prettify_xml(alert)

    @classmethod
    def incident_to_cad_json(cls, incident: MasterIncident) -> Dict[str, Any]:
        """
        Formats a MasterIncident for Computer-Aided Dispatch (CAD / APCO / NENA) console systems.
        """
        priority_map = {"CRITICAL": 1, "HIGH": 2, "MEDIUM": 3, "LOW": 4}

        return {
            "cad_incident_id": f"CAD-RAKSHA-{incident.incident_id.replace('INC-CLUST-', '').replace('INC-NODE-', '')}",
            "source_system": "RakshaNet Offline Disaster Mesh",
            "agency_routing": "NDRF / SDMA Disaster Management",
            "call_type": incident.category,
            "priority": priority_map.get(incident.urgency, 3),
            "status": incident.status,
            "location": {
                "latitude": incident.centroid_lat,
                "longitude": incident.centroid_lng,
                "uncertainty_radius_meters": incident.radius_meters,
                "landmark_description": f"Near coordinates {incident.centroid_lat} N, {incident.centroid_lng} E"
            },
            "casualty_assessment": {
                "estimated_people_impacted": incident.estimated_casualties,
                "handsets_reporting": incident.total_devices,
                "special_needs": incident.vulnerabilities,
                "devices_not_equal_people": True
            },
            "dispatch_guidance": {
                "urgency": incident.urgency,
                "recommended_fleet": ["BOAT"] if "FLOOD" in incident.category else (
                    ["HIGH_CLEARANCE_4WD"] if "COLLAPSE" in incident.category else ["AMBULANCE"]
                )
            },
            "audit_trail": {
                "first_seen_ts": incident.first_reported_at,
                "last_seen_ts": incident.last_reported_at,
                "contributing_pings": incident.raw_packet_ids
            }
        }

    @classmethod
    def format_iso(cls, ts_ms: int) -> str:
        return cls._format_iso8601(ts_ms)

    @classmethod
    def _prettify_xml(cls, elem: ET.Element) -> str:
        rough_string = ET.tostring(elem, encoding="utf-8")
        parsed = minidom.parseString(rough_string)
        return parsed.toprettyxml(indent="  ", encoding="utf-8").decode("utf-8")


# Global Singleton CAP Exporter Instance
cap_exporter = CAPExporter()
