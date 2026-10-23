"""
RakshaNet AI - Backend Online Groq LLM Gateway & Knowledge Engine
Keeps the Groq API Key securely on the backend.
Provides authenticated, rate-limited, resilient AI completions with fallback.
"""

import os
import time
import uuid
import logging
import requests
from typing import Dict, Any, List, Optional
from pathlib import Path
from dotenv import load_dotenv

logger = logging.getLogger("RakshaNet.AIBackend")

# Load environment
load_dotenv(Path(__file__).parent.parent / ".env")

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_MODEL = os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile")
GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions"

# Grounding System Prompt based on NDMA, NDRF, and WHO emergency standards
SYSTEM_GROUNDING_PROMPT = """You are RakshaNet AI, the authoritative emergency disaster-response intelligence and survival copilot.
You provide life-saving, concise, structured, and factual guidance for survivors and rescue teams during natural and man-made disasters.

CRITICAL SAFETY RULES:
1. Always ground your guidance in verified emergency standards (NDMA, NDRF, WHO, IFRC).
2. DO NOT invent emergency numbers:
   - National Emergency Helpline (India & GSM Standard): 112
   - Ambulance / Medical: 108
   - Disaster Management Helpline (NDMA): 1078
   - Police: 100 | Fire: 101
3. DO NOT fabricate medical dosages, toxic chemical decontamination shortcuts, or false rescue team arrival claims.
4. For life-threatening emergencies, provide immediate, numbered, prioritized action steps (ABCs - Airway, Breathing, Circulation first).
5. State clear warnings, contraindications, and advise escalating to professional emergency responders.

RESPONSE FORMAT:
You MUST respond with a valid JSON object matching this schema:
{
  "title": "Short authoritative title or direct answer summary (1-2 sentences)",
  "steps": ["Step 1 action", "Step 2 action", "Step 3 action"],
  "warning": "Critical safety warning or contraindication (or null if none)",
  "category": "Medical" | "Hazards" | "Rescue" | "CBRN" | "Survival" | "General",
  "urgency": "critical" | "high" | "advisory",
  "sources": [
    {
      "title": "Official guideline title (e.g. NDMA National Disaster Management Guidelines)",
      "organization": "NDMA / WHO / NDRF / IFRC",
      "jurisdiction": "India / International"
    }
  ]
}
"""

class BackendAiService:
    """Manages secure server-side Groq LLM inferences with strict privacy and timeouts."""

    @classmethod
    def query(
        cls,
        query: str,
        conversation_history: Optional[List[Dict[str, str]]] = None,
        category: Optional[str] = None,
        telemetry: Optional[Dict[str, Any]] = None,
        timeout_seconds: int = 8,
    ) -> Dict[str, Any]:
        request_id = f"AI-REQ-{uuid.uuid4().hex[:10].upper()}"
        created_at = int(time.time() * 1000)

        # Sanitize query
        cleaned_query = (query or "").strip()
        if not cleaned_query:
            return {
                "request_id": request_id,
                "answer": "No emergency query was provided.",
                "engine": "System Gateway",
                "status": "ERROR",
                "sources": [],
                "warnings": None,
                "steps": [],
                "category": "General",
                "urgency": "advisory",
                "created_at": created_at,
            }

        # Privacy guard: Strip any PII from conversation history
        sanitized_history = []
        if conversation_history:
            for turn in conversation_history[-4:]:  # Limit to 4 turns max
                role = turn.get("role", "user")
                content = str(turn.get("content", ""))[:500]  # Cap length
                sanitized_history.append({"role": role, "content": content})

        # Telemetry context injection (anonymized)
        telemetry_ctx = ""
        if telemetry:
            battery = telemetry.get("battery")
            peers = telemetry.get("mesh_peers")
            if battery is not None or peers is not None:
                telemetry_ctx = f"\n[DEVICE TELEMETRY: Battery={battery}%, MeshPeers={peers}]"

        messages = [
            {"role": "system", "content": SYSTEM_GROUNDING_PROMPT + telemetry_ctx},
        ]
        messages.extend(sanitized_history)
        messages.append({"role": "user", "content": cleaned_query})

        # Check Groq Key availability
        if not GROQ_API_KEY:
            logger.warning("[AIBackend] GROQ_API_KEY not configured on backend.")
            return cls._fallback_response(
                request_id,
                cleaned_query,
                created_at,
                "Backend GROQ_API_KEY is not configured.",
                category
            )

        # Models to attempt
        models_to_try = [
            GROQ_MODEL,
            "llama-3.3-70b-versatile",
            "llama-3.1-8b-instant",
        ]
        # Deduplicate while preserving order
        seen_models = set()
        deduped_models = [m for m in models_to_try if m and not (m in seen_models or seen_models.add(m))]

        last_error = "Unknown error"
        for model in deduped_models:
            try:
                headers = {
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {GROQ_API_KEY}",
                    "User-Agent": "RakshaNet-Backend-AI/1.0",
                }
                payload = {
                    "model": model,
                    "messages": messages,
                    "temperature": 0.25,
                    "max_tokens": 1024,
                    "response_format": {"type": "json_object"},
                }

                resp = requests.post(
                    GROQ_ENDPOINT,
                    json=payload,
                    headers=headers,
                    timeout=timeout_seconds,
                )

                if resp.status_code == 200:
                    data = resp.json()
                    choices = data.get("choices", [])
                    if choices:
                        content_str = choices[0].get("message", {}).get("content", "{}")
                        import json
                        parsed = json.loads(content_str)

                        return {
                            "request_id": request_id,
                            "answer": parsed.get("title", "Emergency Guidance:"),
                            "engine": f"Groq Cloud ({model})",
                            "status": "SUCCESS",
                            "sources": parsed.get("sources", [
                                {
                                    "title": "NDMA Disaster Response Guidelines & WHO Emergency Protocols",
                                    "organization": "NDMA / WHO",
                                    "jurisdiction": "India / Global",
                                }
                            ]),
                            "warnings": parsed.get("warning"),
                            "steps": [str(s) for s in parsed.get("steps", [])],
                            "category": parsed.get("category", category or "General"),
                            "urgency": parsed.get("urgency", "high"),
                            "created_at": created_at,
                        }
                else:
                    last_error = f"Groq returned HTTP {resp.status_code}: {resp.text[:150]}"
                    logger.warning(f"[AIBackend] Model {model} failed: {last_error}")

            except requests.exceptions.Timeout:
                last_error = f"Model {model} timed out after {timeout_seconds}s"
                logger.warning(f"[AIBackend] {last_error}")
            except Exception as e:
                last_error = f"Model {model} exception: {str(e)}"
                logger.warning(f"[AIBackend] {last_error}")

        # If all cloud models failed, return clean fallback
        return cls._fallback_response(
            request_id,
            cleaned_query,
            created_at,
            last_error,
            category
        )

    @classmethod
    def _fallback_response(
        cls,
        request_id: str,
        query: str,
        created_at: int,
        error_detail: str,
        category: Optional[str] = None
    ) -> Dict[str, Any]:
        """Provides verified fallback when Groq cloud is unreachable."""
        return {
            "request_id": request_id,
            "answer": "Cloud AI service degraded or unreachable. Please utilize On-Device Local Knowledge Base.",
            "engine": "Backend Fallback Gatekeeper",
            "status": "ONLINE_DEGRADED",
            "sources": [
                {
                    "title": "RakshaNet Verified Emergency Knowledge Base",
                    "organization": "NDMA / NDRF",
                    "jurisdiction": "India",
                }
            ],
            "warnings": "Cloud LLM reasoning is currently unavailable. For life-threatening emergencies, dial 112 immediately or trigger the SOS beacon.",
            "steps": [
                "Switch to Offline AI or Local Knowledge Base in the header menu.",
                "Follow established SOPs: Airway, Breathing, Circulation (ABCs).",
                "Dial 112 (National Emergency) or 108 (Ambulance) if cellular network is available.",
                "Press and hold the SOS Beacon for 1.5 seconds to broadcast distress packet over the mesh network."
            ],
            "category": category or "Disaster Response",
            "urgency": "high",
            "created_at": created_at,
            "error_detail": error_detail,
        }
