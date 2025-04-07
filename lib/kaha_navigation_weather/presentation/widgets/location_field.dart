import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_with_places/kaha_navigation_weather/presentation/providers/navigation_weather_provider.dart';

class LocationField extends ConsumerStatefulWidget {
  const LocationField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    required this.isSource,
    this.onQueryChanged,
  });

  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final bool isSource;
  final Function(String query)? onQueryChanged;

  @override
  ConsumerState<LocationField> createState() => _LocationFieldState();
}

class _LocationFieldState extends ConsumerState<LocationField> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleClearField() {
    widget.controller.clear();

    if (widget.isSource) {
      ref.read(sourceDataProvider.notifier).state = null;
    } else {
      ref.read(destinationDataProvider.notifier).state = null;
    }

    widget.onQueryChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.labelText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade500),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        prefixIcon: Icon(widget.prefixIcon, color: Colors.grey.shade700),
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey.shade600),
                onPressed: _handleClearField,
              )
            : null,
      ),
      onTap: () {
        ref.read(isSelectedFieldSourceProvider.notifier).state =
            widget.isSource;
      },
      onChanged: (value) {
        _debounceTimer?.cancel();

        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          ref.read(isSelectedFieldSourceProvider.notifier).state =
              widget.isSource;

          if (value.length >= 2 || value.isEmpty) {
            widget.onQueryChanged?.call(value);
          }
        });
      },
    );
  }
}
