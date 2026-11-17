-- Synthetic ToonAgeDB at schema 1 with an explicit analytics opt-in.
-- Migration 2 must leave analytics true. No real character or realm.
return {
    schemaVersion = 1,
    analytics = true,
    analyticsOptedIn = true,
    char = {},
}
