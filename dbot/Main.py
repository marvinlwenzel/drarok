import discord
from dotenv import load_dotenv
import os
import datetime

starttime = datetime.datetime.now()
die = False


class MyClient(discord.Client):
    die = False
    async def on_ready(self):
        print('Logged in as')
        print(self.user.name)
        print(self.user.id)
        print('------')

    async def on_message(self, message):
        # we do not want the bot to reply to itself
        if message.author.id == self.user.id:
            return

        if message.content.startswith('!hello'):
            print("Hello")
            await message.channel.send('Hello {0.author.mention}'.format(message))

        if message.content.startswith('!starttime'):
            print("starttime")
            await message.channel.send('Startet at {}'.format(starttime))

        if message.content.startswith('!ping'):
            print("pong")
            await message.channel.send('pong')

        if message.content.startswith('!die') and not self.die:
            print("first die")
            self.die = True
            await message.channel.send('Do you want me to shut down? Write !yes or !no')

        if message.content.startswith('!yes') and self.die:
            print("dying")
            await message.channel.send('NANI???')
            await self.logout()
            exit(0)

        if message.content.startswith('!no') and self.die:
            print("stopped die")
            self.die = False
            await message.channel.send('ok, stopping dying')


load_dotenv()
client = MyClient()
client.run(os.getenv("TOKEN"))
