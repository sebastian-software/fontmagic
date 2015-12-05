#!/usr/bin/env bash

echo ">>> Serializing fonts into JSON..."
for file in `find _site/assets ! -type d -name "*.woff" -o -name "*.woff2"  -o -name "*.otf" -o -name "*.ttf"`; do
  echo "  - `basename $file`"
  out=$file.b64.json  
  echo -n "{data:'" > $out
  openssl base64 < $file | tr -d '\n' >> $out
  zopfli -i10 $out
  echo -n "'}" >> $out
done

