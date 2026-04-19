CREATE SCHEMA IF NOT EXISTS tournament;
SET search_path TO tournament;

CREATE TABLE IF NOT EXISTS tournament.person (
    person_id SERIAL PRIMARY KEY,
    first_name VARCHAR(20) NOT NULL,
    last_name VARCHAR(20) NOT NULL,
    phone_number VARCHAR(25) UNIQUE NOT NULL 
);

CREATE TABLE IF NOT EXISTS tournament.player (

    player_id INT PRIMARY KEY REFERENCES tournament.person(person_id),
    gamer_tag VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('M','F','Other')), 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tournament.staff (
    staff_id INT PRIMARY KEY REFERENCES tournament.person(person_id),
    position VARCHAR(30) NOT NULL,
    salary NUMERIC(10,2) NOT NULL CHECK (salary >= 0) 
);

CREATE TABLE IF NOT EXISTS tournament.venue (
    venue_id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    city VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS tournament.game (
    game_id SERIAL PRIMARY KEY,
    title VARCHAR(50) UNIQUE NOT NULL,
    entry_fee NUMERIC(10,2) NOT NULL CHECK (entry_fee >= 0)
);

CREATE TABLE IF NOT EXISTS tournament.event (
    event_id SERIAL PRIMARY KEY,
    event_name VARCHAR(50) NOT NULL,
    season VARCHAR(30) NOT NULL,
    start_date DATE NOT NULL CHECK (start_date > DATE '2026-01-01'), 
    event_code VARCHAR(20) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'upcoming', 
    venue_id INT REFERENCES tournament.venue(venue_id)
);

CREATE TABLE IF NOT EXISTS tournament.event_game (
    event_id INT REFERENCES tournament.event(event_id),
    game_id INT REFERENCES tournament.game(game_id),
    PRIMARY KEY (event_id, game_id)
);

CREATE TABLE IF NOT EXISTS tournament.match_session (
    session_id SERIAL PRIMARY KEY,
    player_id INT REFERENCES tournament.player(player_id),
    event_id INT REFERENCES tournament.event(event_id),
    staff_id INT REFERENCES tournament.staff(staff_id),
    start_date DATE NOT NULL CHECK (start_date > DATE '2026-01-01'),
    end_date DATE NOT NULL CHECK (end_date > start_date),
    session_days INT GENERATED ALWAYS AS (end_date - start_date) STORED 
);

CREATE TABLE IF NOT EXISTS tournament.prize_payment (
    payment_id SERIAL PRIMARY KEY,
    session_id INT REFERENCES tournament.match_session(session_id),
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    payment_date DATE DEFAULT CURRENT_DATE,
    method VARCHAR(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS tournament.incident_report (
    incident_id SERIAL PRIMARY KEY,
    event_id INT REFERENCES tournament.event(event_id),
    incident_date DATE NOT NULL,
    description TEXT NOT NULL,
    penalty_fee NUMERIC(10,2) NOT NULL CHECK (penalty_fee >= 0)
);

ALTER TABLE tournament.staff ALTER COLUMN position TYPE VARCHAR(40);

ALTER TABLE tournament.prize_payment ALTER COLUMN method SET DEFAULT 'transfer';

ALTER TABLE tournament.prize_payment ALTER COLUMN method DROP DEFAULT;

ALTER TABLE tournament.venue ADD CONSTRAINT chk_venue_city CHECK (length(city) > 2);

ALTER TABLE tournament.event RENAME COLUMN status TO event_status;


TRUNCATE TABLE
    tournament.incident_report,
    tournament.prize_payment,
    tournament.match_session,
    tournament.event_game,
    tournament.event,
    tournament.game,
    tournament.staff,
    tournament.player,
    tournament.venue,
    tournament.person
RESTART IDENTITY CASCADE;

INSERT INTO tournament.person(first_name, last_name, phone_number) VALUES
('Faker', 'Lee', '87757523722'),
('S1mple', 'Kostyliev', '87788620608'),
('TenZ', 'Ngo', '8777887167'),
('Laura', 'Wilson', '370600004'),
('David', 'Moore', '370600005'),
('Emma', 'Clark', '370600006');

INSERT INTO tournament.player (player_id, gamer_tag, email, gender) VALUES
((SELECT person_id FROM tournament.person WHERE phone_number = '87757523722'), 'HideOnBush', 'faker@t1.gg', 'M'),
((SELECT person_id FROM tournament.person WHERE phone_number = '87788620608'), 'S1mple', 's1mple@navi.gg', 'M'),
((SELECT person_id FROM tournament.person WHERE phone_number = '8777887167'), 'TenZ', 'tenz@sentinels.gg', 'M');

INSERT INTO tournament.staff (staff_id, position, salary) VALUES
((SELECT person_id FROM tournament.person WHERE phone_number = '370600004'), 'Head Admin', 2500),
((SELECT person_id FROM tournament.person WHERE phone_number = '370600005'), 'Shoutcaster', 1800),
((SELECT person_id FROM tournament.person WHERE phone_number = '370600006'), 'Stage Referee', 1700);

INSERT INTO tournament.venue (name, city) VALUES
('Esports Arena Central', 'Los Angeles'),
('Spodek Arena', 'Katowice'),
('O2 Arena', 'London');

INSERT INTO tournament.game (title, entry_fee) VALUES
('League of Legends', 500),
('Counter-Strike 2', 400),
('Valorant', 450);

INSERT INTO tournament.event (event_name, season, start_date, event_code, event_status, venue_id) VALUES
('Worlds', 'Season 16', '2026-10-01', 'W2026', 'upcoming', (SELECT venue_id FROM tournament.venue WHERE name = 'O2 Arena')),
('IEM Katowice', 'Spring', '2026-02-15', 'IEM26', 'active', (SELECT venue_id FROM tournament.venue WHERE name = 'Spodek Arena')),
('Champions', 'Summer', '2026-08-01', 'VCT26', 'upcoming', (SELECT venue_id FROM tournament.venue WHERE name = 'Esports Arena Central'));

INSERT INTO tournament.event_game (event_id, game_id) VALUES
((SELECT event_id FROM tournament.event WHERE event_code = 'W2026'), (SELECT game_id FROM tournament.game WHERE title = 'League of Legends')),
((SELECT event_id FROM tournament.event WHERE event_code = 'IEM26'), (SELECT game_id FROM tournament.game WHERE title = 'Counter-Strike 2')),
((SELECT event_id FROM tournament.event WHERE event_code = 'VCT26'), (SELECT game_id FROM tournament.game WHERE title = 'Valorant'));

INSERT INTO tournament.match_session (player_id, event_id, staff_id, start_date, end_date) VALUES
(
    (SELECT player_id FROM tournament.player WHERE gamer_tag = 'HideOnBush'),
    (SELECT event_id FROM tournament.event WHERE event_code = 'W2026'),
    (SELECT staff_id FROM tournament.staff WHERE position = 'Head Admin'),
    '2026-10-02', '2026-10-05'
),
(
    (SELECT player_id FROM tournament.player WHERE gamer_tag = 'S1mple'),
    (SELECT event_id FROM tournament.event WHERE event_code = 'IEM26'),
    (SELECT staff_id FROM tournament.staff WHERE position = 'Shoutcaster'),
    '2026-02-16', '2026-02-20'
),
(
    (SELECT player_id FROM tournament.player WHERE gamer_tag = 'TenZ'),
    (SELECT event_id FROM tournament.event WHERE event_code = 'VCT26'),
    (SELECT staff_id FROM tournament.staff WHERE position = 'Stage Referee'),
    '2026-08-02', '2026-08-04'
);

INSERT INTO tournament.prize_payment (session_id, amount, payment_date, method) VALUES
((SELECT session_id FROM tournament.match_session LIMIT 1 OFFSET 0), 15000, '2026-10-06', 'crypto'),
((SELECT session_id FROM tournament.match_session LIMIT 1 OFFSET 1), 12000, '2026-02-21', 'wire transfer'),
((SELECT session_id FROM tournament.match_session LIMIT 1 OFFSET 2), 10000, '2026-08-05', 'check');

INSERT INTO tournament.incident_report (event_id, incident_date, description, penalty_fee) VALUES
((SELECT event_id FROM tournament.event WHERE event_code = 'W2026'), '2026-10-03', 'Hardware malfunction delay', 0),
((SELECT event_id FROM tournament.event WHERE event_code = 'IEM26'), '2026-02-18', 'Player behavioral warning', 500),
((SELECT event_id FROM tournament.event WHERE event_code = 'VCT26'), '2026-08-03', 'Late stage arrival', 250);