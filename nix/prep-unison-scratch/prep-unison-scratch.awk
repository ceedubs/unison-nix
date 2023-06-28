#!/usr/bin/awk -f

BEGIN {
  comment=0
}

# comment out unique types because of https://github.com/unisonweb/unison/issues/2196
#
# comment out record type modify functions because of
# https://github.com/unisonweb/unison/issues/3733
#
# comment out record type set functions because you generally want to modify the record type and use
# the generated set function.
#
# Ideally this would comment out record type accessor functions as well, but they are harder to
# detect.
/^unique |^[[:blank:]]*[^\-].*\.(modify|set) :/ {
  comment=1
}

# empty lines typically mean the end of a definition
/^\s*$/ {
  comment=0
}

comment {
  print "--" $0
}

!comment {
  print $0
}
