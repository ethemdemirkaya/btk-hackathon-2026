<?php

namespace App\View\Components;

use Closure;
use Illuminate\Contracts\View\View;
use Illuminate\View\Component;

class AiInsightPanel extends Component
{
    /**
     * Create a new component instance.
     *
     * @param  string  $page      The page slug sent to /api/v1/agent/page-analyze
     * @param  bool    $autoload  Whether to auto-fetch on page load (default: false)
     * @param  string  $title     Panel header title text
     */
    public function __construct(
        public string $page,
        public bool   $autoload = false,
        public string $title    = 'Paranette AI',
    ) {}

    public function render(): View|Closure|string
    {
        return view('components.ai-insight-panel');
    }
}
