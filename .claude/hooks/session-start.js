#!/usr/bin/env node
/**
 * SessionStart Hook — Load previous session context
 *
 * Adapted from everything-claude-code/scripts/hooks/session-start.js
 * Removed: package-manager detection, session-aliases, learned-skills
 *
 * On new session start:
 * 1. Finds most recent session file in ~/.claude/sessions/
 * 2. Injects its content into Claude's context via stdout
 */

const {
  getSessionsDir,
  findFiles,
  ensureDir,
  readFile,
  log,
  output
} = require('./utils');

async function main() {
  const sessionsDir = getSessionsDir();
  ensureDir(sessionsDir);

  // Find session files from the last 7 days
  const recentSessions = findFiles(sessionsDir, '*-session.tmp', { maxAge: 7 });

  if (recentSessions.length > 0) {
    const latest = recentSessions[0];
    log(`[SessionStart] Found ${recentSessions.length} recent session(s)`);
    log(`[SessionStart] Latest: ${latest.path}`);

    const content = readFile(latest.path);
    if (content && !content.includes('[Session context goes here]')) {
      // Inject into Claude's context (stdout → context window)
      output(`Previous session summary:\n${content}`);
    }
  } else {
    log('[SessionStart] No recent sessions found');
  }

  process.exit(0);
}

main().catch(err => {
  console.error('[SessionStart] Error:', err.message);
  process.exit(0);
});
