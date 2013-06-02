#! /bin/bash

ant adr.dist
cd dist/guitar
chmod +x `find . -name '*.sh'`


