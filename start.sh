#!/usr/bin/env bash
BASE="$(dirname "$0")" # base dir

DRYRUN=false
INSTALL=false
CONFIG=false
RESET=false
while [ $# -gt 0 ]; do
	case "$1" in
	-h|--help)
		cat <<- EOF
		QEMU VM Starter

		Options:
		  -h, --help    : Show this help
		  -n, --dry-run : Dry-run mode
		  -i, --install : Install mode
		  -c, --conf    : Edit user.conf
		  -r, --reset   : Reset user.conf

		EOF
		exit
		;;
	-n|--dry-run)
		DRYRUN=true
		;;
	-i|--install)
		INSTALL=true
		;;
	-c|--conf*)
		CONFIG=true
		;;
	-r|--reset)
		RESET=true
		;;
	-*)
		echo "invalid argument '$1'"
		;;
	esac
	shift
done

_cmd() {
	if $DRYRUN
		then echo "$*"
		else "$@"
	fi
}

_fail() {
	echo "[ERROR] $1" >&2
	exit 1
}

if [ -f "$BASE/user.conf" ] && ! $RESET; then
	if $CONFIG; then
		"$EDITOR" "$BASE/user.conf" || _fail
		exit
	fi
	. "$BASE/default.conf" || _fail
	. "$BASE/user.conf" || _fail
else
	cat <<- EOF > "$BASE/user.conf"
	# --- user.conf ---
	# Edit this however you like.
	# After save it, run the script again.
	# =====================================

	EOF
	cat "$BASE/default.conf" >> "$BASE/user.conf" || _fail
	"$EDITOR" "$BASE/user.conf" || _fail
	exit
fi

if $DRYRUN; then
	cat <<- EOF
	=== DRYRUN Mode ===
	EOF
fi

if [[ "$IMG" =~ ^\.\/ ]]; then
	IMG="$BASE/${IMG:2}"
fi

IMG_TYPE="${IMG##*.}"  # File extension

if [ ! -f "$IMG" ]; then
	_cmd qemu-img create -f $IMG_TYPE "$IMG" $IMG_SIZE || _fail
fi

DRIVE="file="$IMG",format="$IMG_TYPE""
[ -z "$DRIVE_OPTS" ] || DRIVE="$DRIVE,$DRIVE_OPTS"

OPTS=(
	-drive "$DRIVE"
)

OPTS+=(${EXEC_OPTS[@]})

if $INSTALL; then
	OPTS+=(
		-boot d # boot from ISO first
		-cdrom "$ISO"
	)
fi

_cmd "$EXEC" "${OPTS[@]}" || _fail

