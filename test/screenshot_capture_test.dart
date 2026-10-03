/// 商店 / README 截图生成器（无头渲染）
///
/// 用途：在没有模拟器与真机的环境下，用 flutter_test 渲染真实页面并导出 PNG。
/// 运行：flutter test test/screenshot_capture_test.dart --update-goldens
/// 产物：test/screenshots/*.png（随后拷贝到 docs/screenshots/）
///
/// 说明：
/// - 数据全部为虚构演示数据（陈氏三代），不含任何真实家族信息。
/// - 载入项目自带字体，避免测试环境默认字体把中文渲染成方块。
library;

import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:familytree/core/constants/app_constants.dart';
import 'package:familytree/core/database/database.dart';
import 'package:familytree/core/i18n/i18n.dart';
import 'package:familytree/core/router/app_router.dart';
import 'package:familytree/core/settings/settings_providers.dart';
import 'package:familytree/core/theme/app_theme.dart';
import 'package:familytree/core/theme/text_scale.dart';
import 'package:familytree/app.dart';
import 'package:familytree/features/family/domain/family_providers.dart';
import 'package:familytree/features/security/presentation/lock_screen.dart';
import 'package:familytree/features/tree/presentation/tree_page.dart';

/// 截图尺寸：393 × 852 逻辑像素 @3x = 1179 × 2556（主流安卓旗舰）
const Size _logicalSize = Size(393, 852);
const double _dpr = 3.0;

/// 候选 CJK 字体（须同时含拉丁字形，否则中文会渲染成空白方块）。
/// 可用环境变量 XUNYUAN_SHOT_FONT 覆盖为本机任意 TTF/OTF。
const List<String> _cjkFontCandidates = [
  r'C:\Windows\Fonts\Deng.ttf', // Windows · 等线
  r'C:\Windows\Fonts\simhei.ttf', // Windows · 黑体
  '/System/Library/Fonts/PingFang.ttc', // macOS
  '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc', // Linux
];

Future<void> _register(String family, String path) async {
  final bytes = await File(path).readAsBytes();
  final loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}

/// 载入字体。
/// - 中文：注册为 Roboto（Material 在 Android 平台的字族名），
///   无头渲染时才不会把汉字画成空白方块；
/// - 图标：MaterialIcons 必须显式载入，否则界面里所有图标都是方块。
///
/// 中文字体按「环境变量 → 系统字体 → 项目自带楷体」的顺序挑选，
/// 最后一项保证任何机器上都能跑出可读的图（只是字形偏楷体）。
Future<void> _loadFonts() async {
  final override = Platform.environment['XUNYUAN_SHOT_FONT'];
  String? cjk;
  if (override != null && override.isNotEmpty && File(override).existsSync()) {
    cjk = override;
  } else {
    for (final candidate in _cjkFontCandidates) {
      if (File(candidate).existsSync()) {
        cjk = candidate;
        break;
      }
    }
  }
  cjk ??= 'assets/fonts/LXGWWenKai.ttf'; // 兜底：项目自带（3866 字子集）

  // 'Roboto' 承接主题里显式指定字族的样式；
  // 'Ahem' 是 flutter test 环境的默认字族——未指定 fontFamily 的样式
  // （如 appBarTheme.titleTextStyle）会落到它上面，不接管就是方块。
  for (final family in const ['Roboto', 'Ahem', 'FlutterTest']) {
    await _register(family, cjk);
  }

  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final icons = '$flutterRoot/bin/cache/artifacts/material_fonts/'
        'materialicons-regular.otf';
    if (File(icons).existsSync()) await _register('MaterialIcons', icons);
  }
}

/// 造一套虚构的三代演示数据
Future<void> _seed(AppDatabase db) async {
  final now = DateTime(2026, 9, 26);
  final treeId = await db.into(db.familyTrees).insert(
        FamilyTreesCompanion.insert(
          name: '颍川陈氏',
          surname: '陈',
          hallName: const Value('德星堂'),
          origin: const Value('河南颍川'),
          generationWords: const Value('廷守景承 世泽绵长'),
          description: const Value(
            '吾族世居颍川，唐末避乱南迁，辗转闽粤，明嘉靖年间卜居佛山汾水之阳。\n'
            '德星堂为堂号，取陈太丘「德星聚」之典，勉子孙以德立身。\n'
            '清中叶族人营布业于佛山，遂成一方望族，至今已传十有八世。',
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );

  Future<int> addPerson({
    required String surname,
    required String givenName,
    required Gender gender,
    int? generation,
    String? generationWord,
    String? branch,
    int? rank,
    DateTime? birthDate,
    DateTime? deathDate,
    bool isAlive = true,
    String? birthPlace,
    String? occupation,
    String? title,
    String? biography,
  }) {
    return db.into(db.persons).insert(
          PersonsCompanion.insert(
            treeId: treeId,
            surname: surname,
            givenName: givenName,
            gender: gender,
            generation: Value(generation),
            generationWord: Value(generationWord),
            branch: Value(branch),
            rank: Value(rank),
            birthDate: Value(birthDate),
            deathDate: Value(deathDate),
            isAlive: Value(isAlive),
            birthPlace: Value(birthPlace),
            occupation: Value(occupation),
            title: Value(title),
            biography: Value(biography),
          ),
        );
  }

  // 第一世
  final g1 = await addPerson(
    surname: '陈',
    givenName: '廷芳',
    gender: Gender.male,
    generation: 16,
    generationWord: '廷',
    branch: '长房',
    rank: 1,
    birthDate: DateTime(1901, 3, 12),
    deathDate: DateTime(1978, 11, 5),
    isAlive: false,
    birthPlace: '广东佛山',
    occupation: '布商',
    title: '德星堂族长',
    biography: '幼读私塾，通经史。年十六随父经营布行，以诚信称于乡里。\n'
        '抗战时主持族中义仓，赈济乡邻三百余户。',
  );
  final g1wife = await addPerson(
    surname: '林',
    givenName: '淑仪',
    gender: Gender.female,
    generation: 16,
    branch: '长房',
    birthDate: DateTime(1905, 7, 20),
    deathDate: DateTime(1986, 2, 18),
    isAlive: false,
    birthPlace: '广东南海',
    occupation: '家务',
  );

  // 第二世
  final g2 = await addPerson(
    surname: '陈',
    givenName: '守拙',
    gender: Gender.male,
    generation: 17,
    generationWord: '守',
    branch: '长房',
    rank: 1,
    birthDate: DateTime(1930, 5, 8),
    birthPlace: '广东佛山',
    occupation: '中学教员',
    title: '高级教师',
    biography: '师范毕业，执教四十载，桃李遍岭南。晚年留心族谱，手抄旧谱三卷。',
  );
  final g2wife = await addPerson(
    surname: '苏',
    givenName: '慧兰',
    gender: Gender.female,
    generation: 17,
    branch: '长房',
    birthDate: DateTime(1933, 9, 2),
    birthPlace: '广东顺德',
    occupation: '医师',
  );
  final g2bro = await addPerson(
    surname: '陈',
    givenName: '守愚',
    gender: Gender.male,
    generation: 17,
    generationWord: '守',
    branch: '二房',
    rank: 2,
    birthDate: DateTime(1934, 1, 25),
    birthPlace: '广东佛山',
    occupation: '工程师',
  );

  // 第三世
  final g3 = await addPerson(
    surname: '陈',
    givenName: '景行',
    gender: Gender.male,
    generation: 18,
    generationWord: '景',
    branch: '长房',
    rank: 1,
    birthDate: DateTime(1962, 4, 16),
    birthPlace: '广东佛山',
    occupation: '建筑师',
  );
  await addPerson(
    surname: '陈',
    givenName: '景明',
    gender: Gender.female,
    generation: 18,
    generationWord: '景',
    branch: '长房',
    rank: 2,
    birthDate: DateTime(1966, 12, 30),
    birthPlace: '广东佛山',
    occupation: '医生',
  );
  final g3child = await addPerson(
    surname: '陈',
    givenName: '承宇',
    gender: Gender.male,
    generation: 19,
    generationWord: '承',
    branch: '长房',
    rank: 1,
    birthDate: DateTime(1992, 8, 3),
    birthPlace: '广东佛山',
    occupation: '软件工程师',
  );

  Future<void> relate(int from, int to, RelationType type,
      {DateTime? start}) async {
    await db.into(db.relationships).insert(
          RelationshipsCompanion.insert(
            treeId: treeId,
            fromPersonId: from,
            toPersonId: to,
            type: type,
            startDate: Value(start),
          ),
        );
  }

  await relate(g1, g2, RelationType.father);
  await relate(g1wife, g2, RelationType.mother);
  await relate(g1, g1wife, RelationType.spouse, start: DateTime(1928, 10, 1));
  await relate(g1, g2bro, RelationType.father);
  await relate(g1wife, g2bro, RelationType.mother);
  await relate(g2, g2bro, RelationType.sibling);
  await relate(g2, g3, RelationType.father);
  await relate(g2wife, g3, RelationType.mother);
  await relate(g2, g2wife, RelationType.spouse, start: DateTime(1958, 5, 4));
  await relate(g3, g3child, RelationType.father);

  Future<void> addEvent({
    int? personId,
    required EventType type,
    required String title,
    DateTime? date,
    String? place,
    String? description,
  }) async {
    await db.into(db.events).insert(
          EventsCompanion.insert(
            treeId: treeId,
            personId: Value(personId),
            type: type,
            title: title,
            date: Value(date),
            place: Value(place),
            description: Value(description),
          ),
        );
  }

  await addEvent(
    personId: g1,
    type: EventType.birth,
    title: '廷芳公出生',
    date: DateTime(1901, 3, 12),
    place: '广东佛山汾水',
  );
  await addEvent(
    personId: g1,
    type: EventType.marriage,
    title: '廷芳公与林淑仪成婚',
    date: DateTime(1928, 10, 1),
    place: '佛山德星堂',
    description: '依族例于祠堂行礼，宴宾三日。',
  );
  await addEvent(
    type: EventType.migration,
    title: '长房迁居汾水之阳',
    date: DateTime(1937, 6, 1),
    place: '广东佛山',
    description: '因时局动荡，长房一支迁至汾水北岸新宅，旧宅改为族中义仓。',
  );
  await addEvent(
    personId: g1,
    type: EventType.death,
    title: '廷芳公辞世',
    date: DateTime(1978, 11, 5),
    place: '广东佛山',
  );
  await addEvent(
    personId: g2,
    type: EventType.honor,
    title: '守拙公获评高级教师',
    date: DateTime(1985, 9, 10),
    place: '广东佛山',
    description: '执教三十年，市教委授予高级教师职称。',
  );
  await addEvent(
    personId: g2,
    type: EventType.other,
    title: '守拙公手抄族谱三卷',
    date: DateTime(1994, 4, 1),
    description: '据旧谱残卷与族中口述，重抄世系三卷，藏于德星堂。',
  );
  await addEvent(
    personId: g3child,
    type: EventType.birth,
    title: '承宇出生',
    date: DateTime(1992, 8, 3),
    place: '广东佛山',
  );
}

/// 应用内主题里未声明字族的样式（appBarTheme.titleTextStyle、按钮 textStyle 等），
/// 在测试环境下会落到默认字体上渲染成方块——它们整体替换而非继承上下文样式。
/// 这里统一补上字族，其余一律沿用应用真实主题。
/// 在真机上该字族本就是 Android 的默认字体，因此不改变实机观感。
const String _font = 'Roboto';

TextStyle? _f(TextStyle? s) => s?.copyWith(fontFamily: _font);

ButtonStyle? _fb(ButtonStyle? s) {
  if (s == null) return null;
  final ts = s.textStyle;
  if (ts == null) return s;
  return s.copyWith(
    textStyle: WidgetStateProperty.resolveWith((states) => _f(ts.resolve(states))),
  );
}

WidgetStateProperty<TextStyle?>? _fp(WidgetStateProperty<TextStyle?>? p) => p == null
    ? null
    : WidgetStateProperty.resolveWith((states) => _f(p.resolve(states)));

ThemeData _fontSafe(ThemeData base) => base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: _font),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: _f(base.appBarTheme.titleTextStyle),
      ),
      chipTheme:
          base.chipTheme.copyWith(labelStyle: _f(base.chipTheme.labelStyle)),
      dialogTheme: base.dialogTheme.copyWith(
        titleTextStyle: _f(base.dialogTheme.titleTextStyle),
        contentTextStyle: _f(base.dialogTheme.contentTextStyle),
      ),
      elevatedButtonTheme:
          ElevatedButtonThemeData(style: _fb(base.elevatedButtonTheme.style)),
      filledButtonTheme:
          FilledButtonThemeData(style: _fb(base.filledButtonTheme.style)),
      outlinedButtonTheme:
          OutlinedButtonThemeData(style: _fb(base.outlinedButtonTheme.style)),
      textButtonTheme:
          TextButtonThemeData(style: _fb(base.textButtonTheme.style)),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        labelStyle: _f(base.inputDecorationTheme.labelStyle),
        hintStyle: _f(base.inputDecorationTheme.hintStyle),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        titleTextStyle: _f(base.listTileTheme.titleTextStyle),
        subtitleTextStyle: _f(base.listTileTheme.subtitleTextStyle),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        labelTextStyle: _fp(base.navigationBarTheme.labelTextStyle),
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        contentTextStyle: _f(base.snackBarTheme.contentTextStyle),
      ),
    );

/// 启动应用（内存数据库 + 中文）
///
/// 注意：这里没有直接用 XunYuanApp，而是复刻它的 MaterialApp 配置，
/// 唯一的差别是给主题补了字族（见 _fontSafe）。隐私锁外壳与自动备份
/// 不在截图范围内，故省略。
Future<void> _pumpApp(WidgetTester tester, AppDatabase db) async {
  tester.view.physicalSize = Size(_logicalSize.width * _dpr, _logicalSize.height * _dpr);
  tester.view.devicePixelRatio = _dpr;
  addTearDown(tester.view.reset);

  I18n.useEnglish = false;
  SharedPreferences.setMockInitialValues(
      {'onboarding_done': true, 'language_mode': 'zh'});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: _fontSafe(AppTheme.light),
        darkTheme: _fontSafe(AppTheme.dark),
        themeMode: ThemeMode.light,
        routerConfig: createRouter(true),
        locale: const Locale('zh', 'CN'),
        supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // 与 XunYuanApp 用同一个字号上限函数，否则测不到这条限制
        builder: (context, child) => limitTextScale(context, child!),
      ),
    ),
  );
  await _settle(tester);
}

/// 推进异步数据流（drift 的 stream 需要真实事件循环），并把界面上的动画跑完。
///
/// 注意：`pump(800ms)` **一次跑不完动画**。Ticker 的第一次 tick 只用来记录基准
/// 时间（elapsed = 0），要再来一帧才会真正前进。所以「切换称谓」这类过渡在旧写法
/// 下会停在第一帧——旧称谓还在、新称谓还没淡进来，截图就会拍到过渡瞬间。
/// 多补一帧才叫真 settle。
Future<void> _settle(WidgetTester tester, {int ms = 500}) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(Duration(milliseconds: ms));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump(const Duration(milliseconds: 800));
}

/// 用路由跳转（比点击更稳，不受具体控件与动画影响）
Future<void> _go(WidgetTester tester, String location) async {
  final ctx = tester.element(find.byType(TreePage));
  GoRouter.of(ctx).go(location);
  await _settle(tester);
}

/// 截取整屏并落盘到 docs/screenshots/（路径相对本测试文件解析）
Future<void> _shot(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../docs/screenshots/$name.png'),
  );
  await _drain(tester);
}

/// 卸载组件树，让 drift 的 stream 在 dispose 时创建的清理 Timer
/// 有机会在测试结束前跑完（否则报 "A Timer is still pending"）。
/// 任何渲染过应用的用例都必须以它收尾。
Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  late AppDatabase db;

  setUpAll(() async {
    // 备份页启动时会读取应用文档目录；测试环境没有该平台通道，
    // 用一个临时目录顶上，否则整页会抛 MissingPluginException
    final docsDir = await Directory.systemTemp.createTemp('xunyuan_shot_docs_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => docsDir.path,
    );
    await _loadFonts();
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await _seed(db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('01 族谱', (tester) async {
    await _pumpApp(tester, db);
    await _shot(tester, '01_tree');
  });

  testWidgets('02 家族首页', (tester) async {
    await _pumpApp(tester, db);
    await _go(tester, '/family/1');
    await _shot(tester, '02_family_home');
  });

  testWidgets('03 成员列表', (tester) async {
    await _pumpApp(tester, db);
    await _go(tester, '/members');
    await _shot(tester, '03_members');
  });

  testWidgets('04 人物详情', (tester) async {
    await _pumpApp(tester, db);
    // 取廷芳公（有生平简介、功名、多起事件），信息最完整
    await _go(tester, '/person/1');
    await _shot(tester, '04_person_detail');
  });

  testWidgets('05 谱系图', (tester) async {
    await _pumpApp(tester, db);
    await _go(tester, '/person/1/tree');
    await _shot(tester, '05_family_tree');
  });

  // 回归：带配偶的节点曾按「单张卡片宽」居中摆放，整组向右溢出半个卡片，
  // 压住右侧兄弟节点。这里直接量渲染后的卡片矩形，钉住不重叠。
  testWidgets('05b 谱系图节点卡片互不重叠', (tester) async {
    await _pumpApp(tester, db);
    await _go(tester, '/person/1/tree');

    // 本人/配偶卡片固定 110×56（父母层的 compact 卡片是 48 高，不在此列）
    final cards = find.byWidgetPredicate((w) =>
        w is ConstrainedBox &&
        w.constraints ==
            const BoxConstraints.tightFor(width: 110, height: 56));
    expect(cards, findsWidgets);

    final rects = [
      for (var i = 0; i < cards.evaluate().length; i++)
        tester.getRect(cards.at(i)),
    ];
    for (var i = 0; i < rects.length; i++) {
      for (var j = i + 1; j < rects.length; j++) {
        final hit = rects[i].intersect(rects[j]);
        expect(
          hit.width <= 0.01 || hit.height <= 0.01,
          isTrue,
          reason: '卡片重叠 ${hit.width.toStringAsFixed(1)}×'
              '${hit.height.toStringAsFixed(1)}：${rects[i]} ∩ ${rects[j]}',
        );
      }
    }
    await _drain(tester);
  });

  // 回归：连线锚点若取「本人卡片中心」，有配偶的节点会比子女层偏左半个配偶宽度，
  // 父子连线被迫拐成钩形。种子数据末两代是单子女链（陈景行 → 陈承宇），
  // 同列时两者卡片中心 x 必须严格相等。
  testWidgets('05c 谱系图单子女链父子同列', (tester) async {
    await _pumpApp(tester, db);
    await _go(tester, '/person/1/tree');

    final cards = find.byWidgetPredicate((w) =>
        w is ConstrainedBox &&
        w.constraints ==
            const BoxConstraints.tightFor(width: 110, height: 56));
    expect(cards, findsWidgets);

    // 同代节点 top 相同，按 top 分行
    final rows = <double, List<Rect>>{};
    for (var i = 0; i < cards.evaluate().length; i++) {
      final r = tester.getRect(cards.at(i));
      rows.putIfAbsent(r.top, () => []).add(r);
    }
    final tops = rows.keys.toList()..sort();
    expect(tops.length, greaterThanOrEqualTo(3), reason: '至少应有 3 代');

    final secondLast = rows[tops[tops.length - 2]]!;
    final last = rows[tops.last]!;
    expect(secondLast.length, 1, reason: '倒数第二代应为单卡片');
    expect(last.length, 1, reason: '最后一代应为单卡片');
    expect(
      last.first.center.dx,
      closeTo(secondLast.first.center.dx, 0.01),
      reason: '父子连线应为垂线，实际偏移 '
          '${(last.first.center.dx - secondLast.first.center.dx).toStringAsFixed(1)}px',
    );

    await _drain(tester);
  });

  // 称呼模式：打开左下角「称呼」开关后，每张卡片副标题应换成相对中心人的称谓。
  // 种子数据以陈廷芳为中心：妻 林淑仪、子 陈守拙/陈守愚、儿媳 苏慧兰、
  // 孙 陈景行、曾孙 陈承宇。
  testWidgets('05d 谱系图称呼模式', (tester) async {
    await _pumpApp(tester, db);
    await _go(tester, '/person/1/tree');

    // 关闭时不应出现任何称谓
    expect(find.text('妻子'), findsNothing);

    await tester.tap(find.text('称呼'));
    await _settle(tester);

    expect(find.text('本人'), findsOneWidget);
    expect(find.text('妻子'), findsOneWidget); // 林淑仪
    expect(find.text('儿子'), findsNWidgets(2)); // 守拙、守愚
    expect(find.text('儿媳'), findsOneWidget); // 苏慧兰
    expect(find.text('孙子'), findsOneWidget); // 陈景行
    expect(find.text('曾孙'), findsOneWidget); // 陈承宇

    await _shot(tester, '05d_family_tree_kinship');
  });

  // 切换中心人物时，全场的称谓要做「旧称谓淡出 → 新称谓淡入」的过渡，而不是硬闪。
  // 断言方式：过渡中段新旧称谓必须同时在场（同一张卡上新旧两个 Text 都在树上），
  // 过渡结束后只剩新称谓（顺便证明称谓数据本身也换对了）。
  testWidgets('05f 切换中心人物时称谓做过渡', (tester) async {
    await _pumpApp(tester, db);
    await _go(tester, '/person/1/tree');
    await tester.tap(find.text('称呼'));
    await _settle(tester);
    expect(find.text('儿媳'), findsOneWidget); // 苏慧兰，相对陈廷芳

    // 把中心人物从陈廷芳换成其子陈守拙
    await tester.tap(find.text('陈守拙'));
    await _settle(tester);
    await tester.tap(find.text('设为中心人物'));
    // 推进到过渡中段（AppMotion.normal = 350ms）：第一帧让变更生效并起动画，
    // 第二帧只是 Ticker 的基准时间，第三帧才真正往前走
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 120));

    expect(
      find.text('儿媳'),
      findsOneWidget,
      reason: '旧称谓「儿媳」应在过渡中淡出，而不是立刻消失',
    );
    expect(
      find.text('孙子'),
      findsNWidgets(2),
      reason: '承宇的新称谓「孙子」与景行尚未退场的旧称谓「孙子」应同时在树上',
    );

    await _settle(tester);
    expect(find.text('儿媳'), findsNothing);
    expect(find.text('曾孙'), findsNothing);
    expect(find.text('本人'), findsOneWidget); // 陈守拙
    expect(find.text('妻子'), findsOneWidget); // 苏慧兰
    expect(find.text('父亲'), findsOneWidget); // 陈廷芳
    expect(find.text('母亲'), findsOneWidget); // 林淑仪
    expect(find.text('儿子'), findsOneWidget); // 陈景行
    expect(find.text('孙子'), findsOneWidget); // 陈承宇

    await _drain(tester);
  });

  // 老年用户会把系统字号调大。族谱树卡片原本写死 56px 高（内容区仅 ~40px，
  // 要塞「姓名 + 世代·字辈」两行），实测 1.3x 起每张卡就溢出 7px、2.0x 达 29px。
  // 现在卡片高度随字号自适应，这里钉住「放大到 1.6x 各主要页面都不报错」。
  testWidgets('09 字体放大 1.6x 不溢出', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    const routes = [
      '/',
      '/family/1',
      '/members',
      '/person/1',
      '/person/1/tree',
      '/timeline',
      '/profile',
      '/backup',
    ];

    for (final route in routes) {
      // 每次重新 pump：_go 依赖当前页还停在 TreePage，跳第二次就取不到路由了
      await _pumpApp(tester, db);
      if (route != '/') {
        final ctx = tester.element(find.byType(TreePage));
        GoRouter.of(ctx).go(route);
        await _settle(tester);
      }

      final failures = <String>[];
      for (var i = 0; i < 8; i++) {
        final e = tester.takeException();
        if (e == null) break;
        failures.add(e.toString().split('\n').first);
      }
      expect(failures, isEmpty, reason: '1.6x 字号下 $route 出现布局异常：$failures');

      if (route.endsWith('/tree')) {
        // 确认真渲染出了卡片（宽度恒为 110，高度随字号变）
        final cards = find.byWidgetPredicate((w) =>
            w is ConstrainedBox &&
            w.constraints.minWidth == 110 &&
            w.constraints.maxWidth == 110);
        expect(cards, findsWidgets, reason: '族谱树卡片未渲染');
      }

      await _drain(tester);
    }
  });

  // 大字模式留档：系统字号 1.6x（应用上限）下卡片应变高、两行都装得下。
  testWidgets('05e 谱系图大字模式', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpApp(tester, db);
    await _go(tester, '/person/1/tree');
    for (var i = 0; i < 30; i++) {
      if (tester.takeException() == null) break;
    }
    await _shot(tester, '05e_family_tree_large_font');
  });

  // 上限本身要生效：系统字号设成 2.0x（部分 ROM 的「超大」档）时，
  // 卡片高度应停在 1.6x 对应的 81.2，而不是 2.0x 的 98。
  testWidgets('10 字号上限 1.6x 生效', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pumpApp(tester, db);
    await _go(tester, '/person/1/tree');

    final heights = <double>{
      for (final e in find
          .byWidgetPredicate((w) =>
              w is ConstrainedBox &&
              w.constraints.minWidth == 110 &&
              w.constraints.maxWidth == 110)
          .evaluate())
        (e.widget as ConstrainedBox).constraints.maxHeight,
    };

    expect(heights, isNotEmpty, reason: '族谱树卡片未渲染');
    // 整卡 81.2、父母 compact 卡 73.2；不该出现 2.0x 的 98 / 90
    expect(
      heights.every((h) => h <= 82),
      isTrue,
      reason: '2.0x 下卡片高度未受 1.6x 上限约束：$heights',
    );
    expect(
      heights.any((h) => (h - 81.2).abs() < 0.01),
      isTrue,
      reason: '未找到 1.6x 对应的整卡高度（期望含 81.2）：$heights',
    );

    await _drain(tester);
  });

  // 锁屏是整棵子树的「兄弟」而不是后代（未解锁时它根本不渲染 child），
  // 所以字号上限必须包在它外层 —— 否则锁屏自己的文字落在约束之外，
  // 2.0x 时 80×80 图标框里的「渊」会被撑破。
  // 这里直接跑真正的 XunYuanApp（它只读 SharedPreferences，插件调用都有兜底）。
  testWidgets('11 锁屏也受字号上限约束', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    SharedPreferences.setMockInitialValues({
      'privacy_lock_enabled': true,
      'onboarding_done': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const XunYuanApp(),
      ),
    );
    await _settle(tester);

    final lock = find.byType(LockScreen);
    expect(lock, findsOneWidget, reason: '隐私锁屏未显示');

    // 取锁屏自己渲染出来的第一个 Text（避开 i18n 语言差异）
    final inner = find.descendant(of: lock, matching: find.byType(Text)).first;
    final scale = MediaQuery.textScalerOf(tester.element(inner)).scale(1.0);
    expect(
      scale,
      closeTo(kMaxTextScale, 0.001),
      reason: '锁屏文字未受 $kMaxTextScale 上限约束，实际 $scale',
    );

    await _drain(tester);
  });

  testWidgets('06 事件时间线', (tester) async {
    await _pumpApp(tester, db);
    await _go(tester, '/timeline');
    await _shot(tester, '06_timeline');
  });

  testWidgets('07 我的', (tester) async {
    await _pumpApp(tester, db);
    await _go(tester, '/profile');
    await _shot(tester, '07_profile');
  });

  testWidgets('08 备份与恢复', (tester) async {
    await _pumpApp(tester, db);
    await _go(tester, '/backup');
    await _shot(tester, '08_backup');
  });
}
