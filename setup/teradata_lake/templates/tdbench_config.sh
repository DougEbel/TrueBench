# This file is always run before starting the TdBench JAVA program by tdbench.sh or tdbench.bat.
# It specifies which version of the JAVA program to run and which DBMS configuration file to run. 
# The setting of TdBench_DBMS may be overridden on the command line of tdbench.sh with the -d parameter.
 
export TdBench_jar_version=tdbench-8.01.04

export TdBench_DBMS=teradata_lake
[ $# = 1 ] && export TdBench_DBMS=$1

# You may put common statements across all DBMSs in this file such as prompting for passwords or cleaning up files. 




# ---------- run the platform specific file specified by TdBench_DBMS or -d parameter ----------
if [ -e tdbench_${TdBench_DBMS}_config.sh ]; then
   source tdbench_${TdBench_DBMS}_config.sh
   rc=$?
   if [ $rc != 0 ]; then echo tdbench_${TdBench_DBMS}_config.sh ended with return code $rc; fi
elif [ -n "${TdBench_DBMS}" ]; then
   echo -e \\nERROR: The file tdbench_${TdBench_DBMS}_config.sh does not exist. Use SETUP to fix tdbench_config.sh\\n
fi
