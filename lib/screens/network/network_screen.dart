import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_button.dart';
import '../chat/chat_screen.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({super.key});

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserModel> _connections = [];
  List<UserModel> _pendingRequests = [];
  List<UserModel> _sentRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNetworkData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNetworkData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      final currentUserId = authService.user?.uid ?? authService.userModel?.uid;
      if (currentUserId == null) return;

      // Load mock data for demonstration
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Mock connections
      final allUsers = await firestoreService.getAllUsers();
      _connections = allUsers.take(3).toList();
      _pendingRequests = allUsers.skip(3).take(2).toList();
      _sentRequests = allUsers.skip(5).take(1).toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load network data: $e');
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections'),
        actions: [
          IconButton(
            onPressed: () => context.push('/people-search'),
            icon: const Icon(Icons.person_add),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.grey500,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Connections'),
            Tab(text: 'Requests'),
            Tab(text: 'Discover'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConnectionsTab(),
                _buildRequestsTab(),
                _buildDiscoverTab(),
              ],
            ),
    );
  }

  Widget _buildConnectionsTab() {
    if (_connections.isEmpty) {
      return _buildEmptyConnections();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _connections.length,
      itemBuilder: (context, index) {
        final connection = _connections[index];
        return _buildConnectionCard(connection);
      },
    );
  }

  Widget _buildRequestsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pending Requests
        if (_pendingRequests.isNotEmpty) ...[
          Text(
            'Pending Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 12),
          ..._pendingRequests.map((user) => _buildRequestCard(user, isPending: true)),
          const SizedBox(height: 24),
        ],
        
        // Sent Requests
        if (_sentRequests.isNotEmpty) ...[
          Text(
            'Sent Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 12),
          ..._sentRequests.map((user) => _buildRequestCard(user, isPending: false)),
        ],
        
        if (_pendingRequests.isEmpty && _sentRequests.isEmpty)
          _buildEmptyRequests(),
      ],
    );
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        // Quick Actions
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.person_add,
                  title: 'Add People',
                  subtitle: 'Find new connections',
                  onTap: () => context.push('/people-search'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.qr_code_scanner,
                  title: 'Scan QR',
                  subtitle: 'Connect via QR code',
                  onTap: () => context.push('/qr-scanner'),
                ),
              ),
            ],
          ),
        ),
        
        // Suggestions
        Expanded(
          child: _buildSuggestions(),
        ),
      ],
    );
  }

  Widget _buildEmptyConnections() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Connections Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start building your professional network by connecting with people you know.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Find People',
              onPressed: () => context.push('/people-search'),
              width: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRequests() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.grey700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connection requests will appear here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(UserModel user) {
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
            
            // Online Status
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: user.isOnline ? AppColors.success : AppColors.grey400,
                shape: BoxShape.circle,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _startChat(user),
                  icon: const Icon(Icons.message, color: AppColors.primary),
                ),
                IconButton(
                  onPressed: () => _viewProfile(user),
                  icon: const Icon(Icons.person, color: AppColors.grey600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(UserModel user, {required bool isPending}) {
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
              radius: 24,
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
                        fontSize: 16,
                      ),
                    )
                  : null,
            ),
            
            const SizedBox(width: 12),
            
            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                  if (user.position != null && user.position!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.position!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Action Buttons
            if (isPending) ...[
              CustomButton(
                text: 'Accept',
                onPressed: () => _acceptRequest(user),
                isSmall: true,
                backgroundColor: AppColors.success,
              ),
              const SizedBox(width: 8),
              CustomButton(
                text: 'Decline',
                onPressed: () => _declineRequest(user),
                isSmall: true,
                backgroundColor: AppColors.grey400,
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Suggested Connections',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.grey900,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5, // Mock suggestions
            itemBuilder: (context, index) {
              return _buildSuggestionCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(int index) {
    final suggestions = [
      {'name': 'Alex Johnson', 'position': 'Product Manager', 'company': 'TechCorp'},
      {'name': 'Maria Garcia', 'position': 'UX Designer', 'company': 'DesignCo'},
      {'name': 'David Chen', 'position': 'Data Scientist', 'company': 'AI Labs'},
      {'name': 'Sarah Wilson', 'position': 'Marketing Director', 'company': 'GrowthCo'},
      {'name': 'Mike Brown', 'position': 'Software Engineer', 'company': 'DevCorp'},
    ];
    
    final suggestion = suggestions[index];
    
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
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: Text(
                suggestion['name']![0],
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion['name']!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${suggestion['position']} at ${suggestion['company']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            CustomButton(
              text: 'Connect',
              onPressed: () => _connectToSuggestion(suggestion['name']!),
              isSmall: true,
            ),
          ],
        ),
      ),
    );
  }

  void _startChat(UserModel user) {
    // Navigate to chat with specific user
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(user: user),
      ),
    );
  }

  void _viewProfile(UserModel user) {
    // Show user profile
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.position != null) Text('Position: ${user.position}'),
            if (user.company != null) Text('Company: ${user.company}'),
            if (user.bio != null) Text('Bio: ${user.bio}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _acceptRequest(UserModel user) {
    setState(() {
      _pendingRequests.remove(user);
      _connections.add(user);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connected with ${user.fullName}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _declineRequest(UserModel user) {
    setState(() {
      _pendingRequests.remove(user);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Declined connection with ${user.fullName}'),
        backgroundColor: AppColors.grey600,
      ),
    );
  }

  void _connectToSuggestion(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connection request sent to $name'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
