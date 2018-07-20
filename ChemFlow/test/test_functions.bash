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

function assertFilesAreNew(){
    if [[ -z ${msg} ]] ; then
        msg=""
    fi
    if [[ -z ${dir} ]] ; then
        dir="test.chemflow/"
    fi
    output=`find ${dir} -type f -newermt "$(date '+%Y-%m-%d %H:%M:%S' -d '3 minute ago')"`
    output=`echo ${output}`
    if [[ "${output}" != "${expected}" ]] ; then
        echo ----------------------------------------------------
        echo
        echo "FAIL: ${TEST}. ${msg}" ;
        echo "AssertionError: New files : ${output} != ${expected}" ;
        echo
        echo ----------------------------------------------------
        error="true"
    fi
}