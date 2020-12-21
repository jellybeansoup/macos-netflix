# Netflix wrapper for macOS

A very simple proof-of-concept app for a `WKWebView` based app to allow viewing Netflix outside the browser on macOS. The goal is to somewhat allow a picture-in-picture style browsing and watching experience. There's a bunch of similar apps on the Mac App Store, but this one is mine, and the idea is to keep it pretty lightweight (no majorly additive features).

![Screenshot displaying the Netflix interface](https://github.com/jellybeansoup/macos-netflix/blob/master/Resources/screenshot.png)

## Installation Instructions

### Direct Download

Go to [the page for the latest release](https://github.com/jellybeansoup/macos-netflix/releases/latest) and download the zipped app. You want the file labelled something akin to "Netflix.zip", and not the ones labelled "source code".

Unzip the app, and drag it into your Applications folder. If you accidentally downloaded the source code, you'll be quite confused, so go back a step and download the _other_ zip file.

That's all there is. Run and enjoy.

### Homebrew

If you have [Homebrew](https://brew.sh/) installed, try running the following in your terminal:
```shell
brew install --cask jellybeansoup-netflix
```

## Alternative Icons

The [Icons](https://github.com/jellybeansoup/macos-netflix/tree/master/Icons) folder contains alternative icons that may be used with the app. After downloading, you can apply the icon of your choice by right clicking on the installed app in Finder, clicking Get Info, and dragging it into the icon well at the top of the window.

![Screenshot displaying the Netflix interface](https://github.com/jellybeansoup/macos-netflix/blob/master/Resources/alternative-icons.gif)

## Legal

Copyright © 2020 Daniel Farrelly. Released under the [BSD license](https://github.com/jellybeansoup/macos-netflix/blob/master/LICENSE).

App icon template is from the [Bjango Templates repository](https://github.com/bjango/Bjango-Templates), which are released under the BSD License, and are copyright © Bjango and Marc Edwards. 

This project is not associated with, affiliated with, or endorsed by Netflix, Inc. A Netflix subscription is required to use this app. Please visit Netflix.com to verify that service is available in your country.
