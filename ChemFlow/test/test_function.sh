#!/usr/bin/env bash

function assertFileExits(){
    if [ -z ${msg} ] ; then
        msg=""
    fi
    if [ ! -s ${FILE} ] ; then
        echo ---------------------------------------------------
        echo
        echo "FAIL: ${TEST}. ${msg}" ;
        echo "AssertionError: File ${FILE} does not exist" ;
        echo
        echo ---------------------------------------------------
    fi
}

function assertOutputIsExpected(){
    if [ -z ${msg} ] ; then
        msg=""
    fi
    if [ "${output}" != "${expected}" ] ; then
        echo ----------------------------------------------------
        echo
        echo "FAIL: ${TEST}. ${msg}" ;
        echo "AssertionError: Output : ${output} != ${expected}" ;
        echo
        echo ----------------------------------------------------
    fi
}