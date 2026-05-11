<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\AccountResource;
use App\Jobs\SyncBankConnectionJob;
use App\Models\Bank;
use App\Models\BankConnection;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BankConnectionController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $connections = BankConnection::with(['bank', 'accounts'])
            ->where('user_id', $request->user()->id)
            ->get()
            ->map(fn ($conn) => [
                'id'           => $conn->id,
                'bank'         => [
                    'id'   => $conn->bank?->id,
                    'name' => $conn->bank?->name,
                    'slug' => $conn->bank?->slug,
                    'logo' => $conn->bank?->logo,
                ],
                'status'       => $conn->status,
                'last_sync_at' => $conn->last_sync_at?->toIso8601String(),
                'accounts'     => AccountResource::collection($conn->accounts),
            ]);

        return response()->json(['connections' => $connections]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'bank_slug'   => 'required|string|exists:banks,slug',
            'credentials' => 'required|array',
        ]);

        $bank = Bank::where('slug', $data['bank_slug'])->firstOrFail();

        $connection = BankConnection::create([
            'user_id' => $request->user()->id,
            'bank_id' => $bank->id,
            'status'  => 'pending',
        ]);

        $connection->setCredentials($data['credentials']);
        $connection->save();

        SyncBankConnectionJob::dispatchSync($connection);
        $connection->refresh()->load(['bank', 'accounts']);

        return response()->json([
            'id'           => $connection->id,
            'bank'         => ['name' => $connection->bank?->name, 'slug' => $connection->bank?->slug],
            'status'       => $connection->status,
            'last_sync_at' => $connection->last_sync_at?->toIso8601String(),
            'accounts'     => AccountResource::collection($connection->accounts),
        ], 201);
    }

    public function sync(Request $request, BankConnection $bankConnection): JsonResponse
    {
        abort_if($bankConnection->user_id !== $request->user()->id, 403);

        SyncBankConnectionJob::dispatchSync($bankConnection);
        $bankConnection->refresh()->load(['bank', 'accounts']);

        return response()->json([
            'status'       => $bankConnection->status,
            'last_sync_at' => $bankConnection->last_sync_at?->toIso8601String(),
            'accounts'     => AccountResource::collection($bankConnection->accounts),
        ]);
    }

    public function destroy(Request $request, BankConnection $bankConnection): JsonResponse
    {
        abort_if($bankConnection->user_id !== $request->user()->id, 403);
        $bankConnection->delete();

        return response()->json(['message' => 'Banka bağlantısı silindi.']);
    }
}
