import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class Nointernet extends StatefulWidget {
  const Nointernet({super.key});

  @override
  State<Nointernet> createState() => _NointernetState();
}

class _NointernetState extends State<Nointernet> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasNetwork = connectivityResult.any((r) =>
          r == ConnectivityResult.mobile || r == ConnectivityResult.wifi);

      if (hasNetwork) {
        try {
          final result = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 5));
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            if (mounted) Navigator.pop(context);
            return;
          }
        } catch (_) {
          // DNS lookup failed — still no real internet
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Still no internet. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  text: 'Whoops! ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'lexend',
                  ),
                  children: [
                    TextSpan(
                      text: 'The internet took a break',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontFamily: 'lexend',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Image.asset('assets/no_internet.png'),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isRetrying ? null : _retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white54,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isRetrying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xff001B36),
                          ),
                        )
                      : const Text(
                          'Retry',
                          style: TextStyle(color: Color(0xff001B36)),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}