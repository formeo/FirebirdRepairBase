# FirebirdRepairBase
Program for analize and repare broken firebird database, it is working on the low level
This is dirty version of program, now program is in develop process.

Now it features: 
* check database pages by type
* replace some header page params
* set READ ONLY and FORCE WRITE flags
* replace check sum on pages
* generate new page

# In developing
* Analisys pages, pump data.
* Analisys TIP sequence, generate lost TIP pages

# Firebird Database Pages
* Database Header Page
* Page Inventory Page (PIP)
* Transaction Inventory Page (TIP)
* Pointer Page
* Data Page
* Index Root Page
* Index B-Tree Page
* Blob Data Page
* Generator Page
* Write Ahead Log Page
