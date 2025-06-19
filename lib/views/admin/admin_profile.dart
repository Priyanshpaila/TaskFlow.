// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../state/auth_state.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController usernameController;
  late TextEditingController emailController;
  final currentPassController = TextEditingController();
  final newPassController = TextEditingController();
  final searchController = TextEditingController();

  late TabController _tabController;

  bool isLoading = false;
  bool isLoadingUsers = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;

  List<User> divisionUsers = [];
  List<User> filteredUsers = [];
  String selectedFilter = 'All';
  Set<String> selectedUsers = {};

  final List<String> userFilters = ['All', 'Active', 'Inactive', 'Pending'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final admin = ref.read(authStateProvider).value!;
    usernameController = TextEditingController(text: admin.username);
    emailController = TextEditingController(text: admin.email);
    _fetchDivisionUsers();

    searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _tabController.dispose();
    usernameController.dispose();
    emailController.dispose();
    currentPassController.dispose();
    newPassController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDivisionUsers() async {
    setState(() => isLoadingUsers = true);
    try {
      final users = await UserService().getAllUsers();
      setState(() {
        divisionUsers = users.where((u) => u.role != 'admin').toList();
        _filterUsers();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching users: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => isLoadingUsers = false);
    }
  }

  void _filterUsers() {
    setState(() {
      filteredUsers =
          divisionUsers.where((user) {
            final matchesSearch =
                user.username.toLowerCase().contains(
                  searchController.text.toLowerCase(),
                ) ||
                user.email.toLowerCase().contains(
                  searchController.text.toLowerCase(),
                );

            final matchesFilter =
                selectedFilter == 'All' ||
                (selectedFilter == 'Active' && user.status == 'active') ||
                (selectedFilter == 'Inactive' && user.status == 'inactive') ||
                (selectedFilter == 'Pending' && user.status == 'pending');

            return matchesSearch && matchesFilter;
          }).toList();
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      await UserService().updateUserProfile(
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        currentPassword: currentPassController.text.trim(),
        newPassword: newPassController.text.trim(),
      );

      await ref
          .read(authStateProvider.notifier)
          .login(
            emailController.text.trim(),
            currentPassController.text.isNotEmpty
                ? newPassController.text.trim()
                : currentPassController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Clear password fields after successful update
        currentPassController.clear();
        newPassController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    try {
      final newStatus = user.status == 'active' ? 'inactive' : 'active';
      // await UserService().updateUserStatus(user.id, newStatus);

      setState(() {
        final index = divisionUsers.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          divisionUsers[index] = user.copyWith(status: newStatus);
          _filterUsers();
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${user.username} ${newStatus == 'active' ? 'activated' : 'deactivated'}',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user status: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showUserDetails(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildUserDetailsSheet(user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(authStateProvider).value!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Admin Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildProfileTab(admin), _buildUsersTab()],
      ),
    );
  }

  Widget _buildProfileTab(User admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildAdminHeader(admin),
          const SizedBox(height: 32),
          _buildProfileForm(),
          const SizedBox(height: 32),
          _buildStatsCards(),
        ],
      ),
    );
  }

  Widget _buildAdminHeader(User admin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.admin_panel_settings,
              size: 50,
              color: Colors.deepPurple.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            admin.username,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Administrator',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  admin.division,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: usernameController,
              label: 'Username',
              icon: Icons.person_outline,
              readOnly: true,
              validator:
                  (val) =>
                      val == null || val.isEmpty
                          ? "Username is required"
                          : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
              validator:
                  (val) =>
                      val != null && val.contains("@")
                          ? null
                          : "Enter a valid email",
            ),
            const SizedBox(height: 24),
            const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: currentPassController,
              label: 'Current Password',
              icon: Icons.lock_outline,
              obscureText: _obscureCurrentPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrentPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed:
                    () => setState(
                      () => _obscureCurrentPassword = !_obscureCurrentPassword,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: newPassController,
              label: 'New Password',
              icon: Icons.lock_outline,
              obscureText: _obscureNewPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed:
                    () => setState(
                      () => _obscureNewPassword = !_obscureNewPassword,
                    ),
              ),
              validator: (val) {
                if (currentPassController.text.isNotEmpty &&
                    (val == null || val.length < 6)) {
                  return 'New password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child:
                    isLoading
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'UPDATE PROFILE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final activeUsers = divisionUsers.where((u) => u.status == 'active').length;
    final inactiveUsers =
        divisionUsers.where((u) => u.status == 'inactive').length;
    final pendingUsers =
        divisionUsers.where((u) => u.status == 'pending').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Division Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Users',
                divisionUsers.length.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Active',
                activeUsers.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Inactive',
                inactiveUsers.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Pending',
                pendingUsers.toString(),
                Icons.hourglass_empty,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        _buildUserControls(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchDivisionUsers,
            color: Colors.deepPurple,
            child:
                isLoadingUsers
                    ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple,
                        ),
                      ),
                    )
                    : _buildUsersList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUserControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.filter_list, color: Colors.white),
                ),
                onSelected: (value) {
                  setState(() {
                    selectedFilter = value;
                    _filterUsers();
                  });
                },
                itemBuilder:
                    (context) =>
                        userFilters
                            .map(
                              (filter) => PopupMenuItem(
                                value: filter,
                                child: Text(filter),
                              ),
                            )
                            .toList(),
              ),
            ],
          ),
          if (selectedUsers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text('${selectedUsers.length} selected'),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => selectedUsers.clear()),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
                TextButton.icon(
                  onPressed: _bulkToggleStatus,
                  icon: const Icon(Icons.toggle_on),
                  label: const Text('Toggle Status'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final isSelected = selectedUsers.contains(user.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border:
                isSelected
                    ? Border.all(color: Colors.deepPurple, width: 2)
                    : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: _getUserStatusColor(
                    user.status,
                  ).withOpacity(0.2),
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getUserStatusColor(user.status),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getUserStatusColor(user.status),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              user.username,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(user.email),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getUserStatusColor(
                          user.status,
                        ).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getUserStatusColor(user.status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.role.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.deepPurple),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          onTap: () => _showUserDetails(user),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: () => _toggleUserStatus(user),
                          child: Row(
                            children: [
                              Icon(
                                user.status == 'active'
                                    ? Icons.block
                                    : Icons.check_circle,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                user.status == 'active'
                                    ? 'Deactivate'
                                    : 'Activate',
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ),
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedUsers.remove(user.id);
                } else {
                  selectedUsers.add(user.id);
                }
              });
            },
            onLongPress: () => _showUserDetails(user),
          ),
        );
      },
    );
  }

  Widget _buildUserDetailsSheet(User user) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: _getUserStatusColor(
                          user.status,
                        ).withOpacity(0.2),
                        child: Text(
                          user.username[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _getUserStatusColor(user.status),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.username,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildDetailRow('Status', user.status.toUpperCase()),
                  _buildDetailRow('Role', user.role.toUpperCase()),
                  _buildDetailRow('Division', user.division),
                  _buildDetailRow('User ID', user.id),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _toggleUserStatus(user);
                          },
                          icon: Icon(
                            user.status == 'active'
                                ? Icons.block
                                : Icons.check_circle,
                          ),
                          label: Text(
                            user.status == 'active' ? 'Deactivate' : 'Activate',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                user.status == 'active'
                                    ? Colors.red
                                    : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          label: const Text('Close'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Color _getUserStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _bulkToggleStatus() {
    // Implement bulk status toggle
    for (final userId in selectedUsers) {
      final user = divisionUsers.firstWhere((u) => u.id == userId);
      _toggleUserStatus(user);
    }
    setState(() => selectedUsers.clear());
  }
}

// Extension to add copyWith method to User model
extension UserExtension on User {
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? division,
    String? status,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      division: division ?? this.division,
      status: status ?? this.status,
    );
  }
}
