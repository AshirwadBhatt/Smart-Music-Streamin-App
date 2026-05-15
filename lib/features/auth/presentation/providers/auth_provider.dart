import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

final authDatasourceProvider = Provider<AuthRemoteDatasource>((ref) => AuthRemoteDatasource());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authDatasourceProvider));
});

// Holds the currently signed-in user (null = signed out)
final currentUserProvider = StateProvider<UserEntity?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getCurrentUser();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> signInGoogle() async {
    state = const AsyncValue.loading();
    final result = await _repo.signInWithGoogle();
    result.fold(
      (f) => state = AsyncValue.error(f.message, StackTrace.current),
      (u) => state = AsyncValue.data(u), // u may be null — OAuth redirects page
    );
  }

  Future<bool> signInWithPhone(String phone) async {
    state = const AsyncValue.loading();
    final result = await _repo.signInWithPhone(phone);
    return result.fold((f) { state = AsyncValue.error(f.message, StackTrace.current); return false; }, (_) { state = const AsyncValue.data(null); return true; });
  }

  Future<void> verifyOtp(String phone, String otp) async {
    state = const AsyncValue.loading();
    final result = await _repo.verifyOtp(phone, otp);
    result.fold(
      (f) => state = AsyncValue.error(f.message, StackTrace.current),
      (u) => state = AsyncValue.data(u),
    );
  }

  Future<void> signInEmail(String email, String pw) async {
    state = const AsyncValue.loading();
    final result = await _repo.signInWithEmail(email, pw);
    result.fold(
      (f) => state = AsyncValue.error(f.message, StackTrace.current),
      (u) => state = AsyncValue.data(u),
    );
  }

  Future<void> signUpEmail(String email, String pw, String name) async {
    state = const AsyncValue.loading();
    final result = await _repo.signUpWithEmail(email, pw, name);
    result.fold(
      (f) => state = AsyncValue.error(f.message, StackTrace.current),
      (u) => state = AsyncValue.data(u),
    );
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
