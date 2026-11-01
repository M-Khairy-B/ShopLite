import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/features/search/presentation/cubits/search_cubit.dart';
import 'package:e_commerce_learn/features/search/presentation/cubits/search_state.dart';

import '../../../../helpers/fake_products_repository.dart';
import '../../../../helpers/mock_products.dart';

/// Less than the debounce: the time between two quick keystrokes.
const _keystroke = Duration(milliseconds: 100);

/// Runs [body] in a fake world where time only passes when the test says so
/// (`async.elapse`), with a [SearchCubit] on [repository] (the mock catalog
/// by default). The cubit is closed at the end.
void _withCubit(
  void Function(FakeAsync async, SearchCubit cubit) body, {
  FakeProductsRepository? repository,
}) {
  fakeAsync((async) {
    final cubit = SearchCubit(
      repository: repository ?? FakeProductsRepository(),
    );
    body(async, cubit);
    cubit.close();
    async.flushMicrotasks();
  });
}

/// Types [text] one letter at a time, quickly, like a user.
void _typeQuickly(FakeAsync async, SearchCubit cubit, String text) {
  for (var length = 1; length <= text.length; length++) {
    cubit.queryChanged(text.substring(0, length));
    async.elapse(_keystroke);
  }
}

void main() {
  test('starts idle, with an empty query', () {
    final cubit = SearchCubit(repository: FakeProductsRepository());

    expect(cubit.state, const SearchIdle());

    cubit.close();
  });

  group('debounce', () {
    test('waits for a pause in typing before searching', () {
      final repository = FakeProductsRepository();
      _withCubit(repository: repository, (async, cubit) {
        cubit.queryChanged('phone');

        async.elapse(SearchCubit.debounce - const Duration(milliseconds: 1));
        expect(repository.searchQueries, isEmpty);
        expect(cubit.state, const SearchIdle());

        async.elapse(const Duration(milliseconds: 1));
        expect(repository.searchQueries, ['phone']);
      });
    });

    test('typing quickly sends one search, for the whole word', () {
      final repository = FakeProductsRepository();
      _withCubit(repository: repository, (async, cubit) {
        _typeQuickly(async, cubit, 'phone');
        async.elapse(SearchCubit.debounce);

        expect(repository.searchQueries, ['phone']);
      });
    });

    test('ignores spaces around the text', () {
      final repository = FakeProductsRepository();
      _withCubit(repository: repository, (async, cubit) {
        cubit.queryChanged('  phone ');
        async.elapse(SearchCubit.debounce);

        expect(repository.searchQueries, ['phone']);
      });
    });

    test('does not search again for the same text', () {
      // For example after typing a space at the end.
      final repository = FakeProductsRepository();
      _withCubit(repository: repository, (async, cubit) {
        cubit.queryChanged('phone');
        async.elapse(SearchCubit.debounce);

        cubit.queryChanged('phone ');
        async.elapse(SearchCubit.debounce);

        expect(repository.searchQueries, ['phone']);
      });
    });
  });

  group('results', () {
    test('shows loading, then the matching products', () {
      _withCubit((async, cubit) {
        final states = <SearchState>[];
        cubit.stream.listen(states.add);

        cubit.queryChanged('phone');
        async.elapse(SearchCubit.debounce);

        expect(states, [
          const SearchLoading(query: 'phone'),
          SearchLoaded(
            [mockProducts[6], mockProducts[7]], // iPhone 5s, iPhone 6
            total: 2,
            query: 'phone',
          ),
        ]);
      });
    });

    test('asks for one page, and keeps the total number of matches', () {
      _withCubit(
        repository: FakeProductsRepository(products: generatedProducts(45)),
        (async, cubit) {
          cubit.queryChanged('product');
          async.elapse(SearchCubit.debounce);

          final state = cubit.state as SearchLoaded;
          expect(state.products, hasLength(SearchCubit.resultLimit));
          expect(state.total, 45);
        },
      );
    });

    test('nothing matching emits the empty state', () {
      _withCubit((async, cubit) {
        cubit.queryChanged('zzz');
        async.elapse(SearchCubit.debounce);

        expect(cubit.state, const SearchEmpty(query: 'zzz'));
      });
    });

    test('submitting searches right away, without waiting', () {
      // The keyboard's search button: the user says they are done typing.
      final repository = FakeProductsRepository();
      _withCubit(repository: repository, (async, cubit) {
        cubit.queryChanged('phon');
        cubit.submit('phone');
        async.flushMicrotasks();

        expect(repository.searchQueries, ['phone']);

        // The search that was waiting for "phon" was cancelled.
        async.elapse(SearchCubit.debounce);
        expect(repository.searchQueries, ['phone']);
      });
    });
  });

  group('clearing the text', () {
    test('goes back to idle, and cancels the search that was waiting', () {
      final repository = FakeProductsRepository();
      _withCubit(repository: repository, (async, cubit) {
        cubit.queryChanged('phone');
        async.elapse(SearchCubit.debounce);

        cubit.queryChanged('pho');
        cubit.queryChanged('');
        async.elapse(SearchCubit.debounce);

        expect(cubit.state, const SearchIdle());
        expect(repository.searchQueries, ['phone']); // not "pho"
      });
    });

    test('drops the answer of a search that was on its way', () {
      final repository = FakeProductsRepository();
      _withCubit(repository: repository, (async, cubit) {
        // Created here, inside fakeAsync: a Completer made outside it would
        // deliver its answer through the real event loop, which
        // flushMicrotasks doesn't run. The answer would never arrive, and
        // the test would pass without testing anything.
        repository.gate = Completer<void>();
        cubit.queryChanged('phone');
        async.elapse(SearchCubit.debounce); // the search is sent

        cubit.queryChanged('');
        repository.gate!.complete(); // ...and answers after the clear
        async.flushMicrotasks();

        expect(cubit.state, const SearchIdle());
      });
    });
  });

  test('an older, slower answer never replaces a newer one', () {
    final repository = FakeProductsRepository();
    _withCubit(repository: repository, (async, cubit) {
      final slow = repository.gate = Completer<void>();
      cubit.queryChanged('mac');
      async.elapse(SearchCubit.debounce); // "mac" is sent, and is slow

      final fast = repository.gate = Completer<void>();
      cubit.queryChanged('phone');
      async.elapse(SearchCubit.debounce); // "phone" is sent

      fast.complete(); // "phone" answers first...
      async.flushMicrotasks();
      slow.complete(); // ...then "mac", too late
      async.flushMicrotasks();

      expect(cubit.state, isA<SearchLoaded>());
      expect(cubit.state.query, 'phone');
    });
  });

  group('retry', () {
    test('after an error, searches again', () {
      final repository = FakeProductsRepository(
        error: const NetworkException(),
      );
      _withCubit(repository: repository, (async, cubit) {
        cubit.queryChanged('phone');
        async.elapse(SearchCubit.debounce);
        expect(
          cubit.state,
          const SearchError(NetworkException(), query: 'phone'),
        );

        repository.error = null; // the connection is back
        cubit.retry();
        async.flushMicrotasks();

        expect(cubit.state, isA<SearchLoaded>());
        expect(repository.searchQueries, ['phone', 'phone']);
      });
    });

    test('does nothing when the search has not failed', () {
      final repository = FakeProductsRepository();
      _withCubit(repository: repository, (async, cubit) {
        cubit.queryChanged('phone');
        async.elapse(SearchCubit.debounce);

        cubit.retry();
        async.flushMicrotasks();

        expect(repository.searchQueries, ['phone']);
      });
    });
  });

  test('an error that is not an AppException is shown as unknown', () {
    _withCubit(repository: FakeProductsRepository(error: StateError('a bug')), (
      async,
      cubit,
    ) {
      // (That it is also reported is RepositoryErrors' job, tested there.)
      cubit.queryChanged('phone');
      async.elapse(SearchCubit.debounce);

      expect(
        cubit.state,
        const SearchError(UnknownException(), query: 'phone'),
      );
    });
  });

  group('closing', () {
    test('cancels the search that was waiting for a pause', () {
      // The user typed, then left the screen before the pause was over.
      fakeAsync((async) {
        final repository = FakeProductsRepository();
        final cubit = SearchCubit(repository: repository);

        cubit.queryChanged('phone');
        cubit.close();
        async.elapse(SearchCubit.debounce);

        expect(repository.searchQueries, isEmpty);
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('while a search is on its way does not fail', () {
      fakeAsync((async) {
        final repository = FakeProductsRepository(gate: Completer<void>());
        final cubit = SearchCubit(repository: repository);

        cubit.queryChanged('phone');
        async.elapse(SearchCubit.debounce);
        cubit.close();
        repository.gate!.complete();
        async.flushMicrotasks();

        expect(cubit.isClosed, isTrue);
      });
    });
  });
}
