#!/usr/bin/env bash

# set the target server and path for scp
# this is my raspberry, hosting my website. This will only work from my
# local wifi network, so be sure to set your own server.
target="vosje@raspberrypi:/home/vosje/https/httpssite/vlibman/images/"
echo "target host: $target"
echo "Press control-c now if incorrect." && sleep 1

stdir="$PWD"
imagename="$(date +%s)"

function cleanup {
    echo "Cleaning up..."
    cd "$stdir" || { exit; }
    rm -vrf "images/$imagename/"
    echo 'Done.'
}
    
echo "Creating vlibman image with name $imagename."
while true && ! [[ "$1" == unattended ]];do
    echo "Do you want to continue?"
    read -rsn1 -p "[y/n]? " yn
    case "$yn" in
        y|Y) break;;
        n|N) exit;;
        *) echo "enter y for yes or n for no"
    esac
done

mkdir -p "images/$imagename/"

for file in "vlibman.sh" "liblist.txt"
do cp -v "$file" "images/$imagename/$file"
done

cd "images/$imagename" || { cleanup; }
chmod u+x vlibman.sh


echo "Packing image..."
tar -cvzf "$imagename.tar.gz" -- *
mv "$imagename.tar.gz" "../$imagename.tar.gz"
echo "Done packing."
cd ..
echo "Generating checksum..."
sha256sum "$imagename.tar.gz" > "$imagename.checksum"
echo "Done."
if ! [[ "$target" == '' ]]; then
    echo "Uploading..."
    scp "$imagename.tar.gz" "$target" || { echo "Could not upload."; cleanup; exit; }
    scp "$imagename.checksum" "$target" || { echo "Could not upload."; cleanup; exit; }
    echo "Getting and modifieing versions.txt..."
    scp "$target/versions.txt" "./" || { echo "Could not download."; cleanup; exit; }
    versions="$imagename $(cat versions.txt)"
    echo "$versions" > versions.txt
    scp "versions.txt" "$target" || { echo "Could not upload."; cleanup; exit; }
fi


cleanup
echo "Image name is $imagename.tar.gz"

