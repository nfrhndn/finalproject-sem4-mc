insert into public.cities (id, name, slug, photo_url) overriding system value values
  (1, 'Jakarta Selatan', 'jakarta-selatan', 'https://images.unsplash.com/photo-1555899434-94d1368aa7af?q=80&w=1200&auto=format&fit=crop'),
  (2, 'Tangerang Selatan', 'tangerang-selatan', 'https://images.unsplash.com/photo-1508964942454-1a56651d54ac?q=80&w=1200&auto=format&fit=crop'),
  (3, 'Bandung', 'bandung', 'https://images.unsplash.com/photo-1598089845447-7ea5b1e8db39?q=80&w=1200&auto=format&fit=crop')
on conflict (slug) do nothing;

insert into public.court_categories (id, name) overriding system value values
  (1, 'Indoor'),
  (2, 'Outdoor'),
  (3, 'Premium')
on conflict (name) do nothing;

insert into public.courts (
  id,
  city_id,
  category_id,
  name,
  thumbnail_url,
  about,
  material,
  price_per_hour,
  address,
  phone,
  status,
  is_featured
) overriding system value values
  (
    1,
    1,
    3,
    'PadalPro Arena Kemang',
    'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?q=80&w=1200&auto=format&fit=crop',
    'Premium indoor padel court with lounge, shower room, and coaching support.',
    'Synthetic Turf',
    350000,
    'Jl. Kemang Raya No. 12, Jakarta Selatan',
    '+628111111101',
    'active',
    true
  ),
  (
    2,
    2,
    1,
    'Bintaro Padel Club',
    'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?q=80&w=1200&auto=format&fit=crop',
    'Comfortable indoor court for casual matches, weekly groups, and beginner sessions.',
    'Panoramic Glass',
    275000,
    'Jl. Bintaro Utama No. 8, Tangerang Selatan',
    '+628111111102',
    'active',
    true
  ),
  (
    3,
    3,
    2,
    'Dago Padel Yard',
    'https://images.unsplash.com/photo-1567220720374-a67f33a5f7b3?q=80&w=1200&auto=format&fit=crop',
    'Outdoor court with fresh air, community sessions, and evening lighting.',
    'Artificial Grass',
    220000,
    'Jl. Dago Atas No. 21, Bandung',
    '+628111111103',
    'active',
    false
  )
on conflict (id) do nothing;

insert into public.court_images (court_id, image_url, sort_order) values
  (1, 'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?q=80&w=1200&auto=format&fit=crop', 1),
  (1, 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?q=80&w=1200&auto=format&fit=crop', 2),
  (2, 'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc67?q=80&w=1200&auto=format&fit=crop', 1),
  (3, 'https://images.unsplash.com/photo-1567220720374-a67f33a5f7b3?q=80&w=1200&auto=format&fit=crop', 1)
on conflict do nothing;

insert into public.court_features (court_id, name) values
  (1, 'Changing Room'),
  (1, 'Coaching Available'),
  (1, 'Cafe'),
  (2, 'Parking Area'),
  (2, 'Equipment Rental'),
  (3, 'Evening Lighting'),
  (3, 'Community Match')
on conflict do nothing;

insert into public.court_operating_hours (court_id, day_of_week, open_hour, close_hour)
select court_id, day_of_week, 7, 23
from generate_series(1, 3) as court_id
cross join generate_series(0, 6) as day_of_week
on conflict (court_id, day_of_week) do nothing;
