# Git 简记

## 1 切换项目 git push 提交地址

```pwd
# cd .git 文件夹 更改 confing 切换git地址
[remote "origin"]
	url = https://gitee.com/mine_1/gpmall.git 
# git 删除远程地址
 git remote rm origin
#.git 更换远程地址
 git remote add origin https://gitee.com/mine_1/gpmall.git 
# 抓取分支
 git fetch   
#把当前分支与远程分支进行关联
 git branch --set-upstream-to=origin/master
 
 see 
  https://blog.csdn.net/private66/article/details/84847623
```

## 2 打项目tag

```pwd
#打tag
     git brench master
     (1)、git tag  (展示项目的所有tag版本)
     (2)、git tag v1.0(tag新版本号) -m 'Release features'
     (3)、git push origin v1.0(tag新版本号)

see 
https://blog.csdn.net/b735098742/article/details/78935748
```

## 3 合并 fork 的仓库发生冲突

```pwd
Step 1: From your project repository, check out a new branch and test the changes.（到项目下面新建分支） 
git checkout -b mercyblitz-master master
git pull https://github.com/mercyblitz/geekbang-lessons.git master

Step 2: Merge the changes and update on GitHub. （这里到idea里合并冲突 然后切到master 上push）
git checkout master git merge --no-ff mercyblitz-master git push origin master

```

