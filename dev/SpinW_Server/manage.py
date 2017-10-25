import os
from project import app, db
from project.models import User, UserJobs
import datetime

# @manager.command
# def test():
#     """Runs the unit tests without coverage."""
#     tests = unittest.TestLoader().discover('tests')
#     result = unittest.TextTestRunner(verbosity=2).run(tests)
#     if result.wasSuccessful():
#         return 0
#     else:
#         return 1
#
#
# @manager.command
# def cov():
#     """Runs the unit tests with coverage."""
#     tests = unittest.TestLoader().discover('tests')
#     unittest.TextTestRunner(verbosity=2).run(tests)
#     COV.stop()
#     COV.save()
#     print('Coverage Summary:')
#     COV.report()
#     basedir = os.path.abspath(os.path.dirname(__file__))
#     covdir = os.path.join(basedir, 'tmp/coverage')
#     COV.html_report(directory=covdir)
#     print('HTML version: file://%s/index.html' % covdir)
#     COV.erase()
#
#
@app.cli.command('create')
def create_db():
    """Creates the db tables."""
    db.create_all()


@app.cli.command('drop')
def drop_db():
    """Drops the db tables."""
    db.drop_all()


@app.cli.command('clear_jobs')
def clear_jobs():
    """Drops the db tables."""
    UserJobs.__table__.drop(db.engine)
    UserJobs.__table__.create(db.engine)


#
@app.cli.command('make_admin')
def create_admin():
    """Creates the admin user."""
    db.session.add(User(
        'admin',
        'admin',
        admin=True,
        confirmed=True,
        confirmed_on=datetime.datetime.now())
    )
    db.session.commit()


if __name__ == '__main__':
    # from project.models import UserJobs, User
    # from manage import create_db, create_admin
    # if app.config['SQLALCHEMY_DATABASE_URI'] is 'sqlite:///:memory:':
    #     create_db()
    #     create_admin()
    # else:
    #     if not os.path.exists(app.config['SQLALCHEMY_DATABASE_URI'].split('///')[1]):
    #         create_db()
    #         create_admin()

    app.run(debug=True)