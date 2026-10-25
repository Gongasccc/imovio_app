import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:imovio/src/features/authentication/data/firebase_auth_repository.dart';
import 'package:imovio/src/features/pipeline/data/deals_repository.dart';
import 'package:imovio/src/features/pipeline/domain/deal.dart';

part 'deal_edit_controller.g.dart';

@riverpod
class DealEditController extends _$DealEditController {
  @override
  FutureOr<void> build() {}

  Future<bool> submit(Deal deal, {required bool isNew}) async {
    final uid = ref.read(currentUidProvider);
    final repo = ref.read(dealsRepositoryProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => isNew
        ? repo.addDeal(uid: uid, deal: deal)
        : repo.updateDeal(uid: uid, deal: deal));
    if (ref.mounted) state = result;
    return !result.hasError;
  }

  Future<bool> delete(DealID id) async {
    final uid = ref.read(currentUidProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
        () => ref.read(dealsRepositoryProvider).deleteDeal(uid: uid, id: id));
    if (ref.mounted) state = result;
    return !result.hasError;
  }
}
