<?php

namespace App\Http\Controllers;

use App\Jobs\SyncBankConnectionJob;
use App\Models\Bank;
use App\Models\BankConnection;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\View\View;
use Throwable;

class BankConnectionController extends Controller
{
    public function index(Request $request): View
    {
        $connections = BankConnection::with(['bank', 'accounts'])
            ->where('user_id', $request->user()->id)
            ->orderByDesc('created_at')
            ->get();

        $banks = Bank::where('is_active', true)->get();

        return view('bank-connections.index', compact('connections', 'banks'));
    }

    public function create(): View
    {
        $banks = Bank::where('is_active', true)->get();
        return view('bank-connections.create', compact('banks'));
    }

    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'bank_id'     => 'required|exists:banks,id',
            'credentials' => 'required|array',
        ]);

        $bank = Bank::findOrFail($request->bank_id);

        $credentials = $this->mapCredentials($bank->slug, $request->input('credentials'));

        $connection = BankConnection::create([
            'user_id' => $request->user()->id,
            'bank_id' => $bank->id,
            'status'  => 'active',
        ]);
        $connection->setCredentials($credentials);
        $connection->save();

        try {
            (new SyncBankConnectionJob($connection))->handle();
            $msg = "{$bank->name} bağlandı ve veriler senkronize edildi.";
        } catch (Throwable $e) {
            $msg = "{$bank->name} bağlandı. Senkronizasyon sırasında hata: " . $e->getMessage();
        }

        return redirect()->route('bank-connections.index')->with('success', $msg);
    }

    public function destroy(Request $request, BankConnection $bankConnection): RedirectResponse
    {
        abort_unless($bankConnection->user_id === $request->user()->id, 403);

        $bankName = $bankConnection->bank->name;
        $bankConnection->delete();

        return redirect()->route('bank-connections.index')
            ->with('success', "{$bankName} bağlantısı kaldırıldı.");
    }

    public function sync(Request $request, BankConnection $bankConnection): RedirectResponse
    {
        abort_unless($bankConnection->user_id === $request->user()->id, 403);

        try {
            (new SyncBankConnectionJob($bankConnection))->handle();
            return redirect()->route('bank-connections.index')
                ->with('success', "{$bankConnection->bank->name} başarıyla senkronize edildi.");
        } catch (Throwable $e) {
            return redirect()->route('bank-connections.index')
                ->with('error', "Senkronizasyon hatası: " . $e->getMessage());
        }
    }

    // ──────────────────────────────────────────────────────────────────────

    private function mapCredentials(string $slug, array $raw): array
    {
        return match ($slug) {
            'ziraat'  => ['tckn'          => $raw['tckn'],          'password'      => $raw['password']],
            'garanti' => ['client_id'     => $raw['client_id'],     'client_secret' => $raw['client_secret']],
            'isbank'  => ['tckn'          => $raw['tckn'],          'hmac_secret'   => $raw['hmac_secret']],
            'akbank'  => ['api_key'       => $raw['api_key']],
            default   => $raw,
        };
    }
}
