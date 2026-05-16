<?php

namespace App\Http\Controllers;

use App\Services\DebtDetectionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class PersonalDebtController extends Controller
{
    public function index(): View
    {
        $user = auth()->user();

        $debts = DB::table('personal_debts')
            ->where('user_id', $user->id)
            ->orderBy('is_settled')
            ->orderByDesc('created_at')
            ->get();

        $givenActive    = $debts->where('direction', 'given')->where('is_settled', false)->sum('amount');
        $receivedActive = $debts->where('direction', 'received')->where('is_settled', false)->sum('amount');
        $settledCount   = $debts->where('is_settled', true)->count();
        $netPosition    = $givenActive - $receivedActive;

        return view('personal-debts.index', compact(
            'debts', 'givenActive', 'receivedActive', 'netPosition', 'settledCount'
        ));
    }

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

    public function autoDetect(): JsonResponse
    {
        $service = new DebtDetectionService();
        $userId  = auth()->id();

        return response()->json([
            'debt_suggestions'      => $service->detectUnconfirmedDebts($userId),
            'repayment_suggestions' => $service->findRepaymentCandidates($userId),
        ]);
    }

    public function confirmDetected(Request $request): JsonResponse
    {
        $data = $request->validate([
            'contact_name'   => 'required|string|max:120',
            'amount'         => 'required|numeric|min:0.01',
            'direction'      => 'required|in:given,received',
            'note'           => 'nullable|string|max:500',
            'transaction_id' => 'nullable|string',
        ]);

        DB::table('personal_debts')->insert([
            'user_id'          => auth()->id(),
            'transaction_id'   => $data['transaction_id'] ?? null,
            'contact_name'     => $data['contact_name'],
            'amount'           => $data['amount'],
            'direction'        => $data['direction'],
            'note'             => $data['note'] ?? null,
            'is_auto_detected' => true,
            'is_settled'       => false,
            'created_at'       => now(),
            'updated_at'       => now(),
        ]);

        return response()->json(['message' => 'Borç kaydı oluşturuldu.'], 201);
    }

    public function markRepayment(Request $request, int $id): JsonResponse
    {
        $data = $request->validate([
            'transaction_id'   => 'required|string',
            'repayment_amount' => 'required|numeric|min:0.01',
        ]);

        $debt = DB::table('personal_debts')
            ->where('id', $id)
            ->where('user_id', auth()->id())
            ->first();

        if (! $debt) {
            return response()->json(['message' => 'Borç bulunamadı.'], 404);
        }

        $profit = round(max(0.0, (float) $data['repayment_amount'] - (float) $debt->amount), 2);

        DB::table('personal_debts')
            ->where('id', $id)
            ->update([
                'is_settled'               => true,
                'settled_at'               => now(),
                'repayment_transaction_id' => $data['transaction_id'],
                'profit_amount'            => $profit,
                'updated_at'               => now(),
            ]);

        return response()->json(['message' => 'Borç kapatıldı.', 'profit' => $profit]);
    }
}
