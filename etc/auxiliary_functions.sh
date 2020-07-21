###############################################################################
#
# I/O auxiliary functions
#
###############################################################################


# color definitions
txtblk='\e[0;30m' # Black - Regular
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtylw='\e[0;33m' # Yellow
txtblu='\e[0;34m' # Blue
txtpur='\e[0;35m' # Purple
txtcyn='\e[0;36m' # Cyan
txtwht='\e[0;37m' # White
bldblk='\e[1;30m' # Black - Bold
bldred='\e[1;31m' # Red
bldgrn='\e[1;32m' # Green
bldylw='\e[1;33m' # Yellow
bldblu='\e[1;34m' # Blue
bldpur='\e[1;35m' # Purple
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
unkblk='\e[4;30m' # Black - Underline
undred='\e[4;31m' # Red
undgrn='\e[4;32m' # Green
undylw='\e[4;33m' # Yellow
undblu='\e[4;34m' # Blue
undpur='\e[4;35m' # Purple
undcyn='\e[4;36m' # Cyan
undwht='\e[4;37m' # White
bakblk='\e[40m'   # Black - Background
bakred='\e[41m'   # Red
badgrn='\e[42m'   # Green
bakylw='\e[43m'   # Yellow
bakblu='\e[44m'   # Blue
bakpur='\e[45m'   # Purple
bakcyn='\e[46m'   # Cyan
bakwht='\e[47m'   # White
txtrst='\e[0m'    # Text Reset

function error_exit() {
  # $1: error string 
  echo -en "${bldred}  *** ERROR   ($0): $1\n"
  echo -en "$txtrst"
  exit 1
}

function error_message() {
  # $1: error string
  echo -en "${bldred}  *** ERROR   ($0): $1\n"
  echo -en "$txtrst"
}

function log_error_message() {
  # $1: error string
  # $2: logfile
  if [ ! -z $2 ]; then
    echo -en "*** ERROR   ($0): $1\n" >> $2 2>&1
  else
    echo -en "  ==> WARNING ($0): No log file provided!\n"
  fi
  
  echo -en "${bldred}  *** ERROR   ($0): $1\n"
  echo -en "$txtrst"
}

function log_error_exit() {
  # $1: error string
  # $2: logfile
  if [ ! -z $2 ]; then
    echo -en "*** ERROR   ($0): $1\n" >> $2 2>&1
  else
    echo -en "  ==> WARNING ($0): log_error_exit: No log file provided!\n"
  fi
  
  echo -en "${bldred}  *** ERROR   ($0): $1\n"
  echo -en "$txtrst"
  exit 1
}


function warning_message() {
  # $1: message string
  echo -en "${bldylw}  ==> WARNING ($0): $1\n"
  echo -en "${txtrst}"
}

function log_warning_message() {
  # $1: message string
  # $2: log file
  if [ ! -z $2 ]; then
    echo -en "==> WARNING ($0): $1\n" >> $2 2>&1
  else
    echo -en "  ==> WARNING ($0): log_warning_messeage: No log file provided!\n"
  fi
  
  echo -en "${bldylw}  ==> WARNING ($0): $1\n"
  echo -en "${txtrst}"

}

function info_message() {
  # $1: message string
  # $2: level (different indention levels)
  if [ -z $2 ]; then
    echo -en "${bldgrn}  --> $1 \n"
    echo -en "${txtrst}"
  else
    if [ $2 == L0 ]; then
      echo -en "  --> $1\n"
    elif [ $2 == L1 ]; then
      echo -en "      $1\n"
    elif [ $2 == L2 ]; then
      echo -en "        $1\n"
    else
      echo -en "  ==> WARNING ($0): info_message: Unknown level $2\n"
      echo -en "${bldgrn}  --> $1\n"
      echo -en "${txtrst}"
    fi
  fi
  echo -en "${txtrst}"
}

function log_info_message() {
  #$1: message string
  #$2: level  (different indention levels)
  #$3: logfile  
  
  # print to logfile 
  if [ ! -z $3 ]; then 
    if [ -z $2 ]; then
      echo -en "--> $1\n" >> $3 2>&1
    else
      echo -en "--> $1\n" >> $3 2>&1
      fi
    fi
  
  #print to screen
  if [ -z $2 ]; then
    echo -en "  --> $1\n"
  else
    if [ $2 == L0 ]; then
      echo -en "${bldgrn}  --> $1\n"
      echo -en "${txtrst}"
    elif [ $2 == L1 ]; then
      echo -en "${bldgrn}      $1\n"
    elif [ $2 == L2 ]; then
      echo -en "${bldgrn}        $1\n"
      echo -en "${txtrst}"
    else
      echo -en "  ==> WARNING ($0): log_info_message: Unknown level $2\n"
      echo -en "${bldgrn}   --> $1\n"
      echo -en "${txtrst}"
    fi
  fi
  echo -en "${txtrst}"
}

function log_only_message() {
  #$1: message string
  #$2: logfile  
  
  # check if logfile provided
  if [ ! -z $2 ]; then 
    echo -en "--> $1\n" >> $2 2>&1
  else 
    echo -en "  ==> WARNING ($0): log_only_message: No log file provided\n"
  fi
}
