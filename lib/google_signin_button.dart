import 'package:flutter/material.dart';
import 'auth_service.dart';

class GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final void Function()? onPressed;
  const GoogleSignInButton({Key? key, this.isLoading = false, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Image.asset('assets/google.png', height: 24),
        label: Text('Sign in with Google'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.grey.shade300),
          textStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }
}
