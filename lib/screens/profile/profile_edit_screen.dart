import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'dart:ui';
import '../../services/auth_service.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/responsive_utils.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _linkedinController = TextEditingController();
  
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  bool _hasChangedUsername = false;
  bool _isCheckingUsername = false;
  String? _usernameError;
  String _phoneNumberPrivacy = 'connections_only'; // 'connections_only', 'private', 'custom'
  List<String> _allowedPhoneViewers = [];
  List<Map<String, dynamic>> _connections = [];
  bool _isLoadingConnections = false;
  bool _isUpdatingPhonePrivacy = false;

  @override
  void initState() {
    super.initState();
    // Delay loading to ensure AuthService is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          _loadUserData();
          _loadPhonePrivacySettings();
        } catch (e) {
          debugPrint('Error in initState postFrameCallback: $e');
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload user data when dependencies change (e.g., AuthService updates)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          _loadUserData();
        } catch (e) {
          debugPrint('Error in didChangeDependencies: $e');
        }
      }
    });
  }

  void _loadUserData() async {
    if (!mounted) return;
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      debugPrint('Loading user data...');
      debugPrint('AuthService userModel: ${authService.userModel}');
      debugPrint('AuthService user: ${authService.user}');
      
      if (authService.userModel != null) {
      debugPrint('Loading from userModel:');
      debugPrint('Full Name: ${authService.userModel!.fullName}');
      debugPrint('Email: ${authService.userModel!.email}');
      debugPrint('Username: ${authService.userModel!.username}');
      debugPrint('Company: ${authService.userModel!.company}');
      debugPrint('Position: ${authService.userModel!.position}');
      debugPrint('Phone: ${authService.userModel!.phoneNumber}');
      
      setState(() {
        _nameController.text = authService.userModel!.fullName;
        _emailController.text = authService.userModel!.email;
        _usernameController.text = authService.userModel!.username;
        _companyController.text = authService.userModel!.company ?? '';
        _positionController.text = authService.userModel!.position ?? '';
        _phoneController.text = authService.userModel!.phoneNumber ?? '';
        _bioController.text = authService.userModel!.bio ?? '';
        _linkedinController.text = authService.userModel!.socialLinks['linkedin'] ?? '';
        _currentImageUrl = authService.userModel!.profileImageUrl;
      });
      
      debugPrint('Controllers updated with userModel data');
    } else if (authService.user != null) {
      debugPrint('Loading from Firebase user:');
      debugPrint('Display Name: ${authService.user!.displayName}');
      debugPrint('Email: ${authService.user!.email}');
      
      setState(() {
        _nameController.text = authService.user!.displayName ?? '';
        _emailController.text = authService.user!.email ?? '';
        _usernameController.text = ''; // No username in Firebase user
        _companyController.text = '';
        _positionController.text = '';
        _phoneController.text = '';
        _bioController.text = '';
        _linkedinController.text = '';
        _currentImageUrl = authService.user!.photoURL;
      });
      
      debugPrint('Controllers updated with Firebase user data');
      
      // If userModel is null but user exists, try to load user data
      if (authService.userModel == null) {
        debugPrint('UserModel is null, attempting to load user data...');
        await authService.loadUserData();
        if (mounted && authService.userModel != null) {
          setState(() {
            _currentImageUrl = authService.userModel!.profileImageUrl ?? _currentImageUrl;
          });
        }
      }
    } else {
      debugPrint('No user data available');
    }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        // Don't show error to user, just log it
        // The UI will show default/empty values
      }
    }
  }

  Future<void> _loadPhonePrivacySettings() async {
    if (!mounted) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      if (authService.userModel != null) {
        final privacy = authService.userModel!.phoneNumberPrivacy ?? 'connections_only';
        final viewers = authService.userModel!.allowedPhoneViewers;
        final safeViewers = List<String>.from(viewers);
        
        if (!mounted) return;
        setState(() {
          _phoneNumberPrivacy = privacy;
          _allowedPhoneViewers = safeViewers;
          // Set loading state if custom and connections need to be loaded
          if (privacy == 'custom' && _connections.isEmpty) {
            _isLoadingConnections = true;
          }
        });
        
        // If privacy is already set to 'custom', load connections
        if (privacy == 'custom' && _connections.isEmpty) {
          await _loadConnections();
        }
      } else if (authService.user != null) {
        // Load from Firestore if userModel is not available
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(authService.user!.uid)
            .get();
        
        if (!mounted) return;
        
        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null) {
            final privacy = data['phoneNumberPrivacy']?.toString() ?? 'connections_only';
            final viewersData = data['allowedPhoneViewers'];
            final safeViewers = viewersData != null && viewersData is List
                ? List<String>.from(viewersData.map((e) => e.toString()))
                : <String>[];
            
            if (!mounted) return;
            setState(() {
              _phoneNumberPrivacy = privacy;
              _allowedPhoneViewers = safeViewers;
              // Set loading state if custom and connections need to be loaded
              if (privacy == 'custom' && _connections.isEmpty) {
                _isLoadingConnections = true;
              }
            });
            
            // If privacy is already set to 'custom', load connections
            if (privacy == 'custom' && _connections.isEmpty) {
              await _loadConnections();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading phone privacy settings: $e');
      if (mounted) {
        setState(() {
          _isLoadingConnections = false;
        });
      }
    }
  }

  Future<void> _loadConnections() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.user == null) {
      debugPrint('Cannot load connections: user is null');
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingConnections = true;
      });
    }

    try {
      debugPrint('Loading connections for user: ${authService.user!.uid}');
      // Load connections
      final connectionsSnapshot = await FirebaseFirestore.instance
          .collection('connections')
          .where('userId', isEqualTo: authService.user!.uid)
          .get();

      debugPrint('Found ${connectionsSnapshot.docs.length} connections');
      
      // Map connections and deduplicate by contactUserId
      final connectionsMap = <String, Map<String, dynamic>>{};
      for (var doc in connectionsSnapshot.docs) {
        try {
          final data = doc.data();
          
          final contactUserId = data['contactUserId']?.toString() ?? '';
          final contactName = data['contactName']?.toString() ?? 'Unknown';
          
          // Only keep the first occurrence of each contactUserId
          if (contactUserId.isNotEmpty && !connectionsMap.containsKey(contactUserId)) {
            debugPrint('  - Connection: $contactName (ID: $contactUserId)');
            connectionsMap[contactUserId] = {
              'id': contactUserId,
              'name': contactName,
            };
          }
        } catch (e) {
          debugPrint('Error processing connection document: $e');
          continue;
        }
      }
      
      final connections = connectionsMap.values.toList();
      debugPrint('Processed ${connections.length} unique connections (deduplicated from ${connectionsSnapshot.docs.length})');
      if (mounted) {
        setState(() {
          _connections = connections;
          _isLoadingConnections = false;
        });
        debugPrint('✅ Connections state updated: ${_connections.length} connections in state');
      }
    } catch (e) {
      debugPrint('❌ Error loading connections: $e');
      if (mounted) {
        setState(() {
          _isLoadingConnections = false;
        });
      }
    }
  }

  Future<void> _updatePhonePrivacy(String value) async {
    if (!mounted || _isUpdatingPhonePrivacy) return;
    
    setState(() {
      _phoneNumberPrivacy = value;
      _isUpdatingPhonePrivacy = true;
      // Set loading state if custom is selected and connections need to be loaded
      if (value == 'custom' && _connections.isEmpty) {
        _isLoadingConnections = true;
      }
    });

    try {
      // Load connections if custom is selected
      if (value == 'custom' && _connections.isEmpty) {
        await _loadConnections();
      }

      if (!mounted) return;

      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updatePhonePrivacySettings(
        phoneNumberPrivacy: value,
        allowedPhoneViewers: value == 'custom' ? _allowedPhoneViewers : null,
      );
      
      if (!mounted) return;
      
      // Reload phone privacy settings from updated userModel to ensure sync
      await _loadPhonePrivacySettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone privacy settings updated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating phone privacy: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update phone privacy: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        // Revert on error - reload from userModel
        await _loadPhonePrivacySettings();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPhonePrivacy = false;
        });
      }
    }
  }

  Future<void> _toggleConnectionSelection(String userId) async {
    if (!mounted) return;
    
    // Store previous state for potential revert
    final previousViewers = List<String>.from(_allowedPhoneViewers);
    
    setState(() {
      if (_allowedPhoneViewers.contains(userId)) {
        _allowedPhoneViewers.remove(userId);
      } else {
        _allowedPhoneViewers.add(userId);
      }
    });

    // Save immediately when selection changes
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.updatePhonePrivacySettings(
        phoneNumberPrivacy: 'custom',
        allowedPhoneViewers: _allowedPhoneViewers,
      );
      
      if (!mounted) return;
      
      // Reload phone privacy settings from updated userModel to ensure sync
      await _loadPhonePrivacySettings();
    } catch (e) {
      debugPrint('Error toggling connection selection: $e');
      // Revert on error
      if (mounted) {
        setState(() {
          _allowedPhoneViewers = previousViewers;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user selection: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }



  Future<void> _checkUsernameExists(String username) async {
    if (username.isEmpty || username.length < 3 || !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      setState(() {
        _usernameError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    // Check if username is the same as current username
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.userModel?.username == username) {
      setState(() {
        _usernameError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameError = null;
    });

    try {
      final usernameExists = await authService.checkUsernameExists(username);
      
      if (usernameExists) {
        setState(() {
          _usernameError = 'Username already exists';
        });
      } else {
        setState(() {
          _usernameError = null;
        });
      }
    } catch (e) {
      setState(() {
        _usernameError = 'Error checking username. Please try again.';
      });
    } finally {
      setState(() {
        _isCheckingUsername = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _currentImageUrl;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user?.uid ?? authService.userModel?.uid;
      
      if (userId == null) return null;

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$userId.jpg');

      await ref.putFile(_selectedImage!);
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      _showErrorSnackBar('Failed to upload image: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Upload image if selected
      String? imageUrl = await _uploadImage();
      
      if (!mounted) return;
      
      // Update user profile
      final socialLinks = <String, String>{};
      if (_linkedinController.text.trim().isNotEmpty) {
        socialLinks['linkedin'] = _linkedinController.text.trim();
      }
      
      await authService.updateUserProfile(
        fullName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        company: _companyController.text.trim(),
        position: _positionController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        profileImageUrl: imageUrl,
        socialLinks: socialLinks,
      );

      if (!mounted) return;

      // Ensure phone privacy settings are also saved (only if not already updating)
      if (!_isUpdatingPhonePrivacy) {
        try {
          await authService.updatePhonePrivacySettings(
            phoneNumberPrivacy: _phoneNumberPrivacy,
            allowedPhoneViewers: _phoneNumberPrivacy == 'custom' ? _allowedPhoneViewers : null,
          );
        } catch (e) {
          debugPrint('Error saving phone privacy settings: $e');
          // Don't fail the entire save if phone privacy fails
        }
      }

      if (!mounted) return;

      // Refresh user data to ensure profile image is updated
      await authService.loadUserData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      if (mounted && Navigator.of(context).canPop()) {
        // Use post frame callback to ensure navigation happens after current frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to update profile: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: ResponsiveUtils.getAllPadding(context, base: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context, baseSize: 18),
                fontWeight: FontWeight.bold,
                color: AppColors.grey900,
              ),
            ),
            SizedBox(height: ResponsiveUtils.getSpacing(context, small: 20, medium: 24, large: 28)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: ResponsiveUtils.getAllPadding(context, base: 20),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: ResponsiveUtils.getIconSize(context, baseSize: 32), color: AppColors.primary),
            SizedBox(height: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12)),
            Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                fontWeight: FontWeight.w500,
                color: AppColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _phoneController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Safety check for Provider
    try {
      Provider.of<AuthService>(context, listen: false);
    } catch (e) {
      debugPrint('Error accessing AuthService in build: $e');
      return Scaffold(
        backgroundColor: AppColors.grey900,
        appBar: AppBar(
          backgroundColor: AppColors.grey800,
          title: const Text(
            'Edit Profile',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile. Please try again.',
                  style: TextStyle(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
          backgroundColor: AppColors.grey900, // Overall Background - matching homepage
          appBar: AppBar(
            backgroundColor: AppColors.grey800, // Sidebar/AppBar Background - matching homepage
            title: const Text(
              'Edit Profile',
              style: TextStyle(color: AppColors.textPrimary), // Bright White Text
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: _isLoading ? AppColors.grey400 : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          body: Builder(
            builder: (context) {
              try {
                return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: ResponsiveUtils.getHorizontalPadding(context),
              right: ResponsiveUtils.getHorizontalPadding(context),
              top: ResponsiveUtils.getVerticalPadding(context),
              bottom: ResponsiveUtils.getVerticalPadding(context) + MediaQuery.of(context).padding.bottom + ResponsiveUtils.getSpacing(context, small: 110, medium: 120, large: 130),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Picture Section
                  _buildProfilePictureSection(),
                  
                  SizedBox(height: ResponsiveUtils.getSpacing(context, small: 32, medium: 36, large: 40)),
                  
                  // Form Fields
                  CustomTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    prefixIcon: Icons.person,
                    enabled: false, // Name is not editable
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: ResponsiveUtils.getSpacing(context, small: 16, medium: 18, large: 20)),
                  
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'Enter your email',
                    prefixIcon: Icons.email,
                    enabled: false, // Email is not editable
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  
                  SizedBox(height: ResponsiveUtils.getSpacing(context, small: 16, medium: 18, large: 20)),
                  
                  // Username field with validation
                  CustomTextField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'Choose a unique username',
                    prefixIcon: Icons.alternate_email,
                    onChanged: (value) {
                      // Track if username has been changed
                      final authService = Provider.of<AuthService>(context, listen: false);
                      if (authService.userModel?.username != value) {
                        _hasChangedUsername = true;
                      }
                      
                      // Debounce the username check to avoid too many API calls
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_usernameController.text == value) {
                          _checkUsernameExists(value);
                        }
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                        return 'Username can only contain letters, numbers, and underscores';
                      }
                      if (_usernameError != null) {
                        return _usernameError;
                      }
                      return null;
                    },
                  ),
                  
                  // Username error message
                  if (_usernameError != null)
                    Container(
                      margin: EdgeInsets.only(top: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12)),
                      padding: ResponsiveUtils.getSymmetricPadding(context, horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 6)),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: ResponsiveUtils.getIconSize(context, baseSize: 16),
                          ),
                          SizedBox(width: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12)),
                          Expanded(
                            child: Text(
                              _usernameError!,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: ResponsiveUtils.getFontSize(context, baseSize: 12),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Username checking indicator
                  if (_isCheckingUsername)
                    Container(
                      margin: EdgeInsets.only(top: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12)),
                      padding: ResponsiveUtils.getSymmetricPadding(context, horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 6)),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: ResponsiveUtils.getIconSize(context, baseSize: 16),
                            height: ResponsiveUtils.getIconSize(context, baseSize: 16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12)),
                          Expanded(
                            child: Text(
                              'Checking username availability...',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: ResponsiveUtils.getFontSize(context, baseSize: 12),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Username change limit warning
                  if (_hasChangedUsername)
                    Container(
                      margin: EdgeInsets.only(top: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12)),
                      padding: ResponsiveUtils.getSymmetricPadding(context, horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 6)),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_outlined,
                            color: Colors.orange,
                            size: ResponsiveUtils.getIconSize(context, baseSize: 16),
                          ),
                          SizedBox(width: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12)),
                          Expanded(
                            child: Text(
                              'You can only change your username once. Choose carefully!',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: ResponsiveUtils.getFontSize(context, baseSize: 12),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: ResponsiveUtils.getSpacing(context, small: 16, medium: 18, large: 20)),
                  
                  CustomTextField(
                    controller: _companyController,
                    label: 'Company',
                    hint: 'Enter your company name',
                    prefixIcon: Icons.business,
                  ),
                  
                  SizedBox(height: ResponsiveUtils.getSpacing(context, small: 16, medium: 18, large: 20)),
                  
                  CustomTextField(
                    controller: _positionController,
                    label: 'Position',
                    hint: 'Enter your job title',
                    prefixIcon: Icons.work,
                  ),
                  
                  SizedBox(height: ResponsiveUtils.getSpacing(context, small: 16, medium: 18, large: 20)),
                  
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'Enter your phone number',
                    prefixIcon: Icons.phone,
                  ),
                  
                  SizedBox(height: ResponsiveUtils.getSpacing(context, small: 24, medium: 28, large: 32)),
                  
                  // Phone Number Privacy Section
                  Builder(
                    builder: (context) {
                      try {
                        return _PhonePrivacySection(
                          phoneNumberPrivacy: _phoneNumberPrivacy,
                          allowedPhoneViewers: List<String>.from(_allowedPhoneViewers),
                          connections: List<Map<String, dynamic>>.from(_connections),
                          isLoadingConnections: _isLoadingConnections,
                          onPrivacyChanged: (value) {
                            if (mounted) {
                              _updatePhonePrivacy(value);
                            }
                          },
                          onToggleConnection: (userId) {
                            if (mounted) {
                              _toggleConnectionSelection(userId);
                            }
                          },
                        );
                      } catch (e) {
                        debugPrint('Error building phone privacy section: $e');
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Error loading privacy settings. Please try again.',
                            style: TextStyle(color: AppColors.error),
                          ),
                        );
                      }
                    },
                  ),
                  
                  SizedBox(height: ResponsiveUtils.getSpacing(context, small: 16, medium: 18, large: 20)),
                  
                  CustomTextField(
                    controller: _bioController,
                    label: 'Bio',
                    hint: 'Tell us about yourself',
                    prefixIcon: Icons.info,
                    maxLines: 3,
                  ),
                  
                  SizedBox(height: ResponsiveUtils.getSpacing(context, small: 16, medium: 18, large: 20)),
                  
                  CustomTextField(
                    controller: _linkedinController,
                    label: 'LinkedIn Profile',
                    hint: 'https://linkedin.com/in/yourprofile',
                    prefixIcon: Icons.work,
                    keyboardType: TextInputType.url,
                  ),
                  
                  SizedBox(height: ResponsiveUtils.getSpacing(context, small: 32, medium: 36, large: 40)),
                  
                  // Save Button
                  CustomButton(
                    text: 'Save Changes',
                    onPressed: _isLoading ? null : _saveProfile,
                    isLoading: _isLoading,
                  ),
                  
                  // Extra bottom spacing to prevent overflow
                  SizedBox(height: MediaQuery.of(context).padding.bottom + ResponsiveUtils.getSpacing(context, small: 30, medium: 36, large: 40)),
                ],
              ),
            ),
          );
              } catch (e) {
                debugPrint('Error building profile edit body: $e');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading profile form. Please try again.',
                          style: TextStyle(color: AppColors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (mounted) {
                              setState(() {});
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        );
  }

  Widget _buildProfilePictureSection() {
    final avatarSize = ResponsiveUtils.getAvatarSize(context, small: 100, medium: 120, large: 140);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Profile Picture
        GestureDetector(
          onTap: _showImageSourceDialog,
          child: Stack(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        )
                      : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: _currentImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => _buildDefaultAvatar(),
                              errorWidget: (context, url, error) {
                                debugPrint('Error loading profile image: $error');
                                debugPrint('Image URL: $_currentImageUrl');
                                return _buildDefaultAvatar();
                              },
                            )
                          : _buildDefaultAvatar(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: ResponsiveUtils.getIconSize(context, baseSize: 36),
                  height: ResponsiveUtils.getIconSize(context, baseSize: 36),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: AppColors.white,
                    size: ResponsiveUtils.getIconSize(context, baseSize: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: ResponsiveUtils.getSpacing(context, small: 12, medium: 14, large: 16)),
        
        Text(
          'Tap to change photo',
          style: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userName = authService.userModel?.fullName ?? 
                    authService.user?.displayName ?? 
                    'User';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
    
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

class _PhonePrivacySection extends StatelessWidget {
  final String phoneNumberPrivacy;
  final List<String> allowedPhoneViewers;
  final List<Map<String, dynamic>> connections;
  final bool isLoadingConnections;
  final ValueChanged<String> onPrivacyChanged;
  final ValueChanged<String> onToggleConnection;

  const _PhonePrivacySection({
    required this.phoneNumberPrivacy,
    required this.allowedPhoneViewers,
    required this.connections,
    required this.isLoadingConnections,
    required this.onPrivacyChanged,
    required this.onToggleConnection,
  });

  @override
  Widget build(BuildContext context) {
    // Debug log to see what the widget receives
    debugPrint('🔍 _PhonePrivacySection build: privacy=$phoneNumberPrivacy, connections=${connections.length}, isLoading=$isLoadingConnections');
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: ResponsiveUtils.getHorizontalPadding(context),
            bottom: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12),
          ),
          child: Text(
            'Phone Number Privacy',
            style: TextStyle(
              fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
              fontWeight: FontWeight.w600,
              color: AppColors.grey500,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 12)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1F295B).withOpacity(0.6),
                    const Color(0xFF283B89).withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(ResponsiveUtils.getBorderRadius(context, base: 12)),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RadioPrivacyTile(
                    icon: Icons.people,
                    title: 'Connections Only',
                    subtitle: 'All people in your connections list can see your phone number',
                    value: 'connections_only',
                    groupValue: phoneNumberPrivacy,
                    onChanged: onPrivacyChanged,
                  ),
                  _RadioPrivacyTile(
                    icon: Icons.lock,
                    title: 'Private',
                    subtitle: 'Number hidden from everyone (only you see it)',
                    value: 'private',
                    groupValue: phoneNumberPrivacy,
                    onChanged: onPrivacyChanged,
                  ),
                  _RadioPrivacyTile(
                    icon: Icons.person,
                    title: 'Custom',
                    subtitle: 'Only selected users can see your contact number',
                    value: 'custom',
                    groupValue: phoneNumberPrivacy,
                    onChanged: onPrivacyChanged,
                  ),
                  if (phoneNumberPrivacy == 'custom') ...[
                    Divider(
                      height: 1,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    Padding(
                      padding: ResponsiveUtils.getAllPadding(context, base: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Connections',
                            style: TextStyle(
                              fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: ResponsiveUtils.getSpacing(context, small: 8, medium: 10, large: 12)),
                          if (isLoadingConnections)
                            Padding(
                              padding: ResponsiveUtils.getSymmetricPadding(context, horizontal: 0, vertical: 16),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          else if (connections.isEmpty)
                            Padding(
                              padding: ResponsiveUtils.getSymmetricPadding(context, horizontal: 0, vertical: 16),
                              child: Text(
                                'No connections available',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, baseSize: 12),
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          else ...[
                            Text(
                              '${allowedPhoneViewers.length} of ${connections.length} connection(s) selected',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(context, baseSize: 12),
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: ResponsiveUtils.getSpacing(context, small: 12, medium: 14, large: 16)),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 200),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: connections.where((connection) {
                                    // Filter out any connections with null/empty IDs
                                    final userId = connection['id'];
                                    return userId != null && userId is String && userId.isNotEmpty;
                                  }).map((connection) {
                                    final userId = connection['id'] as String;
                                    final userName = connection['name'] as String? ?? 'Unknown';
                                    final isSelected = allowedPhoneViewers.contains(userId);

                                    return CheckboxListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        userName,
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.getFontSize(context, baseSize: 14),
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      value: isSelected,
                                      onChanged: (value) {
                                        onToggleConnection(userId);
                                      },
                                      controlAffinity: ListTileControlAffinity.leading,
                                      activeColor: AppColors.primary,
                                      checkColor: Colors.white,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RadioPrivacyTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String> onChanged;

  const _RadioPrivacyTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return ListTile(
      dense: true,
      isThreeLine: false,
      contentPadding: ResponsiveUtils.getSymmetricPadding(context, horizontal: 16, vertical: 8),
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        size: ResponsiveUtils.getIconSize(context, baseSize: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: ResponsiveUtils.getFontSize(context, baseSize: 15),
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: ResponsiveUtils.getFontSize(context, baseSize: 12),
        ),
      ),
      trailing: Radio<String>(
        value: value,
        groupValue: groupValue,
        onChanged: (String? newValue) {
          if (newValue != null && newValue != groupValue) {
            onChanged(newValue);
          }
        },
        activeColor: AppColors.primary,
        fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textSecondary;
        }),
      ),
      onTap: () {
        if (value != groupValue) {
          onChanged(value);
        }
      },
    );
  }
}

