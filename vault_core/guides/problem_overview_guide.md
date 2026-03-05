---
guide_for: problem_overview
version: 1.0
last_updated: 2026-02-12
---

# Problem Overview 작성 가이드

## 1. 목적

하나의 연구 문제(Problem)를 추적하는 **허브 문서**.
문제 정의, 시도한 접근, 핵심 발견, 최종 결론을 한 곳에서 조망한다.
해당 문제 폴더(`PRB-###_xxx/`) 아래의 모든 하위 문서(INV, LRN, RES)를 연결하는 인덱스 역할.

## 2. ID 규칙

```
PRB-[NNN]

예시: PRB-001
```

**파일명은 항상 `_overview.md`**. PRB ID는 폴더명에 표현된다.

## 3. 파일 위치 및 폴더 구조

```
[PROJECT]/problems/PRB-[NNN]_[problem_name]/
├── _overview.md          ← 이 문서
├── investigating/        ← 진행 중인 조사/실험
│   └── INV-###_xxx.md
├── learned/              ← 실패한 시도, 기각된 가설
│   └── LRN-###_xxx.md
├── resolved/             ← 성공한 해결책
│   └── RES-###_xxx.md
└── prompts/              ← 코딩 프롬프트
    └── *.md
```

새 PRB 생성 시 위 폴더 구조를 함께 생성한다.

## 4. 섹션별 작성 규칙

### 4.1 결론

**위치**: 문서 상단, 즉시 결론을 확인할 수 있도록.

- `Investigating` 상태: "미해결. 현재 [INV-###]을 통해 조사 중."
- `Resolved` 상태: 최종 해결책 1-2문장 요약.

### 4.2 핵심 발견

**형식**: 번호 매긴 리스트, 각 항목에 한 줄 설명 + 하위 문서 링크.
시간순이 아닌 **중요도순**으로 정렬.

**좋은 예**:
```
1. **Capacity reduction이 핵심이었다** — 모델 크기를 scLDM에 맞춰 줄이자 
   Pearson 0.747 달성 → [[RES-001_capacity_reduction_ccc]]
2. **Pearson aux loss는 역효과** — Goodhart's Law로 양쪽 다 악화 
   → [[LRN-002_goodharts_law_pearson_aux]]
```

### 4.3 현황

- `Investigating`: 현재 무엇을 시도하고 있는지, 다음 단계는 무엇인지
- `Resolved`: 해결 과정 타임라인 요약

### 4.4 Iteration History

문제 해결 과정의 **iteration cycle**을 시간순으로 추적하는 테이블.
"가설 → 실험 → 메트릭 변화 → 판정 → 다음 가설"의 흐름을 한 눈에 볼 수 있어야 한다.

**컨럼 작성 규칙**:
- **#**: iteration 번호 (1, 2, 3...). 시간순으로 증가
- **날짜**: 시도 날짜 또는 기간
- **가설/접근**: 무엇을 시도했는지 한 문장으로
- **핵심 메트릭 변화**: 정량적 결과 (예: "Pearson 0.65 → 0.74", "loss diverged")
- **판정**: ✅ 성공 / ❌ 실패 / ➖ 부분 성공
- **교훈**: 이 시도에서 배운 핵심 인사이트 (한 문장)
- **문서**: 해당 INV/LRN/RES 링크

**예시**:
```
| # | 날짜 | 가설/접근 | 핵심 메트릭 변화 | 판정 | 교훈 | 문서 |
|---|------|------------|-----------------|------|------|------|
| 1 | 02-10 | Pearson aux loss 추가 | Pearson 0.72→0.68, CCC 0.41→0.38 | ❌ | Goodhart's Law—직접 최적화하면 양쪽 악화 | [[LRN-002]] |
| 2 | 02-12 | 모델 capacity를 scLDM 수준으로 축소 | Pearson 0.65→0.747 | ✅ | 모델 크기가 핵심 병목이었음 | [[RES-001]] |
| 3 | 02-15 | Residual context separation | Pearson 0.747→0.78 (preliminary) | ➖ | 방향성 확인, 훈련 안정성 추가 검증 필요 | [[INV-003]] |
```

**업데이트 시점**: 새 INV/LRN/RES가 생성될 때마다 행을 추가한다.

### 4.5 타임라인

**형식**: 날짜 | 사건 테이블.
문제 발견부터 해결(또는 현재)까지의 주요 이벤트.

## 5. Status 정의

| 상태 | 정의 |
|------|------|
| Investigating | 문제 미해결, 조사/실험 진행 중 |
| Resolved | 문제 해결됨 |

## 6. _overview.md 업데이트 규칙

- **새 INV/LRN/RES 생성 시**: "핵심 발견"과 "Iteration History"에 반영
- **INV 완료 시**: 결과에 따라 LRN 또는 RES 생성, _overview 업데이트
- **문제 해결 시**: status → Resolved, "결론" 섹션 작성

## 7. Notion 아카이빙

- **아카이빙 대상**: `status: Resolved` (또는 장기 Investigating도 중간 기록용)
- **Type**: PRB
- **본문**: _overview.md의 핵심 내용을 요약 (하위 문서는 참조만)
- 하위 INV/LRN/RES는 개별 아카이빙하지 않음 — _overview가 대표

## 8. 새 문제 등록 절차

1. `problems/` 아래 새 폴더 생성: `PRB-[NNN]_[name]/`
2. 하위 폴더 생성: `investigating/`, `learned/`, `resolved/`, `prompts/`
3. `_overview.md` 생성 (이 템플릿 사용)
4. `00_project_index.md`의 problems 섹션에 추가