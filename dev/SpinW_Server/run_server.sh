#!/bin/bash

export FLASK_APP=spinwServer
export APP_SETTINGS=project.config.DevelopmentConfig
export PYTHONPATH=$PWD

flask run -p 80 -h 0.0.0.0
