<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            // Ana kategori → TÜİK slug mapping
            ['name' => 'Yiyecek & İçecek', 'slug' => 'yiyecek-iceeck', 'icon' => 'tabler-tools-kitchen-2', 'color' => '#FF6B35', 'is_essential' => true, 'tuik_category_slug' => 'gida', 'parent_slug' => null],
            ['name' => 'Market', 'slug' => 'market', 'icon' => 'tabler-shopping-cart', 'color' => '#FF6B35', 'is_essential' => true, 'tuik_category_slug' => 'gida', 'parent_slug' => 'yiyecek-iceeck'],
            ['name' => 'Restoran & Kafe', 'slug' => 'restoran-kafe', 'icon' => 'tabler-knife', 'color' => '#FF6B35', 'is_essential' => false, 'tuik_category_slug' => 'lokanta', 'parent_slug' => 'yiyecek-iceeck'],
            ['name' => 'Online Yemek', 'slug' => 'online-yemek', 'icon' => 'tabler-motorbike', 'color' => '#FF6B35', 'is_essential' => false, 'tuik_category_slug' => 'lokanta', 'parent_slug' => 'yiyecek-iceeck'],

            ['name' => 'Ulaşım', 'slug' => 'ulasim', 'icon' => 'tabler-car', 'color' => '#4ECDC4', 'is_essential' => true, 'tuik_category_slug' => 'ulastirma', 'parent_slug' => null],
            ['name' => 'Yakıt', 'slug' => 'yakit', 'icon' => 'tabler-gas-station', 'color' => '#4ECDC4', 'is_essential' => true, 'tuik_category_slug' => 'ulastirma', 'parent_slug' => 'ulasim'],
            ['name' => 'Toplu Taşıma', 'slug' => 'toplu-tasima', 'icon' => 'tabler-bus', 'color' => '#4ECDC4', 'is_essential' => true, 'tuik_category_slug' => 'ulastirma', 'parent_slug' => 'ulasim'],
            ['name' => 'Taksi & Servis', 'slug' => 'taksi-servis', 'icon' => 'tabler-taxi', 'color' => '#4ECDC4', 'is_essential' => false, 'tuik_category_slug' => 'ulastirma', 'parent_slug' => 'ulasim'],

            ['name' => 'Faturalar', 'slug' => 'faturalar', 'icon' => 'tabler-file-invoice', 'color' => '#45B7D1', 'is_essential' => true, 'tuik_category_slug' => 'konut', 'parent_slug' => null],
            ['name' => 'Elektrik', 'slug' => 'elektrik', 'icon' => 'tabler-bolt', 'color' => '#F7DC6F', 'is_essential' => true, 'tuik_category_slug' => 'konut', 'parent_slug' => 'faturalar'],
            ['name' => 'Su', 'slug' => 'su', 'icon' => 'tabler-droplet', 'color' => '#45B7D1', 'is_essential' => true, 'tuik_category_slug' => 'konut', 'parent_slug' => 'faturalar'],
            ['name' => 'Doğalgaz', 'slug' => 'dogalgaz', 'icon' => 'tabler-flame', 'color' => '#F39C12', 'is_essential' => true, 'tuik_category_slug' => 'konut', 'parent_slug' => 'faturalar'],
            ['name' => 'İnternet', 'slug' => 'internet', 'icon' => 'tabler-wifi', 'color' => '#8E44AD', 'is_essential' => true, 'tuik_category_slug' => 'haberlesme', 'parent_slug' => 'faturalar'],
            ['name' => 'Telefon', 'slug' => 'telefon', 'icon' => 'tabler-phone', 'color' => '#8E44AD', 'is_essential' => true, 'tuik_category_slug' => 'haberlesme', 'parent_slug' => 'faturalar'],

            ['name' => 'Sağlık', 'slug' => 'saglik', 'icon' => 'tabler-heart-rate-monitor', 'color' => '#E74C3C', 'is_essential' => true, 'tuik_category_slug' => 'saglik', 'parent_slug' => null],
            ['name' => 'Eczane', 'slug' => 'eczane', 'icon' => 'tabler-pill', 'color' => '#E74C3C', 'is_essential' => true, 'tuik_category_slug' => 'saglik', 'parent_slug' => 'saglik'],
            ['name' => 'Doktor & Hastane', 'slug' => 'doktor-hastane', 'icon' => 'tabler-stethoscope', 'color' => '#E74C3C', 'is_essential' => true, 'tuik_category_slug' => 'saglik', 'parent_slug' => 'saglik'],

            ['name' => 'Eğitim', 'slug' => 'egitim', 'icon' => 'tabler-school', 'color' => '#2980B9', 'is_essential' => true, 'tuik_category_slug' => 'egitim', 'parent_slug' => null],
            ['name' => 'Kurs & Eğitim', 'slug' => 'kurs-egitim', 'icon' => 'tabler-certificate', 'color' => '#2980B9', 'is_essential' => false, 'tuik_category_slug' => 'egitim', 'parent_slug' => 'egitim'],
            ['name' => 'Kitap & Kırtasiye', 'slug' => 'kitap-kirtasiye', 'icon' => 'tabler-book', 'color' => '#2980B9', 'is_essential' => false, 'tuik_category_slug' => 'egitim', 'parent_slug' => 'egitim'],

            ['name' => 'Eğlence', 'slug' => 'eglence', 'icon' => 'tabler-confetti', 'color' => '#9B59B6', 'is_essential' => false, 'tuik_category_slug' => 'eglence', 'parent_slug' => null],
            ['name' => 'Sinema & Tiyatro', 'slug' => 'sinema-tiyatro', 'icon' => 'tabler-movie', 'color' => '#9B59B6', 'is_essential' => false, 'tuik_category_slug' => 'eglence', 'parent_slug' => 'eglence'],
            ['name' => 'Spor', 'slug' => 'spor', 'icon' => 'tabler-ball-football', 'color' => '#27AE60', 'is_essential' => false, 'tuik_category_slug' => 'eglence', 'parent_slug' => 'eglence'],
            ['name' => 'Dijital Abonelik', 'slug' => 'dijital-abonelik', 'icon' => 'tabler-device-tv', 'color' => '#9B59B6', 'is_essential' => false, 'tuik_category_slug' => 'eglence', 'parent_slug' => 'eglence'],

            ['name' => 'Giyim & Aksesuar', 'slug' => 'giyim-aksesuar', 'icon' => 'tabler-shirt', 'color' => '#E91E63', 'is_essential' => false, 'tuik_category_slug' => 'giyim', 'parent_slug' => null],
            ['name' => 'Kıyafet', 'slug' => 'kiyafet', 'icon' => 'tabler-hanger', 'color' => '#E91E63', 'is_essential' => false, 'tuik_category_slug' => 'giyim', 'parent_slug' => 'giyim-aksesuar'],
            ['name' => 'Ayakkabı', 'slug' => 'ayakkabi', 'icon' => 'tabler-shoe', 'color' => '#E91E63', 'is_essential' => false, 'tuik_category_slug' => 'giyim', 'parent_slug' => 'giyim-aksesuar'],

            ['name' => 'Ev & Yaşam', 'slug' => 'ev-yasam', 'icon' => 'tabler-home', 'color' => '#795548', 'is_essential' => false, 'tuik_category_slug' => 'mobilya', 'parent_slug' => null],
            ['name' => 'Mobilya', 'slug' => 'mobilya', 'icon' => 'tabler-sofa', 'color' => '#795548', 'is_essential' => false, 'tuik_category_slug' => 'mobilya', 'parent_slug' => 'ev-yasam'],
            ['name' => 'Beyaz Eşya', 'slug' => 'beyaz-esya', 'icon' => 'tabler-washing-machine', 'color' => '#795548', 'is_essential' => false, 'tuik_category_slug' => 'mobilya', 'parent_slug' => 'ev-yasam'],
            ['name' => 'Elektronik', 'slug' => 'elektronik', 'icon' => 'tabler-device-laptop', 'color' => '#607D8B', 'is_essential' => false, 'tuik_category_slug' => 'mobilya', 'parent_slug' => 'ev-yasam'],

            ['name' => 'Alkol & Sigara', 'slug' => 'alkol-sigara', 'icon' => 'tabler-bottle', 'color' => '#FF5722', 'is_essential' => false, 'tuik_category_slug' => 'alkol', 'parent_slug' => null],

            ['name' => 'Banka & Finans', 'slug' => 'banka-finans', 'icon' => 'tabler-building-bank', 'color' => '#00BCD4', 'is_essential' => false, 'tuik_category_slug' => 'finans', 'parent_slug' => null],
            ['name' => 'Banka Ücreti', 'slug' => 'banka-ucreti', 'icon' => 'tabler-credit-card', 'color' => '#00BCD4', 'is_essential' => false, 'tuik_category_slug' => 'finans', 'parent_slug' => 'banka-finans'],
            ['name' => 'Faiz & Komisyon', 'slug' => 'faiz-komisyon', 'icon' => 'tabler-percent', 'color' => '#00BCD4', 'is_essential' => false, 'tuik_category_slug' => 'finans', 'parent_slug' => 'banka-finans'],
            ['name' => 'Sigorta', 'slug' => 'sigorta', 'icon' => 'tabler-shield', 'color' => '#00BCD4', 'is_essential' => true, 'tuik_category_slug' => 'finans', 'parent_slug' => 'banka-finans'],

            ['name' => 'Diğer', 'slug' => 'diger', 'icon' => 'tabler-dots', 'color' => '#9E9E9E', 'is_essential' => false, 'tuik_category_slug' => 'diger', 'parent_slug' => null],
        ];

        // Slug → ID mapping için
        $slugToId = [];

        foreach ($categories as $cat) {
            $parentId = $cat['parent_slug'] ? ($slugToId[$cat['parent_slug']] ?? null) : null;

            $existing = DB::table('categories')->where('slug', $cat['slug'])->first();
            if ($existing) {
                $slugToId[$cat['slug']] = $existing->id;
                continue;
            }

            $id = DB::table('categories')->insertGetId([
                'parent_id'          => $parentId,
                'name'               => $cat['name'],
                'slug'               => $cat['slug'],
                'icon'               => $cat['icon'],
                'color'              => $cat['color'],
                'is_essential'       => $cat['is_essential'],
                'tuik_category_slug' => $cat['tuik_category_slug'],
                'created_at'         => now(),
                'updated_at'         => now(),
            ]);

            $slugToId[$cat['slug']] = $id;
        }
    }
}
