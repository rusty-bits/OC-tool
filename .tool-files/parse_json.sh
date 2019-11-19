#!/bin/sh

cat -| awk '
{
  gsub(/&lt;/, "<")
  gsub(/&gt;/, ">")
  gsub(/&amp;/, "&")
  gsub(/&quot;/, "\"")
  gsub(/\{/, "{\n")
  gsub(/\}/, "\n}")
  gsub(/:\s*\[/, ":[\n")
  gsub(/\]\s*$/, "\n]\n")
  gsub(/^\s*\[/, "[\n")
  gsub(/\[\s*\{/, "[\n{")
  gsub(/\}\s*\]/, "}\n]")
  gsub(/,[[:blank:]]*$/, ",\n")
  gsub(/",[[:blank:]]*"/, "\",\n\"")
  print
}' | tr -s "\n" | awk '
###############################################################################
function push_state(x) {
  CURRENT_STATE = CURRENT_STATE "/" x
}

function pop_state() {
  match(CURRENT_STATE, /\/[^\/]+$/)
  ret = substr(CURRENT_STATE, RSTART + 1, RLENGTH)
  CURRENT_STATE = substr(CURRENT_STATE, 0, RSTART - 1)
  return ret
}

function get_state() {
  match(CURRENT_STATE, /\/[^\/]+$/)
  return substr(CURRENT_STATE, RSTART + 1, RLENGTH)
}
###############################################################################

###############################################################################
function push_index(x) {
  CURRENT_INDEX = CURRENT_INDEX "/" x
}

function pop_index() {
  match(CURRENT_INDEX, /\/[^\/]+$/)
  ret = substr(CURRENT_INDEX, RSTART + 1, RLENGTH)
  CURRENT_INDEX = substr(CURRENT_INDEX, 0, RSTART - 1)
  return ret
}

function get_index() {
  match(CURRENT_INDEX, /\/[^\/]+$/)
  return substr(CURRENT_INDEX, RSTART + 1, RLENGTH)
}
###############################################################################

###############################################################################
function push_path(x) {
  CURRENT_PATH = CURRENT_PATH "/" x
}

function pop_path() {
  match(CURRENT_PATH, /\/[^\/]+$/)
  ret = substr(CURRENT_PATH, RSTART + 1, RLENGTH)
  CURRENT_PATH = substr(CURRENT_PATH, 0, RSTART - 1)
  return ret
}
###############################################################################

BEGIN {
  CURRENT_PATH = ""
  CURRENT_STATE = "BLOCK"
  CURRENT_INDEX = "0"
}

/^[[:blank:]]*"[^"]+"[[:blank:]]*:[[:blank:]]*[{\[][[:blank:]]*,?[[:blank:]]*$/ {
  match($0, /[\{\[]\s*$/)
  if (substr($0, RSTART, 1) == "{") {
    push_state("BLOCK")
    split($0, path, "\"")
    push_path(path[2])
  } else if (substr($0, RSTART, 1) == "[") {
    push_state("ARRAY")
    push_index("0")
    split($0, path, "\"")
    push_path(path[2])
    push_path("@" get_index())
  } else {
    print "Error: " $0
    print RSTART " : " substr($0, RSTART, 1)
  }
}

/^[[:blank:]]*\[/ {
  push_state("ARRAY")
  push_index("0")
  push_path("@" get_index())
}

/^[[:blank:]]*}/ {
  if (get_state() == "ARRAY") {
    push_index(pop_index() + 1)
    pop_path()
    push_path("@" get_index())
  } else if (get_state() == "BLOCK") {
    pop_path()
    pop_state()
  }
}

/^[[:blank:]]*\]/ {
  pop_state()
  pop_path()
  pop_path()
}

# string
/^[[:blank:]]*"([^"]+)"[[:blank:]]*:[[:blank:]]*"([^"]*)"[[:blank:]]*,?[[:blank:]]*$/ {
  split($0, m, "\"")
  split(substr($0, index($0, ":"), length($0)), n, /:[[:blank:]]*"/)
  split(n[2], n, /"[[:blank:]]*,?[[:blank:]]*/)
  print CURRENT_PATH "/" m[2], "\"" n[1] "\""
}

# string in array
/^[[:blank:]]*"([^"]*)"[[:blank:]]*,?[[:blank:]]*$/ {
  split($0, m, "\"")
  print CURRENT_PATH " " "\"" m[2] "\""
  push_index(pop_index() + 1)
  pop_path()
  push_path("@" get_index())
}

# integer
/"([^"]+)"[[:blank:]]*:[[:blank:]]*([0-9]+),?$/ {
  split($0, m, "\"")
  split(substr($0, index($0, ":") + 1, length($0)), n, ",")
  print CURRENT_PATH "/" m[2], n[1]
}

# boolean, null
/"([^"]+)"[[:blank:]]*:[[:blank:]]*(true|false|null)/ {
  split($0, m, "\"")
  split(substr($0, index($0, ":") + 1, length($0)), n, ",")
  print CURRENT_PATH "/" m[2], n[1]
}
'
