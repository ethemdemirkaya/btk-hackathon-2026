<?php

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class PersonalDebtController extends Controller
{
    // ─── Index ────────────────────────────────────────────────────────────────
    public function index(): View
    {
        $user = auth()->user();

        $debts = DB::table('personal_debts')
            ->where('user_id', $user->id)
            ->orderBy('is_settled')
            ->orderByDesc('created_at')
            ->get();

        // Stats
        $givenActive    = $debts->where('direction', 'given')->where('is_settled', false)->sum('amount');
        $receivedActive = $debts->where('direction', 'received')->where('is_settled', false)->sum('amount');
        $settledCount   = $debts->where('is_settled', true)->count();
        $netPosition    = $givenActive - $receivedActive; // positive = net creditor

        $given    = $debts->where('direction', 'given')->sortBy('is_settled');
        $received = $debts->where('direction', 'received')->sortBy('is_settled');

        return view('personal-debts.index', compact(
            'given', 'received',
            'givenActive', 'receivedActive',
            'netPosition', 'settledCount'
        ));
    }

    // ─── Store (standalone, no linked transaction) ────────────────────────────
    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'contact_name' => 'required|string|max:120',
            'amount'       => 'required|numeric|min:0.01',
            'direction'    => 'required|in:given,received',
            'note'         => 'nullable|string|max:500',
        ]);

        DB::table('personal_debts')->insert([
            'user_id'        => auth()->id(),
            'transaction_id' => null,
            'contact_name'   => $request->contact_name,
            'amount'         => $request->amount,
            'direction'      => $request->direction,
            'note'           => $request->note,
            'is_settled'     => false,
            'created_at'     => now(),
            'updated_at'     => now(),
        ]);

        return redirect()->route('personal-debts.index')
            ->with('success', 'Borç kaydı başarıyla oluşturuldu.');
    }
}
