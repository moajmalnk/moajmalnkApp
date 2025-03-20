import 'dart:async';
import 'dart:io' show Platform, File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';

/// Main entry point of the application
void main() {
  runApp(const MyApp());
}

/// Root widget of the application
/// Configures the app theme and orientation settings
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFF23143B),
      statusBarColor:
          Color(0xFF23143B), // Match the status bar color to the background
    ));
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: const AppBarTheme(color: Color(0xFF23143B)),
        scaffoldBackgroundColor: const Color(0xFF23143B),
      ),
      home: const OpenUrlPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Main page widget that handles URL opening and web view functionality
class OpenUrlPage extends StatefulWidget {
  const OpenUrlPage({super.key});

  @override
  State<OpenUrlPage> createState() => _OpenUrlPageState();
}

/// State management for OpenUrlPage
/// Handles web view controller, navigation, and user interactions
class _OpenUrlPageState extends State<OpenUrlPage> {
  late final WebViewController _controller;
  DateTime? _lastBackPressed;
  static const String _homeUrl = 'https://moajmalnk.in/';
  int _selectedIndex = 0;

  /// Initializes the WebView controller and sets up navigation handlers
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      const params = PlatformWebViewControllerCreationParams();
      _controller = WebViewController.fromPlatformCreationParams(params)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..enableZoom(false)
        ..setUserAgent(
            'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36')
        ..setNavigationDelegate(
          NavigationDelegate(
            onWebResourceError: (WebResourceError error) {
              print('WebView error: ${error.description}');
              _controller.reload();
            },
            onPageStarted: _handlePageStart,
            onNavigationRequest: (NavigationRequest request) async {
              // Check if the URL is a CV download link
              if (request.url.contains('.pdf') ||
                  request.url.contains('/cv') ||
                  request.url.contains('download')) {
                try {
                  await launchUrl(
                    Uri.parse(request.url),
                    mode: LaunchMode.externalApplication,
                  );
                  return NavigationDecision.prevent;
                } catch (e) {
                  print('Error launching URL: $e');
                }
              }
              return _handleNavigationRequest(request);
            },
            onUrlChange: (UrlChange change) {
              // Handle URL changes
            },
            onPageFinished: (String url) async {
              // Enable DOM storage and form data persistence
              await _controller.runJavaScript('''
                localStorage.setItem('formData', '');
                document.forms[0]?.addEventListener('submit', function(e) {
                  localStorage.setItem('formData', JSON.stringify(Object.fromEntries(new FormData(this))));
                });
              ''');
              setState(() {});
            },
          ),
        )
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..loadRequest(Uri.parse(_homeUrl));
    } else {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..enableZoom(false)
        ..setUserAgent('Mozilla/5.0')
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: _handlePageStart,
            onNavigationRequest: _handleNavigationRequest,
            onProgress: (int progress) {
              // Handle page load progress
            },
            onPageFinished: (String url) {
              setState(() {});
            },
          ),
        )
        ..loadRequest(Uri.parse(_homeUrl));
    }
  }

  /// Handles the start of page loading
  void _handlePageStart(String url) {
    setState(() {});
  }

  /// Handles navigation requests and intercepts specific URL schemes
  /// Returns NavigationDecision.prevent for custom URL schemes
  Future<NavigationDecision> _handleNavigationRequest(
      NavigationRequest request) async {
    final String url = request.url;
    if (url.startsWith("whatsapp://")) {
      await _launchUrl('https://wa.me/918848676627?text=Hi%20Ajmal');
      return NavigationDecision.prevent;
    } else if (url.startsWith("tel:")) {
      await _launchUrl('tel:918848676627');
      return NavigationDecision.prevent;
    } else if (url.startsWith("mailto:")) {
      await _launchUrl(
          'mailto:moajmalnk@gmail.com?subject=Hi%20Ajmal&body=I Want To Talk To You?');
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  /// Launches URLs using the system's default handlers
  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  /// Handles back button press with double-tap to exit functionality
  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    if (_lastBackPressed == null ||
        DateTime.now().difference(_lastBackPressed!) >
            const Duration(seconds: 2)) {
      _lastBackPressed = DateTime.now();
      _showExitSnackbar();
      return false;
    }
    return _showExitConfirmationDialog();
  }

  /// Shows a snackbar indicating the user should tap again to exit
  void _showExitSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF9C27B0),
        content: Text('Tap again to exit app', textAlign: TextAlign.center),
        behavior: SnackBarBehavior.floating,
        width: 200,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    );
  }

  /// Shows an exit confirmation dialog
  /// Returns true if user confirms exit, false otherwise
  Future<bool> _showExitConfirmationDialog() async {
    return await showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF23143B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Exit App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Do you want to exit?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey, Colors.grey.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => SystemNavigator.pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF9C27B0),
                              const Color(0xFF7B1FA2)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Text(
                          'Exit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          margin: const EdgeInsets.only(top: 10),
          height: 64,
          width: 64,
          child: FittedBox(
            child: FloatingActionButton(
              onPressed: _showContactOptions,
              elevation: 8,
              highlightElevation: 12,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9C27B0).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.wechat_sharp,
                    color: Colors.white, size: 28, weight: 100),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF23143B),
            gradient: const LinearGradient(
              colors: [Color(0xFF23143B), Color(0xFF1A0F2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, -3),
                spreadRadius: 1,
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.web, 'Home', 1, () async {
                    // First navigate to the page
                    await _controller
                        .loadRequest(Uri.parse('https://moajmalnk.in/'));

                    // Then inject JavaScript to handle popup behavior
                    await _controller.runJavaScript('''
      setTimeout(() => {
        // Show popup
        const popup = document.querySelector('.popup-overlay');
        popup?.classList.add('show');
        
        // Remove any existing auto-close functionality
        if (window.popupCloseTimer) clearTimeout(window.popupCloseTimer);
        
        // Override close function to only work with close button
        const closeBtn = document.querySelector('.close-popup');
        if (closeBtn) {
          closeBtn.onclick = function() {
            popup?.classList.remove('show');
          };
        }
        
        // Scroll to contact section
        document.querySelector('#contact-section')?.scrollIntoView({ 
          behavior: 'smooth',
          block: 'start'
        });
      }, 1000);
    ''');

                    setState(() {
                      _selectedIndex = 1;
                    });
                  }),
                  const SizedBox(width: 100), // Space for FAB
                  _buildNavItem(Icons.web, 'Blogs', 1, () {
                    // Load blog URL in the same WebView
                    _controller
                        .loadRequest(Uri.parse('https://moajmalnk.in/blog'));
                    setState(() {
                      _selectedIndex = 1;
                    });
                  }),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }

  /// Builds a navigation item for the bottom bar
  Widget _buildNavItem(
      IconData icon, String label, int index, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      splashColor: const Color(0xFF9C27B0).withOpacity(0.1),
      highlightColor: const Color(0xFF9C27B0).withOpacity(0.2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: index == _selectedIndex
                ? [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)]
                : [Colors.transparent, Colors.transparent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: index == _selectedIndex
              ? [
                  BoxShadow(
                    color: const Color(0xFF9C27B0).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: index == _selectedIndex
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: index == _selectedIndex
                    ? Colors.white
                    : Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: index == _selectedIndex
                    ? FontWeight.w600
                    : FontWeight.normal,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the contact options bottom sheet
  void _showContactOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      builder: (context) => Container(
        height: 600,
        decoration: const BoxDecoration(
          color: Color(0xFF23143B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF23143B), Color(0xFF1A0F2E)],
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Contact Me',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Contact Information Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Column(
                children: [
                  _buildContactInfo(Icons.phone, '+91 8848676627'),
                  const SizedBox(height: 10),
                  _buildContactInfo(Icons.email, 'info@moajmalnk.in'),
                  const SizedBox(height: 10),
                  _buildContactInfo(Icons.web, 'www.moajmalnk.in'),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            // Existing Grid View
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(20),
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _buildContactButton(
                    'Call',
                    Icons.call,
                    const Color(0xFF9C27B0),
                    () => _showConfirmationDialog(
                      'Call',
                      'Would you like to call Ajmal?',
                      () => launchUrl(Uri.parse('tel:+918848676627')),
                    ),
                  ),
                  _buildContactButton(
                    'WhatsApp',
                    Icons.wechat_sharp,
                    const Color(0xFF7B1FA2),
                    () => _showConfirmationDialog(
                      'WhatsApp',
                      'Would you like to message on WhatsApp?',
                      () => launchUrl(Uri.parse(
                          'https://wa.me/918848676627?text=Hi%20Ajmal%20I%20Want%20To%20Talk%20To%20You?')),
                    ),
                  ),
                  _buildContactButton(
                    'SMS',
                    Icons.message,
                    const Color(0xFF6A1B9A),
                    () => _showConfirmationDialog(
                      'SMS',
                      'Would you like to send an SMS?',
                      () => launchUrl(Uri.parse(
                          'sms:918848676627?body=Hi%20Ajmal%20I%20Want%20To%20Talk%20To%20You')),
                    ),
                  ),
                  _buildContactButton(
                    'Email',
                    Icons.mail,
                    const Color(0xFF4A148C),
                    () => _showConfirmationDialog(
                      'Email',
                      'Would you like to send an email?',
                      () => launchUrl(Uri.parse(
                          'mailto:moajmalnk@gmail.com?subject=Hi%20Ajmal&body=I%20Want%20To%20Talk%20To%20You')),
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

  /// Builds a contact action button with gradient background
  Widget _buildContactButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before performing contact actions
  Future<void> _showConfirmationDialog(
      String title, String message, VoidCallback onConfirm) async {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF23143B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildDialogButton(
                      'Cancel',
                      Colors.grey,
                      () => Navigator.pop(context),
                    ),
                    _buildDialogButton(
                      'Confirm',
                      const Color(0xFF9C27B0),
                      () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds a styled button for dialogs
  Widget _buildDialogButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Builds a contact information row with copy functionality
  Widget _buildContactInfo(IconData icon, String text) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        _showCopiedMessage(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(
              Icons.copy,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a temporary overlay message when text is copied
  void _showCopiedMessage(String text) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 90,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '$text copied to clipboard',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  /// Downloads and opens the CV PDF file
  void _downloadCV() async {
    final url = 'https://moajmalnk.in/assets/pdf/moajmalnk-cv.pdf';

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/moajmalnk-cv.pdf';

      final response = await http.get(Uri.parse(url));
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      Navigator.pop(context);
      await OpenFile.open(filePath);
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to download CV. Please try again.')),
      );
    }
  }
}
