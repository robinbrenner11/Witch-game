#!/usr/bin/env bash
# Installiert Godot (Linux, headless nutzbar) für Cloud-Sessions und CI.
# Aufruf aus dem Repo-Wurzelordner:  bash tools/setup_godot.sh
# Andere Version:                    GODOT_VERSION=4.7.1 bash tools/setup_godot.sh
#
# Danach liegt `godot` in ~/.local/bin. Lokal unter Windows brauchst du das nicht.
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.7.2}"
BIN_DIR="${HOME}/.local/bin"
NAME="Godot_v${GODOT_VERSION}-stable_linux.x86_64"
URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/${NAME}.zip"

if command -v godot >/dev/null 2>&1 && godot --version 2>/dev/null | grep -q "^${GODOT_VERSION}"; then
	echo "Godot ${GODOT_VERSION} ist schon da: $(command -v godot)"
	exit 0
fi

mkdir -p "${BIN_DIR}"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

echo "Lade Godot ${GODOT_VERSION} …"
curl -fsSL -o "${TMP}/godot.zip" "${URL}"
python3 -m zipfile -e "${TMP}/godot.zip" "${TMP}/out"
install -m 755 "${TMP}/out/${NAME}" "${BIN_DIR}/godot"

case ":${PATH}:" in
	*":${BIN_DIR}:"*) ;;
	*) echo "Hinweis: ${BIN_DIR} ist nicht im PATH. export PATH=\"${BIN_DIR}:\$PATH\"" ;;
esac

"${BIN_DIR}/godot" --version
echo "Fertig. Einmal importieren: godot --headless --import"
