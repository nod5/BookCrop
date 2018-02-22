# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/).

## [2018-02-22] - 2018-02-22
### Added
- GitHub repo
- scrub mode for binarized .tif files
- command line input: multiple image filepaths 
- command line input: .txt file with one image filepath per line

### Changed
- big code cleanup/rewrite
- fix rotation preview outside screen if start in landscape mode

## [2016-04-12] - 2016-04-12
### Changed
- show errormessage if libjpeg-62.dll is missing

## [2016-04-11] - 2016-04-11
### Changed
- fix image size bug on non-english systems (thanks hatatat)

## [2014-11-14] - 2014-11-14
### Added
- R L mode: separate cropping of R.jpg and L.jpg files 
- option to rotate image 90 degree steps before crop

### Changed
- fix preview flickering
- fix variable error

## [2013-06-22] - 2013-06-22
### Added
- .tif input support
- faster preview with -size command in graphicsmagick
- faster crop with jpegtran from libjpeg-turbo

### Changed
- fix find GraphicsMagick path via registry also in 64bit Windows

## [2012-12-13] - 2012-12-13
### Added
- preview height adapts to screen height
- crop to subfolder option

### Changed
- fix selection was imprecise in some cases

## [2012-12-08] - 2012-12-08
### Added
- first release
