package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"
)

const (
	reset  = "\033[0m"
	bold   = "\033[1m"
	cyan   = "\033[96m"
	green  = "\033[92m"
	yellow = "\033[93m"
	red    = "\033[91m"
	gray   = "\033[90m"
	white  = "\033[97m"
	blue   = "\033[94m"
)

func projectRoot() string {
	exe, _ := os.Executable()
	dir := filepath.Dir(exe)
	if filepath.Base(dir) == "launcher" {
		return filepath.Dir(dir)
	}
	return dir
}

func webDir(root string) string { return filepath.Join(root, "web") }

func logLine(color, symbol, msg string) {
	fmt.Printf("%s%s %s%s\n", color, symbol, msg, reset)
}

func logStep(msg string)  { logLine(cyan, "→", msg) }
func logOK(msg string)    { logLine(green, "✓", msg) }
func logWarn(msg string)  { logLine(yellow, "!", msg) }
func logError(msg string) { logLine(red, "✗", msg) }
func logInfo(msg string)  { logLine(gray, "·", msg) }

func banner() {
	fmt.Println()
	fmt.Printf("%s%s╔══════════════════════════════════════════════════╗%s\n", bold, cyan, reset)
	fmt.Printf("%s%s║     PARANETTE — BTK AKADEMİ HACKATHON           ║%s\n", bold, white, reset)
	fmt.Printf("%s%s╚══════════════════════════════════════════════════╝%s\n", bold, cyan, reset)
	fmt.Println()
}

// ── Port kontrolleri ──────────────────────────────────────────────────────

func portOpen(host string, port int) bool {
	conn, err := net.DialTimeout("tcp", fmt.Sprintf("%s:%d", host, port), time.Second)
	if err != nil {
		return false
	}
	conn.Close()
	return true
}

func mysqlReady() bool   { return portOpen("127.0.0.1", 3306) }
func laravelReady() bool { return portOpen("127.0.0.1", 8000) }

func emulatorReady(adb string) bool {
	out, err := exec.Command(adb, "devices").Output()
	if err != nil {
		return false
	}
	return strings.Contains(string(out), "emulator-")
}

// ── Yerel IP algılama (gerçek cihaz için) ─────────────────────────────────

func detectLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "10.0.2.2"
	}
	for _, addr := range addrs {
		ipnet, ok := addr.(*net.IPNet)
		if !ok || ipnet.IP.IsLoopback() {
			continue
		}
		if ip4 := ipnet.IP.To4(); ip4 != nil {
			return ip4.String()
		}
	}
	return "10.0.2.2"
}

// ── AVD listesi ve seçimi ─────────────────────────────────────────────────

type avdInfo struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

// listAVDs: mevcut tüm AVD'leri döner.
// Önce JSON (--machine) dener, başarısız olursa metin parse eder.
func listAVDs(flutter string) []avdInfo {
	out, err := exec.Command(flutter, "emulators", "--machine").CombinedOutput()
	if err == nil {
		var list []avdInfo
		if json.Unmarshal(out, &list) == nil && len(list) > 0 {
			return list
		}
	}

	out, _ = exec.Command(flutter, "emulators").CombinedOutput()
	var list []avdInfo
	for _, line := range strings.Split(string(out), "\n") {
		line = strings.TrimSpace(line)
		if !strings.HasPrefix(line, "•") {
			continue
		}
		parts := strings.Split(line, "•")
		if len(parts) < 2 {
			continue
		}
		fields := strings.Fields(parts[1])
		if len(fields) == 0 {
			continue
		}
		avdID := fields[0]
		avdName := avdID
		if len(parts) >= 3 {
			avdName = strings.TrimSpace(parts[2])
		}
		list = append(list, avdInfo{ID: avdID, Name: avdName})
	}
	if len(list) > 0 {
		return list
	}
	return []avdInfo{{ID: "Medium_Phone", Name: "Medium Phone"}}
}

// selectAVD: her zaman kullanıcıya AVD listesini gösterir.
func selectAVD(flutter string, reader *bufio.Reader) avdInfo {
	avds := listAVDs(flutter)

	fmt.Printf("%s%s┌─────────────────────────────────────────────────┐%s\n", bold, cyan, reset)
	fmt.Printf("%s%s│  EMÜLATÖR SEÇİMİ                                │%s\n", bold, white, reset)
	fmt.Printf("%s%s├─────────────────────────────────────────────────┤%s\n", bold, cyan, reset)
	for i, a := range avds {
		entry := fmt.Sprintf("%s (%s)", a.ID, a.Name)
		row := fmt.Sprintf("│  %d → %-44s│", i+1, entry)
		fmt.Printf("%s%s%s%s\n", bold, gray, row, reset)
	}
	fmt.Printf("%s%s└─────────────────────────────────────────────────┘%s\n", bold, cyan, reset)
	fmt.Printf("  Seçim [1]: ")

	line, _ := reader.ReadString('\n')
	choice := strings.TrimSpace(line)

	idx := 0
	if choice != "" {
		var n int
		if _, err := fmt.Sscan(choice, &n); err == nil && n >= 1 && n <= len(avds) {
			idx = n - 1
		}
	}

	selected := avds[idx]
	logOK(fmt.Sprintf("Seçilen AVD: %s (%s)", selected.ID, selected.Name))
	return selected
}

// ── Bekleme yardımcısı ────────────────────────────────────────────────────

func waitUntil(check func() bool, label string, timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if check() {
			fmt.Println()
			return true
		}
		fmt.Printf("\r%s  bekliyor: %s%s%s %-3d sn",
			gray, yellow, label, gray, int(time.Until(deadline).Seconds()))
		time.Sleep(500 * time.Millisecond)
	}
	fmt.Println()
	return false
}

func startBackground(name string, args ...string) *exec.Cmd {
	cmd := exec.Command(name, args...)
	cmd.SysProcAttr = sysProcAttr()
	if err := cmd.Start(); err != nil {
		logError(fmt.Sprintf("%s başlatılamadı: %v", name, err))
	}
	return cmd
}

// ── API bağlantı seçimi ───────────────────────────────────────────────────

func selectAPIHost(reader *bufio.Reader) string {
	localIP := detectLocalIP()

	fmt.Printf("%s%s┌─────────────────────────────────────────────────┐%s\n", bold, cyan, reset)
	fmt.Printf("%s%s│  API BAĞLANTI MODU                              │%s\n", bold, white, reset)
	fmt.Printf("%s%s├─────────────────────────────────────────────────┤%s\n", bold, cyan, reset)
	fmt.Printf("%s%s│  1 → Emülatör     (10.0.2.2)  ← varsayılan     │%s\n", bold, gray, reset)
	fmt.Printf("%s%s│  2 → Gerçek cihaz (%s)         │%s\n", bold, yellow, padRight(localIP, 16), reset)
	fmt.Printf("%s%s│  3 → Manuel IP gir                              │%s\n", bold, gray, reset)
	fmt.Printf("%s%s└─────────────────────────────────────────────────┘%s\n", bold, cyan, reset)
	fmt.Printf("  Seçim [1]: ")

	line, _ := reader.ReadString('\n')
	choice := strings.TrimSpace(line)

	switch choice {
	case "2":
		logOK(fmt.Sprintf("Yerel IP: %s", localIP))
		return localIP
	case "3":
		fmt.Printf("  IP adresi girin (örn: 192.168.1.100): ")
		ip, _ := reader.ReadString('\n')
		ip = strings.TrimSpace(ip)
		if ip == "" {
			ip = "10.0.2.2"
		}
		logOK(fmt.Sprintf("Manuel IP: %s", ip))
		return ip
	default:
		logOK("Emülatör modu: 10.0.2.2")
		return "10.0.2.2"
	}
}

func padRight(s string, n int) string {
	for len(s) < n {
		s += " "
	}
	return s
}

// ── Main ──────────────────────────────────────────────────────────────────

func main() {
	if runtime.GOOS == "windows" {
		enableVirtualTerminal()
	}

	banner()

	reader := bufio.NewReader(os.Stdin)

	php     := findPHP()
	mysql   := findMySQLManager()
	flutter := findFlutter()
	adb     := findADB()

	logInfo(fmt.Sprintf("PHP     : %s", php))
	logInfo(fmt.Sprintf("Flutter : %s", flutter))
	logInfo(fmt.Sprintf("ADB     : %s", adb))
	if mysql != "" {
		logInfo(fmt.Sprintf("MySQL   : %s", mysql))
	}
	fmt.Println()

	// ── API bağlantı modu ────────────────────────────────────────────────
	apiHost := selectAPIHost(reader)
	fmt.Println()

	root := projectRoot()
	web  := webDir(root)

	// ── 1. MySQL ─────────────────────────────────────────────────────────
	fmt.Printf("%s[1/5] MySQL kontrolü...%s\n", bold, reset)
	if mysqlReady() {
		logOK("MySQL zaten çalışıyor (port 3306)")
	} else if mysql != "" {
		logStep(fmt.Sprintf("Başlatılıyor: %s", filepath.Base(mysql)))
		startBackground(mysql)
		if waitUntil(mysqlReady, "MySQL", 60*time.Second) {
			logOK("MySQL hazır")
		} else {
			logWarn("MySQL 60 saniyede hazır olmadı — devam ediliyor")
		}
	} else {
		logWarn("MySQL yöneticisi bulunamadı. MySQL'in çalıştığından emin olun.")
	}
	fmt.Println()

	// ── 2. Laravel ───────────────────────────────────────────────────────
	fmt.Printf("%s[2/5] Laravel sunucusu...%s\n", bold, reset)
	if laravelReady() {
		logOK("Laravel zaten çalışıyor (port 8000)")
	} else {
		logStep("php artisan serve başlatılıyor...")
		laravelCmd := exec.Command(php, "artisan", "serve", "--host=127.0.0.1", "--port=8000")
		laravelCmd.Dir = web
		laravelCmd.SysProcAttr = sysProcAttr()
		if err := laravelCmd.Start(); err != nil {
			logError(fmt.Sprintf("Laravel başlatılamadı: %v", err))
		} else if waitUntil(laravelReady, "Laravel", 30*time.Second) {
			logOK("Laravel hazır → http://127.0.0.1:8000")
		} else {
			logWarn("Laravel 30 saniyede yanıt vermedi")
		}
	}
	fmt.Println()

	// ── 3. Android Emülatör ──────────────────────────────────────────────
	fmt.Printf("%s[3/5] Android Emülatörü...%s\n", bold, reset)
	if emulatorReady(adb) {
		logOK("Emülatör zaten çalışıyor")
	} else {
		selectedAVD := selectAVD(flutter, reader)
		logStep(fmt.Sprintf("AVD başlatılıyor: %s (%s)", selectedAVD.ID, selectedAVD.Name))
		startBackground(flutter, "emulators", "--launch", selectedAVD.ID)
		if waitUntil(func() bool { return emulatorReady(adb) }, "Emülatör", 120*time.Second) {
			logOK(fmt.Sprintf("Emülatör hazır: %s", selectedAVD.Name))
		} else {
			logWarn("Emülatör 120 saniyede hazır olmadı")
		}
	}
	fmt.Println()

	// ── 4. Boot tamamlanmasını bekle ─────────────────────────────────────
	fmt.Printf("%s[4/5] Emülatör boot kontrolü...%s\n", bold, reset)
	logStep("sys.boot_completed bekleniyor...")
	bootReady := false
	for i := 0; i < 60; i++ {
		out, _ := exec.Command(adb, "wait-for-device", "shell",
			"getprop", "sys.boot_completed").Output()
		if strings.TrimSpace(string(out)) == "1" {
			bootReady = true
			break
		}
		time.Sleep(2 * time.Second)
	}
	if bootReady {
		logOK("Emülatör tamamen boot oldu")
	} else {
		logWarn("Boot kontrolü zaman aşımı — Flutter yükleniyor...")
	}
	fmt.Println()

	// ── 5. Flutter ───────────────────────────────────────────────────────
	fmt.Printf("%s[5/5] Flutter uygulaması başlatılıyor...%s\n", bold, reset)
	logInfo(fmt.Sprintf("Proje: %s", filepath.Join(root, "mobile")))
	fmt.Println()

	fmt.Printf("%s%s┌─────────────────────────────────────────┐%s\n", bold, blue, reset)
	fmt.Printf("%s%s│  WEB   → http://127.0.0.1:8000          │%s\n", bold, white, reset)
	fmt.Printf("%s%s│  API   → http://127.0.0.1:8000/api/v1   │%s\n", bold, cyan, reset)
	fmt.Printf("%s%s│  MOBİL → http://%s:8000/api/v1  │%s\n", bold, yellow, padRight(apiHost, 9), reset)
	fmt.Printf("%s%s└─────────────────────────────────────────┘%s\n", bold, blue, reset)
	fmt.Println()

	mobileDir := filepath.Join(root, "mobile")
	// API_HOST --dart-define ile Flutter'a iletilir; api_endpoints.dart okur
	flutterCmd := exec.Command(flutter, "run",
		"-d", "emulator-5554",
		fmt.Sprintf("--dart-define=API_HOST=%s", apiHost),
	)
	flutterCmd.Dir = mobileDir
	flutterCmd.Stdin = os.Stdin
	flutterCmd.Stdout = os.Stdout
	flutterCmd.Stderr = os.Stderr

	logOK("Flutter başlatıldı — r: hot reload | R: restart | q: çıkış")
	fmt.Println()

	if err := flutterCmd.Run(); err != nil {
		logError(fmt.Sprintf("Flutter çıktı: %v", err))
	}

	fmt.Println()
	logInfo("Flutter oturumu bitti. Çıkmak için Enter'a bas...")
	reader.ReadString('\n')
}
