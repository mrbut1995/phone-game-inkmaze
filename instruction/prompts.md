# Prompts to give the AI agent (copy, fill, send)

Rule of thumb: **one stage per run, one NEW chat per run, one explicit file, no folder attachments.** Do not answer "continue" in the same chat after a session ends: open a new chat and paste prompt 2 (the history of earlier sessions would be re-sent at every step; one session cost 12.8M input tokens this way). Attach nothing automatically (close the "current file" chip in Copilot Chat). Commit a git baseline before every run (`git add -A && git commit -m base`).

## 0. Before the first run
`instruction/<game>_gameplay.md` is filled (spatial/directional rules have worked examples, section 5; every criterion has an id, section 15). Optional: `python tools/start.py`.

## 1. Plan only (first run for a new game)
```
Read #file:instruction/brief.md and follow it.
Task: create the plan for instruction/duckpond_gameplay.md using `python tools/gameplay_to_plan.py`, then refine each session
(real file paths, contracts, budget) until `python tools/plan.py check` passes.
Do NOT write game code. Stop and report the sessions table, risks and open questions.
```

## 2. Execute one plan session (repeat per session)
```
Read #file:instruction/brief.md and follow it.
Task: execute the next plan session (`python tools/plan.py next`). Read only its Context pack.
Finish with `python tools/run_checks.py` (exit 0), `python tools/diff_summary.py --save docs/reports/<date>_<session>.md`,
`python tools/plan.py finish <S..>`, then STOP. Do not start the next session.
```

## 3. Fix a bug / change something small
```
Read #file:instruction/brief.md and follow it.
Bug: <what you see, where, expected>. First reproduce it with a failing test (one per direction/case, plus the blocked/edge case),
then fix, then `python tools/run_checks.py`. Report with diff_summary. Do not touch unrelated code.
```

## 4. Prepare work for an external AI website (Claude / AI Studio)
```
Follow #file:ai_helper/instruction_ai_helper.md . Request: <what I want changed>. Target: claude | aistudio.
Prepare the session and STOP.
```
Then paste `prompt.txt`, attach `context.txt`, save the answer to `response.md` and say "apply session N".

## 5. Review what an agent did
```
Read #file:instruction/brief.md. Review the last run: compare the changes (`git diff --stat`, `python tools/diff_summary.py`)
and docs/reports/<file> with the rules; list deviations by rule id. Do not change code.
```

## Common mistakes
- Attaching the whole `instruction/` folder or the open editor file: costs ~25k tokens before any work. Use `#file:instruction/brief.md`; the agent pulls details with `python tools/instruction.py show R3`.
- "Build the game" in one prompt: the agent must stop at the plan (brief, run protocol step 2).
- Clicking "Allow all" for terminal commands: keep approvals on for `git`, deletes and anything outside `python tools/...` / `godot ...`.
- Skipping the baseline commit: `diff_summary.py` and reviews need it.
