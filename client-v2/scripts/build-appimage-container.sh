#!/usr/bin/env bash
set -euo pipefail
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd -- "$source_dir"
output_dir=${1:-dist-appimage}
version=$(sed -n 's/^project(RuTool VERSION \([0-9.]*\).*/\1/p' CMakeLists.txt)
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Missing project version' >&2; exit 1; }
test_build_dir=${RUTOOL_TEST_BUILD_DIR:-build-linux-$version-tests}
release_build_dir=${RUTOOL_RELEASE_BUILD_DIR:-build-appimage-$version}
for path in "$test_build_dir" "$release_build_dir"; do
    [[ "$path" == build-* && "$path" != */* && "$path" != *..* ]] || { echo 'Use a build-* directory name without slashes' >&2; exit 1; }
done
[[ "$output_dir" != /* && "$output_dir" != *..* ]] || { echo 'Use a relative output directory inside client-v2' >&2; exit 1; }
[[ ! -e "$output_dir" ]] || { echo "Output already exists: $output_dir (choose a new directory)" >&2; exit 1; }
# Keep the large Qt SDK on the project disk instead of duplicating Docker layers.
mkdir -p build-linux-sdk build-linux-tools "$test_build_dir"
printf '%s\n' 11112222333344445555666677778888 > "$test_build_dir/machine-id"
docker build --target sdk-bootstrap -f packaging/linux/Dockerfile -t rutool-linux-bootstrap .
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -e LANG=C.UTF-8 \
    -e RUTOOL_BUILD_JOBS="${RUTOOL_BUILD_JOBS:-4}" \
    -v "$source_dir:/work" -v "$source_dir/build-linux-sdk:/opt/Qt" \
    -v "$source_dir/$test_build_dir/machine-id:/etc/machine-id:ro" \
    rutool-linux-bootstrap bash -c '
        set -euo pipefail
        if [[ ! -x "$QMAKE" ]]; then
            /opt/aqt/bin/aqt install-qt linux desktop 6.8.3 linux_gcc_64 \
                --outputdir /opt/Qt --modules qtimageformats qtshadertools
        fi
        ./scripts/fetch-appimage-tools.sh build-linux-tools
        ./scripts/build-linux.sh "$2"
        ./scripts/build-linux.sh "$3" -DBUILD_TESTING=OFF
        export RUTOOL_TOOLS_DIR=/work/build-linux-tools
        ./scripts/package-appimage.sh "$3" "$1"
    ' bash "$output_dir" "$test_build_dir" "$release_build_dir"
