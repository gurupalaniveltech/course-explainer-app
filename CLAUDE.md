# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A small Flask web app that lists courses and shows course detail pages. Per README, `python src/app.py` serves it at `http://127.0.0.1:5000`.

This is a **starter template in a partially-implemented state** — see "Known incomplete state" below before assuming existing code is correct.

## Commands

A `venv/` exists in the repo root (Python 3.14, Flask 3.1.2). Prefix commands with `./venv/Scripts/python.exe` (Windows) or activate it first with `venv\Scripts\activate`.

```bash
./venv/Scripts/python.exe src/app.py                          # run dev server (debug=True)
./venv/Scripts/python.exe -m unittest discover -s tests       # run all tests
./venv/Scripts/python.exe -m unittest tests.test_app          # run one test module
./venv/Scripts/python.exe -m unittest tests.test_app.AppTestCase.test_course   # run one test
uv pip install -r requirements.txt                            # install deps (README uses uv)
```

There is no linter, formatter, or CI configured.

## Testing requirement

Every change must ship with tests:

- Add or update unit tests in [tests/test_app.py](tests/test_app.py) for any behavior you add or modify — new routes, view logic, and model changes all need coverage.
- Run the full suite (`./venv/Scripts/python.exe -m unittest discover -s tests`) before reporting the work done, and make sure **all** tests pass — including any that were already failing in the area you touched.
- If a test cannot be made to pass, say so explicitly along with the failure output rather than leaving it silently broken.

## Spec files for large features

Any non-trivial feature (a new page, a data layer, an auth flow, anything spanning several files) gets a written spec **before** the implementation, so another developer can pick it up cold.

- Write it to `specs/<feature-name>.md` (kebab-case), and create the `specs/` directory if it does not exist yet.
- Cover: the problem and goal, routes/endpoints added or changed, data model changes, template changes, and the test cases that will prove it works. Note anything explicitly out of scope.
- Keep the spec in sync as the implementation shifts — a stale spec is worse than none. Link it from the PR or commit that implements it.
- Small changes (a bug fix, copy edit, single-line view change) do not need a spec.

## Architecture

Four moving parts, deliberately split:

- [src/app.py](src/app.py) — creates the `Flask` app and wires routes with `app.add_url_rule` rather than `@app.route` decorators. Routes are registered here, **not** alongside the view functions. Endpoint names (`index`, `course`) are what templates pass to `url_for`.
- [src/views.py](src/views.py) — plain view functions with no Flask decorators. They must stay importable from `app.py` as bare names.
- [src/models.py](src/models.py) — a `Course` class plus a module-level `courses` list acting as the in-memory data store. No database.
- [src/templates/](src/templates/) — Jinja2. [layout.html](src/templates/layout.html) is the base with a `content` block; detail pages `{% extends %}` it.

**Import layout matters.** `app.py` does `from views import index, course` — a flat, non-package import that only resolves when `src/` is on `sys.path`. This is why [tests/test_app.py:6](tests/test_app.py#L6) inserts `src/` into `sys.path` before importing `app`. Running `python -m src.app` from the root will fail; run `python src/app.py`, or keep the `sys.path` shim in tests.

## Template conventions

The starter template shipped with these broken; they are now fixed and guarded by tests, so keep them intact:

- Page templates contain **only** `{% extends 'layout.html' %}`, `{% block title %}`, and `{% block content %}`. No `<html>`, `<head>`, or `<body>` of their own, and never `{% include 'layout.html' %}` — both produce nested documents. `test_pages_extend_layout_without_nesting` asserts exactly one `<!DOCTYPE>` and one `<body>` per page.
- Don't add a `<div class="container">` inside a block; `layout.html` already wraps content in `<main class="container">`.
- CSS lives only in [styles.css](src/static/css/styles.css), linked once from `layout.html` via `url_for('static', ...)`. `test_index_has_no_raw_css` catches CSS pasted into markup.
- Course URLs use `Course.id`, not list position. Look courses up with `models.get_course()`, which returns `None` for unknown or non-numeric ids; views turn that into `abort(404)`.

Design notes for the current course pages are in [specs/course-detail-pages.md](specs/course-detail-pages.md).

## Notes

- `gunicorn` and `python-dotenv` are in [requirements.txt](requirements.txt) but nothing in the code loads a `.env` or references a WSGI entry point. README documents a `.env` file that does not exist.
- `.gitignore` ignores `.venv` but not `venv`, so avoid `git add -A` without checking `git status` first.
- Tests assert on rendered bytes. Note `test_course` matches `b'Course Details'`, which comes from the nav link in `layout.html` rather than from the detail content — editing the layout's nav can break it.
- There is no styled 404 template; unknown course ids get Flask's default error page.
