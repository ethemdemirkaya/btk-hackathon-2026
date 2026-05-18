<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $flat = filter_var($request->query('flat', false), FILTER_VALIDATE_BOOLEAN);

        $query = Category::select('id', 'name', 'slug', 'icon', 'color', 'parent_id')
            ->orderBy('name');

        if (!$flat) {
            $query->whereNull('parent_id');
        }

        $categories = $query->get();

        return response()->json(['categories' => $categories]);
    }
}
