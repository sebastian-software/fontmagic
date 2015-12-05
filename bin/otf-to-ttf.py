#!/usr/bin/env python
# coding: utf-8
# Copyright 2013 The Font Bakery Authors. All Rights Reserved.
# Forked from https://raw.githubusercontent.com/googlefonts/fontbakery/master/bakery_cli/scripts/font2ttf.py
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# See AUTHORS.txt for the list of Authors and LICENSE.txt for the License.

import fontforge
import argparse
import os


def convert(sourceFont, ttf):
    font = fontforge.open(sourceFont)

    font.selection.all()

    # Remove overlap
    font.removeOverlap()

    # Convert curves to quadratic (TrueType)
    font.layers.font.is_quadratic = True

    # Simplify
    font.simplify(1, ('setstarttoextremum', 'removesingletonpoints', 'mergelines'))

    # Correct Directions
    font.correctDirection()

    # Generate with DSIG and OpenType tables
    flags = ('dummy-dsig', 'opentype')
    font.generate(ttf, flags=flags)



parser = argparse.ArgumentParser()
parser.add_argument('source', nargs='+', type=str)

args = parser.parse_args()

for src in args.source:
    if not os.path.exists(src):
        print('Error: {} does not exists'.format(src))
        continue

    basename, _ = os.path.splitext(src)
    convert(src, '{}.ttf'.format(basename))
