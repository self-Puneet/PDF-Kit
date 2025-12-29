first there would be 3 small widgets - PDFs, Images, Downloads, Recently Used.
each of these pages should be routing a new page. about which we will be discussing in the next section. 

than there will be a section for storage in which there will be full width widgets for the internal storage (for sure). and if any external storage is like SSD card than show SSD card Container and if not than just show a contianer showing that no external storage found. 

than a section for recent files
with all the document tiles for recent files used like being shown on the home_page. show only 10 document tiles there and then there shoudl be a arrow button in right most side of the section header "recent files" to navigate to the recent files page (which is already there in the router).

then in the starting section I have discused that there will be 4 widgets
- PDFs
- Images
- Downloads
- Recently Used - navigate to same recent file page

so each of these pages should be routing a new page. about which we will be discussing in the next section. 

# Task 2
ok notice the file_screen_page.dart. it has 2 mods 1 for selection and on2 for showing and other operations of the file. similarily you have to do the same in the recent files page. 
```dart
  static const filesRootFullscreen = 'files.root.fullscreen';
  static const filesFolderFullScreen = 'files.folder.fullscreen';
  static const filesSearchFullscreen = 'files.search.fullscreen'; // NEW

```

like this make another route for recent files page which should be routing to same page but with different query parameters as you can see in file_selection_shell.dart. and accordingly update the file_selection_shell.dart and the app_router.dart as you want. so that you can make a full_screen mode for recent files too. and then update the root file page too.