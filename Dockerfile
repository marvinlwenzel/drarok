FROM python:3.8

COPY ./Pipfile /opt/app/
COPY ./Pipfile.lock /opt/app/

WORKDIR /opt/app

RUN pip install pipenv

COPY dbot /opt/app/dbot

CMD pipenv run python dbot/Main.py