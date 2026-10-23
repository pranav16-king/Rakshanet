import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/emergency_design_tokens.dart';

/// 1. Compact semantic status pill badge.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.color = AppColors.success,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: color.withValues(alpha: 0.38),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. Compact professional header (NO logo, 44x44 back button, centered title, step indicator).
class EmergencyHeader extends StatelessWidget {
  final String title;
  final String stepText;
  final VoidCallback? onBack;

  const EmergencyHeader({
    super.key,
    required this.title,
    required this.stepText,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: InkWell(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headerTitle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 32),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondarySurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              stepText,
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3. Compact horizontal progress indicator below header.
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 2,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep / totalSteps).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
      child: Row(
        children: [
          Text(
            'STEP $currentStep OF $totalSteps',
            style: const TextStyle(
              color: AppColors.cyan,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 3,
                child: Stack(
                  children: [
                    Container(color: AppColors.elevatedSurface),
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.blue, AppColors.cyan],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            currentStep == 1 ? 'Profile Details' : 'Verification',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. Compact horizontal Offline Status Card.
class OfflineStatusCard extends StatelessWidget {
  const OfflineStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Offline Ready',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    StatusBadge(
                      label: 'LOCAL STORAGE ACTIVE',
                      color: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Your emergency information is stored securely on this device.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: const [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 11,
                      color: AppColors.cyan,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'No cloud connection required',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 5. Section Header with consistent icon and title.
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? badgeText;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.elevatedSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.cyan,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
          ),
          if (badgeText != null)
            Text(
              badgeText!,
              style: AppTypography.helper,
            ),
        ],
      ),
    );
  }
}

/// 6. Standard Accessible Text Input Field with external top label, focus/valid/error states.
class AppTextField extends StatefulWidget {
  final String label;
  final String placeholder;
  final IconData icon;
  final TextEditingController controller;
  final bool isRequired;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? optionalLabel;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;

  const AppTextField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.controller,
    this.isRequired = false,
    this.readOnly = false,
    this.onTap,
    this.optionalLabel,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.inputFormatters,
    this.textInputAction = TextInputAction.next,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  String? _errorText;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    widget.controller.addListener(_handleTextChange);
  }

  void _handleFocusChange() {
    if (!mounted) return;
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (!_focusNode.hasFocus && _hasInteracted && widget.validator != null) {
        _errorText = widget.validator!(widget.controller.text);
      }
    });
  }

  void _handleTextChange() {
    if (!mounted) return;
    if (widget.controller.text.isNotEmpty) {
      _hasInteracted = true;
    }
    if (_hasInteracted && widget.validator != null) {
      final err = widget.validator!(widget.controller.text);
      if (err != _errorText) {
        setState(() => _errorText = err);
      }
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    widget.controller.removeListener(_handleTextChange);
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isValid {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return false;
    if (widget.validator != null) {
      return widget.validator!(text) == null;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: (val) {
        if (widget.validator != null) {
          final err = widget.validator!(widget.controller.text);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _errorText != err) {
              setState(() {
                _hasInteracted = true;
                _errorText = err;
              });
            }
          });
          return err;
        }
        return null;
      },
      builder: (fieldState) {
        final hasError = _errorText != null && _errorText!.isNotEmpty;
        final borderColor = hasError
            ? AppColors.danger
            : _isFocused
                ? AppColors.cyan
                : _isValid
                    ? AppColors.success.withValues(alpha: 0.45)
                    : AppColors.border;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full Non-Truncated Top Label
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: widget.label,
                      style: AppTypography.fieldLabel,
                      children: [
                        if (widget.isRequired)
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: AppColors.primaryAmber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.optionalLabel != null)
                  Text(
                    widget.optionalLabel!,
                    style: AppTypography.helper,
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Input Box (54px minimum height)
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              constraints: const BoxConstraints(minHeight: 54),
              decoration: BoxDecoration(
                color: _isFocused
                    ? AppColors.elevatedSurface
                    : AppColors.secondarySurface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: borderColor,
                  width: (_isFocused || hasError) ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    widget.icon,
                    size: 20,
                    color: hasError
                        ? AppColors.danger
                        : _isFocused
                            ? AppColors.cyan
                            : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      readOnly: widget.readOnly,
                      onTap: widget.onTap,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      inputFormatters: widget.inputFormatters,
                      style: AppTypography.inputText,
                      cursorColor: AppColors.cyan,
                      onChanged: (value) {
                        fieldState.didChange(value);
                        widget.onChanged?.call(value);
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        hintText: widget.placeholder,
                        hintStyle: AppTypography.placeholder,
                      ),
                    ),
                  ),
                  if (_isValid && !hasError) ...[
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.success,
                      ),
                    ),
                  ] else if (hasError) ...[
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: AppColors.danger,
                      ),
                    ),
                  ] else
                    const SizedBox(width: 12),
                ],
              ),
            ),

            // Inline Error Message
            if (hasError) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _errorText!,
                      style: AppTypography.errorText,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 7. Structured Phone Field with Country Code Selector + Phone Number Input.
class PhoneField extends StatefulWidget {
  final String label;
  final String selectedDialCode;
  final ValueChanged<String> onDialCodeChanged;
  final TextEditingController controller;
  final bool isRequired;
  final String? Function(String?)? validator;

  const PhoneField({
    super.key,
    required this.label,
    required this.selectedDialCode,
    required this.onDialCodeChanged,
    required this.controller,
    this.isRequired = true,
    this.validator,
  });

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  String? _errorText;
  bool _hasInteracted = false;

  static const List<String> _dialCodes = [
    '+91',
    '+1',
    '+44',
    '+61',
    '+81',
    '+971',
    '+65',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
  }

  void _onFocusChange() {
    if (!mounted) return;
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (!_focusNode.hasFocus && _hasInteracted && widget.validator != null) {
        _errorText = widget.validator!(widget.controller.text);
      }
    });
  }

  void _onTextChange() {
    if (!mounted) return;
    if (widget.controller.text.isNotEmpty) {
      _hasInteracted = true;
    }
    if (_hasInteracted && widget.validator != null) {
      final err = widget.validator!(widget.controller.text);
      if (err != _errorText) {
        setState(() => _errorText = err);
      }
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isValid {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return false;
    if (widget.validator != null) {
      return widget.validator!(text) == null;
    }
    return text.length >= 7;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: (val) {
        if (widget.validator != null) {
          final err = widget.validator!(widget.controller.text);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _errorText != err) {
              setState(() {
                _hasInteracted = true;
                _errorText = err;
              });
            }
          });
          return err;
        }
        return null;
      },
      builder: (fieldState) {
        final hasError = _errorText != null && _errorText!.isNotEmpty;
        final borderColor = hasError
            ? AppColors.danger
            : _isFocused
                ? AppColors.cyan
                : _isValid
                    ? AppColors.success.withValues(alpha: 0.45)
                    : AppColors.border;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: widget.label,
                      style: AppTypography.fieldLabel,
                      children: [
                        if (widget.isRequired)
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: AppColors.primaryAmber,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Text(
                  widget.isRequired ? 'Required' : 'Optional',
                  style: AppTypography.helper,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Country Code Selector [ +91 ▼ ]
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _dialCodes.contains(widget.selectedDialCode)
                          ? widget.selectedDialCode
                          : '+91',
                      dropdownColor: AppColors.elevatedSurface,
                      icon: const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                      style: AppTypography.inputText,
                      items: _dialCodes.map((code) {
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Text(code, style: AppTypography.inputText),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) widget.onDialCodeChanged(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Phone Number Input Box
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    constraints: const BoxConstraints(minHeight: 54),
                    decoration: BoxDecoration(
                      color: _isFocused
                          ? AppColors.elevatedSurface
                          : AppColors.secondarySurface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: borderColor,
                        width: (_isFocused || hasError) ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(
                          Icons.phone_outlined,
                          size: 20,
                          color: hasError
                              ? AppColors.danger
                              : _isFocused
                                  ? AppColors.cyan
                                  : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            focusNode: _focusNode,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9\-\s]'),
                              ),
                              LengthLimitingTextInputFormatter(15),
                            ],
                            style: AppTypography.inputText,
                            cursorColor: AppColors.cyan,
                            onChanged: (v) => fieldState.didChange(v),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 15),
                              hintText: 'Emergency contact number',
                              hintStyle: AppTypography.placeholder,
                            ),
                          ),
                        ),
                        if (_isValid && !hasError)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: AppColors.success,
                            ),
                          )
                        else if (hasError)
                          const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: AppColors.danger,
                            ),
                          )
                        else
                          const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (hasError) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _errorText!,
                      style: AppTypography.errorText,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 8. Non-overflowing Accessible Dropdown Field.
class DropdownField<T> extends StatelessWidget {
  final String label;
  final String placeholder;
  final IconData icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? optionalLabel;

  const DropdownField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.optionalLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.fieldLabel,
              ),
            ),
            if (optionalLabel != null)
              Text(
                optionalLabel!,
                style: AppTypography.helper,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    hint: Text(
                      placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.placeholder,
                    ),
                    dropdownColor: AppColors.elevatedSurface,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    style: AppTypography.inputText,
                    items: items,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 9. Multiline Optional Medical Conditions Field.
class MedicalField extends StatefulWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;

  const MedicalField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
  });

  @override
  State<MedicalField> createState() => _MedicalFieldState();
}

class _MedicalFieldState extends State<MedicalField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: AppTypography.fieldLabel),
            const Text('Optional', style: AppTypography.helper),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _isFocused
                ? AppColors.elevatedSurface
                : AppColors.secondarySurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: _isFocused ? AppColors.cyan : AppColors.border,
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.medical_services_outlined,
                  size: 20,
                  color:
                      _isFocused ? AppColors.cyan : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  minLines: 2,
                  maxLines: 4,
                  style: AppTypography.inputText,
                  cursorColor: AppColors.cyan,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 2),
                    hintText: widget.placeholder,
                    hintStyle: AppTypography.placeholder,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 10. Dominant Primary CTA Button (48px height, Emergency Amber #FFB800, dark text, right arrow).
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData trailingIcon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.trailingIcon = Icons.arrow_forward_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryAmber,
          foregroundColor: AppColors.textOnAmber,
          disabledBackgroundColor:
              AppColors.primaryAmber.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.textOnAmber,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textOnAmber,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    trailingIcon,
                    size: 18,
                    color: AppColors.textOnAmber,
                  ),
                ],
              ),
      ),
    );
  }
}

/// 11. Compact Privacy / Security Note below the CTA.
class SecurityNote extends StatelessWidget {
  const SecurityNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Icon(
            Icons.lock_outline_rounded,
            size: 13,
            color: AppColors.textMuted,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Your emergency profile is stored locally on this device. Available offline without internet.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 12. Review Summary Card for Step 2 (Review & Confirm).
class ReviewItemRow {
  final String label;
  final String value;

  const ReviewItemRow({required this.label, required this.value});
}

class ReviewCard extends StatelessWidget {
  final IconData icon;
  final String categoryTitle;
  final List<ReviewItemRow> rows;
  final VoidCallback onEdit;

  const ReviewCard({
    super.key,
    required this.icon,
    required this.categoryTitle,
    required this.rows,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.cyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  categoryTitle.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 36),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: AppColors.cyan,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.borderSubtle, height: 20),
          ...rows.map((row) {
            final isNotProvided =
                row.value.trim().isEmpty || row.value == 'Not specified';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.label,
                      style: AppTypography.fieldLabel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(
                      isNotProvided ? 'Not specified' : row.value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: isNotProvided
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight:
                            isNotProvided ? FontWeight.w400 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
