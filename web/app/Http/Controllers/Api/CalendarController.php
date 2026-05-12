<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CalendarController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user  = $request->user();
        $month = $request->input('month', now()->format('Y-m'));

        if (! preg_match('/^\d{4}-\d{2}$/', $month)) {
            $month = now()->format('Y-m');
        }

        [$year, $mon] = explode('-', $month);
        $startOfMonth = Carbon::create((int) $year, (int) $mon, 1)->startOfDay();
        $endOfMonth   = $startOfMonth->copy()->endOfMonth();

        $events = [];

        // Bills
        $bills = DB::table('bills')
            ->where('user_id', $user->id)
            ->whereNotNull('due_day')
            ->whereNull('deleted_at')
            ->get();

        foreach ($bills as $b) {
            $day = (int) $b->due_day;
            if ($day >= 1 && $day <= $endOfMonth->day) {
                $events[$day][] = [
                    'type'   => 'bill',
                    'title'  => $b->name,
                    'amount' => (float) $b->average_amount,
                ];
            }
        }

        // Subscriptions
        $subs = DB::table('subscriptions')
            ->where('user_id', $user->id)
            ->where('status', 'active')
            ->whereNull('deleted_at')
            ->get();

        foreach ($subs as $sub) {
            $day = null;
            if ($sub->next_billing_date) {
                $nbDate = Carbon::parse($sub->next_billing_date);
                if ($sub->billing_cycle === 'monthly') {
                    $day = $nbDate->day;
                } elseif ($sub->billing_cycle === 'yearly') {
                    if ($nbDate->month === (int) $mon) $day = $nbDate->day;
                } elseif ($nbDate->format('Y-m') === $month) {
                    $day = $nbDate->day;
                }
            }

            if ($day && $day >= 1 && $day <= $endOfMonth->day) {
                $monthlyAmt = match ($sub->billing_cycle) {
                    'yearly' => (float) $sub->amount / 12,
                    'weekly' => (float) $sub->amount * 4.33,
                    default  => (float) $sub->amount,
                };
                $events[$day][] = [
                    'type'   => 'subscription',
                    'title'  => $sub->name,
                    'amount' => $monthlyAmt,
                ];
            }
        }

        // Loan payments
        $loans = DB::table('loans as l')
            ->join('bank_connections as bc', 'bc.id', '=', 'l.bank_connection_id')
            ->join('banks as b', 'b.id', '=', 'bc.bank_id')
            ->where('l.user_id', $user->id)
            ->whereNotNull('l.next_payment_date')
            ->whereNull('l.deleted_at')
            ->select('l.next_payment_date', 'l.next_payment_amount', 'l.type', 'b.name as bank_name')
            ->get();

        foreach ($loans as $loan) {
            $day = min(Carbon::parse($loan->next_payment_date)->day, $endOfMonth->day);
            $events[$day][] = [
                'type'   => 'loan',
                'title'  => $loan->bank_name . ' ' . match ($loan->type) {
                    'mortgage' => 'Konut Kredisi',
                    'vehicle'  => 'Araç Kredisi',
                    'personal' => 'İhtiyaç Kredisi',
                    default    => 'Kredi',
                },
                'amount' => (float) $loan->next_payment_amount,
            ];
        }

        ksort($events);

        $totalPayments = 0.0;
        foreach ($events as $dayEvents) {
            foreach ($dayEvents as $e) {
                $totalPayments += $e['amount'];
            }
        }

        return response()->json([
            'month'          => $month,
            'events'         => $events,
            'total_payments' => round($totalPayments, 2),
            'event_count'    => array_sum(array_map('count', $events)),
        ]);
    }
}
