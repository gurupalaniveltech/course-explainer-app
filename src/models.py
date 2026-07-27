class Course:
    def __init__(self, id, title, description, instructor, duration, topics=None):
        self.id = id
        self.title = title
        self.description = description
        self.instructor = instructor
        self.duration = duration
        self.topics = topics or []

    def __repr__(self):
        return f"<Course {self.title} by {self.instructor}>"

courses = [
    Course(1, "Introduction to Python", "Learn the basics of Python programming.", "John Doe", "4 weeks",
           ["Syntax and types", "Control flow", "Functions", "Modules and packages"]),
    Course(2, "Web Development with Flask", "Build web applications using Flask.", "Jane Smith", "6 weeks",
           ["Routing", "Jinja2 templates", "Forms and validation", "Deployment"]),
    Course(3, "Data Science Fundamentals", "An introduction to data science concepts and tools.", "Alice Johnson", "8 weeks",
           ["NumPy and pandas", "Data cleaning", "Visualization", "Intro to modelling"]),
]

def get_course(course_id):
    """Return the Course with this id, or None if the id is unknown or not a number."""
    try:
        wanted = int(course_id)
    except (TypeError, ValueError):
        return None
    return next((course for course in courses if course.id == wanted), None)
