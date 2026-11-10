import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// ⚠️ مفاتيح قاعدة البيانات الخاصة بك
const String supabaseUrl = 'https://hihsyulcigbgjihmqafc.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpaHN5dWxjaWdiZ2ppaG1xYWZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQyMzgxMjIsImV4cCI6MjEwOTgxNDEyMn0.gJnW41Ey6UF0LvNjCyR9sYyklNgtinWuncFJprPKIMY';
// ملاحظة: ميزة الذكاء الاصطناعي تحتاج مفتاح Gemini، يمكنك تركه فارغاً الآن
const String geminiApiKey = 'YOUR_GEMINI_API_KEY'; 

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
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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
  bool _isAnalyzing = false;

  Future<void> _pickImage(bool isReceipt) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isReceipt) _receiptImage = File(pickedFile.path);
        else _shamImage = File(pickedFile.path);
      });
      if (isReceipt) _analyzeReceipt(_receiptImage!);
    }
  }

  Future<void> _analyzeReceipt(File image) async {
    if (geminiApiKey == 'YOUR_GEMINI_API_KEY') return; 
    setState(() => _isAnalyzing = true);
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: geminiApiKey);
      final prompt = 'استخرج المبلغ الإجمالي من صورة الفاتورة هذه. أجب برقم فقط دون أي كلمات أخرى.';
      final response = await model.generateContent([
        Content.multi([TextPart(prompt), DataPart('image/jpeg', await image.readAsBytes())])
      ]);
      final extractedAmount = response.text?.trim() ?? '';
      if (double.tryParse(extractedAmount) != null) {
        _amountController.text = extractedAmount;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر قراءة الفاتورة آلياً')));
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _uploadBill() async {
    if (_receiptImage == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إضافة صورة الفاتورة والمبلغ')));
      return;
    }
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      final path = '${user?.id ?? 'anon'}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await supabase.storage.from('bills').upload(path, _receiptImage!);
      final receiptUrl = supabase.storage.from('bills').getPublicUrl(path);

      String? shamUrl;
      if (_shamImage != null) {
        final shamPath = '${user?.id ?? 'anon'}/sham_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('bills').upload(shamPath, _shamImage!);
        shamUrl = supabase.storage.from('bills').getPublicUrl(shamPath);
      }

      await supabase.from('bills').insert({
        'user_id': user?.id,
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
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نسيم - مساعدة المحتاجين')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
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
                  if (_isAnalyzing) const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
                  TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ المطلوب (بالليرة)')),
                  TextField(controller: _descController, decoration: const InputDecoration(labelText: 'وصف الدين أو الحالة')),
                  TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'رقم الهاتف للتواصل')),
                  TextField(controller: _shamCashController, decoration: const InputDecoration(labelText: 'رقم أو عنوان محفظة شام كاش')),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _uploadBill,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                    child: const Text('رفع الفاتورة'),
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
