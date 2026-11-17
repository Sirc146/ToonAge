-- Synthetic ToonAgeDB from before schema 1.
-- No real character, realm, or SavedVariables. Pebble-Fakeserver is fake.
return {
    onboardScope = "account",
    onboardedAccount = true,
    char = {
        ["Pebble-Fakeserver"] = { note = "synthetic pre-migration row" },
    },
}
