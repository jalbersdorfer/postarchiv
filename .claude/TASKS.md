# ELDOAR - Pending Tasks

## Backlog

### #1 Add .deleted extension to PDF files on delete
When a document is deleted via the UI, rename the .pdf file to .pdf.deleted
(and companion .pdf.txt and .pdf.jpg files accordingly). Verify and fix the
delete handler in dancerApp.pl.

### #2 Fix delete function to reload page after deletion
After deleting a document via the UI trashbin/delete button, the page should
automatically reload to reflect the removal. Fix the frontend JS or the
Dancer2 route response to trigger a page reload.

### #3 Add version number below the banner
Display a version number beneath the main banner/header in the UI. Define the
version string (e.g. in dancerApp.pl or a config file) and pass it to the
index.tt template for rendering.

### #4 Add date column to index and make it editable in frontend
Add a visible date column to the document listing on the index page. The date
should be derived from the document's date-based ID (millisecond Unix timestamp).
Make the date editable in the frontend so users can correct wrongly parsed dates.
Editing the date should update the Sphinx index entry and optionally rename the file.

### #5 Change default sort order to date column descending
Change the default sort order of the document listing to sort by the date column
descending (newest first). Should be explicit on the date column once task #4 is done.

### #6 Add Tag functionality with history tracking
- Add/remove tags to documents via the UI
- Tags should be persisted (in Sphinx index or a separate store)
- Track tag changes with timestamps (added/removed history)
- Display tag history in the frontend
- Tags should be searchable
This is a larger feature requiring schema changes, backend routes, and frontend UI.

### #7 Replace Bootstrap with oak.ink for frontend
Replace Bootstrap CSS with oak.ink in all frontend templates (index.tt, upload.tt,
admin.tt). Update public/css and public/js references. Ensure all existing UI
components are properly restyled.
