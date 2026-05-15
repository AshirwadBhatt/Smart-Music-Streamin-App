abstract class Failure {
  final String message;
  const Failure(this.message);
}
class NetworkFailure    extends Failure { const NetworkFailure([String m = 'No internet connection']) : super(m); }
class ServerFailure     extends Failure { const ServerFailure([String m = 'Server error']) : super(m); }
class AuthFailure       extends Failure { const AuthFailure([String m = 'Authentication failed']) : super(m); }
class CacheFailure      extends Failure { const CacheFailure([String m = 'Cache error']) : super(m); }
class StreamingFailure  extends Failure { const StreamingFailure([String m = 'Streaming error']) : super(m); }
class NotFoundFailure   extends Failure { const NotFoundFailure([String m = 'Not found']) : super(m); }
