import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_commerce_learn/core/errors/app_exception.dart';
import 'package:e_commerce_learn/core/widgets/error_view.dart';

Widget _host(AppException error, {void Function()? onRetry}) {
  return MaterialApp(
    home: Scaffold(
      body: ErrorView(error: error, onRetry: onRetry ?? () {}),
    ),
  );
}

void main() {
  // What each kind of error should look like.
  const expectations = <(AppException, String, IconData)>[
    (NetworkException(), "You're offline", Icons.wifi_off),
    (RequestTimeoutException(), 'That took too long', Icons.timer_off_outlined),
    (NotFoundException(), 'Not found', Icons.search_off),
    (ServerException(500), 'Server problem', Icons.cloud_off_outlined),
    (
      UnexpectedResponseException(),
      'Something went wrong',
      Icons.error_outline,
    ),
    (UnknownException(), 'Something went wrong', Icons.error_outline),
  ];

  for (final (error, title, icon) in expectations) {
    testWidgets('${error.runtimeType} shows its title, message and icon', (
      tester,
    ) async {
      await tester.pumpWidget(_host(error));

      expect(find.text(title), findsOneWidget);
      expect(find.text(error.message), findsOneWidget);
      expect(find.byIcon(icon), findsOneWidget);
    });
  }

  testWidgets('"Try again" calls onRetry', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(const NetworkException(), onRetry: () => retries++),
    );

    await tester.tap(find.text('Try again'));

    expect(retries, 1);
  });

  testWidgets('meets the accessibility guidelines', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(const ServerException(500)));

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    semantics.dispose();
  });

  testWidgets('has no overflow on a short screen with the largest text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1080); // landscape phone
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(_host(const RequestTimeoutException()));

    expect(tester.takeException(), isNull);
  });
}
