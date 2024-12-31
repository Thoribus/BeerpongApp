import 'package:beerpongapp/screens/account_screen.dart';
import 'package:beerpongapp/util/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:beerpongapp/models/user.dart';
import 'package:beerpongapp/beerpong_icons_icons.dart';

class MockUserProvider extends ChangeNotifier implements UserProvider {
  User? _user;
  bool _signedIn = false;

  @override
  User? get user => _user;

  @override
  Future<void> signIn() async {
    _signedIn = true;
    _user = User(id: '123', username: 'TestUser');
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
    _user = null;
    notifyListeners();
  }

  @override
  Future<void> updateUser(User user) async {
    _user = user;
    notifyListeners();
  }

  @override
  Future<void> loadUser() async {
    // Mock load user behavior
  }

  @override
  Future<User?> signInWithGoogle() {
    // TODO: implement signInWithGoogle
    throw UnimplementedError();
  }
}

void main() {
  Widget createTestWidget({required Widget child}) {
    return ChangeNotifierProvider<UserProvider>(
      create: (_) => MockUserProvider(),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('shows sign in button when user is not signed in', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(child: const AccountScreen()));

    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('shows user data when user is signed in', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(child: const AccountScreen()));
    final userProvider = Provider.of<UserProvider>(tester.element(find.byType(AccountScreen)), listen: false);
    userProvider.signIn();
    await tester.pumpAndSettle();

    expect(find.text('TestUser'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('shows icon picker when avatar is tapped', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(child: const AccountScreen()));
    final userProvider = Provider.of<UserProvider>(tester.element(find.byType(AccountScreen)), listen: false);
    userProvider.signIn();
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();

    expect(find.text('Select Icon and Color'), findsOneWidget);
  });

  testWidgets('updates user icon and color', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget(child: const AccountScreen()));
    final userProvider = Provider.of<UserProvider>(tester.element(find.byType(AccountScreen)), listen: false);
    userProvider.signIn();
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(BeerpongIcons.cat_avatar));
    await tester.pumpAndSettle();

    expect((userProvider.user!.icon == BeerpongIcons.cat_avatar), isTrue);

    await tester.tap(find.text('Select Background Color'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CircleAvatar).last);
    await tester.pumpAndSettle();

    expect((userProvider.user!.iconColor == Colors.cyan), isTrue);
  });
}
