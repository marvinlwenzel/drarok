FROM python:3.8

COPY . /opt/app

WORKDIR /opt/app

RUN pip install pipenv

RUN pipenv install

CMD pipenv run python dbot/Main.py