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
      height: 120, // Keep the large height
      child: ElevatedButton.icon(
        icon: Image.asset('assets/google.png', height: 64),
        label: Text(
          'Sign in with Google',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          side: BorderSide(color: Colors.grey.shade300),
          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
          padding: EdgeInsets.zero, // Remove all padding
        ),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }
}
