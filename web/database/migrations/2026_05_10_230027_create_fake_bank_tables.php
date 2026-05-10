<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Fake bank müşterileri (4 banka: ziraat, garanti, isbank, akbank)
        Schema::create('fake_bank_customers', function (Blueprint $table) {
            $table->id();
            $table->string('bank_slug', 20); // ziraat, garanti, isbank, akbank
            $table->string('customer_id', 20)->unique();
            $table->string('tckn', 11);
            $table->string('name');
            $table->string('email')->nullable();
            $table->string('password_hash');
            $table->json('api_credentials')->nullable(); // token, secret vs.
            $table->timestamps();

            $table->index(['bank_slug', 'tckn']);
        });

        Schema::create('fake_bank_accounts', function (Blueprint $table) {
            $table->id();
            $table->string('bank_slug', 20);
            $table->foreignId('fake_customer_id')->constrained('fake_bank_customers')->cascadeOnDelete();
            $table->string('external_id', 30);
            $table->string('account_type'); // checking, savings
            $table->string('iban', 34);
            $table->string('currency', 3)->default('TRY');
            $table->decimal('balance', 15, 2)->default(0);
            $table->decimal('available_balance', 15, 2)->default(0);
            $table->date('opened_at');
            $table->timestamps();

            $table->unique(['bank_slug', 'external_id']);
        });

        Schema::create('fake_bank_cards', function (Blueprint $table) {
            $table->id();
            $table->string('bank_slug', 20);
            $table->foreignId('fake_customer_id')->constrained('fake_bank_customers')->cascadeOnDelete();
            $table->foreignId('fake_account_id')->nullable()->constrained('fake_bank_accounts')->nullOnDelete();
            $table->string('type'); // credit, debit
            $table->string('masked_number', 19);
            $table->string('full_number_encrypted')->nullable();
            $table->string('expiry', 7); // MM/YYYY
            $table->string('holder_name');
            $table->decimal('credit_limit', 15, 2)->nullable();
            $table->decimal('current_debt', 15, 2)->default(0);
            $table->unsignedTinyInteger('statement_day')->nullable();
            $table->unsignedTinyInteger('due_day')->nullable();
            $table->timestamps();
        });

        Schema::create('fake_bank_transactions', function (Blueprint $table) {
            $table->id();
            $table->string('bank_slug', 20);
            $table->foreignId('fake_account_id')->nullable()->constrained('fake_bank_accounts')->cascadeOnDelete();
            $table->foreignId('fake_card_id')->nullable()->constrained('fake_bank_cards')->nullOnDelete();
            $table->string('external_id', 40)->unique();
            $table->timestamp('posted_at');
            $table->decimal('amount', 15, 2);
            $table->string('currency', 3)->default('TRY');
            $table->string('description');
            $table->string('merchant_name')->nullable();
            $table->string('channel')->nullable(); // pos, atm, online, transfer
            $table->unsignedTinyInteger('installment_no')->nullable();
            $table->unsignedTinyInteger('installment_total')->nullable();
            $table->timestamps();

            $table->index(['fake_account_id', 'posted_at']);
            $table->index(['fake_card_id', 'posted_at']);
        });

        Schema::create('fake_bank_loans', function (Blueprint $table) {
            $table->id();
            $table->string('bank_slug', 20);
            $table->foreignId('fake_customer_id')->constrained('fake_bank_customers')->cascadeOnDelete();
            $table->string('external_id', 30);
            $table->string('type'); // personal, mortgage, vehicle
            $table->decimal('principal', 15, 2);
            $table->decimal('current_balance', 15, 2);
            $table->decimal('interest_rate', 8, 4);
            $table->unsignedSmallInteger('total_installments');
            $table->unsignedSmallInteger('paid_installments')->default(0);
            $table->date('next_payment_date')->nullable();
            $table->decimal('next_payment_amount', 15, 2)->nullable();
            $table->timestamps();

            $table->unique(['bank_slug', 'external_id']);
        });

        // OAuth token'ları (Garanti bankas için)
        Schema::create('fake_bank_oauth_tokens', function (Blueprint $table) {
            $table->id();
            $table->string('bank_slug', 20);
            $table->string('access_token', 128)->unique();
            $table->string('refresh_token', 128)->nullable();
            $table->foreignId('fake_customer_id')->constrained('fake_bank_customers')->cascadeOnDelete();
            $table->json('scopes')->nullable();
            $table->timestamp('expires_at');
            $table->timestamps();

            $table->index(['bank_slug', 'access_token']);
        });

        // Webhook log tablosu
        Schema::create('fake_bank_webhook_logs', function (Blueprint $table) {
            $table->id();
            $table->string('bank_slug', 20);
            $table->string('callback_url');
            $table->string('event_type');
            $table->json('payload');
            $table->string('status')->default('pending'); // pending, delivered, failed
            $table->unsignedTinyInteger('attempts')->default(0);
            $table->timestamp('last_attempt_at')->nullable();
            $table->timestamps();

            $table->index(['bank_slug', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('fake_bank_webhook_logs');
        Schema::dropIfExists('fake_bank_oauth_tokens');
        Schema::dropIfExists('fake_bank_loans');
        Schema::dropIfExists('fake_bank_transactions');
        Schema::dropIfExists('fake_bank_cards');
        Schema::dropIfExists('fake_bank_accounts');
        Schema::dropIfExists('fake_bank_customers');
    }
};
