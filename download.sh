#!/usr/bin/env bash
set -Eeu

declare -a tmpfiles=()
cleanup(){
	rm -rf "${tmpfiles[@]}"
}
trap cleanup EXIT
get_route_urls(){
	curl 'https://www.ns.nl/dagje-uit/wandelen' -sS | xmllint --html - 2>/dev/null --xpath 'string(//*[local-name()="app-dagjeuit"]/@appdata)' | jq -r '.results[].url | "https://www.ns.nl\(.)"'
}

get_gpx_urls(){
	local url
	for url in "${@}"; do
		( curl -SLs "${url}" | grep -oE '[^"]+\.gpx' ) &
	done
	wait
}

get_gpx_files(){
	local url
	for url in "${@}"; do
		local file="$(mktemp)"
		tmpfiles+=("${file}")
		curl -SLs "${url}" -o "${file}" &
	done
	wait
}
readarray -t urls < <(get_route_urls)
readarray -t gpx_urls < <(get_gpx_urls "${urls[@]}")

get_gpx_files "${gpx_urls[@]}"

{
	head -n2 <"${tmpfiles[0]}"
	xmllint --format "${tmpfiles[@]}" | sed -ne '/<trk>/,/<\/trk>/p'
	tail -n1 <"${tmpfiles[0]}"
} | xmllint --noblanks -
