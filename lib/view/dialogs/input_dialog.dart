import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';
import '../../view_model/dialog_view_model.dart';

class InputDialog extends StatefulWidget {
  final DialogViewModel viewModel;
  final Future<void> Function(String, String?, [bool?]) onConfirm;

  const InputDialog({
    super.key,
    required this.viewModel,
    required this.onConfirm,
  });

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> with SignalsMixin {
  late final TextEditingController _controller;
  late final TextEditingController _accountBalanceController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _accountBalanceController = TextEditingController();
    _controller.text = widget.viewModel.dialogInputValue.value;
    _accountBalanceController.text =
        widget.viewModel.dialogAccountBalanceValue.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    _accountBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Watch((_) {
        return Row(
          children: [
            Icon(_getDialogIcon(), color: Colors.deepPurpleAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.viewModel.dialogTitle.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      }),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Help text
          Watch((_) {
            return Text(
              widget.viewModel.getValidationHelpText(),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            );
          }),
          const SizedBox(height: 16),

          // Account Balance field (only for Max Drawdown dialog)
          Watch((_) {
            if (widget.viewModel.dialogType.value == DialogType.maxDrawdown) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Balance',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _accountBalanceController,
                    enabled: !_isProcessing,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your total account balance',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.deepPurpleAccent,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                      errorText:
                          widget.viewModel.dialogAccountBalanceError.value,
                      errorStyle: const TextStyle(color: Colors.red),
                      prefixIcon: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                    onChanged: (value) {
                      widget.viewModel.updateAccountBalanceValue(value);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }
            return const SizedBox.shrink();
          }),

          // Dynamic Max Drawdown Toggle (only for Max Drawdown dialog)
          Watch((_) {
            if (widget.viewModel.dialogType.value == DialogType.maxDrawdown) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade600),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          color: Colors.deepPurpleAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dynamic Max Drawdown',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Increase max drawdown when profits exceed initial balance',
                                style: TextStyle(
                                  color: Colors.grey.shade300,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: widget
                              .viewModel
                              .isDynamicMaxDrawdownEnabled
                              .value,
                          onChanged: (value) {
                            widget.viewModel.toggleDynamicMaxDrawdown(value);
                          },
                          activeColor: Colors.deepPurpleAccent,
                          inactiveThumbColor: Colors.grey.shade400,
                          inactiveTrackColor: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }
            return const SizedBox.shrink();
          }),

          // Max Drawdown Input field
          Watch((_) {
            if (widget.viewModel.dialogType.value == DialogType.maxDrawdown) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Maximum Drawdown',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }
            return const SizedBox.shrink();
          }),

          // Input field
          Watch((_) {
            return TextField(
              controller: _controller,
              enabled: !_isProcessing,
              autofocus:
                  widget.viewModel.dialogType.value != DialogType.maxDrawdown,
              keyboardType: _getKeyboardType(),
              inputFormatters: _getInputFormatters(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.viewModel.dialogHint.value,
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.deepPurpleAccent,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                errorText: widget.viewModel.dialogError.value,
                errorStyle: const TextStyle(color: Colors.red),
                prefixIcon: Icon(
                  _getPrefixIcon(),
                  color: Colors.deepPurpleAccent,
                ),
              ),
              onChanged: (value) {
                widget.viewModel.updateInputValue(value);
              },
              onSubmitted: (_) => _handleConfirm(),
            );
          }),

          // Additional info based on dialog type
          Watch((_) {
            return _buildAdditionalInfo();
          }),
        ],
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),

        // Confirm button
        Watch((_) {
          return ElevatedButton(
            onPressed: _isProcessing ? null : _handleConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(widget.viewModel.getDialogButtonText()),
          );
        }),
      ],
    );
  }

  IconData _getDialogIcon() {
    switch (widget.viewModel.dialogType.value) {
      case DialogType.maxDrawdown:
        return Icons.heart_broken;
      case DialogType.lossPerTrade:
        return Icons.percent;
      case DialogType.tradeResult:
        return Icons.add_chart;
    }
  }

  IconData _getPrefixIcon() {
    switch (widget.viewModel.dialogType.value) {
      case DialogType.maxDrawdown:
        return Icons.attach_money;
      case DialogType.lossPerTrade:
        return Icons.percent;
      case DialogType.tradeResult:
        return Icons.attach_money;
    }
  }

  TextInputType _getKeyboardType() {
    return const TextInputType.numberWithOptions(decimal: true, signed: true);
  }

  List<TextInputFormatter> _getInputFormatters() {
    return [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))];
  }

  Widget _buildAdditionalInfo() {
    switch (widget.viewModel.dialogType.value) {
      case DialogType.maxDrawdown:
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Set your account balance and maximum drawdown amount',
                  style: TextStyle(color: Colors.blue.shade300, fontSize: 11),
                ),
              ),
            ],
          ),
        );

      case DialogType.lossPerTrade:
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Maximum risk per trade as % of account balance',
                  style: TextStyle(color: Colors.orange.shade300, fontSize: 11),
                ),
              ),
            ],
          ),
        );

      case DialogType.tradeResult:
        return Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enter positive value for profit, negative for loss',
                  style: TextStyle(color: Colors.green.shade300, fontSize: 11),
                ),
              ),
            ],
          ),
        );
    }
  }

  Future<void> _handleConfirm() async {
    if (_isProcessing) return;

    final inputValue = widget.viewModel.getInputValue();
    if (inputValue == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // For Max Drawdown dialog, also pass the account balance and toggle state
      if (widget.viewModel.dialogType.value == DialogType.maxDrawdown) {
        final accountBalance = widget.viewModel.getAccountBalanceValue();
        await widget.onConfirm(
          inputValue,
          accountBalance,
          widget.viewModel.isDynamicMaxDrawdownEnabled.value,
        );
      } else {
        await widget.onConfirm(inputValue, null);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      widget.viewModel.setError(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
