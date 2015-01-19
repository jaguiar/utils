#!/bin/bash

### Courtesy of Yaourtcorp - Beware, this scripts uses some initScriptFunction, comment the following line to disable it
### Launch a suite of (Spring) batches one after the other
### Use a FAIL_ON_ERROR parameter to decide if we shall stop when a batch fails or continue anyway. This parameter is set to "false" by default.

#add functions logs
. /lib/lsb/init-functions

#Help function to adapt
help(){
  cat <<HELP
execute-all-batches -- launch a suite of (Spring) batches one after the other.

USAGE: execute-all-batches [OPTIONS] [BASE_DIR] [FAIL_ON_ERROR]

OPTIONS:
	-h help message
	-f force a restart of batches that have already been executed at least once (ask each batch to force the restart mode)
EXAMPLE: 
execute-all-batches . true
will launch the batches suite with the current folder as the "root folder" and stops if (and after) a batch fails.

execute-all-batches -f '/opt/mybatches' 
will force a restart of the batches suite with the folder "opt/mybatches" as the "root folder" and will not stop if some batches fail.

HELP
  exit 0
}
error(){
    # print an error and exit
    log_failure_msg "`date` $1"
    exit 1
}
info(){
    # print an information message
    echo "`date` $1"
}
# The option parser
# -h take no arguments
while [ -n "$1" ]; do
case $1 in
    -h) help;shift 1;; # function help is called
    -f) opt_force_restart=1;shift 1;; # variable opt_force_restart is set
    --) shift;break;; # end of options
    -*) error "error: no such option $1. -h for help";exit 1;;
    *)  break;;
esac
done

# command line parameters 
BATCHES_ROOT_FOLDER=$1
FAIL_ON_ERROR=$2
# put extra command line parameters here 

# script to launch each batches, consider using a list or a pattern if there are lots of them
SCRIPT_FOR_BATCH_1="start-batch-1.sh"
SCRIPT_FOR_BATCH_2="start-batch-2.sh"
SCRIPT_FOR_BATCH_N="start-batch-N.sh"

if [ -z "$BATCHES_ROOT_FOLDER" ]; then
  info "BATCHES_ROOT_FOLDER is forced to ."
  BATCHES_ROOT_FOLDER=.
fi
info "BATCHES_ROOT_FOLDER : $BATCHES_ROOT_FOLDER "

if [ -z "$FAIL_ON_ERROR" ]; then
  info "FAIL_ON_ERROR is forced to false"
  FAIL_ON_ERROR="false"
fi
info "FAIL_ON_ERROR : $FAIL_ON_ERROR "

FORCE_RESTART_PARAM=""
if [ opt_force_restart ]; then
  info "FORCE_RESTART is set"
  FORCE_RESTART_PARAM="-f"
fi

# test extra parameters here

# PUT OTHER ENVIRONNEMENT VARIABLES
PATH=/bin:/usr/bin:/sbin:/usr/sbin
#JAVA_HOME=$JAVA_HOME

BATCH1_START=`date +%s`
info "Starting batch 1: BATCHES_ROOT_FOLDER=$BATCHES_ROOT_FOLDER [DECLARE OTHER PARAMS HERE]"
$BATCHES_ROOT_FOLDER/$SCRIPT_FOR_BATCH_1 $FORCE_RESTART_PARAM $BATCHES_ROOT_FOLDER #add params
failed=$?
BATCH1_END=`date +%s`
info "End of batch 1 failed=$failed FAIL_ON_ERROR=$FAIL_ON_ERROR in $(($BATCH1_END-$BATCH1_START)) ms"

if [ $FAIL_ON_ERROR = "true" ]; then
    if [ $failed != 0 ]; then
        error "Erreur with batch $SCRIPT_FOR_BATCH_1"
        exit 1
    fi
fi

BATCH2_START=`date +%s`
info "Starting batch 2: BATCHES_ROOT_FOLDER=$BATCHES_ROOT_FOLDER [DECLARE OTHER PARAMS HERE]"
$BATCHES_ROOT_FOLDER/$SCRIPT_FOR_BATCH_2 $FORCE_RESTART_PARAM $BATCHES_ROOT_FOLDER #add params
failed=$?
BATCH2_END=`date +%s`
info "End of batch 2 failed=$failed FAIL_ON_ERROR=$FAIL_ON_ERROR in $(($BATCH2_END-$BATCH2_START)) ms"

if [ $FAIL_ON_ERROR = "true" ]; then
    if [ $failed != 0 ]; then
        error "Erreur with batch $SCRIPT_FOR_BATCH_2"
        exit 1
    fi
fi

BATCHN_START=`date +%s`
info "Starting batch N: BATCHES_ROOT_FOLDER=$BATCHES_ROOT_FOLDER [DECLARE OTHER PARAMS HERE]"
$BATCHES_ROOT_FOLDER/$SCRIPT_FOR_BATCH_N $FORCE_RESTART_PARAM $BATCHES_ROOT_FOLDER #add params
failed=$?
BATCHN_END=`date +%s`
info "End of batch N  failed=$failed FAIL_ON_ERROR=$FAIL_ON_ERROR in $(($BATCHN_END-$BATCHN_START)) ms"

if [ $FAIL_ON_ERROR = "true" ]; then
    if [ $failed != 0 ]; then
        error "Erreur with batch $SCRIPT_FOR_BATCH_N"
        exit 1
    fi
fi

veryEnd=`date +%s`
info "End of batches suite, BATCHES_ROOT_FOLDER=$BATCHES_ROOT_FOLDER in $(($veryEnd-$BATCH1_START)) ms"
exit 0
