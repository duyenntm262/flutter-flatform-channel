import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';
List<Object?> wrapResponse({Object? result, PlatformException? error, bool empty = false}) {
  if (empty) {
    return <Object?>[];
  }
  if (error == null) {
    return <Object?>[result];
  }
  return <Object?>[error.code, error.message, error.details];
}

class MyMessage {
  MyMessage({
    required this.title,
    required this.body,
    required this.email,
  });

  String title;

  String body;

  String email;

  Object encode() {
    return <Object?>[
      title,
      body,
      email,
    ];
  }

  static MyMessage decode(Object result) {
    result as List<Object?>;
    return MyMessage(
      title: result[0]! as String,
      body: result[1]! as String,
      email: result[2]! as String,
    );
  }
}

class _MessageApiCodec extends StandardMessageCodec {
  const _MessageApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is MyMessage) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:
        return MyMessage.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class MessageApi {
  /// Constructor for [MessageApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  MessageApi({BinaryMessenger? binaryMessenger})
      : _binaryMessenger = binaryMessenger;
  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = _MessageApiCodec();

  Future<List<MyMessage?>> getMessages(String arg_fromEmail) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.flutter_platform_channel.MessageApi.getMessages', codec,
        binaryMessenger: _binaryMessenger);
    final List<Object?>? replyList =
    await channel.send(<Object?>[arg_fromEmail]) as List<Object?>?;
    if (replyList == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
      );
    } else if (replyList.length > 1) {
      throw PlatformException(
        code: replyList[0]! as String,
        message: replyList[1] as String?,
        details: replyList[2],
      );
    } else if (replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (replyList[0] as List<Object?>?)!.cast<MyMessage?>();
    }
  }
}