import 'package:flutter/material.dart';

import '../core/api/models.dart';
import '../core/config.dart';
import '../theme/tokens.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar(this.user, {super.key, this.size = 40});
  final PublicUser user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppTokens.accent),
      child: Center(
        child: Text(user.initials,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.38, fontFamily: AppTokens.display)),
      ),
    );
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: user.avatarUrl == null
            ? fallback
            : Image.network(resolveUrl(user.avatarUrl!), fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback),
      ),
    );
  }
}
