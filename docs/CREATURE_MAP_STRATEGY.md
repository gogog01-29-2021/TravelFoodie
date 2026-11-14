# Creature Map — Strategy

A game-style layer for TravelFoodie, inspired by monster-collecting map games:
restaurants become "habitats" on a stylised map, you find creatures by being near
them and shaking the phone, and what you catch fills a collection ("Foodie-dex").

This is a plan to iterate on, not a spec. Nothing here is implemented yet.

## 1. Guardrail first: original IP only

Pokémon and Nintendo/The Pokémon Company IP must not appear anywhere shipped.

- No Pokémon names, characters, sprites, ball designs or logos in the app, store
  listing, screenshots, icons, string resources, code identifiers or search keywords.
- The shipped feature name must be our own (working name: **Foodie-dex**).
- Use an original creature set (see section 4, v1.3). Keep a record of where every
  piece of art came from (author, licence, date). Re-check the licence if art is
  AI-generated.
- Why this is rule one: Google Play removes apps on IP complaints, and it can put
  the whole developer account at risk, not just one release.

## 2. What the code gives us today

| Need | Already in the repo | Gap |
|---|---|---|
| Map | `feature/trip/.../MapFragment.kt` (Google Maps SDK 18.2.0): default style, one marker for the tapped place, search, My Location FAB | No styling, no restaurant markers |
| Restaurants | `RestaurantEntity` in `core/data/.../local/entity/Entities.kt` (id, regionId, name, category, rating, lat, lng) | Not shown on the map |
| Shake | `core/sensors/.../ShakeDetector.kt` | Only wired up inside `RestaurantListFragment` |
| Proximity | `RestaurantListFragment` uses `Location.distanceBetween` for `isNearDestination` | Lives in one screen; `AttractionListFragment` bypasses it |
| Animation | Lottie `slot_machine.json` in `feature/restaurant` and `feature/attraction` | No encounter / catch animation |
| Persistence | Room `AppDatabase` v7, Firebase sync in `core/sync` | No collection tables |

## 3. Constraints that shape the plan

- **Room migration.** `DataModule.kt` and `AppDatabase.kt` call
  `fallbackToDestructiveMigration()`. Adding a collection table without an explicit
  `Migration(7, 8)` would wipe local data on update, including everything a user
  has caught. Write the migration and test the upgrade path.
- **Foreground only.** Keep encounters foreground-only. Background location triggers a
  much heavier Play review and is not needed for a shake-to-encounter loop.
- **Map and Places terms.** Custom map styling is allowed, but it must not hide Google
  attribution. Before building a persistent collection on top of Places results,
  re-read the current Google Maps Platform terms on caching and storing Places data,
  and the Kakao Local API terms. Safest design: store our own IDs plus the place ID,
  and refresh the rest.
- **Privacy.** A capture log is location history. Update the privacy policy and the
  Play Data safety form before shipping v1.3.
- **Safety.** Add a "don't play while walking in traffic or driving" notice on first use.

## 4. Phases

**v1.1 — Look (low risk, no data changes)**
- Add `res/raw/map_style.json` and apply it with `MapStyleOptions` in `onMapReady`.
  JSON styling needs no Cloud Console map ID.
- Load the selected trip's restaurants onto the map with a custom marker per food
  category (vector drawables to `BitmapDescriptor`). Cluster if a region has many.
- Touches: `MapFragment.kt`, `fragment_map.xml`, new drawables and raw resource.

**v1.2 — Encounter**
- Pull the shake + proximity logic out of `RestaurantListFragment` into a reusable
  controller that the map screen can also use.
- On shake near a restaurant, pick a creature (stable per restaurant: seed with
  `restaurantId`, weight rarity by rating) and show an encounter dialog with a new
  Lottie animation. Reuse `slot_machine.json` as a placeholder until art exists.
- Touches: `core/sensors`, `feature/restaurant`, `feature/trip` (map).

**v1.3 — Collect**
- `CreatureEntity` (catalog, can ship as bundled JSON) and `CaptureEntity`
  (captureId, userId, creatureId, restaurantId, tripId, capturedAt, lat, lng).
  New DAO, **`Migration(7, 8)`**, Foodie-dex grid screen (silhouettes for uncaught).
- Optional Firebase sync through `core/sync` (open question below).
- Touches: `core/data`, `core/domain`, new screen, navigation graph.

**v1.4 — Polish (optional)**
- Per-trip completion badges, a Kakao share card (Kakao share is already in the app),
  sound, widget showing Foodie-dex progress.

## 5. Release order

Ship the plain app as 1.0.0 first. The Play target-API requirement and the store
review are the long pole, and the creature features can then ship as 1.1.0 to 1.3.0
without blocking the first release. Check in Play Console whether a new personal
developer account must run a closed test with a minimum number of testers before
production.

## 6. Open questions for the owner

1. Art: who makes the creatures, and what is the budget and licence?
2. Should the collection sync through Firebase (needs login, shows up on new phones)
   or stay on-device only?
3. Korea-only first, or international? (Affects Kakao vs Google data, and language.)
4. Is shipping 1.0.0 before the map work acceptable?
5. Is "Foodie-dex" the final name, or do we want something more distinct?
