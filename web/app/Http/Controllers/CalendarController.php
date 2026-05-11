<?php

namespace App\Http\Controllers;

use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\View\View;

class CalendarController extends Controller
{
    public function index(Request $request): View
    {
        $user  = $request->user();
        $month = $request->input('month', now()->format('Y-m'));

        if (! preg_match('/^\d{4}-\d{2}$/', $month)) {
            $month = now()->format('Y-m');
        }

        [$year, $mon]  = explode('-', $month);
        $year          = (int) $year;
        $mon           = (int) $mon;
        $startOfMonth  = Carbon::create($year, $mon, 1)->startOfDay();
        $endOfMonth    = $startOfMonth->copy()->endOfMonth();
        $prevMonth     = $startOfMonth->copy()->subMonth()->format('Y-m');
        $nextMonth     = $startOfMonth->copy()->addMonth()->format('Y-m');

        // Monday-first offset: Mon=0 ... Sun=6
        $firstDayOfWeek = ($startOfMonth->dayOfWeek + 6) % 7;

        $events = []; // keyed by day number

        // ── Bills (repeat monthly on due_day) ──────────────────────────────
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
                    'amount' => $b->average_amount,
                    'color'  => 'warning',
                    'icon'   => 'tabler-file-invoice',
                    'link'   => route('bills.index'),
                ];
            }
        }

        // ── Subscriptions ────────────────────────────────────────────────────
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
                    $day = $nbDate->day; // same day every month
                } elseif ($sub->billing_cycle === 'yearly') {
                    if ($nbDate->month === $mon) {
                        $day = $nbDate->day;
                    }
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
                    'color'  => 'info',
                    'icon'   => 'tabler-repeat',
                    'link'   => route('subscriptions.index'),
                ];
            }
        }

        // ── Loan payments (show on same day of month) ─────────────────────────
        $loans = DB::table('loans as l')
            ->join('bank_connections as bc', 'bc.id', '=', 'l.bank_connection_id')
            ->join('banks as b', 'b.id', '=', 'bc.bank_id')
            ->where('l.user_id', $user->id)
            ->whereNotNull('l.next_payment_date')
            ->whereNull('l.deleted_at')
            ->select('l.next_payment_date', 'l.next_payment_amount', 'l.type', 'b.name as bank_name')
            ->get();

        foreach ($loans as $loan) {
            $loanDate = Carbon::parse($loan->next_payment_date);

            // Use the payment day of month, clamped to the last valid day of the viewed month
            // (e.g. a loan due on the 31st shows on the 28th/29th in February)
            $day = min($loanDate->day, $endOfMonth->day);

            if ($day >= 1) {
                $typeLabel = match ($loan->type) {
                    'mortgage' => 'Konut Kredisi',
                    'vehicle'  => 'Araç Kredisi',
                    'personal' => 'İhtiyaç Kredisi',
                    default    => 'Kredi',
                };

                $events[$day][] = [
                    'type'   => 'loan',
                    'title'  => $loan->bank_name . ' ' . $typeLabel,
                    'amount' => $loan->next_payment_amount,
                    'color'  => 'danger',
                    'icon'   => 'tabler-building-bank',
                    'link'   => route('loans.index'),
                ];
            }
        }

        // Total outgoing for the month
        $totalMonthlyPayments = 0.0;
        foreach ($events as $dayEvents) {
            foreach ($dayEvents as $e) {
                $totalMonthlyPayments += (float) ($e['amount'] ?? 0);
            }
        }

        $eventCount = array_sum(array_map('count', $events));

        return view('calendar.index', compact(
            'events', 'month', 'startOfMonth', 'endOfMonth',
            'firstDayOfWeek', 'prevMonth', 'nextMonth',
            'totalMonthlyPayments', 'eventCount', 'year', 'mon'
        ));
    }
}
