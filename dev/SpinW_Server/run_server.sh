#!/bin/bash

export FLASK_APP=spinwServer
export APP_SETTINGS=project.config.DevelopmentConfig
export PYTHONPATH=$PWD

flask create
flask run
