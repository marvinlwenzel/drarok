from discord.ext.commands import Bot
from dotenv import load_dotenv
import os
import datetime
from time import sleep

from storage import GoogleSpreadsheetStorage, PersonalGuildNotesRepository, PersonalGuildNote

load_dotenv(dotenv_path="drarok.env")

starttime = datetime.datetime.now()


class MyBot(Bot):
    to_be_confirmed = False
    exec_after_confirmation = None

    inittime = datetime.datetime.now()

    def __init__(self, gstoreage_credential_json, command_prefix='?', description=None, **options):
        super().__init__(command_prefix, description=description, **options)
        self.inittime = datetime.datetime.utcnow()
        self.gss = GoogleSpreadsheetStorage(gstoreage_credential_json)

    async def close_after_commanded(self):
        print("Received command to stop running. Closing Bot.")
        await self.close()


description = '''An example bot to showcase the discord.ext.commands extension
module.

There are a number of utility commands being showcased here.'''
bot = MyBot(gstoreage_credential_json=os.getenv("GS_CRED_JSON"), command_prefix='?', description=description)


@bot.event
async def on_ready():
    print('Logged in as')
    print(bot.user.name)
    print(bot.user.id)
    print('------')


@bot.command()
async def add(ctx, left: int, right: int):
    """Adds two numbers together."""
    await ctx.send(left + right)


@bot.command()
async def die(ctx):
    bot.exec_after_confirmation = bot.close_after_commanded
    bot.to_be_confirmed = True
    await ctx.send("Do you want me to stop running?")


@bot.command()
async def exit(ctx):
    await die(ctx)


@bot.command()
async def yes(ctx):
    if not bot.to_be_confirmed:
        await ctx.send("Nothing to confirm.")
    else:
        await ctx.send("Confirmed")
        do_now = bot.exec_after_confirmation
        bot.to_be_confirmed = False
        bot.exec_after_confirmation = None
        await do_now()


@bot.command()
async def no(ctx):
    if not bot.to_be_confirmed:
        await ctx.send("Nothing to decline.")
    else:
        await ctx.send("Declined")
        bot.to_be_confirmed = False
        bot.exec_after_confirmation = None


@bot.command()
async def delme(ctx, time: int):
    delmsg = ctx.message
    time = 3 if time is None else time
    answer = await ctx.send("5")
    for t in reversed(range(time - 1)):
        sleep(1)
        msg = "Bye" if t == 0 else str(t)
        await answer.edit(content=msg)

    await delmsg.delete()
    await answer.delete()


@bot.command()
async def starttime(ctx):
    await ctx.send("Started {} UTC".format(bot.inittime))


@bot.command()
async def newprefix(ctx, prefix: str):
    old = bot.command_prefix
    bot.command_prefix = prefix
    await ctx.send("Change prefix from {} to {}".format(old, bot.command_prefix))


@bot.command()
async def note(ctx, *args: str):
    gid = ctx.guild.id
    uid = ctx.author.id

    if len(args) == 0 or args[0] == 'help':
        await ctx.send("Here you should get a useful and up-to-date help msg at some point")
        return
    elif args[0] == 'list':
        answer = await ctx.send("Fetching notes...")
        pgs = PersonalGuildNotesRepository(bot.gss, guild_id= gid)
        notes = pgs.read_all_for_user(uid)
        printable_notes = map(PersonalGuildNote.pretty_print, notes)
        msg = """```\n{}```""".format("\n".join(printable_notes))
        await answer.edit(content=msg)
        return
    elif args[0] == 'add':
        note = " ".join(args[1:])
        answer = await ctx.send("Adding note...")
        pgs = PersonalGuildNotesRepository(bot.gss, guild_id=gid)
        pgs.add_note_for_user(user_id=uid, content=note)
        await answer.edit(content="Done")
        return
    else:
        await ctx.send("Here you should get a useful and up-to-date help msg at some point")

bot.run(os.getenv("DRAROK_TOKEN"))
