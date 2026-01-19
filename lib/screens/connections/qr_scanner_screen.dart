import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../constants/app_colors.dart';
import '../../services/connection_request_service.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import '../chat/group_chat_screen.dart';
import 'search_users_screen.dart';
import '../../utils/haptics.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleQRCode(String qrData) async {
    try {
      await Haptics.scanSuccess();
      // Check if it's a group QR code
      if (qrData.startsWith('vynco://group/')) {
        final inviteCode = qrData.replaceFirst('vynco://group/', '');
        await _joinGroup(inviteCode);
        return;
      }

      // Handle user connection QR code (fast-path)
      Map<String, dynamic>? user;
      String? scannedUserId;
      if (qrData.startsWith('vynco://user/')) {
        scannedUserId = qrData.split('/').last;
        // Fetch user details from Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(scannedUserId).get();
        if (userDoc.exists) {
          user = userDoc.data();
          user?['id'] = scannedUserId;
        } else {
          user = {'id': scannedUserId};
        }
      } else {
        final connectionRequestService = ConnectionRequestService();
        user = await connectionRequestService.getUserByQRCode(qrData);
        scannedUserId = user?['id'];
      }

      if (scannedUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        }
        return;
      }

      // Create mutual connections for both users without pre-check queries
      await _connectInstant(scannedUserId, displayNameHint: user?['fullName'] ?? user?['username']);

      // Close the scanner screen once connection is made
      if (mounted) {
        // Get root navigator context before popping to show dialog after closing scanner
        final rootNavigator = Navigator.of(context, rootNavigator: true);
        Navigator.of(context).pop();
        // Show hovering options to add to group, create group, or add later in the previous screen context
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (rootNavigator.context.mounted) {
            _showScannedUserActions({'id': scannedUserId, ...?user}, rootNavigator.context);
          }
        });
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing QR code: $e')),
        );
      }
    }
  }

  void _showScannedUserActions(Map<String, dynamic> user, BuildContext dialogContext) {
    final String displayName = (user['fullName'] ?? user['username'] ?? 'User');
    showDialog(
      context: dialogContext,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1F295B).withOpacity(0.9),
                      const Color(0xFF283B89).withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF6B8FAE).withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: const Color(0xFF1F295B).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with icon and title
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Connect with',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Action buttons
                      _buildActionButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _selectGroupAndAdd(user, dialogContext);
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('You have successfully connected with $displayName')),
                            );
                          }
                        },
                        icon: Icons.group_add,
                        label: 'Add to Group',
                        isPrimary: true,
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _createGroupAndAdd(user, dialogContext);
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('You have successfully connected with $displayName')),
                            );
                          }
                        },
                        icon: Icons.add_circle_outline,
                        label: 'Create Group',
                        isPrimary: false,
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          if (dialogContext.mounted) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('Added $displayName to your connections')),
                            );
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('You have successfully connected with $displayName')),
                            );
                          }
                        },
                        icon: Icons.person_add_alt_1,
                        label: 'Add to Connections',
                        isPrimary: false,
                      ),
                      const SizedBox(height: 24),
                      
                      // Info text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Tip: You can add them to groups later from Connections',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              )
            : null,
        color: isPrimary ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrimary
              ? AppColors.primary.withOpacity(0.5)
              : AppColors.textPrimary.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? AppColors.white : AppColors.textPrimary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? AppColors.white : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectGroupAndAdd(Map<String, dynamic> user, BuildContext hostContext) async {
    final auth = Provider.of<AuthService>(hostContext, listen: false);
    if (auth.user == null) return;
    final groups = await GroupService.getUserGroups(auth.user!.uid).first;

    String? selectedGroupId = groups.isNotEmpty ? groups.first.id : null;

    await showDialog(
      context: hostContext,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.grey800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Choose Group', style: TextStyle(color: AppColors.textPrimary)),
          content: DropdownButtonFormField<String>(
            value: selectedGroupId,
            dropdownColor: AppColors.grey800,
            decoration: const InputDecoration(
              filled: true,
              fillColor: AppColors.grey50,
              border: OutlineInputBorder(),
              labelText: 'Group',
              labelStyle: TextStyle(color: AppColors.textSecondary),
            ),
            items: groups
                .map((g) => DropdownMenuItem<String>(
                      value: g.id,
                      child: Text(g.name, style: const TextStyle(color: AppColors.textPrimary)),
                    ))
                .toList(),
            onChanged: (v) => selectedGroupId = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                if (selectedGroupId == null) return;
                try {
                  await GroupService.addConnectionToGroup(
                    groupId: selectedGroupId!,
                    connectionId: '${auth.user!.uid}_${user['id']}',
                    connectionUserId: user['id'],
                  );
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (hostContext.mounted) {
                    ScaffoldMessenger.of(hostContext).showSnackBar(
                      SnackBar(content: Text('Added ${user['fullName'] ?? user['username']} to group')),
                    );
                  }
                } catch (e) {
                  if (hostContext.mounted) {
                    ScaffoldMessenger.of(hostContext).showSnackBar(
                      SnackBar(content: Text('Failed to add to group: $e')),
                    );
                  }
                }
              },
              child: const Text('Add', style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createGroupAndAdd(Map<String, dynamic> user, BuildContext hostContext) async {
    final auth = Provider.of<AuthService>(hostContext, listen: false);
    if (auth.user == null) return;

    final nameController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: hostContext,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.grey800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Create Group', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.grey900),
                decoration: const InputDecoration(
                  labelText: 'Group name',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                style: const TextStyle(color: AppColors.grey900),
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                try {
                  final groupId = await GroupService.createGroup(
                    name: name,
                    description: descController.text.trim(),
                    createdBy: auth.user!.uid,
                  );
                  await GroupService.addConnectionToGroup(
                    groupId: groupId,
                    connectionId: '${auth.user!.uid}_${user['id']}',
                    connectionUserId: user['id'],
                  );
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (hostContext.mounted) {
                    ScaffoldMessenger.of(hostContext).showSnackBar(
                      SnackBar(content: Text('Created "$name" and added ${user['fullName'] ?? user['username']}')),
                    );
                  }
                } catch (e) {
                  if (hostContext.mounted) {
                    ScaffoldMessenger.of(hostContext).showSnackBar(
                      SnackBar(content: Text('Failed to create group: $e')),
                    );
                  }
                }
              },
              child: const Text('Create', style: TextStyle(color: AppColors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _connectInstant(String otherUserId, {String? displayNameHint}) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final me = authService.user;
      if (me == null) {
        throw Exception('User not logged in');
      }

      if (otherUserId == me.uid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You cannot connect with yourself')),
          );
        }
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();

      // Deterministic doc ids avoid read-before-write; create() fails if exists
      final myDocId = '${me.uid}_$otherUserId';
      final theirDocId = '${otherUserId}_${me.uid}';

      final batch = firestore.batch();
      final myRef = firestore.collection('connections').doc(myDocId);
      final theirRef = firestore.collection('connections').doc(theirDocId);

      // Prepare minimal payloads
      final myData = {
        'id': myDocId,
        'userId': me.uid,
        'contactUserId': otherUserId,
        'contactName': displayNameHint ?? '',
        'contactEmail': '',
        'contactPhone': null,
        'contactCompany': null,
        'connectionNote': 'Added via QR scan',
        'connectionMethod': 'QR Scan',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isNewConnection': true,
      };

      final myName = authService.userModel?.fullName ?? me.displayName ?? '';
      final myEmail = authService.userModel?.email ?? me.email ?? '';
      final theirData = {
        'id': theirDocId,
        'userId': otherUserId,
        'contactUserId': me.uid,
        'contactName': myName,
        'contactEmail': myEmail,
        'contactPhone': null,
        'contactCompany': null,
        'connectionNote': 'Added via QR scan',
        'connectionMethod': 'QR Scan',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'isNewConnection': true,
      };

      // Set both connections
      batch.set(myRef, myData, SetOptions(merge: true));
      batch.set(theirRef, theirData, SetOptions(merge: true));
      
      debugPrint('🔄 Committing bidirectional connections...');
      debugPrint('   - myDocId: $myDocId (userId: ${me.uid} -> contactUserId: $otherUserId)');
      debugPrint('   - theirDocId: $theirDocId (userId: $otherUserId -> contactUserId: ${me.uid})');
      debugPrint('   - myData: ${myData}');
      debugPrint('   - theirData: ${theirData}');
      
      await batch.commit();
      
      debugPrint('✅ Successfully created bidirectional connections!');

      // Fire-and-forget notification for the other user
      try {
        final senderName = authService.userModel?.fullName ?? me.displayName ?? 'Someone';
        await firestore.collection('notifications').add({
          'receiverId': otherUserId,
          'title': 'New Connection',
          'body': '$senderName added you using your digital card',
          'data': {
            'type': 'connection_added',
            'senderId': me.uid,
            'senderName': senderName,
          },
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'connection_added',
        });
      } catch (_) {}

      if (mounted) {
        final name = displayNameHint ?? 'user';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $name to your connections')),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in _connectInstant: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding connection: $e')),
        );
      }
    }
  }

  Future<void> _joinGroup(String inviteCode) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.user == null) return;

      // Get group by invite code
      final group = await GroupService.getGroupByInviteCode(inviteCode);
      if (group == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group not found')),
          );
        }
        return;
      }

      // Close the scanner screen once group is found
      if (mounted) {
        final rootNavigator = Navigator.of(context, rootNavigator: true);
        Navigator.of(context).pop();
        // Show group info dialog in the previous screen context
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (rootNavigator.context.mounted) {
            _showGroupJoinDialog(inviteCode, group, rootNavigator.context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error joining group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGroupJoinDialog(String inviteCode, dynamic group, BuildContext dialogContext) {
    final authService = Provider.of<AuthService>(dialogContext, listen: false);
    if (authService.user == null) return;

    showDialog(
      context: dialogContext,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Join Group',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Color(int.parse(group.color.replaceFirst('#', '0xFF'))),
              child: const Icon(
                Icons.group,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              group.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              group.description,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${group.members.length} members',
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await GroupService.joinGroupByInviteCode(
                    inviteCode: inviteCode,
                    userId: authService.user!.uid,
                    userName: authService.user!.displayName ?? 'User',
                  );
                  
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Successfully joined ${group.name}'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                    
                    // Navigate to group chat
                    Navigator.push(
                      dialogContext,
                      MaterialPageRoute(
                        builder: (context) => GroupChatScreen(
                          group: group,
                          currentUser: authService.userModel!,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Failed to join group: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Join',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendConnectionRequest(Map<String, dynamic> user) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.user;
      final currentUserModel = authService.userModel;

      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      String currentUserName = 'User';
      String? currentUserProfileImageUrl;

      if (currentUserModel != null) {
        currentUserName = currentUserModel.fullName;
        currentUserProfileImageUrl = currentUserModel.profileImageUrl;
      } else if (currentUser.displayName != null) {
        currentUserName = currentUser.displayName!;
        currentUserProfileImageUrl = currentUser.photoURL;
      }

      final connectionRequestService = ConnectionRequestService();
      await connectionRequestService.sendConnectionRequest(
        senderId: currentUser.uid,
        senderName: currentUserName,
        senderProfileImageUrl: currentUserProfileImageUrl,
        receiverId: user['id'],
        receiverName: user['fullName'] ?? user['username'],
        receiverProfileImageUrl: user['profileImageUrl'],
        message: 'Hi! I scanned your QR code and would like to connect.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection request sent to ${user['fullName'] ?? user['username']}')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () async {
              await controller.toggleTorch();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                if (_isScanning && capture.barcodes.isNotEmpty) {
                  final String? code = capture.barcodes.first.rawValue;
                  if (code != null) {
                    setState(() {
                      _isScanning = false;
                    });
                    _handleQRCode(code);
                  }
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black,
            child: Column(
              children: [
                const Text(
                  'Position the QR code within the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SearchUsersScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Search Instead'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
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