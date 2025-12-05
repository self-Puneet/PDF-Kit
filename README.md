# PDF-Kit
It's an app for all your PDF needs, providing a robust toolkit to merge multiple PDFs, split single documents, convert images to PDF, compress file sizes, rotate pages, add passwords, and much more. Developed using Flutter and Dart.

1. in the reorder pdf screen I want  (user can remove page, rotate page and reorder their sequence)
    - reorder pdf page title
    - description for the reordering page
    - a widget showing that x pages removed and y pages rotate
    - below should be reorderable grid of the pdf page preview components of column count 2. 
    - on preview there should be a button for rotating the page and second button for removing the page
    - on remove button click the page preview border will turn to red showing that this page will be removed from the pdf and the in the top widget it will start showing 1 page removed
    - also I want that there should be a single unit of scrollable unit on whole page i.e. I don't want a seperate scrolling thing in the grid and in rest of page. I want them as a single unit so that if suppose there are 100 pages i.e. grid of rows 50 and if I am at the bottom most row than by long pressing the component and dragging it to the top the whole page together moves as a singel scrollable child and thus I reach the top most part of page.
    - then offcourse bottom navigation bar for reordering. 
    - on pressign the reordering then the reorder_service should be implemented properly. if you want to change the service itself than feel free

2. in the pdf_to_image
    - title
    - description
    - images name prefix (naming style of the multiple images which is going to be used user can change it)
    - saving location of the images widget remains same
    - select pdf file with a pages selected button telling how many pages selected
    - docEntryCard from document_title telling about the pdf selected
    - on pressing on the page selected button on the right of selected pdf file sub heading than the new page should open having these things.
        - page selector almost have all of it. just make any potential problem go away and I guess it is not scrollable or something make it done. cards should not be reorderable.

not everythign need to be chnaged specially in the pdf_to_image however the reorder_pdf page have to be chagned. as you already know we are not gonna use pdf_page_seletror for grid.