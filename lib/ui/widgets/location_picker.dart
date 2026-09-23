import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/gazetteer.dart';

/// Cascading State → District → City pickers, backed by the [Gazetteer].
///
/// Location is chosen, never typed. Free-text location fields let people store
/// "mandya", "Mandya ", "Mandia" or nonsense, which then cannot be grouped,
/// counted or shown on a map. Restricting input to the gazetteer means every
/// stored place is spelt one way and always has coordinates.
///
/// The three levels are dependent: choosing a state clears the district and
/// city below it, because a district from the previous state would no longer be
/// valid. City is optional — a district is enough to place a user — but state
/// and district are required.
class LocationPicker extends StatelessWidget {
  const LocationPicker({
    super.key,
    required this.state,
    required this.district,
    required this.city,
    required this.onChanged,
    this.cityLabel = 'City / town / village',
    this.requireCity = false,
  });

  final String? state;
  final String? district;
  final String? city;

  /// Called with the full selection whenever any level changes. Values below a
  /// changed level arrive as null, so the caller's state stays consistent.
  final void Function({String? state, String? district, String? city})
  onChanged;

  final String cityLabel;
  final bool requireCity;

  @override
  Widget build(BuildContext context) {
    final districts = Gazetteer.districtsIn(state);
    final cities = Gazetteer.citiesIn(state, district);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PickerLabel('State / union territory'),
        SearchableSelectField(
          // Keyed by the current value so the field rebuilds when a parent
          // selection resets it, rather than holding a stale value.
          key: ValueKey('state-$state'),
          title: 'State / union territory',
          options: Gazetteer.stateNames,
          value: state,
          hintText: 'Select your state',
          icon: Icons.map_outlined,
          // Changing state invalidates the district and city beneath it.
          onSelected: (v) => onChanged(state: v),
          validator: (v) => v == null ? 'Select your state' : null,
        ),
        const SizedBox(height: 14),

        const _PickerLabel('District'),
        SearchableSelectField(
          key: ValueKey('district-$state-$district'),
          title: 'District',
          options: districts,
          value: districts.contains(district) ? district : null,
          hintText: state == null
              ? 'Select a state first'
              : 'Select your district',
          icon: Icons.location_city_outlined,
          enabled: state != null,
          onSelected: (v) => onChanged(state: state, district: v),
          validator: (v) => v == null ? 'Select your district' : null,
        ),
        const SizedBox(height: 14),

        _PickerLabel(cityLabel, optional: !requireCity),
        SearchableSelectField(
          key: ValueKey('city-$district-$city'),
          title: cityLabel,
          options: cities,
          value: cities.contains(city) ? city : null,
          hintText: district == null
              ? 'Select a district first'
              : 'Select your city, town or village',
          icon: Icons.place_outlined,
          enabled: district != null,
          onSelected: (v) =>
              onChanged(state: state, district: district, city: v),
          validator: (v) =>
              requireCity && v == null ? 'Select your city or town' : null,
        ),
      ],
    );
  }
}

/// A single-level country dropdown, for exporters and foreign investors.
class CountryPicker extends StatelessWidget {
  const CountryPicker({
    super.key,
    required this.country,
    required this.onChanged,
    this.label = 'Country',
  });

  final String? country;
  final ValueChanged<String?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PickerLabel(label),
        SearchableSelectField(
          key: ValueKey('country-$country'),
          title: label,
          options: Gazetteer.countryNames,
          value: Gazetteer.countryNames.contains(country) ? country : null,
          hintText: 'Select your country',
          icon: Icons.public,
          onSelected: onChanged,
          validator: (v) => v == null ? 'Select your country' : null,
        ),
      ],
    );
  }
}

/// A place field that *suggests* gazetteer names but still accepts free text.
///
/// Used where a strict dropdown would be wrong rather than helpful: a lorry
/// pickup point is often a warehouse, mandi gate or landmark that no gazetteer
/// lists. Suggesting known names pushes people onto mappable spellings — so the
/// trip shows on a map whenever it can — without blocking the genuine cases a
/// closed list would reject.
///
/// Signup deliberately does *not* use this; there, location must be exact, so
/// it uses [LocationPicker].
class PlaceAutocompleteField extends StatelessWidget {
  const PlaceAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon = Icons.place_outlined,
  });

  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (value) => Gazetteer.search(value.text),
      // Autocomplete owns its own controller, so the caller's controller is
      // kept in sync from the field builder instead of being handed over.
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
        if (textController.text != controller.text) {
          textController.text = controller.text;
        }
        return TextField(
          controller: textController,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => controller.text = v,
          onSubmitted: (_) => onSubmitted(),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(prefixIcon, size: 20),
          ),
        );
      },
      onSelected: (v) => controller.text = v,
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 360),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    title: Text(option),
                    onTap: () => onSelected(option),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A dropdown that can be filtered by typing, for closed lists too long to
/// scroll comfortably.
///
/// Selection is still strictly constrained: the search box only filters the
/// list, it is never accepted as a value, so this keeps the "no invalid names"
/// guarantee while staying usable at national scale. Uttar Pradesh alone has
/// 75 districts, and a plain dropdown of that length means hunting through an
/// unlabelled scroll for a name you already know.
///
/// Implemented as a [FormField] so it validates exactly like the
/// [DropdownButtonFormField] it replaces.
class SearchableSelectField extends FormField<String> {
  SearchableSelectField({
    super.key,
    required List<String> options,
    required String? value,
    required ValueChanged<String?> onSelected,
    required String hintText,
    required IconData icon,
    String? title,
    bool enabled = true,
    super.validator,
  }) : super(
         initialValue: options.contains(value) ? value : null,
         builder: (field) {
           final selected = field.value;
           return _SelectFieldSurface(
             text: selected,
             hintText: hintText,
             icon: icon,
             enabled: enabled,
             errorText: field.errorText,
             onTap: !enabled
                 ? null
                 : () async {
                     final picked = await showModalBottomSheet<String>(
                       context: field.context,
                       isScrollControlled: true,
                       backgroundColor: Colors.transparent,
                       builder: (_) => _SearchableSheet(
                         title: title ?? hintText,
                         options: options,
                         selected: selected,
                       ),
                     );
                     if (picked == null) return;
                     field.didChange(picked);
                     onSelected(picked);
                   },
           );
         },
       );
}

/// The closed-state appearance: deliberately styled to read as a dropdown,
/// because that is what it behaves like from the user's point of view.
class _SelectFieldSurface extends StatelessWidget {
  const _SelectFieldSurface({
    required this.text,
    required this.hintText,
    required this.icon,
    required this.enabled,
    required this.errorText,
    required this.onTap,
  });

  final String? text;
  final String hintText;
  final IconData icon;
  final bool enabled;
  final String? errorText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          errorText: errorText,
          suffixIcon: const Icon(Icons.arrow_drop_down),
          enabled: enabled,
        ),
        isEmpty: text == null,
        child: text == null
            ? Text(
                hintText,
                style: TextStyle(
                  color: enabled
                      ? Theme.of(context).hintColor
                      : AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              )
            : Text(text!, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _SearchableSheet extends StatefulWidget {
  const _SearchableSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<String> options;
  final String? selected;

  @override
  State<_SearchableSheet> createState() => _SearchableSheetState();
}

class _SearchableSheetState extends State<_SearchableSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    // Prefix matches first: typing "man" should reach Mandya before it
    // reaches somewhere that merely contains those letters.
    final prefix = <String>[];
    final contains = <String>[];
    for (final option in widget.options) {
      final lower = option.toLowerCase();
      if (q.isEmpty || lower.startsWith(q)) {
        prefix.add(option);
      } else if (lower.contains(q)) {
        contains.add(option);
      }
    }
    final results = [...prefix, ...contains];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: results.isEmpty
                    // A dead end is worth naming: the list is closed, so if a
                    // place is genuinely missing the user needs to know that
                    // rather than assume they mistyped.
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No match for "$_query".\nTry a shorter spelling.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: results.length,
                        itemBuilder: (context, i) {
                          final option = results[i];
                          final isSelected = option == widget.selected;
                          return ListTile(
                            dense: true,
                            title: Text(
                              option,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                            // Not const: AppColors.primary is re-pointed at
                            // runtime when the education palette is applied.
                            trailing: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: AppColors.primary,
                                    size: 20,
                                  )
                                : null,
                            onTap: () => Navigator.of(context).pop(option),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerLabel extends StatelessWidget {
  const _PickerLabel(this.text, {this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (optional) ...[
            const SizedBox(width: 6),
            Text(
              '(optional)',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
