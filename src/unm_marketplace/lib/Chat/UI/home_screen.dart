import 'package:unm_marketplace/Chat/UI/screens.dart';
import 'package:unm_marketplace/Chat/pages/contacts_page.dart';
import 'package:unm_marketplace/Chat/pages/notification_page.dart';
import 'package:unm_marketplace/Chat/pages/messages_page.dart';
import 'package:unm_marketplace/Chat/theme.dart';
import 'package:unm_marketplace/Chat/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:unm_marketplace/Chat/app.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({Key? key}) : super(key: key);

  final ValueNotifier<int> pageIndex = ValueNotifier(0);
  final ValueNotifier<String> title = ValueNotifier('Messages');

  final pages = const [
    MessagesPage(),
    NotificationsPage(),
    ContactsPage(),
  ];

  final pageTitles = const [
    'Messages',
    'Notifications',
    'Contacts'
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ValueListenableBuilder(
          valueListenable: title,
          builder: (BuildContext context, String value, _){
            return Text(
              title.value,
              style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),  
      centerTitle: true, // Set this property to true to center the title
      leadingWidth: 54,
      leading: Align(
        alignment: Alignment.centerRight,
        child: IconBackground(
          icon: Icons.search,
          onTap: () {
          print('TODO search');
          },
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 24.0),
          child: Hero(
            tag: 'hero-profile-picture',
            child: Avatar.small(
              url: context.currentUserImage,
              onTap: () {
              Navigator.of(context).push(ProfileScreen.route);
            }
            ),
          ),
        ),
      ],
    ),
      body: ValueListenableBuilder(
        valueListenable: pageIndex,
        builder: (BuildContext context, int value, _) {
          return pages[value];
        },
      ),
      bottomNavigationBar: _BottomNavigationBar(
        onItemSelected: _onNavigationItemSelected,
      ),
    );
  }

  void _onNavigationItemSelected(index) {
        title.value = pageTitles[index];
        pageIndex.value = index;
      }
}

class _BottomNavigationBar extends StatefulWidget {
  const _BottomNavigationBar({
    Key? key,
    required this.onItemSelected,
  }) : super(key: key);

  final ValueChanged<int> onItemSelected;

  @override
  _BottomNavigationBarState createState() => _BottomNavigationBarState();
}

class _BottomNavigationBarState extends State<_BottomNavigationBar> {

  var selectedIndex = 0;

  void handleSelectedItem(int index) {
      setState(() {
        selectedIndex = index;
      });
      widget.onItemSelected(index);
    }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Card(
      color: (brightness == Brightness.light) ? Colors.transparent : null,
      elevation: 0,
      margin: const EdgeInsets.all(0),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavigationBarItem(
                index: 0,
                label: 'Messages', 
                icon: Icons.message,
                isSelected: (selectedIndex == 0),
                onTap: handleSelectedItem,
                ),
              _NavigationBarItem(
                index: 1,
                label: 'Notifications', 
                icon: Icons.notifications,
                isSelected: (selectedIndex == 1),
                onTap: handleSelectedItem,
              ),
              _NavigationBarItem(
                index: 2,
                label: 'Contacts', 
                icon: Icons.contact_mail,
                isSelected: (selectedIndex == 2),
                onTap: handleSelectedItem,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationBarItem extends StatelessWidget {
  const _NavigationBarItem({
    Key? key, 
    required this.index,
    required this.label,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
  }) : super(key: key);

  final ValueChanged<int> onTap;
  final bool isSelected;
  final int index;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        onTap(index);
      },
      child: SizedBox(
        height: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.secondary : null, 
             ),
            SizedBox(height: 8,),
            Text(
              label, 
              style: isSelected 
              ? const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
                )
              : const TextStyle(fontSize: 11),
            )
          ],
        )
      ),
    );
  }
}