from dotenv import load_dotenv
import os
if __name__ == '__main__':
    load_dotenv()
    print("Hello world")
    print("Yout Token is {}".format(os.getenv("TOKEN")))