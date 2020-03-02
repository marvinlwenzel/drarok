import gspread
from oauth2client.service_account import ServiceAccountCredentials


def _guild_storage_name_for_id(guild_id):
    return "DBS_Guild[{}]".format(guild_id)


def _global_storage_for_id(id):
    return "DBS_global[]".format(id)


class GoogleSpreadsheetStorage:

    def __init__(self, cred_json):
        self.scope = ['https://spreadsheets.google.com/feeds',
                      'https://www.googleapis.com/auth/drive']
        self.credentials = ServiceAccountCredentials.from_json_keyfile_name(cred_json, self.scope)
        self.gc = gspread.authorize(self.credentials)

    def has_guild_storage(self, guild_id):
        try:
            x = self.gc.open(_guild_storage_name_for_id(guild_id))
        except:
            return False
        else:
            return x is not None

    def create_guild_storage(self, guild_id):
        new_sheet = self.gc.create(_guild_storage_name_for_id(guild_id))
        new_sheet.share("atminbokz@gmail.com", role="writer", perm_type="user")


class PersonalGuildNote:
    def __init__(self, guild_id, user_id, note_value, note_name=None):
        self.guild_id = guild_id
        self.user_id = user_id
        self.name = note_name
        self.content = note_value


class PersonalGuildNotesRepository:
    '''
    The first two columns are reserved for content, name respectively.
    '''
    def __init__(self, gss: GoogleSpreadsheetStorage, guild_id):
        self.gss = gss
        self.guild_id = guild_id
        self.ss = self.gss.gc.open(_guild_storage_name_for_id(self.guild_id))

    def read_all_for_user(self, user_id):
        try:
            wks = self.ss.worksheet(str(user_id))
        except:
            return None
        result = []
        content = wks.col_values(1)
        for i in range(len(content)):
            result.append(PersonalGuildNote(self.guild_id, user_id, content[i], wks.cell(row=i+1, col=2).value, ))
        return result

    def add_note_for_user(self, user_id, content, name=None):
        try:
            wks = self.ss.worksheet(str(user_id))
        except:
            wks = self.ss.add_worksheet(title=str(user_id), cols=3, rows=50)
        wks.append_row([content, name])