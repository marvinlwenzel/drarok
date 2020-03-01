from dotenv import load_dotenv
import os
if __name__ == '__main__':

    print("Hello world")
    print("Yout Token is {}".format(os.getenv("TOKEN")))