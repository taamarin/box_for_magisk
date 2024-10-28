#!/bin/sh

# sed -i "s/$(grep -oP 'version=\K[^ ]+' module.prop)/$(cat module.prop | grep 'version=' | awk -F '=' '{print $2}')($(git log --oneline -n 1 | awk '{print $1}'))/g" module.prop
zip -r -o -X -ll box_for_root-$(cat module.prop | grep 'version=' | awk -F '=' '{print $2}').zip ./ -x '.git/*' -x 'CHANGELOG.md' -x 'update.json' -x 'build.sh' -x '.github/*' -x 'docs/*'