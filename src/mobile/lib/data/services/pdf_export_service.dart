import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:the_app/data/models/transaction.dart';
import 'package:the_app/data/models/account.dart';
import 'package:the_app/data/models/budget.dart';

class PdfExportService {
  final _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  final _dateFormat = DateFormat('dd/MM/yyyy');

  Future<String?> generateMonthlyReport({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Budget> budgets,
    required DateTime month,
    required double totalIncome,
    required double totalExpenses,
    required double balance,
  }) async {
    final pdf = pw.Document();

    final monthName = DateFormat('MMMM yyyy', 'es').format(month).toUpperCase();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(monthName),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummarySection(totalIncome, totalExpenses, balance),
          pw.SizedBox(height: 20),
          _buildTransactionsSection(transactions, accounts),
          pw.SizedBox(height: 20),
          _buildBudgetSection(budgets, transactions, month),
          pw.SizedBox(height: 20),
          _buildAccountsSection(accounts, transactions),
        ],
      ),
    );

    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar reporte',
        fileName: 'reporte_$monthName.pdf',
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsBytes(await pdf.save());
        return result;
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  pw.Widget _buildHeader(String monthName) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Reporte Financiero',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                monthName,
                style: const pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'Finanzas App',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado: ${_dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(
      double income, double expenses, double balance) {
    final isPositive = balance >= 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RESUMEN DEL MES',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                  'Ingresos', _currencyFormat.format(income), PdfColors.green),
              _buildSummaryItem(
                  'Gastos', _currencyFormat.format(expenses), PdfColors.red),
              _buildSummaryItem(
                'Balance',
                _currencyFormat.format(balance.abs()),
                isPositive ? PdfColors.green : PdfColors.red,
                prefix: isPositive ? '+' : '-',
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value, PdfColor color,
      {String prefix = ''}) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '$prefix$value',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTransactionsSection(
      List<Transaction> transactions, List<Account> accounts) {
    final accountMap = {for (var a in accounts) a.id: a.name};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TRANSACCIONES',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableHeader('Fecha'),
                _buildTableHeader('Descripción'),
                _buildTableHeader('Categoría'),
                _buildTableHeader('Cuenta'),
                _buildTableHeader('Monto'),
              ],
            ),
            ...transactions.take(50).map((t) => pw.TableRow(
                  children: [
                    _buildTableCell(_dateFormat.format(t.date)),
                    _buildTableCell(t.description),
                    _buildTableCell(t.category),
                    _buildTableCell(accountMap[t.accountId] ?? 'N/A'),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        '${t.isExpense ? '-' : '+'}${_currencyFormat.format(t.amount)}',
                        style: pw.TextStyle(
                          color: t.isExpense ? PdfColors.red : PdfColors.green,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )),
          ],
        ),
        if (transactions.length > 50)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              '... y ${transactions.length - 50} transacciones más',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  pw.Widget _buildBudgetSection(
      List<Budget> budgets, List<Transaction> transactions, DateTime month) {
    final monthExpenses = transactions
        .where((t) =>
            t.isExpense &&
            t.date.month == month.month &&
            t.date.year == month.year)
        .fold<Map<String, double>>({}, (map, t) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
      return map;
    });

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PRESUPUESTOS',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 8),
        ...budgets.map((b) {
          final spent = monthExpenses[b.category] ?? 0;
          final percent = b.limit > 0 ? (spent / b.limit * 100) : 0;
          final remaining = b.limit - spent;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(b.category, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: percent > 100
                        ? PdfColors.red
                        : (percent > 80 ? PdfColors.orange : PdfColors.green),
                  ),
                ),
                pw.Text(
                  'Restante: ${_currencyFormat.format(remaining)}',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildAccountsSection(
      List<Account> accounts, List<Transaction> transactions) {
    final accountBalances = <String, double>{};
    for (final a in accounts) {
      accountBalances[a.id] = a.initialBalance;
    }
    for (final t in transactions) {
      accountBalances[t.accountId] = (accountBalances[t.accountId] ?? 0) +
          (t.isExpense ? -t.amount : t.amount);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CUENTAS',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableHeader('Cuenta'),
                _buildTableHeader('Tipo'),
                _buildTableHeader('Balance'),
              ],
            ),
            ...accounts.map((a) => pw.TableRow(
                  children: [
                    _buildTableCell(a.name),
                    _buildTableCell(a.type),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        _currencyFormat.format(accountBalances[a.id] ?? 0),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: (accountBalances[a.id] ?? 0) >= 0
                              ? PdfColors.green
                              : PdfColors.red,
                        ),
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ],
    );
  }
}
