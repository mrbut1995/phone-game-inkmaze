# Instruction: Planning (gameplay -> `plan/` sessions)

**Version 1.2.** Turns `instruction/<game_name>_gameplay.md` into a list of **bounded work sessions** stored in `plan/`, so agents do not run continuously and burn resources.
Engineering rules: `instruction_writing_project.md`. Tools: `instruction_tools.md` (`tools/plan.py`).

---

## 0. Principles (MUST)

1. **Plan once, execute in small sessions.** One agent run = **one session**. After the session: report and **STOP**. A human reviews before the next session.
2. **Each session is self-contained:** it lists the *only* files to read (context pack), the contracts it provides/expects, its tasks, its tests and its Definition of Done. The agent never needs to explore or re-read the whole gameplay file.
3. **Vertical slices:** every session ends with a runnable game and a green test suite, never a half-wired feature.
4. **The plan is the source of "what next".** Agents use `python tools/plan.py next`, not their own judgement.
5. **Plan *what* and *where*, not code.** Contracts (class names, signals, function signatures) yes; implementation no.

## 1. Inputs and outputs

| | Path |
|---|---|
| Input (required, filled) | `instruction/<game_name>_gameplay.md` (sections 4-9 and 15 must not be `TBD`; otherwise write the question in `plan/00_overview.md` > Risks and ask the human first) |
| Output | `plan/00_overview.md`, `plan/session_NN_<slug>.md`, optional `plan/changes.md` |

Naming: plan sessions are **`S01`, `S02`...**; external-AI helper sessions are `ai_helper/session_1`... (different namespace, see `ai_helper/instruction_ai_helper.md`).

## 1b. Whole-game requests (MUST)

A request like "build the game from the gameplay file" **starts here**, not with code. If `plan/` is missing: run `python tools/gameplay_to_plan.py` (creates S01 walking skeleton + one session per milestone with every criterion mapped to a task), refine it (section 2 steps 2-7), `python tools/plan.py check`, report, **STOP**. Building everything in one run skips the review gate, hides scope and makes the final report unverifiable (observed in the *Echoes of Aeloria* build: no plan, 28 rooms + 5 enemies + boss in one pass). `run_checks.py` prints `[WARN] plan` when a gameplay file exists but `plan/` does not.

## 2. Planning procedure (the agent does ONLY this, no implementation)

1. Read `instruction_writing_project.md` (structure, rules) and the gameplay file once.
2. **Inventory** from gameplay sections 4-14: scenes by kind (screen/object/component/variant), scripts, Definitions (`.tres`), placeholder visuals, animations, EventBus signals, tests. Print sections with `python tools/plan.py spec <n>` if needed.
3. **Dependency graph:** foundation -> core loop -> entities -> interactions -> UI -> content -> polish/art swap.
4. **Slice** into sessions with the rules in section 3.
5. Start from `python tools/gameplay_to_plan.py` (or `plan.py init` + `plan.py new <slug> "<Title>"`); fill every section: real file paths in `files:`, Contracts, Budget.
6. **Cover every acceptance criterion:** each criterion id (`M1-1`...) in at least one task (`[M1-1]`) and one test. `python tools/plan.py check` MUST pass (it reports uncovered criteria).
7. Fill overview: order and rationale, risks, assumptions. `python tools/plan.py sync`.
8. **STOP.** Report: sessions table, risks, open questions. Do not start building.

## 3. Slicing rules (MUST)

| Rule | Detail |
|---|---|
| Session 1 = **walking skeleton** | autoloads, base scenes, boot -> menu -> game, test runner green, `run_checks` green |
| Order by **dependency, then risk** | uncertain/risky mechanics early; polish, audio, real art last (placeholders first) |
| Size limits | **<= 8 tasks**, **<= 12 files in the context pack**, a task = one cohesive change of <= 3 files + its test. Bigger -> split the session |
| Tests live with the code | tests are tasks in the **same** session as the behaviour they cover |
| One theme per session | e.g. "Command system", "Perception + AI", "Inventory UI". Not "misc" |
| Interfaces first | if session B uses session A's API, A's **Contracts** section states it, so B does not re-read A's code |
| Creative/UI-heavy work | MAY be `Executor: web-ai` (done through `ai_helper`), see section 7 |
| Re-verification | a session finishing as `unverified` blocks its dependents until verified |

## 4. Session file format (strict; `plan.py check` enforces it)

File `plan/session_NN_<slug>.md`:

```markdown
# S03 - Command system
- Status: planned            (planned | in_progress | done | unverified | blocked)
- Executor: agent            (agent | web-ai)
- Depends on: S01, S02       (or none)
- Gameplay refs: 5.1, 5.2, M2-1, M2-2
- Budget: tasks=6 files=10 tokens=60k

## Goal
One or two sentences: what is playable/testable when this is done.

## Context pack
The ONLY files to read (path - why). Prefer outlines: `script_index.py --file <path>`. Files created by earlier sessions exist by then; files created here are marked (new).
- scripts/objects/world/Actor.gd - actor API
- scripts/commands/ActorCommand.gd (new) - base class created in T01

## Contracts
Provides: `class CommandHandler`: `handle(cmd) -> bool`, signals `command_started`, `command_finished`.
Expects: `Actor.model: ActorModel` (S02), `EventBus.actor_attacked` (S02).

## Tasks
- [ ] S03-T01 [M2-1] ActorCommand + MoveCommand (files: scripts/commands/ActorCommand.gd, MoveCommand.gd)
- [ ] S03-T02 [M2-1] CommandHandler priority/queue/cooldown (files: scripts/components/actor/CommandHandler.gd)
- [ ] S03-T03 [M2-2] Unit tests for the handler (files: tests/unit/components/actor/test_command_handler.gd)

## Tests
- tests/unit/components/actor/test_command_handler.gd: priority interrupt (M2-1), cooldown (M2-2)

## Definition of Done
- [ ] All tasks ticked
- [ ] Tests above written; `python tools/run_checks.py` green (or session marked unverified)
- [ ] Handoff filled

## Handoff
Decisions, deviations, open issues the next session must know.

## Log
```

Rules for each field:
- **Task line:** `- [ ] S03-T02 [criteria ids] outcome (files: a, b)`. Ids unique and prefixed with the session id. States: `[ ]` open, `[x]` done, `[!]` blocked.
- **Context pack** is a *budget*: if the agent needs more files, the plan was wrong (record in Handoff, or `plan/changes.md`).
- **Tests** section is mandatory for `agent` sessions.
- Never leave template comments or placeholder lines.

## 5. Execution protocol (what a future agent does for ONE session)

1. `python tools/plan.py next` -> read **only** its output + the Context pack (+ `instruction_writing_project.md` once). Print gameplay detail with `plan.py spec <section>` only when needed.
2. Do the open tasks in order, using the tools (`instruction_tools.md`). Write the test with the code.
3. While iterating: `python tools/run_checks.py --fast`. Before finishing: `python tools/run_checks.py` (full).
4. `python tools/plan.py done <task ids>` as each task completes.
5. Fill **Handoff**.
6. `python tools/plan.py finish S03` (runs the full gate; if Godot is unavailable `--unverified` records it honestly).
7. **STOP.** Final report in the format of `instruction_writing_project.md` section 9 plus: session id, tasks done, next session id from `plan.py status`. Do **not** begin the next session.

If blocked: `python tools/plan.py block S03-T02 "reason"` and stop with a question.

## 6. Changing the plan

- Allowed triggers: blocked task, wrong estimate, new gameplay decision, failed assumption.
- **Never rewrite a `done` session.** Fix forward with a new session (next number) or edit only `planned` sessions.
- Gameplay change (criteria added/removed) -> edit the gameplay file **first** (human approval), then re-plan.
- Log every change: one line in `plan/00_overview.md` > Changes, details in `plan/changes.md` (date, what, why).
- Always re-run `python tools/plan.py check` and `plan.py sync`.

## 7. `web-ai` sessions

For tasks better done by an external AI website (screen redesign, long UI scenes, creative content):
1. Mark the session `Executor: web-ai`. Its Handoff names the `ai_helper` session number when created.
2. The agent follows `ai_helper/instruction_ai_helper.md` (`--plan S05`) to prepare the prompt, then **stops** and waits for the human.
3. After the human saves `response.md`: `ai_helper.py apply` -> import -> `run_checks.py` -> tick tasks -> `plan.py finish`.

## 8. Resource economy

- **A session is a chat.** Start every session in a **new chat**; state lives in `plan/` (Context pack, Contracts, the previous Handoff printed by `plan.py next`). Measured on DuckPond: five sessions in one chat made the next session send ~80k tokens of history at each of its 188 steps (12.8M input tokens); a fresh chat starts near 25k.
- **Step budget:** `Budget: ... steps=80`. Count tool calls; past the budget write the Handoff and stop with a partial report.
- **Content is verified by a test that loads every content file** (levels, definitions, rooms) in the session that adds it, not by manually running each file; manual runs cost 40+ extra steps in S06.
- A Handoff records decisions that would otherwise be re-discovered (engine quirks, workarounds, ids) in <= 15 lines.

- Never chain sessions automatically. The stop-and-review gate is the whole point.
- Prefer `--fast` checks while iterating; the full gate once per session.
- Keep each session within its `Budget`; exceeding it twice means the session must be split in `plan/changes.md`.

## 9. Plan quality checklist

- [ ] `plan.py check` passes (sections, limits, dependencies acyclic, every criterion covered, no empty Tests).
- [ ] Session 1 is a walking skeleton; risky mechanics are early; art/polish last.
- [ ] Every session ends runnable and green; tests are in the same session as the code.
- [ ] Contracts let later sessions avoid re-reading earlier code.
- [ ] Context packs list <= 12 files each and every path exists (or is marked `(new)`).
- [ ] Overview has order, rationale, risks, assumptions.
