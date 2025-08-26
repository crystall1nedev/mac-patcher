#!/bin/bash
# made by eva with <3

welcome() {
    if [[ ${RECOVERY} != "1" ]]; then clear; fi
    echo "Shitass Patcher:tm:"
    OS=$(sw_vers | sed '2,3d' | cut -b 15-64)
    HOST_VERSION=$(sw_vers | sed '1,1d' | sed '2,2d' | cut -b 18-64)
    HOST_BUILD=$(sw_vers | sed '1,2d' | cut -b 16-64)
    # The capability of man is too great
    if [[ $OS != "macOS" ]]; then echo "mf what you doing trying to run this on another os"; exit 1; fi
    echo "Running on $OS $HOST_VERSION (build $HOST_BUILD)"
    if [[ ${NO_SANITY} == "1" && ${DIRECTORY} != "" ]]; then OGDIR=$DIRECTORY; VALIDDIR=1; else
    if [[ -z ${DIRECTORY} || ! -d ${DIRECTORY} ]]; then DIRECTORY=$(dirname "$(realpath "$0")"); VALIDDIR=0; else VALIDDIR=1; fi
    fi
    if [[ ${NO_SANITY} == "1" && ${SYSTEM} != "" ]]; then OGSYS=$SYSTEM; VALIDSYS=1; else
    if [[ -z ${SYSTEM} || ! -f ${SYSTEM}/System/Library/CoreServices/SystemVersion.plist ]]; then SYSTEM="/Volumes/Macintosh HD"; VALIDSYS=0; else echo "--system specified; ${SYSTEM}"; fi
    fi
    if [[ -f "${SYSTEM}/System/Library/CoreServices/SystemVersion.plist" ]]; then
        TARGET_VERSION=$(plutil -convert json "${SYSTEM}"/System/Library/CoreServices/SystemVersion.plist -o - | jq ."ProductVersion" | sed s/\"//g)
        TARGET_BUILD=$(plutil -convert json "${SYSTEM}"/System/Library/CoreServices/SystemVersion.plist -o - | jq ."ProductBuildVersion" | sed s/\"//g)
        VALIDTARGET=1
    else
        TARGET_VERSION=$HOST_VERSION; TARGET_BUILD=$HOST_BUILD; VALIDTARGET=0
    fi
    echo "Patching for $OS $TARGET_VERSION (build $TARGET_BUILD)"
    echo ""
    echo "Made by Eva with <3"
    echo ""
    if [[ ${RECOVERY} != "1" && $(id -u) != "0" ]]; then echo "This script needs to be run with sudo when not in recoveryOS."; exit 1; fi
}

goodbye() {
    echo "Thank you for using Shitass Patcher:tm:"
}

showopts() {
    echo """--help                Show this help and exit.
--help-data           Prints information about how this script looks for files and uses them.
--data [path]         Specify a custom directory for patch files.
--system [path]       Specifies a custom mount path for the system volume.
--graphics            Installs graphics patches. Values: [ivy,hsw,bdw,skl,gcn,gcn4,kep] 
--audio               Installs audio patches.
--wifi                Installs WiFi patches.
--t1                  Installs Apple T1 chip patches.
--kdk                 Installs kdk.pkg or kdk.dmg in the patch directory.
--recovery            Indicate that you are patching from recoveryOS.
--no-interaction      Indicate that you do not want to be asked for each patchset.
--more-interaction    Indicate that you want to be asked to run every command.
--revert              Undo all patching and restore the system volume to the defaults.

There are various other undocumented options.
If you need to use them, you should be able to read this script.
"""
    exit 0
}

showdatahelp() {
    echo """The --help-data flag shows you how to set up your environment for patching with
this script.

By default, the script is designed to look for patches in a folder called \"${TARGET_BUILD}\"
contained in the same directory as the script. If your patches are stored in another
directory, you can specify this via the --data argument, followed by the path.

Inside of this directory, you'll need to have specific subdirectories containing the
patches themselves. Which ones you need depends on the hardware you ask for:
|- ${TARGET_BUILD}/graphics/hsw       - Haswell integrated graphics.
|- ${TARGET_BUILD}/graphics/bdw       - Broadwell integrated graphics.
|- ${TARGET_BUILD}/graphics/skl       - Skylake integrated graphics.
|- ${TARGET_BUILD}/graphics/gcn       - AMD GCN discrete graphics.
|- ${TARGET_BUILD}/graphics/gcn4      - AMD Polaris discrete graphics.
|- ${TARGET_BUILD}/graphics/kep       - NVIDIA Kepler discrete graphics.
|- ${TARGET_BUILD}/graphics/metallibs - Metallibs for 3802-based graphics.
|- ${TARGET_BUILD}/audio              - Audio patches.
|- ${TARGET_BUILD}/wifi               - Wireless patches.
|- ${TARGET_BUILD}/t1                 - Apple T1 chip patches.

Inside of these folders, you'll need to make a directory structure that mirrors where
you want the file to go. Some examples are provided below:
|- ${TARGET_BUILD}/audio/System/Library/Extensions/AppleHDA.kext
|- ${TARGET_BUILD}/graphics/hsw/System/Library/PrivateFrameworks/AppleGVA.framework
|- ${TARGET_BUILD}/wifi/usr/libexec/wifip2pd

Additionally, it's a good idea to have a Kernel Debug Kit on hand, even if you aren't
going to be installing it with this script. This script prefers ${TARGET_BUILD}/kdk.pkg,
however it will also accept ${TARGET_BUILD}/kdk.dmg.
 - If one isn't available for your build, you can try and use one from an earlier build.
    """
    goodbye; exit 0
}

engagedefaults() {
    MODEL="Macmini7,1"; GRAPHICS=("hsw"); AUDIO=1; WIFI=1; KDK=1; RECOVERY=1; INTERACTION=0;
    if [[ -z ${DIRECTORY} ]]; then DIRECTORY="/Volumes/Storage/OCLP"; fi
    if [[ -z ${SYSTEM} ]]; then SYSTEM="/Volumes/Macintosh\ HD"; fi
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -d|--data)
      if [[ "$2" != *"--"* ]]; then DIRECTORY="$2"; fi; if [[ ${DIRECTORY: -1} == "/" ]]; then DIRECTORY="${DIRECTORY%?}"; fi; shift; shift ;;
    -s|--system)
      if [[ "$2" != *"--"* ]]; then SYSTEM="$2"; fi; if [[ ${SYSTEM: -1} == "/" ]]; then SYSTEM="${SYSTEM%?}"; fi; shift; shift ;;
    -m|--model)
      if [[ "$2" != *"--"* ]]; then MODEL="$2"; fi; shift; shift ;;
    -g|--graphics)
      if [[ "$2" != *"--"* ]]; then IFS=',' read -ra GRAPHICS <<< "$2"; fi; shift; shift ;;
    -a|--audio)
      AUDIO=1; shift ;;
    -w|--wifi)
      WIFI=1; shift ;;
    --t1)
      T1=1; shift ;;
    --kdk)
      KDK=1; shift ;;
    --recovery)
      RECOVERY=1; shift ;;
    --no-interaction)
      if [[ ${MORE_INTERACTION} == "1" ]]; then welcome; echo "--more-interaction and --no-interaction can't be used at the same time."; exit 1; fi; INTERACTION=0; shift ;;
    --more-interaction)
      if [[ ${INTERACTION} == "0" ]]; then welcome; echo "--no-interaction and --more-interaction can't be used at the same time."; exit 1; fi; MORE_INTERACTION=1; shift ;;
    --revert)
      REVERT=1; shift ;;
    --help)
      welcome; showopts; shift ;;
    --help-data)
      welcome; showdatahelp; shift ;;
    --dry-run)
      DRYRUN=1; shift ;;
    --disable-sanitychecks)
      NO_SANITY=1; shift ;;
    --socamx)
      DIRECTORY="/Volumes/Extras/Tahoe_Test_Patches"; SYSTEM="/Volumes/Tahoe"; shift ;;
    -*|--*)
      welcome; echo "Unknown option $1"; echo ""; showopts; exit 1 ;;
    *)
      POSITIONAL_ARGS+=("$1"); shift ;;
  esac
done

dofunction() {
    local FUNCTION=$1
    case $FUNCTION in
        mount) MESSAGE="mount the system volume"; shift ;;
        kdk) MESSAGE="begin KDK installation"; shift ;;
        graphics) MESSAGE="begin graphics patching"; shift ;;
        audio) MESSAGE="begin audio patching"; shift ;;
        wifi) MESSAGE="begin wireless patching"; shift ;;
        t1) MESSAGE="begin T1 Security Chip patching"; shift ;;
        finish) MESSAGE="finish patch installation"; shift ;;
        revert) MESSAGE="restore SSV"; shift ;;
        *) MESSAGE="How did you get here?"; exit 1; shift ;;
    esac
    if [[ ${INTERACTION} == "1" ]]; then read -n 1 -s -r -p "Press any key to $MESSAGE..."; echo ""; else echo "Preparing to $MESSAGE in 5 seconds..."; sleep 5; fi
    for ((i = 0; i < ${#COMMANDS[@]}; i++)); do
        if [[ ${DRYRUN} == "1" ]]; then echo "  ${COMMANDS[$i]}"; else
        if [[ ${MORE_INTERACTION} == "1" ]]; then read -n 1 -s -r -p "Press any key to run the following command: ${COMMANDS[$i]}"; echo ""; fi
        eval "${COMMANDS[$i]}"; fi
        echo "wait"
    done
    COMMANDS=()
}

copypatches() {
    local DIR=$1
    COMMANDS+=( "cp -rv \"${DIRECTORY}/${TARGET_BUILD}\"/${DIR}/ \"${SYSTEM}\"/");
}

revert_function() {
    COMMANDS=( "bless --folder \"${SYSTEM}\"/System/Library/CoreServices --bootefi --last-sealed-snapshot")
    dofunction "revert"
    echo ""
}

mount_function() {
    COMMANDS=()
    if [[ ${RECOVERY} == "1" ]]; then
        COMMANDS=( "mount -uw \"${SYSTEM}\"" )
    else
        DISKID=$(diskutil info -plist "${SYSTEM}" | plutil -convert json -o - -- - | jq .DeviceIdentifier | sed s/\"//g)
        ISSNAPSHOT=$(diskutil info -plist / | plutil -convert json -o - -- - | jq .APFSSnapshot)
        if [[ ${ISSNAPSHOT} == "true" ]]; then
            DISKID=${DISKID%??}
        fi
        COMMANDS=( "mount -t apfs -o nobrowse /dev/${DISKID} /System/Volumes/Update/mnt1" )
        SYSTEM="/System/Volumes/Update/mnt1"
    fi
    dofunction "mount"
    echo ""
}

kdk_function() {
    COMMANDS=( "rm -rfv \"${SYSTEM}\"/Library/Developer/KDKs/KDK_${TARGET_VERSION}_*.kdk" )
    if [[ ${KDKPKG} != "1" ]]; then COMMANDS+=(
        "hdiutil attach \"${DIRECTORY}/${TARGET_BUILD}\"/kdk.dmg"
        "installer -pkg /Volumes/Kernel\ Debug\ Kit/KernelDebugKit.pkg -target \"${SYSTEM}\"" )
    else COMMANDS+=( "installer -pkg \"${DIRECTORY}/${TARGET_BUILD}\"/kdk.pkg -target \"${SYSTEM}\"" ); fi
    COMMANDS+=( "ditto -Vv \"${SYSTEM}\"/Library/Developer/KDKs/KDK_${TARGET_VERSION}_*.kdk/System/Library/Extensions \"${SYSTEM}\"/System/Library/Extensions" )
    dofunction "kdk"
    echo ""
}

graphics_function() {
    COMMANDS=()
    if [[ ${METALLIBS} == "1" ]]; then copypatches "graphics/metallibs"; fi
    for ((i = 0; i < ${#GRAPHICS[@]}; i++)); do copypatches "graphics/${GRAPHICS[$i]}"; done
    dofunction "graphics"
    echo ""
}

audio_function() {
    copypatches "audio"
    dofunction "audio"
    echo ""
}

wifi_function() {
    copypatches "wifi"
    dofunction "wifi"
    echo ""
}

t1_function() {
    copypatches "t1"
    dofunction "t1"
    echo ""
}

finish_function() {
    COMMANDS=()
    if [[ (! -z ${GRAPHICS[0]} || ${AUDIO} == "1" ) || ${RECOVERY} == "1" ]]; then COMMANDS+=( "kmutil create --allow-missing-kdk --volume-root \"${SYSTEM}\" --update-all --variant-suffix release" ); fi
    COMMANDS+=( "bless --folder \"${SYSTEM}\"/System/Library/CoreServices --bootefi --create-snapshot" )
    dofunction "finish"
    echo ""
}

POSITIONAL_ARGS=()

welcome

if [[ ${DRYRUN} == "1" ]]; then echo "--dry-run specified; will only print commands"; fi
if [[ ${NO_SANITY} == "1" ]]; then echo "--disable-sanitychecks specified; bold of you to assume this works fine"; fi
if [[ -z ${INTERACTION} ]]; then INTERACTION=1; echo "--no-interaction was not given; defaulting to interactive mode"; else echo "--no-interaction specified; will not prompt for anything"; fi
if [[ ${MORE_INTERACTION} == "1" ]]; then echo "--more-interaction specified; will be more annoying"; fi
if [[ ${DRYRUN} == "1" || ${NO_SANITY} == "1" ]]; then echo ""; fi
if [[ ${VALIDDIR} == "1" || ${NO_SANITY} == "1" ]]; then echo "--data specified; ${DIRECTORY}"; else echo "--data not given or invalid; assuming ${DIRECTORY}"; fi
if [[ ${VALIDSYS} == "1" || ${NO_SANITY} == "1" ]]; then echo "--system specified; ${SYSTEM}"; else echo "--system not given or invalid; assuming ${SYSTEM}"; fi
if [[ ${RECOVERY} == "1" ]]; then echo ""; echo "--recovery specified; will remount ${SYSTEM}"; fi

echo ""
if [[ ${VALIDTARGET} != "1" ]]; then
    if [[ ${NO_SANITY} == "1" ]]; then echo "--system (or the default) does not have SystemVersion.plist";
    else echo "--system (or the default) does not have SystemVersion.plist; check your command."; exit 1; fi
fi

if [[ ${REVERT} != "1" ]]; then
if [[ -z ${KDK} && ${RECOVERY} == "1" ]]; then echo "--kdk is implied when running in recoveryOS"; KDK=1;
    if [[ ${KDK} == "1" && -f ${DIRECTORY}/${TARGET_BUILD}/kdk.pkg ]]; then KDKPKG=1; fi
fi
if [[ ${NO_SANITY} != "1" && ! -d ${DIRECTORY}/${TARGET_BUILD} ]]; then echo "couldn't find ${DIRECTORY}/${TARGET_BUILD}; check your files"; exit 1; fi
echo ""

if [[ -f $(dirname "$(realpath "$0")")/models ]]; then source $(dirname "$(realpath "$0")")/models
else echo "--model cannot be used as the models file is missing"; echo ""; MODEL=""; fi
if [[ ${MODEL} != "" ]]; then
GRAPHICS=(); AUDIO=0; WIFI=0; T1=0
case ${MODEL} in
    Macmini*) modeldefaults_macmini; shift ;;
    iMac*) modeldefaults_imac; shift ;;
    MacBook[1-10]*) modeldefaults_macbook; shift ;;
    MacBookPro*) modeldefaults_macbookpro; shift ;;
    MacBookAir*) modeldefaults_macbookair; shift ;;
    iMacPro1,1) modeldefaults_imacpro; shift ;;
    MacPro*) modeldefaults_macpro; shift ;;
    *) FAMILY="invalid"; shift ;;
esac
if [[ ${FAMILY} == "invalid" ]]; then echo ""; echo "--model resolution failed, check your command"; exit 1; fi
if [[ ${UNSUPPORTED} == "1" ]]; then echo ""; echo "--model ${MODEL} couldn't be resolved because it isn't supported"; exit 1; fi
echo "--model ${MODEL} was resolved to ${FAMILY} ${MAKE}"
echo ""
fi

if [[ -z ${GRAPHICS[0]} && ${AUDIO} != "1" && ${WIFI} != "1" && ${T1} != "1" ]]; then echo "--model Macmini7,1 will be set as no patches were requested"; echo ""; engagedefaults; fi

for ((i = 0; i < ${#GRAPHICS[@]}; i++)); do
    case ${GRAPHICS[$i]} in
        ivy) echo "--graphics ivy; will install Ivy Bridge graphics support"; METALLIBS=1; shift ;;
        hsw) echo "--graphics hsw; will install Haswell graphics support"; METALLIBS=1; shift ;;
        bdw) echo "--graphics bdw; will install Broadwell graphics support "; shift ;;
        skl) echo "--graphics skl; will install Skylake graphics support"; shift ;;
        gcn) echo "--graphics gcn; will install AMD GCN graphics support"; shift ;;
        gcn4) echo "--graphics gcn4; will install AMD Polaris graphics support"; shift ;;
        kep) echo "--graphics kep; will install NVIDIA Kepler graphics support"; METALLIBS=1; shift ;;
        *) echo "unrecognized graphics arch \"${GRAPHICS[$i]}\" given; check your command"; exit 1 ;;
    esac
    if [[ ${NO_SANITY} != "1" && ! -d ${DIRECTORY}/${TARGET_BUILD}/graphics/metallibs && ${METALLIBS} == "1" ]]; then echo "couldn't find ${DIRECTORY}/${TARGET_BUILD}/graphics/metallibs; check your files or remove --graphics ${GRAPHICS[$i]}"; exit 1; fi
    if [[ ${NO_SANITY} != "1" && ! -d ${DIRECTORY}/${TARGET_BUILD}/graphics/${GRAPHICS[$i]} ]]; then echo ""; echo "couldn't find ${DIRECTORY}/${TARGET_BUILD}/graphics/${GRAPHICS[$i]}; check your files or remove --graphics ${GRAPHICS[$i]}"; exit 1; fi
done
if [[ ${AUDIO} == "1" ]]; then echo "--audio specified; will install audio support";
if [[ ${NO_SANITY} != "1" && ! -d ${DIRECTORY}/${TARGET_BUILD}/audio ]]; then echo ""; echo "couldn't find anything at ${DIRECTORY}/${TARGET_BUILD}/audio; check your files or remove --audio"; exit 1; fi
fi
if [[ ${WIFI} == "1" ]]; then echo "--wifi specified; will install wireless support";
if [[ ${NO_SANITY} != "1" && ! -d ${DIRECTORY}/${TARGET_BUILD}/wifi ]]; then echo "couldn't find ${DIRECTORY}/${TARGET_BUILD}/wifi; check your files or remove --wifi"; exit 1; fi
fi
if [[ ${T1} == "1" ]]; then echo "--t1 specified; will install Apple T1 Chip support";
if [[ ${NO_SANITY} != "1" && ! -d ${DIRECTORY}/${TARGET_BUILD}/t1 ]]; then echo "couldn't find ${DIRECTORY}/${TARGET_BUILD}/t1; check your files or remove --t1"; exit 1; fi
fi
if [[ ${KDK} == "1" && -f ${DIRECTORY}/${TARGET_BUILD}/kdk.pkg ]]; then KDKPKG=1; fi
if [[ ${KDK} == "1" && ${KDKPKG} == "1" ]]; then echo "--kdk specified; will install kdk from ${DIRECTORY}/${TARGET_BUILD}/kdk.pkg"; fi
if [[ ${KDK} == "1" && ${KDKPKG} != "1" ]]; then echo "--kdk specified; will install kdk from ${DIRECTORY}/${TARGET_BUILD}/kdk.dmg";
if [[ ${NO_SANITY} != "1" && ! -f ${DIRECTORY}/${TARGET_BUILD}/kdk.dmg ]]; then echo "couldn't find ${DIRECTORY}/${TARGET_BUILD}/kdk.dmg; check your files or remove --kdk"; exit 1; fi
fi


echo ""
if [[ ! -z ${GRAPHICS[2]} ]]; then echo "Three gpu archs given; only a max of two are supported"; exit 1; fi

set -- "${POSITIONAL_ARGS[@]}"

if [[ ${INTERACTION} == "1" ]]; then
    read -n 1 -s -r -p "Press any key to begin patching..."
else
    echo "Patching will begin in 5 seconds..."
    sleep 5
fi

echo ""; echo ""

mount_function
if [[ ${KDK} == "1" ]]; then kdk_function; fi
if [[ ! -z ${GRAPHICS[0]} ]]; then graphics_function; fi
if [[ ${AUDIO} == "1" ]]; then audio_function; fi
if [[ ${WIFI} == "1" ]]; then wifi_function; fi
if [[ ${T1} == "1" ]]; then t1_function; fi
finish_function

else
echo ""; echo "--revert specified; will now undo all patches"; echo ""
if [[ ${INTERACTION} == "1" ]]; then
    read -n 1 -s -r -p "Press any key to begin reverting..."
else
    echo "Reverting will begin in 5 seconds..."
    sleep 5
fi

echo ""; echo ""

if [[ ${RECOVERY} == "1" ]]; then mount_function; fi
revert_function
fi

goodbye
