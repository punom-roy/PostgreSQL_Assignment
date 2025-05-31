-- Active: 1748433551065@@127.0.0.1@5432@conservation_db

DROP TABLE IF EXISTS sightings, species, rangers CASCADE;

-- rangers table
CREATE TABLE rangers (
    ranger_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL
);

-- species table
CREATE TABLE species (
    species_id SERIAL PRIMARY KEY,
    common_name VARCHAR(100) NOT NULL,
    scientific_name VARCHAR(100) NOT NULL,
    discovery_date DATE NOT NULL,
    conservation_status VARCHAR(50) CHECK (
        conservation_status IN ('Endangered', 'Vulnerable', 'Least Concern', 'Extinct')
    ) DEFAULT 'Least Concern'
);

-- sightings table
CREATE TABLE sightings (
    sighting_id SERIAL PRIMARY KEY,
    species_id INT REFERENCES species(species_id) ON DELETE CASCADE,
    ranger_id INT REFERENCES rangers(ranger_id) ON DELETE CASCADE,
    sighting_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    location VARCHAR(100) NOT NULL,
    notes TEXT
);

-- Insert rangers DATA
INSERT INTO rangers (ranger_id, name, region) VALUES
(1, 'Alice Green', 'Northern Hills'),
(2, 'Bob White', 'River Delta'),
(3, 'Carol King', 'Mountain Range');

-- Insert species DATA
INSERT INTO species (species_id, common_name, scientific_name, discovery_date, conservation_status) VALUES
(1, 'Snow Leopard', 'Panthera uncia', '1775-01-01', 'Endangered'),
(2, 'Bengal Tiger', 'Panthera tigris tigris', '1758-01-01', 'Endangered'),
(3, 'Red Panda', 'Ailurus fulgens', '1825-01-01', 'Vulnerable'),
(4, 'Asiatic Elephant', 'Elephas maximus indicus', '1758-01-01', 'Endangered');

-- Insert sightings DATA
INSERT INTO sightings (sighting_id, species_id, ranger_id, location, sighting_time, notes) VALUES
(1, 1, 1, 'Peak Ridge', '2024-05-10 07:45:00', 'Camera trap image captured'),
(2, 2, 2, 'Bankwood Area', '2024-05-12 16:20:00', 'Juvenile seen'),
(3, 3, 3, 'Bamboo Grove East', '2024-05-15 09:10:00', 'Feeding observed'),
(4, 1, 2, 'Snowfall Pass', '2024-05-18 18:30:00', NULL);

-- Relationships Between Tables
SELECT r.name AS ranger, sp.common_name AS species, s.location, s.sighting_time
FROM sightings s
JOIN rangers r ON s.ranger_id = r.ranger_id
JOIN species sp ON s.species_id = sp.species_id;

---------------PostgreSQL Problems----------------
---1️⃣ Register a new ranger with provided data with name = 'Derek Fox' and region = 'Coastal Plains'
INSERT INTO rangers (ranger_id, name, region)
VALUES (4, 'Derek Fox', 'Coastal Plains');

---2️⃣ Count unique species ever sighted.
SELECT COUNT(DISTINCT species_id) AS unique_species_count
FROM sightings;

---3️⃣ Find all sightings where the location includes "Pass".
SELECT *
FROM sightings
WHERE location ILIKE '%Pass%';

---4️⃣ List each ranger's name and their total number of sightings.
SELECT r.name, COUNT(s.sighting_id) AS total_sightings
FROM rangers r
LEFT JOIN sightings s ON r.ranger_id = s.ranger_id
GROUP BY r.name
ORDER BY r.name;

---5️⃣ List species that have never been sighted.
SELECT sp.common_name
FROM species sp
LEFT JOIN sightings s ON sp.species_id = s.species_id
WHERE s.sighting_id IS NULL;

---6️⃣ Show the most recent 2 sightings.
SELECT sp.common_name, s.sighting_time, r.name
FROM sightings s
JOIN species sp ON s.species_id = sp.species_id
JOIN rangers r ON s.ranger_id = r.ranger_id
ORDER BY s.sighting_time DESC
LIMIT 2;

---7️⃣ Update all species discovered before year 1800 to have status 'Historic'.
SELECT conname
FROM pg_constraint
WHERE conrelid = 'species'::regclass
AND contype = 'c';

ALTER TABLE species
DROP CONSTRAINT species_conservation_status_check;

ALTER TABLE species
ADD CONSTRAINT species_conservation_status_check
CHECK (conservation_status IN ('Endangered', 'Vulnerable', 'Historic'));

UPDATE species
SET conservation_status = 'Historic'
WHERE discovery_date < '1800-01-01';

/*
8️⃣ Label each sighting's time of day as 'Morning', 'Afternoon', or 'Evening'.
Morning: before 12 PM
Afternoon: 12 PM–5 PM
Evening: after 5 PM
*/
SELECT
sighting_id,
CASE
    WHEN EXTRACT(HOUR FROM sighting_time) < 12 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM sighting_time) BETWEEN 12 AND 17 THEN 'Afternoon'
    ELSE 'Evening'
END AS time_of_day
FROM sightings
ORDER BY sighting_id;

---9️⃣ Delete rangers who have never sighted any species
DELETE FROM rangers
WHERE ranger_id NOT IN (
SELECT DISTINCT ranger_id FROM sightings
);