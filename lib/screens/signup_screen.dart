// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';

// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   bool passwordVisible = false;

//   // Form controllers
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmController = TextEditingController();
//   final TextEditingController _dobController = TextEditingController();

//   DateTime? _selectedDob;
//   File? _selectedImage;
//   final ImagePicker _picker = ImagePicker();

//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final pickedFile = await _picker.pickImage(
//         source: source,
//         maxWidth: 1024,
//         maxHeight: 1024,
//         imageQuality: 80,
//       );
//       if (pickedFile != null) {
//         setState(() {
//           _selectedImage = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       log('Image picker error: $e');
//     }
//   }

//   void _showImagePicker() {
//     showModalBottomSheet(
//       context: context,
//       builder: (BuildContext context) => SafeArea(
//         child: Wrap(
//           children: [
//             SizedBox(
//               height: 100,
//               child: ListTile(
//                 leading: const Icon(Icons.photo_camera),
//                 title: const Text('Camera'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _pickImage(ImageSource.camera);
//                 },
//               ),
//             ),
//             // ListTile(
//             //   leading: const Icon(Icons.photo_library),
//             //   title: const Text('Gallery'),
//             //   onTap: () {
//             //     Navigator.pop(context);
//             //     _pickImage(ImageSource.gallery);
//             //   },
//             // ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _getBatchesFromApi() async {
//     print('get batches');
//     try {
//       final url = kBatchListUrl;
//       final res = await get(Uri.parse(url));
//       print('res ${res.statusCode}, ${res.body}');
//       if (res.statusCode == 200) {
//         final parsedBody = BatchListResponse.fromJson(jsonDecode(res.body));
//         print(res);
//         final batches = parsedBody.data;

//         if (batches == null) {
//           print('batches null');
//           return;
//         }

//         setState(() {
//           _batches = batches;
//         });
//         print(_batches);
//       } else {
//         log(res.toString());
//       }
//     } catch (e, s) {
//       log(e.toString(), stackTrace: s);
//     }
//   }

//   @override
//   void initState() {
//     passwordVisible = true;
//     _getBatchesFromApi();
//     super.initState();
//   }

//   String selectedValue = '';

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _passwordController.dispose();
//     _confirmController.dispose();
//     _dobController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickDob() async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime(2003, 1, 1),
//       firstDate: DateTime(1950),
//       lastDate: DateTime.now(),
//     );

//     if (picked != null) {
//       setState(() {
//         _selectedDob = picked;
//         // Use YYYY-MM-DD format
//         _dobController.text = picked.toIso8601String().split('T').first;
//       });
//     }
//   }

//   Future<void> _submit() async {
//     final name = _nameController.text.trim();
//     final email = _emailController.text.trim();
//     final phone = _phoneController.text.trim();
//     final password = _passwordController.text;
//     final confirm = _confirmController.text;
//     final batchId = selectedValue;
//     final dob = _dobController.text;

//     if (name.isEmpty ||
//         email.isEmpty ||
//         phone.isEmpty ||
//         password.isEmpty ||
//         batchId.isEmpty ||
//         _selectedImage == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please fill all fields and select an image'),
//         ),
//       );
//       return;
//     }

//     if (password != confirm) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
//       return;
//     }

//     final url = '$kBaseUrl/student/signup';

//     try {
//       // Prepare JSON body including base64 image so backend can use req.body.image
//       final Map<String, dynamic> body = {
//         'name': name,
//         'email': email,
//         'phone_number': phone,
//         'batch': batchId,
//         'password': password,
//       };
//       if (dob.isNotEmpty) body['dob'] = dob;

//       try {
//         final bytes = await _selectedImage!.readAsBytes();
//         final b64 = base64Encode(bytes);
//         final dataUri = 'data:image/jpeg;base64,$b64';
//         body['image'] = dataUri; // backend will read this from req.body.image
//       } catch (e) {
//         log('Failed to read image bytes for base64: $e');
//       }

//       // Send JSON request
//       final response = await post(
//         Uri.parse(url),
//         headers: {'content-type': 'application/json'},
//         body: jsonEncode(body),
//       );

//       log('[signup] ${response.statusCode} ${response.body}');

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('Signup successful')));
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (_) => const LoginScreen()),
//         );
//       } else {
//         String msg = 'Signup failed';
//         try {
//           final parsed = jsonDecode(response.body) as Map<String, dynamic>;
//           if (parsed['message'] != null) msg = parsed['message'].toString();
//         } catch (_) {}
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text(msg)));
//       }
//     } catch (e) {
//       log('Signup error: $e');
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Network error')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Center(
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Sign up',
//                     style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
//                   ),

//                   Container(color: Colors.orange, width: 60, height: 2),
//                   SizedBox(height: 30),
//                   Text(
//                     "Name",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   TextField(
//                     controller: _nameController,
//                     style: TextStyle(height: 2.5),
//                     decoration: InputDecoration(
//                       prefixIcon: Icon(Icons.person, size: 18.0),
//                       hintText: 'Enter your Full Name',
//                     ),
//                   ),
//                   SizedBox(height: 30),

//                   Text(
//                     "Email",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   TextField(
//                     controller: _emailController,
//                     keyboardType: TextInputType.emailAddress,
//                     style: TextStyle(height: 2.5),
//                     decoration: InputDecoration(
//                       prefixIcon: Icon(Icons.email, size: 18.0),
//                       hintText: 'Enter your Email',
//                     ),
//                   ),
//                   SizedBox(height: 30),

//                   Text(
//                     "Phone ",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   TextField(
//                     controller: _phoneController,
//                     keyboardType: TextInputType.phone,
//                     style: TextStyle(height: 2.5),
//                     decoration: InputDecoration(
//                       prefixIcon: Icon(Icons.phone, size: 18.0),
//                       hintText: 'Enter your Phone number',
//                     ),
//                   ),
//                   SizedBox(height: 30),

//                   Text(
//                     "Date of Birth",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   TextField(
//                     controller: _dobController,
//                     readOnly: true,
//                     onTap: _pickDob,
//                     decoration: InputDecoration(
//                       prefixIcon: Icon(Icons.cake, size: 18.0),
//                       hintText: 'Select Date of Birth',
//                     ),
//                   ),
//                   const SizedBox(height: 30),

//                   Text(
//                     "Batch",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),

//                   DropdownMenu(
//                     width: double.infinity,
//                     // Make dropdown look like TextField underline
//                     inputDecorationTheme: const InputDecorationTheme(
//                       border: UnderlineInputBorder(),
//                       enabledBorder: UnderlineInputBorder(
//                         borderSide: BorderSide(color: Colors.grey),
//                       ),
//                       focusedBorder: UnderlineInputBorder(
//                         borderSide: BorderSide(color: Colors.blue),
//                       ),
//                       // prefixIcon: Icon(Icons.list, size: 18),
//                       contentPadding: EdgeInsets.symmetric(vertical: 16),
//                     ),

//                     hintText: "Select Batch",

//                     dropdownMenuEntries: _batches
//                         .map(
//                           (e) => DropdownMenuEntry(
//                             value: e.id,
//                             label: e.name ?? '',
//                           ),
//                         )
//                         .toList(),
//                     onSelected: (value) {
//                       setState(() {
//                         selectedValue = value?.toString() ?? '';
//                       });
//                     },
//                   ),

//                   SizedBox(height: 30),
//                   Text(
//                     "Password",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),

//                   TextField(
//                     controller: _passwordController,
//                     obscureText: passwordVisible,
//                     style: TextStyle(height: 2.5),
//                     decoration: InputDecoration(
//                       prefixIcon: Icon(Icons.key_rounded, size: 19.0),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           passwordVisible
//                               ? Icons.visibility
//                               : Icons.visibility_off,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             passwordVisible = !passwordVisible;
//                           });
//                         },
//                       ),
//                       hintText: 'Enter your Password',
//                     ),
//                   ),
//                   SizedBox(height: 30),
//                   Text(
//                     "Confirm Password",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   TextField(
//                     controller: _confirmController,
//                     obscureText: true,
//                     style: TextStyle(height: 2.5),
//                     decoration: InputDecoration(
//                       prefixIcon: Icon(Icons.key_rounded, size: 19.0),
//                       hintText: 'Confirm your Password',
//                     ),
//                   ),

//                   const SizedBox(height: 30),

//                   Text(
//                     "Upload Photo",
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 10),
//                   Center(
//                     child: Column(
//                       children: [
//                         if (_selectedImage != null)
//                           Container(
//                             width: 120,
//                             height: 120,
//                             decoration: BoxDecoration(
//                               border: Border.all(color: Colors.grey),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Image.file(
//                               _selectedImage!,
//                               fit: BoxFit.cover,
//                             ),
//                           )
//                         else
//                           Container(
//                             width: 120,
//                             height: 120,
//                             decoration: BoxDecoration(
//                               border: Border.all(color: Colors.grey),
//                               borderRadius: BorderRadius.circular(8),
//                               color: Colors.grey.shade200,
//                             ),
//                             child: Icon(
//                               Icons.camera_alt,
//                               size: 50,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         const SizedBox(height: 12),
//                         ElevatedButton.icon(
//                           onPressed: _showImagePicker,
//                           icon: const Icon(Icons.camera_alt),
//                           label: const Text('Pick Photo'),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 30),
//                   SizedBox(height: 30),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _submit,
//                       child: Text('Submit'),
//                     ),
//                   ),

//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     spacing: 8,
//                     children: [
//                       Text('Already have an account?'),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.of(context).pushReplacement(
//                             MaterialPageRoute<void>(
//                               builder: (context) => const LoginScreen(),
//                             ),
//                           );
//                         },
//                         child: Text('Sign In'),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
