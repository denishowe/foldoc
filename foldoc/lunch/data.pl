#!/bin/sh

# Runs in its own directory - /var/www/foldoc.org/lunch

echo "Access-Control-Allow-Origin: *"
echo Access-Control-Allow-Methods: PUT
echo Content-type: application/json
echo
dir=data
file=$dir/data.json
if [ $REQUEST_METHOD != PUT ]; then
  cat $file
  exit 0
fi
d=$(date --utc +%F-%H%M%S)
mkdir -p $dir
cp -f $file $dir/$d.json
cat > $file
