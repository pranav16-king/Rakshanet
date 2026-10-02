/**
 * RakshaNet SQLite Database Schemas
 * Source of truth for all on-device offline persistence.
 */

export const CREATE_TABLES_SQL = `
-- 1. Civilian User Profile
CREATE TABLE IF NOT EXISTS user_profile (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    preferred_language TEXT DEFAULT 'en',
    age INTEGER,
    blood_group TEXT,
    emergency_contact TEXT,
    medical_notes TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- 2. Local Device Identity (Hardware-anonymized)
CREATE TABLE IF NOT EXISTS device_identity (
    id TEXT PRIMARY KEY,
    device_id TEXT UNIQUE NOT NULL,
    public_key TEXT NOT NULL,
    private_key_ref TEXT NOT NULL,
    created_at INTEGER NOT NULL
);

-- 3. Discovered Nearby Devices (Radio peers)
CREATE TABLE IF NOT EXISTS nearby_devices (
    id TEXT PRIMARY KEY,
    device_id TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    connection_type TEXT NOT NULL,
    signal_strength INTEGER NOT NULL,
    proximity_band TEXT NOT NULL,
    last_seen INTEGER NOT NULL,
    first_seen INTEGER NOT NULL,
    is_connected INTEGER DEFAULT 0,
    hop_count INTEGER DEFAULT 1,
    battery_level INTEGER
);

-- 4. Conversations
CREATE TABLE IF NOT EXISTS conversations (
    id TEXT PRIMARY KEY,
    conversation_id TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

-- 5. Conversation Participants
CREATE TABLE IF NOT EXISTS conversation_participants (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    device_id TEXT NOT NULL,
    display_name TEXT NOT NULL,
    joined_at INTEGER NOT NULL,
    last_seen INTEGER NOT NULL,
    FOREIGN KEY(conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);

-- 6. Offline Messages (Save-before-send source of truth)
CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    message_id TEXT UNIQUE NOT NULL,
    conversation_id TEXT NOT NULL,
    sender_device_id TEXT NOT NULL,
    sender_name TEXT NOT NULL,
    message_type TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    expires_at INTEGER NOT NULL,
    status TEXT NOT NULL,
    hop_count INTEGER DEFAULT 0,
    ttl INTEGER DEFAULT 5,
    FOREIGN KEY(conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);

-- 7. Message Relay Audit Trail (DTN Hop tracer)
CREATE TABLE IF NOT EXISTS message_relays (
    id TEXT PRIMARY KEY,
    message_id TEXT NOT NULL,
    from_device_id TEXT NOT NULL,
    to_device_id TEXT NOT NULL,
    hop_number INTEGER NOT NULL,
    received_at INTEGER NOT NULL,
    forwarded_at INTEGER,
    status TEXT NOT NULL,
    FOREIGN KEY(message_id) REFERENCES messages(id) ON DELETE CASCADE
);

-- Indexes for lightning-fast queries during mesh storms
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_status ON messages(status);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at);
CREATE INDEX IF NOT EXISTS idx_nearby_last_seen ON nearby_devices(last_seen);
`;
