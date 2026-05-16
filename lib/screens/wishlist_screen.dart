// lib/screens/wishlist_screen.dart
// Autor: Diego (Apioide) — feature/diego-wishlist-analisis
//
// Wishlist: Cola (Queue) de piezas guardadas para comprar después.
//   - enqueue() al guardar una pieza desde el catálogo
//   - dequeue() al "comprar" una pieza (pasa al ensamble)
//   - Muestra el orden FIFO de la cola con numeración

import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_state.dart';
import '../models/api_models/item_model.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final AppState _estado = AppState();

  @override
  void initState() {
    super.initState();
    _estado.addListener(_actualizar);
  }

  @override
  void dispose() {
    _estado.removeListener(_actualizar);
    super.dispose();
  }

  void _actualizar() => setState(() {});

  // Dequeue: comprar la pieza del frente y moverla al ensamble
  void _comprar() {
    final pieza = _estado.comprarDesdWishlist();
    if (pieza == null) return;
    _snack('${pieza.nombre} movida al ensamble.');
  }

  // Quitar una pieza específica sin comprarla (por si el usuario se arrepiente)
  void _quitarDeLaWishlist(ItemModel pieza) {
    // Reconstruimos la cola sin esa pieza
    final lista = _estado.wishlist.toList();
    while (!_estado.wishlist.isEmpty) {
      _estado.wishlist.dequeue();
    }
    for (final p in lista) {
      if (p != pieza) _estado.wishlist.enqueue(p);
    }
    _estado.notificar();
    _snack('${pieza.nombre} quitada de la Wishlist.');
  }

  void _snack(String msg, {bool esError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(color: AppColors.textOnDark)),
        backgroundColor: esError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final piezas = _estado.wishlist.toList();
    final totalWishlist =
        piezas.fold(0.0, (sum, p) => sum + p.precio);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        centerTitle: true,
        title: const Text('Wishlist',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: piezas.isEmpty
          ? _buildVacio()
          : Column(
              children: [
                _buildHeader(piezas.length, totalWishlist),
                _buildInfoCola(),
                Expanded(child: _buildListaCola(piezas)),
              ],
            ),
      // Botón principal: comprar el primero (dequeue)
      floatingActionButton: piezas.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _comprar,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnDark,
              icon: const Icon(Icons.shopping_cart_checkout_rounded),
              label: const Text('Comprar siguiente'),
            ),
    );
  }

  Widget _buildVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.favorite_rounded,
                size: 36, color: AppColors.secondary),
          ),
          const SizedBox(height: 16),
          const Text('Tu Wishlist está vacía',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Agrega piezas desde el Catálogo',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHeader(int count, double total) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          _HeaderStat(Icons.favorite_rounded, '$count', 'En lista'),
          const SizedBox(width: 12),
          _HeaderStat(Icons.attach_money_rounded,
              'Q${total.toStringAsFixed(0)}', 'Total'),
          const SizedBox(width: 12),
          _HeaderStat(Icons.arrow_forward_rounded,
              'FIFO', 'Orden cola'),
        ],
      ),
    );
  }

  Widget _buildInfoCola() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.linear_scale_rounded,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          const Text(
            'Cola FIFO — el primero que entra es el primero en comprarse',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCola(List<ItemModel> piezas) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: piezas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final pieza = piezas[i];
        final esPrimero = i == 0;
        return Container(
          decoration: BoxDecoration(
            color: esPrimero ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: esPrimero ? AppColors.primary : AppColors.border),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: esPrimero
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('${i + 1}',
                    style: TextStyle(
                        color: esPrimero
                            ? AppColors.textOnDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
            ),
            title: Text(pieza.nombre,
                style: TextStyle(
                    color: esPrimero
                        ? AppColors.textOnDark
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            subtitle: Text(
              '${pieza.categoria}${esPrimero ? " · Siguiente en comprarse" : ""}',
              style: TextStyle(
                  color: esPrimero
                      ? AppColors.textOnDark.withValues(alpha: 0.7)
                      : AppColors.textSecondary,
                  fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Q${pieza.precio.toStringAsFixed(0)}',
                    style: TextStyle(
                        color: esPrimero
                            ? AppColors.textOnDark
                            : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _quitarDeLaWishlist(pieza),
                  child: Icon(Icons.close_rounded,
                      size: 18,
                      color: esPrimero
                          ? AppColors.textOnDark.withValues(alpha: 0.7)
                          : AppColors.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String valor;
  final String etiqueta;
  const _HeaderStat(this.icon, this.valor, this.etiqueta);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textOnDark, size: 18),
            const SizedBox(height: 4),
            Text(valor,
                style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(etiqueta,
                style: TextStyle(
                    color: AppColors.textOnDark.withValues(alpha: 0.65),
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
