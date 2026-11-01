import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/errors/repository_errors.dart';

/// The smallest cubit that uses [RepositoryErrors]. It remembers what was
/// reported to [onError], where a real cubit's BlocObserver would see it.
class _TestCubit extends Cubit<int> with RepositoryErrors<int> {
  _TestCubit() : super(0);

  final reported = <Object>[];

  @override
  void onError(Object error, StackTrace stackTrace) {
    reported.add(error);
    super.onError(error, stackTrace);
  }
}

void main() {
  late _TestCubit cubit;

  setUp(() => cubit = _TestCubit());
  tearDown(() => cubit.close());

  test('returns what the repository answered', () async {
    final answer = await cubit.callRepository(() async => 42);

    expect(answer, 42);
    expect(cubit.reported, isEmpty);
  });

  test('passes an AppException on unchanged, without reporting it', () async {
    // Being offline is expected, not a bug.
    await expectLater(
      cubit.callRepository<int>(() async => throw const NetworkException()),
      throwsA(isA<NetworkException>()),
    );
    expect(cubit.reported, isEmpty);
  });

  test('reports any other error, and throws an UnknownException', () async {
    await expectLater(
      cubit.callRepository<int>(() async => throw StateError('a bug')),
      throwsA(isA<UnknownException>()),
    );
    expect(cubit.reported, [isA<StateError>()]);
  });

  test('also catches an error thrown before any Future', () async {
    // A repository can fail synchronously, before it returns a Future.
    await expectLater(
      cubit.callRepository<int>(() => throw StateError('a bug')),
      throwsA(isA<UnknownException>()),
    );
    expect(cubit.reported, [isA<StateError>()]);
  });

  test('does not report to a closed cubit', () async {
    // The screen went away while the repository was working. Reporting to
    // a closed cubit is not allowed.
    await cubit.close();

    await expectLater(
      cubit.callRepository<int>(() async => throw StateError('a bug')),
      throwsA(isA<UnknownException>()),
    );
    expect(cubit.reported, isEmpty);
  });
}
