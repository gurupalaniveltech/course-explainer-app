from flask import abort, render_template
from models import courses, get_course

def index():
    return render_template('index.html', courses=courses)

def course(course_id):
    found = get_course(course_id)
    if found is None:
        abort(404)
    return render_template('course.html', course=found)
