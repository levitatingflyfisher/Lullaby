import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../babies/domain/entities/baby.dart';
import '../../../../core/providers/repository_providers.dart';

final activeBabyProvider = StreamProvider<BabyEntity?>((ref) {
  final repo = ref.watch(babyRepositoryProvider);
  return repo.watchActiveBaby();
});
