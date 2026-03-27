import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinService extends ChangeNotifier {
  static const String _pinKey = 'user_pin';
  static const String _pinEnabledKey = 'pin_enabled';

  String? _pin;
  bool _isPinEnabled = false;
  bool _isLocked = false;
  bool _isLoading = true;

  bool get isPinEnabled => _isPinEnabled;
  bool get isLocked => _isLocked && _isPinEnabled;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _pin = prefs.getString(_pinKey);
    _isPinEnabled = prefs.getBool(_pinEnabledKey) ?? false;
    _isLocked = _isPinEnabled && _pin != null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setBool(_pinEnabledKey, true);
    _pin = pin;
    _isPinEnabled = true;
    _isLocked = false;
    notifyListeners();
  }

  Future<void> disablePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_pinEnabledKey, false);
    _pin = null;
    _isPinEnabled = false;
    _isLocked = false;
    notifyListeners();
  }

  bool verifyPin(String pin) {
    if (_pin == pin) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lock() {
    if (_isPinEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }

  void unlock() {
    _isLocked = false;
    notifyListeners();
  }

  Future<void> changePin(String oldPin, String newPin) async {
    if (_pin == oldPin) {
      await setPin(newPin);
    } else {
      throw Exception('PIN actual incorrecto');
    }
  }
}

class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;
  final VoidCallback? onSetup;

  const PinLockScreen({
    super.key,
    required this.onUnlock,
    this.onSetup,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final List<String> _pin = [];
  final int _pinLength = 4;
  String? _error;
  bool _isConfirming = false;
  String? _firstPin;

  void _addDigit(String digit) {
    if (_pin.length < _pinLength) {
      setState(() {
        _pin.add(digit);
        _error = null;
      });

      if (_pin.length == _pinLength) {
        _handlePinComplete();
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin.removeLast();
        _error = null;
      });
    }
  }

  void _handlePinComplete() {
    final enteredPin = _pin.join();

    if (widget.onSetup != null) {
      if (!_isConfirming) {
        _firstPin = enteredPin;
        setState(() {
          _isConfirming = true;
          _pin.clear();
        });
      } else {
        if (_firstPin == enteredPin) {
          widget.onSetup!();
        } else {
          setState(() {
            _error = 'Los PINs no coinciden';
            _pin.clear();
            _isConfirming = false;
            _firstPin = null;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0e1117) : const Color(0xFFf8f9fa),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline,
                  size: 64, color: Color(0xFFe94560)),
              const SizedBox(height: 24),
              Text(
                widget.onSetup != null
                    ? (_isConfirming
                        ? 'Confirma tu PIN'
                        : 'Crea un PIN de 4 dígitos')
                    : 'Ingresa tu PIN',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < _pin.length
                          ? const Color(0xFFe94560)
                          : Colors.transparent,
                      border: Border.all(
                        color: const Color(0xFFe94560),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFe94560)),
                ),
              ],
              const SizedBox(height: 48),
              _buildKeypad(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((d) => _buildKey(d, isDark)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((d) => _buildKey(d, isDark)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((d) => _buildKey(d, isDark)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80),
            _buildKey('0', isDark),
            _buildBackspaceKey(isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String digit, bool isDark) {
    return InkWell(
      onTap: () => _addDigit(digit),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF1a1a2e) : Colors.grey[200],
        ),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey(bool isDark) {
    return InkWell(
      onTap: _removeDigit,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        child: const Center(
          child: Icon(Icons.backspace_outlined, size: 28),
        ),
      ),
    );
  }
}
