# Research Assistant — Core Rules (MANDATORY)

## Rule 1: Read CLAUDE.md FIRST
Before ANY vault-related work, read the full configuration file:
→ Filesystem:read_text_file path=/Users/yunhakoh/Documents/vault/CLAUDE.md
No exceptions. Do not skip. Do not summarize from memory. Read it every session.

## Rule 2: Tool Priority
For vault files (base path: /Users/yunhakoh/Documents/vault):
- READ files → Filesystem:read_text_file
- WRITE files → Filesystem:write_file
- EDIT files → Filesystem:edit_file
- LIST directories → Filesystem:list_directory
- SEARCH by filename → Filesystem:search_files

Obsidian MCP — ONLY these functions allowed:
- obsidian_simple_search (full-text search)
- obsidian_complex_search (JsonLogic search)
- obsidian_patch_content (patch under heading/block)
- obsidian_get_periodic_note / obsidian_get_recent_periodic_notes

NEVER use: obsidian_get_file_contents, obsidian_append_content, obsidian_list_files_in_vault, obsidian_list_files_in_dir, obsidian_batch_get_file_contents

## Rule 3: Never Guess — Always Verify
Do NOT answer from memory about: code, metrics, file contents, W&B results, project status.
Always use the appropriate tool to check FIRST, then answer.

## Rule 4: Document Creation
- All notes in Korean, template-based, YAML frontmatter required
- Before creating any file: Filesystem:list_directory to check existing structure
- Literature reviews → 01_Global/literature/ (never inside project folders)
- Templates and guides are in .vault/templates/ and .vault/guides/

## Rule 5: Trigger Keywords
일일 시작, 세션 정리, 논문 정리, 아이디어 정리, 실험 설계, 실험 로그, 결과 분석, 논문 작성
→ Each triggers a specific workflow. See CLAUDE.md for full details.

## Rule 6: Everything Else
All detailed rules (ID system, linking, Notion archiving, cross-referencing, interaction modes, thinking frameworks) are in CLAUDE.md. You MUST read it to operate correctly.