#!/usr/bin/env bash

function assertFileExits(){
    if [ ! -s ${FILE} ] ; then
        echo "FAIL: ${TEST}. ${msg}" ;
        echo "AssertionError: File ${FILE} does not exist" ;
        exit 2
    fi
}