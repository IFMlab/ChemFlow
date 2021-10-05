#!/usr/bin/env bash

function assertFileExits(){
    if [[ -z ${msg} ]] ; then
        msg=""
    fi
    if [[ -f ${FILE} ]] ; then
        let PASSED++
    else
        echo "[ TestFlow ] ---------------------------------------"
        echo
        echo "FAIL: ${TEST}. ${msg}" ;
        echo "AssertionError: File ${FILE} does not exist" ;
        echo
        echo "----------------------------------------------------"
        error="true"
        let FAILED++
    fi
}

function assertOutputIsExpected(){
    if [[ -z ${msg} ]] ; then
        msg=""
    fi
    if [[ "${output}" != "${expected}" ]] ; then
        echo "[ TestFlow ] ---------------------------------------"
        echo
        echo "FAIL: ${TEST}. ${msg}" ;
        echo "AssertionError: Output : ${output} != ${expected}" ;
        echo
        echo "----------------------------------------------------"
        error="true"
        let FAILED++
    else
        let PASSED++
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
        echo "[ TestFlow ] ---------------------------------------"
        echo
        echo "FAIL: ${TEST}. ${msg}" ;
        echo "AssertionError: New files : ${output} != ${expected}" ;
        echo
        echo "----------------------------------------------------"
        error="true"
        let FAILED++
    else
        let PASSED++
    fi
}