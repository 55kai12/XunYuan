# 寻渊 隐私政策 · XunYuan Privacy Policy

**最后更新：2026 年 9 月 26 日**

---

## 简体中文

### 一句话说明

寻渊**不收集、不上传、不共享**你的任何数据。它是一款完全离线运行的本地应用。

### 1. 数据存放在哪里

你录入的全部内容——家族信息、成员资料、亲属关系、事件记录、照片与简介配图——**仅保存在你自己的设备上**（应用私有目录内的 SQLite 数据库与图片文件）。开发者无法访问，也不存在任何服务器接收这些数据。

### 2. 应用不具备联网能力

寻渊在 `AndroidManifest.xml` 中**未申请 `INTERNET` 权限**。这意味着它在系统层面就无法建立网络连接——不是"承诺不上传"，而是"没有能力上传"。你可以自行在开源仓库中核验这一点。

### 3. 不收集的信息

- 不要求注册账号，不收集手机号、邮箱、姓名等任何身份信息
- 不集成统计 SDK、广告 SDK、崩溃上报 SDK
- 不使用设备标识符、位置信息、通讯录、短信、通话记录
- 不进行任何形式的行为分析或个性化推荐

### 4. 权限用途说明

| 权限 | 用途 | 说明 |
| --- | --- | --- |
| `USE_BIOMETRIC`<br>`USE_FINGERPRINT` | 隐私锁 | 开启"隐私锁"后，进入应用需指纹/面容验证。验证过程由系统在设备本地完成，应用只接收"通过/不通过"的结果，无法获取你的生物特征数据 |

以下能力**无需额外权限**，且均由你主动触发：

- **相机 / 相册**：调用系统相机或系统照片选择器，仅处理你当次选中的图片，不会扫描或读取整个相册
- **文件导入 / 导出**：通过系统文件选择器读写你指定的备份文件、GEDCOM 文件或 PDF

### 5. 数据导出与分享

备份包、GEDCOM、PDF 等导出文件全部由你主动发起，**保存位置与分享对象完全由你决定**。应用不会自动上传或外发任何文件。

### 6. 数据删除

- 在应用内删除成员、家族或事件时，对应的图片文件会同步清理
- 卸载应用将一并移除应用私有目录中的全部数据，不可恢复

### 7. 未成年人

本应用不面向儿童设计，也不会有意收集未成年人的任何个人信息。

### 8. 政策变更

若本政策发生变更，我们会更新本文件并同步修改"最后更新"日期。由于应用不联网，重大变更也会在版本更新说明中提示。

### 9. 联系方式

寻渊是开源软件，任何隐私相关的疑问、建议或问题，欢迎在 GitHub 仓库提交 Issue：

<https://github.com/55kai12/XunYuan/issues>

---

## English

### Summary

XunYuan **does not collect, upload, or share any of your data**. It is a fully offline, local-first application.

### 1. Where your data lives

Everything you enter — family trees, member profiles, relationships, events, photos and inline images — is stored **only on your own device** (a local SQLite database and image files inside the app's private directory). The developer has no access to it, and no server receives it.

### 2. The app cannot access the network

XunYuan does **not request the `INTERNET` permission** in its `AndroidManifest.xml`. At the operating-system level, the app is incapable of opening a network connection. This is not merely a promise — you can verify it in the open-source repository.

### 3. What we do not collect

- No account registration; no phone number, email address, or name
- No analytics SDK, no advertising SDK, no crash-reporting SDK
- No device identifiers, location, contacts, SMS, or call logs
- No behavioural profiling or personalised recommendations

### 4. Permissions and why they are needed

| Permission | Purpose | Notes |
| --- | --- | --- |
| `USE_BIOMETRIC`<br>`USE_FINGERPRINT` | App lock | When "Privacy Lock" is on, unlocking the app requires fingerprint or face verification. Verification happens locally on your device; the app only receives a pass/fail result and never accesses your biometric data |

The following features require **no additional permissions** and are always user-initiated:

- **Camera / Photos**: uses the system camera or system photo picker, handling only the images you explicitly select. Your photo library is never scanned or read in bulk
- **File import / export**: reads and writes only the backup, GEDCOM, or PDF files you choose through the system file picker

### 5. Export and sharing

Backup archives, GEDCOM files and PDFs are generated only when you ask for them, and **you decide where they are saved and with whom they are shared**. The app never uploads or sends anything on its own.

### 6. Data deletion

- Deleting a member, family or event inside the app also removes the associated image files
- Uninstalling the app removes all data in its private directory. This is irreversible

### 7. Children

This app is not directed at children and does not knowingly collect any personal information from minors.

### 8. Changes to this policy

If this policy changes, we will update this document and its "last updated" date. Since the app never connects to the network, significant changes will also be noted in the release notes.

### 9. Contact

XunYuan is open-source software. For any privacy-related question or concern, please open an issue at:

<https://github.com/55kai12/XunYuan/issues>
