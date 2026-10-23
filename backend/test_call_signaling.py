"""Security and state-flow tests for the authenticated WebRTC signaling gateway."""

from contextlib import ExitStack
from pathlib import Path
import sys

import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).parent.parent))

from backend.gateway.app import app, call_signaling_manager, create_access_token
from backend.gateway.storage import gateway_storage


@pytest.fixture(autouse=True)
def isolated_call_users():
    gateway_storage.clear()
    call_signaling_manager._connections.clear()
    call_signaling_manager._sessions.clear()
    call_signaling_manager._active_call_by_user.clear()
    call_signaling_manager._invite_attempts.clear()
    caller = gateway_storage.create_user({
        "id": "USR-CALLER",
        "email": "caller@example.invalid",
        "name": "Caller",
        "role": "Responder",
        "agency": "Test",
        "password": "not-used-by-websocket",
    })
    recipient = gateway_storage.create_user({
        "id": "USR-RECIPIENT",
        "email": "recipient@example.invalid",
        "name": "Recipient",
        "role": "Responder",
        "agency": "Test",
        "password": "not-used-by-websocket",
    })
    yield caller, recipient
    call_signaling_manager._connections.clear()
    call_signaling_manager._sessions.clear()
    call_signaling_manager._active_call_by_user.clear()


def _auth_headers(user):
    token = create_access_token({"sub": user["email"], "id": user["id"]})
    return {"authorization": f"Bearer {token}"}


def test_signaling_requires_an_authenticated_socket():
    with TestClient(app) as client:
        with pytest.raises(Exception):
            with client.websocket_connect("/api/v1/calls/signaling"):
                pass


def test_invite_accept_and_server_authorized_sdp_relay(isolated_call_users):
    caller, recipient = isolated_call_users
    with TestClient(app) as client, ExitStack() as stack:
        caller_ws = stack.enter_context(
            client.websocket_connect("/api/v1/calls/signaling", headers=_auth_headers(caller))
        )
        recipient_ws = stack.enter_context(
            client.websocket_connect("/api/v1/calls/signaling", headers=_auth_headers(recipient))
        )
        assert caller_ws.receive_json()["event"] == "call_ready"
        assert recipient_ws.receive_json()["event"] == "call_ready"

        caller_ws.send_json({"event": "call_invite", "recipient_id": recipient["id"]})
        created = caller_ws.receive_json()
        incoming = recipient_ws.receive_json()
        assert created["event"] == "call_created"
        assert incoming["event"] == "incoming_call"
        assert created["call_id"] == incoming["call_id"]
        assert incoming["caller"]["id"] == caller["id"]
        assert "email" not in incoming["caller"]

        call_id = created["call_id"]
        recipient_ws.send_json({"event": "call_accept", "call_id": call_id})
        assert caller_ws.receive_json() == {"event": "call_accepted", "call_id": call_id}

        # A recipient cannot impersonate the caller by submitting an SDP offer.
        recipient_ws.send_json({
            "event": "sdp_offer",
            "call_id": call_id,
            "description": {"type": "offer", "sdp": "not-authorized"},
        })
        assert recipient_ws.receive_json()["code"] == "invalid_signal"

        caller_ws.send_json({
            "event": "sdp_offer",
            "call_id": call_id,
            "description": {"type": "offer", "sdp": "valid-offer"},
            "from_user_id": recipient["id"],
        })
        relay = recipient_ws.receive_json()
        assert relay == {
            "event": "sdp_offer",
            "call_id": call_id,
            "from_user_id": caller["id"],
            "description": {"type": "offer", "sdp": "valid-offer"},
        }


def test_offline_or_unknown_recipient_is_not_reported_as_ringing(isolated_call_users):
    caller, recipient = isolated_call_users
    with TestClient(app) as client, client.websocket_connect(
        "/api/v1/calls/signaling", headers=_auth_headers(caller)
    ) as caller_ws:
        assert caller_ws.receive_json()["event"] == "call_ready"
        caller_ws.send_json({"event": "call_invite", "recipient_id": recipient["id"]})
        error = caller_ws.receive_json()
        assert error["event"] == "call_error"
        assert error["code"] == "recipient_unreachable"
