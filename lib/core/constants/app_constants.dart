/// 应用全局常量
/// 寻渊 - 本地优先的中文族谱工具
library;



/// 应用基本信息
class AppConstants {
  AppConstants._();

  /// 应用名称（中文原名，不随语言切换；界面标题需要翻译时用 '寻渊'.tr）
  static const String appName = '寻渊';

  /// 英文名称
  static const String appNameEn = 'XunYuan';

  /// 包名
  static const String packageName = 'com.xunyuan.familytree';

  /// 品牌标语
  static const String slogan = '寻根问祖，渊远流长';

  /// 数据库文件名
  static const String databaseName = 'xunyuan.db';

  /// 备份文件扩展名
  static const String backupExtension = '.xunyuan.json';

  /// 当前版本
  static const String version = '0.3.50';

  /// 构建号
  static const String buildNumber = '62';
}

/// 路由路径常量
class AppRoutes {
  AppRoutes._();

  /// 族谱树页（首页）
  static const String tree = '/';

  /// 成员列表页
  static const String members = '/members';

  /// 时间线页
  static const String timeline = '/timeline';

  /// 我的页
  static const String profile = '/profile';
}

/// 底部导航项索引
class NavIndex {
  NavIndex._();

  static const int tree = 0;
  static const int members = 1;
  static const int timeline = 2;
  static const int profile = 3;
}
