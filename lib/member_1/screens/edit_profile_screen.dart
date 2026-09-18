import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dine_pulse/core/theme/app_theme.dart';
import 'package:dine_pulse/core/utils/app_utils.dart';
import 'package:dine_pulse/core/constants/app_constants.dart';
import 'package:dine_pulse/member_1/services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _phoneCtrl;
  String? _selectedCuisine;
  List<String> _selectedDietary = [];
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  final List<String> _dietaryOptions = ['Vegetarian', 'Vegan', 'Gluten-Free', 'Dairy-Free', 'Nut-Free', 'Halal', 'Kosher'];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    _selectedCuisine = user?.preferredCuisine;
    _selectedDietary = List.from(user?.dietaryPreferences ?? []);
    _notificationsEnabled = user?.notificationsEnabled ?? true;
    _emailNotifications = user?.emailNotifications ?? true;
    _smsNotifications = user?.smsNotifications ?? false;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthService>();
    final currentUser = auth.currentUser!;

    final updated = currentUser.copyWith(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      preferredCuisine: _selectedCuisine,
      dietaryPreferences: _selectedDietary,
      notificationsEnabled: _notificationsEnabled,
      emailNotifications: _emailNotifications,
      smsNotifications: _smsNotifications,
    );

    final ok = await auth.updateProfile(updated);
    if (!mounted) return;
    if (ok) {
      SnackBarHelper.showSuccess(context, 'Profile updated successfully!');
      Navigator.pop(context);
    } else {
      SnackBarHelper.showError(context, auth.error ?? 'Failed to update profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Consumer<AuthService>(
        builder: (context, auth, _) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primary.withOpacity(0.15),
                        child: Text(
                          auth.currentUser?.initials ?? '?',
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: AppTheme.primary),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Personal info section
                _SectionLabel('Personal Information'),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        validator: AppValidators.validateName,
                        decoration: const InputDecoration(labelText: 'First Name', prefixIcon: Icon(Icons.person_outlined, color: AppTheme.primary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameCtrl,
                        textCapitalization: TextCapitalization.words,
                        validator: AppValidators.validateName,
                        decoration: const InputDecoration(labelText: 'Last Name', prefixIcon: Icon(Icons.person_outlined, color: AppTheme.primary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  validator: AppValidators.validatePhone,
                  decoration: const InputDecoration(labelText: 'Phone Number (optional)', prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.primary)),
                ),
                const SizedBox(height: 14),

                // Preferences
                _SectionLabel('Food Preferences'),
                DropdownButtonFormField<String>(
                  value: _selectedCuisine,
                  decoration: const InputDecoration(labelText: 'Favourite Cuisine', prefixIcon: Icon(Icons.restaurant, color: AppTheme.primary)),
                  items: AppConstants.cuisineTypes.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCuisine = v),
                ),
                const SizedBox(height: 14),

                // Dietary preferences
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dietary Preferences', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _dietaryOptions.map((d) {
                          final isSelected = _selectedDietary.contains(d);
                          return FilterChip(
                            label: Text(d),
                            selected: isSelected,
                            onSelected: (_) => setState(() {
                              if (isSelected) _selectedDietary.remove(d);
                              else _selectedDietary.add(d);
                            }),
                            selectedColor: AppTheme.primary,
                            labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontSize: 12),
                            checkmarkColor: Colors.white,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Notifications
                _SectionLabel('Notifications'),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface, borderRadius: BorderRadius.circular(14),
                    boxShadow: const [AppTheme.cardBoxShadow],
                  ),
                  child: Column(
                    children: [
                      _NotifSwitch(
                        label: 'Push Notifications',
                        subtitle: 'Receive alerts on your device',
                        icon: Icons.notifications_outlined,
                        value: _notificationsEnabled,
                        onChanged: (v) => setState(() => _notificationsEnabled = v),
                      ),
                      const Divider(height: 1, indent: 54),
                      _NotifSwitch(
                        label: 'Email Notifications',
                        subtitle: 'Reservation confirmations by email',
                        icon: Icons.email_outlined,
                        value: _emailNotifications,
                        onChanged: (v) => setState(() => _emailNotifications = v),
                      ),
                      const Divider(height: 1, indent: 54),
                      _NotifSwitch(
                        label: 'SMS Notifications',
                        subtitle: 'Text messages for reminders',
                        icon: Icons.sms_outlined,
                        value: _smsNotifications,
                        onChanged: (v) => setState(() => _smsNotifications = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleSave,
                    child: auth.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
    );
  }
}

class _NotifSwitch extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifSwitch({required this.label, required this.subtitle, required this.icon, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
      trailing: Switch(activeColor: AppTheme.accent, value: value, onChanged: onChanged),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }
}
