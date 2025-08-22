import 'package:flutter/material.dart';


class CustomEmailField extends StatelessWidget {
  final TextEditingController controller;

  const CustomEmailField({super.key, required this.controller});

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: 'E-mail',
        prefixIcon: const Icon(Icons.email),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: 'exemplo@dominio.com',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo obrigatório';
        } else if (!isValidEmail(value.trim())) {
          return 'Formato de e-mail inválido';
        }
        return null;
      },
    );
  }
}
