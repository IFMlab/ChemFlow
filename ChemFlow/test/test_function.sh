#!/usr/bin/env bash

function assertFileExits(){
    if [[ -z ${msg} ]] ; then
        msg=""
    fi
    if [[ -f ${FILE} ]] ; then
        true
    else
        echo ---------------------------------------------------
        echo
        echo "FAIL: ${TEST}. ${msg}" ;
        echo "AssertionError: File ${FILE} does not exist" ;
        echo
        echo ---------------------------------------------------
        error="true"
    fi
}

function assertOutputIsExpected(){
    if [[ -z ${msg} ]] ; then
        msg=""
    fi
    if [[ "${output}" != "${expected}" ]] ; then
        echo ----------------------------------------------------
        echo
        echo "FAIL: ${TEST}. ${msg}" ;
        echo "AssertionError: Output : ${output} != ${expected}" ;
        echo
        echo ----------------------------------------------------
        error="true"
    fi
}