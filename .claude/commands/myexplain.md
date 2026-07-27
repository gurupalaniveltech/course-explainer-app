---
description: Explain a file — simple summary or detailed walkthrough with a flow chart
argument-hint: <file-path> [simple|detail]
allowed-tools: Read, Grep, Glob
---

Explain the file **$1** at the depth requested by the second argument.

Mode requested: `$2` (if empty, default to `simple`)

## Step 1 — Locate and read

- Read `$1`. If the path is relative or ambiguous, use Glob to resolve it (e.g. `**/$1`) before reading.
- If no file matches, say so plainly and list the closest matches. Do not guess at content.
- Read the whole file. If it is very large, read it in chunks — never explain from a partial read.

## Step 2 — Explain according to mode

### If mode is `simple`

Keep it short — a developer skimming to decide whether to open the file.

1. **What it is** — one sentence: purpose and role in the project.
2. **Key pieces** — up to 6 bullets, one per important function/class/route/export, each with a `file:line` reference and a one-line description.
3. **Dependencies** — what it imports and who imports it (use Grep to check callers).
4. **Gotchas** — up to 3 bullets, only if genuinely non-obvious.

No flow chart in simple mode. Aim for under 250 words.

### If mode is `detail`

Give a full walkthrough so someone could modify the file confidently.

1. **Purpose** — what problem this file solves and where it sits in the architecture.

2. **Flow chart** — an ASCII box/arrow diagram of the main execution path (request → handler → data → response, or input → transform → output). Use this style, adapted to the file:

   ```
   ┌─────────────────┐
   │  entry point    │
   └────────┬────────┘
            │
            ▼
   ┌─────────────────┐      ┌──────────────────┐
   │  main branch    │─────▶│  side effect     │
   └────────┬────────┘  no  └──────────────────┘
            │ yes
            ▼
   ┌─────────────────┐
   │  result         │
   └─────────────────┘
   ```

   Label every branch with its condition. Keep it to the real control flow in the file — do not invent steps.

3. **Line-by-line walkthrough** — go through the file in order, grouped into logical blocks. For each block: the `file:line` range, what it does, and *why* it is written that way. Call out non-obvious idioms.

4. **Data shapes** — every structure that flows through: parameters, return values, module-level state, template variables. Include types and example values.

5. **Interactions** — use Grep to find who calls into this file and what it calls out to. List each edge as `caller → this file → callee`.

6. **Edge cases & failure modes** — what happens on bad input, missing data, or errors. Note anything unhandled.

7. **Testing** — which existing tests cover this file (search `tests/`), and what is *not* covered.

8. **If you change this** — 3–5 bullets on what to watch out for, including anything a test asserts on that would break.

## Rules

- Reference every claim with a clickable `[filename.py:42](path/to/filename.py#L42)` link.
- Describe what the code actually does, not what it appears intended to do. If they differ, say so.
- Explain only. Do not edit any file, and do not propose a refactor unless asked.
- If the second argument is neither `simple` nor `detail`, note that you defaulted to `simple` and continue.
