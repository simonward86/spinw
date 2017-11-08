from project import app, db
from project.models import User, UserJobs
import datetime


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

    app.run(debug=True)