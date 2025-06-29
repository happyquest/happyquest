# HappyQuest Project - Claude Code Context

## Project Overview
システム構築に必要な知識をスクレイピング収集し、RAG・FTコーパスに加工。マルチエージェントで開発手法を検討し、エラー・ログ解析による学習データ化、オープンソースDoxygenドキュメント活用でMLサイクル最適化を行う。

## Development Environment
- **OS**: Windows11 WSL2 Ubuntu24.04環境
- **User**: nanashi7777
- **Project Directory**: /home/nanashi7777/happyquest/
- **Current Branch**: feature/clean-integration
- **Python**: 3.12.9
- **Node.js**: 23.8.0
- **Installed Tools**: GitHub CLI, Homebrew, Docker CE, pyenv, nvm, uv, SSH

## Project Structure
```
/home/nanashi7777/happyquest/
├── README.md (merge conflict exists)
├── PROJECT_RULES.md (comprehensive project rules)
├── docs/ (documentation)
├── src/ (source code)
├── tests/ (test files)
├── infrastructure/ (infrastructure config)
├── scripts/ (automation scripts)
├── 作業報告書/ (work reports)
├── トラブル事例/ (trouble cases)
└── アーカイブ/ (archives)
```

## Required Documentation (Missing)
Based on PROJECT_RULES.md, these files need to be created:
1. SRS.md - システム要件仕様書
2. ARCHITECTURE.md - システムアーキテクチャ
3. TEST_POLICY.md - テスト方針書
4. API_SPEC.md - API仕様書

## Development Workflow
- **4-Phase Management**: 調査・情報収集 → 設計・計画 → 実装・テスト → 評価・改善提案
- **GitHub PR-based development**: Issue-driven development required
- **TDD Required**: Test coverage >80%
- **Quality Standards**: Google coding standards compliance

## MCP Server Configuration
- **Docker MCP Tools**: Browser automation, screenshot capture, web operations
- **GitHub MCP**: Repository operations, issue management
- **HashiCorp Terraform MCP**: Google Cloud resource management
- **Database MCP**: DB operations, schema management

## Testing Strategy
- **Primary**: MCP Browser Tools (基本ナビゲーション・要素認識テスト)
- **Secondary**: Playwright (フル機能テスト)
- **Backend**: pytest (Python testing)
- **CI/CD**: GitHub Actions

## Work Report & Trouble Management
- Work reports required at project milestones
- Trouble cases must be documented within 24 hours
- Standard templates defined in PROJECT_RULES.md

## Git Workflow Rules
- All improvements/fixes must follow Issue → Branch → PR → Review → Merge workflow
- Branch naming: feature/issue-{number}-{feature-name}
- PR title format: "Fix #{number}: description"
- Squash merge preferred

## Quality Control
- **Final deliverable confirmation**: d.takikita@happyquest.ai
- **Required checks**: Playwright tests, manual verification, security checks
- **Auto-tests mandatory**: CI/CD pipeline must pass

## File Management Rules
- No temporary files in root directory (use temp/ directory)
- Archive old files after 6 months
- Monthly maintenance for unused files
- Follow standard directory structure

## Memory Notes
- Current git status shows merge conflicts in README.md
- Multiple untracked files need organization
- Recent commits show workflow management system implementation
- Focus on defensive security tasks only

## Atlassian Credentials
### HappyQuest-CLI1 組織
- **組織ID**: 256e25b9-b633-4bad-9b0d-25b6d8f763cd
- **API-KEY**: ATCTT3xFfGN0FYonXFBMpf4uEv-JNJT--sjhxloL5kHHKbSDIWClff8_LcnMeZAICHuGkyB27Ar2m6P-ogGiBSfDNw-PM_bYdPj6KJizYeuu7Aebz5b4pvrOKcqrvgIb2fJRt0C7ADy_sYC-KNmurQzNuZ27bXgloyvTwf8nvfNncbIRLQPeS1g=7E1D744E

### HappyQuest 個人アカウント
- **APIトークン**: ATATT3xFfGF0NnqbL3W4YolNIQcX1jM5HXqn8YW6TIHLOF5pupiY9QZvJTJ0wPghpNNCrO6xq8OJ1UbxCqF2Shcbf-A2QboI4eSt4oNr70jYtgo_Jkz-GqEtouP7ydwXuilXWqJ3HMd69_AJgvVGPidSvxmWr98I_zRwe4WUEwKN9bNG17KpCN8=46CA7A25
- **ユーザー**: nanashi7777@example.com
- **Jiraホスト**: https://happyquest.atlassian.net