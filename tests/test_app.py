import unittest
import sys
import os

# Add the src directory to the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'src')))

from app import app
from models import courses

class AppTestCase(unittest.TestCase):
    def setUp(self):
        self.app = app.test_client()
        self.app.testing = True

    def test_index(self):
        response = self.app.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Welcome to the Course Explainer', response.data)

    def test_index_lists_every_course(self):
        response = self.app.get('/')
        for course in courses:
            self.assertIn(course.title.encode(), response.data)
            self.assertIn(f'/course/{course.id}'.encode(), response.data)

    def test_index_has_no_raw_css(self):
        # styles.css must be linked, never pasted into the layout body
        response = self.app.get('/')
        self.assertNotIn(b'box-sizing', response.data)
        self.assertNotIn(b'existing code', response.data)

    def test_course(self):
        response = self.app.get('/course/1')
        self.assertEqual(response.status_code, 200)
        self.assertIn(b'Course Details', response.data)

    def test_course_renders_model_data(self):
        expected = courses[0]
        response = self.app.get(f'/course/{expected.id}')
        self.assertEqual(response.status_code, 200)
        body = response.data.decode()
        self.assertIn(expected.title, body)
        self.assertIn(expected.description, body)
        self.assertIn(expected.instructor, body)
        self.assertIn(expected.duration, body)
        for topic in expected.topics:
            self.assertIn(topic, body)

    def test_course_unknown_id_returns_404(self):
        self.assertEqual(self.app.get('/course/999').status_code, 404)

    def test_course_non_numeric_id_returns_404(self):
        self.assertEqual(self.app.get('/course/abc').status_code, 404)

    def test_pages_extend_layout_without_nesting(self):
        # both templates must extend layout.html, not wrap it in a second document
        for path in ('/', '/course/1'):
            body = self.app.get(path).data.decode()
            self.assertEqual(body.lower().count('<!doctype html>'), 1, path)
            self.assertEqual(body.lower().count('<body>'), 1, path)

if __name__ == '__main__':
    unittest.main()
