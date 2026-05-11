<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Receipt;
use App\Services\ReceiptOCRAgent;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReceiptController extends Controller
{
    public function __construct(private readonly ReceiptOCRAgent $ocrAgent) {}

    public function index(Request $request): JsonResponse
    {
        $receipts = Receipt::where('user_id', $request->user()->id)
            ->orderByDesc('purchased_at')
            ->limit(50)
            ->get()
            ->map(fn ($r) => [
                'id'            => $r->id,
                'merchant_name' => $r->merchant_name,
                'total_amount'  => (float) $r->total_amount,
                'currency'      => $r->currency,
                'purchased_at'  => $r->purchased_at?->toIso8601String(),
                'category'      => $r->category,
                'items_count'   => is_array($r->items) ? count($r->items) : 0,
            ]);

        return response()->json(['receipts' => $receipts]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'image' => 'required|image|max:10240',
        ]);

        $path = $request->file('image')->store('receipts', 'local');

        try {
            $result  = $this->ocrAgent->processFromPath(storage_path('app/' . $path));
            $receipt = Receipt::create([
                'user_id'       => $request->user()->id,
                'image_path'    => $path,
                'merchant_name' => $result['merchant_name'] ?? null,
                'total_amount'  => $result['total_amount'] ?? 0,
                'currency'      => $result['currency'] ?? 'TRY',
                'purchased_at'  => $result['date'] ?? now(),
                'category'      => $result['category'] ?? null,
                'items'         => $result['items'] ?? [],
                'raw_ocr'       => $result['raw'] ?? null,
            ]);

            return response()->json([
                'receipt' => [
                    'id'            => $receipt->id,
                    'merchant_name' => $receipt->merchant_name,
                    'total_amount'  => (float) $receipt->total_amount,
                    'currency'      => $receipt->currency,
                    'purchased_at'  => $receipt->purchased_at?->toIso8601String(),
                    'category'      => $receipt->category,
                    'items'         => $receipt->items,
                ],
            ], 201);
        } catch (\Throwable $e) {
            return response()->json([
                'error'   => 'OCR işlemi başarısız.',
                'details' => config('app.debug') ? $e->getMessage() : null,
            ], 500);
        }
    }

    public function destroy(Request $request, Receipt $receipt): JsonResponse
    {
        abort_if($receipt->user_id !== $request->user()->id, 403);
        $receipt->delete();

        return response()->json(['message' => 'Fiş silindi.']);
    }
}
