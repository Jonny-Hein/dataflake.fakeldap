#!/usr/bin/env bash


package=dataflake.fakeldap-addepar
version=$(cat version.txt)

if [ -z "$PACKAGECLOUD_TOKEN" ]; then
  echo 'Cannot release: $PACKAGECLOUD_TOKEN must be set'
  exit 1
fi

repository='altx/addepar'
packagecloud="https://$PACKAGECLOUD_TOKEN:@packagecloud.io"
endpoint="api/v1/repos/$repository/packages.json"

# see https://git-scm.com/docs/git-sh-setup
source "$(git --exec-path)/git-sh-setup"

hint='Please commit or stash them.'

require_clean_work_tree 'release' "$hint"

if [[ ! -z "$(git ls-files --exclude-standard --others)" ]]; then
    echo 'Cannot release: You have untracked files.' >&2
    echo "$hint" >&2
    exit 1
fi

format='py2.py3-none-any.whl'
python setup.py bdist_wheel

if [[ $? != 0 ]]; then
  echo 'Package build failed: aborting.' >&2
  exit 1
fi

echo "release $package $version? (y/n): "
read confirmed

if [ "$confirmed" != 'y' ]; then
  echo "ABORTING" >&2
  exit 0
fi

# see https://blog.packagecloud.io/eng/2016/03/28/pushing-packages-to-packagecloud/
python_dist_type_id=166
normed_pkg_name="$(echo $package | tr - _)"

curl -X POST "$packagecloud/$endpoint" \
  -F "package[distro_version_id]=$python_dist_type_id" \
  -F "package[package_file]=@dist/$normed_pkg_name-$version-$format" \
  --progress-bar | tee /dev/null
