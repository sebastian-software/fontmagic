#!/usr/bin/env bash

cd `dirname $0`
tools=`pwd`

fontfolder = $1
if [ $fontfolder == "" ]; then
  echo "First parameter should be the source font folder!"
  exit 1
fi

cd $1

dist="web/"
echo ">>> Cleanup..."
rm -rf $dist > /dev/null 2>&1
mkdir -p $dist > /dev/null 2>&1

# Loop trough all original OpenType fonts
for otf in *.otf; do
  echo ">>> $otf"

  # Common Options for pyftsubset:
  #
  # --unicodes=41-5a,61-7a    Include all ASCII symbols
  # --unicodes=20-7e          Basic Latin (via: http://sourceforge.net/p/fontforge/git/ci/master/tree/fonttools/pcl2ttf.c#l656)
  # --unicodes=a0-ff          Latin-1 Supplement
  # --unicodes=100-17f        Latin Extended-A
  # --unicodes=180-24f        Latin Extended-B
  # --unicodes=20ac           Euro Symbol
  #
  # --recommended-glyphs      Include some standard characters (not required but for compatibility)
  # --text-file               Include all character used in the given text file
  #
  # --layout-features='*'     Keep all layout features like kerning
  # --layout-features='onum,liga' Keep old style numbers, ligatures (http://help.typekit.com/customer/portal/articles/1789736)
  #
  # --name-legacy             Keep non-unicode name (compatibility)
  # --name-languages          Keep all language info
  # --obfuscate-names         Make the font unusable as a system font

  subsetted=$dist`echo $otf | sed s:.otf:-subset.otf:g`
  echo "  - Subsetting OTF..."
  pyftsubset $otf --output-file=$subsetted \
    --unicodes="`cat $tools/../encodings/latin-ssoft_unique-glyphs.nam | cut -d\  -f1`" \
    --layout-features='*' \
    --name-legacy \
    --name-languages='*' \
    --obfuscate-names

  echo "    - Size: `du -sh $otf | cut -f1` =>`du -sh $subsetted | cut -f1`"

  #echo "Hinting OTF (Latin)..."
  #hinted_otf=`echo $otf | sed s:.otf:-hinted.otf:g`
  #autohint -q $otf || exit 1

  ttf=`echo $subsetted | sed s:.otf:.ttf:g`
  echo "  - Convert result to TTF..."
  fontforge -script $tools/otf-to-ttf.py $subsetted > /dev/null 2>&1 || exit 1

  # Common Options for ttfautohint:
  #
  # -c, --composites           By default, the components of a composite glyph get hinted separately.
  #                            If this flag is set, the composite glyph itself gets hinted (and the
  #                            hints of the components are ignored). Using this flag increases the
  #                            bytecode size a lot, however, it might yield better hinting results.
  # -d, --dehint               remove all hints
  # -D, --default-script=S     set default OpenType script (default: latn)
  # -l, --hinting-range-min=N  the minimum PPEM value for hint sets
  #                            (default: 8)
  # -r, --hinting-range-max=N  the maximum PPEM value for hint sets
  #                            (default: 50)
  # -s, --symbol               input is symbol font
  # -w, --strong-stem-width=S  use strong stem width routine for modes S,
  #                            where S is a string of up to three letters
  #                            with possible values `g' for grayscale,
  #                            `G' for GDI ClearType, and `D' for
  #                            DirectWrite ClearType
  # -W, --windows-compatibility add blue zones for `usWinAscent' and
  #                            `usWinDescent' to avoid clipping
  # -x --increase-x-height=n   If this flag is set, values in the range 6 PPEM to n PPEM are
  #                            much more often rounded up. The default value for n is 14.

  # For highter values we use OTF/Postscript to use grayscale antialiasing (no ClearType)
  hintmin=12
  hintmax=30

  # Stop hinting when there’s enough vertical pixels to make the glyphs look good (~50px).
  # if you want to turn off hinting for values larger than 40, you should specify both parameters
  # --hinting-range-max=40 and --hinting-limit=40.
  # Hinting is generally tricky under 16px, but ttfautohint does an okay job there, too.
  # Rounding up the xheight is okay for fonts < 15px
  # Smooth horizontal stems = more fidelity fonts (more correct rendering)
  #
  # Via: http://typedrawers.com/discussion/434/best-ttfautohint-settings

  # I consider smooth stem widths superior to strong stem widths
  # since the overall shape distortions are reduced, together with a better
  # grayness.  The default setting makes it possible: strong stem widths only in
  # the GDI environment, where non-integer positioning leads to extremely ugly
  # results otherwise.
  #
  # 'G' (the default) means:
  # - full-pixel stem widths for GDI ClearType
  # - discrete, possibly non-integer stem widths for both DW ClearType and grayscale hinting
  #
  # Via: https://lists.gnu.org/archive/html/freetype/2014-02/msg00003.html

  echo "  - Hinting TTF..."
  hinted=`echo $ttf | sed s:.ttf:-hinted.ttf:g`
  ttfautohint \
    --windows-compatibility --composites --default-script=latn \
    --hinting-range-min=$hintmin --hinting-range-max=$hintmax --hinting-limit=$hintmax \
    --no-info \
    $ttf $hinted > /dev/null

  echo "  - Creating plain TTF..."
  plain=`echo $ttf | sed s:.ttf:-plain.ttf:g`
  ttfautohint -d $ttf $plain

  echo "  - Generating hinted EOT..."
  eotgdi=`echo $hinted | sed s:.ttf:.eot:g`
  # ttf2eot $hinted > $eotgdi
  python $tools/eotlitetool.py $hinted

  # Does MTX compression, but compilation of the tool is currently broken on Mac OS 10.10
  # See also:
  # - http://typophile.com/node/89218
  # - https://github.com/mekkablue/webfontmaker/blob/master/webfontmaker.sh
  # java -jar sfnttool.jar -e -x $hinted $eotgdi

  echo "  - Generating hinted TTF/WOFF..."
  sfnt2woff-zopfli $hinted

  echo "  - Generating plain TTF/WOFF..."
  sfnt2woff-zopfli $plain

  echo "  - Generating OTF/WOFF..."
  sfnt2woff-zopfli $subsetted

  echo "  - Generating hinted TTF/WOFF2..."
  woff2_compress $hinted > /dev/null

  echo "  - Generating plain TTF/WOFF2..."
  woff2_compress $plain > /dev/null

  echo "  - Generating OTF/WOFF2..."
  woff2_compress $subsetted > /dev/null

done

echo ">>> Setup"
echo "  - OTF/WOFF for Mac OS / iOS / Linux / Android"
echo "  - OTF/WOFF for Windows based browsers > 30px (display sizes)"
echo "  - TTF/WOFF/DirectWrite for DirectWrite enabled Windows browsers (IE>=9/Chrome>=37) for sizes < 30px (text sizes)"
echo "  - TTF/WOFF/GDI for legacy GDI Windows browsers for sizes < 30px (text sizes)"
echo "  - EOT is only needed for IE < 9"
