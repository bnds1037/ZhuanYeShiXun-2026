# Git Push 到团队远程仓库解决方案

## 问题分析

### 当前状态
- **本地分支**: `MAP`（存在合并冲突）
- **当前远程**: `https://github.com/keter023999-oss/-2026.git`
- **目标远程**: `https://github.com/bnds1037/ZhuanYeShiXun-2026.git`
- **目标分支**: `Develop`

### 错误原因
1. 远程仓库地址不正确，指向了个人仓库而非团队仓库
2. 本地存在合并冲突，需要先解决
3. `.godot/` 目录包含大量缓存文件，不应该提交到远程

## 解决方案步骤

### 步骤 1：修正 .gitignore（排除 .godot/）

**修改文件**: `.gitignore`

**修改内容**:
```
# Godot 4+ specific ignores
.godot/
/android/
```

### 步骤 2：重置合并状态（解决冲突）

```powershell
# 放弃当前合并
git merge --abort

# 重置到上次提交状态
git reset --hard HEAD
```

### 步骤 3：添加团队远程仓库

```powershell
# 添加团队仓库作为新的远程
git remote add team https://github.com/bnds1037/ZhuanYeShiXun-2026.git

# 验证远程配置
git remote -v
```

### 步骤 4：拉取团队 Develop 分支

```powershell
# 拉取团队远程的 Develop 分支
git fetch team Develop

# 创建本地 Develop 分支并追踪远程
git checkout -b Develop team/Develop
```

### 步骤 5：添加并提交更改

```powershell
# 添加所有更改
git add -A

# 提交更改
git commit -m "更新地图系统相关代码"
```

### 步骤 6：推送到团队仓库

```powershell
# 推送到团队仓库的 Develop 分支
git push team Develop
```

## 风险处理

### 风险 1：冲突解决后丢失本地更改
- **处理方式**: 在重置前使用 `git stash` 保存更改，重置后使用 `git stash pop` 恢复

### 风险 2：远程分支保护无法推送
- **处理方式**: 如果 Develop 分支有保护，需要先创建功能分支，然后通过 Pull Request 合并

### 风险 3：.godot/ 文件已经被提交
- **处理方式**: 使用 `git rm --cached -r .godot/` 移除已提交的缓存文件

## 验证方案

执行完成后，运行以下命令验证：

```powershell
# 查看分支状态
git branch -v

# 查看远程配置
git remote -v

# 查看提交历史
git log --oneline -5
```

## 后续操作建议

1. **删除旧的 origin 远程**（如果不再需要）:
   ```powershell
   git remote remove origin
   git remote rename team origin
   ```

2. **设置上游跟踪**:
   ```powershell
   git push -u team Develop
   ```

3. **日常开发流程**:
   ```powershell
   # 拉取最新代码
   git pull team Develop

   # 创建功能分支
   git checkout -b feature/xxx

   # 提交并推送
   git add .
   git commit -m "描述更改"
   git push team feature/xxx
   ```

## 文件清单

| 文件 | 说明 |
|------|------|
| `.gitignore` | 需要修改，添加 `.godot/` |
| `project.godot` | 可能需要检查是否有冲突 |
| `.git/config` | 远程配置文件（自动修改） |