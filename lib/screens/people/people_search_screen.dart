import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PeopleSearchScreen extends StatefulWidget {
  const PeopleSearchScreen({super.key});

  @override
  State<PeopleSearchScreen> createState() => _PeopleSearchScreenState();
}

class _PeopleSearchScreenState extends State<PeopleSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  List<String> _sentRequests = [];
  List<String> _receivedRequests = [];
  List<String> _connections = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      // Get current user ID
      final currentUserId = authService.user?.uid ?? authService.userModel?.uid;
      if (currentUserId == null) return;

      // Load all users except current user
      final users = await firestoreService.getAllUsers();
      final filteredUsers = users.where((user) => user.uid != currentUserId).toList();
      
      // Load user's connections and requests
      final connections = await firestoreService.getUserConnections(currentUserId);
      final sentRequests = await firestoreService.getSentConnectionRequests(currentUserId);
      final receivedRequests = await firestoreService.getReceivedConnectionRequests(currentUserId);

      if (mounted) {
        setState(() {
          _allUsers = filteredUsers;
          _filteredUsers = filteredUsers;
          _connections = connections.map((c) => c.uid).toList();
          _sentRequests = sentRequests.map((r) => r.uid).toList();
          _receivedRequests = receivedRequests.map((r) => r.uid).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load users: $e');
      }
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          return user.fullName.toLowerCase().contains(query.toLowerCase()) ||
                 (user.company?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                 (user.position?.toLowerCase().contains(query.toLowerCase()) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _sendConnectionRequest(String targetUserId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      final currentUserId = authService.user?.uid ?? authService.userModel?.uid;
      if (currentUserId == null) return;

      await firestoreService.sendConnectionRequest(currentUserId, targetUserId);
      
      setState(() {
        _sentRequests.add(targetUserId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection request sent!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to send request: $e');
    }
  }

  Future<void> _acceptConnectionRequest(String targetUserId) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      final currentUserId = authService.user?.uid ?? authService.userModel?.uid;
      if (currentUserId == null) return;

      await firestoreService.acceptConnectionRequest(targetUserId, currentUserId);
      
      setState(() {
        _connections.add(targetUserId);
        _receivedRequests.remove(targetUserId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection accepted!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to accept request: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover People'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              controller: _searchController,
              label: 'Search People',
              hint: 'Search by name, company, or position...',
              prefixIcon: Icons.search,
              onChanged: _filterUsers,
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : _buildUsersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
            size: 64,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty 
                ? 'No users found'
                : 'No results for "$_searchQuery"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Be the first to join!'
                : 'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isConnected = _connections.contains(user.uid);
    final hasSentRequest = _sentRequests.contains(user.uid);
    final hasReceivedRequest = _receivedRequests.contains(user.uid);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              backgroundImage: user.profileImageUrl != null 
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: user.profileImageUrl == null
                  ? Text(
                      user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                  if (user.position != null && user.position!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.position!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                  if (user.company != null && user.company!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.company!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Action Button
            _buildActionButton(user, isConnected, hasSentRequest, hasReceivedRequest),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(UserModel user, bool isConnected, bool hasSentRequest, bool hasReceivedRequest) {
    if (isConnected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 16, color: AppColors.success),
            const SizedBox(width: 4),
            Text(
              'Connected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    } else if (hasSentRequest) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              'Pending',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      );
    } else if (hasReceivedRequest) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomButton(
            text: 'Accept',
            onPressed: () => _acceptConnectionRequest(user.uid),
            isSmall: true,
            backgroundColor: AppColors.success,
          ),
          const SizedBox(width: 8),
          CustomButton(
            text: 'Decline',
            onPressed: () {
              // TODO: Implement decline functionality
            },
            isSmall: true,
            backgroundColor: AppColors.grey400,
          ),
        ],
      );
    } else {
      return CustomButton(
        text: 'Connect',
        onPressed: () => _sendConnectionRequest(user.uid),
        isSmall: true,
      );
    }
  }
}
