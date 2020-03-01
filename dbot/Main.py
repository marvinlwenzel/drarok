import discord
from discord.ext.commands import Bot
from dotenv import load_dotenv
import os
import datetime

load_dotenv()

starttime = datetime.datetime.now()

class MyBot(Bot):
    to_be_confirmed = False
    exec_after_confirmation = None

    pass

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
    await ctx.send("Do you want me to stop running?")


#
# class MyClient(discord.Client):
#     die = False
#     async def on_ready(self):
#         print('Logged in as')
#         print(self.user.name)
#         print(self.user.id)
#         print('------')
#
#     async def on_message(self, message):
#         # we do not want the bot to reply to itself
#         if message.author.id == self.user.id:
#             return
#
#         if message.content.startswith('!hello'):
#             print("Hello")
#             await message.channel.send('Hello {0.author.mention}'.format(message))
#
#         if message.content.startswith('!starttime'):
#             print("starttime")
#             await message.channel.send('Startet at {}'.format(starttime))
#
#         if message.content.startswith('!ping'):
#             print("pong")
#             await message.channel.send('pong')
#
#         if message.content.startswith('!die') and not self.die:
#             print("first die")
#             self.die = True
#             await message.channel.send('Do you want me to shut down? Write !yes or !no')
#
#         if message.content.startswith('!yes') and self.die:
#             print("dying")
#             await message.channel.send('NANI???')
#             await self.logout()
#             exit(0)
#
#         if message.content.startswith('!no') and self.die:
#             print("stopped die")
#             self.die = False
#             await message.channel.send('ok, stopping dying')
#

bot.run(os.getenv("TOKEN"))

