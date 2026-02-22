# ELDOAR - Electronic Document Archive

## Project Overview

ELDOAR is a Perl-based document management system that provides full-text search and management of PDF documents. It uses Sphinx search engine for indexing and Dancer2 web framework for the UI.

## Architecture

### Technology Stack
- **Backend**: Perl with Dancer2 web framework
- **Search Engine**: Sphinx (Real-time index via MySQL protocol)
- **Database Protocol**: MySQL protocol on port 9306
- **Text Extraction**: pdf2txt, ocrmypdf (with German language support)
- **Image Processing**: ImageMagick (convert) for thumbnail generation
- **Frontend**: Bootstrap CSS, Template Toolkit

### Key Components

#### 1. Web Application (`dancerApp.pl`)
- **Entry Point**: 132+ lines, Dancer2 routes
- **Main Routes**:
  - `GET /` - Search interface and document listing
  - `GET /file/**` - File download handler
  - `DELETE /file/:id` - Delete document (moves to `.deleted`)
  - `POST /upload` - PDF upload with OCR and indexing
  - `GET /upload` - Upload form
  - `GET /admin` - Admin dashboard
  - `POST /admin/reindex` - Trigger reindex operation

#### 2. Reindex Script (`reindex.pl`)
- **Purpose**: Rebuild Sphinx index from filesystem
- **ID Generation**: Date-based IDs from YYYY-MM-DD in filename
  - Base timestamp = Unix timestamp (start of day) × 1000 milliseconds
  - Example: `2024-06-01` → `1717200000000`
  - Increments within 24-hour range for collisions
- **Process**:
  1. Clears existing index
  2. Scans `data/files/` recursively for PDFs
  3. Reads companion `.pdf.txt` files for content
  4. Generates unique date-based IDs
  5. Inserts into Sphinx RT index
- **Fallback Logic**:
  - No date in filename → uses directory `YYYY/MM/01`
  - No directory date → uses current date
  - Missing `.txt` file → inserts empty content with warning

#### 3. Sphinx Integration
- **Index Name**: `testrt` (Real-time index)
- **Connection**: DBI MySQL driver to `$SPHINX_HOST:$SPHINX_PORT`
- **Schema**:
  ```sql
  id       - BIGINT (primary key, date-based milliseconds)
  gid      - UINT (currently same as id)
  title    - STRING (relative file path: data/files/YYYY/MM/filename.pdf)
  content  - TEXT (full-text indexed, extracted PDF text)
  ```
- **Query Pattern**:
  ```sql
  SELECT * FROM testrt WHERE MATCH('search term') ORDER BY id DESC LIMIT 18
  ```

## File Structure

```
postarchiv/
├── dancerApp.pl           # Main web application (Dancer2)
├── reindex.pl             # Reindex script (new)
├── start.sh               # Application launcher
├── views/
│   ├── index.tt           # Search interface
│   ├── upload.tt          # Upload form
│   └── admin.tt           # Admin dashboard (new)
├── public/
│   ├── css/
│   │   └── bootstrap.min.css
│   └── js/
│       └── bootstrap.bundle.min.js
└── data/files/            # Document storage (from $ELDOAR_HOME)
    └── YYYY/              # Year directories
        └── MM/            # Month directories
            ├── scan_YYYY-MM-DD_HHMMSS.pdf
            ├── scan_YYYY-MM-DD_HHMMSS.pdf.txt  (extracted text)
            └── scan_YYYY-MM-DD_HHMMSS.pdf.jpg  (thumbnail)
```

### File Naming Convention
- **PDFs**: `scan_YYYY-MM-DD_HHMMSS.pdf`
- **Text**: `{filename}.pdf.txt` (companion file with extracted text)
- **Thumbnail**: `{filename}.pdf.jpg` (first page as JPEG)
- **Deleted**: `{filename}.pdf.deleted` (soft delete marker)

## Environment Variables

### Required
- `SPHINX_HOST` - Sphinx server host (default: `127.0.0.1`)
- `SPHINX_PORT` - Sphinx MySQL protocol port (default: `9306`)
- `ELDOAR_HOME` - Application home directory (default: `/app`)

### Optional
- `OVERVIEW_LIMIT` - Number of documents on homepage (default: `18`)
- `OVERVIEW_ORDER` - Sort order for listings (default: `DESC`)

## Common Operations

### Running the Application
```bash
./start.sh
# Access at http://localhost:3000
```

### Reindex from Filesystem
```bash
# Standalone
perl reindex.pl

# Via web UI
# Navigate to http://localhost:3000/admin
# Click "Start Reindex" button
```

### Upload Documents
```bash
# Via web UI: http://localhost:3000/upload

# Via curl:
curl -F 'file=@path/to/document.pdf' http://localhost:3000/upload
```

### Delete Documents
- Use web UI delete button (soft delete to `.deleted`)
- Removes from Sphinx index
- Moves PDF, TXT, and JPG files to `.deleted` versions

### Check Sphinx Index
```bash
mysql -h $SPHINX_HOST -P $SPHINX_PORT -e "SELECT COUNT(*) FROM testrt;"
mysql -h $SPHINX_HOST -P $SPHINX_PORT -e "SELECT id, title FROM testrt ORDER BY id LIMIT 10;"
```

## Document Processing Pipeline

### Upload Flow
1. User uploads PDF via `/upload` route
2. File saved to `data/files/YYYY/MM/filename.pdf`
3. Text extraction: `pdf2txt` → `.pdf.txt`
4. If text < 10 chars: OCR with `ocrmypdf -l deu`
5. Generate ID: `time() * 1000 + counter`
6. Insert into Sphinx: `(id, gid, title, content)`
7. Generate thumbnail: `convert [0]` → `.pdf.jpg`
8. Redirect to homepage

### Reindex Flow
1. Clear Sphinx index: `DELETE FROM testrt WHERE id > 0`
2. Scan filesystem: `File::Find` in `data/files/`
3. For each PDF:
   - Extract date from filename
   - Calculate base timestamp (milliseconds)
   - Find free ID in date range
   - Read `.pdf.txt` content
   - Insert into Sphinx
4. Progress output every 50 documents

## Date-Based ID System

### Why Date-Based IDs?
- Stable IDs across reindex operations
- Chronological sorting by ID
- Allows deterministic regeneration
- Documents from same day are grouped

### ID Calculation
```perl
# Example: scan_2024-06-01_190905.pdf

# Step 1: Extract date
$year = 2024, $month = 06, $day = 01

# Step 2: Convert to Unix timestamp (start of day, UTC)
$timestamp = timegm(0, 0, 0, 1, 5, 124)  # = 1717200000 seconds

# Step 3: Convert to milliseconds
$base_id = 1717200000 * 1000  # = 1717200000000

# Step 4: Find free ID
# Query Sphinx for existing IDs in range [base_id, base_id + 86400000)
# Increment until free ID found
$final_id = 1717200000000  # (or +1, +2, etc. if collision)
```

### ID Range
- Each day has 86,400,000 possible IDs (milliseconds in a day)
- Multiple documents per day get sequential IDs
- Typical dataset (~850 docs over 7 years) fits easily

## Admin Interface

### Access
Navigate to: `http://localhost:3000/admin`

### Features
- **Document Count**: Shows total indexed documents
- **Reindex Button**: Triggers full reindex from filesystem
- **Warning**: Clear indication that reindex deletes existing data
- **Back Link**: Return to search interface

### Security Note
⚠️ Admin routes currently have **no authentication**. Consider adding auth if exposed to network.

## Development Notes

### Code Style
- Perl 5 with `strict` and `warnings`
- Dancer2 route-based architecture
- Template Toolkit for views
- DBI for database connectivity
- File::Find for filesystem traversal

### Existing Patterns
- Database connection: `DBI->connect("dbi:mysql:database=;host=$ENV{'SPHINX_HOST'};port=$ENV{'SPHINX_PORT'}", "", "", {mysql_no_autocommit_cmd => 1})`
- Template rendering: `template 'view.tt', { data => $value }`
- Redirects: `redirect uri_for('/path')`
- Debugging: `debug 'message'`

### Error Handling
- Missing `.txt` files: warn and continue with empty content
- Date parsing failures: fallback to directory date or current date
- ID collisions: increment within day range, continue past if exhausted
- Database errors: die with descriptive message

## Testing

### Manual Testing Checklist
1. **Search**: Verify existing search works
2. **Upload**: Upload new PDF, verify indexing
3. **Delete**: Delete document, verify soft delete
4. **Admin**: Access `/admin`, check document count
5. **Reindex**: Trigger reindex, verify completion
6. **Post-Reindex Search**: Verify search still works with new IDs

### Verification Queries
```bash
# Document count
mysql -h 127.0.0.1 -P 9306 -e "SELECT COUNT(*) FROM testrt;"

# Sample documents
mysql -h 127.0.0.1 -P 9306 -e "SELECT id, title FROM testrt ORDER BY id LIMIT 10;"

# Search test
mysql -h 127.0.0.1 -P 9306 -e "SELECT id, title FROM testrt WHERE MATCH('test') LIMIT 5;"

# ID range check (verify date-based IDs)
mysql -h 127.0.0.1 -P 9306 -e "SELECT MIN(id), MAX(id), COUNT(*) FROM testrt;"
```

## Known Limitations

1. **No Authentication**: Admin routes are unprotected
2. **Synchronous Reindex**: POST request blocks until completion (~30s for 850 docs)
3. **No Progress Bar**: Web UI shows no progress during reindex
4. **No Backup**: Reindex deletes existing index without backup
5. **No Dry Run**: Cannot preview reindex changes
6. **Single-threaded**: Reindex processes PDFs sequentially

## Future Enhancements

- [ ] Add admin authentication
- [ ] Background job queue for reindex
- [ ] WebSocket progress updates during reindex
- [ ] Index backup before reindex
- [ ] Dry-run mode for reindex
- [ ] Reindex logging to file
- [ ] Parallel PDF processing
- [ ] Document versioning
- [ ] Multi-user access control
- [ ] Document tagging/categories
- [ ] Advanced search filters (date range, etc.)

## Troubleshooting

### Reindex Issues

**Problem**: Reindex script fails with database connection error
```
Solution: Verify Sphinx is running and environment variables are set:
echo $SPHINX_HOST  # Should be 127.0.0.1 or container name
echo $SPHINX_PORT  # Should be 9306
```

**Problem**: Missing text files warnings during reindex
```
Solution: Normal if PDFs were added manually. Run pdf2txt manually:
pdf2txt file.pdf > file.pdf.txt
```

**Problem**: Wrong number of documents indexed
```
Solution: Check for .deleted files being skipped:
find data/files -name "*.pdf" | wc -l
find data/files -name "*.pdf.deleted" | wc -l
```

### Search Issues

**Problem**: Search returns no results after reindex
```
Solution: Verify index has content:
mysql -h $SPHINX_HOST -P $SPHINX_PORT -e "SELECT COUNT(*) FROM testrt;"
Check .txt files have content (not empty)
```

**Problem**: Document IDs are not date-based
```
Solution: Verify filenames match pattern scan_YYYY-MM-DD_HHMMSS.pdf
Check reindex.pl extract_date() function is working
```

## Dataset Information

- **Total Documents**: ~848 PDFs (as of 2024)
- **Date Range**: 2019-2026
- **Directory Structure**: Organized by YYYY/MM
- **Average File Size**: Varies (scanned documents)
- **Language**: German (OCR with `deu` language pack)

## References

- **Sphinx Documentation**: https://sphinxsearch.com/docs/
- **Dancer2 Manual**: https://metacpan.org/pod/Dancer2::Manual
- **Template Toolkit**: http://www.template-toolkit.org/docs/
- **DBI Documentation**: https://metacpan.org/pod/DBI
