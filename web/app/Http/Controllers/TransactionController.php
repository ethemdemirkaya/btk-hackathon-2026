<?php

namespace App\Http\Controllers;

use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\View\View;
use Symfony\Component\HttpFoundation\StreamedResponse;

class TransactionController extends Controller
{
    // ─── List / Filter ────────────────────────────────────────────────────────
    public function index(Request $request): View
    {
        $user = $request->user();

        $query = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->join('bank_connections as bc', 'bc.id', '=', 'a.bank_connection_id')
            ->join('banks as b', 'b.id', '=', 'bc.bank_id')
            ->leftJoin('categories as c', 'c.id', '=', 't.category_id')
            ->where('a.user_id', $user->id)
            ->select(
                't.id', 't.posted_at', 't.amount', 't.description',
                't.merchant_name', 't.merchant_category', 't.channel',
                'b.name as bank_name', 'b.logo as bank_logo', 'b.slug as bank_slug',
                'a.account_type',
                'c.name as category_name', 'c.icon as category_icon', 'c.color as category_color'
            );

        if ($q = $request->input('q')) {
            $query->where(function ($sub) use ($q) {
                $sub->where('t.description', 'like', "%{$q}%")
                    ->orWhere('t.merchant_name', 'like', "%{$q}%");
            });
        }

        $type = $request->input('type');
        if ($type === 'income')  $query->where('t.amount', '>', 0);
        if ($type === 'expense') $query->where('t.amount', '<', 0);

        if ($from = $request->input('from')) $query->whereDate('t.posted_at', '>=', $from);
        if ($to   = $request->input('to'))   $query->whereDate('t.posted_at', '<=', $to);

        if ($catId = $request->input('category')) {
            $query->where('t.category_id', (int) $catId);
        }

        if ($bankSlug = $request->input('bank')) {
            $query->where('b.slug', $bankSlug);
        }

        if ($minAmt = $request->input('min_amount')) {
            $query->whereRaw('ABS(t.amount) >= ?', [(float) $minAmt]);
        }

        if ($maxAmt = $request->input('max_amount')) {
            $query->whereRaw('ABS(t.amount) <= ?', [(float) $maxAmt]);
        }

        $transactions = $query->orderByDesc('t.posted_at')->paginate(30)->withQueryString();

        $stats = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('a.user_id', $user->id)
            ->where('t.posted_at', '>=', now()->startOfMonth())
            ->selectRaw('COALESCE(SUM(CASE WHEN t.amount > 0 THEN t.amount ELSE 0 END), 0) as income')
            ->selectRaw('COALESCE(SUM(CASE WHEN t.amount < 0 THEN ABS(t.amount) ELSE 0 END), 0) as expense')
            ->selectRaw('COUNT(*) as total_count')
            ->selectRaw('COALESCE(AVG(ABS(t.amount)), 0) as avg_amount')
            ->first();

        $categories = DB::table('categories')->whereNull('parent_id')->orderBy('name')->get();

        $banks = DB::table('banks as b')
            ->join('bank_connections as bc', 'bc.bank_id', '=', 'b.id')
            ->where('bc.user_id', $user->id)
            ->select('b.slug', 'b.name')
            ->distinct()
            ->orderBy('b.name')
            ->get();

        $personalDebts = DB::table('personal_debts')
            ->where('user_id', $user->id)
            ->where('is_settled', false)
            ->orderByDesc('created_at')
            ->get();

        return view('transactions.index', compact(
            'transactions', 'stats', 'categories', 'banks', 'personalDebts'
        ));
    }

    // ─── CSV Export ───────────────────────────────────────────────────────────
    public function export(Request $request): StreamedResponse
    {
        $user  = $request->user();
        $query = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->join('bank_connections as bc', 'bc.id', '=', 'a.bank_connection_id')
            ->join('banks as b', 'b.id', '=', 'bc.bank_id')
            ->leftJoin('categories as c', 'c.id', '=', 't.category_id')
            ->where('a.user_id', $user->id)
            ->select(
                't.posted_at', 't.description', 't.merchant_name',
                't.merchant_category', 't.amount', 't.channel',
                'b.name as bank_name', 'a.account_type', 'c.name as category_name'
            );

        if ($q = $request->input('q')) {
            $query->where(fn($s) => $s->where('t.description', 'like', "%{$q}%")->orWhere('t.merchant_name', 'like', "%{$q}%"));
        }
        $type = $request->input('type');
        if ($type === 'income')  $query->where('t.amount', '>', 0);
        if ($type === 'expense') $query->where('t.amount', '<', 0);
        if ($from = $request->input('from')) $query->whereDate('t.posted_at', '>=', $from);
        if ($to   = $request->input('to'))   $query->whereDate('t.posted_at', '<=', $to);

        $rows     = $query->orderByDesc('t.posted_at')->get();
        $filename = 'islemler-' . now()->format('Y-m-d') . '.csv';

        return response()->streamDownload(function () use ($rows) {
            $fp = fopen('php://output', 'w');
            fputs($fp, "\xEF\xBB\xBF");
            fputcsv($fp, ['Tarih', 'Açıklama', 'Mağaza', 'Kategori', 'Tutar (₺)', 'Kanal', 'Banka', 'Hesap Türü'], ';');
            foreach ($rows as $row) {
                fputcsv($fp, [
                    Carbon::parse($row->posted_at)->format('d.m.Y H:i'),
                    $row->description,
                    $row->merchant_name ?? '',
                    $row->category_name ?? $row->merchant_category ?? '',
                    number_format((float) $row->amount, 2, ',', '.'),
                    $row->channel ?? '',
                    $row->bank_name,
                    $row->account_type,
                ], ';');
            }
            fclose($fp);
        }, $filename, ['Content-Type' => 'text/csv; charset=UTF-8']);
    }

    // ─── Import: show form ────────────────────────────────────────────────────
    public function showImport(Request $request): View
    {
        $accounts = DB::table('accounts as a')
            ->join('bank_connections as bc', 'bc.id', '=', 'a.bank_connection_id')
            ->join('banks as b', 'b.id', '=', 'bc.bank_id')
            ->where('a.user_id', $request->user()->id)
            ->select('a.id', 'a.account_type', 'a.iban', 'a.balance', 'b.name as bank_name')
            ->get();

        $preview = session('import_preview');
        return view('transactions.import', compact('accounts', 'preview'));
    }

    // ─── Import: parse & preview ──────────────────────────────────────────────
    public function previewImport(Request $request): RedirectResponse
    {
        $request->validate([
            'csv_file'   => 'required|file|mimes:csv,txt|max:10240',
            'account_id' => 'required|integer',
        ]);

        $account = DB::table('accounts')
            ->where('id', $request->account_id)
            ->where('user_id', $request->user()->id)
            ->first();
        abort_unless($account, 403);

        $content = file_get_contents($request->file('csv_file')->getRealPath());

        $enc = mb_detect_encoding($content, ['UTF-8', 'Windows-1254', 'ISO-8859-9', 'ISO-8859-1'], true);
        if ($enc && $enc !== 'UTF-8') {
            $content = mb_convert_encoding($content, 'UTF-8', $enc);
        }
        $content = ltrim($content, "\xEF\xBB\xBF");

        $lines = array_values(array_filter(
            explode("\n", str_replace(["\r\n", "\r"], "\n", $content)),
            fn($l) => trim($l) !== ''
        ));

        if (count($lines) < 2) {
            return back()->withErrors(['csv_file' => 'Dosya çok az satır içeriyor.']);
        }

        $sep     = str_contains($lines[0], ';') ? ';' : ',';
        $headers = str_getcsv(trim($lines[0]), $sep);
        $rows    = [];

        for ($i = 1; $i < count($lines); $i++) {
            $row = str_getcsv(trim($lines[$i]), $sep);
            if (count(array_filter($row, fn($v) => trim($v) !== '')) > 0) {
                $rows[] = $row;
            }
        }

        if (empty($rows)) {
            return back()->withErrors(['csv_file' => 'Veri satırı bulunamadı.']);
        }

        session([
            'import_preview' => [
                'account_id' => $request->account_id,
                'headers'    => $headers,
                'rows'       => array_slice($rows, 0, 5000),
                'preview'    => array_slice($rows, 0, 10),
                'total'      => count($rows),
            ],
        ]);

        return redirect()->route('transactions.import');
    }

    // ─── Import: confirm & save ───────────────────────────────────────────────
    public function confirmImport(Request $request): RedirectResponse
    {
        $request->validate([
            'col_date'     => 'required|integer|min:0',
            'col_amount'   => 'required|integer|min:0',
            'col_desc'     => 'required|integer|min:0',
            'col_merchant' => 'nullable|integer|min:0',
            'col_credit'   => 'nullable|integer|min:0',
            'date_format'  => 'required|string|max:20',
        ]);

        $data = session('import_preview');
        if (! $data) {
            return redirect()->route('transactions.import')
                ->withErrors(['msg' => 'Oturum süresi doldu. Lütfen tekrar yükleyin.']);
        }

        $account = DB::table('accounts')
            ->where('id', $data['account_id'])
            ->where('user_id', $request->user()->id)
            ->first();
        abort_unless($account, 403);

        $colDate  = (int) $request->col_date;
        $colAmt   = (int) $request->col_amount;
        $colDesc  = (int) $request->col_desc;
        $colMerch = $request->filled('col_merchant') ? (int) $request->col_merchant : null;
        $colCred  = $request->filled('col_credit')   ? (int) $request->col_credit   : null;
        $dateFmt  = $request->date_format;

        $inserted = 0;
        $skipped  = 0;
        $batch    = [];

        foreach ($data['rows'] as $row) {
            try {
                $rawDate = trim($row[$colDate] ?? '');
                $date    = Carbon::createFromFormat($dateFmt, $rawDate);
                if (! $date) { $skipped++; continue; }

                $rawAmt = str_replace(['.', ' '], '', trim($row[$colAmt] ?? ''));
                $rawAmt = str_replace(',', '.', $rawAmt);
                $amount = (float) $rawAmt;

                if ($colCred !== null) {
                    $rawCred = str_replace(['.', ' '], '', trim($row[$colCred] ?? '0'));
                    $rawCred = str_replace(',', '.', $rawCred);
                    $credit  = (float) $rawCred;
                    $amount  = $credit > 0 ? $credit : -abs($amount);
                }

                if ($amount == 0) { $skipped++; continue; }

                $batch[] = [
                    'id'            => Str::uuid()->toString(),
                    'account_id'    => $account->id,
                    'posted_at'     => $date->toDateTimeString(),
                    'amount'        => $amount,
                    'try_amount'    => $amount,
                    'currency'      => 'TRY',
                    'description'   => mb_substr(trim($row[$colDesc] ?? 'İçe aktarılan işlem'), 0, 255),
                    'merchant_name' => $colMerch !== null ? (mb_substr(trim($row[$colMerch] ?? ''), 0, 100) ?: null) : null,
                    'channel'       => 'import',
                    'created_at'    => now(),
                    'updated_at'    => now(),
                ];
                $inserted++;

                if (count($batch) >= 200) {
                    DB::table('transactions')->insert($batch);
                    $batch = [];
                }
            } catch (\Throwable) {
                $skipped++;
            }
        }

        if (! empty($batch)) DB::table('transactions')->insert($batch);

        session()->forget('import_preview');

        $msg = "{$inserted} işlem başarıyla içe aktarıldı";
        if ($skipped > 0) $msg .= ", {$skipped} satır atlandı";

        return redirect()->route('transactions.index')->with('success', $msg . '.');
    }

    // ─── Personal Debt: store ─────────────────────────────────────────────────
    public function storeDebt(Request $request, string $txId): RedirectResponse
    {
        $request->validate([
            'contact_name' => 'required|string|max:100',
            'direction'    => 'required|in:given,received',
            'amount'       => 'required|numeric|min:0.01',
            'note'         => 'nullable|string|max:500',
        ]);

        $tx = DB::table('transactions as t')
            ->join('accounts as a', 'a.id', '=', 't.account_id')
            ->where('t.id', $txId)
            ->where('a.user_id', $request->user()->id)
            ->select('t.id')
            ->first();
        abort_unless($tx, 403);

        DB::table('personal_debts')->insert([
            'user_id'        => $request->user()->id,
            'transaction_id' => $txId,
            'contact_name'   => $request->contact_name,
            'amount'         => $request->amount,
            'direction'      => $request->direction,
            'note'           => $request->note,
            'is_settled'     => false,
            'created_at'     => now(),
            'updated_at'     => now(),
        ]);

        return back()->with('success', 'Borç kaydı oluşturuldu.');
    }

    // ─── Personal Debt: settle ────────────────────────────────────────────────
    public function settleDebt(Request $request, int $debtId): RedirectResponse|JsonResponse
    {
        $affected = DB::table('personal_debts')
            ->where('id', $debtId)
            ->where('user_id', $request->user()->id)
            ->update(['is_settled' => true, 'settled_at' => now(), 'updated_at' => now()]);

        if ($request->wantsJson()) return response()->json(['ok' => (bool) $affected]);
        return back()->with('success', 'Borç kapatıldı.');
    }

    // ─── Personal Debt: destroy ───────────────────────────────────────────────
    public function destroyDebt(Request $request, int $debtId): RedirectResponse|JsonResponse
    {
        DB::table('personal_debts')
            ->where('id', $debtId)
            ->where('user_id', $request->user()->id)
            ->delete();

        if ($request->wantsJson()) return response()->json(['ok' => true]);
        return back()->with('success', 'Borç kaydı silindi.');
    }
}
