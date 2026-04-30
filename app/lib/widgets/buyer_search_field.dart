import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/buyer.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Autocomplete text field for searching/selecting existing buyers
/// or entering a new buyer name.
class BuyerSearchField extends ConsumerStatefulWidget {
  final Buyer? initialBuyer;
  final ValueChanged<Buyer?> onBuyerSelected;
  final ValueChanged<String> onNewBuyerName;

  const BuyerSearchField({
    super.key,
    this.initialBuyer,
    required this.onBuyerSelected,
    required this.onNewBuyerName,
  });

  @override
  ConsumerState<BuyerSearchField> createState() => _BuyerSearchFieldState();
}

class _BuyerSearchFieldState extends ConsumerState<BuyerSearchField> {
  late TextEditingController _controller;
  Buyer? _selectedBuyer;
  List<Buyer> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialBuyer?.buyerName ?? '',
    );
    _selectedBuyer = widget.initialBuyer;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _selectedBuyer = null;
      });
      widget.onBuyerSelected(null);
      return;
    }

    final buyerService = ref.read(buyerServiceProvider);
    final results = await buyerService.searchBuyers(query);

    setState(() {
      _suggestions = results;
      _showSuggestions = results.isNotEmpty;
      _selectedBuyer = null;
    });

    widget.onNewBuyerName(query.trim());
  }

  void _selectBuyer(Buyer buyer) {
    _controller.text = buyer.buyerName;
    setState(() {
      _selectedBuyer = buyer;
      _showSuggestions = false;
    });
    widget.onBuyerSelected(buyer);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onSearchChanged,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: 'Buyer Name',
            hintText: 'Type to search or add new buyer',
            prefixIcon: const Icon(Icons.person, size: 24),
            suffixIcon: _selectedBuyer != null
                ? Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedBuyer!.buyerCode,
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  )
                : (_controller.text.isNotEmpty
                    ? Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: AppTheme.accentAmber,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : null),
          ),
        ),

        // Suggestions dropdown
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cardShadow,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final buyer = _suggestions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                    child: Text(
                      buyer.buyerName[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    buyer.buyerName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    buyer.buyerCode,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textMedium),
                  ),
                  onTap: () => _selectBuyer(buyer),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                );
              },
            ),
          ),
      ],
    );
  }
}
