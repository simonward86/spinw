#################
#### imports ####
#################
import json

from flask import abort, request, render_template, Blueprint, url_for, redirect, flash, g
from flask_login import login_user, logout_user, login_required, current_user
import datetime
import base64

from project import db, config, login_manager
from project.models import User, UserJobs

from project.user.forms import RegisterForm, LoginForm

################
#### config ####
################

user_blueprint = Blueprint('user', __name__, )

################
####  auth  ####
################
@login_manager.request_loader
def load_user_from_request(request):
    user = None
    header = request.headers.get('Authorization')
    if header is None:
        return user

    if 'Basic' in header:
        api = base64.b64decode(header.replace('Basic ', '', 1)).decode()
        (username, password) = api.split(':')
        user = verify_password(username, password)
    elif 'Token' in header:
        user = verify_token(header.replace('Basic ', '', 1))
    g.user = user
    return user


def verify_password(username_or_token, password):
    # first try to authenticate by token if user is silly
    user = verify_token(username_or_token)
    if user is None:  # this sets g.user as well.
        # try to authenticate with username/password
        user = User.query.filter_by(username=username_or_token).first()
        if not user or not user.verify_password(password):
            user = User.query.filter_by(email=username_or_token).first()
            if not user or not user.verify_password(password):
                return None
    return user

def verify_token(token):
    user = User.verify_auth_token(token)
    return user

@login_manager.unauthorized_handler
def send_unauth():
    abort(403)

################
#### route  ####
################
@user_blueprint.route('/users/register', methods=['GET', 'POST'])
def register():
    g.views = "Register"
    best = request.accept_mimetypes.best_match(['application/json', 'text/html'])
    if best in 'text/html':
        form = RegisterForm(request.form)
        if form.validate_on_submit():
            user = User(form.username.data, form.password.data,
                        email=form.email.data, confirmed=False)
            db.session.add(user)
            db.session.commit()
            flash('Registration successful', 'success')
        else:
            flash('Registration failed', 'danger')
            render_template('user/register.html', form=form)
        return render_template('user/register.html', form=form)

    elif best in 'application/json':
        if 'MATLAB' in request.headers.environ.get('HTTP_USER_AGENT'):
            username = request.form.get('username')
            password = request.form.get('password')
            email = request.form.get('email')
        else:
            username = request.json.get('username')
            password = request.json.get('password')
            email = request.json.get('email')
        if username is None:
            abort(400)
        else:
            if password is None and not config.get('USE_LDAP'):
                abort(400)  # missing arguments
        if User.query.filter_by(email=email).first() is not None:
            abort(409)  # existing user
        if config.get('USE_LDAP'):  # Create the user
            user = User(username=username, password="", email=email)
        else:
            user = User(username=username, password=password, email=email)
        db.session.add(user)
        db.session.commit()
        return json.dumps({'username': user.email}), 201
    else:
        abort(400)


@user_blueprint.route('/users/login', methods=['GET', 'POST'])
def login():
    form = LoginForm(request.form)
    g.views = "Login"
    if form.validate_on_submit():
        user = User.query.filter_by(email=form.email.data).first()
        if user and verify_password(user.email, request.form['password']):
            login_user(user)
            flash('Login successful.', 'success')
            return redirect(url_for('user.job_list'))
        else:
            flash('Invalid email and/or password.', 'danger')
            return render_template('user/login.html', form=form)
    return render_template('user/login.html', form=form)


@user_blueprint.route('/users/logout')
@login_required
def logout():
    logout_user()
    flash('You were logged out.', 'success')
    return redirect(url_for('user.login'))


@user_blueprint.route('/users/confirm/<token>')
def confirm_email(token):
    user = User.verify_auth_token(token)
    if user is None:
        ret = {"message": 'The confirmation link is invalid or has expired.', "success": False}
        return json.dumps(ret)
    if user.confirmed:
        ret = {"message": 'Account already confirmed. Please login.', "success": True}
    else:
        user.confirmed = True
        user.confirmed_on = datetime.datetime.now()
        db.session.commit()
        ret = {"message": 'You have confirmed your account. Thanks!', "success": True}
    return json.dumps(ret)


@user_blueprint.route('/users/token')
@login_required
def get_auth_token():
    user = current_user
    token = user.generate_auth_token(config.get("TOKEN_DURATION"))
    return json.dumps({'token': token.decode('ascii'), 'duration': config.get("TOKEN_DURATION")})


@user_blueprint.route('/users/quota')
@login_required
def get_quota():
    user = current_user
    return json.dumps({'used': user.quota_used, 'total': user.quota_total})


@user_blueprint.route("/users/jobs",methods=["GET","POST"])
@login_required
def job_list():
    if request.method == "GET":
        best = request.accept_mimetypes.best_match(['application/json', 'text/html'])
        running_jobs = list(map(lambda x: x.get_public(),
                            db.session.query(UserJobs).filter(UserJobs.completed == False,
                                                              UserJobs.running == True,
                                                              UserJobs.user_id == current_user.id
                                                              ).order_by(UserJobs.start_time).all()))
        done_jobs = list(map(lambda x: x.get_public(),
                         db.session.query(UserJobs).filter(UserJobs.completed == True,
                                                           UserJobs.running == False,
                                                           UserJobs.user_id == current_user.id
                                                           ).order_by(UserJobs.start_time).all()))
        if best in 'text/html':
            g.views = "Job Monitor"
            return render_template('user/job_table.html', running_jobs=running_jobs, done_jobs=done_jobs)
        else:
            waiting_jobs = list(map(lambda x: x.get_public(),
                                db.session.query(UserJobs).filter(UserJobs.completed == False,
                                                                  UserJobs.running == False,
                                                                  UserJobs.user_id == current_user.id
                                                                  ).order_by(UserJobs.start_time).all()))
            return json.dumps({"Waiting":waiting_jobs,"Running":running_jobs,'Completed':done_jobs})
    else:
        if request.json is None:
            job = request.form.get('job_id')
            action = request.form.get('action')
        else:
            job = request.json.get('job_id')
            action = request.json.get('action')
        if job is None:
            abort(400)
        got_job = db.session.query(UserJobs).filter(UserJobs.job_id == job,UserJobs.user_id == current_user.id).order_by(UserJobs.start_time).all()
        if got_job is None:
            abort(400)
        if action is None:
            json.dumps(got_job.get_public)
        elif action == 'delete':
            db.session.query(UserJobs).filter(UserJobs.job_id == job, UserJobs.user_id == current_user.id).delete(synchronize_session=False)
            db.session.commit()
            return json.dumps({"message": 'Deleted job %s'%job, "success": True})

@user_blueprint.route("/users")
@login_required
def user_home():
    user = current_user
    return current_user.username
