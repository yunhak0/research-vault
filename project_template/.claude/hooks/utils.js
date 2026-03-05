/**
 * Utility functions for Claude Code hooks
 *
 * Stripped-down version of everything-claude-code/scripts/lib/utils.js
 * Keeps only functions used by session-start, session-end, pre-compact,
 * and suggest-compact hooks.
 *
 * Original: https://github.com/affaan-m/everything-claude-code
 * License: MIT
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

// ── Directories ──────────────────────────────────────────────────────────────

function getHomeDir() {
  return os.homedir();
}

function getSessionsDir() {
  return path.join(getHomeDir(), '.claude', 'sessions');
}

function getTempDir() {
  return os.tmpdir();
}

/**
 * Ensure a directory exists (create recursively if not)
 */
function ensureDir(dirPath) {
  try {
    if (!fs.existsSync(dirPath)) {
      fs.mkdirSync(dirPath, { recursive: true });
    }
  } catch (err) {
    if (err.code !== 'EEXIST') {
      throw new Error(`Failed to create directory '${dirPath}': ${err.message}`);
    }
  }
  return dirPath;
}

// ── Date/Time ────────────────────────────────────────────────────────────────

function getDateString() {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

function getTimeString() {
  const now = new Date();
  const h = String(now.getHours()).padStart(2, '0');
  const min = String(now.getMinutes()).padStart(2, '0');
  return `${h}:${min}`;
}

function getDateTimeString() {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  const h = String(now.getHours()).padStart(2, '0');
  const min = String(now.getMinutes()).padStart(2, '0');
  const s = String(now.getSeconds()).padStart(2, '0');
  return `${y}-${m}-${d} ${h}:${min}:${s}`;
}

// ── Session/Project ──────────────────────────────────────────────────────────

/**
 * Get short session ID from CLAUDE_SESSION_ID env var (last 8 chars)
 * Falls back to git repo name, then cwd basename, then 'default'
 */
function getSessionIdShort(fallback = 'default') {
  const sessionId = process.env.CLAUDE_SESSION_ID;
  if (sessionId && sessionId.length > 0) {
    return sessionId.slice(-8);
  }
  return getProjectName() || fallback;
}

function getProjectName() {
  try {
    const { execSync } = require('child_process');
    const toplevel = execSync('git rev-parse --show-toplevel', {
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    }).trim();
    return path.basename(toplevel);
  } catch {
    return path.basename(process.cwd()) || null;
  }
}

// ── File Operations ──────────────────────────────────────────────────────────

function readFile(filePath) {
  try {
    return fs.readFileSync(filePath, 'utf8');
  } catch {
    return null;
  }
}

function writeFile(filePath, content) {
  ensureDir(path.dirname(filePath));
  fs.writeFileSync(filePath, content, 'utf8');
}

function appendFile(filePath, content) {
  ensureDir(path.dirname(filePath));
  fs.appendFileSync(filePath, content, 'utf8');
}

/**
 * Replace text in a file
 * @param {string} filePath
 * @param {string|RegExp} search
 * @param {string} replace
 * @returns {boolean} true if written successfully
 */
function replaceInFile(filePath, search, replace) {
  const content = readFile(filePath);
  if (content === null) return false;
  try {
    writeFile(filePath, content.replace(search, replace));
    return true;
  } catch {
    return false;
  }
}

/**
 * Find files matching a glob pattern in a directory
 * @param {string} dir - Directory to search
 * @param {string} pattern - Glob pattern (e.g., "*.tmp", "*-session.tmp")
 * @param {object} options - { maxAge: days }
 * @returns {Array<{path: string, mtime: number}>} Sorted newest-first
 */
function findFiles(dir, pattern, options = {}) {
  if (!dir || !pattern) return [];
  const { maxAge = null } = options;
  const results = [];

  if (!fs.existsSync(dir)) return results;

  const regexPattern = pattern
    .replace(/[.+^${}()|[\]\\]/g, '\\$&')
    .replace(/\*/g, '.*')
    .replace(/\?/g, '.');
  const regex = new RegExp(`^${regexPattern}$`);

  try {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isFile() || !regex.test(entry.name)) continue;
      const fullPath = path.join(dir, entry.name);
      let stats;
      try { stats = fs.statSync(fullPath); } catch { continue; }

      if (maxAge !== null) {
        const ageInDays = (Date.now() - stats.mtimeMs) / (1000 * 60 * 60 * 24);
        if (ageInDays <= maxAge) {
          results.push({ path: fullPath, mtime: stats.mtimeMs });
        }
      } else {
        results.push({ path: fullPath, mtime: stats.mtimeMs });
      }
    }
  } catch { /* ignore permission errors */ }

  results.sort((a, b) => b.mtime - a.mtime);
  return results;
}

// ── Hook I/O ─────────────────────────────────────────────────────────────────

/** Log to stderr (visible to user in Claude Code terminal) */
function log(message) {
  console.error(message);
}

/** Output to stdout (injected into Claude's context) */
function output(data) {
  if (typeof data === 'object') {
    console.log(JSON.stringify(data));
  } else {
    console.log(data);
  }
}

// ── Exports ──────────────────────────────────────────────────────────────────

module.exports = {
  getHomeDir,
  getSessionsDir,
  getTempDir,
  ensureDir,
  getDateString,
  getTimeString,
  getDateTimeString,
  getSessionIdShort,
  getProjectName,
  readFile,
  writeFile,
  appendFile,
  replaceInFile,
  findFiles,
  log,
  output
};
