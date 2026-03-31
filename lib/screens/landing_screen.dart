import 'dart:async';
import 'package:flutter/material.dart';
import 'basic_info.dart';
import 'itineraries_list_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final List<String> _images = [
    'assets/images/landing_bg_2.png',
    'assets/images/landing_bg_6.png',
    'assets/images/landing_bg_3.png',
    'assets/images/landing_bg_9.png',
    'assets/images/landing_bg_4.png',
    'assets/images/landing_bg_8.png',
    'assets/images/landing_bg_1.png',
    'assets/images/landing_bg_10.png',
    'assets/images/landing_bg_5.png',
    'assets/images/landing_bg_7.png',
  ];

  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  final double containerHeight = 355.0;
  final double overlap = 28.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);

    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_pageController.hasClients) {
        if (_currentPage >= _images.length - 1) {
          _pageController.jumpToPage(0);
          setState(() {
            _currentPage = 0;
          });
        } else {
          _currentPage++;
          _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double pageViewHeight = MediaQuery.of(context).size.height - (containerHeight - overlap);

    return Scaffold(
      body: Stack(
        children: [
          // Top container (background images)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: pageViewHeight,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Image.asset(_images[index], fit: BoxFit.cover);
              },
            ),
          ),
          // Bottom container (app description + button)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: containerHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Intellinary', textAlign: TextAlign.center, style: Theme.of(context).textTheme.displayLarge),
                  const SizedBox(height: 24),
                  Text(
                    'Your next trip, intelligently crafted',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Perfectly tailored to your unique travel style, featuring hidden gems and local favorites',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const BasicInfoStepper()));
                    },
                    icon: const Icon(Icons.route, size: 32.0, color: Colors.black),
                    label: const Text('Create a New Itinerary'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
                      textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ItinerariesListScreen()));
                    },
                    style: OutlinedButton.styleFrom(
                      textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('My Trips'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
