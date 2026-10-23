"""
Unit tests for RakshaNet Mesh Routing, TTL Decay, DTN Queueing,
Chunk Reassembly, Gateway Synchronization, and GPS-Free Multilateration.
"""
import pytest
import math
import hashlib
import time
from typing import List, Dict, Optional, Tuple

class SimulatedNode:
    def __init__(self, node_id: str, role: str, is_online: bool = True, is_gateway: bool = False):
        self.node_id = node_id
        self.role = role
        self.is_online = is_online
        self.is_gateway = is_gateway
        self.queue: List[Dict] = []
        self.seen_packet_ids = set()

class SimulatedLink:
    def __init__(self, u: str, v: str, link_type: str, latency_ms: int, reliability: float, is_active: bool = True):
        self.u = u
        self.v = v
        self.link_type = link_type
        self.latency_ms = latency_ms
        self.reliability = reliability
        self.is_active = is_active

class MeshRoutingEngine:
    def __init__(self, nodes: Dict[str, SimulatedNode], links: List[SimulatedLink]):
        self.nodes = nodes
        self.links = links

    def find_route(self, source: str, destination: str) -> Optional[List[str]]:
        # Dijkstra's shortest path based on latency and link activity
        from collections import deque
        import heapq
        
        queue = [(0, source, [source])]
        visited = {}

        while queue:
            cost, current, path = heapq.heappop(queue)
            if current in visited and visited[current] <= cost:
                continue
            visited[current] = cost

            if current == destination:
                return path

            for link in self.links:
                if not link.is_active:
                    continue
                neighbor = None
                if link.u == current and self.nodes[link.v].is_online:
                    neighbor = link.v
                elif link.v == current and self.nodes[link.u].is_online:
                    neighbor = link.u

                if neighbor and neighbor not in path:
                    heapq.heappush(queue, (cost + link.latency_ms, neighbor, path + [neighbor]))
        return None

    def forward_packet(self, packet: Dict, path: List[str]) -> Tuple[bool, str, Dict]:
        """
        Forwards a packet along the selected path, decrementing TTL and incrementing hop count.
        Returns (success, reason, updated_packet).
        """
        pkt = dict(packet)
        current = pkt['currentNodeId']
        
        # Check TTL
        if pkt['ttl'] <= 0:
            return False, "TTL_EXPIRED", pkt

        # Find next hop
        try:
            curr_idx = path.index(current)
            if curr_idx >= len(path) - 1:
                return True, "DESTINATION_REACHED", pkt
            next_hop = path[curr_idx + 1]
        except ValueError:
            return False, "NODE_NOT_ON_PATH", pkt

        # Check if next hop is online
        next_node = self.nodes.get(next_hop)
        if not next_node or not next_node.is_online:
            # Queue at current node
            curr_node = self.nodes[current]
            curr_node.queue.append(pkt)
            pkt['deliveryStatus'] = 'QUEUED'
            pkt['retryCount'] += 1
            return False, "NEXT_HOP_OFFLINE_QUEUED", pkt

        # Forward
        pkt['currentNodeId'] = next_hop
        pkt['hopCount'] += 1
        pkt['ttl'] -= 1
        pkt['deliveryStatus'] = 'RELAYED'
        next_node.seen_packet_ids.add(pkt['packetId'])
        
        if next_hop == pkt['destinationNodeId']:
            pkt['deliveryStatus'] = 'DELIVERED'
            return True, "DELIVERED", pkt

        return True, "FORWARDED", pkt

def solve_multilateration(anchors: List[Tuple[float, float, float]]):
    """
    Weighted multilateration for (x_i, y_i, d_i).
    Estimates position (x, y) and residual uncertainty.
    """
    if len(anchors) < 3:
        raise ValueError("At least 3 anchors required")
    
    # Linearize with respect to anchor 0
    x0, y0, d0 = anchors[0]
    A = []
    b = []
    for x_i, y_i, d_i in anchors[1:]:
        A.append([2 * (x_i - x0), 2 * (y_i - y0)])
        b.append((x_i**2 + y_i**2 - d_i**2) - (x0**2 + y0**2 - d0**2))
    
    import numpy as np
    A_mat = np.array(A, dtype=float)
    b_mat = np.array(b, dtype=float)
    
    # Solve pseudo-inverse: (A^T A)^-1 A^T b
    pos, residuals, rank, s = np.linalg.lstsq(A_mat, b_mat, rcond=None)
    est_x, est_y = pos[0], pos[1]
    
    # Calculate RMS residual uncertainty
    errors = [abs(math.hypot(x_i - est_x, y_i - est_y) - d_i) for x_i, y_i, d_i in anchors]
    rms_uncertainty = math.sqrt(sum(e**2 for e in errors) / len(errors))
    
    return est_x, est_y, rms_uncertainty


# ============================================================================
# TESTS
# ============================================================================

def test_routing_shortest_path_and_repeater_failure_healing():
    nodes = {
        'phoneA': SimulatedNode('phoneA', 'ORIGIN'),
        'phoneB': SimulatedNode('phoneB', 'RELAY'),
        'repeaterC': SimulatedNode('repeaterC', 'REPEATER'),
        'vehicleD': SimulatedNode('vehicleD', 'GATEWAY'),
        'commandE': SimulatedNode('commandE', 'HQ'),
    }
    links = [
        SimulatedLink('phoneA', 'phoneB', 'BLE', latency_ms=45, reliability=0.98),
        SimulatedLink('phoneB', 'repeaterC', 'LoRa', latency_ms=60, reliability=0.95),
        SimulatedLink('repeaterC', 'vehicleD', 'LoRa', latency_ms=55, reliability=0.95),
        SimulatedLink('phoneB', 'vehicleD', 'Wi-Fi Direct', latency_ms=180, reliability=0.85), # Bypass link
        SimulatedLink('vehicleD', 'commandE', '4G', latency_ms=30, reliability=0.99),
    ]

    engine = MeshRoutingEngine(nodes, links)

    # 1. Primary path through repeater
    route = engine.find_route('phoneA', 'commandE')
    assert route == ['phoneA', 'phoneB', 'repeaterC', 'vehicleD', 'commandE']

    # 2. Simulate repeater failure
    nodes['repeaterC'].is_online = False
    healed_route = engine.find_route('phoneA', 'commandE')
    # Should automatically heal by choosing the direct Phone B -> Vehicle D bypass
    assert healed_route == ['phoneA', 'phoneB', 'vehicleD', 'commandE']


def test_ttl_decay_and_storm_suppression():
    nodes = {
        'n1': SimulatedNode('n1', 'ORIGIN'),
        'n2': SimulatedNode('n2', 'RELAY'),
        'n3': SimulatedNode('n3', 'RELAY'),
    }
    links = [
        SimulatedLink('n1', 'n2', 'BLE', 50, 1.0),
        SimulatedLink('n2', 'n3', 'BLE', 50, 1.0),
    ]
    engine = MeshRoutingEngine(nodes, links)

    packet = {
        'packetId': 'PKT-TEST-001',
        'currentNodeId': 'n1',
        'destinationNodeId': 'n3',
        'hopCount': 0,
        'ttl': 1, # Set TTL to 1
        'deliveryStatus': 'CREATED',
        'retryCount': 0,
    }

    # Hop 1: n1 -> n2
    success, reason, pkt = engine.forward_packet(packet, ['n1', 'n2', 'n3'])
    assert success is True
    assert pkt['hopCount'] == 1
    assert pkt['ttl'] == 0
    assert pkt['currentNodeId'] == 'n2'

    # Hop 2: n2 -> n3 (TTL is now 0, must abort and suppress storm)
    success, reason, pkt = engine.forward_packet(pkt, ['n1', 'n2', 'n3'])
    assert success is False
    assert reason == 'TTL_EXPIRED'


def test_store_and_forward_queue_persistence_and_gateway_sync():
    nodes = {
        'survivor': SimulatedNode('survivor', 'ORIGIN'),
        'mule': SimulatedNode('mule', 'RELAY'),
        'gateway': SimulatedNode('gateway', 'GATEWAY', is_online=False), # Initially offline
        'cloud': SimulatedNode('cloud', 'SERVER'),
    }
    links = [
        SimulatedLink('survivor', 'mule', 'BLE', 40, 1.0),
        SimulatedLink('mule', 'gateway', 'BLE', 40, 1.0),
        SimulatedLink('gateway', 'cloud', 'INTERNET', 30, 1.0),
    ]
    engine = MeshRoutingEngine(nodes, links)

    pkt = {
        'packetId': 'SOS-DISASTER-77',
        'currentNodeId': 'survivor',
        'destinationNodeId': 'cloud',
        'hopCount': 0,
        'ttl': 5,
        'deliveryStatus': 'CREATED',
        'retryCount': 0,
    }

    path = ['survivor', 'mule', 'gateway', 'cloud']

    # Hop 1: survivor -> mule
    s1, r1, pkt = engine.forward_packet(pkt, path)
    assert s1 is True
    assert pkt['currentNodeId'] == 'mule'

    # Hop 2: mule -> gateway (Gateway is offline!)
    s2, r2, pkt = engine.forward_packet(pkt, path)
    assert s2 is False
    assert r2 == 'NEXT_HOP_OFFLINE_QUEUED'
    assert pkt['deliveryStatus'] == 'QUEUED'
    assert len(nodes['mule'].queue) == 1

    # Gateway comes back online (e.g. vehicle moves into cell fringe)
    nodes['gateway'].is_online = True
    queued_pkt = nodes['mule'].queue.pop(0)
    
    # Retry forwarding
    s3, r3, pkt = engine.forward_packet(queued_pkt, path)
    assert s3 is True
    assert pkt['currentNodeId'] == 'gateway'
    assert pkt['deliveryStatus'] == 'RELAYED'

    # Hop 3: gateway -> cloud
    s4, r4, pkt = engine.forward_packet(pkt, path)
    assert s4 is True
    assert pkt['currentNodeId'] == 'cloud'
    assert pkt['deliveryStatus'] == 'DELIVERED'


def test_16kb_photo_chunking_and_reassembly():
    # Generate 16KB mock payload
    raw_payload = b"IMG_DISASTER_SECTOR_4_" * 750 # ~16.5 KB
    expected_hash = hashlib.sha256(raw_payload).hexdigest()

    # Split into 4 chunks
    chunk_size = 4096
    chunks = []
    total_chunks = math.ceil(len(raw_payload) / chunk_size)

    for i in range(total_chunks):
        chunk_data = raw_payload[i * chunk_size : (i + 1) * chunk_size]
        chunks.append({
            'chunk_index': i,
            'total_chunks': total_chunks,
            'data': chunk_data,
            'checksum': hashlib.sha256(chunk_data).hexdigest(),
        })

    assert len(chunks) == 5

    # Simulate arrival out of order: [2, 0, 4, 1, 3]
    received_chunks = [chunks[2], chunks[0], chunks[4], chunks[1], chunks[3]]

    # Receiver verifies and reassembles
    reassembly_buffer = {}
    for c in received_chunks:
        # Verify individual chunk integrity
        assert hashlib.sha256(c['data']).hexdigest() == c['checksum']
        reassembly_buffer[c['chunk_index']] = c['data']

    assert len(reassembly_buffer) == total_chunks

    # Reconstruct in order
    reconstructed = b"".join(reassembly_buffer[i] for i in range(total_chunks))
    assert reconstructed == raw_payload
    assert hashlib.sha256(reconstructed).hexdigest() == expected_hash


def test_gps_free_location_estimation_multilateration():
    # True unanchored survivor position: (25.0, 35.0)
    true_x, true_y = 25.0, 35.0

    # 4 known-position anchors surrounding survivor
    anchors_known = [
        (0.0, 0.0),    # Anchor 1
        (50.0, 0.0),   # Anchor 2
        (50.0, 60.0),  # Anchor 3
        (0.0, 60.0),   # Anchor 4
    ]

    # Calculate simulated distances with ±1.5m synthetic RSSI noise
    import random
    random.seed(42)
    measurements = []
    for ax, ay in anchors_known:
        exact_dist = math.hypot(ax - true_x, ay - true_y)
        noise = random.uniform(-1.5, 1.5)
        measurements.append((ax, ay, exact_dist + noise))

    # Solve multilateration
    est_x, est_y, uncertainty = solve_multilateration(measurements)

    # Estimated position should be within 2.5 meters of true position
    pos_error = math.hypot(est_x - true_x, est_y - true_y)
    assert pos_error < 2.5
    assert uncertainty < 3.0
    print(f"True: ({true_x}, {true_y}) -> Estimated: ({est_x:.2f}, {est_y:.2f}) [Error: {pos_error:.2f}m, Uncertainty: ±{uncertainty:.2f}m]")
