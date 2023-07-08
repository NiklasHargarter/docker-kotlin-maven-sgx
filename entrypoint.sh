#!/bin/sh

/aesmd.sh

gramine-sgx-get-token --output kotlin.token --sig kotlin.sig
gramine-sgx kotlin