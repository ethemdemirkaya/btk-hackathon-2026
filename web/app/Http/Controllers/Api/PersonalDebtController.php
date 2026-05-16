<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\DebtDetectionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PersonalDebtController extends Controller
{
    // ── Yardımcı: DB kaydını mobil formata dönüştür ───────────────────────
    // Mobil: type (borrowed/lent), counterparty_name, description
    // DB:    direction (received/given), contact_name, note

    private function toMobile(object $row): array
    {
        $data = (array) $row;
        $data['type']              = $row->direction === 'received' ? 'borrowed' : 'lent';
        $data['counterparty_name'] = $row->contact_name;
        $data['description']       = $row->note;
        $data['due_date']          = null;
        return $data;
    }

    // ── Listele ───────────────────────────────────────────────────────────

    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()->id;

        $debts = DB::table('personal_debts')
            ->where('user_id', $userId)
            ->orderBy('is_settled')
            ->orderByDesc('created_at')
            ->get();

        // i_owe = aldığım borç (received) aktif | owed_to_me = verdiğim borç (given) aktif
        $iOwe     = (float) $debts->where('direction', 'received')->where('is_settled', false)->sum('amount');
        $owedToMe = (float) $debts->where('direction', 'given')->where('is_settled', false)->sum('amount');

        return response()->json([
            'debts'   => $debts->map(fn ($d) => $this->toMobile($d))->values(),
            'summary' => [
                'i_owe'         => $iOwe,
                'owed_to_me'    => $owedToMe,
                'net_position'  => $owedToMe - $iOwe,
                'settled_count' => $debts->where('is_settled', true)->count(),
            ],
        ]);
    }

    // ── Oluştur ───────────────────────────────────────────────────────────

    public function store(Request $request): JsonResponse
    {
        // Mobil hem eski (contact_name/direction) hem yeni (counterparty_name/type) formatı gönderebilir
        $raw = $request->validate([
            'contact_name'      => 'sometimes|string|max:120',
            'counterparty_name' => 'sometimes|string|max:120',
            'amount'            => 'required|numeric|min:0.01',
            'direction'         => 'sometimes|in:given,received',
            'type'              => 'sometimes|in:borrowed,lent',
            'note'              => 'nullable|string|max:500',
            'description'       => 'nullable|string|max:500',
        ]);

        $contactName = $raw['contact_name'] ?? $raw['counterparty_name'] ?? null;
        if (! $contactName) {
            return response()->json(['message' => 'Kişi adı zorunludur.'], 422);
        }

        $direction = $raw['direction'] ?? match ($raw['type'] ?? '') {
            'borrowed' => 'received',
            'lent'     => 'given',
            default    => null,
        };
        if (! $direction) {
            return response()->json(['message' => 'Yön (direction/type) zorunludur.'], 422);
        }

        $id = DB::table('personal_debts')->insertGetId([
            'user_id'          => $request->user()->id,
            'transaction_id'   => null,
            'contact_name'     => $contactName,
            'amount'           => $raw['amount'],
            'direction'        => $direction,
            'note'             => $raw['note'] ?? $raw['description'] ?? null,
            'is_auto_detected' => false,
            'is_settled'       => false,
            'created_at'       => now(),
            'updated_at'       => now(),
        ]);

        return response()->json(['debt' => $this->toMobile(DB::table('personal_debts')->where('id', $id)->first())], 201);
    }

    // ── Güncelle ──────────────────────────────────────────────────────────

    public function update(Request $request, int $id): JsonResponse
    {
        $raw = $request->validate([
            'contact_name'      => 'sometimes|string|max:120',
            'counterparty_name' => 'sometimes|string|max:120',
            'amount'            => 'sometimes|numeric|min:0.01',
            'direction'         => 'sometimes|in:given,received',
            'type'              => 'sometimes|in:borrowed,lent',
            'note'              => 'nullable|string|max:500',
            'description'       => 'nullable|string|max:500',
        ]);

        $fields = [];
        if ($name = $raw['contact_name'] ?? $raw['counterparty_name'] ?? null) {
            $fields['contact_name'] = $name;
        }
        if (isset($raw['amount'])) {
            $fields['amount'] = $raw['amount'];
        }
        if ($dir = $raw['direction'] ?? match ($raw['type'] ?? '') {
            'borrowed' => 'received', 'lent' => 'given', default => null,
        }) {
            $fields['direction'] = $dir;
        }
        if (array_key_exists('note', $raw) || array_key_exists('description', $raw)) {
            $fields['note'] = $raw['note'] ?? $raw['description'] ?? null;
        }

        if (empty($fields)) {
            return response()->json(['message' => 'Güncellenecek alan yok.'], 422);
        }

        $fields['updated_at'] = now();

        $affected = DB::table('personal_debts')
            ->where('id', $id)
            ->where('user_id', $request->user()->id)
            ->update($fields);

        if (! $affected) {
            return response()->json(['message' => 'Borç bulunamadı.'], 404);
        }

        return response()->json(['debt' => $this->toMobile(DB::table('personal_debts')->where('id', $id)->first())]);
    }

    // ── Kapat ─────────────────────────────────────────────────────────────

    public function settle(Request $request, int $id): JsonResponse
    {
        $affected = DB::table('personal_debts')
            ->where('id', $id)
            ->where('user_id', $request->user()->id)
            ->update(['is_settled' => true, 'settled_at' => now(), 'updated_at' => now()]);

        if (! $affected) {
            return response()->json(['message' => 'Borç bulunamadı.'], 404);
        }

        return response()->json(['message' => 'Borç kapatıldı.']);
    }

    // ── Sil ───────────────────────────────────────────────────────────────

    public function destroy(Request $request, int $id): JsonResponse
    {
        $affected = DB::table('personal_debts')
            ->where('id', $id)
            ->where('user_id', $request->user()->id)
            ->delete();

        if (! $affected) {
            return response()->json(['message' => 'Borç bulunamadı.'], 404);
        }

        return response()->json(['message' => 'Borç silindi.']);
    }

    // ── AI Otomatik Tespit ────────────────────────────────────────────────

    /**
     * Son 90 günün işlemlerini tarar; açıklamasında borç anahtar kelimesi geçen
     * ve henüz kayıt altına alınmamış işlemler ile mevcut borçların geri ödeme
     * adaylarını döner.
     */
    public function autoDetect(Request $request): JsonResponse
    {
        $service = new DebtDetectionService();
        $userId  = $request->user()->id;

        return response()->json([
            'debt_suggestions'      => $service->detectUnconfirmedDebts($userId),
            'repayment_suggestions' => $service->findRepaymentCandidates($userId),
        ]);
    }

    /**
     * Kullanıcı tespit edilen bir işlemi borç olarak onaylar.
     */
    public function confirmDetected(Request $request): JsonResponse
    {
        $data = $request->validate([
            'contact_name'   => 'required|string|max:120',
            'amount'         => 'required|numeric|min:0.01',
            'direction'      => 'required|in:given,received',
            'note'           => 'nullable|string|max:500',
            'transaction_id' => 'nullable|string',
        ]);

        $id = DB::table('personal_debts')->insertGetId([
            'user_id'          => $request->user()->id,
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

        return response()->json(['debt' => $this->toMobile(DB::table('personal_debts')->where('id', $id)->first())], 201);
    }

    /**
     * Kullanıcı bir işlemin mevcut bir borcun geri ödemesi olduğunu onaylar.
     * Borcu kapatır ve elde edilen karı hesaplar.
     */
    public function markRepayment(Request $request, int $id): JsonResponse
    {
        $data = $request->validate([
            'transaction_id'   => 'required|string',
            'repayment_amount' => 'required|numeric|min:0.01',
        ]);

        $debt = DB::table('personal_debts')
            ->where('id', $id)
            ->where('user_id', $request->user()->id)
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

        $message = $profit > 0
            ? number_format($profit, 2, ',', '.') . ' TL kar ile borç kapatıldı.'
            : 'Borç kapatıldı.';

        return response()->json([
            'debt'    => $this->toMobile(DB::table('personal_debts')->where('id', $id)->first()),
            'profit'  => $profit,
            'message' => $message,
        ]);
    }
}
