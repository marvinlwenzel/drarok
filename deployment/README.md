# Deployment

Drarok is intended to be deployed with docker and the `cheapdeploy.sh` script.
In here are sample files that indicate the type of configurations are needed for
deployment.

| File                       | What is it?                                                                                                    |
| -------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `.env`                     | A single file containing all configuration. It accumulates all other `*.env` listed below                      |
| `drarok.env`               | Runtime configuration for Drarok. Contains tokens and filenames for everything that should be read at runtime. |
| `drarok_deployment.env`    | Deployment configuration for Drarok, catered specifically for `cheapdeploy.sh`                                 |
| `drarok-abcd1234abcd.json` | The GoogleService authentication credentials. Needed for GoogleSpreadSheets API                                |
