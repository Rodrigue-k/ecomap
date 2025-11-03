CREATE TABLE waste_bins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  type TEXT NOT NULL,
  image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  device_id TEXT NOT NULL
);