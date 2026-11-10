import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String supabaseUrl = 'https://hihsyulcigbgjihmqafc.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpaHN5dWxjaWdiZ2ppaG1xYWZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQyMzgxMjIsImV4cCI6MjEwOTgxNDEyMn0.gJnW41Ey6UF0LvNjCyR9sYyklNgtinWuncFJprPKIMY';
const String adsterraSmartlink = 'https://asiafilm.org/4/d271823115ccad5281c9e633a6f6496e';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const NassemApp());
}

class NassemApp extends StatelessWidget {
  const NassemApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نسيم',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const SplashRouter(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});
  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    await Future.delayed(const Duration(seconds: 1));
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session == null) {
      _navigateTo(const AuthScreen());
    } else {
      final prefs = await SharedPreferences.getInstance();
      bool hasWatchedAds = prefs.getBool('has_watched_ads_${session.user.id}') ?? false;
      if (hasWatchedAds) {
        _navigateTo(const MainScreen());
      } else {
        _navigateTo(const AdOnboardingScreen());
      }
    }
  }

  void _navigateTo(Widget page) {
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  Future<void> _submit() async {
    final username = _userController.text.trim();
    final password = _passController.text.trim();
    
    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال اسم المستخدم وكلمة المرور')));
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'), backgroundColor: Colors.red));
      return;
    }

    final email = '$username@nassem.com';
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
      } else {
        await Supabase.instance.client.auth.signUp(email: email, password: password);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;
      bool hasWatchedAds = prefs.getBool('has_watched_ads_${user?.id}') ?? false;
      
      if (mounted) {
        if (hasWatchedAds) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AdOnboardingScreen()));
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        String msg = e.message;
        if (msg.contains('already registered')) msg = 'اسم المستخدم مسجل بالفعل';
        else if (msg.contains('Invalid login credentials')) msg = 'اسم المستخدم أو كلمة المرور غير صحيحة';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $msg'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.volunteer_activism, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              Text(_isLogin ? 'مرحباً بك في نسيم' : 'إنشاء حساب جديد', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(controller: _userController, decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 15),
              TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور (6 أحرف على الأقل)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isLogin ? 'تسجيل الدخول' : 'إنشاء حساب'),
              ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? 'ليس لديك حساب؟ سجل الآن' : 'لديك حساب بالفعل؟ سجل دخولك'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdOnboardingScreen extends StatefulWidget {
  const AdOnboardingScreen({super.key});
  @override
  State<AdOnboardingScreen> createState() => _AdOnboardingScreenState();
}

class _AdOnboardingScreenState extends State<AdOnboardingScreen> {
  int _adsWatched = 0;

  Future<void> _watchAd() async {
    if (_adsWatched >= 5) return; 
    final Uri url = Uri.parse(adsterraSmartlink);
    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      setState(() => _adsWatched++);
    }
  }

  Future<void> _finishOnboarding() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_watched_ads_${user.id}', true);
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.monetization_on, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text('خطوة أخيرة لتفعيل حسابك!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('لدعم استمرارية التطبيق المجاني، يرجى مشاهدة 5 إعلانات قصيرة لمرة واحدة فقط.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 30),
              Text('$_adsWatched / 5', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 20),
              if (_adsWatched < 5)
                ElevatedButton.icon(
                  onPressed: _watchAd,
                  icon: const Icon(Icons.play_circle_fill),
                  label: const Text('شاهد إعلان الآن'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                )
              else
                ElevatedButton.icon(
                  onPressed: _finishOnboarding,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('تم! الدخول إلى التطبيق'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final amountController = TextEditingController();
  final descController = TextEditingController();
  final phoneController = TextEditingController();
  final shamController = TextEditingController();
  File? receiptImage;
  File? shamImage;
  bool isUploading = false;
  int uploadAdsWatched = 0;

  @override
  void dispose() {
    amountController.dispose();
    descController.dispose();
    phoneController.dispose();
    shamController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نسيم'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'كل الفواتير (للمتبرعين)', icon: Icon(Icons.list)),
              Tab(text: 'فواتيري ورسائلي', icon: Icon(Icons.person)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
              },
            )
          ],
        ),
        body: TabBarView(
          children: [
            _buildBillsList(showAll: true),
            _buildBillsList(showAll: false),
          ],
        ),
      ),
    );
  }

  Widget _buildBillsList({required bool showAll}) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final stream = Supabase.instance.client.from('bills').stream(primaryKey: ['id']).order('created_at', ascending: false);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        List<Map<String, dynamic>> allBills = snapshot.data!;
        List<Map<String, dynamic>> bills = showAll 
            ? allBills 
            : allBills.where((bill) => bill['user_id'] == userId).toList();
        
        if (bills.isEmpty && showAll) return const Center(child: Text('لا توجد فواتير حالياً.'));
        if (bills.isEmpty && !showAll) return _buildUploadCard();

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: bills.length + (!showAll ? 1 : 0),
          itemBuilder: (context, index) {
            if (!showAll && index == 0) {
              return _buildUploadCard();
            }
            
            final billIndex = showAll ? index : index - 1;
            final bill = bills[billIndex];
            final isMyBill = bill['user_id'] == userId;

            return Card(
              child: ListTile(
                leading: Image.network(bill['receipt_image_url'] ?? '', width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image)),
                title: Text('المبلغ: ${bill['amount']} ل.س', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('الحالة: ${bill['description'] ?? "غير محدد"}\nالهاتف: ${bill['phone_number'] ?? "غير متوفر"}'),
                isThreeLine: true,
                trailing: IconButton(
                  icon: Icon(Icons.chat, color: isMyBill ? Colors.orange : Colors.teal),
                  tooltip: isMyBill ? 'الرد على المتبرعين' : 'مراسلة صاحب الفاتورة',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(bill: bill)));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUploadCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('أضف فاتورتك أو دينك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) setState(() => receiptImage = File(picked.path));
                    },
                    child: Container(
                      height: 100, color: Colors.grey[200],
                      child: receiptImage != null ? Image.file(receiptImage!, fit: BoxFit.cover) : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long), Text('صورة الفاتورة')]),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (picked != null) setState(() => shamImage = File(picked.path));
                    },
                    child: Container(
                      height: 100, color: Colors.grey[200],
                      child: shamImage != null ? Image.file(shamImage!, fit: BoxFit.cover) : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.qr_code), Text('كود شام كاش')]),
                    ),
                  ),
                ),
              ],
            ),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ المطلوب')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'وصف الدين')),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
            TextField(controller: shamController, decoration: const InputDecoration(labelText: 'رقم شام كاش')),
            const SizedBox(height: 15),
            
            if (uploadAdsWatched < 5)
              ElevatedButton.icon(
                onPressed: () async {
                  if (uploadAdsWatched >= 5) return;
                  final Uri url = Uri.parse(adsterraSmartlink);
                  if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    setState(() => uploadAdsWatched++);
                  }
                },
                icon: const Icon(Icons.play_circle_fill),
                label: Text('يجب مشاهدة 5 إعلانات لفتح الرفع ($uploadAdsWatched/5)'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
              )
            else
              ElevatedButton(
                onPressed: isUploading ? null : () async {
                  if (receiptImage == null || amountController.text.isEmpty) return;
                  setState(() => isUploading = true);
                  try {
                    final user = Supabase.instance.client.auth.currentUser;
                    final path = '${user!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                    await Supabase.instance.client.storage.from('bills').upload(path, receiptImage!);
                    final url = Supabase.instance.client.storage.from('bills').getPublicUrl(path);

                    String? shamUrl;
                    if (shamImage != null) {
                      final shamPath = '${user.id}/sham_${DateTime.now().millisecondsSinceEpoch}.jpg';
                      await Supabase.instance.client.storage.from('bills').upload(shamPath, shamImage!);
                      shamUrl = Supabase.instance.client.storage.from('bills').getPublicUrl(shamPath);
                    }

                    await Supabase.instance.client.from('bills').insert({
                      'user_id': user.id, 'amount': double.parse(amountController.text),
                      'description': descController.text, 'phone_number': phoneController.text,
                      'sham_cash_code': shamController.text, 'receipt_image_url': url, 'sham_cash_image_url': shamUrl,
                    });
                    
                    setState(() { 
                      uploadAdsWatched = 0; 
                      receiptImage = null; 
                      shamImage = null; 
                      amountController.clear(); 
                      descController.clear(); 
                      phoneController.clear(); 
                      shamController.clear();
                    });
                    
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الرفع بنجاح')));
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                  } finally {
                    setState(() => isUploading = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
                child: isUploading ? const CircularProgressIndicator(color: Colors.white) : const Text('رفع الفاتورة الآن'),
              ),
          ],
        ),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> bill;
  const ChatPage({super.key, required this.bill});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _msgController = TextEditingController();
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  bool isOwner = false;

  @override
  void initState() {
    super.initState();
    isOwner = widget.bill['user_id'] == currentUserId;
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_msgController.text.trim().isEmpty) return;
    await Supabase.instance.client.from('chats').insert({
      'bill_id': widget.bill['id'],
      'message': _msgController.text.trim(),
      'sender_id': currentUserId,
    });
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isOwner ? 'الرد على المتبرعين' : 'مراسلة صاحب الفاتورة'),
            Text('فاتورة بقيمة ${widget.bill['amount']} ل.س', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          if (widget.bill['phone_number'] != null && widget.bill['phone_number'].toString().isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () => launchUrl(Uri.parse('tel:${widget.bill['phone_number']}')),
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client.from('chats').stream(primaryKey: ['id']).order('created_at'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                List<Map<String, dynamic>> allMessages = snapshot.data!;
                final messages = allMessages.where((msg) => msg['bill_id'] == widget.bill['id']).toList();

                if (messages.isEmpty) return const Center(child: Text('لا توجد رسائل بعد. ابدأ المحادثة!'));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == currentUserId;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal[100] : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                          ),
                        ),
                        child: Text(msg['message'], style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك هنا...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
