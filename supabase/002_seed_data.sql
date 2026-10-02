-- ==========================================
-- KI-Telefonagent
-- Testdaten
-- ==========================================

-- Mitarbeiter
insert into public.employees (name)
values
    ('Anna'),
    ('Lisa'),
    ('Sarah');

-- Leistungen
insert into public.services (
    name,
    duration_minutes,
    price
)
values
    ('Haarschnitt', 45, 35.00),
    ('Waschen und Schneiden', 60, 45.00),
    ('Färben', 120, 90.00);

-- Beispieltermine
insert into public.appointments (
    employee_id,
    service_id,
    customer_name,
    customer_phone,
    appointment_date,
    start_time
)
values
    (1, 1, 'Max Müller', '01761234567', '2026-10-05', '10:00'),
    (1, 1, 'Anna Weber', '01769876543', '2026-10-05', '11:00'),
    (2, 1, 'Lisa Schmidt', '01761234568', '2026-10-05', '14:00'),
    (3, 2, 'Tom Becker', '01761234569', '2026-10-05', '13:00');