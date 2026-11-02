import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';

/// For cubits that ask a repository for data: one place for the rule about
/// errors that aren't [AppException]s.
///
/// `with RepositoryErrors<State>` gives the cubit [callRepository]. (A mixin
/// adds methods to a class without being its parent; `on BlocBase<S>` means
/// only cubits and blocs can use it, so it can call [addError].)
mixin RepositoryErrors<S> on BlocBase<S> {
  /// Runs [call] (a repository call) and returns its answer.
  ///
  /// Throws AppExceptions only. Repositories promise that, so anything else
  /// is a bug: it is reported (to BlocObserver.onError) and turned into an
  /// [UnknownException], which still gives the user a way to retry.
  Future<T> callRepository<T>(Future<T> Function() call) async {
    try {
      // `return await`, not just `return`: without the await, an error from
      // the Future would arrive after this try had already finished.
      return await call();
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      // A closed cubit (its screen went away while we waited) must not be
      // given errors.
      if (!isClosed) {
        addError(error, stackTrace);
      }
      throw const UnknownException();
    }
  }
}
