compileNewDDC
Error: Couldn't resolve the package 'supabase_flutter' in 'package:supabase_flutter/supabase_flutter.dart'.
main.dart:4:8: Error: Not found: 'package:supabase_flutter/supabase_flutter.dart'
import 'package:supabase_flutter/supabase_flutter.dart';
       ^
main.dart:6:8: Error: Error when reading '/tmp/dartpadJWCQCZ/lib/services/auth_service.dart': No such file or directory
import '../services/auth_service.dart';
       ^
main.dart:222:24: Error: Type 'AuthException' not found.
  String _mapAuthError(AuthException e) {
                       ^^^^^^^^^^^^^
main.dart:30:18: Error: Method not found: 'main'.
      entrypoint.main();
                 ^^^^
main.dart:183:10: Error: 'AuthException' isn't a type.
    } on AuthException catch (e) {
         ^^^^^^^^^^^^^
main.dart:169:15: Error: The getter 'AuthService' isn't defined for the type '_AuthPageState'.
 - '_AuthPageState' is from 'package:dartpad_sample/main.dart' ('/tmp/dartpadJWCQCZ/lib/main.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'AuthService'.
        await AuthService.instance.signIn(
              ^^^^^^^^^^^
main.dart:174:15: Error: The getter 'AuthService' isn't defined for the type '_AuthPageState'.
 - '_AuthPageState' is from 'package:dartpad_sample/main.dart' ('/tmp/dartpadJWCQCZ/lib/main.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'AuthService'.
        await AuthService.instance.signUp(
              ^^^^^^^^^^^
main.dart:199:10: Error: 'AuthException' isn't a type.
    } on AuthException catch (e) {
         ^^^^^^^^^^^^^
main.dart:195:13: Error: The getter 'Supabase' isn't defined for the type '_AuthPageState'.
 - '_AuthPageState' is from 'package:dartpad_sample/main.dart' ('/tmp/dartpadJWCQCZ/lib/main.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'Supabase'.
      await Supabase.instance.client.auth.signInWithOAuth(
            ^^^^^^^^
main.dart:196:9: Error: The getter 'OAuthProvider' isn't defined for the type '_AuthPageState'.
 - '_AuthPageState' is from 'package:dartpad_sample/main.dart' ('/tmp/dartpadJWCQCZ/lib/main.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'OAuthProvider'.
        OAuthProvider.google,
        ^^^^^^^^^^^^^
main.dart:215:13: Error: The getter 'AuthService' isn't defined for the type '_AuthPageState'.
 - '_AuthPageState' is from 'package:dartpad_sample/main.dart' ('/tmp/dartpadJWCQCZ/lib/main.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'AuthService'.
      await AuthService.instance.resetPassword(email);
            ^^^^^^^^^^^
main.dart:222:24: Error: 'AuthException' isn't a type.
  String _mapAuthError(AuthException e) {
                       ^^^^^^^^^^^^^

