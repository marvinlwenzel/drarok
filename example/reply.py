import discord
from dotenv import load_dotenv
import os

class MyClient(discord.Client):
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


load_dotenv()
client = MyClient()
client.run(os.getenv("TOKEN"))
