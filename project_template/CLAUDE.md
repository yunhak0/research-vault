# CLAUDE.md — Coding Agent Configuration

> This file governs **code-level work** (implementation, debugging, testing).
> For **research documentation rules** (vault notes, templates, Obsidian workflows), see the vault-level config:
> `{VAULT_PATH}/CLAUDE.md` (where this project is symlinked from)

---

## Bootstrap

> **첫 세션 자동 설정**: 이 파일에 `[TODO]` 마커가 남아 있으면, 아래 절차를 실행하라.
>
> 1. 이 repo의 `pyproject.toml`, `Makefile`, `scripts/`, `configs/` 등을 읽는다
> 2. 각 `[TODO]` 항목을 코드베이스에서 추출한 실제 값으로 채운다
> 3. 추출할 수 없는 항목은 사용자에게 질문한다
> 4. 완료 후 이 Bootstrap 섹션 전체를 삭제한다
> 5. 변경 사항을 커밋한다: `git commit -m "chore: bootstrap CLAUDE.md"`
>
> **원칙**: 코드에서 읽을 수 있는 정보는 여기에 중복하지 않는다.
> 이 파일에는 코드에서 유추할 수 없는 것만 남긴다.

---

## Workflow Orchestration

### 1. Plan Node Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `agent-docs/tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes — don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests — then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

---

## Task Management

1. **Plan First**: Write plan to `agent-docs/tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `agent-docs/tasks/todo.md`
6. **Capture Lessons**: Update `agent-docs/tasks/lessons.md` after corrections

### Prompt-driven Workflow

Claude Desktop에서 연구·설계를 마친 후, 구현 프롬프트를 작성해 서버 Claude Code에 넘긴다.

**세션 시작 시**:
1. `agent-docs/tasks/todo.md`를 읽는다
2. `Pending` 상태의 PROMPT가 있으면 해당 파일을 읽는다
3. 프롬프트의 배경·요구사항·검증 기준에 따라 구현한다
4. 검증 기준 통과 시 프롬프트의 `status`를 `Done`으로 변경한다
5. `todo.md`에서 해당 항목을 `[x]`로 마킹한다

**프롬프트 위치**:
- 프로젝트 전체 대상: `agent-docs/tasks/prompts/PROMPT-###_{slug}.md`
- 특정 문제 대상: `agent-docs/obsidian/problems/PRB-###/prompts/PROMPT-###_{slug}.md`

---

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.

---

## Session Persistence (Hooks)

This project includes Claude Code hooks (`.claude/hooks.json` + `.claude/hooks/`) that automate context management across sessions.

**What happens automatically:**
- **Session start**: Previous session summary is loaded into your context (tasks done, files modified, tools used)
- **Session end**: Current session is parsed from JSONL transcript and saved to `~/.claude/sessions/`
- **Pre-compact**: A `[Compaction occurred at HH:MM]` marker is appended to your session file
- **Every 50 Edit/Write calls**: A stderr nudge suggests considering `/compact`

**Token optimization** (`.claude/settings.json`):
- Default model: Sonnet (override with `--model opus` when needed)
- Auto-compact at 50% context (not the default 95%)
- Thinking tokens capped at 10,000

**Use Opus Thinking**

**Relationship with `tasks/`:**
- Session hooks = automatic, ephemeral ("what happened last time")
- `agent-docs/tasks/todo.md` = manual, persistent (current plan + checklist)
- `agent-docs/tasks/lessons.md` = manual, cumulative (project-wide lessons database)

**Customization:**
- Change compact threshold: edit `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` in `.claude/settings.json`
- Change nudge interval: set env var `COMPACT_THRESHOLD=100`
- Disable any hook: remove it from `.claude/hooks.json`

---

## analyze/ Convention

`agent-docs/analyze/` 디렉토리는 분석 스크립트·결과·리포트를 보관한다. agent-docs/의 INV/RES 문서와 양방향 참조를 유지한다.

### 명명 규칙

```
agent-docs/analyze/{prb번호}_{용도}.py
```

예시:
- `agent-docs/analyze/prb001_metric_check.py` — PRB-001 메트릭 진단
- `agent-docs/analyze/prb001_correlation_analysis.py` — PRB-001 상관관계 분석
- `agent-docs/analyze/prb002_loss_curve.py` — PRB-002 loss 시각화

### Docstring 규칙

모든 분석 스크립트 상단에 관련 문서 ID와 W&B 경로를 기록한다:

```python
"""
PRB-001 메트릭 진단 스크립트

관련 문서: INV-001 (탐구), RES-001 (해결)
W&B: wandb.ai/xxx/yyy
"""
```

### 재현성 원칙

- 스크립트 실행만으로 결과를 재현할 수 있어야 한다
- 하드코딩된 경로 대신 argparse 또는 config 파일 사용
- RES 문서의 핵심 수치와 스크립트의 대응 관계가 명확해야 한다
- INV에서 만든 스크립트가 RES에서도 유효하면 그대로 계승 (docstring에 RES ID 추가)

---

## Project Overview

**Project**: {{PROJECT_ID}}_{{PROJECT_NAME}}
**Description**: {{PROJECT_DESCRIPTION}}
**Current phase**: [TODO: 현재 활발히 작업 중인 단계. 예: "Stage 1 AE training"]
**PRD**: [TODO: PRD 경로가 있으면 기입. 없으면 이 줄 삭제]

---

## Build & Runtime

[TODO: pyproject.toml, Makefile, scripts/ 에서 추출]

<!-- 코드에서 유추할 수 없는 것만 남긴다. 예시:
- uv 를 쓰는데 캐시 경로가 특수한 경우: UV_CACHE_DIR=/scratch/.../uv-cache
- 서버별로 다른 실행 방법이 있는 경우
- 빌드 시 알려진 함정(gotcha)이 있는 경우
-->

---

## Metrics Convention

[TODO: W&B 또는 stdout에 로깅되는 핵심 메트릭명. pl_modules.py 등에서 추출]

<!-- 에이전트가 메트릭명을 잘못 만들어내는 것을 방지하는 용도.
예:
| Category | Key | Source |
|----------|-----|--------|
| Cell correlation | `val/recon_pearson` | `pl_modules.py:L120` |
-->

---

## Execution Environment

[TODO: 학습/평가에 사용하는 서버 정보]

<!-- 예:
| Server | GPU | Purpose |
|--------|-----|---------|
| kfold | B200 | Primary training |
-->

---

## Known Issues

<!-- 에이전트가 반복적으로 걸려 넘어지는 broken/stale 파일을 기록한다.
이것이 컨텍스트 파일에서 검증된 두 가지 효과 중 하나이다. -->

| File | Issue | Status |
|------|-------|--------|
| | | |

---

## Last Updated

- Date: {{CREATED_DATE}}
