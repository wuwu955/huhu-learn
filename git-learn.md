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


## 4 回滚提交后代码

```pwd
1、git commit到本地分支、但没有git push到远程

git log # 得到你需要回退一次提交的commit id
git reset --hard <commit_id>  # 回到其中你想要的某个版
或者
git reset --hard HEAD^  # 回到最新的一次提交
或者
git reset HEAD^  # 此时代码保留，回到 git add 之前

2、git push把修改提交到远程仓库
1）通过git reset是直接删除指定的commit

git log # 得到你需要回退一次提交的commit id
git reset --hard <commit_id>
git push origin HEAD --force # 强制提交一次，之前错误的提交就从远程仓库删除

2）通过git revert是用一次新的commit来回滚之前的commit

git log # 得到你需要回退一次提交的commit id
git revert <commit_id>  # 撤销指定的版本，撤销也会作为一次提交进行保存

3） git revert 和 git reset的区别
- git revert是用一次新的commit来回滚之前的commit，此次提交之前的commit都会被保留；
- git reset是回到某次提交，提交及之前的commit都会被保留，但是此commit id之后的修改都会被删除


参考 https://blog.csdn.net/asoar/article/details/84111841
```
## 5 查看分支的创建人
```
git log --oneline dev | cut -d " " -f 1 | tail -1 | xargs git log
```

## 6 克隆别人项目 修改后push 到自己仓库
```
1 创建自己的项目仓库复制项目git 地址
2 修改.git 文件中config 文件 把url 换成自己的仓库地址
3 push 报错 Updates were rejected because the tip of your current branch is behind 采用下面的命令push
4 git push -f origin master

```
