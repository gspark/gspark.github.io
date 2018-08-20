---
title: docker镜像shell脚本备份
date: 2018-08-20 11:05:25
tags: docker
---

# docker镜像shell脚本备份

## get docker tag shell脚本

``` bash
POM_POSITION=mt-parent/pom.xml
versionNum=$(awk -v RS="</*docker.image.tag>" 'NR==2{print}' $POM_POSITION)
if [ ${#versionNum} -gt 15 ];
then exit 0
else
currentTime=$(date +%Y%m%d%H%M%S000)
commiteId=$(git rev-parse --short HEAD)
wholeTag=${versionNum}_${currentTime}_${commiteId}
echo $wholeTag
sed -i "s/<docker.image.tag>$versionNum/<docker.image.tag>$wholeTag/g" $POM_POSITION
versionNum2=$(awk -v RS="</*docker.image.tag>" 'NR==2{print}' $POM_POSITION)
echo $versionNum2
fi
```

## 构建镜像脚本

``` bash
POM_POSITION=mt-parent/pom.xml
wholeTag=$(awk -v RS="</*docker.image.tag>" 'NR==2{print}' $POM_POSITION)
docker rmi 54.223.110.70/java/mt-user:$wholeTag
```
