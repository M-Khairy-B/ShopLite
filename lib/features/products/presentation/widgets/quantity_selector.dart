import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A "− 1 +" control for choosing how many items to buy.
///
/// The quantity is local UI state, so it lives in this widget's [State].
/// Every lifecycle method logs a line to the debug console so you can watch
/// the order in which Flutter calls them (Phase 1, Task 6).
class QuantitySelector extends StatefulWidget {
  const QuantitySelector({
    super.key,
    this.initialQuantity = 1,
    this.maxQuantity = 10,
  });

  final int initialQuantity;
  final int maxQuantity;

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  _QuantitySelectorState() {
    _log('State object created');
  }

  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _log('initState (quantity = $_quantity)');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _log('didChangeDependencies');
  }

  @override
  void didUpdateWidget(covariant QuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _log('didUpdateWidget');
  }

  @override
  void reassemble() {
    super.reassemble();
    _log('reassemble (hot reload)');
  }

  @override
  void deactivate() {
    _log('deactivate');
    super.deactivate();
  }

  @override
  void dispose() {
    _log('dispose');
    super.dispose();
  }

  void _increment() {
    setState(() {
      _quantity++;
    });
    _log('setState (quantity = $_quantity)');
  }

  void _decrement() {
    setState(() {
      _quantity--;
    });
    _log('setState (quantity = $_quantity)');
  }

  @override
  Widget build(BuildContext context) {
    _log('build (quantity = $_quantity)');

    // One group for screen readers: "Quantity, 1", followed by the
    // "Decrease quantity" and "Increase quantity" buttons inside it.
    return Semantics(
      container: true,
      label: 'Quantity',
      value: '$_quantity',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.outlined(
            tooltip: 'Decrease quantity',
            onPressed: _quantity > 1 ? _decrement : null,
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 48,
            // Already announced as the group's value above.
            child: ExcludeSemantics(
              child: Text(
                '$_quantity',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton.outlined(
            tooltip: 'Increase quantity',
            onPressed: _quantity < widget.maxQuantity ? _increment : null,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

/// Prints lifecycle messages in debug builds only.
void _log(String message) {
  if (kDebugMode) {
    debugPrint('[QuantitySelector] $message');
  }
}
