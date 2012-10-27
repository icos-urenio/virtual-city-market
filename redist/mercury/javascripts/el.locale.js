jQuery(window).on('mercury:ready', function() {
	Mercury.I18n['el'] =
		{
			"Save": "Αποθήκευση",
		  "Save this page": "Αποθήκευση σελίδας",
		  "Preview": "Προεπισκόπηση",
		  "Preview this page": "Προεπισκόπηση σελίδας",
		  "Undo": "Αναίρεση",
		  "Undo your last action": "Αναίρεση ενέργειας",
		  "Redo": "Επανάληψη",
		  "Redo your last action": "Επανάληψη ενέργειας",
		  "Link": "Σύνδεσμος",
		  "Insert Link": "Εισαγωγή συνδέσμου",
		  "Media": "Μέσα",
		  "Insert Media (images and videos)": "Εισαγωγή μέσων (εικόνες και βίντεο)",
		  "Table": "Πίνακας",
		  "Insert Table": "Εισαγωγή πίνακα",
		  "Character": "Χαρακτήρες",
		  "Special Characters": "Ειδικοί χαρακτήρες",
		  "Snippet": "Μακροεντολές",
		  "Snippet Panel": "Πάνελ μακροεντολών",
		  "History": "Ιστορικό",
		  "Page Version History": "Ιστορικό έκδοσης σελίδων",
		  "Notes": "Σημειώσεις",
		  "Page Notes": "Σημειώσεις σελίδας",
		  "Style": "Στυλ",
		  "Block Format": "Μορφή μπλοκ",
		  "Background Color": "Χρώμα υπόβαθρου",
		  "Text Color": "Χρώμα κειμένου",
		  "Bold": "Έντονα",
		  "Italicize": "Πλάγια",
		  "Overline": "Υπεργράμμιση",
		  "Strikethrough": "Διαγράμμιση",
		  "Underline": "Υπογράμμιση",
		  "Subscript": "Δείκτης",
		  "Superscript": "Εκθέτης",
		  "Align Left": "Στοίχιση αριστερά",
		  "Center": "Κέντρο",
		  "Align Right": "Στοίχιση δεξιά",
		  "Justify Full": "Πλήρης στοίχιση",
		  "Unordered List": "Μη αριθμημένη λίστα",
		  "Numbered List": "Αριθμημένη λίστα",
		  "Decrease Indentation": "Μείωση εσοχής",
		  "Increase Indentation": "Αύξηση εσοχής",
		  "Insert Table Row": "Εισαγωγή γραμμής πίνακα",
		  "Insert a table row before the cursor": "Εισαγωγή γραμμής πίνακα πριν τον δρομέα",
		  "Insert a table row after the cursor": "Εισαγωγή γραμμής πίνακα μετά τον δρομέα",
		  "Delete Table Row": "Διαγραφή γραμμής πίνακα",
		  "Delete this table row": "Διαγραφή αυτής της γραμμής πίνακα",
		  "Insert Table Column": "Εισαγωγή στήλης πίνακα",
		  "Insert a table column before the cursor": "Εισαγωγή στήλης πίνακα πριν τον δρομέα",
		  "Insert a table column after the cursor": "Εισαγωγή στήλης πίνακα μετά τον δρομέα",
		  "Delete Table Column": "Διαγραφή στήλης πίνακα",
		  "Delete this table column": "Διαγραφή αυτής της στήλης πίνακα",
		  "Increase Cell Columns": "Αύξηση του διαστηλίου",
		  "Decrease Cell Columns": "Μείωση του διαστηλίου και προσθήκη νέας στήλης",
		  "Increase Cell Rows": "Αύξηση του εύρους γραμμής",
		  "Decrease Cell Rows": "Μείωση του εύρους γραμμής και προσθήκη νέας γραμμής",
		  "Horizontal Rule": "Διαχωριστική γραμμή",
		  "Insert a horizontal rule": "Εισαγωγή διαχωριστικής γραμμής",
		  "Remove Formatting": "Κατάργηση μορφοποίησης",
		  "Remove formatting for the selection": "Κατάργηση μορφοποίησης της επιλογής",
		  "Edit HTML": "Επεξεργασία HTML",
		  "Edit the HTML content": "Επεξεργασία του περιεχομένου HTML",
		  "Edit Snippet Settings": "Ρυθμίσεις μακροεντολής",
		  "Remove Snippet": "Αφαίρεση μακροεντολής"
		}
	});
/*

  # ### General
  # Error Messages
  "Mercury.Regions.%s is unsupported in this client. Supported browsers are %s.": ""
  "Mercury.PageEditor can only be instantiated once.": ""
  "Opera isn't a fully supported browser, your results may not be optimal.": ""
  "Mercury.PageEditor failed to load: %s\n\nPlease try refreshing.": ""
  "Region type is malformed, no data-type provided, or \"%s\" is unknown for the \"%s\" region.": ""
  "Mercury was unable to save to the url: %s": ""
  "invalid": ""
  "can't be blank": ""
  # Confirmations
  "You have unsaved changes.  Are you sure you want to leave without saving them first?": ""

  # ### Toolbar / Buttons
  # Error Messages
  "Unknown button type \"%s\" used for the \"%s\" button.": ""
  "Unknown button structure -- please provide an array, object, or string for \"%s\".": ""

  # ### Modals / Dialogs / Etc.
  # Error Messages
  "Mercury was unable to load %s for the \"%s\" dialog.": ""
  "Mercury was unable to load %s for the lightview.": ""
  "Mercury was unable to load %s for the modal.": ""

  # ### Snippets
  # Error Messages
  "Error loading the preview for the \"%s\" snippet.": ""
  # Misc
  "Snippet Options": ""

  # ### Uploader
  # Error Messages
  "Unable to process response: %s": ""
  "Error: Unable to upload the file": ""
  "Malformed response from server": "" # needs translation
  "Too large": ""
  "Unsupported format": ""
  # Statuses
  "Processing...": ""
  "Uploading...": ""
  "Aborted": ""
  "Successfully uploaded...": ""
  "Name: %s": ""
  "Size: %s": ""
  "Type: %s": ""

  # Inserting Media
  "Error: The provided youtube share url was invalid.": ""
  "Error: The provided vimeo url was invalid.": ""

  # Statusbar
  "Path:": ""


  # ## HTML / Template Strings

  # ### Modals
  # Insert Link Modal (link.html)
  "Link Content": ""
  "Standard Links": ""
  "URL": ""
  "Index / Bookmark Links": ""
  "Existing Links": ""
  "Bookmark": ""
  "Options": ""
  "Link Target": ""
  "Self (the same window or tab)": ""
  "Blank (a new window or tab)": ""
  "Top (removes any frames)": ""
  "Popup Window (javascript new window popup)": ""
  "Popup Width": ""
  "Popup Height": ""

  # Insert Media Modal (media.html)
  "Images": ""
  "Videos": ""
  "YouTube URL": ""
  "Vimeo URL": ""
  "Alignment": ""
  "None": ""
  "Left": ""
  "Right": ""
  "Top": ""
  "Middle": ""
  "Bottom": ""
  "Absolute Middle": ""
  "Absolute Bottom": ""
  "Width": ""
  "Height": ""
  "Insert Media": ""

  # Insert Table Modal (table.html)
  "Rows": ""
  "Add Before": ""
  "Add After": ""
  "Remove": ""
  "Columns": ""
  "Row Span": ""
  "Column Span": ""
  "Border": ""
  "Spacing": ""

  # HTML Editor Modal (htmleditor.html)
  "HTML Editor": ""
  "Save and Replace": ""

  # ### Dialogs / Etc.
  # Color Palettes (forecolor.html, backcolor.html)
  "Last Color Picked": ""

  # Block Format Select (formatblock.html)
  "Heading 1": ""
  "Heading 2": ""
  "Heading 3": ""
  "Heading 4": ""
  "Heading 5": ""
  "Heading 6": ""
  "Paragraph": ""
  "Blockquote": ""
  "Formatted": ""

  # About Mercury Panel (about.html)
  "Project Home": ""
  "Project Source": ""

  # ### Demo / Placeholder / Defaults
  "The history panel is expected to be implemented with a server back end.  Since this is a demo, we didn't include it.": ""

  "The notes panel is expected to be implemented with a server back end.  Since this is a demo, we didn't include it.": ""

  "Snippet Name": ""
  "A one or two line long description of what this snippet does.": ""

  "First Name": ""
  "Favorite Beer": ""
  "Insert Snippet": ""


  # ## Custom Regional Overrides (eg. en-US)
  _US_:
    "Save": ""
*/