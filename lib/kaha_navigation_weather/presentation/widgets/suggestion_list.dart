// Updated SuggestionList widget that handles AsyncValue
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SuggestionList extends ConsumerWidget {
  final AsyncValue<List?>? suggestionsAsync;
  final Function(String placeId, String description) onSelected;
  final double height;

  const SuggestionList({
    super.key,
    required this.suggestionsAsync,
    required this.onSelected,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (suggestionsAsync == null) {
      return const SizedBox.shrink();
    }

    return AnimatedSlide(
      offset: suggestionsAsync != null ? Offset.zero : const Offset(0, -0.1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: suggestionsAsync != null ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          height: height,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 450),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.7),
                ),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: suggestionsAsync!.when(
              data: (suggestions) {
                if (suggestions == null || suggestions.isEmpty) {
                  return Center(
                    key: const ValueKey('empty'),
                    child: Text(
                      'No suggestions found',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return _buildSuggestionsList(suggestions);
              },
              loading: () => Center(
                key: const ValueKey('loading'),
                child: const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (error, stack) => Center(
                key: const ValueKey('error'),
                child: Text(
                  'Error: $error',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList(List suggestions) {
    return Container(
      key: const ValueKey('suggestions'),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey.shade200,
          indent: 16,
          endIndent: 16,
        ),
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          // Extract place_id and description from the suggestion
          final placeId = suggestion.keys.first;
          final description = suggestion[placeId];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onSelected(placeId, description),
              child: ListTile(
                leading: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                title: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                horizontalTitleGap: 0,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                visualDensity: VisualDensity.compact,
                dense: true,
              ),
            ),
          );
        },
      ),
    );
  }
}
