import 'package:flutter/material.dart';
import 'package:logger/logger.dart' as log;
import 'package:stream_chat_flutter_core/stream_chat_flutter_core.dart';

const streamKey = 'adqmr32mfsg4'; 

var logger = log.Logger();

/// Extensions can be used to add functionality to the SDK.
extension StreamChatContext on BuildContext {
  /// Fetches the current user image.
  String? get currentUserImage {
    final currentUser = StreamChatCore.of(this).currentUser;
    final image = currentUser?.image;

    if(currentUser == null) {
      logger.e('Current user is null.');
    }
    
    if (image == null) {
      logger.e('Current user image is null.');
    }
    
    return image;
  }

  /// Fetches the current user.
  User? get currentUser {
    final currentUser = StreamChatCore.of(this).currentUser;
    
    if (currentUser == null) {
      logger.e('Current user is null.');
    }
    
    return currentUser;
  }
}
