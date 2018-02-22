# BookCrop

BookCrop.ahk -- version 2018-02-22 -- by Nod5 -- GPLv3 -- Made in Windows 10

AutoHotkey program to quickly crop many same sized images via an overlay preview

[Download BookCrop binary](https://github.com/nod5/BookCrop/releases)

![Alt text](images/bookcrop_screenshot1.PNG?raw=true)

![Alt text](images/bookcrop_screenshot2.PNG?raw=true)

[larger screenshot](images/bookcrop_screenshot2_large.PNG)


## How to use
1. Drag and drop jpeg/tif images or a folder with images
2. BookCrop overlays them into one preview
3. Draw a rectangle and click "crop" to crop all images

## Setup
- Install latest [GraphicsMagick](http://sourceforge.net/projects/graphicsmagick/files/graphicsmagick-binaries/) (Q8 version is faster)
- Get two files from [libjpeg-turbo](http://sourceforge.net/projects/libjpeg-turbo/files/):
    - Download libjpeg-turbo-1.5.3-gcc64.exe or newer
    - Unzip the .exe with 7zip
    - browse to \bin subfolder
    - copy `jpegtran.exe` and `libjpeg-62.dll` and place next to `BookCrop.exe`

## More Features

- `Ctrl`+`Click` and draw another rectangle to split crop into two images with L and R suffix.

- `Ctrl`+`Tab` starts R L mode. Files ending with `L.jpg` and `R.jpg` are previewed and cropped separately.

- `R` / `L` at preview: rotate preview in 90 degree steps.

- `S` at preview: Scrub mode. Draw a rectangle to whiten that area in binarized tif input images. Useful for scrubbing noise near inner/outer edges on book page photos.

- Command line input: a folder path or image filepaths or a .txt with one image filepath per line.
````
BookCrop.exe "C:\folder"
````

````
BookCrop.exe "C:\dir\a.jpg" "C:\dir\b.jpg"
````

````
BookCrop.exe "C:\files.txt"
````


- Drop a folder: Process all jpg or tif in folder (whichever there is more of).

- Drop a single jpg or tif: Quick preview. Move threshold slider to refresh.
Change threshold in quick preview if the overlay is too dark or light.

- Important: Preview and cropping only works well on same size input images.

- Advice: Use crop to subfolder, so you can redo if you overcrop.

- If you wish to run/build BookCrop.ahk from source: install [Autohotkey](https://autohotkey.com)

## Feedback
GitHub , https://github.com/nod5/BookCrop
