CREATE TABLE IF NOT EXISTS clusters (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    created_at TEXT
);

CREATE TABLE IF NOT EXISTS cluster_images (
    cluster_id INTEGER,
    image_id TEXT
);

CREATE TABLE IF NOT EXISTS image_metadata (
    id TEXT PRIMARY KEY,
    latitude REAL,
    longitude REAL,
    created_at TEXT
);

CREATE TABLE IF NOT EXISTS image_vectors (
    image_id TEXT PRIMARY KEY,
    vectors TEXT,
    created_at TEXT
)