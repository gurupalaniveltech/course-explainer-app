# Spec: model-backed course pages

## Problem

The templates were written against a data model that was never wired up. `models.courses` is
unused, `views.course()` passes only a raw `course_id`, and `course.html` renders
`{{ course.title }}` — so `/course/<id>` returns a 500 (`'course' is undefined`). The landing page
hardcodes three links labelled "Course 1/2/3". Separately, both page templates are full standalone
HTML documents that misuse `layout.html`, producing nested `<html>` documents and pushing page
content outside the layout's `.container`.

## Goal

Serve both pages from `models.courses` and render them through `layout.html` via template
inheritance.

## Data model ([src/models.py](../src/models.py))

- `Course` gains `id` (int, stable public identifier) and `topics` (list of strings). `topics`
  defaults to an empty list so a course without topics is valid.
- Seed the three existing courses with ids 1–3 and a short topic list each.
- Add `get_course(course_id)`: coerces the value to `int`, returns the matching `Course` or `None`.
  Lookup is by `id`, **not** by list position — the URL id is decoupled from list order.

## Routes ([src/views.py](../src/views.py))

No new routes; `app.py` wiring is unchanged.

- `index()` → passes `courses` to the template.
- `course(course_id)` → `get_course()`, then `abort(404)` when the id is unknown or non-numeric.
  Previously any id returned 200 (or 500); unknown ids are now a proper 404.

## Templates

- [index.html](../src/templates/index.html) and [course.html](../src/templates/course.html) become
  `{% extends 'layout.html' %}` with `{% block title %}` and `{% block content %}` only — no
  `<html>`, `<head>`, or `<body>` of their own, and no `{% include %}`.
- Their own `<div class="container">` wrappers are dropped; `layout.html` already wraps
  `{% block content %}` in `<main class="container">`.
- The landing page loops over `courses`, linking each by `course.id` and labelling it with
  `course.title` instead of "Course N".

## Test cases ([tests/test_app.py](../tests/test_app.py))

- Landing page lists real course titles and links to `/course/1`.
- `/course/1` returns 200 and renders title, description, instructor, duration, and topics.
- `/course/999` returns 404; `/course/abc` returns 404 (not 500).
- Neither page emits a nested `<!DOCTYPE>` (guards the `extends` structure).
- Existing `test_index_has_no_raw_css` continues to guard the layout against pasted CSS.

## Out of scope

- Persistence — `courses` stays an in-memory list.
- Course creation/editing, search, pagination, and a styled 404 page.
- The unused `gunicorn` / `python-dotenv` dependencies and the missing `.env`.
