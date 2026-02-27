import 'package:flutter/material.dart';
import 'package:streamapp/features/iptv/data/models/iptv_country_model.dart';
import 'package:streamapp/features/iptv/data/models/iptv_enriched_channel.dart';
import 'package:streamapp/features/iptv/presentation/widgets/iptv_channel_card.dart';
import 'package:streamapp/features/iptv/presentation/pages/iptv_player_page.dart';

/// Displays a country's channels in a horizontal grid-style row.
class IptvCountryCatalogSection extends StatefulWidget {
  final String countryCode;
  final List<IptvEnrichedChannel> channels;
  final List<IptvCountryModel> allCountries;

  /// Catalog index used by the focus manager.
  final int catalogIndex;

  /// The currently globally focused catalog index (from parent focus manager).
  final int focusedCatalogIndex;

  /// The currently globally focused channel index within this catalog.
  final int focusedChannelIndex;

  const IptvCountryCatalogSection({
    super.key,
    required this.countryCode,
    required this.channels,
    required this.allCountries,
    required this.catalogIndex,
    required this.focusedCatalogIndex,
    required this.focusedChannelIndex,
  });

  @override
  State<IptvCountryCatalogSection> createState() =>
      _IptvCountryCatalogSectionState();
}

class _IptvCountryCatalogSectionState
    extends State<IptvCountryCatalogSection> {
  final ScrollController _scrollController = ScrollController();

  static const double _cardWidth = 160.0;
  static const double _cardHeight = 160.0;
  static const double _horizontalSpacing = 12.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isMyCatalogFocused =>
      widget.focusedCatalogIndex == widget.catalogIndex;

  IptvCountryModel? get _country {
    try {
      return widget.allCountries.firstWhere(
        (c) => c.code.toUpperCase() == widget.countryCode.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  void _scrollToIndex(int index) {
    if (!_scrollController.hasClients) return;
    final offset =
        (index * (_cardWidth + _horizontalSpacing)) - 60;
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(IptvCountryCatalogSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isMyCatalogFocused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToIndex(widget.focusedChannelIndex);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final country = _country;
    final countryName = country?.name ?? widget.countryCode;
    final countryFlag = country?.flag ?? '🌍';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Country header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: [
              Text(
                countryFlag,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      countryName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.channels.length} channel${widget.channels.length == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              if (_isMyCatalogFocused)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Horizontal channel row
        SizedBox(
          height: _cardHeight,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context)
                .copyWith(scrollbars: false),
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              itemCount: widget.channels.length,
              itemBuilder: (context, index) {
                final channel = widget.channels[index];
                final isFocused =
                    _isMyCatalogFocused &&
                        widget.focusedChannelIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(right: _horizontalSpacing),
                  child: SizedBox(
                    width: _cardWidth,
                    child: IptvChannelCard(
                      channel: channel,
                      isFocused: isFocused,
                      onTap: () {
                        if (channel.streamUrl != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IptvPlayerPage(
                                channel: channel,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
