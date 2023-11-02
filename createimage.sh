#!/usr/bin/env bash

stdir="$PWD"
imagename="image-$(date +%s)"

function cleanup {
    echo "Cleaning up..."
    cd "$stdir"
    rm -vrf "images/$imagename/"
    echo 'Done.'
}
    
echo "Creating vlibman image with name $imagename."
while true;do
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


cleanup
echo "Image name is $imagename.tar.gz"

