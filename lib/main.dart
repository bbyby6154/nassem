import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// ⚠️ مفاتيح Supabase الخاصة بك
const String supabaseUrl = 'https://hihsyulcigbgjihmqafc.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpaHN5dWxjaWdiZ2ppaG1xYWZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQyMzgxMjIsImV4cCI6MjEwOTgxNDEyMn0.gJnW41Ey6UF0LvNjCyR9sYyklNgtinWuncFJprPKIMY';

// ⚠️ رابط الإعلان الخاص بك (Smartlink)
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
      home: Supabase.instance.client.auth.currentSession == null
          ? const AuthScreen()
          : const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ================= شاشة تسجيل الدخول =================
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
    if (username.isEmpty || password.isEmpty) return;

    final email = '$username@nassem.com';
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
      } else {
        await Supabase.instance.client.auth.signUp(email: email, password: password);
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
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
              TextField(
                controller: _userController,
                decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              ),
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

// ================= الشاشة الرئيسية =================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shamCashController = TextEditingController();
  final _descController = TextEditingController();
  File? _receiptImage;
  File? _shamImage;
  bool _isUploading = false;
  
  // عدّاد الإعلانات
  int _adsWatched = 0;

  Future<void> _pickImage(bool isReceipt) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isReceipt) _receiptImage = File(pickedFile.path);
        else _shamImage = File(pickedFile.path);
      });
    }
  }

  // دالة فتح رابط الإعلان وزيادة العداد
  Future<void> _watchAd() async {
    if (_adsWatched >= 5) return; 
    
    final Uri url = Uri.parse(adsterraSmartlink);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح رابط الإعلان')));
      }
    } else {
      setState(() {
        _adsWatched++;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم احتساب الإعلان. تبقى ${5 - _adsWatched} إعلانات لفتح زر الرفع'),
          backgroundColor: Colors.teal,
        ));
      }
    }
  }

  Future<void> _uploadBill() async {
    if (_adsWatched < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يجب مشاهدة 5 إعلانات أولاً لفتح الرفع')));
      return;
    }

    if (_receiptImage == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إضافة صورة الفاتورة والمبلغ')));
      return;
    }
    setState(() => _isUploading = true);
    
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

      final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('bills').upload(path, _receiptImage!);
      final receiptUrl = supabase.storage.from('bills').getPublicUrl(path);

      String? shamUrl;
      if (_shamImage != null) {
        final shamPath = '${user.id}/sham_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('bills').upload(shamPath, _shamImage!);
        shamUrl = supabase.storage.from('bills').getPublicUrl(shamPath);
      }

      await supabase.from('bills').insert({
        'user_id': user.id,
        'amount': double.parse(_amountController.text),
        'description': _descController.text,
        'phone_number': _phoneController.text,
        'sham_cash_code': _shamCashController.text,
        'receipt_image_url': receiptUrl,
        'sham_cash_image_url': shamUrl,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفع الفاتورة بنجاح')));
        setState(() {
          _receiptImage = null; _shamImage = null;
          _amountController.clear(); _phoneController.clear();
          _shamCashController.clear(); _descController.clear();
          // إعادة تصفير العداد بعد الرفع (اختياري، قم بإزالة هذا السطر إذا أردت بقاء الفتح دائماً)
          _adsWatched = 0; 
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('نسيم - مساعدة المحتاجين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
              }
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- قسم الإعلانات ---
          Card(
            color: _adsWatched >= 5 ? Colors.green[50] : Colors.orange[50],
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    _adsWatched >= 5 ? 'تم فتح الرفع! يمكنك رفع فاتورتك الآن.' : 'يجب مشاهدة 5 إعلانات لفتح زر رفع الفاتورة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _adsWatched >= 5 ? Colors.green[800] : Colors.orange[800]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  if (_adsWatched < 5)
                    ElevatedButton.icon(
                      onPressed: _watchAd,
                      icon: const Icon(Icons.play_circle_fill),
                      label: Text('شاهد إعلان (${_adsWatched} / 5)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    )
                  else
                    const Icon(Icons.check_circle, color: Colors.green, size: 40),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          
          // --- نموذج رفع الفاتورة ---
          Card(
            elevation: 4,
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
                          onTap: () => _pickImage(true),
                          child: Container(
                            height: 120,
                            color: Colors.grey[200],
                            child: _receiptImage != null 
                              ? Image.file(_receiptImage!, fit: BoxFit.cover) 
                              : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.receipt_long, size: 40), Text('صورة الفاتورة')]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickImage(false),
                          child: Container(
                            height: 120,
                            color: Colors.grey[200],
                            child: _shamImage != null 
                              ? Image.file(_shamImage!, fit: BoxFit.cover) 
                              : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.qr_code, size: 40), Text('كود شام كاش')]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ المطلوب (بالليرة)')),
                  TextField(controller: _descController, decoration: const InputDecoration(labelText: 'وصف الدين أو الحالة')),
                  TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف للتواصل')),
                  TextField(controller: _shamCashController, decoration: const InputDecoration(labelText: 'رقم أو عنوان محفظة شام كاش')),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    // الزر معطل إذا لم يشاهد 5 إعلانات
                    onPressed: (_isUploading || _adsWatched < 5) ? null : _uploadBill,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                      backgroundColor: _adsWatched >= 5 ? Colors.teal : Colors.grey,
                    ),
                    child: _isUploading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : Text(_adsWatched < 5 ? 'مقفل (شاهد 5 إعلانات)' : 'رفع الفاتورة'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('الفواتير المتاحة للمتبرعين:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client.from('bills').stream(primaryKey: ['id']).order('created_at'),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final bills = snapshot.data!;
              if (bills.isEmpty) return const Text('لا توجد فواتير حالياً.');
              
              return Column(
                children: bills.map((bill) {
                  return Card(
                    child: ListTile(
                      leading: Image.network(bill['receipt_image_url'] ?? '', width: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image)),
                      title: Text('المبلغ: ${bill['amount']} ل.س', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('الحالة: ${bill['description'] ?? "غير محدد"}\nشام كاش: ${bill['sham_cash_code'] ?? "غير متوفر"}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.chat, color: Colors.teal),
                        onPressed: () => showDialog(context: context, builder: (context) => ChatScreen(billId: bill['id'])),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ================= شاشة الدردشة =================
class ChatScreen extends StatefulWidget {
  final int billId;
  const ChatScreen({super.key, required this.billId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgController = TextEditingController();
  
  void _sendMessage() async {
    if (_msgController.text.isEmpty) return;
    await Supabase.instance.client.from('chats').insert({
      'bill_id': widget.billId,
      'message': _msgController.text,
      'sender_id': Supabase.instance.client.auth.currentUser?.id,
    });
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('التواصل مع صاحب الفاتورة'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client.from('chats').stream(primaryKey: ['id']).eq('bill_id', widget.billId).order('created_at'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!;
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['sender_id'] == Supabase.instance.client.auth.currentUser?.id;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.teal[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(msg['message']),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(child: TextField(controller: _msgController, decoration: const InputDecoration(hintText: 'اكتب رسالة...'))),
                IconButton(icon: const Icon(Icons.send, color: Colors.teal), onPressed: _sendMessage),
              ],
            )
          ],
        ),
      ),
    );
  }
}
