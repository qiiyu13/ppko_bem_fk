import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';

// Simple mock of the Mediku app without database dependencies
void main() {
  runApp(
    DevicePreview(enabled: true, builder: (context) => const MockMedikuApp()),
  );
}

class MockMedikuApp extends StatelessWidget {
  const MockMedikuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MEDIKU Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        fontFamily: 'Plus Jakarta Sans',
      ),
      home: const MockPatientDashboard(),
      builder: DevicePreview.appBuilder,
    );
  }
}

// Mock Patient Dashboard - simulates the main screen
class MockPatientDashboard extends StatefulWidget {
  const MockPatientDashboard({super.key});

  @override
  State<MockPatientDashboard> createState() => _MockPatientDashboardState();
}

class _MockPatientDashboardState extends State<MockPatientDashboard> {
  int _currentIndex = 0;

  final List<String> _tabTitles = [
    '',
    'Jadwal',
    'Tanaman Toga',
    'Asisten',
    'Profil',
  ];

  @override
  Widget build(BuildContext context) {
    final showAppBar = _currentIndex != 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: showAppBar
          ? AppBar(
              backgroundColor: const Color(0xFFF5F5F5),
              elevation: 0,
              centerTitle: true,
              title: Text(
                _tabTitles[_currentIndex],
                style: const TextStyle(
                  color: Colors.teal,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const MockHomeTab(),
          const MockScheduleTab(),
          const MockTanamanTab(),
          const MockAsistenTab(),
          const MockProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Beranda', 0),
                _buildNavItem(Icons.calendar_today, 'Jadwal', 1),
                _buildNavItem(Icons.local_florist, 'Toga', 2),
                _buildNavItem(Icons.chat_bubble, 'Asisten', 3),
                _buildNavItem(Icons.person, 'Profil', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.teal : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.teal : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Mock Home Tab
class MockHomeTab extends StatelessWidget {
  const MockHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Pagi,',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Budi Santoso',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.teal),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Health Metrics Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Kesehatan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricItem('Tekanan Darah', '120/80', 'mmHg'),
                      _buildMetricItem('Kolesterol', '195', 'mg/dL'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Next Appointment
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jadwal Berikutnya',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Medical Screening',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '22 Maret 2026 • Balai Desa Sukamaju',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

// Mock Schedule Tab
class MockScheduleTab extends StatelessWidget {
  const MockScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildScheduleCard(
          'Medical Screening',
          '22 Maret 2026',
          '08:00 - 12:00',
          'Balai Desa Sukamaju',
          Colors.teal,
        ),
        const SizedBox(height: 12),
        _buildScheduleCard(
          'Konsultasi Dokter',
          '29 Maret 2026',
          '14:00 - 16:00',
          'Puskesmas Sehat',
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildScheduleCard(
          'Cek Lab',
          '5 April 2026',
          '09:00 - 11:00',
          'Laboratorium Medika',
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildScheduleCard(
    String title,
    String date,
    String time,
    String location,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(color: color, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '$time • $location',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Mock Tanaman Toga Tab
class MockTanamanTab extends StatelessWidget {
  const MockTanamanTab({super.key});

  @override
  Widget build(BuildContext context) {
    final plants = [
      {'name': 'Jahe', 'benefit': 'Mengurangi mual', 'image': '🌿'},
      {'name': 'Kunyit', 'benefit': 'Anti-inflamasi', 'image': '🌱'},
      {
        'name': 'Temulawak',
        'benefit': 'Meningkatkan nafsu makan',
        'image': '🍃',
      },
      {'name': 'Sambiloto', 'benefit': 'Meningkatkan imunitas', 'image': '🌾'},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: plants.length,
      itemBuilder: (context, index) {
        final plant = plants[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plant['image']!, style: const TextStyle(fontSize: 48)),
              const Spacer(),
              Text(
                plant['name']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plant['benefit']!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Mock Asisten Tab
class MockAsistenTab extends StatelessWidget {
  const MockAsistenTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.teal.shade300,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tanya Asisten',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tanyakan kesehatanmu kepada asisten AI',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.chat),
            label: const Text('Mulai Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Mock Profile Tab
class MockProfileTab extends StatelessWidget {
  const MockProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 40, color: Colors.teal),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Budi Santoso',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'NIK: 12131415',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildInfoChip('Pria', Icons.male),
                    const SizedBox(width: 8),
                    _buildInfoChip('O+', Icons.bloodtype),
                    const SizedBox(width: 8),
                    _buildInfoChip('45 th', Icons.cake),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Family Members Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Anggota Keluarga',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildFamilyMember('Siti Aminah', 'Istri', '42 th'),
                const Divider(),
                _buildFamilyMember('Rudi Hartono', 'Anak', '18 th'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.teal),
      label: Text(label),
      backgroundColor: Colors.teal.shade50,
      side: BorderSide.none,
    );
  }

  Widget _buildFamilyMember(String name, String relation, String age) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.teal.shade100,
        child: Text(name[0], style: const TextStyle(color: Colors.teal)),
      ),
      title: Text(name),
      subtitle: Text('$relation • $age'),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
