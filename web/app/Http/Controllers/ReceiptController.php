<?php

namespace App\Http\Controllers;

use App\Models\Receipt;
use App\Services\Agents\Specialists\ReceiptOCRAgent;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\View\View;
use Throwable;

class ReceiptController extends Controller
{
    public function index(Request $request): View
    {
        $receipts = Receipt::where('user_id', $request->user()->id)
            ->orderByDesc('purchased_at')
            ->orderByDesc('created_at')
            ->get();

        return view('receipts.index', compact('receipts'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'image' => 'required|file|mimes:jpg,jpeg,png,gif,webp,pdf|max:10240',
        ]);

        $user = $request->user();
        $file = $request->file('image');

        // Save to public storage
        $path = $file->store("receipts/{$user->id}", 'public');
        $fullPath = Storage::disk('public')->path($path);

        // Create receipt record immediately with just the image
        $receipt = Receipt::create([
            'user_id'    => $user->id,
            'image_path' => $path,
        ]);

        // Run OCR agent
        try {
            $agent  = new ReceiptOCRAgent($user);
            $result = $agent->run([
                'image_path' => $fullPath,
                'mime_type'  => $file->getMimeType(),
            ]);

            $receipt->update([
                'ocr_raw_text'  => $result['raw_text'] ?? null,
                'ocr_extracted' => $result,
                'merchant_name' => $result['merchant_name'] ?? null,
                'total_amount'  => $result['total_amount'] ?? null,
                'vat_amount'    => $result['vat_amount'] ?? null,
                'items'         => $result['items'] ?? null,
                'purchased_at'  => $this->parseDate($result['purchased_at'] ?? null),
                'warranty_until'=> $this->parseDate($result['warranty_until'] ?? null),
            ]);

            if ($request->wantsJson()) {
                return response()->json(['success' => true, 'receipt' => $receipt->fresh()]);
            }

            return redirect()->route('receipts.index')
                ->with('success', "Fiş analiz edildi: {$receipt->merchant_name} — ₺" . number_format((float)$receipt->total_amount, 2, ',', '.'));

        } catch (Throwable $e) {
            // OCR failed but receipt record exists — still redirect with partial data
            if ($request->wantsJson()) {
                return response()->json(['success' => false, 'error' => $e->getMessage(), 'receipt' => $receipt], 422);
            }

            return redirect()->route('receipts.index')
                ->with('error', 'Fiş yüklendi fakat OCR analizi başarısız: ' . $e->getMessage());
        }
    }

    public function destroy(Request $request, Receipt $receipt)
    {
        abort_unless($receipt->user_id === $request->user()->id, 403);

        Storage::disk('public')->delete($receipt->image_path);
        $receipt->delete();

        if ($request->wantsJson()) {
            return response()->json(['success' => true]);
        }

        return redirect()->route('receipts.index')->with('success', 'Fiş silindi.');
    }

    private function parseDate(?string $raw): ?string
    {
        if ($raw === null || $raw === '' || strtolower($raw) === 'null') {
            return null;
        }
        try {
            return \Carbon\Carbon::parse($raw)->toDateString();
        } catch (\Throwable) {
            return null;
        }
    }
}
