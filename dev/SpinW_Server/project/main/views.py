#################
#### imports ####
#################

from flask import Blueprint,render_template, g

################
#### config ####
################

main_blueprint = Blueprint('main', __name__,)

################
#### routes ####
################

@main_blueprint.route('/')
def home():
    g.views = "Applications"
    return render_template('main/index.html')
