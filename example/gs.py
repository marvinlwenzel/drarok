from dbot.storage import GoogleSpreadsheetStorage, PersonalGuildNote, PersonalGuildNotesRepository

uid = 321321321
gid = 683400722985123888

gss = GoogleSpreadsheetStorage("drarok-f6d2effce9cb.json")

if not gss.has_guild_storage(gid):
    gss.create_guild_storage(gid)

x = PersonalGuildNotesRepository(gss, gid)

x.add_note_for_user(uid, "Was du wieder erkennst", "name123")
x.add_note_for_user(uid, "Geheim")
x.add_note_for_user(uid, "Deine große liebe für Jenny", "Eine Lüge")

x.read_all_for_user(uid)

gss.has_guild_storage(uid)
