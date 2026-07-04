create or replace function public.expire_stale_bookings()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  expired_count integer;
begin
  update public.bookings
  set
    status = 'expired',
    updated_at = now()
  where status = 'pending_payment'
    and expires_at is not null
    and expires_at <= now();

  get diagnostics expired_count = row_count;
  return expired_count;
end;
$$;

create or replace function public.get_available_slots(p_court_id bigint, p_date date)
returns jsonb
language plpgsql
as $$
declare
  court_record public.courts;
  hours_record public.court_operating_hours;
  slots jsonb;
begin
  perform public.expire_stale_bookings();

  select * into court_record from public.courts where id = p_court_id and status = 'active';
  if not found then
    raise exception 'Court is not available';
  end if;

  select * into hours_record
  from public.court_operating_hours
  where court_id = p_court_id
    and day_of_week = extract(dow from p_date)::integer;

  if not found then
    return jsonb_build_object(
      'court_id', court_record.id,
      'court_name', court_record.name,
      'date', p_date::text,
      'price_per_hour', court_record.price_per_hour,
      'slots', '[]'::jsonb
    );
  end if;

  select jsonb_agg(
    jsonb_build_object(
      'time', lpad(hour_value::text, 2, '0') || ':00',
      'available', not exists (
        select 1
        from public.bookings b
        where b.court_id = p_court_id
          and b.booking_date = p_date
          and b.status in ('pending_payment', 'paid')
          and int4range(b.start_hour, b.end_hour, '[)') && int4range(hour_value, hour_value + 1, '[)')
      ) and not exists (
        select 1
        from public.court_blocked_slots bs
        where bs.court_id = p_court_id
          and bs.blocked_date = p_date
          and int4range(bs.start_hour, bs.end_hour, '[)') && int4range(hour_value, hour_value + 1, '[)')
      )
    )
    order by hour_value
  ) into slots
  from generate_series(hours_record.open_hour, hours_record.close_hour - 1) as hour_value;

  return jsonb_build_object(
    'court_id', court_record.id,
    'court_name', court_record.name,
    'date', p_date::text,
    'price_per_hour', court_record.price_per_hour,
    'slots', coalesce(slots, '[]'::jsonb)
  );
end;
$$;

create or replace function public.create_booking(
  p_court_id bigint,
  p_date date,
  p_start_hour integer,
  p_end_hour integer
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  court_record public.courts;
  booking_record public.bookings;
  expires_at_value timestamptz := now() + interval '15 minutes';
begin
  perform public.expire_stale_bookings();

  if current_user_id is null then
    raise exception 'Not authenticated';
  end if;

  if p_start_hour >= p_end_hour then
    raise exception 'Invalid time range';
  end if;

  select * into court_record from public.courts where id = p_court_id and status = 'active';
  if not found then
    raise exception 'Court is not available';
  end if;

  insert into public.bookings (
    user_id,
    court_id,
    booking_date,
    start_hour,
    end_hour,
    price_per_hour,
    tax_amount,
    status,
    expires_at
  )
  values (
    current_user_id,
    p_court_id,
    p_date,
    p_start_hour,
    p_end_hour,
    court_record.price_per_hour,
    round(((p_end_hour - p_start_hour) * court_record.price_per_hour * 0.11)::numeric)::integer,
    'pending_payment',
    expires_at_value
  )
  returning * into booking_record;

  return jsonb_build_object(
    'booking', public.booking_to_json(booking_record),
    'expires_at', expires_at_value::text,
    'expires_in_seconds', 900
  );
exception
  when exclusion_violation then
    raise exception 'Selected time slot is no longer available';
end;
$$;
