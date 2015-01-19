#!/bin/sh
#################################################################################
## Launch a spring batch with the current date (special format) as a parameter ##
#################################################################################
## To declare this batch in cron table, launch it with parameter 
## date today=$(TZ='<Zone1>/<Zone2>' date +%Y-%m-%d_%H:00:00)
## Example : today=$(TZ='Europe/London' date +%Y-%m-%d_%H:00:00)
## refer to tzselect(1) for timezones doc

#add logs functions
. /lib/lsb/init-functions

#Fonctions d'aide
help(){
  cat <<HELP
start-spring-batch-date -- launch a spring batch that takes a date as a parameter.

USAGE: start-spring-batch-date [OPTIONS] [BASE_DIR] [A_DATE]

OPTIONS:
	-h help message
	-f force a restart of a batch that has already been executed at least once (append the current timestamp as a "run.time" jobparameter)
EXAMPLE: 
start-spring-batch-date . '2014-12-10_13:00:00'
will launch the spring batch using the date '2014-12-10_13:00:00' as a job parameter.

start-spring-batch-date -f . '2014-12-10_13:00:00'
will force a restart for the spring batch using the date '2014-12-10_13:00:00' as a job parameter.

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

# PARAMETERS
BATCH_BASE="$1"
if [ -z "$BATCH_BASE" ]; then
  info "BATCH_BASE is forced to ."
  BATCH_BASE="."
fi
info "`date` BATCH_BASE : $BATCH_BASE "

A_DATE="$3"
if [ -z "$A_DATE" ]; then
  error "A_DATE is not set"
fi
info "A_DATE : $A_DATE "

# maybe we can have some properties file to include
#CONF_FILE="$BATCH_BASE/conf/spring-batch.properties"
#if [ -z "$CONF_FILE" ]; then
#  error "CONF_FILE is not set"
#fi
#info "CONF_FILE : $CONF_FILE "

EXTRA_PARAMETERS=""
if [ opt_force_restart ]; then
  info "FORCE_RESTART is set"
  EXTRA_PARAMETERS="run.time=`date +%s`"
fi
info "EXTRA_PARAMETERS : $EXTRA_PARAMETERS "

# ENVIRONNEMENT VARIABLES
PATH=/bin:/usr/bin:/sbin:/usr/sbin
JAVA_HOME=$JAVA_HOME
EXECUTABLE=bin/java
JAVA_OPTS="-server -Djava.awt.headless=true -Xmx1024M -Xms1024M "
JAVA_OPTS="$JAVA_OPTS -Dhostname=`hostname` -Dbatch.base=$BATCH_BASE " #-Dlogback.configurationFile=$BATCH_BASE/conf/logback.xml " if we need logback conf
# we suppose dependencies libs are in "$BATCH_BASE/lib" folder and the main batch jar is in a separate "$BATCH_BASE/my-spring-bactch" folder (may be useful if we have several batches in the same root folder).
JAVA_CLASSPATH="$(echo ${BATCH_BASE}/lib/*.jar . | sed 's/ /:/g')"
JAVA_CLASSPATH="$(echo ${BATCH_BASE}/my-spring-bactch/*.jar . | sed 's/ /:/g')$JAVA_CLASSPATH"


info "JAVA_HOME : $JAVA_HOME - JAVA_OPTS : $JAVA_OPTS"

# check JAVA_HOME
if [ -z "$JAVA_HOME" ]; then
  error "JAVA_HOME is not set"
fi

# Check that target executable exists
if [ ! -x "$JAVA_HOME"/"$EXECUTABLE" ]; then
    error "Cannot find $JAVA_HOME/$EXECUTABLE \
    This file is needed to run this program"
fi

info "$JAVA_HOME/$EXECUTABLE $JAVA_OPTS -classpath $JAVA_CLASSPATH org.springframework.batch.core.launch.support.CommandLineJobRunner myBatchJob.xml myBatchJob a.date=$A_DATE $EXTRA_PARAMETERS"
exec "$JAVA_HOME"/"$EXECUTABLE" $JAVA_OPTS -classpath $JAVA_CLASSPATH \
        org.springframework.batch.core.launch.support.CommandLineJobRunner \
        myBatchJob.xml myBatchJob a.date=$A_DATE $EXTRA_PARAMETERS
