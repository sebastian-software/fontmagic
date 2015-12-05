# FontMagic - The Web Font Builder

## Installatiom

1. Install FontTools (Subsetting Fonts)

$ `brew install fonttools`

2. Install FontForge (Converting Fonts)

$ `brew install fontforge`

3. Install TTF-Autohint (Hinting for Windows Fonts)

$ `brew install ttfautohint`

4. Install Webfont Tools

$ `brew tap bramstein/webfonttools`
$ `brew update`
$ `brew install woff2`
$ `brew install sfnt2woff-zopfli`


## Usage

Original fonts in OTF (OpenType) format should be placed into `src/assets/fonts` without any subfolders.

Then execute and let the magic happen:

$ `bin/regenerate-web-fonts.sh`

Afterwards you'll find the generated web fonts in `src/assets/fonts/web`.

