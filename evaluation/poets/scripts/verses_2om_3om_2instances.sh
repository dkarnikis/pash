# verses with 2 or more, 3 or more, exactly 2 instances of light.
INPUT=${INPUT:-$PASH_TOP/evaluation/scripts/input/genesis}
grep -c 'light.*light' ${INPUT} 
grep -c 'light.*light.*light' ${INPUT}
grep 'light.*light' ${INPUT} | grep -vc 'light.*light.*light'
#grep -c 'light.*light' ${INPUT} | paste -sd+ | bc
#grep -c 'light.*light.*light' ${INPUT} | paste -sd+ | bc
#grep 'light.*light' ${INPUT} | grep -vc 'light.*light.*light'  | paste -sd+ | bc