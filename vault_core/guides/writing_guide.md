---
guide_for: writing
version: 1.0
last_updated: 2026-02-12
---

# Writing (논문 섹션) 작성 가이드

## 1. 목적

논문의 각 섹션을 체계적으로 작성하고 관리한다.
Foundations와 Resolved 문서들을 종합하여 출판 가능한 형태로 발전시킨다.

## 2. ID 규칙

```
WRT-[NNN]

예시: WRT-001
```

논문 섹션은 frontmatter의 `section` 필드로 구분한다:
`abstract`, `introduction`, `methods`, `results`, `discussion`, `conclusion`

## 3. 파일 위치

```
[PROJECT]/docs/writing/WRT-[NNN]_[section_name].md
```

## 4. 섹션별 작성 가이드

### 4.1 Abstract

**구조** (각 1-2문장, 총 150-250 단어):
1. 배경/동기
2. 목적
3. 방법
4. 결과 (구체적 수치 포함)
5. 의의

**규칙**: 약어 풀어쓰기, 인용 없음, 미래형 불가

### 4.2 Introduction

**구조** (funnel: 일반 → 구체적):
1. Hook — 큰 그림
2. Background — 관련 연구 (2-3단락)
3. Gap — 기존 연구의 한계
4. Our Approach — 접근법 개요
5. Contributions — 구체적 기여점

### 4.3 Methods

**구조**:
1. Overview — 파이프라인 개요
2. Data — 데이터셋, 전처리, 분할
3. Model — 아키텍처 상세
4. Training — 학습 설정
5. Evaluation — 평가 프로토콜

**참조**: FND 문서들이 Methods의 핵심 소스.

### 4.4 Results

**구조**: RQ/PRB별로 섹션 구분
- 객관적 사실 위주, 해석 최소화
- Figure/Table 참조 필수
- 통계적 유의성 명시

**참조**: RES 문서들이 Results의 핵심 소스.

### 4.5 Discussion

**구조**:
1. Summary — 주요 발견
2. Interpretation — 의미, 원인
3. Comparison — 기존 연구 대비
4. Limitations — 한계 (솔직하게)
5. Future Work — 향후 방향

### 4.6 Conclusion

1-2단락, 200 단어 이내. Abstract와 표현 달리.

## 5. 버전 관리

파일명에 버전 포함하지 않음. 문서 내 버전 히스토리 테이블 사용.

## 6. Status 정의

| 상태 | 정의 |
|------|------|
| Draft | 초안 작성 중 |
| In Progress | 리뷰/수정 진행 중 |
| Completed | 제출 가능 수준 |

## 7. Notion 아카이빙

- **아카이빙 대상**: `status: Completed` (제출 버전)
- **Type**: WRT