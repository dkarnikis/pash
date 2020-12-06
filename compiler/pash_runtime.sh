#!/bin/bash

## Abort script if variable is unset
set -u

## Check flags
pash_output_time_flag=0
pash_execute_flag=1
pash_speculation_flag=0 # By default there is no speculation
pash_checking_speculation=0
for item in $@
do
    if [ "$pash_checking_speculation" -eq 1 ]; then
        pash_checking_speculation=0
        if [ "no_spec" == "$item" ]; then
            pash_speculation_flag=0
        elif [ "quick_abort" == "$item" ]; then
            ## TODO: Fix how speculation interacts with compile_optimize_only and compile_only
            pash_speculation_flag=1
        else
            echo "Unknown value for option --speculation"
            exit 1
        fi
    fi

    if [ "--output_time" == "$item" ]; then
        pash_output_time_flag=1
    fi

    if [ "--compile_optimize_only" == "$item" ] || [ "--compile_only" == "$item" ]; then
        pash_execute_flag=0
    fi

    if [ "--speculation" == "$item" ]; then
        pash_checking_speculation=1
    fi
done

## Prepare a file with all shell variables
pash_runtime_shell_variables_file=$(mktemp -u)
declare -p > $pash_runtime_shell_variables_file

## Prepare a file for the output shell variables to be saved in
pash_output_variables_file=$(mktemp -u)
# >&2 echo "Input vars: $pash_runtime_shell_variables_file --- Output vars: $pash_output_variables_file"

## The first argument contains the sequential script. Just running it should work for all tests.
pash_sequential_script_file=$1

## The parallel script will be saved in the following file if compilation is successful.
pash_compiled_script_file=$(mktemp -u)

## Just execute the original script
# >&2 echo "Sequential file in: $1 contains"
# >&2 cat $1
# ./pash_wrap_vars.sh $pash_runtime_shell_variables_file $pash_output_variables_file $1


## Count the execution time
pash_exec_time_start=$(date +"%s%N")

if [ "$pash_speculation_flag" -eq 1 ]; then
    source pash_runtime_quick_abort.sh
else        
    python3.8 pash_runtime.py ${pash_compiled_script_file} --var_file "${pash_runtime_shell_variables_file}" "${@:2}"
    pash_runtime_return_code=$?

    ## Count the execution time and execute the compiled script
    if [ "$pash_execute_flag" -eq 1 ]; then
        ## If the compiler failed, we have to run the sequential
        if [ "$pash_runtime_return_code" -ne 0 ]; then
            # source ${pash_sequential_script_file}
            ./pash_wrap_vars.sh $pash_runtime_shell_variables_file $pash_output_variables_file ${pash_sequential_script_file}
            pash_runtime_final_status=$?
        else
            ./pash_wrap_vars.sh $pash_runtime_shell_variables_file $pash_output_variables_file ${pash_compiled_script_file}
            # source ${pash_compiled_script_file}
            pash_runtime_final_status=$?
        fi
    fi
fi
## Source back the output variables of the compiled script. 
## In all cases we should have executed a script
source pash_source_declare_vars.sh $pash_output_variables_file

pash_exec_time_end=$(date +"%s%N")

## TODO: Maybe remove the temp file after execution

## We want the execution time in milliseconds
if [ "$pash_output_time_flag" -eq 1 ]; then
    pash_exec_time_ms=$(echo "scale = 3; ($pash_exec_time_end-$pash_exec_time_start)/1000000" | bc)
    >&2 echo "Execution time: $pash_exec_time_ms  ms"
fi

>&2 echo "Final status: $pash_runtime_final_status"
(exit "$pash_runtime_final_status")