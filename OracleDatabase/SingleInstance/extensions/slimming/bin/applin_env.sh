
applin_init()
{
    CURRENT_SCRIPT=$1
    export CURRENT_SCRIPT="$(readlink -f $CURRENT_SCRIPT)"

    CURRENT_SCRIPT_NAME="$(basename $CURRENT_SCRIPT)"

    BIN_DIR="$( cd "$( dirname "$CURRENT_SCRIPT" )" && pwd )"
    export BIN_DIR

    BASE_DIR="$( cd $BIN_DIR/.. && pwd )"
    export BASE_DIR

    APPLIN_BASE="$( grep -F -m 1 'APPLIN_BASE=' ${BASE_DIR}/.applin_base )"
    APPLIN_BASE="${APPLIN_BASE#*=}"
    APPLIN_BASE="$( realpath ${BASE_DIR}/${APPLIN_BASE} )"

    # Check for overrides in applin base
    APPLIN_BASE_OVERRIDE="$( grep -F -m 1 'APPLIN_BASE_OVERRIDE=' ${BASE_DIR}/.applin_base )"
    APPLIN_BASE_OVERRIDE="${APPLIN_BASE_OVERRIDE#*=}"

    # Check if there is a override
    APPLIN_BASE=${APPLIN_BASE_OVERRIDE:-$APPLIN_BASE}
    export APPLIN_BASE
}

launch_python_application()
{
    applin_init $1

    if [ -z "$PYTHON_BIN" ];
    then
        if which python3 >/dev/null 2>&1;
        then
            PYTHON_BIN="$(which python3)"
        else
            ERROR_MSG="$CURRENT_SCRIPT_NAME requires python3. python3 is not found in PATH."
            ERROR_MSG="$ERROR_MSG Please install python and/or modify PATH."
            echo "$ERROR_MSG"

            exit 1
        fi
    fi

    PYTHONPATH="${BASE_DIR}/lib:${APPLIN_BASE}/lib"
    export PYTHONPATH

    MAIN_SCRIPT=${CURRENT_SCRIPT}_main.py

    exec $PYTHON_BIN $MAIN_SCRIPT $@
}

launch_perl_application()
{
    applin_init $1
    shift

    if [ -z "$PERL_BIN" ];
    then
        if [ -f "/usr/bin/perl" ];
        then
            PERL_BIN=/usr/bin/perl
        else
            PERL_BIN="$(which perl)"
        fi
    fi

    PERL5LIB=$BASE_DIR/lib:$APPLIN_BASE/lib/perl5/applin/
    export PERL5LIB

    MAIN_SCRIPT=${CURRENT_SCRIPT}_main.pl

    exec $PERL_BIN $PERL_OPT $MAIN_SCRIPT $@
}
