#!/bin/sh

release(){
    echo "processing repository $repository"

    # taken grom xbmc-czech-sf.net
    for addonFile in $@ ; do
        dirname=$addonFile
        if [ ! -f $addonFile/addon.xml ] ; then
            echo "$addonFile/addon.xml does not exist, skipping"
            continue
        fi
        addon_id=$("$TOOLS/get_addon_attribute" "$addonFile/addon.xml" "id")
        addon_version=$("$TOOLS/get_addon_attribute" "$addonFile/addon.xml" "version")

       if [ -z "$addon_id" ] ; then
          echo "Addon id not found!" >&2
          exit 1
       fi

       if [ -z "$addon_version" ] ; then
           echo "Addon id not found!" >&2
           exit 2
       fi

       target_dir="$BUILD_DIR/$addon_id"
       if [ ! -d "$target_dir" ] ; then
           mkdir "$target_dir"
       fi
       echo "Packing $addon_id $addon_version"	

       # make package
       package="$target_dir/$addon_id-$addon_version.zip"
       if [ -e "$package" ] ; then
           rm "$package"
       fi
       zip -FS -r "$package" "$dirname" -x "*.py[oc] *.sw[onp]" ".*"

       # copy changelog file
       changelog=$(ls "$dirname"/[Cc]hangelog.txt)
       if [ -f "$changelog" ] ; then
           cp "$changelog" "$target_dir"/changelog-$addon_version.txt
       fi

       # copy icon file
       icon="$dirname"/icon.png
       if [ -f "$icon" ] ; then
           cp "$icon" "$target_dir"/
       fi
       echo

    done
}


echo 'Updating repositories'
git submodule foreach git pull origin master

TOOLS=$( cd $(dirname $0) ; pwd -P )
BUILD_DIR=$TOOLS/repo
echo "Cleaning up *.pyc files.."
find . -name '*.pyc' | xargs rm -f

repositories=$(ls -l | grep "^d" | gawk -F' ' '{print $8}')
for repository in $repositories ; do
    cd $repository
    addons=$(ls -l | grep "^d" | gawk -F' ' '{print $8}')
    release $addons
    cd ..
done
release repository.xbmc.prismcube.ruby.czsk
	
echo 'regenerating addons.xml'
python addons_xml_generator.py
