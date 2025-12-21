# FirebirdRepairBase

A low-level tool for analyzing and potentially recovering data from **broken** Firebird database files (`.fdb`, `.gdb`). It bypasses the standard Firebird engine to read raw page structures and data.

**Warning:** This is a **development version**. It directly manipulates database files. Always create a **backup** of your database before using this tool. Use at your own risk.

## Features

*   **Database Structure Analysis:**
    *   Opens and reads Firebird database files.
    *   Identifies and counts pages by type (Header, PIP, TIP, Pointer, Data, Index Root/BTree, Blob, Generator, WAL).
    *   Displays basic page information (number, type, checksum, relation ID).
*   **Header Manipulation:**
    *   Reads and interprets database header flags.
    *   Allows setting/clearing specific flags (e.g., Read Only, Force Write).
*   **Page Content Inspection:**
    *   Reads specific pages by number.
    *   Extracts and displays raw record fragments from Data Pages.
    *   Allows changing page type and checksum (Dangerous!).
*   **Transaction Analysis:**
    *   Reads Transaction Inventory Pages (TIP).
    *   Counts transactions by state (Active, Limbo, Dead, Committed).
*   **Basic Data Recovery:**
    *   Extracts raw data fragments from Data Pages.
    *   *(WIP)* Basic MVCC (Multi-Version Concurrency Control) awareness for data visibility (see TODO).
    *   *(New)* Parses basic record headers to identify deleted records and data length.
*   **Record Fragment Parsing:**
    *   Introduces `uRecordParser` module for analyzing individual record fragments.
    *   Extracts key information like transaction ID, back pointer, flags, and data length from the record header.

## In Development (TODO)

*   **Advanced Data Recovery:**
    *   Implement full MVCC logic to reconstruct the correct, visible version of records based on transaction states and TIP page data.
    *   Export recovered data to a new, valid Firebird database or other formats (e.g., CSV).
    *   Analyze and potentially repair B-Tree index structures.
    *   Analyze and potentially repair Blob page chains.
*   **Deeper Integrity Checks:**
    *   Verify logical links between pages (e.g., Pointer Pages -> Data Pages, Record Back Pointers).
    *   Identify orphaned pages.
*   **Page Generation/Repair:**
    *   Implement logic to generate missing TIP or PIP pages if necessary.
    *   Attempt to rebuild damaged page structures.
*   **User Interface Improvements:**
    *   Add search functionality within page data.
    *   Provide more detailed views for different page types (B-Tree keys, Blob data).
    *   Add a 'Restore from Backup' feature.
    *   Improve error handling and user feedback.

## Supported Firebird Pages

*   Database Header Page
*   Page Inventory Page (PIP)
*   Transaction Inventory Page (TIP)
*   Pointer Page
*   Data Page
*   Index Root Page
*   Index B-Tree Page
*   Blob Data Page
*   Generator Page
*   Write Ahead Log Page (WAL) (Note: WAL functionality might be limited)

## Technical Details

*   **Language:** Pascal (Delphi).
*   **Target:** Windows.
*   **Approach:** Direct file I/O, parsing raw page structures according to Firebird Internal Format documentation (`fbint-page-1.html`) and Firebird source code conventions.
*   **Modules:**
    *   `uStructs`: Core data structures (TPag, THdr, etc.).
    *   `uPageAnalyzer`: General page reading and type identification.
    *   `uDataPage`: Data Page header parsing and record fragment extraction.
    *   `uTipPage`: TIP page header parsing and transaction state analysis.
    *   `uBtreePage`: B-Tree page header parsing and key extraction.
    *   `uRecordParser`: *(New)* Parses headers of individual record fragments.
    *   `uDatabaseStats`: Aggregates statistics using `uPageAnalyzer`.
    *   `uFlagManager`: Manages database header flags.

## License

MIT

## Author

Gordienko Roman

