#!/usr/bin/env python3
"""
Obsidian Vault Index 자동 업데이트 스크립트

사용법:
    python update_index.py [vault_path]

    vault_path를 지정하지 않으면 스크립트 위치 기준 상위 폴더를 vault로 간주
"""

import re
import yaml
from pathlib import Path
from datetime import datetime, timedelta


def parse_frontmatter(filepath: Path) -> dict:
    """마크다운 파일의 YAML frontmatter 파싱"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        match = re.match(r'^---\s*\n(.*?)\n---', content, re.DOTALL)
        if match:
            return yaml.safe_load(match.group(1)) or {}
    except Exception as e:
        print(f"Warning: Failed to parse {filepath}: {e}")
    return {}


def get_title_from_file(filepath: Path) -> str:
    """파일에서 제목 추출 (frontmatter의 title 또는 첫 번째 # 헤딩)"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        fm = parse_frontmatter(filepath)
        if fm.get('title'):
            return fm['title']

        match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
        if match:
            return match.group(1).strip()

        return filepath.stem
    except:
        return filepath.stem


def _wikilink(filepath: Path, vault_path: Path, title: str, in_table: bool = True) -> str:
    """Obsidian wiki-link 생성: [[file_stem]] 또는 [[file_stem\|title]]
    
    in_table=True이면 \| 이스케이프로 alias 사용.
    파일명과 제목이 같으면 alias 생략.
    """
    stem = filepath.stem
    if stem == title or not title:
        return f'[[{stem}]]'
    if in_table:
        return f'[[{stem}\|{title}]]'
    return f'[[{stem}|{title}]]'


def find_projects(vault_path: Path) -> list:
    """P로 시작하는 프로젝트 폴더 찾기"""
    projects = []
    for item in vault_path.iterdir():
        if item.is_dir() and re.match(r'^P\d{3}', item.name):
            projects.append(item)
    return sorted(projects)


def _scan_md_files(folder: Path) -> list:
    """폴더 내 .md 파일을 스캔하여 doc_info 리스트 반환"""
    docs = []
    if not folder.exists():
        return docs
    for f in folder.glob('*.md'):
        if f.name.startswith('00_') or f.name.startswith('_'):
            continue
        fm = parse_frontmatter(f)
        docs.append({
            'id': fm.get('doc_id', fm.get('id', f.stem)),
            'title': get_title_from_file(f),
            'status': fm.get('status', 'Unknown'),
            'path': f,
            'updated': fm.get('updated', ''),
        })
    return docs


def scan_project(project_path: Path) -> dict:
    """프로젝트 폴더 스캔하여 정보 수집 (problem-centric 구조)"""
    project_info = {
        'id': project_path.name.split('_')[0],
        'name': project_path.name,
        'path': project_path,
        'foundations': [],
        'problems': [],
        'engineering': [],
        'writing': [],
        'stats': {
            'total_foundations': 0,
            'total_problems': 0,
            'resolved_problems': 0,
            'investigating_problems': 0,
            'total_engineering': 0,
            'total_writing': 0,
            'total_prompts': 0,
        }
    }

    # Symlink: vault/P00X/ → repo/agent-docs/obsidian/
    # So foundations/, problems/, etc. are directly under project_path
    if not project_path.exists():
        return project_info

    project_info['foundations'] = _scan_md_files(project_path / 'foundations')

    problems_path = project_path / 'problems'
    if problems_path.exists():
        for prb_dir in sorted(problems_path.iterdir()):
            if not prb_dir.is_dir() or not re.match(r'^PRB-\d{3}', prb_dir.name):
                continue

            overview_path = prb_dir / '_overview.md'
            overview_fm = parse_frontmatter(overview_path) if overview_path.exists() else {}

            prb_info = {
                'id': overview_fm.get('doc_id', prb_dir.name.split('_')[0]),
                'name': prb_dir.name,
                'title': get_title_from_file(overview_path) if overview_path.exists() else prb_dir.name,
                'status': overview_fm.get('status', 'Unknown'),
                'path': prb_dir,
                'investigating': _scan_md_files(prb_dir / 'investigating'),
                'learned': _scan_md_files(prb_dir / 'learned'),
                'resolved': _scan_md_files(prb_dir / 'resolved'),
                'prompts': _scan_md_files(prb_dir / 'prompts'),
            }
            project_info['problems'].append(prb_info)

    # ENG는 단일 문서만 지원 (폴더 구조 불가 — 복잡하면 PRB로 재분류)
    project_info['engineering'] = _scan_md_files(project_path / 'engineering')

    project_info['writing'] = _scan_md_files(project_path / 'writing')

    project_info['stats']['total_foundations'] = len(project_info['foundations'])
    project_info['stats']['total_problems'] = len(project_info['problems'])
    project_info['stats']['resolved_problems'] = sum(
        1 for p in project_info['problems'] if p['status'].lower() == 'resolved'
    )
    project_info['stats']['investigating_problems'] = sum(
        1 for p in project_info['problems'] if p['status'].lower() == 'investigating'
    )
    project_info['stats']['total_engineering'] = len(project_info['engineering'])
    project_info['stats']['total_writing'] = len(project_info['writing'])
    project_info['stats']['total_prompts'] = sum(
        len(p['prompts']) for p in project_info['problems']
    )

    return project_info


def get_project_status(project_info: dict) -> str:
    """프로젝트 상태 결정"""
    index_path = project_info['path'] / '00_project_index.md'
    if index_path.exists():
        fm = parse_frontmatter(index_path)
        if fm.get('status'):
            return fm['status']

    stats = project_info['stats']
    if stats['total_problems'] == 0 and stats['total_foundations'] == 0:
        return 'Planning'
    elif stats['investigating_problems'] > 0:
        return 'Active'
    elif stats['resolved_problems'] == stats['total_problems'] and stats['total_problems'] > 0:
        return 'Completed'
    return 'Active'


def get_recent_documents(vault_path: Path, days: int = 7) -> list:
    """최근 N일 내 업데이트된 문서 찾기"""
    recent = []
    cutoff = datetime.now() - timedelta(days=days)

    for md_file in vault_path.rglob('*.md'):
        rel = str(md_file.relative_to(vault_path))
        if '.vault' in rel or 'ZZ_Temp' in rel:
            continue

        fm = parse_frontmatter(md_file)
        updated = fm.get('updated', '')

        if updated:
            try:
                updated_date = datetime.strptime(str(updated), '%Y-%m-%d')
                if updated_date >= cutoff:
                    recent.append({
                        'date': updated,
                        'id': fm.get('doc_id', fm.get('id', md_file.stem)),
                        'title': get_title_from_file(md_file),
                        'type': detect_doc_type(md_file),
                        'status': fm.get('status', ''),
                        'path': md_file,
                    })
            except:
                pass

    return sorted(recent, key=lambda x: x['date'], reverse=True)[:20]


def scan_global_literature(vault_path: Path) -> list:
    """01_Global/literature/ 폴더에서 전역 문헌 리뷰 스캔"""
    literature = []
    lit_path = vault_path / '01_Global' / 'literature'
    if lit_path.exists():
        for f in lit_path.glob('*.md'):
            if f.stem == 'literature_review_summary':
                continue
            fm = parse_frontmatter(f)
            doc_info = {
                'id': fm.get('doc_id', fm.get('id', f.stem)),
                'title': get_title_from_file(f),
                'status': fm.get('status', 'Unknown'),
                'path': f,
                'updated': fm.get('updated', ''),
            }
            literature.append(doc_info)
    return sorted(literature, key=lambda x: x['id'])


def detect_doc_type(filepath: Path) -> str:
    """파일 경로/이름으로 문서 유형 추론"""
    name = filepath.stem.upper()
    parent = filepath.parent.name
    grandparent = filepath.parent.parent.name if filepath.parent.parent else ''

    if 'DAILY' in name:
        return 'Daily'
    elif parent == 'literature' or name.startswith('LIT-'):
        return 'Literature'
    elif parent == 'foundations' or name.startswith('FND-'):
        return 'Foundation'
    elif parent == 'investigating' or name.startswith('INV-'):
        return 'Investigating'
    elif parent == 'learned' or name.startswith('LRN-'):
        return 'Learned'
    elif parent == 'resolved' or name.startswith('RES-'):
        return 'Resolved'
    elif parent == 'engineering' or name.startswith('ENG-'):
        return 'Engineering'
    elif parent == 'writing' or name.startswith('WRT-'):
        return 'Writing'
    elif parent == 'prompts':
        return 'Prompt'
    elif name == '_OVERVIEW' or (grandparent == 'problems' and name == '_OVERVIEW'):
        return 'Problem Overview'
    elif parent.startswith('PRB-'):
        return 'Problem'
    return 'Other'


def generate_master_index(vault_path: Path, projects: list, global_literature: list = None) -> str:
    """master_index.md 내용 생성"""
    if global_literature is None:
        global_literature = []
    today = datetime.now().strftime('%Y-%m-%d')

    content = f"""---
template_type: master_index
created: {today}
updated: {today}
auto_update: true
---

# Master Index

## 프로젝트 목록

| Project ID | 프로젝트명 | 상태 | 생성일 | 문제 수 | 해결 | 진행 중 |
|------------|-----------|------|--------|---------|------|---------|
"""

    total_projects = len(projects)
    active_projects = 0
    completed_projects = 0
    total_problems = 0
    resolved_problems = 0

    for p in projects:
        status = get_project_status(p)
        if status == 'Active':
            active_projects += 1
        elif status == 'Completed':
            completed_projects += 1

        total_problems += p['stats']['total_problems']
        resolved_problems += p['stats']['resolved_problems']

        index_path = p['path'] / '00_project_index.md'
        created = ''
        if index_path.exists():
            fm = parse_frontmatter(index_path)
            created = fm.get('created', '')

        content += f"| {p['id']} | [[{p['name']}/00_project_index\|{p['name']}]] | {status} | {created} | {p['stats']['total_problems']} | {p['stats']['resolved_problems']} | {p['stats']['investigating_problems']} |\n"

    if not projects:
        content += "| | | | | | | |\n"

    recent_docs = get_recent_documents(vault_path)

    content += """
## 최근 활동

*최근 7일 내 업데이트된 문서*

| 날짜 | 문서 ID | 문서명 | 유형 | 상태 변경 |
|------|---------|--------|------|----------|
"""

    for doc in recent_docs[:10]:
        link = _wikilink(doc['path'], vault_path, doc['title'])
        content += f"| {doc['date']} | {doc['id']} | {link} | {doc['type']} | {doc['status']} |\n"

    if not recent_docs:
        content += "| | | | | |\n"

    content += """
## 문헌 리뷰 (Global)

| ID | 제목 | 상태 | 업데이트 |
|----|------|------|---------|
"""

    for lit in global_literature:
        link = _wikilink(lit['path'], vault_path, lit['title'])
        content += f"| {lit['id']} | {link} | {lit['status']} | {lit['updated']} |\n"

    if not global_literature:
        content += "| | | | |\n"

    content += f"""
## 통계

| 항목 | 수 |
|------|---|
| 전체 프로젝트 | {total_projects} |
| 진행 중 | {active_projects} |
| 완료 | {completed_projects} |
| 전체 문제 | {total_problems} |
| 해결 문제 | {resolved_problems} |
| 문헌 리뷰 | {len(global_literature)} |
"""

    return content


def generate_project_index(project_info: dict, vault_path: Path) -> str:
    """00_project_index.md 내용 생성 (problem-centric 구조)"""
    today = datetime.now().strftime('%Y-%m-%d')
    p = project_info

    index_path = p['path'] / '00_project_index.md'
    existing_fm = {}
    if index_path.exists():
        existing_fm = parse_frontmatter(index_path)

    created = existing_fm.get('created', today)
    project_name = existing_fm.get('project_name', p['name'])
    goal = existing_fm.get('goal', '')
    status = existing_fm.get('status', get_project_status(p))

    content = f"""---
template_type: project_index
created: {created}
updated: {today}
auto_update: true
project_name: {project_name}
status: {status}
goal: {goal}
---

# {p['id']} Project Index

## 프로젝트 정보

| 항목 | 내용 |
|------|------|
| 프로젝트 ID | {p['id']} |
| 프로젝트명 | {project_name} |
| 시작일 | {created} |
| 상태 | {status} |
| 목표 | {goal} |

## Foundations (기반 결정)

| ID | 제목 | 상태 | 업데이트 |
|----|------|------|---------|
"""

    for fnd in p['foundations']:
        link = _wikilink(fnd['path'], vault_path, fnd['title'])
        content += f"| {fnd['id']} | {link} | {fnd['status']} | {fnd['updated']} |\n"

    if not p['foundations']:
        content += "| | | | |\n"

    content += """
## Problems (연구 문제)

| ID | 문제명 | 상태 | INV | LRN | RES | PRM |
|----|--------|------|-----|-----|-----|-----|
"""

    for prb in p['problems']:
        n_inv = len(prb['investigating'])
        n_lrn = len(prb['learned'])
        n_res = len(prb['resolved'])
        n_prm = len(prb['prompts'])
        overview_path = prb['path'] / '_overview.md'
        link = _wikilink(overview_path, vault_path, prb['title'])
        content += f"| {prb['id']} | {link} | {prb['status']} | {n_inv} | {n_lrn} | {n_res} | {n_prm} |\n"

    if not p['problems']:
        content += "| | | | | | | |\n"

    for prb in p['problems']:
        content += f"\n### {prb['id']}: {prb['title']}\n"

        if prb['investigating']:
            content += "\n**Investigating:**\n\n| ID | 제목 | 상태 |\n|----|------|------|\n"
            for doc in prb['investigating']:
                link = _wikilink(doc['path'], vault_path, doc['title'])
                content += f"| {doc['id']} | {link} | {doc['status']} |\n"

        if prb['learned']:
            content += "\n**Learned:**\n\n| ID | 제목 | 상태 |\n|----|------|------|\n"
            for doc in prb['learned']:
                link = _wikilink(doc['path'], vault_path, doc['title'])
                content += f"| {doc['id']} | {link} | {doc['status']} |\n"

        if prb['resolved']:
            content += "\n**Resolved:**\n\n| ID | 제목 | 상태 |\n|----|------|------|\n"
            for doc in prb['resolved']:
                link = _wikilink(doc['path'], vault_path, doc['title'])
                content += f"| {doc['id']} | {link} | {doc['status']} |\n"

        if prb['prompts']:
            content += "\n**Prompts:**\n\n| 제목 | 상태 | 업데이트 |\n|------|------|----------|\n"
            for doc in prb['prompts']:
                link = _wikilink(doc['path'], vault_path, doc['title'])
                content += f"| {link} | {doc['status']} | {doc['updated']} |\n"

    content += """
## Engineering (엔지니어링)

| ID | 제목 | 상태 | 업데이트 |
|----|------|------|---------|
"""

    for eng in p['engineering']:
        link = _wikilink(eng['path'], vault_path, eng['title'])
        content += f"| {eng['id']} | {link} | {eng['status']} | {eng['updated']} |\n"

    if not p['engineering']:
        content += "| | | | |\n"

    content += """
## Writing (논문 작성)

| ID | 제목 | 상태 | 업데이트 |
|----|------|------|---------|
"""

    for wrt in p['writing']:
        link = _wikilink(wrt['path'], vault_path, wrt['title'])
        content += f"| {wrt['id']} | {link} | {wrt['status']} | {wrt['updated']} |\n"

    if not p['writing']:
        content += "| | | | |\n"

    stats = p['stats']
    content += f"""
## 문서 현황

| 영역 | 문서 수 |
|------|--------|
| Foundations | {stats['total_foundations']} |
| Problems | {stats['total_problems']} (해결: {stats['resolved_problems']}, 진행: {stats['investigating_problems']}) |
| Engineering | {stats['total_engineering']} |
| Writing | {stats['total_writing']} |
| Prompts | {stats['total_prompts']} |
"""

    content += """
## 타임라인

| 날짜 | 마일스톤 | 비고 |
|------|---------|------|
"""

    content += f"| {created} | 프로젝트 시작 | |\n"

    return content


def update_vault_indices(vault_path: Path):
    """Vault의 모든 인덱스 업데이트"""
    print(f"Scanning vault: {vault_path}")

    projects_raw = find_projects(vault_path)
    print(f"Found {len(projects_raw)} projects")

    projects = []
    for proj_path in projects_raw:
        print(f"  Scanning project: {proj_path.name}")
        project_info = scan_project(proj_path)
        projects.append(project_info)

    global_literature = scan_global_literature(vault_path)
    print(f"Found {len(global_literature)} global literature reviews")

    master_content = generate_master_index(vault_path, projects, global_literature)
    master_path = vault_path / '00_master_index.md'
    with open(master_path, 'w', encoding='utf-8') as f:
        f.write(master_content)
    print(f"Updated: {master_path}")

    for p in projects:
        project_content = generate_project_index(p, vault_path)
        project_index_path = p['path'] / '00_project_index.md'
        project_index_path.parent.mkdir(parents=True, exist_ok=True)
        with open(project_index_path, 'w', encoding='utf-8') as f:
            f.write(project_content)
        print(f"Updated: {project_index_path}")

    print("\nIndex update completed!")


def main():
    import sys

    if len(sys.argv) > 1:
        vault_path = Path(sys.argv[1])
    else:
        # 스크립트 위치 기준: .vault/scripts/ → vault root
        vault_path = Path(__file__).parent.parent.parent

    if not vault_path.exists():
        print(f"Error: Vault path does not exist: {vault_path}")
        sys.exit(1)

    update_vault_indices(vault_path)


if __name__ == '__main__':
    main()
