<?php

namespace App\Http\Controllers;

use App\Models\Bill;
use Illuminate\Http\Request;
use Illuminate\View\View;

class BillController extends Controller
{
    public function index(Request $request): View
    {
        $user = $request->user();

        $bills = Bill::where('user_id', $user->id)
            ->orderBy('due_day')
            ->get();

        $totalMonthly = $bills->sum(fn ($b) => (float) ($b->average_amount ?? 0));

        // Next due this month
        $today    = now()->day;
        $upcoming = $bills->filter(fn ($b) => $b->due_day !== null && $b->due_day >= $today)
                          ->sortBy('due_day');

        return view('bills.index', compact('bills', 'totalMonthly', 'upcoming'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name'               => 'required|string|max:200',
            'type'               => 'required|string|in:electricity,water,gas,internet,phone,rent,insurance,other',
            'provider'           => 'nullable|string|max:200',
            'account_number'     => 'nullable|string|max:100',
            'average_amount'     => 'nullable|numeric|min:0',
            'due_day'            => 'nullable|integer|min:1|max:31',
            'is_autopay'         => 'boolean',
            'autopay_account_id' => 'nullable|integer|exists:accounts,id,user_id,' . $request->user()->id,
        ]);

        $data['user_id']   = $request->user()->id;
        $data['is_autopay'] = (bool) ($data['is_autopay'] ?? false);

        Bill::create($data);

        return redirect()->route('bills.index')->with('success', 'Fatura eklendi.');
    }

    public function update(Request $request, Bill $bill)
    {
        abort_unless($bill->user_id === $request->user()->id, 403);

        $data = $request->validate([
            'last_amount' => 'required|numeric|min:0',
        ]);

        $bill->update([
            'last_amount'  => $data['last_amount'],
            'last_paid_at' => now(),
        ]);

        return redirect()->route('bills.index')->with('success', "{$bill->name} ödeme kaydedildi.");
    }

    public function destroy(Request $request, Bill $bill)
    {
        abort_unless($bill->user_id === $request->user()->id, 403);

        $bill->delete();

        if ($request->wantsJson()) {
            return response()->json(['success' => true]);
        }

        return redirect()->route('bills.index')->with('success', 'Fatura silindi.');
    }
}
