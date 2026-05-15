import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _ds;
  AuthRepositoryImpl(this._ds);

  UserEntity _map(sb.User u) => UserEntity(
    id: u.id,
    email: u.email ?? '',
    username: u.userMetadata?['full_name'] as String?,
    avatarUrl: u.userMetadata?['avatar_url'] as String?,
    phone: u.phone,
  );

  @override Future<Either<Failure, UserEntity?>> signInWithGoogle() async {
    try {
      await _ds.signInWithGoogle(); // triggers OAuth redirect, returns void
      final u = _ds.getCurrentUser();
      return Right(u == null ? null : _map(u));
    } catch (e) { return Left(AuthFailure(e.toString())); }
  }

  @override Future<Either<Failure, void>> signInWithPhone(String phone) async {
    try { await _ds.signInWithPhone(phone); return const Right(null); }
    catch (e) { return Left(AuthFailure(e.toString())); }
  }

  @override Future<Either<Failure, UserEntity>> verifyOtp(String phone, String otp) async {
    try { return Right(_map(await _ds.verifyOtp(phone, otp))); }
    catch (e) { return Left(AuthFailure(e.toString())); }
  }

  @override Future<Either<Failure, UserEntity>> signInWithEmail(String email, String pw) async {
    try { return Right(_map(await _ds.signInWithEmail(email, pw))); }
    catch (e) { return Left(AuthFailure(e.toString())); }
  }

  @override Future<Either<Failure, UserEntity>> signUpWithEmail(String email, String pw, String name) async {
    try { return Right(_map(await _ds.signUpWithEmail(email, pw, name))); }
    catch (e) { return Left(AuthFailure(e.toString())); }
  }

  @override Future<Either<Failure, void>> signOut() async {
    try { await _ds.signOut(); return const Right(null); }
    catch (e) { return Left(AuthFailure(e.toString())); }
  }

  @override UserEntity? getCurrentUser() {
    final u = _ds.getCurrentUser();
    return u == null ? null : _map(u);
  }
}
