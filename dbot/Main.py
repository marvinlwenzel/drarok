from discord.ext.commands import Bot
from dotenv import load_dotenv
import os
import datetime
from time import sleep

load_dotenv()

starttime = datetime.datetime.now()


class MyBot(Bot):
    to_be_confirmed = False
    exec_after_confirmation = None

    inittime = datetime.datetime.now()

    def __init__(self, command_prefix, description=None, **options):
        self.inittime = datetime.datetime.utcnow()
        super().__init__(command_prefix, description=description, **options)

    async def close_after_commanded(self):
        print("Received command to stop running. Closing Bot.")
        await self.close()


description = '''An example bot to showcase the discord.ext.commands extension
module.

There are a number of utility commands being showcased here.'''
bot = MyBot(command_prefix='?', description=description)


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


bot.run(os.getenv("DRAROK_TOKEN"))
