#!/bin/bash

# Show the set-difference between two streams (i.e., elements in the first that are not in the second).

# For default data, it uses the current set 

p="../../stats/c_stats/"
A=${1:-${p}posix.txt}
B=${2:-${p}coreutils.txt}
comm -3 <(cut -d ' ' -f 1 $A | sort ) <( cut -d ' ' -f 1 $B | sort)