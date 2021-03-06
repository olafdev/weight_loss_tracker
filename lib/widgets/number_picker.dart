import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Created by Marcin Szałek

///NumberPicker is a widget designed to pick a number between #minValue and #maxValue
class NumberPicker extends StatelessWidget {
  ///height of every list element
  static const double DEFAULT_ITEM_EXTENT = 50.0;

  ///width of list view
  static const double DEFUALT_LISTVIEW_WIDTH = 100.0;

  ///constructor for integer number picker
  NumberPicker.integer({
    Key? key,
    required int initialValue,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
    this.itemExtent = DEFAULT_ITEM_EXTENT,
    this.listViewWidth = DEFUALT_LISTVIEW_WIDTH,
  })
      : assert(initialValue != null),
        assert(minValue != null),
        assert(maxValue != null),
        assert(maxValue > minValue),
        assert(initialValue >= minValue && initialValue <= maxValue),
        selectedIntValue = initialValue,
        selectedDecimalValue = -1,
        decimalPlaces = 0,
        intScrollController = ScrollController(
          initialScrollOffset: (initialValue - minValue) * itemExtent,
        ),
        decimalScrollController = ScrollController(
          initialScrollOffset: (initialValue - minValue) * itemExtent,
        ),
        _listViewHeight = 3 * itemExtent,
        super(key: key);

  ///constructor for decimal number picker
  NumberPicker.decimal({
    Key? key,
    required double initialValue,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
    this.decimalPlaces = 1,
    this.itemExtent = DEFAULT_ITEM_EXTENT,
    this.listViewWidth = DEFUALT_LISTVIEW_WIDTH,
  })
      : assert(initialValue != null),
        assert(minValue != null),
        assert(maxValue != null),
        assert(decimalPlaces != null && decimalPlaces > 0),
        assert(maxValue > minValue),
        assert(initialValue >= minValue && initialValue <= maxValue),
        selectedIntValue = initialValue.floor(),
        selectedDecimalValue = ((initialValue - initialValue.floorToDouble()) *
            math.pow(10, decimalPlaces))
            .round(),
        intScrollController = ScrollController(
          initialScrollOffset: (initialValue.floor() - minValue) * itemExtent,
        ),
        decimalScrollController = ScrollController(
          initialScrollOffset: ((initialValue - initialValue.floorToDouble()) *
              math.pow(10, decimalPlaces))
              .roundToDouble() *
              itemExtent,
        ),
        _listViewHeight = 3 * itemExtent,
        super(key: key);

  ///called when selected value changes
  final ValueChanged<num> onChanged;

  ///min value user can pick
  final int minValue;

  ///max value user can pick
  final int maxValue;

  ///inidcates how many decimal places to show
  /// e.g. 0=>[1,2,3...], 1=>[1.0, 1.1, 1.2...]  2=>[1.00, 1.01, 1.02...]
  final int decimalPlaces;

  ///height of every list element in pixels
  final double itemExtent;

  ///view will always contain only 3 elements of list in pixels
  final double _listViewHeight;

  ///width of list view in pixels
  final double listViewWidth;

  ///ScrollController used for integer list
  late ScrollController intScrollController;

  ///ScrollController used for decimal list
  late ScrollController decimalScrollController;

  ///Currently selected integer value
  final int selectedIntValue;

  ///Currently selected decimal value
  final int selectedDecimalValue;

  //
  //----------------------------- PUBLIC ------------------------------
  //

  animateInt(int valueToSelect) {
    _animate(intScrollController, (valueToSelect - minValue) * itemExtent);
  }

  animateDecimal(int decimalValue) {
    _animate(decimalScrollController, decimalValue * itemExtent);
  }

  animateDecimalAndInteger(double valueToSelect) {
    animateInt(valueToSelect.floor());
    animateDecimal(((valueToSelect - valueToSelect.floorToDouble()) *
        math.pow(10, decimalPlaces))
        .round());
  }

  //
  //----------------------------- VIEWS -----------------------------
  //

  ///main widget
  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    if (decimalPlaces == 0) {
      return _integerListView(themeData);
    } else {
      return Row(
        children: <Widget>[
          _integerListView(themeData),
          _decimalListView(themeData),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
      );
    }
  }

  Widget _integerListView(ThemeData themeData) {
    TextStyle defaultStyle = themeData.textTheme.bodyText1!;
    TextStyle selectedStyle =
    themeData.textTheme.headlineSmall!.copyWith(color: themeData.primaryColor);

    int itemCount = maxValue - minValue + 3;

    return NotificationListener(
      child: Container(
        height: _listViewHeight,
        width: listViewWidth,
        child: ListView.builder(
          controller: intScrollController,
          itemExtent: itemExtent,
          itemCount: itemCount,
          cacheExtent: _calculateCacheExtent(itemCount),
          itemBuilder: (BuildContext context, int index) {
            final int value = minValue + index - 1;

            //define special style for selected (middle) element
            final TextStyle itemStyle =
            value == selectedIntValue ? selectedStyle : defaultStyle;

            bool isExtra = index == 0 || index == itemCount - 1;

            return isExtra
                ? Container() //empty first and last element
                : Center(
              child: Text(value.toString(), style: itemStyle),
            );
          },
        ),
      ),
      onNotification: _onIntegerNotification,
    );
  }

  Widget _decimalListView(ThemeData themeData) {
    TextStyle defaultStyle = themeData.textTheme.bodyText1!;
    TextStyle selectedStyle =
    themeData.textTheme.headlineSmall!.copyWith(color: themeData.primaryColor);

    int itemCount =
    selectedIntValue == maxValue ? 3 : math.pow(10, decimalPlaces).toInt() + 2;

    return NotificationListener(
      child: Container(
        height: _listViewHeight,
        width: listViewWidth,
        child: ListView.builder(
          controller: decimalScrollController,
          itemExtent: itemExtent,
          itemCount: itemCount,
          itemBuilder: (BuildContext context, int index) {
            final int value = index - 1;

            //define special style for selected (middle) element
            final TextStyle itemStyle =
            value == selectedDecimalValue ? selectedStyle : defaultStyle;

            bool isExtra = index == 0 || index == itemCount - 1;

            return isExtra
                ? Container() //empty first and last element
                : Center(
              child: Text(
                  value.toString().padLeft(decimalPlaces, '0'),
                  style: itemStyle),
            );
          },
        ),
      ),
      onNotification: _onDecimalNotification,
    );
  }

  //
  // ----------------------------- LOGIC -----------------------------
  //

  bool _onIntegerNotification(Notification notification) {
    if (notification is ScrollNotification) {
      //calculate
      int intIndexOfMiddleElement =
          (notification.metrics.pixels + _listViewHeight / 2) ~/ itemExtent;
      int intValueInTheMiddle = minValue + intIndexOfMiddleElement - 1;
      intValueInTheMiddle = _normalizeMiddleValue(intValueInTheMiddle);

      if (_userStoppedScrolling(notification, intScrollController)) {
        //center selected value
        animateInt(intValueInTheMiddle);
      }

      //update selection
      if (intValueInTheMiddle != selectedIntValue) {
        num newValue;
        if (decimalPlaces == 0) {
          //return integer value
          newValue = (intValueInTheMiddle);
        } else {
          if (intValueInTheMiddle == maxValue) {
            //if new value is maxValue, then return that value and ignore decimal
            newValue = (intValueInTheMiddle.toDouble());
            animateDecimal(0);
          } else {
            //return integer+decimal
            double decimalPart = _toDecimal(selectedDecimalValue);
            newValue = ((intValueInTheMiddle + decimalPart).toDouble());
          }
        }
        onChanged(newValue);
      }
    }
    return true;
  }

  bool _onDecimalNotification(Notification notification) {
    if (notification is ScrollNotification) {
      //calculate middle value
      int indexOfMiddleElement =
          (notification.metrics.pixels + _listViewHeight / 2) ~/ itemExtent;
      int decimalValueInTheMiddle = indexOfMiddleElement - 1;
      decimalValueInTheMiddle = _normalizeMiddleValue(decimalValueInTheMiddle);

      if (_userStoppedScrolling(notification, decimalScrollController)) {
        //center selected value
        animateDecimal(decimalValueInTheMiddle);
      }

      //update selection
      if (selectedIntValue != maxValue &&
          decimalValueInTheMiddle != selectedDecimalValue) {
        double decimalPart = _toDecimal(decimalValueInTheMiddle);
        double newValue = ((selectedIntValue + decimalPart).toDouble());
        onChanged(newValue);
      }
    }
    return true;
  }

  ///There was a bug, when if there was small integer range, e.g. from 1 to 5,
  ///When user scrolled to the top, whole listview got displayed.
  ///To prevent this we are calculating cacheExtent by our own so it gets smaller if number of items is smaller
  double _calculateCacheExtent(int itemCount) {
    double cacheExtent = 250.0; //default cache extent
    if ((itemCount - 2) * DEFAULT_ITEM_EXTENT <= cacheExtent) {
      cacheExtent = ((itemCount - 3) * DEFAULT_ITEM_EXTENT);
    }
    return cacheExtent;
  }

  ///When overscroll occurs on iOS,
  ///we can end up with value not in the range between [minValue] and [maxValue]
  ///To avoid going out of range, we change values out of range to border values.
  int _normalizeMiddleValue(int valueInTheMiddle) {
    return math.max(math.min(valueInTheMiddle, maxValue), minValue);
  }

  ///indicates if user has stopped scrolling so we can center value in the middle
  bool _userStoppedScrolling(Notification notification,
      ScrollController scrollController) {
    return notification is UserScrollNotification &&
        notification.direction == ScrollDirection.idle &&
        scrollController.position.activity is! HoldScrollActivity;
  }

  ///converts integer indicator of decimal value to double
  ///e.g. decimalPlaces = 1, value = 4  >>> result = 0.4
  ///     decimalPlaces = 2, value = 12 >>> result = 0.12
  double _toDecimal(int decimalValueAsInteger) {
    return double.parse((decimalValueAsInteger * math.pow(10, -decimalPlaces))
        .toStringAsFixed(decimalPlaces));
  }

  ///scroll to selected value
  _animate(ScrollController scrollController, double value) {
    scrollController.animateTo(value,
        duration: const Duration(seconds: 1), curve: const ElasticOutCurve());
  }
}

///Returns AlertDialog as a Widget so it is designed to be used in showDialog method
class NumberPickerDialog extends StatefulWidget {
  final int minValue;
  final int maxValue;
  final int initialIntegerValue;
  final double initialDoubleValue;
  final int decimalPlaces;
  final Widget? title;
  final EdgeInsets? titlePadding;
  final Widget? confirmWidget;
  final Widget? cancelWidget;

  ///constructor for integer values
  NumberPickerDialog.integer({
    Key? key,
    required this.minValue,
    required this.maxValue,
    required this.initialIntegerValue,
    this.title,
    this.titlePadding,
    // Widget confirmWidget,
    // Widget cancelWidget,
  })
      : confirmWidget = const Text("OK"),
        cancelWidget = const Text("CANCEL"),
        decimalPlaces = 0,
        initialDoubleValue = -1.0, super(key: key);

  ///constructor for decimal values
  NumberPickerDialog.decimal({
    required this.minValue,
    required this.maxValue,
    required this.initialDoubleValue,
    this.decimalPlaces = 1,
    this.title,
    this.titlePadding,
    // Widget confirmWidget,
    // Widget cancelWidget,
  })
      : confirmWidget = const Text("OK"),
        cancelWidget = const Text("CANCEL"),
        initialIntegerValue = -1;

  @override
  State<NumberPickerDialog> createState() =>
      _NumberPickerDialogControllerState(
          initialIntegerValue, initialDoubleValue);
}

class _NumberPickerDialogControllerState extends State<NumberPickerDialog> {
  int selectedIntValue;
  double selectedDoubleValue;

  _NumberPickerDialogControllerState(this.selectedIntValue,
      this.selectedDoubleValue);

  _handleValueChanged(num value) {
    if (value is int) {
      setState(() => selectedIntValue = value);
    } else {
      setState(() => selectedDoubleValue = value.toDouble());
    }
  }

  NumberPicker _buildNumberPicker() {
    if (widget.decimalPlaces > 0) {
      return NumberPicker.decimal(
          initialValue: selectedDoubleValue,
          minValue: widget.minValue,
          maxValue: widget.maxValue,
          decimalPlaces: widget.decimalPlaces,
          onChanged: _handleValueChanged);
    } else {
      return NumberPicker.integer(
        initialValue: selectedIntValue,
        minValue: widget.minValue,
        maxValue: widget.maxValue,
        onChanged: _handleValueChanged,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      titlePadding: widget.titlePadding,
      content: _buildNumberPicker(),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: widget.cancelWidget!,
        ),
        TextButton(
            onPressed: () =>
                Navigator.of(context).pop(widget.decimalPlaces > 0
                    ? selectedDoubleValue
                    : selectedIntValue),
            child: widget.confirmWidget!),
      ],
    );
  }
}
