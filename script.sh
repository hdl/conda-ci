#!/bin/bash

source ./.travis/common.sh
set -e

$SPACER

start_section "info.conda.package" "Info on ${YELLOW}conda package${NC}"
conda render $CONDA_BUILD_ARGS
end_section "info.conda.package"

$SPACER

start_section "conda.check" "${GREEN}Checking...${NC}"
conda build --check $CONDA_BUILD_ARGS || true
end_section "conda.check"

$SPACER

start_section "conda.build" "${GREEN}Building..${NC}"
if [[ $TRAVIS_OS_NAME != 'windows' ]]; then
    if [[ $KEEP_ALIVE = 'true' ]]; then
        travis_wait $TRAVIS_MAX_TIME python $TRAVIS_BUILD_DIR/.travis/.travis-output.py /tmp/output.log conda build $CONDA_BUILD_ARGS
    else
        python $TRAVIS_BUILD_DIR/.travis/.travis-output.py /tmp/output.log conda build $CONDA_BUILD_ARGS
    fi
else
    # Work-around: prevent console output being mangled
    winpty.exe -Xallow-non-tty -Xplain conda build $CONDA_BUILD_ARGS 2>&1 | tee /tmp/output.log
fi
end_section "conda.build"

$SPACER

start_section "conda.build" "${GREEN}Installing..${NC}"
# Remove channels before testing installation if requested
echo "Channel and channel_priority configuration:"
conda config --show channels
conda config --show channel_priority
echo
echo "Configuration sources:"
conda config --show-sources
echo
if [[ "$BUILDONLY_CHANNELS" != "" ]]; then
    echo "Removing BUILDONLY_CHANNELS ('$BUILDONLY_CHANNELS') before installation test..."
    echo
    for CHANNEL in $BUILDONLY_CHANNELS; do
        if conda config --show channels | grep "$CHANNEL" &>/dev/null; then
            for CONDARC_FILE in $(conda config --show-sources | egrep '==> .+ <==' | cut -d' ' -f2); do
                if grep "$CHANNEL" "$CONDARC_FILE" &>/dev/null; then
                    echo -n "Removing '$CHANNEL' from '$CONDARC_FILE'."
                    conda config --file "$CONDARC_FILE" --remove channels $CHANNEL
                fi
            done
        else
            echo "WARNING: Conda wouldn't use '$CHANNEL' channel anyway!"
        fi
    done
    echo
    echo "Channel configuration after removing BUILDONLY_CHANNELS:"
    conda config --show channels
    echo
fi
# Install the package and its dependencies (not installed by default for local packages)
conda install $CONDA_OUT
conda update --only-deps $PACKAGE_NAME
end_section "conda.build"

$SPACER

start_section "conda.du" "${GREEN}Disk usage..${NC}"
du -h $CONDA_OUT
end_section "conda.du"

$SPACER

start_section "conda.clean" "${GREEN}Cleaning up..${NC}"
#conda clean -s --dry-run
end_section "conda.clean"

$SPACER
