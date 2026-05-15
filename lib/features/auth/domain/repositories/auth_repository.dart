import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity?>> signInWithGoogle();
  Future<Either<Failure, void>>       signInWithPhone(String phone);
  Future<Either<Failure, UserEntity>> verifyOtp(String phone, String otp);
  Future<Either<Failure, UserEntity>> signInWithEmail(String email, String password);
  Future<Either<Failure, UserEntity>> signUpWithEmail(String email, String password, String username);
  Future<Either<Failure, void>>       signOut();
  UserEntity?                         getCurrentUser();
}
