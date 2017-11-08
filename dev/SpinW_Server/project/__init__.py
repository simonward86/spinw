# project/__init__.py


#################
#### imports ####
#################

import os

from flask import Flask, render_template, g
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager, current_user
################
#### config ####
################

def _check_config_variables_are_set(config):

    assert config['SECRET_KEY'] is not None,\
           'SECRET_KEY is not set, set it in the production config file.'
    assert config['SECURITY_PASSWORD_SALT'] is not None,\
           'SECURITY_PASSWORD_SALT is not set, '\
           'set it in the production config file.'

    assert config['SQLALCHEMY_DATABASE_URI'] is not None,\
           'SQLALCHEMY_DATABASE_URI is not set, '\
           'set it in the production config file.'


app = Flask(__name__)


app.config.from_object(os.environ['APP_SETTINGS'])
config = app.config
_check_config_variables_are_set(config)

####################
#### extensions ####
####################

login_manager = LoginManager(app)

db = SQLAlchemy(app)

if config.get('USE_PYMATLAB'):
    import matlab.engine
    eng = matlab.engine.start_matlab()
    eng.addpath(eng.genpath(config.get('DEPLOY_PATH')))
    cores = config.get('CORES')
    if cores > 1:
        eng.parpool(cores)

else:
    from project.deploy_conn import tcip
    eng = tcip.tcip(config.get('DEPLOY_SERVER'), config.get('DEPLOY_PORT'))


####################
#### flask-login ####
####################
login_manager.login_view = "user.login"
login_manager.login_message_category = "danger"
from project.models import User

@login_manager.user_loader
def load_user(user_id):
    return User.query.filter(User.id == int(user_id)).first()

####################
#### vairables  ####
####################
results = dict()
running = dict()

####################
#### blueprints ####
####################

from project.main.views import main_blueprint
from project.spinw.views import spinw_blueprint
from project.user.views import user_blueprint

app.register_blueprint(main_blueprint)
app.register_blueprint(user_blueprint)
app.register_blueprint(spinw_blueprint)

####################
#### threading  ####
####################
from status import Status

status_thread = Status(2)
status_thread.start()


####################
#  context inject  #
####################
@app.context_processor
def inject_data():
    if 'views' in g:
        return dict(user=current_user, views=g.views)
    else:
        return dict(user=current_user, views='Temp')


########################
#### error handlers ####
########################

@app.errorhandler(403)
def forbidden_page(error):
    g.views = '403 Error'
    return render_template("errors/403.html"), 403

@app.errorhandler(401)
def forbidden_page(error):
    g.views = '401 Error'
    return render_template("errors/401.html"), 401

@app.errorhandler(404)
def page_not_found(error):
    g.views = '404 Error'
    return render_template("errors/404.html"), 404


@app.errorhandler(500)
def server_error_page(error):
    g.views = '500 Error'
    return render_template("errors/500.html"), 500