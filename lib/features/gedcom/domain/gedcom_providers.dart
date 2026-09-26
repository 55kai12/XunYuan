/// GEDCOM 相关 Provider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../family/domain/family_providers.dart';
import '../data/gedcom_service.dart';

/// GEDCOM 服务 Provider
final gedcomServiceProvider = Provider<GedcomService>((ref) {
  final db = ref.watch(databaseProvider);
  return GedcomService(db);
});
