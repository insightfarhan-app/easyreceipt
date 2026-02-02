import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SalesGraph extends StatelessWidget {
  final List<double> data;

  const SalesGraph({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5), 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sales Performance",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Last 7 Days",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.show_chart,
                      color: Color(0xFF22C55E),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Live",
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: data.isEmpty || data.every((e) => e == 0)
                ? Center(
                    child: Text(
                      "No sales data yet",
                      style: GoogleFonts.inter(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  )
                : CustomPaint(
                    size: Size.infinite,
                    painter: _ChartPainter(data),
                  ),
          ),
          const SizedBox(height: 10),
          // Days Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final date = DateTime.now().subtract(Duration(days: 6 - index));
              return Text(
                "${date.day}/${date.month}",
                style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> data;

  _ChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [
        const Color(0xFF3B82F6).withOpacity(0.3),
        const Color(0xFF3B82F6).withOpacity(0.0),
      ]);

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    // Draw Grid Lines
    double dx = size.width / (data.length - 1);
    for (int i = 0; i < data.length; i++) {
      canvas.drawLine(
        Offset(i * dx, 0),
        Offset(i * dx, size.height),
        gridPaint,
      );
    }
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      gridPaint,
    );
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), gridPaint);
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      gridPaint,
    );

    // Normalize Data
    double maxVal = data.reduce((curr, next) => curr > next ? curr : next);
    if (maxVal == 0) maxVal = 1;

    final path = Path();
    final fillPath = Path();

    // Start point
    final startY = size.height - (data[0] / maxVal) * size.height;
    path.moveTo(0, startY);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, startY);

    for (int i = 1; i < data.length; i++) {
      final x = i * dx;
      final y = size.height - (data[i] / maxVal) * size.height;

      // Smooth Curve using quadratic bezier
      final previousX = (i - 1) * dx;
      final previousY = size.height - (data[i - 1] / maxVal) * size.height;

      final controlX = (previousX + x) / 2;

      path.cubicTo(controlX, previousY, controlX, y, x, y);
      fillPath.cubicTo(controlX, previousY, controlX, y, x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw Shadow/Glow
    canvas.drawPath(
      path,
      paint
        ..color = const Color(0xFF3B82F6).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Draw Main Line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(
      path,
      paint
        ..color = const Color(0xFF60A5FA)
        ..maskFilter = null,
    );

    // Draw Points
    for (int i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = size.height - (data[i] / maxVal) * size.height;
      canvas.drawCircle(Offset(x, y), 4, Paint()..color = Colors.white);
      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()..color = const Color(0xFF3B82F6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
