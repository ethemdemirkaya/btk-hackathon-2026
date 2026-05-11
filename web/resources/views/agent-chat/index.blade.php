<x-app-layout>
  <x-slot name="title">Ajan Asistan</x-slot>

  <x-slot name="pageCss">
  <style>
    #chat-container {
      height: calc(100vh - 340px);
      min-height: 400px;
      overflow-y: auto;
      scroll-behavior: smooth;
    }
    .message-bubble {
      max-width: 85%;
      word-break: break-word;
    }
    .message-bubble.user {
      background: #7367f0;
      color: #fff;
      border-radius: 18px 18px 4px 18px;
    }
    .message-bubble.assistant {
      background: var(--bs-tertiary-bg);
      border: 1px solid var(--bs-border-color);
      border-radius: 18px 18px 18px 4px;
    }
    .agent-badge {
      font-size: 10px;
      padding: 2px 8px;
      border-radius: 20px;
      font-weight: 600;
    }
    .typing-dots span {
      width: 8px; height: 8px; border-radius: 50%;
      background: #7367f0; display: inline-block;
      animation: bounce 1.4s infinite ease-in-out both;
    }
    .typing-dots span:nth-child(1) { animation-delay: -0.32s; }
    .typing-dots span:nth-child(2) { animation-delay: -0.16s; }
    @@keyframes bounce {
      0%, 80%, 100% { transform: scale(0); }
      40%            { transform: scale(1); }
    }
    .specialist-panel { font-size: 13px; }
    .specialist-panel pre { font-size: 11px; white-space: pre-wrap; }
  </style>
  </x-slot>

  {{-- Header --}}
  <div class="d-flex align-items-center justify-content-between mb-5 flex-wrap gap-3">
    <div>
      <h4 class="fw-bold mb-0">
        <i class="icon-base ti tabler-robot text-primary me-2"></i>Ajan Asistan
      </h4>
      <p class="text-muted mb-0">Paralel çalışan yapay zeka ajanlarıyla finansal kararlar al</p>
    </div>
    <div class="d-flex gap-2">
      <a href="{{ route('agent-chat.index') }}" class="btn btn-sm btn-outline-secondary">
        <i class="icon-base ti tabler-plus me-1"></i> Yeni Sohbet
      </a>
    </div>
  </div>

  <div class="row g-5">

    {{-- Chat panel --}}
    <div class="col-xl-8">
      <div class="card h-100">
        <div class="card-header border-bottom d-flex align-items-center gap-3 py-3">
          <div class="avatar bg-label-primary">
            <i class="icon-base ti tabler-brain text-primary"></i>
          </div>
          <div>
            <h6 class="mb-0">Paranette AI</h6>
            <small class="text-success"><i class="icon-base ti tabler-circle-filled me-1" style="font-size:8px"></i>Çevrimiçi &bull; Gemini 2.5 Pro + Flash</small>
          </div>
        </div>

        <div class="card-body p-0">
          <div id="chat-container" class="p-4">

            {{-- Welcome --}}
            <div id="welcome-msg" class="{{ $history->isNotEmpty() ? 'd-none' : '' }}">
              <div class="text-center py-5">
                <div class="avatar avatar-xl bg-label-primary mb-3 mx-auto">
                  <i class="icon-base ti tabler-sparkles icon-36px text-primary"></i>
                </div>
                <h5 class="mb-2">Paranette Ajan Asistanı</h5>
                <p class="text-muted mb-4 mx-auto" style="max-width:400px">
                  Finansal kararlarınız için uzman ajanlar devreye girer, canlı analiz sunar.
                </p>
                <div class="row g-3 justify-content-center" style="max-width:600px; margin: 0 auto;">
                  <div class="col-sm-6">
                    <div class="card border cursor-pointer suggestion-card" data-msg="50.000 TL'ye telefon almak istiyorum, nasıl yaparım?">
                      <div class="card-body p-3 text-start">
                        <i class="icon-base ti tabler-device-mobile text-primary mb-2"></i>
                        <p class="small mb-0">50.000 TL'ye telefon almak istiyorum</p>
                      </div>
                    </div>
                  </div>
                  <div class="col-sm-6">
                    <div class="card border cursor-pointer suggestion-card" data-msg="Aylık bütçemi nasıl optimize edebilirim?">
                      <div class="card-body p-3 text-start">
                        <i class="icon-base ti tabler-chart-pie text-success mb-2"></i>
                        <p class="small mb-0">Aylık bütçemi nasıl optimize edebilirim?</p>
                      </div>
                    </div>
                  </div>
                  <div class="col-sm-6">
                    <div class="card border cursor-pointer suggestion-card" data-msg="Enflasyon birikimimi nasıl etkiliyor?">
                      <div class="card-body p-3 text-start">
                        <i class="icon-base ti tabler-trending-up text-warning mb-2"></i>
                        <p class="small mb-0">Enflasyon birikimimi nasıl etkiliyor?</p>
                      </div>
                    </div>
                  </div>
                  <div class="col-sm-6">
                    <div class="card border cursor-pointer suggestion-card" data-msg="Son harcamalarımda anormal bir durum var mı?">
                      <div class="card-body p-3 text-start">
                        <i class="icon-base ti tabler-alert-triangle text-danger mb-2"></i>
                        <p class="small mb-0">Harcamalarımda anormal bir durum var mı?</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {{-- History --}}
            @foreach($history as $msg)
              @if($msg->role === 'user')
                <div class="d-flex justify-content-end mb-4">
                  <div class="message-bubble user p-3 shadow-sm">
                    {{ $msg->content }}
                  </div>
                </div>
              @else
                <div class="mb-4">
                  <div class="d-flex gap-2 align-items-start">
                    <div class="avatar avatar-sm bg-label-primary flex-shrink-0">
                      <i class="icon-base ti tabler-robot text-primary" style="font-size:14px"></i>
                    </div>
                    <div class="flex-grow-1">
                      @if(!empty($msg->metadata['agents_used']))
                        <div class="d-flex flex-wrap gap-1 mb-2">
                          @foreach($msg->metadata['agents_used'] as $a)
                            <span class="agent-badge bg-label-info text-info">{{ $a }}</span>
                          @endforeach
                        </div>
                      @endif
                      <div class="message-bubble assistant p-3 shadow-sm">
                        {!! nl2br(e($msg->content)) !!}
                      </div>
                    </div>
                  </div>
                </div>
              @endif
            @endforeach

          </div>

          {{-- Typing indicator --}}
          <div id="typing-indicator" class="px-4 pb-2 d-none">
            <div class="d-flex gap-2 align-items-center">
              <div class="avatar avatar-sm bg-label-primary">
                <i class="icon-base ti tabler-robot text-primary" style="font-size:14px"></i>
              </div>
              <div class="message-bubble assistant p-3">
                <div class="typing-dots d-flex gap-1">
                  <span></span><span></span><span></span>
                </div>
                <small class="text-muted ms-2" id="typing-label">Ajanlar çalışıyor...</small>
              </div>
            </div>
          </div>
        </div>

        {{-- Input --}}
        <div class="card-footer border-top p-3">
          <form id="chat-form" class="d-flex gap-2">
            @csrf
            <input type="hidden" name="session_id" value="{{ $sessionId }}">
            <input type="text" id="chat-input" name="message"
                   class="form-control form-control-lg"
                   placeholder="Bir şey sor... (örn: 50.000 TL'ye telefon alabilir miyim?)"
                   autocomplete="off">
            <button type="submit" class="btn btn-primary btn-lg px-4" id="send-btn">
              <i class="icon-base ti tabler-send"></i>
            </button>
          </form>
        </div>
      </div>
    </div>

    {{-- Side panel --}}
    <div class="col-xl-4">

      {{-- Agent status --}}
      <div class="card mb-5">
        <div class="card-header">
          <h6 class="card-title mb-0">
            <i class="icon-base ti tabler-cpu me-2 text-primary"></i>Aktif Ajanlar
          </h6>
        </div>
        <div class="card-body p-0">
          <ul class="list-group list-group-flush" id="agent-status-list">
            @foreach(['purchase_planner' => ['Satın Alma Planlayıcı','tabler-shopping-cart','primary'], 'inflation_aware' => ['Enflasyon Analisti','tabler-trending-up','warning'], 'budget_advisor' => ['Bütçe Danışmanı','tabler-chart-pie','success'], 'anomaly_detector' => ['Anomali Dedektörü','tabler-alert-triangle','danger'], 'transaction_classifier' => ['İşlem Sınıflandırıcı','tabler-tag','info']] as $key => [$label, $icon, $color])
              <li class="list-group-item d-flex align-items-center gap-2 py-2" id="agent-{{ $key }}">
                <div class="avatar avatar-sm bg-label-{{ $color }}">
                  <i class="icon-base ti {{ $icon }} text-{{ $color }}" style="font-size:13px"></i>
                </div>
                <div class="flex-grow-1">
                  <div class="fw-medium small">{{ $label }}</div>
                </div>
                <span class="badge bg-label-secondary agent-state">Beklemede</span>
              </li>
            @endforeach
          </ul>
        </div>
      </div>

      {{-- Recent runs --}}
      <div class="card mb-5">
        <div class="card-header">
          <h6 class="card-title mb-0">
            <i class="icon-base ti tabler-history me-2 text-muted"></i>Son Çalışmalar
          </h6>
        </div>
        <div class="card-body specialist-panel p-0">
          <ul class="list-group list-group-flush" id="runs-list">
            @forelse($recentRuns as $run)
              <li class="list-group-item py-2">
                <div class="d-flex justify-content-between align-items-center">
                  <span class="small fw-medium text-truncate" style="max-width:140px">{{ $run->agent_name }}</span>
                  <span class="badge @if($run->status === 'completed') bg-label-success @elseif($run->status === 'failed') bg-label-danger @else bg-label-warning @endif small">
                    {{ $run->status }}
                  </span>
                </div>
                <div class="text-muted" style="font-size:11px">
                  {{ $run->model_used ?? '—' }} &bull; {{ $run->duration_ms ? $run->duration_ms . 'ms' : '—' }}
                  &bull; {{ $run->tokens_in + $run->tokens_out }} tok
                </div>
              </li>
            @empty
              <li class="list-group-item text-muted small py-3 text-center">Henüz çalışma yok</li>
            @endforelse
          </ul>
        </div>
      </div>

      {{-- Insights --}}
      @if($insights->isNotEmpty())
        <div class="card">
          <div class="card-header">
            <h6 class="card-title mb-0">
              <i class="icon-base ti tabler-bulb me-2 text-warning"></i>Öngörüler
            </h6>
          </div>
          <div class="card-body p-0">
            <ul class="list-group list-group-flush">
              @foreach($insights as $insight)
                <li class="list-group-item py-2">
                  <div class="fw-medium small">{{ $insight->title }}</div>
                  <p class="text-muted small mb-0">{{ Str::limit($insight->body, 80) }}</p>
                </li>
              @endforeach
            </ul>
          </div>
        </div>
      @endif

    </div>
  </div>

  <x-slot name="pageJs">
  <script>
  (function () {
    const chatContainer  = document.getElementById('chat-container');
    const form           = document.getElementById('chat-form');
    const input          = document.getElementById('chat-input');
    const sendBtn        = document.getElementById('send-btn');
    const typingIndicator = document.getElementById('typing-indicator');
    const typingLabel    = document.getElementById('typing-label');
    const welcomeMsg     = document.getElementById('welcome-msg');
    const sessionId      = form.querySelector('[name=session_id]').value;
    const csrfToken      = document.querySelector('meta[name=csrf-token]').content;

    const agentLabels = {
      purchase_planner:        'Satın Alma Planlayıcı',
      budget_advisor:          'Bütçe Danışmanı',
      inflation_aware:         'Enflasyon Analisti',
      anomaly_detector:        'Anomali Dedektörü',
      transaction_classifier:  'İşlem Sınıflandırıcı',
    };

    // Suggestion cards
    document.querySelectorAll('.suggestion-card').forEach(card => {
      card.addEventListener('click', () => {
        input.value = card.dataset.msg;
        input.focus();
      });
    });

    function scrollToBottom() {
      chatContainer.scrollTop = chatContainer.scrollHeight;
    }

    function appendMessage(role, content, agentsUsed = []) {
      welcomeMsg?.classList.add('d-none');

      if (role === 'user') {
        const el = document.createElement('div');
        el.className = 'justify-content-end mb-4 d-flex';
        el.innerHTML = `<div class="message-bubble user p-3 shadow-sm">${escapeHtml(content)}</div>`;
        chatContainer.insertBefore(el, document.getElementById('typing-indicator'));
      } else {
        const badges = agentsUsed.map(a =>
          `<span class="agent-badge bg-label-info text-info">${a}</span>`
        ).join('');

        const el = document.createElement('div');
        el.className = 'mb-4';
        el.innerHTML = `
          <div class="d-flex gap-2 align-items-start">
            <div class="avatar avatar-sm bg-label-primary flex-shrink-0">
              <i class="icon-base ti tabler-robot text-primary" style="font-size:14px"></i>
            </div>
            <div class="flex-grow-1">
              ${badges ? `<div class="d-flex flex-wrap gap-1 mb-2">${badges}</div>` : ''}
              <div class="message-bubble assistant p-3 shadow-sm">${escapeHtml(content).replace(/\n/g, '<br>')}</div>
            </div>
          </div>`;
        chatContainer.insertBefore(el, document.getElementById('typing-indicator'));
      }

      scrollToBottom();
    }

    function setAgentStates(agents, state) {
      document.querySelectorAll('.agent-state').forEach(el => {
        el.textContent = 'Beklemede';
        el.className = 'badge bg-label-secondary agent-state';
      });
      agents.forEach(a => {
        const li = document.getElementById(`agent-${a}`);
        if (li) {
          const badge = li.querySelector('.agent-state');
          badge.textContent = state === 'running' ? 'Çalışıyor' : 'Tamamlandı';
          badge.className = `badge ${state === 'running' ? 'bg-label-warning' : 'bg-label-success'} agent-state`;
        }
      });
    }

    function escapeHtml(str) {
      const d = document.createElement('div');
      d.appendChild(document.createTextNode(str));
      return d.innerHTML;
    }

    // ── Real-time agent polling ─────────────────────────────────────
    let pollingTimer = null;
    const agentStepLabels = [
      'İstek yönlendiriliyor…',
      'Uzman ajanlar seçiliyor…',
      'Finansal veriler analiz ediliyor…',
      'Bütçe ve harcamalar değerlendiriliyor…',
      'Sonuçlar sentezleniyor…',
    ];
    let stepIdx = 0;

    function startPolling() {
      stepIdx = 0;
      pollingTimer = setInterval(async () => {
        // Cycle through descriptive labels
        typingLabel.textContent = agentStepLabels[stepIdx % agentStepLabels.length];
        stepIdx++;

        // Fetch recent runs to light up agent badges
        try {
          const r = await fetch('{{ route("agent-chat.runs") }}', {
            headers: { 'Accept': 'application/json', 'X-CSRF-TOKEN': csrfToken },
          });
          const d = await r.json();
          const recent = (d.runs ?? []).slice(0, 5);
          const runningNames = recent
            .filter(run => run.status === 'running')
            .map(run => run.agent_name);
          if (runningNames.length) setAgentStates(runningNames, 'running');
        } catch (_) {}
      }, 2500);
    }

    function stopPolling() {
      clearInterval(pollingTimer);
      pollingTimer = null;
      typingLabel.textContent = 'Ajanlar çalışıyor…';
    }

    async function sendMessage(msg) {
      if (!msg.trim()) return;

      appendMessage('user', msg);
      input.value = '';
      sendBtn.disabled = true;

      // Reset agent badges to "waiting"
      document.querySelectorAll('.agent-state').forEach(el => {
        el.textContent = 'Beklemede';
        el.className = 'badge bg-label-secondary agent-state';
      });

      typingIndicator.classList.remove('d-none');
      scrollToBottom();
      startPolling();

      try {
        const resp = await fetch('{{ route("agent-chat.send") }}', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': csrfToken,
            'Accept': 'application/json',
          },
          body: JSON.stringify({ message: msg, session_id: sessionId }),
        });

        stopPolling();
        const data = await resp.json();
        typingIndicator.classList.add('d-none');

        if (data.agents_used?.length) {
          setAgentStates(data.agents_used, 'done');
        }

        if (data.status === 'error') {
          appendMessage('assistant', '⚠️ ' + (data.reply ?? 'Bir hata oluştu. Lütfen tekrar deneyin.'), []);
        } else {
          appendMessage('assistant', data.reply, data.agents_used ?? []);
        }

      } catch (err) {
        stopPolling();
        typingIndicator.classList.add('d-none');
        appendMessage('assistant', 'Bağlantı hatası. İnternet bağlantınızı kontrol edip tekrar deneyin.');
      } finally {
        sendBtn.disabled = false;
        input.focus();
      }
    }

    form.addEventListener('submit', e => {
      e.preventDefault();
      sendMessage(input.value.trim());
    });

    scrollToBottom();
  })();
  </script>
  </x-slot>
</x-app-layout>
