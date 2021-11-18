#!/usr/bin/env bash
#
#   Update the chart corresponding to the git tag with a new version number,
#   Package with helm and update the index,
#   Create a git commit containing these actions
#

# Get particular image being built from the tag name
# Expected tag format is: image_full-vendor-path_application-name_version
# e.g. php-7.1-fpm_drupal-8_12

IFS="_" read -ra TAG <<< "$CIRCLE_TAG"

index=0
for val in "${TAG[@]}"; do
    if [ $index -eq 0 ]; then
        CHARTNAME=$val
    fi
    if [ $index -eq 1 ]; then
        VERSION=$val
    fi
    ((index++))
done

echo "Circle tag is $CIRCLE_TAG, chartname: $CHARTNAME, version: $VERSION"

# Always add a newline in case the chart author doesn't terminate the file with one.
echo "" >> ./$CHARTNAME/Chart.yaml
echo "version: $VERSION" >> ./$CHARTNAME/Chart.yaml

cat ./$CHARTNAME/Chart.yaml

helm package --destination . ./$CHARTNAME

ls -lah

git checkout .
git fetch origin gh-pages
git checkout gh-pages

helm repo index . --url https://favish.github.com/helm-charts

git config --global user.name "favish-ci"
git config --global user.email "dev@favish.com"

git add .
git commit -m "Create $CHARTNAME version $VERSION [ci skip]"
git push origin gh-pages


