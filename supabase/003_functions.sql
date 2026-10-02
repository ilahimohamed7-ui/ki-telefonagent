-- ==========================================
-- KI-Telefonagent
-- Datenbankfunktionen
-- ==========================================


-- ==========================================
-- 1. Freie Termine prüfen
-- ==========================================

create or replace function public.check_availability(
    requested_date date,
    requested_service_id bigint
)
returns table (
    employee_id bigint,
    employee_name text,
    available_time time
)
language sql
as $$
    with service_info as (
        select duration_minutes
        from public.services
        where id = requested_service_id
    ),
    time_slots as (
        select
            generate_series(
                requested_date::timestamp + time '09:00',
                requested_date::timestamp + time '17:00',
                interval '30 minutes'
            ) as slot
    )
    select
        e.id as employee_id,
        e.name as employee_name,
        t.slot::time as available_time
    from public.employees e
    cross join time_slots t
    cross join service_info s
    where not exists (
        select 1
        from public.appointments a
        join public.services booked_service
            on booked_service.id = a.service_id
        where
            a.employee_id = e.id
            and a.appointment_date = requested_date
            and t.slot < (
                requested_date::timestamp
                + a.start_time
                + booked_service.duration_minutes * interval '1 minute'
            )
            and (
                t.slot
                + s.duration_minutes * interval '1 minute'
            ) > (
                requested_date::timestamp + a.start_time
            )
    )
    and (
        t.slot
        + s.duration_minutes * interval '1 minute'
    ) <= requested_date::timestamp + time '18:00'
    order by t.slot, e.name;
$$;


-- ==========================================
-- 2. Termin erstellen
-- ==========================================

create or replace function public.create_appointment(
    p_employee_id bigint,
    p_service_id bigint,
    p_customer_name text,
    p_customer_phone text,
    p_appointment_date date,
    p_start_time time
)
returns bigint
language plpgsql
as $$
declare
    new_appointment_id bigint;
    requested_duration integer;
begin

    -- Dauer der gewünschten Leistung holen
    select duration_minutes
    into requested_duration
    from public.services
    where id = p_service_id;

    -- Prüfen, ob die Leistung existiert
    if requested_duration is null then
        raise exception 'Die gewünschte Leistung wurde nicht gefunden.';
    end if;

    -- Prüfen, ob der Mitarbeiter existiert
    if not exists (
        select 1
        from public.employees
        where id = p_employee_id
    ) then
        raise exception 'Der Mitarbeiter wurde nicht gefunden.';
    end if;

    -- Prüfen, ob sich der neue Termin überschneidet
    if exists (
        select 1
        from public.appointments a
        join public.services booked_service
            on booked_service.id = a.service_id
        where
            a.employee_id = p_employee_id
            and a.appointment_date = p_appointment_date
            and (
                p_appointment_date::timestamp + p_start_time
            ) < (
                p_appointment_date::timestamp
                + a.start_time
                + booked_service.duration_minutes * interval '1 minute'
            )
            and (
                p_appointment_date::timestamp
                + p_start_time
                + requested_duration * interval '1 minute'
            ) > (
                p_appointment_date::timestamp + a.start_time
            )
    ) then
        raise exception 'Dieser Zeitraum ist bereits belegt.';
    end if;

    -- Termin erstellen
    insert into public.appointments (
        employee_id,
        service_id,
        customer_name,
        customer_phone,
        appointment_date,
        start_time
    )
    values (
        p_employee_id,
        p_service_id,
        p_customer_name,
        p_customer_phone,
        p_appointment_date,
        p_start_time
    )
    returning id into new_appointment_id;

    return new_appointment_id;

end;
$$;