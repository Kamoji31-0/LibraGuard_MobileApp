import 'package:flutter/material.dart';
import 'services/pc_service.dart';

class PcSelectionScreen extends StatefulWidget {
  const PcSelectionScreen({super.key});

  @override
  State<PcSelectionScreen> createState() => _PcSelectionScreenState();
}

class _PcSelectionScreenState extends State<PcSelectionScreen> {
  Color get _primaryColor => Theme.of(context).primaryColor;
  Color get _accentColor => Theme.of(context).colorScheme.secondary;
  Color get _backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get _textColor =>
      Theme.of(context).textTheme.bodyLarge?.color ?? const Color(0xFF1D2939);
  Color get _cardColor => Theme.of(context).cardColor;
  Color get _availableColor => const Color(0xFF4ADE80);

  final PcService _pcService = PcService();

  List<LibraryComputer> _computers = [];
  bool _isLoading = true;
  String? _errorMessage;

  LibraryComputer? _selectedComputer;
  int _durationMinutes = 60;

  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _loadComputers();
  }

  Future<void> _loadComputers() async {

    final cached = await _pcService.getPersistentCachedComputers();
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _computers = cached;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

final computers = await _pcService.fetchComputers();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (computers.isEmpty && _computers.isEmpty) {

        _computers = List.generate(
          8,
          (i) => LibraryComputer(
            id: 'PC-0${i + 1}',
            name: 'PC-0${i + 1}',
            status: 'Available',
          ),
        );
        _errorMessage = 'Could not load live data. Showing local list.';
      } else if (computers.isNotEmpty) {
        _computers = computers;
        _errorMessage = null;
      }
    });
  }

  Future<void> _submitReservation() async {
    if (_selectedComputer == null) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final res = await _pcService.submitReservation(
      computerId: _selectedComputer!.id,
      durationMinutes: _durationMinutes,
    );

    if (!mounted) return;

    if (res['success'] == true) {
      final session = res['session'] as PcSession?;
      _showSuccessSheet(session);
    } else {
      setState(() {
        _isSubmitting = false;
        _submitError = res['message'] ?? 'Something went wrong.';
      });
    }
  }

  void _showSuccessSheet(PcSession? session) {
    setState(() => _isSubmitting = false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          left: 24,
          right: 24,
          top: 32,
        ),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryColor,
                    const Color(0xFF5E0000),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CONNECTION STATUS',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Icon(Icons.desktop_windows_outlined,
                          color: Colors.white70, size: 20),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Awaiting Approval',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('COMPUTER',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 9,
                                    letterSpacing: 1.2)),
                            const SizedBox(height: 4),
                            Text(
                              session?.computerName ??
                                  _selectedComputer?.name ??
                                  '---',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('REQ. DURATION',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 9,
                                    letterSpacing: 1.2)),
                            const SizedBox(height: 4),
                            Text(
                              session?.duration ?? _durationLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time,
                      color: Color(0xFFF59E0B), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your reservation is pending librarian approval. '
                      'Please present your RFID card when you arrive.',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.75),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Back to Home',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _durationLabel {
    final h = _durationMinutes ~/ 60;
    final m = _durationMinutes % 60;
    return h > 0
        ? '$h Hour${h > 1 ? 's' : ''} ${m > 0 ? '$m Min' : ''}'.trim()
        : '$m Minutes';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _primaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Computer Reservation',
                      style: TextStyle(
                        color: _accentColor,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RESERVE A LIBRARY COMPUTER',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.desktop_windows_outlined,
                            color: _textColor.withOpacity(0.8), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Computer Lab',
                          style: TextStyle(
                            color: _textColor.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.wifi_off,
                              color: Colors.orange.shade400, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                  color: Colors.orange.shade700, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildComputerGrid(),
                    const SizedBox(height: 24),
                    _buildReservationDetails(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildComputerGrid() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _textColor.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MAIN COMPUTER DESK',
                style: TextStyle(
                  color: _textColor.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: _loadComputers,
                child: Icon(Icons.refresh,
                    color: _textColor.withOpacity(0.4), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              _buildLegendDot(_availableColor, 'Available'),
              const SizedBox(width: 16),
              _buildLegendDot(Colors.orange, 'In Use'),
              const SizedBox(width: 16),
              _buildLegendDot(_primaryColor, 'Selected'),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: _computers.map((pc) => _buildPcNode(pc)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: _textColor.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPcNode(LibraryComputer pc) {
    final isSelected = _selectedComputer?.id == pc.id;
    final Color dotColor = isSelected
        ? _primaryColor
        : (pc.isAvailable ? _availableColor : Colors.orange);

    return GestureDetector(
      onTap:
          pc.isAvailable ? () => setState(() => _selectedComputer = pc) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.08) : _cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? _primaryColor
                : (pc.isAvailable
                    ? _textColor.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.4)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 7,
              right: 7,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.desktop_windows,
                    color: isSelected ? _primaryColor : dotColor,
                    size: 26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pc.name,
                    style: TextStyle(
                      color: isSelected ? _primaryColor : _textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _textColor.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reservation Details',
            style: TextStyle(
                color: _textColor, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

Text('Selected Computer',
              style:
                  TextStyle(color: _textColor.withOpacity(0.6), fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            children: [
              if (_selectedComputer != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _accentColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    _selectedComputer!.name,
                    style: TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                Text(
                  'Tap a computer above to select',
                  style: TextStyle(
                      color: _textColor.withOpacity(0.4), fontSize: 13),
                ),
            ],
          ),

          const SizedBox(height: 20),

Text('Session Duration',
              style:
                  TextStyle(color: _textColor.withOpacity(0.6), fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [15, 30, 60, 120].map((mins) {
              final selected = _durationMinutes == mins;
              final label = mins < 60
                  ? '$mins Min'
                  : (mins == 60 ? '1 Hour' : '${mins ~/ 60} Hours');
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _durationMinutes = mins),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? _primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? _primaryColor
                            : _textColor.withOpacity(0.1),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: selected ? Colors.white : _textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

if (_submitError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF800000).withOpacity(0.05)
                    : Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF800000).withOpacity(0.2)
                        : Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF800000)
                          : Colors.red.shade700,
                      size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_submitError!,
                        style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF800000)
                                : Colors.red.shade700,
                            fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          Row(
            children: [
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _textColor,
                  side: BorderSide(color: _textColor.withOpacity(0.1)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_selectedComputer == null || _isSubmitting)
                      ? null
                      : _submitReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _textColor.withOpacity(0.05),
                    disabledForegroundColor: _textColor.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _selectedComputer == null
                              ? 'Select a Computer'
                              : 'Confirm Reservation',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
