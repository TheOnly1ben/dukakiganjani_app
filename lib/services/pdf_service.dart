import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../model/store.dart';
import '../model/sales.dart';

class PdfService {
  static Future<void> generateAndShareSalesReport({
    required Store store,
    required Map<String, dynamic> salesReport,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat('#,###');

    // Extract data from sales report
    final totalSales = salesReport['total_sales'] ?? 0;
    final totalProfit = salesReport['total_profit'] ?? 0;
    final salesCount = salesReport['sales_count'] ?? 0;
    final cashSales = salesReport['cash_sales'] ?? 0;
    final creditSales = salesReport['credit_sales'] ?? 0;
    final topProducts = salesReport['top_products'] ?? [];
    final recentSales = salesReport['recent_sales'] ?? [];
    final allSales = (salesReport['sales'] as List<Sale>?) ?? [];

    // Generate report title based on date range
    String reportPeriod;
    if (startDate != null && endDate != null) {
      if (dateFormat.format(startDate) == dateFormat.format(endDate)) {
        reportPeriod = dateFormat.format(startDate);
      } else {
        reportPeriod =
            '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
      }
    } else {
      reportPeriod = dateFormat.format(DateTime.now());
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'RIPOTI YA MAUZO',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    store.name,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    reportPeriod,
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'MUHTASARI',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  _buildSummaryRow('Jumla ya Mauzo',
                      'TZS ${currencyFormat.format(totalSales)}'),
                  _buildSummaryRow(
                      'Faida', 'TZS ${currencyFormat.format(totalProfit)}'),
                  pw.Divider(
                      height: 16, thickness: 1, color: PdfColors.grey300),
                  _buildSummaryRow('Mauzo ya Taslimu',
                      'TZS ${currencyFormat.format(cashSales)}'),
                  _buildSummaryRow('Mauzo ya Mkopo',
                      'TZS ${currencyFormat.format(creditSales)}'),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Top Products Section
            if (topProducts.isNotEmpty) ...[
              pw.Text(
                'BIDHAA ZILIZOUZWA ZAIDI',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Header
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Bidhaa', isHeader: true),
                      _buildTableCell('Kiasi',
                          isHeader: true, align: pw.TextAlign.right),
                      _buildTableCell('Idadi',
                          isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  // Data rows
                  ...topProducts.take(10).map((product) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(product['name'] ?? ''),
                        _buildTableCell(
                          'TZS ${currencyFormat.format(product['total_amount'] ?? 0)}',
                          align: pw.TextAlign.right,
                        ),
                        _buildTableCell(
                          '${product['quantity_sold'] ?? 0}',
                          align: pw.TextAlign.right,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 24),
            ],

            // Sales History Section - Complete list with all products
            if (allSales.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              pw.Text(
                'HISTORIA YA MAUZO',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              ...allSales.map((sale) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Sale header
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(sale.createdAt ?? DateTime.now()),
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: sale.paymentMethod == PaymentMethod.cash
                                  ? PdfColors.green100
                                  : PdfColors.orange100,
                              borderRadius: const pw.BorderRadius.all(
                                  pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              sale.paymentMethod == PaymentMethod.cash
                                  ? 'Taslimu'
                                  : 'Mkopo',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: sale.paymentMethod == PaymentMethod.cash
                                    ? PdfColors.green900
                                    : PdfColors.orange900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Products table
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(3),
                        1: const pw.FlexColumnWidth(1),
                        2: const pw.FlexColumnWidth(2),
                      },
                      children: [
                        // Table header
                        pw.TableRow(
                          decoration:
                              const pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            _buildTableCell('Bidhaa', isHeader: true),
                            _buildTableCell('Idadi',
                                isHeader: true, align: pw.TextAlign.center),
                            _buildTableCell('Kiasi',
                                isHeader: true, align: pw.TextAlign.right),
                          ],
                        ),
                        // Product rows
                        ...sale.items.map((item) {
                          return pw.TableRow(
                            children: [
                              _buildTableCell(item.productName),
                              _buildTableCell(
                                '${item.quantity}',
                                align: pw.TextAlign.center,
                              ),
                              _buildTableCell(
                                'TZS ${currencyFormat.format(item.subtotal)}',
                                align: pw.TextAlign.right,
                              ),
                            ],
                          );
                        }).toList(),
                        // Total row
                        pw.TableRow(
                          decoration:
                              const pw.BoxDecoration(color: PdfColors.grey100),
                          children: [
                            _buildTableCell('JUMLA', isHeader: true),
                            _buildTableCell(''),
                            _buildTableCell(
                              'TZS ${currencyFormat.format(sale.totalAmount)}',
                              isHeader: true,
                              align: pw.TextAlign.right,
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ],

            // Footer
            pw.SizedBox(height: 32),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Ripoti iliyoundwa tarehe ${dateFormat.format(DateTime.now())} | Duka Ganjani',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Save PDF to temporary directory
    final output = await getTemporaryDirectory();
    final fileName =
        'Ripoti_${store.name.replaceAll(' ', '_')}_$reportPeriod.pdf'
            .replaceAll('/', '_');
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    // Share the PDF
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Ripoti ya Mauzo - ${store.name}',
      text: 'Ripoti ya mauzo kwa kipindi: $reportPeriod',
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }
}
