#!/usr/bin/env bash

brew tap bramstein/webfonttools && \
brew update && \
brew install fonttools fontforge ttfautohint woff2 sfnt2woff-zopfli &&
echo "Done!"
