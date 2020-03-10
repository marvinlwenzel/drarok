# drarok
Python based Discord bot for my own needs. :shrug:

## Dependencies
* Python 3.8
* [pipenv](https://pypi.org/project/pipenv/)

## Install
We're using [pipenv](https://pipenv-es.readthedocs.io/es/stable/basics.html) to create and manage a virtual environment containing all required packages. You have to install pipenv first using pip:
```bash
pip install pipenv
```

To initially create the virutal environment from pipfile run:
```bash
pipenv install
```

To start the server within the the virtual environment run:
```bash
pipenv run <add our command here>
```

You can also run a shell inside the virutal environment running:
```bash
pipenv shell
```
| COMMAND  | container runs before | container does not run before | container runs after                   | container does not run after | build new docker image locally | expect git in WORKDIR |
| -------- | --------------------- | ----------------------------- | -------------------------------------- | ---------------------------- | ------------------------------ | --------------------- |
| START    | error                 | expected                      | expected                               | error                        | no                             | idc                   |
| RESTART  | idc                   | idc                           | expected                               | error                        | no                             | idc                   |
| STOP     | idc                   | idc                           | somehow we gonna kill it for surrender | expected                     | no                             | idc                   |
| INSTALL  | error                 | expected                      | expected                               | error                        | yes                            | yes                   |
| REDEPLOY | idc                   | idc                           | expected                               | error                        | yes                            | yes                   |
|          |                       |                               |                                        |                              |                                |                       |
