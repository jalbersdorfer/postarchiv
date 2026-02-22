# ELDOAR Project Memory

## Critical Pattern: Always Verify Before Assuming

**Lesson**: When modifying configurations that reference files or directories:
1. **Always check if files actually exist** before writing to config
2. **Use Read or Glob tools** to verify file locations first
3. **Always read back the modified files** to confirm changes are correct
4. **Never assume directory structure** - verify by looking at the codebase

### Example: Docker Compose Build Context
When the user asked to change docker-compose.yml to build from a Dockerfile:
- ❌ First assumed Dockerfile was in `./eldoar/` (didn't exist)
- ❌ Then assumed it was in same directory as docker-compose (`.`)
- ✅ Should have used Read/Glob to check: Dockerfile is at repository root

**Correct pattern**:
```yaml
build:
  context: ..           # Points from example/ to repository root
  dockerfile: Dockerfile
```

When in doubt about file locations, always verify with Read or Glob before making changes.

## DBD::mysql vs DBD::MariaDB for Sphinx/Manticore

**Never use DBD::MariaDB with Sphinx or Manticore.**

DBD::MariaDB sends initialization SQL (SET character_set_server, etc.) that
Sphinx/Manticore don't support. These can't be suppressed.

**Correct approach:**
- Use `DBD::mysql` (compiles fine against `libmariadb-dev`)
- Use `{mysql_no_autocommit_cmd => 1}` to suppress initialization SQL
- DSN: `dbi:mysql:database=;host=...;port=9306`
